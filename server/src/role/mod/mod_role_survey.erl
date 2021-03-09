%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 五月 2018 14:43
%%%-------------------------------------------------------------------
-module(mod_role_survey).
-author("laijichang").
-include("role.hrl").
-include("role_extra.hrl").
-include("proto/mod_role_survey.hrl").

%% API
-export([
    online/1,
    handle/2,
    level_up/3
]).

-export([
    gm_reset_survey/1
]).

online(State) ->
    #r_role{role_id = RoleID} = State,
    OldSurveyID = mod_role_extra:get_data(?SURVEY_ID, 0, State),
    #r_survey{survey_id = SurveyID, min_level = MinLevel} = get_world_survey(State),
    IsOpen = SurveyID > OldSurveyID andalso mod_role_data:get_role_level(State) >= MinLevel,
    common_misc:unicast(RoleID, #m_survey_state_toc{is_open = IsOpen}),
    State.

handle({survey_change, SurveyID}, State) ->
    do_survey_change(SurveyID, State);
handle({#m_survey_info_tos{}, RoleID, _PID}, State) ->
    do_survey_info(RoleID, State);
handle({#m_survey_summit_tos{answer_string = AnswerString, answer_time = AnswerTime, survey_id = SurveyID}, RoleID, _PID}, State) ->
    do_survey_summit(RoleID, SurveyID, AnswerString, AnswerTime, State).

do_survey_change(ChangeSurveyID, State) ->
    RoleID = State#r_role.role_id,
    #r_survey{survey_id = SurveyID} = get_world_survey(State),
    ?IF(ChangeSurveyID =:= SurveyID, common_misc:unicast(RoleID, #m_survey_state_toc{is_open = false}), ok),
    online(State).

level_up(OldLevel, NewLevel, State) ->
    #r_survey{min_level = MinLevel} = get_world_survey(State),
    case OldLevel < MinLevel andalso MinLevel =< NewLevel of
        true ->
            online(State);
        _ ->
            ok
    end.

gm_reset_survey(State) ->
    State2 = mod_role_extra:set_data(?SURVEY_ID, 0, State),
    online(State2).

do_survey_info(RoleID, State) ->
    case catch check_survey_info(State) of
        {ok, SurveyID, Questions, Rewards} ->
            DataRecord = #m_survey_info_toc{questions = Questions, rewards = Rewards, survey_id = SurveyID},
            common_misc:unicast(RoleID, DataRecord),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_survey_info_toc{err_code = ErrCode}),
            State
    end.

check_survey_info(State) ->
    OldSurveyID = mod_role_extra:get_data(?SURVEY_ID, 0, State),
    Survey = get_world_survey(State),
    #r_survey{
        survey_id = SurveyID,
        min_level = MinLevel,
        questions = Questions,
        rewards = Rewards} = Survey,
    ?IF(SurveyID > OldSurveyID, ok, ?THROW_ERR(?ERROR_SURVEY_SUMMIT_001)),
    ?IF(mod_role_data:get_role_level(State) >= MinLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    {ok, SurveyID, Questions, Rewards}.

do_survey_summit(RoleID, SurveyID, AnswerString, AnswerTime, State) ->
    case catch check_survey_summit(SurveyID, State) of
        {ok, GoodsList} ->
            State2 = role_misc:create_goods(State, ?ITEM_GAIN_SURVEY_REWARD, GoodsList),
            State3 = mod_role_extra:set_data(?SURVEY_ID, SurveyID, State2),
            ?TRY_CATCH(log_survey_summit(SurveyID, AnswerString, AnswerTime, State2)),
            common_misc:unicast(RoleID, #m_survey_summit_toc{}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_survey_summit_toc{err_code = ErrCode}),
            State
    end.

check_survey_summit(SurveyID, State) ->
    OldSurveyID = mod_role_extra:get_data(?SURVEY_ID, 0, State),
    ?IF(SurveyID > OldSurveyID, ok, ?THROW_ERR(?ERROR_SURVEY_SUMMIT_001)),
    #r_role{role_attr = #r_role_attr{game_channel_id = GameChannelID}} = State,
    SurveyList = world_data:get_survey_list(),
    SurveyList2 = [ Survey|| #r_survey{game_channel_id_list = GameChannelIDList} = Survey <- SurveyList, lists:member(GameChannelID, GameChannelIDList)],
    Survey =
        case lists:keyfind(SurveyID, #r_survey.survey_id, SurveyList2) of
            #r_survey{} = SurveyT ->
                SurveyT;
            _ ->
                ?THROW_ERR(?ERROR_SURVEY_SUMMIT_001)
        end,
    #r_survey{rewards = Rewards} = Survey,
    GoodsList = [ #p_goods{type_id = TypeID, num = Num} || #p_kv{id = TypeID, val = Num} <- Rewards],
    {ok, GoodsList}.

log_survey_summit(SurveyID, AnswerString, AnswerTime, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    Texts = lists:sublist(AnswerString, 2000),
    Log =
        #log_role_question{
            role_id = RoleID,
            vip_level = mod_role_vip:get_vip_level(State),
            question_id = SurveyID,
            result = unicode:characters_to_binary(Texts),
            use_time = AnswerTime,
            channel_id = ChannelID,
            game_channel_id = GameChannelID
        },
    mod_role_dict:add_background_logs(Log).

get_world_survey(State) ->
    #r_role{role_attr = #r_role_attr{game_channel_id = GameChannelID}} = State,
    SurveyList = world_data:get_survey_list(),
    SurveyList2 = [ Survey|| #r_survey{game_channel_id_list = GameChannelIDList} = Survey <- SurveyList, lists:member(GameChannelID, GameChannelIDList)],
    case SurveyList2 of
        [_|_] ->
            [Survey|_] = lists:reverse(lists:keysort(#r_survey.survey_id, SurveyList2)),
            Survey;
        _ ->
            #r_survey{}
    end.


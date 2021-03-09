%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 四月 2018 11:30
%%%-------------------------------------------------------------------
-module(mod_map_family_as).
-author("WZP").

-include("common.hrl").
-include("map.hrl").
-include("global.hrl").
-include("activity.hrl").
-include("family_as.hrl").
-include("proto/mod_family_as.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_family_as.hrl").
-include("proto/mod_role_chat.hrl").
-include("proto/world_activity_server.hrl").
%% API
-export([
    init/0,
    handle/1,
    loop/1,
    role_enter_map/1
]).

-export([
    activity_end/1
]).

-export([
    answer_question/4
]).

init() ->
    ok.

role_enter_map(RoleID) ->
    RoleAsExp = mod_role_family_as:get_family_as_exp(RoleID),
    common_misc:unicast(RoleID, #m_family_as_exp_toc{exp = RoleAsExp#r_family_as_exp.exp}),
    Target = lists:member(RoleID, mod_map_ets:get_family_as_collect_roles()),
    Res = ?IF(Target, ?FAMILY_AS_IS_CL, ?FAMILY_AS_IS_NOT_CL),
    common_misc:unicast(RoleID, #m_family_as_cl_toc{collection = Res}),
    case get_now_questions() of
        {Question, RefreshTime} ->
            case Question =/= no_question of
                true ->
                    common_misc:unicast(RoleID, #m_family_as_time_toc{time = RefreshTime});
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

activity_end(MapPid) ->
    pname_server:send(MapPid, {mod, ?MODULE, activity_end}).



handle({send_question, Questions, FamilyName}) ->
    set_family_as_questions(Questions),
    set_family_name(FamilyName);
handle({start, Now}) ->
    do_start_answer(Now);
handle({rank_info, RankInfoList}) ->
    do_bc_rank_info(RankInfoList);
handle({check_answer, RoleName, Answer, RoleID}) ->
    check_answer(Answer, RoleName, RoleID);
handle(activity_end) ->
    do_map_end();
handle(do_start_answer_i) ->
    do_start_answer_i();
handle({do_get_question, RoleID}) ->
    do_send_question(RoleID);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

loop(Now) ->
    AddExpTime = get_add_exp_time(),
    if
        AddExpTime =< Now ->
            map_server:send_all_role({mod, mod_role_family_as, add_reward}),
            [Config] = lib_config:find(cfg_global, ?FAMILY_AS_ADD_EXP_TIME),
            [Time, _, _, _] = Config#c_global.list,
            set_add_exp_time(AddExpTime + Time);
        true ->
            ok
    end,
    case get_now_questions() of
        {Question, Refresh} ->
            case Refresh =:= Now andalso Question =/= no_question of
                false ->
                    ok;
                _ ->
                    FamilyID = map_common_dict:get_map_extra_id(),
                    case get_family_as_questions() of
                        [] ->
                            set_now_questions(no_question, ?FAMILY_AS_REFRESH_TIME + time_tool:now()),
                            common_broadcast:bc_del_top_record_to_family(FamilyID);
                        [NewQuestion|OtherQuestion] ->
                            common_broadcast:bc_top_record_to_family(FamilyID, NewQuestion#c_activity_family_as.question),
                            RefreshTime = ?FAMILY_AS_REFRESH_TIME + time_tool:now(),
                            common_broadcast:bc_record_to_family(FamilyID, #m_family_as_time_toc{time = RefreshTime}),
                            set_now_questions(NewQuestion, RefreshTime),
                            set_family_as_questions(OtherQuestion)
                    end
            end;
        _ ->
            ok
    end.

do_send_question(RoleID) ->
    case get_now_questions() of
        {#c_activity_family_as{question = Question}, _} ->
            DataRecord = #m_chat_set_top_toc{channel_type = ?CHANNEL_FAMILY, msg = Question},
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end.

answer_question(Answer, RoleName, MapPName, RoleID) ->
    pname_server:send(MapPName, {mod, mod_map_family_as, {check_answer, RoleName, Answer, RoleID}}).

check_answer(Answer, RoleName, RoleID) ->
    {Question, _} = get_now_questions(),
    ?IF(Question =:= no_question, ok, check_answer2(Answer, RoleName, Question, RoleID)).
check_answer2(Answer, RoleName, Question, RoleID) ->
    Res = check_answer3(Question#c_activity_family_as.answer, Answer),
    if
        Res ->
            FamilyID = map_common_dict:get_map_extra_id(),
            FamilyName = get_family_name(),
            world_activity_server:info_mod(mod_family_as, {bingo, FamilyID, FamilyName}),
            case get_family_as_questions() of
                [] ->
                    set_now_questions(no_question, ?FAMILY_AS_REFRESH_TIME + time_tool:now()),
                    common_broadcast:bc_del_top_record_to_family(FamilyID),
                    ChatRole = #p_chat_role{
                        role_id = ?FAMILY_AS_BINGO_ROLE_ID,
                        role_name = "活动提示",
                        level = 999,
                        vip_level = 15};
                [NewQuestion|OtherQuestion] ->
                    ChatRole = #p_chat_role{
                        role_id = ?FAMILY_AS_BINGO_END_ROLE_ID,
                        role_name = "活动提示",
                        level = 999,
                        vip_level = 15},
                    common_broadcast:bc_top_record_to_family(FamilyID, NewQuestion#c_activity_family_as.question),
                    RefreshTime = ?FAMILY_AS_REFRESH_TIME + time_tool:now(),
                    common_broadcast:bc_record_to_family(FamilyID, #m_family_as_time_toc{time = RefreshTime}),
                    set_now_questions(NewQuestion, RefreshTime),
                    set_family_as_questions(OtherQuestion)
            end,
            DataRecord = #m_chat_text_toc{
                channel_type = ?CHANNEL_FAMILY,
                role_info = ChatRole,
                msg = RoleName,
                time = time_tool:now()},
            common_broadcast:bc_role_info_to_family(FamilyID, {mod, mod_role_chat, {chat_info, 0, DataRecord}}),
            role_misc:info_role(RoleID, {mod, mod_role_family_as, right_answer});
        true ->
            ok
    end.

check_answer3(AnswerList, Answer) ->
    List = string:tokens(AnswerList, ","),
    lists:member(Answer, List).


start_activity(Now) ->
    [Config] = lib_config:find(cfg_global, ?FAMILY_AS_ADD_EXP_TIME),
    [Time, _Rate, _Contribute, _] = Config#c_global.list,
    set_add_exp_time(Now + Time + ?FAMILY_AS_RANK_START_DELAY).

set_family_as_questions(Questions) ->
    erlang:put({?MODULE, family_as_questions}, Questions).
get_family_as_questions() ->
    erlang:get({?MODULE, family_as_questions}).

set_family_name(FamilyName) ->
    erlang:put({?MODULE, family_name}, FamilyName).
get_family_name() ->
    erlang:get({?MODULE, family_name}).

set_now_questions(Question, RefreshTime) ->
    erlang:put({?MODULE, now_questions}, {Question, RefreshTime}).
get_now_questions() ->
    erlang:get({?MODULE, now_questions}).

set_add_exp_time(Time) ->
    erlang:put({?MODULE, add_exp_time}, Time).
get_add_exp_time() ->
    erlang:get({?MODULE, add_exp_time}).

do_map_end() ->
    map_server:kick_all_roles(),
    map_server:delay_shutdown().



do_start_answer(Now) ->
    erlang:send_after(?MAP_SHUTDOWN_TIME * 1000, erlang:self(), {mod, ?MODULE, do_start_answer_i}),
    start_activity(Now).

do_start_answer_i() ->
    [Question|OtherQuestion] = get_family_as_questions(),
    FamilyID = map_common_dict:get_map_extra_id(),
    common_broadcast:bc_top_record_to_family(FamilyID, Question#c_activity_family_as.question),
    set_now_questions(Question, ?FAMILY_AS_REFRESH_TIME + time_tool:now()),
    set_family_as_questions(OtherQuestion).


do_bc_rank_info(RankInfoList) ->
    map_server:send_all_gateway(#m_family_as_rank_toc{rank_list = RankInfoList}).


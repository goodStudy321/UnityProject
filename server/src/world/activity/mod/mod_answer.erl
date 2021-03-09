%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 四月 2018 19:17
%%%-------------------------------------------------------------------
-module(mod_answer).
-author("WZP").
-include("global.hrl").
-include("answer.hrl").
-include("map.hrl").
-include("all_pb.hrl").
-include("activity.hrl").
-include("proto/mod_role_map.hrl").
-include("common.hrl").
-include("common_records.hrl").
-include("letter_template.hrl").
-include("proto/mod_answer.hrl").


%% API
-export([
    init/0,
    activity_prepare/0,
    activity_start/0,
    activity_end/0,
    loop/1,
    handle/1
]).


-export([
    is_activity_open/0,
    role_pre_enter/1,
    role_enter_map/2,
    role_leave_map/1
]).


-export([
    get_activity_mod/0,
    set_role_rank/1,
    get_role_rank_by_id/1,
    get_add_score/3,
    gm_activity_end/0,
    get_reward_by_rank/1,
    attack/3
]).


gm_activity_end() ->
    ?ERROR_MSG("-------do_map_end------~w",[gm_activity_end]),
    do_end_activity_one(),
    activity_end().


init() ->
    ok.

activity_prepare() ->
    AllQuestion = cfg_activity_question:list(),
    AllQuestion2 = lib_tool:random_reorder_list(AllQuestion),
    {ok, Question} = lib_tool:random_elements_from_list(?QUESTION_NUM, AllQuestion2),
    Question2 = format_question(Question, []),
    set_question(Question2),
    set_answer_ctrl(#r_answer_ctrl{cur_extra_id = 0, cur_role_num = 0, extra_id_list = []}),
    catch lib_tool:init_ets(?ETS_ANSWER_RANK, #r_answer_rank.role_id),
    ets:delete_all_objects(?ETS_ANSWER_RANK),
    common_broadcast:bc_role_info_to_world({mod, mod_role_answer, answer_start}).

activity_start() ->
    Now = time_tool:now(),
    set_now_question({#c_activity_question{id = 0}, Now, 0}),
    set_answer_status(#r_answer_status{status = ?WAIT_FOR_ANSWER, start_time = Now, settlement_time = Now + ?ANSWERING_WAIT_TIME}),
    set_rank_first_three([]),
    ExtraID = 1,
    start_map(ExtraID).



handle(Info) ->
    do_handle_info(Info).

loop(Now) ->
    #r_answer_status{status = Status, settlement_time = SettlementTime, start_time = StartTime} = get_answer_status(),
    ?IF(SettlementTime =< Now, loop2(Status, Now, StartTime), ok).

loop2(Status, Now, StartTime) ->
    if
        Status =:= ?WAIT_FOR_ANSWER ->
            #r_answer_ctrl{extra_id_list = ExtraIdList} = get_answer_ctrl(),
            set_answer_extra(ExtraIdList),
            [Question|OtherQuestions] = get_question(),
            {_, _, QuestionNum} = get_now_question(),
            set_now_question({Question, Now, QuestionNum + 1}),
            set_question(OtherQuestions),
            lists:foreach(fun(ExtraID) ->
                PName = map_misc:get_map_pname(?MAP_ANSWER, ExtraID),
                pname_server:send(PName, {mod, mod_map_answer, {send_question, Question, Now, QuestionNum + 1}})
                          end, ExtraIdList),
            set_answer_status(#r_answer_status{status = ?ANSWERING, start_time = StartTime, settlement_time = Now + ?ANSWER_TIME}),
            ok;
        Status =:= ?ANSWERING ->
            #r_answer_ctrl{extra_id_list = ExtraIdList} = get_answer_ctrl(),
            case get_question() of
                [] ->
                    set_answer_status(#r_answer_status{status = ?ANSWERING_END, start_time = StartTime, settlement_time = Now + ?ANSWER_NOTICE_TIME});
                _ ->
                    set_answer_status(#r_answer_status{status = ?ANSWERING_FREE, start_time = StartTime, settlement_time = Now + ?ANSWER_NOTICE_TIME})
            end,
            lists:foreach(fun(ExtraID) ->
                PName = map_misc:get_map_pname(?MAP_ANSWER, ExtraID),
                pname_server:send(PName, {mod, mod_map_answer, question_round_end})
                          end, ExtraIdList),
            ok;
        Status =:= ?ANSWERING_FREE ->
            case get_question() of
                [] ->
                    ok;
                [Question|OtherQuestions] ->
                    #r_answer_ctrl{extra_id_list = ExtraIdList} = get_answer_ctrl(),
                    set_answer_extra(ExtraIdList),
                    {_, _, QuestionNum} = get_now_question(),
                    set_now_question({Question, Now, QuestionNum + 1}),
                    set_question(OtherQuestions),
                    lists:foreach(fun(ExtraID) ->
                        PName = map_misc:get_map_pname(?MAP_ANSWER, ExtraID),
                        pname_server:send(PName, {mod, mod_map_answer, {send_question, Question, Now, QuestionNum + 1}})
                                  end, ExtraIdList),
                    set_answer_status(#r_answer_status{status = ?ANSWERING, start_time = StartTime, settlement_time = Now + ?ANSWER_TIME})
            end,
            ok;
        true ->
            ok
    end.



do_handle_info({role_pre_enter, Level}) ->
    do_role_pre_enter(Level);
do_handle_info({attack, Skill, Pos,RoleID}) ->
    role_misc:info_role(RoleID, {mod, mod_role_answer, {be_hit, Skill, Pos}});
do_handle_info({role_enter_map, RoleID, Name}) ->
    do_role_enter_map(RoleID, Name);
do_handle_info({role_leave_map, RoleID}) ->
    do_role_leave_map(RoleID);
do_handle_info({map_complete_updaterank, ExtraID, AddScores}) ->
    do_rank(ExtraID, AddScores);
do_handle_info(Info) ->
    ?ERROR_MSG("unkonw info : ~w", [Info]).


do_map_end() ->
    #r_answer_ctrl{extra_id_list = ExtraIDList} = get_answer_ctrl(),
    [pname_server:send(map_misc:get_map_pname(?MAP_ANSWER, ExtraID), {mod, mod_map_answer, do_map_end}) || ExtraID <- ExtraIDList].

do_role_pre_enter(Level) ->
    case catch check_pre_enter(Level) of
        {ok, ExtraID} -> %% 之前进入过地图
            {ok, BornPos} = map_misc:get_born_pos(?MAP_ANSWER),
            {ok, ExtraID, BornPos, common_config:get_server_id()};
        {error, ErrCode} ->
            {error, ErrCode}
    end.


check_pre_enter(Level) ->
%%    #r_answer_status{status = Status} = get_answer_status(),
%%    ?IF(Status =/= ?ANSWERING_END, ok, ?THROW_ERR(?ERROR_PRE_ENTER_013)),
    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ?ACTIVITY_ANSWER),
    ?IF(is_activity_open(), ok, ?THROW_ERR(?ERROR_PRE_ENTER_011)),
    ?IF(Level >= MinLevel, ok, ?THROW_ERR(?ERROR_PRE_ENTER_001)),
    #r_answer_ctrl{cur_extra_id = ExtraID, cur_role_num = CurRoleNum} = get_answer_ctrl(),
    case CurRoleNum < ?MAX_EXTRA_ROLE_NUM of
        true ->
            {ok, ExtraID};
        _ ->
            NewExtraID = ExtraID + 1,
            start_map(NewExtraID),
            {ok, NewExtraID}
    end.


do_role_enter_map(RoleID, Name) ->
    Info = case ets:lookup(?ETS_ANSWER_RANK, RoleID) of
               [#r_answer_rank{} = RoleAnswer] ->
                   RoleAnswer#r_answer_rank{in_map = ?ANSWER_IN_MAP};
               _ ->
                   #r_answer_rank{role_id = RoleID, name = Name, in_map = ?ANSWER_IN_MAP}
           end,
    set_role_rank(Info),
    AnswerCtrl = get_answer_ctrl(),
    NewAnswerCtrl = AnswerCtrl#r_answer_ctrl{cur_role_num = 1 + AnswerCtrl#r_answer_ctrl.cur_role_num},
    set_answer_ctrl(NewAnswerCtrl),
    {Question, Time, QuestionNum} = get_now_question(),
    mod_map_answer:send_question_to_one(Question, Time, RoleID, QuestionNum),
    #r_answer_status{status = Status} = get_answer_status(),
    case get_rank_first_three() of
        [] ->
            ok;
        FirstThree ->
            SelfInfo = format_rank_info(Info),
            case Status of
                ?ANSWERING_END ->
                    #r_activity{end_time = EndTime} = world_activity_server:get_activity(?ACTIVITY_ANSWER),
                    common_misc:unicast(RoleID, #m_answer_rank_toc{rank_list = FirstThree, self = SelfInfo, is_end = EndTime});
                _ ->
                    common_misc:unicast(RoleID, #m_answer_rank_toc{rank_list = FirstThree, self = SelfInfo, is_end = 0})
            end
    end.

do_role_leave_map(RoleID) ->
    Status = get_answer_status(),
    case Status#r_answer_status.status =:= ?ANSWERING_END of
        true ->
            ok;
        _ ->
            RoleRank = mod_answer:get_role_rank_by_id(RoleID),
            mod_answer:set_role_rank(RoleRank#r_answer_rank{in_map = ?ANSWER_LEAVE_MAP})
    end.

activity_end() ->
    ets:delete(?ETS_ANSWER_RANK),
    set_answer_status(#r_answer_status{status = ?ANSWERING_END}),
    set_rank_first_three([]).


do_end_activity_one() ->
    RankList = ets:tab2list(?ETS_ANSWER_RANK),
    do_send_reward(RankList),
    do_map_end(),
    log_role_answer(RankList),
    do_answer_broadcast(RankList).

do_rank(ExtraID, AddScores) ->
    add_roles_score(AddScores),
    List = get_answer_extra(),
    case lists:delete(ExtraID, List) of
        [] ->
            do_sort_rank();
        NewList ->
            set_answer_extra(NewList)
    end.

add_roles_score([]) ->
    ok;
add_roles_score([#p_kv{id = RoleID, val = AddScore}|T]) ->
    #r_answer_rank{score = OldScore} = RoleRank = mod_answer:get_role_rank_by_id(RoleID),
    mod_answer:set_role_rank(RoleRank#r_answer_rank{score = OldScore + AddScore, add_score = AddScore}),
    add_roles_score(T).

%%重新排序RANK.
do_sort_rank() ->
    RankList = ets:tab2list(?ETS_ANSWER_RANK),
    NewRankList = lists:sort(
        fun(A, B) ->
            A#r_answer_rank.score > B#r_answer_rank.score
        end, RankList),
    {_, NewRankList2, FirstThree2} = lists:foldl(
        fun(RankInfo, {Rank, NewRankList2, FirstThree}) ->
            NewRankInfo = RankInfo#r_answer_rank{rank = Rank},
            ets:insert(?ETS_ANSWER_RANK, NewRankInfo),
            if
                Rank < 4 ->
                    {Rank + 1, [NewRankInfo|NewRankList2], [NewRankInfo|FirstThree]};
                true ->
                    {Rank + 1, [NewRankInfo|NewRankList2], FirstThree}
            end
        end, {1, [], []}, NewRankList),
%%    ?ERROR_MSG("-----------------NewRankList2----------~w", [NewRankList2]),
%%    ?ERROR_MSG("-----------------FirstThree2----------~w", [FirstThree2]),
    Status = broadcast_rank_info(NewRankList2, FirstThree2),
    ?IF(Status =:= ?ANSWERING_END, do_end_activity_one(), ok).

do_send_reward([]) ->
    ok;
do_send_reward([#r_answer_rank{role_id = RoleID, score = Score, rank = Rank}|T]) ->
    mod_role_confine:answer_rank(Rank, RoleID),
    case get_reward_by_rank(Rank) of
        {ok, GoodsList, ExpRate} ->
            role_misc:info_role(RoleID, mod_role_answer, {answer_add_exp, ExpRate}),
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_ANSWER,
                text_string = [lib_tool:to_list(Score)],
                action = ?ITEM_GAIN_LETTER_ANSWER_REWARD,
                goods_list = GoodsList},
            common_letter:send_cross_letter(RoleID, LetterInfo),
            do_send_reward(T);
        _ ->
            do_send_reward(T)
    end.




start_map(ExtraID) ->
    {ok, MapPID} = map_sup:start_map(?MAP_ANSWER, ExtraID),
    {#c_activity_question{id = QuestionID} = Question, _Time, _} = get_now_question(),
    ?IF(QuestionID =:= 0, ok, pname_server:send(MapPID, {mod, mod_map_answer, {send_now_question, Question}})),
    #r_answer_ctrl{extra_id_list = ExtraIDList} = BattleCtrl = get_answer_ctrl(),
    set_answer_ctrl(BattleCtrl#r_answer_ctrl{cur_extra_id = ExtraID, cur_role_num = 0, extra_id_list = [ExtraID|ExtraIDList]}),
    {ok, MapPID}.

set_answer_ctrl(AnswerCtrl) ->
    erlang:put({?MODULE, answer_ctrl}, AnswerCtrl).
get_answer_ctrl() ->
    erlang:get({?MODULE, answer_ctrl}).

set_answer_extra(ExtraList) ->
    erlang:put({?MODULE, extra}, ExtraList).
get_answer_extra() ->
    erlang:get({?MODULE, extra}).

set_answer_status(Info) ->
    erlang:put({?MODULE, status}, Info).
get_answer_status() ->
    erlang:get({?MODULE, status}).

set_question(RankList) ->
    erlang:put({?MODULE, question}, RankList).
get_question() ->
    erlang:get({?MODULE, question}).


%%题目  {#c_activity_question{id = 0}, Now,Num}
set_now_question(QuestionInfo) ->
    erlang:put({?MODULE, now_question}, QuestionInfo).

get_now_question() ->
    erlang:get({?MODULE, now_question}).

%%设置前三
set_rank_first_three(List) ->
    erlang:put({?MODULE, first_three}, List).

get_rank_first_three() ->
    erlang:get({?MODULE, first_three}).

%% 更变积分数据
set_role_rank(RoleAnswer) ->
    ets:insert(?ETS_ANSWER_RANK, RoleAnswer).

get_role_rank_by_id(RoleID) ->
    case ets:lookup(?ETS_ANSWER_RANK, RoleID) of
        [#r_answer_rank{} = RoleAnswer] ->
            RoleAnswer;
        _ ->
            #r_answer_rank{role_id = RoleID}
    end.



is_activity_open() ->
    #r_activity{status = Status} = get_activity(),
    Status =:= ?STATUS_OPEN.

get_activity() ->
    world_activity_server:get_activity(?ACTIVITY_ANSWER).

role_pre_enter(Level) ->
    Mod = get_activity_mod(),
    Mod:call_mod(?MODULE, {role_pre_enter, Level}).

role_enter_map(RoleID, Name) ->
    Mod = get_activity_mod(),
    Mod:info_mod(?MODULE, {role_enter_map, RoleID, Name}).


attack(Skill, Pos,RoleID)->
    cross_activity_server:info_mod(?MODULE, {attack, Skill, Pos,RoleID}).


role_leave_map(RoleID) ->
    Mod = get_activity_mod(),
    Mod:info_mod(?MODULE, {role_leave_map, RoleID}).


%%根据进入时间得到积分
get_add_score(Now, IntoTime, Type) ->
    Time = IntoTime - Now,
%%    ?ERROR_MSG("-------Time------------------~w",[Time]),
    [Config] = lib_config:find(cfg_answer_exp, 1),
    case Time > 0 of
        true ->

            get_add_score_i(Time, Config, Type);
        _ ->
            get_add_score_i(0, Config, Type)
    end.

get_add_score_i(Time, Config, Type) ->
    [Begin, End] = Config#c_answer_exp.section,
    if
        Time >= Begin andalso End >= Time ->
            Rate = ?IF(Type =:= wrong, Config#c_answer_exp.wrong_exp_rate, Config#c_answer_exp.right_exp_rate),
            {Config#c_answer_exp.score, Rate};
        true ->
            case lib_config:find(cfg_answer_exp, Config#c_answer_exp.id + 1) of
                [] ->
                    Rate = ?IF(Type =:= wrong, Config#c_answer_exp.wrong_exp_rate, Config#c_answer_exp.right_exp_rate),
                    {Config#c_answer_exp.score, Rate};
                [NewConfig] ->
                    get_add_score_i(Time, NewConfig, Type)
            end
    end.


get_reward_by_rank(Rank) ->
    [Config] = lib_config:find(cfg_activity_as_reward, 1),
    get_reward_by_rank(Config, Rank).


get_reward_by_rank(Config, Rank) ->
    [Begin, End] = Config#c_activity_as_reward.section,
    if
        Rank >= Begin andalso End >= Rank ->
            GoodsList = get_reward_goods(lib_tool:string_to_intlist(Config#c_activity_as_reward.reward)),
            {ok, GoodsList, Config#c_activity_as_reward.rate};
        true ->
            case lib_config:find(cfg_activity_as_reward, Config#c_activity_as_reward.id + 1) of
                [] ->
                    false;
                [NewConfig] ->
                    get_reward_by_rank(NewConfig, Rank)
            end
    end.

get_reward_goods(List) ->
    get_reward_goods(List, []).

get_reward_goods([], List) ->
    List;
get_reward_goods([{Type, Num, Bind}|T], List) ->
    Goods = #p_goods{type_id = Type, num = Num, bind = Bind},
    get_reward_goods(T, [Goods|List]).




format_question([], Questions) ->
    Questions;
format_question([{_, Question}|T], Questions) ->
    format_question(T, [Question|Questions]).


%%广播排名
broadcast_rank_info(NewRankList, FirstThree) ->
    FirstThreeInfo = format_rank_info(FirstThree),
    set_rank_first_three(FirstThreeInfo),
    #r_answer_status{status = Status} = get_answer_status(),
    case Status of
        ?ANSWERING_END ->
            broadcast_rank_info2(NewRankList, FirstThreeInfo, ending);
        _ ->
            broadcast_rank_info2(NewRankList, FirstThreeInfo, opening)
    end,
    Status.

broadcast_rank_info2([], _FirstThreeInfo, _Status) ->
    ok;
broadcast_rank_info2([SelfInfo|T], FirstThreeInfo, Status) ->
    case SelfInfo#r_answer_rank.in_map =:= ?ANSWER_IN_MAP of
        true ->
            SelfInfo2 = format_rank_info(SelfInfo),
            case Status of
                opening ->
                    common_misc:unicast(SelfInfo#r_answer_rank.role_id, #m_answer_rank_toc{rank_list = FirstThreeInfo, self = SelfInfo2, is_end = ?ANSWER_IS_NOT_END, add_score = SelfInfo#r_answer_rank.add_score});
                _ ->
                    #r_activity{end_time = EndTime} = world_activity_server:get_activity(?ACTIVITY_ANSWER),
                    common_misc:unicast(SelfInfo#r_answer_rank.role_id, #m_answer_rank_toc{rank_list = FirstThreeInfo, self = SelfInfo2, is_end = EndTime, add_score = SelfInfo#r_answer_rank.add_score})
            end;
        _ ->
            ok
    end,
    broadcast_rank_info2(T, FirstThreeInfo, Status).

format_rank_info(List) when erlang:is_list(List) ->
    format_rank_info(List, []);
format_rank_info(Info) ->
    #r_answer_rank{role_id = RoleID, score = Score, name = Name, rank = Rank} = Info,
    #p_answer_rank{rank = Rank, role_id = RoleID, role_name = Name, score = Score}.

format_rank_info([], List) ->
    List;
format_rank_info([Info|T], List) ->
    #r_answer_rank{role_id = RoleID, score = Score, name = Name, rank = Rank} = Info,
    NewInfo = #p_answer_rank{rank = Rank, role_id = RoleID, role_name = Name, score = Score},
    format_rank_info(T, [NewInfo|List]).

log_role_answer(RankList) ->
    LogList = [
        #log_role_answer{role_id = RoleID, answer_rank = Rank, score = Score}
        || #r_answer_rank{role_id = RoleID, rank = Rank, score = Score} <- RankList],
    background_misc:log(LogList).

do_answer_broadcast(RankList) ->
    RankList2 = lists:sublist(lists:keysort(#r_answer_rank.rank, RankList), 3),
    [common_broadcast:send_world_common_notice(?NOTICE_ANSWER_END, [common_role_data:get_role_name(RoleID), lib_tool:to_list(Rank)]) ||
        #r_answer_rank{role_id = RoleID, rank = Rank} <- RankList2].

get_activity_mod() ->
    activity_misc:get_activity_mod(?ACTIVITY_ANSWER).
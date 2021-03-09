%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 七月 2018 19:25
%%%-------------------------------------------------------------------
-module(mod_family_bt).
-author("WZP").
-include("activity.hrl").
-include("common.hrl").
-include("family_battle.hrl").
-include("map.hrl").
-include("common_records.hrl").
-include("all_pb.hrl").
-include("global.hrl").
-include("family.hrl").
-include("role.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    handle/1,
    activity_prepare/0,
    activity_start/0,
    activity_end/0,
    loop/1
]).

-export([
    set_role_rank/1,
    get_role_rank_by_id/1,
    is_activity_open/0
]).

-export([
    get_vc_config/3,
    get_extra_by_rank/2,
    get_map_pids/0
]).

-export([
    gm_end/0
]).

activity_prepare() ->
    lib_tool:init_ets(?ETS_FAMILY_BATTLE_RANK, #r_family_battle_rank.role_id).

activity_start() ->
    {MapPidS2, ExtraList2} = lists:foldl(
        fun(ExtraID, {MapPidS, ExtraList}) ->
            {Rank1, Rank2} = get_rank_by_extra(ExtraID),
            BattleRankList = world_data:get_family_battle_rank(),
            RankInfo1 = lists:keyfind(Rank1, #c_family_battle_rank.rank, BattleRankList),
            RankInfo2 = lists:keyfind(Rank2, #c_family_battle_rank.rank, BattleRankList),
            if
                RankInfo1 =:= RankInfo2 -> {MapPidS, ExtraList};
                RankInfo1 =:= false andalso RankInfo2 =/= false ->
                    {ok, Pid} = start_map(ExtraID),
                    InfoList = [{?FAMILY_BATTLE_RED, 0, "", 0, 0},
                                {?FAMILY_BATTLE_BLUE, RankInfo2#c_family_battle_rank.family_id, RankInfo2#c_family_battle_rank.family_name, RankInfo2#c_family_battle_rank.power, RankInfo2#c_family_battle_rank.rank}],
                    pname_server:send(Pid, {mod, mod_map_family_bt, {open_info, InfoList}}),
                    {[Pid|MapPidS], [ExtraID|ExtraList]};
                RankInfo1 =/= false andalso RankInfo2 =:= false ->
                    {ok, Pid} = start_map(ExtraID),
                    InfoList = [{?FAMILY_BATTLE_BLUE, 0, "", 0, 0},
                                {?FAMILY_BATTLE_RED, RankInfo1#c_family_battle_rank.family_id, RankInfo1#c_family_battle_rank.family_name, RankInfo1#c_family_battle_rank.power, RankInfo1#c_family_battle_rank.rank}],
                    pname_server:send(Pid, {mod, mod_map_family_bt, {open_info, InfoList}}),
                    {[Pid|MapPidS], [ExtraID|ExtraList]};
                true ->
                    {ok, Pid} = start_map(ExtraID),
                    InfoList = [{?FAMILY_BATTLE_RED, RankInfo1#c_family_battle_rank.family_id, RankInfo1#c_family_battle_rank.family_name, RankInfo1#c_family_battle_rank.power, RankInfo1#c_family_battle_rank.rank},
                                {?FAMILY_BATTLE_BLUE, RankInfo2#c_family_battle_rank.family_id, RankInfo2#c_family_battle_rank.family_name, RankInfo2#c_family_battle_rank.power, RankInfo2#c_family_battle_rank.rank}],
                    pname_server:send(Pid, {mod, mod_map_family_bt, {open_info, InfoList}}),
                    {[Pid|MapPidS], [ExtraID|ExtraList]}
            end
        end, {[], []}, ?FAMILY_BATTLE_ROUND_ONE_MAP),
    set_map_pids(MapPidS2),
    set_extra(ExtraList2),
    Now = time_tool:now(),
    [Config] = lib_config:find(cfg_global, ?FAMILY_BATTLE_GLOBAL),
    [BattleTime, WaitTime, _SleepTime, _] = Config#c_global.list,
    Status = #r_family_battle_status{start_time = Now, end_time = Now + BattleTime + WaitTime, round = ?FAMILY_BATTLE_ROUND_ONE},
    set_status(Status),
    ok.

activity_end() ->
    ets:delete(?ETS_FAMILY_BATTLE_RANK),
    ok.

gm_end() ->
    ExtraList = get_extra(),
    ?ERROR_MSG("--------ExtraList---------------------~w", [ExtraList]),
    [pname_server:send(map_misc:get_map_pname(?MAP_FAMILY_BT, ExtraID), {mod, mod_map_family_bt, do_map_end_i}) || ExtraID <- ExtraList].


start_map(ExtraID) ->
    ?ERROR_MSG("--------ExtraList---------------------~w", [ExtraID]),
    map_sup:start_map(?MAP_FAMILY_BT, ExtraID).

handle(Info) ->
    do_handle_info(Info).


do_handle_info({round_end, Winner, Loser, WinFamilyID, LoseFamilyID, ExtraID}) ->
    do_round_end(Winner, Loser, WinFamilyID, LoseFamilyID, ExtraID);
do_handle_info({family_member_leave, _FamilyID, RoleID}) ->
    ets:delete(?ETS_FAMILY_BATTLE_RANK, RoleID);
do_handle_info(Info) ->
    ?ERROR_MSG("unkonw info : ~w", [Info]).



loop(Now) ->
    #r_family_battle_status{end_time = EndTime, round = Round} = get_status(),
    case Now >= EndTime of
        true ->
            case Round of
                ?FAMILY_BATTLE_ROUND_ONE ->
                    ?ERROR_MSG("-----round_one_end--------------~w", [round_one_end]),
                    round_one_end();
                ?FAMILY_BATTLE_ROUND_SLEEP ->
                    ?ERROR_MSG("-----round_sleep_end--------------~w", [round_sleep_end]),
                    round_sleep_end();
                ?FAMILY_BATTLE_ROUND_TWO ->
                    ?ERROR_MSG("-----round_two_end--------------~w", [round_two_end]),
                    round_two_end();
                _ ->
                    ok
            end;
        _ ->
            ok
    end.



do_round_end(Winner, Loser, WinFamilyID, LoseFamilyID, ExtraID) ->
    Result = get_battle_result(),
    set_battle_result([{ExtraID, Winner, Loser}|Result]),
    List = get_extra(),
    case lists:delete(ExtraID, List) of
        [] ->
            Status = get_status(),
            case Status#r_family_battle_status.round =:= ?FAMILY_BATTLE_ROUND_SLEEP of
                true ->
                    do_round_one_end();
                _ ->
                    do_round_two_end()
            end;
        NewList ->
            set_extra(NewList)
    end,
    do_winner_achievement(WinFamilyID),
    log_family_battle(WinFamilyID, LoseFamilyID).

%%{old , New}   S 神级  X仙级
do_round_one_end() ->
    Result = get_battle_result(),
    ?ERROR_MSG("-do_round_one_end-Result---------------~w", [Result]),
    set_battle_result([]),
    {SWinners2, SLosers2, XWinners2, XLosers2} = lists:foldl(fun({_, Winner, Loser}, {SWinners, SLosers, XWinners, XLosers}) ->
        {SWinners1, XWinners1} = case Winner < 5 of
                                     true ->
                                         {[Winner|SWinners], XWinners};
                                     _ ->
                                         {SWinners, [Winner|XWinners]}
                                 end,
        {SLosers1, XLosers1} = case Loser < 5 of
                                   true ->
                                       {[Loser|SLosers], XLosers};
                                   _ ->
                                       {SLosers, [Loser|XLosers]}
                               end,
        {SWinners1, SLosers1, XWinners1, XLosers1}
                                                             end, {[], [], [], []}, Result),
    SLosers3 = [LoserID || LoserID <- SLosers2, LoserID =/= 0],
    XLosers3 = [LoserID2 || LoserID2 <- XLosers2, LoserID2 =/= 0],
%%    Winners1 = [WinnerID || WinnerID <- SWinners2, WinnerID =/= 0],  此赛区目前规则不会轮空产生0
    XWinners3 = [WinnerID2 || WinnerID2 <- XWinners2, WinnerID2 =/= 0],
    SList = lists:sort(SWinners2) ++ lists:sort(SLosers3),
    XList = lists:sort(XWinners3) ++ lists:sort(XLosers3),
    ?ERROR_MSG("-do_round_one_end-Result---------------~w", [{SList, XList}]),
    {RankID, List1} = lists:foldl(fun(WinnerID, {Rank, NewList}) ->
        {Rank + 1, [{WinnerID, Rank}|NewList]}
                                  end, {1, []}, SList),
    {_, List2} = lists:foldl(fun(Loser2, {Rank2, NewList2}) ->
        {Rank2 + 1, [{Loser2, Rank2}|NewList2]}
                             end, {RankID, []}, XList),
    List3 = List1 ++ List2,
    ?ERROR_MSG("-do_round_one_end List3------------------~w", [List3]),
    RankList = world_data:get_family_battle_rank(),
    ?ERROR_MSG("-do_round_one_end RankList----------------~w", [RankList]),
    NewRankList = lists:foldl(fun(Info, NewRankList) ->
        {_, NewRank} = lists:keyfind(Info#c_family_battle_rank.rank, 1, List3),
        [Info#c_family_battle_rank{rank = NewRank}|NewRankList]
                              end, [], RankList),
    ?ERROR_MSG("-NewRankList----------------~w", [NewRankList]),
    world_data:set_family_battle_rank(NewRankList),
    send_round_reward(NewRankList, 1, []).

%%{old , New}
do_round_two_end() ->
    Result = get_battle_result(),
    ?ERROR_MSG("-do_round_two_end-Result---------------~w", [Result]),
    set_battle_result([]),
    List1 = lists:foldl(fun({ExtraID, Winner, Loser}, List) ->
        List2 = [{Winner, ExtraID div 10}|List],
        %%只有Loser可能为0
        case Loser =:= 0 of
            true ->
                List2;
            _ ->
                [{Loser, ExtraID rem 10}|List2]
        end
                        end, [], Result),
    ?ERROR_MSG("-do_round_two_end List1------------------~w", [List1]),
    RankList = world_data:get_family_battle_rank(),
    ?ERROR_MSG("-RankList-----------------~w", [RankList]),
    NewRankList = lists:foldl(fun(Info, NewRankList) ->
        {_, NewRank} = lists:keyfind(Info#c_family_battle_rank.rank, 1, List1),
        [Info#c_family_battle_rank{rank = NewRank}|NewRankList]
                              end, [], RankList),
    ?ERROR_MSG("-do_round_two_end NewRankList------------------~w", [NewRankList]),
    world_data:set_family_battle_rank(NewRankList),
    send_end_reward(NewRankList).



send_end_reward(RankList) ->
    refresh_temple(RankList),
    send_round_reward(RankList, 2, []).

%%发送区域胜败奖励
send_round_reward([], Round, ActAcc) ->
    %% 触发仙盟争霸活动
    ?IF(Round =:= 2, act_family:family_battle_end(ActAcc), ok),
    ok;
send_round_reward([Info|T], Round, ActAcc) ->
    #c_family_battle_rank{rank = Rank, family_id = FamilyID} = Info,
    ConfigID = get_config_id(Rank, Round),
    [Config] = lib_config:find(cfg_fbt_round_reward, ConfigID),
    List = lib_tool:string_to_intlist(Config#c_fbt_round_reward.reward),
    GoodList = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- List],
    #p_family{members = Members} = mod_family_data:get_family(FamilyID),
    lists:foreach(
        fun(#p_family_member{role_id = RoleID}) ->
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_FAMILY_BT_ROUND,
                text_string = [lib_tool:to_list(Config#c_fbt_round_reward.word)],
                action = ?ITEM_GAIN_LETTER_FB_ROUND,
                goods_list = GoodList
            },
            common_letter:send_letter(RoleID, LetterInfo)
        end, Members),
    %% 该次获得冠军会触发成就
    ?IF(Rank =:= 1 andalso Round =:= 2, [mod_role_achievement:family_win_champion(RoleID) || #p_family_member{role_id = RoleID} <- Members], ok),
    ActAcc2 = ?IF(Rank =< 3, [get_act_family_battle(Rank, Members)|ActAcc], ActAcc),
    send_round_reward(T, Round, ActAcc2).

get_config_id(Rank, Round) ->
    case Round of
        1 ->
            (Rank + 1) div 2;
        2 ->
            case Rank < 5 of
                true ->
                    case Rank rem 2 =:= 1 of
                        true ->
                            1;
                        _ ->
                            2
                    end;
                _ ->
                    case Rank rem 2 =:= 1 of
                        true ->
                            3;
                        _ ->
                            4
                    end
            end
    end.


%%刷新神庙
refresh_temple(RankList) ->
    List = [Info || Info <- RankList, Info#c_family_battle_rank.rank < 4],
    OldTempleList = world_data:get_family_temple(),
    NewTemples = refresh_temple_i(List, OldTempleList, []),
    world_data:set_family_temple(NewTemples),
    BcList = mod_role_family_bt:tran_to_list(NewTemples, []),
    common_broadcast:bc_record_to_world(#m_family_battle_temple_toc{list = BcList}),
    deal_with_temple(OldTempleList, NewTemples).

deal_with_temple(OldTempleList, NewTemples) ->
    remove_old_title(OldTempleList),
    add_title_and_buff(NewTemples).

remove_old_title([]) ->
    ok;
remove_old_title([#r_family_battle_temple{rank = Rank, role_id = RoleID}|T]) ->
    case lib_config:find(cfg_fbt_temple, Rank) of
        [] ->
            remove_old_title(T);
        [Config] ->
            mod_role_title:update_title(Config#c_fbt_temple.title, ?REMOVE_TITLE, RoleID),
            remove_old_title(T)
    end.

add_title_and_buff([]) ->
    ok;
add_title_and_buff([#r_family_battle_temple{rank = Rank, role_id = RoleID}|T]) ->
    case lib_config:find(cfg_fbt_temple, Rank) of
        [] ->
            add_title_and_buff(T);
        [Config] ->
            GoodList = [#p_goods{type_id = Config#c_fbt_temple.title, num = 1, bind = true}],
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_FAMILY_BT_TITLE,
                action = ?ITEM_GAIN_LETTER_FB_TITLE,
                goods_list = GoodList
            },
            common_letter:send_letter(RoleID, LetterInfo),
            mod_role_buff:add_buff([#buff_args{buff_id = Config#c_fbt_temple.buff, from_actor_id = 0}], RoleID),
            add_title_and_buff(T)
    end.

refresh_temple_i([], _OldTempleList, NewTemples) ->
    NewTemples;
refresh_temple_i([Info|T], OldTempleList, NewTemples) ->
    Family = mod_family_data:get_family(Info#c_family_battle_rank.family_id),
    CvTimes = case lists:keyfind(Info#c_family_battle_rank.rank, #r_family_battle_temple.rank, OldTempleList) of
                  false ->
                      send_continuity_victory(Info#c_family_battle_rank.rank, 1, Info#c_family_battle_rank.family_id, 0),
                      1;
                  OldInfo ->
                      case Info#c_family_battle_rank.family_id =:= OldInfo#r_family_battle_temple.family_id of
                          true ->
                              send_continuity_victory(Info#c_family_battle_rank.rank, OldInfo#r_family_battle_temple.cv_time + 1, Info#c_family_battle_rank.family_id, OldInfo#r_family_battle_temple.family_id),
                              OldInfo#r_family_battle_temple.cv_time + 1;
                          _ ->
                              case Info#c_family_battle_rank.rank =:= 1 of
                                  true ->
                                      send_end_continuity_victory(Info#c_family_battle_rank.family_id, OldInfo#r_family_battle_temple.cv_time);
                                  _ ->
                                      ok
                              end,
                              send_continuity_victory(Info#c_family_battle_rank.rank, 1, Info#c_family_battle_rank.family_id, OldInfo#r_family_battle_temple.family_id),
                              1
                      end
              end,
    #p_family_member{role_id = RoleID} = lists:keyfind(?TITLE_OWNER, #p_family_member.title, Family#p_family.members),
    Attr = common_role_data:get_role_attr(RoleID),
    Temple = #r_family_battle_temple{role_id = RoleID, role_name = Attr#r_role_attr.role_name, skin = Attr#r_role_attr.skin_list, rank = Info#c_family_battle_rank.rank,
                                     family_name = Info#c_family_battle_rank.family_name, family_id = Info#c_family_battle_rank.family_id, sex = Attr#r_role_attr.sex, level = Attr#r_role_attr.level,
                                     category = Attr#r_role_attr.category, cv_time = CvTimes},
    refresh_temple_i(T, OldTempleList, [Temple|NewTemples]).

send_continuity_victory(Rank, VctTime, FamilyID, OldFamilyID) ->
    mod_family_battle:family_add_continuity_victory(Rank, VctTime, FamilyID, OldFamilyID).

send_end_continuity_victory(FamilyID, VctTime) ->
    case VctTime =:= 1 of
        true ->
            ok;
        _ ->
            mod_family_battle:family_end_continuity_victory(FamilyID, VctTime)
    end.


get_vc_config(Rank, VctTime, WorldLevel) ->
    List = lib_config:list(cfg_fbt_cv_reward),
    get_vc_config(List, Rank, VctTime, WorldLevel).

get_vc_config([], _Rank, _VctTime, _WorldLevel) ->
    false;
get_vc_config([{_, Info}|T], Rank, VctTimes, WorldLevel) ->
    case Info#c_fbt_cv_reward.rank =:= Rank andalso Info#c_fbt_cv_reward.cv_times =:= VctTimes of
        true ->
            [Min, Max] = Info#c_fbt_cv_reward.world_level,
            case Min =< WorldLevel andalso Max >= WorldLevel of
                true ->
                    Info;
                _ ->
                    get_vc_config(T, Rank, VctTimes, WorldLevel)
            end;
        _ ->
            get_vc_config(T, Rank, VctTimes, WorldLevel)
    end.

round_one_end() ->
    Result = get_battle_result(),
    ExtraList = get_extra(),
    lists:foreach(fun(ExtraID) ->
        case lists:keyfind(ExtraID, 1, Result) of
            false ->
                PName = map_misc:get_map_pname(?MAP_FAMILY_BT, ExtraID),
                pname_server:send(PName, {mod, mod_map_family_bt, round_one_end});
            _ ->
                ok
        end
                  end, ExtraList),
    Status = get_status(),
    [Config] = lib_config:find(cfg_global, ?FAMILY_BATTLE_GLOBAL),
    [_BattleTime, _WaitTime, SleepTime, _] = Config#c_global.list,
    Status2 = #r_family_battle_status{start_time = Status#r_family_battle_status.end_time, end_time = Status#r_family_battle_status.end_time + SleepTime, round = ?FAMILY_BATTLE_ROUND_SLEEP},
    set_status(Status2),
    ok.

round_sleep_end() ->
    ets:delete_all_objects(?ETS_FAMILY_BATTLE_RANK),
    BattleRankList = world_data:get_family_battle_rank(),
    {MapPidS2, ExtraList2} = lists:foldl(
        fun(ExtraID, {MapPidS, ExtraList}) ->
            {Rank1, Rank2} = get_rank_by_extra(ExtraID),
            RankInfo1 = lists:keyfind(Rank1, #c_family_battle_rank.rank, BattleRankList),
            RankInfo2 = lists:keyfind(Rank2, #c_family_battle_rank.rank, BattleRankList),
            if
                RankInfo1 =:= RankInfo2 -> {MapPidS, ExtraList};
                RankInfo1 =:= false andalso RankInfo2 =/= false ->
                    {ok, Pid} = start_map(ExtraID),
                    InfoList = [{?FAMILY_BATTLE_RED, 0, "", 0, 0},
                                {?FAMILY_BATTLE_BLUE, RankInfo2#c_family_battle_rank.family_id, RankInfo2#c_family_battle_rank.family_name, RankInfo2#c_family_battle_rank.power,
                                 RankInfo2#c_family_battle_rank.rank}],
                    pname_server:send(Pid, {mod, mod_map_family_bt, {open_info, InfoList}}),
                    {[Pid|MapPidS], [ExtraID|ExtraList]};
                RankInfo2 =:= false andalso RankInfo1 =/= false ->
                    {ok, Pid} = start_map(ExtraID),
                    InfoList = [{?FAMILY_BATTLE_BLUE, 0, "", 0, 0},
                                {?FAMILY_BATTLE_RED, RankInfo1#c_family_battle_rank.family_id, RankInfo1#c_family_battle_rank.family_name, RankInfo1#c_family_battle_rank.power, RankInfo1#c_family_battle_rank.rank}],
                    pname_server:send(Pid, {mod, mod_map_family_bt, {open_info, InfoList}}),
                    {[Pid|MapPidS], [ExtraID|ExtraList]};
                true ->
                    {ok, Pid} = start_map(ExtraID),
                    InfoList = [{?FAMILY_BATTLE_RED, RankInfo1#c_family_battle_rank.family_id, RankInfo1#c_family_battle_rank.family_name, RankInfo1#c_family_battle_rank.power, RankInfo1#c_family_battle_rank.rank},
                                {?FAMILY_BATTLE_BLUE, RankInfo2#c_family_battle_rank.family_id, RankInfo2#c_family_battle_rank.family_name, RankInfo2#c_family_battle_rank.power, RankInfo2#c_family_battle_rank.rank}],
                    pname_server:send(Pid, {mod, mod_map_family_bt, {open_info, InfoList}}),
                    {[Pid|MapPidS], [ExtraID|ExtraList]}
            end
        end, {[], []}, ?FAMILY_BATTLE_ROUND_TWO_MAP),
    set_map_pids(MapPidS2),
    set_extra(ExtraList2),
    Status = get_status(),
    [Config] = lib_config:find(cfg_global, ?FAMILY_BATTLE_GLOBAL),
    [BattleTime, WaitTime, _SleepTime, _] = Config#c_global.list,
    Status2 = #r_family_battle_status{start_time = Status#r_family_battle_status.end_time, end_time = Status#r_family_battle_status.end_time + BattleTime + WaitTime, round = ?FAMILY_BATTLE_ROUND_TWO},
    set_status(Status2),
    ok.

round_two_end() ->
    Result = get_battle_result(),
    ExtraList = get_extra(),
    lists:foreach(fun(ExtraID) ->
        case lists:keyfind(ExtraID, 1, Result) of
            false ->
                PName = map_misc:get_map_pname(?MAP_FAMILY_BT, ExtraID),
                pname_server:send(PName, {mod, mod_map_family_bt, round_two_end});
            _ ->
                ok
        end
                  end, ExtraList),
    Status = get_status(),
    Status2 = Status#r_family_battle_status{end_time = Status#r_family_battle_status.end_time + 100000, round = ?FAMILY_BATTLE_ROUND_END},
    set_status(Status2),
    ok.

do_winner_achievement(WinFamilyID) ->
    case mod_family_data:get_family(WinFamilyID) of
        #p_family{members = Members} ->
            [mod_role_achievement:family_win(RoleID) || #p_family_member{role_id = RoleID} <- Members];
        _ ->
            ok
    end.

log_family_battle(WinFamilyID, LoseFamilyID) ->
    Log = #log_family_battle{
        win_family_id = WinFamilyID,
        lose_family_id = LoseFamilyID
    },
    background_misc:log(Log).

get_act_family_battle(Rank, Members) ->
    {value, #p_family_member{role_id = OwnerID}, Members2} = lists:keytake(?TITLE_OWNER, #p_family_member.title, Members),
    RoleList = [MemberRoleID || #p_family_member{role_id = MemberRoleID} <- Members2],
    {Rank, OwnerID, RoleList}.


is_activity_open() ->
    #r_activity{status = Status} = get_activity(),
    Status =:= ?STATUS_OPEN.

get_activity() ->
    world_activity_server:get_activity(?ACTIVITY_FAMILY_BATTLE).


set_battle_result(List) ->
    erlang:put({?MODULE, result}, List).

get_battle_result() ->
    case erlang:get({?MODULE, result}) of
        undefined ->
            [];
        List ->
            List
    end.

set_status(Status) ->
    erlang:put({?MODULE, status}, Status).

get_status() ->
    erlang:get({?MODULE, status}).

set_map_pids(List) ->
    erlang:put({?MODULE, pids}, List).

get_map_pids() ->
    erlang:get({?MODULE, pids}).

set_extra(List) ->
    erlang:put({?MODULE, extras}, List).

get_extra() ->
    erlang:get({?MODULE, extras}).


%% 更变积分数据
set_role_rank(Info) ->
    ets:insert(?ETS_FAMILY_BATTLE_RANK, Info).

get_role_rank_by_id(RoleID) ->
    case ets:lookup(?ETS_FAMILY_BATTLE_RANK, RoleID) of
        [#r_family_battle_rank{} = RoleAnswer] ->
            RoleAnswer;
        _ ->
            #r_family_battle_rank{role_id = RoleID}
    end.



get_rank_by_extra(ExtraID) ->
    {ExtraID div 10, ExtraID rem 10}.

get_extra_by_rank(Rank, Round) ->
    case Round of
        1 ->
            case Rank of
                1 -> 13;
                2 -> 24;
                3 -> 13;
                4 -> 24;
                5 -> 57;
                6 -> 68;
                7 -> 57;
                8 -> 68
            end;
        _ ->
            case Rank of
                1 -> 12;
                2 -> 12;
                3 -> 34;
                4 -> 34;
                5 -> 56;
                6 -> 56;
                7 -> 78;
                8 -> 78
            end
    end.

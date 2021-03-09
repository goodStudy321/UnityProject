#!/usr/bin/env escript
%% -*- erlang -*-
-mode(compile).

-export([main/1]).
-include("../../include/mission.hrl").
-include("../../include/global.hrl").
-define(MAX_LEVEL, 1000).
-define(FILE_NAME, "cfg_mission.erl").

main([]) ->
    Path = filename:dirname(escript:script_name()),
    EbinPath = Path ++ "/../../ebin/",
    code:add_path(EbinPath),
    OutPath = Path ++ "/../../config/dyn/",
    gen_mission(OutPath).

gen_mission(OutPath) ->
    {MissionList, MainList, DailyList, MonsterMissions, ListenItems} = get_mission_config(),
    List = [ {Level, []} || Level <- lists:seq(1, ?MAX_LEVEL)],
    Main = gen_level_list(MainList, List),
    {TypeList2, DailyList2, TypeTimes} = gen_daily_list(DailyList),
    T = gen_level_list(TypeList2, List),
    LevelList = merge_level_config(lists:keysort(1, Main), lists:keysort(1, T), []),
    BaseOut = get_base_output(MissionList),
    LevelOut = get_level_output(LevelList),
    MonsterLevelList = gen_monster_level_list(MonsterMissions, List),
    MonsterLevelOut = get_monster_level_output(lists:keysort(1,MonsterLevelList)),
    DailyOut = get_common_output("{daily,", DailyList2),
    TimeOut = get_common_output("{daily_times,", TypeTimes),
    ListenItemOut = get_common_output("{item_missions,", ListenItems),
    Header = "-module(cfg_mission).
-include(\"config.hrl\").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H\n",
    Content = Header ++ BaseOut ++ LevelOut ++ DailyOut ++ TimeOut ++ MonsterLevelOut ++ ListenItemOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?FILE_NAME, Content, [{encoding, utf8}]),
    ok.


get_mission_config() ->
    List = cfg_mission_excel:list(),
    lists:foldl(
        fun({_MissionID, Base}, {Acc1, Acc2, Acc3, Acc4, Acc5}) ->
            #c_mission_excel{
                id = MissionID,
                name = MissionName,
                type = Type,
                sub_type = SubType,
                times = Times,
                rounds = Rounds,
                pre_mission = PreMission,
                next_mission = NextMission,
                min_level = MinLevel,
                max_level = MaxLevel,
                need_family = NeedFamily,
                need_relive_args = ReliveArgs,
                auto_accept = AutoAccept,
                auto_complete = AutoComplete,
                listener_type = ListenerType,
                listener_value = ListenerValue,
                exp_type = ExpType,
                exp = Exp,
                item = Items,
                add_buffs = AddBuffs,
                need_function_id = NeedFunctionID
            } = Base,
            MaxLevel2 = ?IF(MaxLevel =< 0, ?MAX_LEVEL, MaxLevel),
            case get_type_mission(PreMission, Type) of
                main_mission -> %% 主线任务
                    NewAcc2 = [{Type, SubType, MinLevel, MinLevel, MissionID}|Acc2], NewAcc3 = Acc3;
                branch_mission ->
                    NewAcc2 = [{Type, SubType, MinLevel, MaxLevel2, MissionID}|Acc2], NewAcc3 = Acc3;
                daily_mission ->
                    NewAcc2 = Acc2, NewAcc3 = [{Type, SubType, MinLevel, MaxLevel2, Rounds * Times, MissionID}|Acc3];
                _ ->
                    NewAcc2 = Acc2, NewAcc3 = Acc3
            end,
            Listeners = get_listen(ListenerType, ListenerValue),
            case ListenerType =:= ?MISSION_LISTEN_ITEM of
                true ->
                    {NewAcc4, NewAcc5} = get_listen_item_args(MissionID, MinLevel, MaxLevel2, ListenerValue, Acc4, Acc5);
                _ ->
                    NewAcc4 = Acc4,
                    NewAcc5 = Acc5
            end,
            Items2 =
                case Items =:= ?SPECIAL_ITEM_REWARD of
                    true ->
                        [];
                    _ ->
                        [ begin
                              [TypeID, Num, BindNum] = string:tokens(OneReward, ","),
                              {lib_tool:to_integer(TypeID), lib_tool:to_integer(Num), lib_tool:to_integer(BindNum)}
                          end || OneReward <- string:tokens(Items, ";")]
                end,
            Conditions = [{?CONDITION_LEVEL, MinLevel, MaxLevel2}, {?CONDITION_FAMILY, ?NEED_FAMILY(NeedFamily)}],
            Conditions2 =
                case ReliveArgs of
                    [ReliveLevel, ProgressArgs] ->
                        [{?CONDITION_RELIVE_ARGS, ReliveLevel, ProgressArgs}|Conditions];
                    _ ->
                        Conditions
                end,
            Conditions3 = ?IF(Type =:= ?MISSION_TYPE_FAIRY, [{?CONDITION_FAIRY, 1}|Conditions2], Conditions2),
            Conditions4 = ?IF(NeedFunctionID > 0, [{?CONDITION_FUNCTION, NeedFunctionID}|Conditions3], Conditions3),
            Mission =
                #c_mission{
                    id = MissionID,
                    name = MissionName,
                    type = Type,
                    sub_type = SubType,
                    max_times = Rounds * Times,
                    pre_mission = PreMission,
                    next_mission = NextMission,
                    min_level = MinLevel,
                    conditions = Conditions4,
                    auto_accept = AutoAccept,
                    auto_complete = AutoComplete,
                    listeners = Listeners,
                    exp_type = ExpType,
                    exp = Exp,
                    item = Items2,
                    add_buffs = AddBuffs},
            {[Mission|Acc1], NewAcc2, NewAcc3, NewAcc4, NewAcc5}
        end, {[], [], [], [], []}, List).

gen_level_list(BranchList, List) ->
    LevelList = lists:seq(1, ?MAX_LEVEL),
    lists:foldl(
        fun({Type, SubType, MinLevel, MaxLevel, MissionID}, Acc1) ->
            lists:foldl(
                fun(Level, Acc2) ->
                    case Level >= MinLevel andalso Level =< MaxLevel of
                        true ->
                            {value, {Level, NowList}, Remain} = lists:keytake(Level, 1, Acc2),
                            [{Level, [{Type, SubType, MissionID}|NowList]}|Remain];
                        _ ->
                            Acc2
                    end
                end, Acc1, LevelList)
        end, List, BranchList).

gen_daily_list(TypeList) ->
    {TypeList2, TypeTimes} =
        lists:foldl(
            fun({Type, SubType, MinLevel, MaxLevel, AllTimes, MissionID}, {Acc1, Acc2}) ->
                NewAcc1 =
                    case lists:keyfind(SubType, 1, Acc1) of
                        {SubType, Type, LM} ->
                            lists:keyreplace(SubType, 1, Acc1, {SubType, Type, [{MinLevel, MaxLevel, MissionID}|LM]});
                        _ ->
                            [{SubType, Type, [{MinLevel, MaxLevel, MissionID}]}|Acc1]
                    end,
                NewAcc2 = ?IF(lists:keymember(Type, 1, Acc2), Acc2, [{Type, AllTimes}|Acc2]),
                {NewAcc1, NewAcc2}
        end, {[], []}, TypeList),
    {TypeList3, DailyList2} =
        lists:foldl(
            fun({SubType, Type, LM}, {Acc1, Acc2}) ->
                {MinLevel, MaxLevel, DailyList} = gen_type_list2(SubType, LM, ?MAX_LEVEL, 0, []),
                {[{Type, SubType, MinLevel, MaxLevel, []}|Acc1], [{SubType, DailyList}|Acc2]}
            end, {[], []}, TypeList2),
    {TypeList3, DailyList2, TypeTimes}.

gen_type_list2(_SubType, [], MinLevel, MaxLevel, Acc) ->
    {MinLevel, MaxLevel, Acc};
gen_type_list2(SubType, [{MinLevel, MaxLevel, MissionID}|R], MinLevelAcc, MaxLevelAcc, Acc) ->
    case lists:keyfind({MinLevel, MaxLevel}, 1, Acc) of
        {{MinLevel, MaxLevel}, MissionIDList} ->
            Acc2 = lists:keyreplace({MinLevel, MaxLevel}, 1, Acc, {{MinLevel, MaxLevel}, [MissionID|MissionIDList]});
        _ ->
            Acc2 = [{{MinLevel, MaxLevel}, [MissionID]}|Acc]
    end,
    MinLevelAcc2 = ?IF(MinLevel < MinLevelAcc, MinLevel, MinLevelAcc),
    MaxLevelAcc2 = ?IF(MaxLevel > MaxLevelAcc, MaxLevel, MaxLevelAcc),
    gen_type_list2(SubType, R, MinLevelAcc2, MaxLevelAcc2, Acc2).

gen_monster_level_list(MonsterList, List) ->
    LevelList = lists:seq(1, ?MAX_LEVEL),
    lists:foldl(
        fun({Item, MinLevel, MaxLevel}, Acc1) ->
            lists:foldl(
                fun(Level, Acc2) ->
                    case Level >= MinLevel andalso Level =< MaxLevel of
                        true ->
                            {value, {Level, NowList}, Remain} = lists:keytake(Level, 1, Acc2),
                            [{Level, [Item|NowList]}|Remain];
                        _ ->
                            Acc2
                    end
                end, Acc1, LevelList)
        end, List, MonsterList).

merge_level_config([], [], Acc) ->
    Acc;
merge_level_config([{Level, List1}|R1], [{Level, List2}|R2], Acc) ->
    merge_level_config(R1, R2, [{Level, List1 ++ List2}|Acc]).

get_type_mission(0, Type) when Type =:= ?MISSION_TYPE_MAIN ->
    main_mission;
get_type_mission(_PreMission, Type) when Type =:= ?MISSION_TYPE_BRANCH ->
    branch_mission;
get_type_mission(_PreMission, Type) when ?IS_MISSION_LOOP(Type) ->
    daily_mission;
get_type_mission(_, _) ->
    undefined.

get_listen(Type, String) ->
    List = string:tokens(String, "|"),
    lists:foldl(
        fun(Value, Acc) ->
            [get_listen2(Type, string:tokens(Value, ","))|Acc]
        end, [], List).

get_listen2(?MISSION_KILL_MONSTER, [TypeID, _, Num|_]) ->
    {?MISSION_KILL_MONSTER, lib_tool:to_integer(TypeID), lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_SPEAK, [NpcID, _MapID]) ->
    {?MISSION_SPEAK, lib_tool:to_integer(NpcID), lib_tool:to_integer(1), 10000};
get_listen2(?MISSION_COLLECT, [TypeID, _, Num]) ->
    {?MISSION_COLLECT, lib_tool:to_integer(TypeID), lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_MOVE, [Mx, _My, _MapID]) ->
    {?MISSION_MOVE, erlang:abs(lib_tool:to_integer(Mx)), 1, 10000};
get_listen2(?MISSION_RATE, [TypeID, _MapID, Num, _Item, Rate]) ->
    {?MISSION_RATE, lib_tool:to_integer(TypeID), lib_tool:to_integer(Num), lib_tool:to_integer(Rate)};
get_listen2(?MISSION_FRONT, [TypeID, _MapID|_]) ->
    {?MISSION_FRONT, lib_tool:to_integer(TypeID), 1, 10000};
get_listen2(?MISSION_FINISH_COPY, [_CopyType, MapID, Num|_]) ->
    {?MISSION_FINISH_COPY, lib_tool:to_integer(MapID), lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_POWER, [NeedPower|_]) ->
    {?MISSION_POWER, 0, lib_tool:to_integer(NeedPower), 10000};
get_listen2(?MISSION_REFINE, [NeedLevel, Num|_]) ->
    {?MISSION_REFINE, lib_tool:to_integer(NeedLevel), lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_GAIN_EXP, [NeedExp|_]) ->
    {?MISSION_GAIN_EXP, lib_tool:to_integer(NeedExp), 1, 10000};
get_listen2(?MISSION_ACTIVE, [NeedActive|_]) ->
    {?MISSION_ACTIVE, 0, lib_tool:to_integer(NeedActive), 10000};
get_listen2(?MISSION_FRIEND_NUM, [NeedFriendNum|_]) ->
    {?MISSION_FRIEND_NUM, 0, lib_tool:to_integer(NeedFriendNum), 10000};
get_listen2(?MISSION_WORLD_BOSS, [NeedBossLevel, Num|_]) ->
    {?MISSION_WORLD_BOSS, lib_tool:to_integer(NeedBossLevel), lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_OFFLINE_SOLO, [Times|_]) ->
    {?MISSION_OFFLINE_SOLO, 0, lib_tool:to_integer(Times), 10000};
get_listen2(?MISSION_COMPOSE, [NeedTypeID, NeedTimes|_]) ->
    {?MISSION_COMPOSE, lib_tool:to_integer(NeedTypeID), lib_tool:to_integer(NeedTimes), 10000};
get_listen2(?MISSION_ALL_REFINE_LEVEL, [NeedLevel|_]) ->
    {?MISSION_ALL_REFINE_LEVEL, 0, lib_tool:to_integer(NeedLevel), 10000};
get_listen2(?MISSION_FINISH_DAILY_MISSION, [NeedType, Times|_]) ->
    {?MISSION_FINISH_DAILY_MISSION, lib_tool:to_integer(NeedType), lib_tool:to_integer(Times), 10000};
get_listen2(?MISSION_LISTEN_ITEM, [_MonsterTypeID, _MapID, Num, ItemTypeID, _Rate|_]) ->
    {?MISSION_LISTEN_ITEM, lib_tool:to_integer(ItemTypeID), lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_CONFINE, [ConfineID|_]) ->
    {?MISSION_CONFINE, lib_tool:to_integer(ConfineID), 1, 10000};
get_listen2(?MISSION_FAMILY_MISSION, [Num|_]) ->
    {?MISSION_FAMILY_MISSION, 0, lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_FAMILY_ESCORT, [Num|_]) ->
    {?MISSION_FAMILY_ESCORT, 0, lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_FAMILY_ROB_ESCORT, [Num|_]) ->
    {?MISSION_FAMILY_ROB_ESCORT, 0, lib_tool:to_integer(Num), 10000};
get_listen2(?MISSION_KILL_FIVE_ELEMENT_BOSS, [NeedBossLevel, Num|_]) ->
    {?MISSION_KILL_FIVE_ELEMENT_BOSS, lib_tool:to_integer(NeedBossLevel), lib_tool:to_integer(Num), 10000};
get_listen2(Type, _) ->
    {Type, 0, 0, 10000}.

get_listen_item_args(MissionID, MinLevel, MaxLevel, ListenerValue, MonsterMissions, ListenItems) ->
    List = string:tokens(ListenerValue, "|"),
    lists:foldl(
        fun(String, {MonsterLevelAcc, ListenItemsAcc}) ->
            [_MonsterTypeID, _MapID, _Num, ItemTypeID, Rate|_] = string:tokens(String, ","),
            ItemTypeID2 = lib_tool:to_integer(ItemTypeID),
            Rate2 = lib_tool:to_integer(Rate),
            MonsterItem = #r_mission_item_monster{
                mission_id = MissionID,
                item_type_id = ItemTypeID2,
                item_rate = Rate2
            },
            MonsterLevelAcc2 = [{MonsterItem, MinLevel, MaxLevel}|MonsterLevelAcc],
            ListenItemsAcc2 = get_listen_item(ItemTypeID2, MissionID, ListenItemsAcc),
            {MonsterLevelAcc2, ListenItemsAcc2}
        end, {MonsterMissions, ListenItems}, List).

get_listen_item(ItemTypeID, MissionID, ListenItems) ->
    case lists:keyfind(ItemTypeID, 1, ListenItems) of
        {ItemTypeID, MissionList} ->
            lists:keyreplace(ItemTypeID, 1, ListenItems, [MissionID|MissionList]);
        _ ->
            [{ItemTypeID, [MissionID]}|ListenItems]
    end.
%%%

get_base_output(MissionList) ->
    lists:foldl(
        fun(#c_mission{id = MissionID} = Mission, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(MissionID) ++ ", " ++ lib_tool:to_output(Mission) ++ ")\n",
            Output ++ Acc
        end, [], MissionList).

get_level_output(List) ->
    lists:foldl(
        fun({Level, LevelList}, Acc) ->
            Output = "?C({level, " ++ lib_tool:to_output(Level) ++ "}, " ++ lib_tool:to_output(LevelList) ++ ")\n",
            Output ++ Acc
        end, [], List).

get_monster_level_output(List) ->
    lists:foldl(
        fun({Level, LevelList}, Acc) ->
            Output = "?C({monster_level, " ++ lib_tool:to_output(Level) ++ "}, " ++ lib_tool:to_output(LevelList) ++ ")\n",
            Output ++ Acc
        end, [], List).

get_common_output(Key, List) ->
    lists:foldl(
        fun({Type, MissionList}, Acc) ->
            Output = "?C("++ Key ++ lib_tool:to_output(Type) ++ "}, " ++ lib_tool:to_output(MissionList) ++ ")\n",
            Output ++ Acc
        end, [], List).

#!/usr/bin/env escript
%% -*- erlang -*-
%% vim: set ft=erlang:
-export([main/1]).
-include("../../include/achievement.hrl").
-include("../../include/global.hrl").
-define(FILE_NAME, "cfg_achievement.erl").

main([]) ->
    Path = filename:dirname(escript:script_name()),
    EbinPath = Path ++ "/../../ebin/",
    code:add_path(EbinPath),
    OutPath = Path ++ "/../../config/dyn/",
    gen_achievement(OutPath).

gen_achievement(OutPath) ->
    {AchievementList, TypeList, ConditionList} = get_achievement_args(),
    BaseOut = get_base_output(AchievementList),
    TypeOut = get_common_output("{conditon_type, ", TypeList),
    ConditionOut = get_max_output(ConditionList),
    Header = "-module(cfg_achievement).
-include(\"config.hrl\").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H\n",
    Content = Header ++ BaseOut ++ TypeOut ++ ConditionOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?FILE_NAME, Content, [{encoding, utf8}]),
    ok.

get_achievement_args() ->
    List = cfg_achievement_excel:list(),
    lists:foldl(
        fun({ID, #c_achievement{condition_type = ConditionType, condition_id = ConditionID, condition_args = Args} = Config}, {AchievementAcc, TypeAcc, ConditionAcc}) ->
            TypeAcc2 =
                case lists:keyfind(ConditionType, 1, TypeAcc) of
                    {ConditionType, IDList} ->
                        lists:keyreplace(ConditionType, 1, TypeAcc, {ConditionType, [ID|IDList]});
                    _ ->
                        [{ConditionType, [ID]}|TypeAcc]
                end,
            Key = {ConditionType, ConditionID},
            ConditionAcc2 =
                case lists:keyfind(Key, 1, ConditionAcc) of
                    {Key, OldVal} ->
                        case Args > OldVal of
                            true ->
                                lists:keyreplace(Key, 1, ConditionAcc, {Key, Args});
                            _ ->
                                ConditionAcc
                        end;
                    _ ->
                        [{Key, Args}|ConditionAcc]
                end,
            {[Config|AchievementAcc], TypeAcc2, ConditionAcc2}
        end, {[], [], []}, List).

get_base_output(MissionList) ->
    lists:foldl(
        fun(#c_achievement{id = AchievementID} = Config, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(AchievementID) ++ ", " ++ lib_tool:to_output(Config) ++ ")\n",
            Output ++ Acc
        end, [], MissionList).

get_max_output(List) ->
    lists:foldl(
        fun({{Type, ID}, MissionList}, Acc) ->
            Output = "?C({max_val, "++ lib_tool:to_output(Type) ++ ", " ++ lib_tool:to_output(ID) ++ "}, " ++ lib_tool:to_output(MissionList) ++ ")\n",
            Output ++ Acc
        end, [], List).

get_common_output(Key, List) ->
    lists:foldl(
        fun({Type, MissionList}, Acc) ->
            Output = "?C("++ Key ++ lib_tool:to_output(Type) ++ "}, " ++ lib_tool:to_output(MissionList) ++ ")\n",
            Output ++ Acc
        end, [], List).

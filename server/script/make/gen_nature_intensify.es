#!/usr/bin/env escript
%% -*- erlang -*-
%% vim: set ft=erlang:
-export([main/1]).
-include("../../include/nature.hrl").
-include("../../include/global.hrl").
-define(FILE_NAME, "cfg_new_nature_intensify.erl").

main([]) ->
    Path = filename:dirname(escript:script_name()),
    EbinPath = Path ++ "/../../ebin/",
    code:add_path(EbinPath),
    OutPath = Path ++ "/../../config/dyn/",
    gen_achievement(OutPath).

gen_achievement(OutPath) ->
    {AchievementList, ConditionList} = get_nature_intensify(),
    BaseOut = get_base_output(AchievementList),
    ConditionOut = get_max_output(ConditionList),

    Header =
        "-module(cfg_new_nature_intensify).
-include(\"config.hrl\").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H\n",

    Content = Header ++ BaseOut ++ ConditionOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?FILE_NAME, Content, [{encoding, utf8}]),
    ok.

get_nature_intensify() ->
    List = cfg_nature_intensify:list(),
    lists:foldl(
        fun({ID, #c_nature_intensify{place = Place, level = Level} = Config}, {AchievementAcc, ConditionAcc}) ->
            Key = {Place, Level},
            ConditionAcc2 =
                case lists:keyfind(Key, 1, ConditionAcc) of
                    {Key, _OldVal} ->
                        lists:keyreplace(Key, 1, ConditionAcc, {Key, ID});
                    _ ->
                        [{Key, ID} | ConditionAcc]
                end,
            {[Config | AchievementAcc], ConditionAcc2}
        end, {[], []}, List).

get_base_output(MissionList) ->
    lists:foldl(
        fun(#c_nature_intensify{intensify_id = IntensifyID} = Config, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(IntensifyID) ++ ", " ++ lib_tool:to_output(Config) ++ ")\n",
            Output ++ Acc
        end, [], MissionList).

get_max_output(List) ->
    lists:foldl(
        fun({{Type, ID}, MissionList}, Acc) ->
            Output = "?C({get_id, "++ lib_tool:to_output(Type) ++ ", " ++ lib_tool:to_output(ID) ++ "}, " ++ lib_tool:to_output(MissionList) ++ ")\n",
            Output ++ Acc
        end, [], List).

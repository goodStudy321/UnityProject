#!/usr/bin/env escript
%% -*- erlang -*-
%% vim: set ft=erlang:
-export([main/1]).
-include("../../include/role.hrl").
-include("../../include/global.hrl").
-define(RUNE_TREASURE, "cfg_rune_treasure.erl").

main([]) ->
    Path = filename:dirname(escript:script_name()),
    EbinPath = Path ++ "/../../ebin/",
    code:add_path(EbinPath),
    OutPath = Path ++ "/../../config/dyn/",
    gen_rune_treasure(OutPath).

gen_rune_treasure(OutPath) ->
    {TreasureList, BoxList} = get_rune_treasure_args(),
    BaseOut = get_base_output(TreasureList),
    BoxOut = get_box_output(BoxList),
    Header = "-module(cfg_rune_treasure).
-include(\"config.hrl\").
-export[find/1].
?CFG_H\n",
    Content = Header ++ BaseOut ++ BoxOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?RUNE_TREASURE, Content, [{encoding, utf8}]),
    ok.

get_rune_treasure_args() ->
    List = cfg_rune_treasure_excel:list(),
    lists:foldl(
        fun({ID, Config}, {BaseAcc, BoxAcc}) ->
            #c_rune_treasure{id = ID, box_id = BoxID} = Config,
            case lists:keyfind(BoxID, 1, BoxAcc) of
                {BoxID, IDList} ->
                    BoxAcc2 = lists:keyreplace(BoxID, 1, BoxAcc, {BoxID, [ID|IDList]});
                _ ->
                    BoxAcc2 = [{BoxID, [ID]}|BoxAcc]
            end,
            {[Config|BaseAcc], BoxAcc2}
        end, {[], []}, List).

get_base_output(MissionList) ->
    lists:foldl(
        fun(#c_rune_treasure{id = ID} = Config, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(ID) ++ ", " ++ lib_tool:to_output(Config) ++ ")\n",
            Output ++ Acc
        end, [], MissionList).

get_box_output(List) ->
    lists:foldl(
        fun({BoxID, IDList}, Acc) ->
            Output = "?C({box_id, " ++ lib_tool:to_output(BoxID) ++ "}, " ++ lib_tool:to_output(IDList) ++ ")\n",
            Output ++ Acc
        end, [], List).
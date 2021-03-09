#!/usr/bin/env escript
%% -*- erlang -*-
%% vim: set ft=erlang:
-export([main/1]).
-include("../../include/drop.hrl").
-include("../../include/global.hrl").
-define(FILE_NAME, "cfg_special_drop.erl").

main([]) ->
    Path = filename:dirname(escript:script_name()),
    EbinPath = Path ++ "/../../ebin/",
    code:add_path(EbinPath),
    OutPath = Path ++ "/../../config/dyn/",
    gen_special_drop(OutPath).

gen_special_drop(OutPath) ->
    {SpecialList, GroupList} = gen_special_drop_args(),
    BaseOut = get_base_output(SpecialList),
    GroupOut = get_group_output(GroupList),
    Header = "-module(cfg_special_drop).
-include(\"config.hrl\").
-export[find/1].
?CFG_H\n",
    Content = Header ++ BaseOut ++ GroupOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?FILE_NAME, Content, [{encoding, utf8}]),
    ok.

gen_special_drop_args() ->
    List = cfg_special_drop_excel:list(),
    lists:foldl(
        fun({_ID, #c_special_drop{index = Index, drop_group = DropGroupID} = Config}, {Acc, GroupAcc}) ->
            GroupAcc2 =
                case lists:keyfind(DropGroupID, 1, GroupAcc) of
                    {_GroupID, IndexList} ->
                        lists:keyreplace(DropGroupID, 1, GroupAcc, {DropGroupID, [Index|IndexList]});
                    _ ->
                        [{DropGroupID, [Index]}|GroupAcc]
                end,
            {[Config|Acc], GroupAcc2}
        end, {[], []}, List).

get_base_output(MissionList) ->
    lists:foldl(
        fun(#c_special_drop{index = ID} = Config, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(ID) ++ ", " ++ lib_tool:to_output(Config) ++ ")\n",
            Output ++ Acc
        end, [], MissionList).

get_group_output(List) ->
    lists:foldl(
        fun({GroupID, IndexList}, Acc) ->
            Output = "?C({drop_group_index, "++ lib_tool:to_output(GroupID) ++ "}, " ++ lib_tool:to_output(IndexList) ++ ")\n",
            Output ++ Acc
        end, [], List).

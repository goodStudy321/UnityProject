#!/usr/bin/env escript
%% -*- erlang -*-
%% vim: set ft=erlang:
-export([main/1]).
-include("../../include/drop.hrl").
-include("../../include/global.hrl").
-define(FILE_NAME, "cfg_drop_item.erl").

main([]) ->
    Path = filename:dirname(escript:script_name()),
    EbinPath = Path ++ "/../../ebin/",
    code:add_path(EbinPath),
    OutPath = Path ++ "/../../config/dyn/",
    gen_drop_item(OutPath).

gen_drop_item(OutPath) ->
    DropItemList = get_drop_item_list(),
    BaseOut = get_base_output(DropItemList),
    Header = "-module(cfg_drop_item).
-include(\"config.hrl\").
-export[find/1].
?CFG_H\n",
    Content = Header ++ BaseOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?FILE_NAME, Content, [{encoding, utf8}]),
    ok.

get_drop_item_list() ->
    List = cfg_drop_item_excel:list(),
    lists:foldl(
        fun({IndexID, Config}, Acc) ->
            #c_drop_item_excel{
                all_num = AllNum,
                all_refresh_hours = AllRefreshHours,
                personal_num = PersonalNum,
                personal_refresh_hours = PersonalRefreshHours,
                drop_list = DropList
            } = Config,
            AddList = [ {DropID, #c_drop_item{
                index_id = IndexID,
                all_num = AllNum,
                all_refresh_hours = AllRefreshHours,
                personal_num = PersonalNum,
                personal_refresh_hours = PersonalRefreshHours}} || DropID <- DropList],
            AddList ++ Acc
        end, [], List).

get_base_output(DropItemList) ->
    lists:foldl(
        fun({Key, Config}, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(Key) ++ ", " ++ lib_tool:to_output(Config) ++ ")\n",
            Output ++ Acc
        end, [], DropItemList).
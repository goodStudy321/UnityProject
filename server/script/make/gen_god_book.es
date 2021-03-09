#!/usr/bin/env escript
%% -*- erlang -*-
%% vim: set ft=erlang:
-export([main/1]).
-include("../../include/god_book.hrl").
-include("../../include/global.hrl").
-define(FILE_NAME, "cfg_god_book.erl").

main([]) ->
    Path = filename:dirname(escript:script_name()),
    EbinPath = Path ++ "/../../ebin/",
    code:add_path(EbinPath),
    OutPath = Path ++ "/../../config/dyn/",
    gen_god_book(OutPath).

gen_god_book(OutPath) ->
    {GodBookList, TypeList, ConditionList} = get_god_book_args(),
    BaseOut = get_base_output(GodBookList),
    TypeOut = get_type_output(TypeList),
    ConditionOut = get_condition_output(ConditionList),
    Header = "-module(cfg_god_book).
-include(\"config.hrl\").
-export[find/1].
?CFG_H\n",
    Content = Header ++ BaseOut ++ TypeOut ++ ConditionOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?FILE_NAME, Content, [{encoding, utf8}]),
    ok.

get_god_book_args() ->
    List = cfg_god_book_excel:list(),
    lists:foldl(
        fun({ID, #c_god_book{type = Type, condition_type = ConditionType} = Config}, {GodBookAcc, TypeAcc, ConditionTypeAcc}) ->
            case lists:keyfind(Type, 1, TypeAcc) of
                {Type, AccIDList} ->
                    TypeAcc2 = lists:keyreplace(Type, 1, TypeAcc, {Type, [ID|AccIDList]});
                _ ->
                    TypeAcc2 = [{Type, [ID]}|TypeAcc]
            end,
            case lists:keyfind(ConditionType, 1, ConditionTypeAcc) of
                {ConditionType, TypeIDList} ->
                    case lists:keyfind(Type, 1, TypeIDList) of
                        {Type, IDList} ->
                            TypeIDList2 = lists:keyreplace(Type, 1, TypeIDList, {Type, [ID|IDList]});
                        _ ->
                            TypeIDList2 = [{Type, [ID]}]
                    end,
                    ConditionTypeAcc2 = lists:keyreplace(ConditionType, 1, ConditionTypeAcc, {ConditionType, TypeIDList2});
                _ ->
                    ConditionTypeAcc2 = [{ConditionType, [{Type, [ID]}]}|ConditionTypeAcc]
            end,
            {[Config|GodBookAcc], TypeAcc2, ConditionTypeAcc2}
        end, {[], [], []}, List).

get_base_output(MissionList) ->
    lists:foldl(
        fun(#c_god_book{id = GodBookID} = Config, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(GodBookID) ++ ", " ++ lib_tool:to_output(Config) ++ ")\n",
            Output ++ Acc
        end, [], MissionList).

get_type_output(List) ->
    lists:foldl(
        fun({Type, IDList}, Acc) ->
            Output = "?C({type, " ++ lib_tool:to_output(Type) ++ "}, " ++ lib_tool:to_output(IDList) ++ ")\n",
            Output ++ Acc
        end, [], List).

get_condition_output(ConditionList) ->
    lists:foldl(
        fun({ConditionType, IDList}, Acc) ->
            Output = "?C({condition_type, " ++ lib_tool:to_output(ConditionType) ++ "}, " ++ lib_tool:to_output(IDList) ++ ")\n",
            Output ++ Acc
        end, [], ConditionList).

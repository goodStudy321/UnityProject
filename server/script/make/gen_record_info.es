#!/usr/bin/env escript
%% -*- erlang -*-
%% vim: set ft=erlang:

%%%-------------------------------------------------------------------
%%% File        : record_info.erl
%%% Author      : 纪秀峰 jixiuf@gmail.com
%%% Description : utilities for manipulating records
%%%
%%% Created     :  2 Sep 2008 by Gordon Guthrie
%%%-------------------------------------------------------------------
%% http://trapexit.org/Match%5FSpecifications%5FAnd%5FRecords%5F%28Dynamically!%29
%% http://forum.trapexit.org/viewtopic.php?p=21790

-define(DEST_DIR, "src/common").                     %relative to ebin/
-define(MODULENAME, "record_info").
-define(INCLUDE_CMD_IN_DEST_MODULE, "").

-export([main/1]).


main([]) ->
    FilePathsT = filelib:wildcard("include/*.hrl"),
    FilePathsProto = filelib:wildcard("include/proto/*.hrl"),
    FilePaths = FilePathsT ++ FilePathsProto,
    Trees = [begin
                 {ok, Tree} = epp:parse_file(I, ["include/"], []),
                 Tree
             end || I <- FilePaths],
    Tree2 = lists:usort(lists:append(Trees)),
    Src = make_src(Tree2),
    ok = file:write_file(filename:join([?DEST_DIR, ?MODULENAME]) ++ ".erl", list_to_binary(Src)).

make_src(Tree) -> make_src(Tree, []).

make_src([], Acc) ->
    top_and_tail([
                  make_info(Acc, []),
                  "\n"
                 ]);
make_src([{attribute, _, record, Record} | T], Acc) -> make_src(T, [Record | Acc]);
make_src([_H | T], Acc) -> make_src(T, Acc).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
make_info([], Acc1) ->
    Head = "%% get all field name of a record\n",
    Tail1 = "fields(_Other) -> [].\n",
    [Head | lists:reverse([Tail1 | Acc1])];
make_info([{RecName, Def} | T], Acc1) ->
    Fields = lists:map(fun(RecordField) ->                  
                               %{record_field,3,{atom,3,name}},or {record_field,2,{atom,2,classe},{string,2,"asdf"}}
                               %{typed_record_field,{record_field,829,{atom,829,role_id},{integer,829,0}},{type,829,non_neg_integer,[]}}
                               R = case element(1, RecordField) of
                                       record_field ->
                                           RecordField;
                                       typed_record_field ->
                                           element(2, RecordField)
                                   end,
                               {atom, _Index, Field} = element(3, R),
                               Field
                       end, Def),
    %% [F|| {record_field,_Num,{atom,_Num2,F}} <- Def ],
    Cause = "fields(" ++ atom_to_list(RecName) ++ ") -> " ++
    io_lib:format("~p", [Fields]) ++ ";\n",
    make_info(T, [Cause | Acc1])
    .


top_and_tail(Acc1) ->
    Top = "%% This module automatically generated - do not edit\n" ++
    "\n" ++
    "%%% This module provides utilities for getting info about records\n" ++
    "%% -record(user,[id,name,age]).\n" ++

    "%% fields(user)==[id,name,age]\n" ++
    "\n" ++
    "-module(" ++ ?MODULENAME ++ ").\n" ++
    "\n" ++
    ?INCLUDE_CMD_IN_DEST_MODULE ++
    "\n" ++
    "-export([fields/1]).\n" ++
    "\n",
    Top ++ lists:flatten(Acc1).

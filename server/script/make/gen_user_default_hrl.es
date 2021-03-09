#!/usr/bin/env escript
%% -*- erlang -*-

-export([main/1]).


-define(HEADER_FILES_PATH, "./include/*.hrl").
-define(HEADER_PROTO_FILES_PATH, "./include/proto/*.hrl").
-define(HEADER_PROTO_PATH, "proto/").
-define(USER_DEFAULT_HRL, "./include/user_default.hrl").

main([]) ->
    FilePaths = filelib:wildcard(?HEADER_FILES_PATH),
    ProtoPath = filelib:wildcard(?HEADER_PROTO_FILES_PATH),
    FileList1 = [filename:basename(I) || I <- FilePaths],
    FileList2 = [ ?HEADER_PROTO_PATH ++ filename:basename(I)|| I <- ProtoPath],
    make_header_file(FileList1 ++ FileList2).


make_header_file(FileList) ->
    Top = "%% This module automatically generated - do not edit\n\n",
    Code =
        lists:foldr(
          fun(File, Acc) ->
              if
                  File =:= "user_default.hrl" orelse File =:= "proto.hrl" ->
                      Acc;
                  true ->
                      lists:concat(["-include(\"",  File, "\").\n", Acc])
              end
          end, [], FileList),
    Content = erlang:list_to_binary(["-ifndef(USER_DEFAULT_HRL).\n-define(USER_DEFAULT_HRL, true).\n\n", Top, Code, "\n-endif."]),
    case file:read_file(?USER_DEFAULT_HRL) of
        {ok, Content} -> ignore;
        _ ->
            file:write_file(?USER_DEFAULT_HRL, Content, [{encoding, utf8}])
    end,
    ok.
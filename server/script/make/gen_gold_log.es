#!/usr/bin/env escript
%% -*- erlang -*-
-mode(compile).
-export([main/1]).
-define(EXIT, halt(1)).
-define(E(A, Y), io:format( "[~w]:" ++  A, [?LINE|Y])).
-define(CHECK_FILE(FILE), case filelib:is_file(FILE) of true -> ok; _ -> ?E("file:~s not exist ~n~n", [FILE]), ?EXIT end).
-define(GOLD_PATTERN, "^-define\\([^,]*,[\\s]*([0-9]+)[^%]*%%\\s*+([^%\n]+)\\s*$" ).
-define(ACTION_PATTERN, "^-define\\([^,]*,[\\s]*([0-9]+)[^%]*%%\\s*+([^%\n]+)\\s*$").
-define(OUT_FILE, "./config/dyn/cfg_gold_log.erl").
-define(BEHAVIOR_FILE, "./include/behavior_log.hrl").

-define(WEB_OUT_DIR, "./../web/admin/files/config/").

main([]) ->
    ?CHECK_FILE(?BEHAVIOR_FILE),
    GoldHeader = "-module(cfg_gold_log).
-include(\"config.hrl\").
-export[find/1].
?CFG_H\n",
    GoldEnd = "?CFG_E.",
    {ok, S} = file:open(?BEHAVIOR_FILE, [read, {encoding, latin1}]),
    {ok, GoldPattern} = re:compile(?GOLD_PATTERN),
    GoldBody = read_gold_body(io:get_line(S, ''), S, GoldPattern, []),
    Str = GoldHeader ++ GoldBody ++ GoldEnd,
    file:write_file(?OUT_FILE, Str, [{encoding, latin1}]),
    file:close(S),

    {ok, S2} = file:open(?BEHAVIOR_FILE, [read, {encoding, latin1}]),
    {ok, ActionPattern} = re:compile(?ACTION_PATTERN),
    ActionBody = read_action_body(io:get_line(S2, ''), S2, ActionPattern, []),
    ActionStr = ActionBody,
    filelib:ensure_dir(?WEB_OUT_DIR),
    file:write_file(?WEB_OUT_DIR ++ "excel_log_action.php", ActionStr, [{encoding, latin1}]),
    file:close(S2),
    ok.

read_gold_body(eof, _S, _RePattern, Res) ->
    Res;
read_gold_body(LineStr, S, RePattern, Res) ->
    case re:run(LineStr, RePattern) of
        {match, [_, {CodeIndex, CodeLen}, {TextIndex, TextLen}]} -> %% 用replace也不错
            CodeStr = string:substr(LineStr, CodeIndex + 1, CodeLen),
            TextStr = string:substr(LineStr, TextIndex + 1, TextLen),
            NewLineStr = "?C(" ++ CodeStr ++ ", \"" ++ TextStr ++ "\")\n",
            NewRes = [NewLineStr|Res];
        _Err ->
            NewRes = Res
    end,
    read_gold_body(io:get_line(S,''), S, RePattern, NewRes).

read_action_body(eof, _S, _RePattern, Res) ->
    Res;
read_action_body(LineStr, S, RePattern, Res) ->
    case re:run(LineStr, RePattern) of
        {match, [_, {CodeIndex, CodeLen}, {TextIndex, TextLen}]} -> %% 用replace也不错
            CodeStr = string:substr(LineStr, CodeIndex + 1, CodeLen),
            TextStr = string:substr(LineStr, TextIndex + 1, TextLen),
            NewLineStr = CodeStr ++ "=" ++ TextStr ++ "||\n",
            NewRes = [NewLineStr|Res];
        _Err ->
            NewRes = Res
    end,
    read_action_body(io:get_line(S,''), S, RePattern, NewRes).

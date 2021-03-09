#!/usr/bin/env escript
%% -*- erlang -*-
%% vim: set ft=erlang:
-mode(compile).
-export([main/1]).
-define(START_JSON, "/config/start_config.json").
-define(COMMON_CONFIG, "/setting/common.config").

main([BaseDir, Fun|Args]) ->
    application:start(inets),
    set_base_dir(BaseDir),
    if
        Fun =:= "get_common_config" ->
            get_common_config(Args);
        Fun =:= "cfile" ->
            cfile(Args)
    end.

%%%===================================================================
%%% get_common_config start
%%%===================================================================
get_common_config(KeyList) ->
    ConfigList = get_common_config_list(),
    ValueList = get_common_config2(KeyList, ConfigList, []),
    String = get_out_value(ValueList, []),
    io:format("~s", [String]).

get_common_config2([], _ConfigList,Acc) ->
    lists:reverse(Acc);
get_common_config2([Key|R], ConfigList, Acc) ->
    {ok, Value} = get_config_by_key(Key, ConfigList),
    get_common_config2(R, ConfigList, [Value|Acc]).

get_out_value([], Acc) ->
    Acc;
get_out_value([T|R], []) ->
    get_out_value(R, T);
get_out_value([T|R], Acc) ->
    Acc2 = Acc ++ " " ++ T,
    get_out_value(R, Acc2).

get_config_by_key(Key, ConfigList) ->
    case get_config(Key, ConfigList) of
        {ok, Value} ->
            {ok, Value};
        _ ->
            io:format("Key not found:~w~n", [Key]),
            erlang:halt(0)
    end.

get_config(Key, List) ->
    case lists:keyfind(to_atom(Key), 1, List) of
        {_, Value} ->
            {ok, to_list(Value)};
        _ ->
            false
    end.

get_common_config_list() ->
    BaseDir = get_base_dir(),
    {ok, List} = file:consult(BaseDir ++ ?COMMON_CONFIG),
    {id, ServerName} = lists:keyfind(id, 1, List),
    get_config_by_url_body(ServerName, BaseDir ++ ?START_JSON).

get_config_by_url_body(ServerName, FileName) ->
    Time = get_now(),
    MD5 = to_md5(lists:concat([Time, "web-auth-key"])),
    AuthString = "&time=" ++ to_list(Time) ++ "&ticket=" ++ MD5,
    case catch file:read_file("/data/erl_env/escript_tool.env") of
        {ok, <<"1", _Remain>>} -> %% 内网测试服优先
            UrlList = [
                "http://192.168.2.250:82",
                "http://api.xj.phantom-u3d001.com",
                "http://zc.api-test.phantom-u3d001.com"
            ];
        {ok, <<"2", _Remain>>} -> %% 外网测试服优先
            UrlList = [
				"http://zc.api-test.phantom-u3d001.com",
                "http://api.xj.phantom-u3d001.com",
                "http://192.168.2.250:82"
            ];
        _ -> %% 正式环境
            UrlList = [
                "http://api.xj.phantom-u3d001.com",
                "http://zc.api-test.phantom-u3d001.com",
                "http://192.168.2.250:82"
            ]
    end,
    case catch get_config_by_url_body2(UrlList, to_list(ServerName), AuthString) of
        {ok, KVList} ->
            KVList;
        _ ->
            {ok, KVList} = get_config_by_file(ServerName, FileName),
            KVList
    end.

get_config_by_url_body2([], _ServerName, _AuthString) ->
    false;
get_config_by_url_body2([Url|R], ServerName, AuthString) ->
    Url2 = Url ++ "/index/index/startConfig?&key=" ++ ServerName ++ AuthString,
    case httpc:request(get, {Url2, []},  [{timeout, 3000}], [], default) of
        {ok, {{_, 200, _}, _Header, Body}} when Body =/= "[]" andalso Body =/= "" ->
            {ok, {obj, [{_, {obj, ConfigList}}]}, []} = decode(Body),
            KVList = get_config_kv_list(ConfigList, []),
            {ok, KVList};
        _ ->
            get_config_by_url_body2(R, ServerName, AuthString)
    end.

get_config_by_file(ServerName, FileName) ->
    {ok, Content} = file:read_file(FileName),
    {ok, {obj, ConfigList}, []} = decode(Content),
    {_, {obj, DefaultList}} = lists:keyfind("default", 1, ConfigList),
    {_, {obj, ServerConfigList}} = lists:keyfind(ServerName, 1, ConfigList),
    FirstList = get_config_kv_list(ServerConfigList, []),
    KVList = get_config_kv_list(DefaultList, FirstList),
    {ok, KVList}.

get_config_kv_list([], Acc) ->
    Acc;
get_config_kv_list([{Key, Value}|R], Acc) ->
    Key2 = to_atom(Key),
    case lists:keymember(Key2, 1, Acc) of
        true ->
            Acc2 = Acc;
        _ ->
            Value2 = get_common_config_value(Value),
            Acc2 = [{Key2, Value2}|Acc]
    end,
    get_config_kv_list(R, Acc2).

get_common_config_value(null) ->
    "";
get_common_config_value(Value) ->
    case catch erlang:is_integer(Value) of
        true ->
            Value;
        _ ->
            case to_atom(Value) of
                Bool when erlang:is_boolean(Bool) ->
                    Bool;
                _ ->
                    to_list(Value)
            end
    end.

%% 从rfc4627 copy过来的
decode(Bin) when is_binary(Bin) ->
    decode(binary_to_list(Bin));
decode(Bytes) ->
    {_Charset, Codepoints} = unicode_decode(Bytes),
    decode_noauto(Codepoints).

unicode_decode([0,0,254,255|C]) -> {'utf-32', xmerl_ucs:from_ucs4be(C)};
unicode_decode([255,254,0,0|C]) -> {'utf-32', xmerl_ucs:from_ucs4le(C)};
unicode_decode([254,255|C]) -> {'utf-16', xmerl_ucs:from_utf16be(C)};
unicode_decode([239,187,191|C]) -> {'utf-8', xmerl_ucs:from_utf8(C)};
unicode_decode(C=[0,0,_,_|_]) -> {'utf-32be', xmerl_ucs:from_ucs4be(C)};
unicode_decode(C=[_,_,0,0|_]) -> {'utf-32le', xmerl_ucs:from_ucs4le(C)};
unicode_decode(C=[0,_|_]) -> {'utf-16be', xmerl_ucs:from_utf16be(C)};
unicode_decode(C=[_,0|_]) -> {'utf-16le', xmerl_ucs:from_utf16le(C)};
unicode_decode(C=_) -> {'utf-8', xmerl_ucs:from_utf8(C)}.

decode_noauto(Bin) when is_binary(Bin) ->
    decode_noauto(binary_to_list(Bin));
decode_noauto(Chars) ->
    case catch parse(skipws(Chars)) of
        {'EXIT', Reason} ->
            %% Reason is usually far too much information, but helps
            %% if needing to debug this module.
            {error, Reason};
        {Value, Remaining} ->
            {ok, Value, skipws(Remaining)}
    end.


parse([$" | Rest]) -> %% " emacs balancing
    {Codepoints, Rest1} = parse_string(Rest, []),
    {list_to_binary(xmerl_ucs:to_utf8(Codepoints)), Rest1};
parse("true" ++ Rest) -> {true, Rest};
parse("false" ++ Rest) -> {false, Rest};
parse("null" ++ Rest) -> {null, Rest};
parse([${ | Rest]) -> parse_object(skipws(Rest), []);
parse([$[ | Rest]) -> parse_array(skipws(Rest), []);
parse([]) -> exit(unexpected_end_of_input);
parse(Chars) -> parse_number(Chars, []).

skipws([X | Rest]) when X =< 32 ->
    skipws(Rest);
skipws(Chars) ->
    Chars.

parse_string(Chars, Acc) ->
    case parse_codepoint(Chars) of
        {done, Rest} ->
            {lists:reverse(Acc), Rest};
        {ok, Codepoint, Rest} ->
            parse_string(Rest, [Codepoint | Acc])
    end.

parse_codepoint([$" | Rest]) -> %% " emacs balancing
    {done, Rest};
parse_codepoint([$\\, Key | Rest]) ->
    parse_general_char(Key, Rest);
parse_codepoint([X | Rest]) ->
    {ok, X, Rest}.

parse_general_char($b, Rest) -> {ok, 8, Rest};
parse_general_char($t, Rest) -> {ok, 9, Rest};
parse_general_char($n, Rest) -> {ok, 10, Rest};
parse_general_char($f, Rest) -> {ok, 12, Rest};
parse_general_char($r, Rest) -> {ok, 13, Rest};
parse_general_char($/, Rest) -> {ok, $/, Rest};
parse_general_char($\\, Rest) -> {ok, $\\, Rest};
parse_general_char($", Rest) -> {ok, $", Rest};
parse_general_char($u, [D0, D1, D2, D3 | Rest]) ->
    Codepoint =
        (digit_hex(D0) bsl 12) +
            (digit_hex(D1) bsl 8) +
            (digit_hex(D2) bsl 4) +
            (digit_hex(D3)),
    if
        Codepoint >= 16#D800 andalso Codepoint < 16#DC00 ->
            % High half of surrogate pair
            case parse_codepoint(Rest) of
                {low_surrogate_pair, Codepoint2, Rest1} ->
                    [FinalCodepoint] =
                        xmerl_ucs:from_utf16be(<<Codepoint:16/big-unsigned-integer,
                            Codepoint2:16/big-unsigned-integer>>),
                    {ok, FinalCodepoint, Rest1};
                _ ->
                    exit(incorrect_usage_of_surrogate_pair)
            end;
        Codepoint >= 16#DC00 andalso Codepoint < 16#E000 ->
            {low_surrogate_pair, Codepoint, Rest};
        true ->
            {ok, Codepoint, Rest}
    end.

%% @spec (Hexchar::char()) -> integer()
%% @doc Returns the number corresponding to Hexchar.
%%
%% Hexchar must be one of the characters `$0' through `$9', `$A'
%% through `$F' or `$a' through `$f'.
digit_hex($0) -> 0;
digit_hex($1) -> 1;
digit_hex($2) -> 2;
digit_hex($3) -> 3;
digit_hex($4) -> 4;
digit_hex($5) -> 5;
digit_hex($6) -> 6;
digit_hex($7) -> 7;
digit_hex($8) -> 8;
digit_hex($9) -> 9;

digit_hex($A) -> 10;
digit_hex($B) -> 11;
digit_hex($C) -> 12;
digit_hex($D) -> 13;
digit_hex($E) -> 14;
digit_hex($F) -> 15;

digit_hex($a) -> 10;
digit_hex($b) -> 11;
digit_hex($c) -> 12;
digit_hex($d) -> 13;
digit_hex($e) -> 14;
digit_hex($f) -> 15.

finish_number(Acc, Rest) ->
    Str = lists:reverse(Acc),
    {case catch list_to_integer(Str) of
         {'EXIT', _} -> list_to_float(Str);
         Value -> Value
     end, Rest}.

parse_number([$- | Rest], Acc) ->
    parse_number1(Rest, [$- | Acc]);
parse_number(Rest = [C | _], Acc) ->
    case is_digit(C) of
        true -> parse_number1(Rest, Acc);
        false -> exit(syntax_error)
    end.

parse_number1(Rest, Acc) ->
    {Acc1, Rest1} = parse_int_part(Rest, Acc),
    case Rest1 of
        [] -> finish_number(Acc1, []);
        [$. | More] ->
            {Acc2, Rest2} = parse_int_part(More, [$. | Acc1]),
            parse_exp(Rest2, Acc2, false);
        _ ->
            parse_exp(Rest1, Acc1, true)
    end.

parse_int_part(Chars = [_Ch | _Rest], Acc) ->
    parse_int_part0(Chars, Acc).

parse_int_part0([], Acc) ->
    {Acc, []};
parse_int_part0([Ch | Rest], Acc) ->
    case is_digit(Ch) of
        true -> parse_int_part0(Rest, [Ch | Acc]);
        false -> {Acc, [Ch | Rest]}
    end.

parse_exp([$e | Rest], Acc, NeedFrac) ->
    parse_exp1(Rest, Acc, NeedFrac);
parse_exp([$E | Rest], Acc, NeedFrac) ->
    parse_exp1(Rest, Acc, NeedFrac);
parse_exp(Rest, Acc, _NeedFrac) ->
    finish_number(Acc, Rest).

parse_exp1(Rest, Acc, NeedFrac) ->
    {Acc1, Rest1} = parse_signed_int_part(Rest, if
                                                    NeedFrac -> [$e, $0, $. | Acc];
                                                    true -> [$e | Acc]
                                                end),
    finish_number(Acc1, Rest1).

parse_signed_int_part([$+ | Rest], Acc) ->
    parse_int_part(Rest, [$+ | Acc]);
parse_signed_int_part([$- | Rest], Acc) ->
    parse_int_part(Rest, [$- | Acc]);
parse_signed_int_part(Rest, Acc) ->
    parse_int_part(Rest, Acc).

is_digit($0) -> true;
is_digit($1) -> true;
is_digit($2) -> true;
is_digit($3) -> true;
is_digit($4) -> true;
is_digit($5) -> true;
is_digit($6) -> true;
is_digit($7) -> true;
is_digit($8) -> true;
is_digit($9) -> true;
is_digit(_) -> false.

parse_object([$} | Rest], Acc) ->
    {{obj, lists:reverse(Acc)}, Rest};
parse_object([$, | Rest], Acc) ->
    parse_object(skipws(Rest), Acc);
parse_object([$" | Rest], Acc) -> %% " emacs balancing
    {KeyCodepoints, Rest1} = parse_string(Rest, []),
    [$: | Rest2] = skipws(Rest1),
    {Value, Rest3} = parse(skipws(Rest2)),
    parse_object(skipws(Rest3), [{KeyCodepoints, Value} | Acc]).

parse_array([$] | Rest], Acc) ->
    {lists:reverse(Acc), Rest};
parse_array([$, | Rest], Acc) ->
    parse_array(skipws(Rest), Acc);
parse_array(Chars, Acc) ->
    {Value, Rest} = parse(Chars),
    parse_array(skipws(Rest), [Value | Acc]).

to_atom(Msg) when erlang:is_atom(Msg) ->
    Msg;
to_atom(Msg) when erlang:is_binary(Msg) ->
    erlang:list_to_atom(erlang:binary_to_list(Msg));
to_atom(Msg) when erlang:is_list(Msg) ->
    erlang:list_to_atom(Msg);
to_atom(Msg) when erlang:is_integer(Msg) ->
    erlang:list_to_atom(erlang:integer_to_list(Msg));
to_atom(_) ->
    erlang:throw(other_value).  %%list_to_atom("").

to_list(Msg) when erlang:is_list(Msg) ->
    Msg;
to_list(Msg) when erlang:is_atom(Msg) ->
    erlang:atom_to_list(Msg);
to_list(Msg) when erlang:is_binary(Msg) ->
    erlang:binary_to_list(Msg);
to_list(Msg) when erlang:is_tuple(Msg) ->
    erlang:tuple_to_list(Msg);
to_list(Msg) when erlang:is_integer(Msg) ->
    erlang:integer_to_list(Msg);
to_list(Msg) when erlang:is_float(Msg) ->
    float_to_str(Msg);
to_list(PID) when erlang:is_pid(PID) ->
    pid_to_str(PID);
to_list(_) ->
    erlang:throw(other_value).

float_to_str(N) when erlang:is_integer(N) ->
    integer_to_list(N) ++ ".00";
float_to_str(F) when erlang:is_float(F) ->
    [A] = io_lib:format("~.2f", [F]),
    A.

pid_to_str(PID) ->
    erlang:pid_to_list(PID).
%%%===================================================================
%%% get_common_config end
%%%===================================================================


%%%===================================================================
%%% cfile start
%%%===================================================================
-define(EXIT(Code), erlang:halt(Code)).
-define(NONE, none).
%% 脚本到根目录的相对路径
%% 编译选项
-define(COMPILE_OPT,
    [
        {i, "."},
        {i, "include"},
        {i, "include/proto"},
        {i, "./config/erl"},
        {i, "deps/deps/emysql/include"},
        {i, "deps/deps/ibrowse/include"},
        {i, "deps/deps/mochiweb/include"},
        {i, "deps/db/include"},
        {inline_size, 30},
        report,
        warnings_as_errors,
        verbose,
        {d, 'TEST'},
        debug_info
    ]
).

-define(E(FormatStr, Args), io:format(unicode:characters_to_binary(FormatStr), Args)).
-define(E(FormatStr), io:format(unicode:characters_to_binary(FormatStr))).

%% 入口
cfile([]) ->
    cfile_usage(),
    ?EXIT(0);
cfile(Mods) ->
    cd_to_root_dir(),
    code:add_path(filename:join([".", "ebin"])),
    ConfigList = get_common_config_list(),
    [begin
         case catch find_file(Mod) of
             ?NONE ->
                 ?E("错误:在代码中无法找到模块:~s~n", [Mod]),
                 ?EXIT(1);
             {ok, FilePath} ->
                 ?E("编译文件:~s~n", [FilePath]),
                 compile_file(FilePath, ConfigList)
         end
     end || Mod <- Mods],
    ok.

%% 用法
cfile_usage() ->
    ?E(
        "编译单个文件，用法:
   ./cfile mod ...
            mod     - 模块名称
        举例
        ./cfile gateway mgeed
        在代码中查找gateway.erl和mgee.erl并编译

        ").


%% 在代码中查找某个模块
find_file(Mod) ->
    FileName =
        case filename:extension(Mod) of
            "" ->
                Mod ++ ".erl";
            ".erl" ->
                Mod
        end,
    [begin
         case filelib:wildcard(FindPath) of
             [] ->
                 ok;
             [File] ->
                 throw({ok, File})
         end
     end || FindPath <-
        [
            filename:join([".", "update", FileName]),
            filename:join([".", "src", FileName]),
            filename:join([".", "src", "*", FileName]),
            filename:join([".", "src", "*", "*", FileName]),
            filename:join([".", "src", "*", "*", "*", FileName]),
            filename:join([".", "deps", "deps", "*", "src", FileName]),
            filename:join([".", "deps", "deps", "*", "src", "mod", FileName]),
            filename:join([".", "deps", "*", "src", FileName]),
            filename:join([".", "deps", "*", "src", "mod", FileName]),
            filename:join([".", "config", "erl", FileName]),
            filename:join([".", "config", "excel", FileName]),
            filename:join([".", "config", "map_dyn", FileName]),
            filename:join([".", "config", "dyn", FileName])
        ]],
    ?NONE.

%% 编译文件
compile_file(FilePath, ConfigList) ->
    OutDir = get_out_dir(ConfigList),
    Opts = [{outdir, OutDir} | ?COMPILE_OPT],
    ?E("编译选项:~p~n", [Opts]),
    case compile:file(FilePath, Opts) of
        {ok, _Data} ->
            cp_to_ebin(OutDir, FilePath),
            ?E("编译成功:~p!~n", [_Data]);
        {ok, _, Warnings} ->
            cp_to_ebin(OutDir, FilePath),
            ?E("编译成功!~n"),
            ?E("警告:~n~p~n", [Warnings]);
        error ->
            ?E("编译失败!~n"),
            ?EXIT(1);
        {error, Errors, Warnings} ->
            ?E("编译失败!~n"),
            ?E("错误:~n~p~n", [Errors]),
            ?E("警告:~n~p~n", [Warnings]),
            ?EXIT(1)
    end.

cd_to_root_dir()->
    file:set_cwd(get_base_dir()).

%% 获取outdir
get_out_dir(ConfigList) ->
    {ok, GameCode} = get_config_by_key("game_code", ConfigList),
    {ok, AgentCode} = get_config_by_key("agent_code", ConfigList),
    {ok, ServerID} = get_config_by_key("server_id", ConfigList),
    lists:concat(["/data/", GameCode ,"_", AgentCode, "_", ServerID, "/server/ebin"]).


%% 同时copy到ebin
cp_to_ebin(OutDir, SrcFile) ->
    Beam = filename:basename(SrcFile, ".erl") ++ ".beam",
    Dst = filename:join([".", "ebin", Beam]),
    Src = filename:join([OutDir, Beam]),
    CMD = io_lib:format("cp ~s ~s", [Src, Dst]),
    os:cmd(CMD),
    ok.

get_now() ->
    {A, B, _} = os:timestamp(),
    A * 1000000 + B.

to_md5(S) ->
    MD5Bin = erlang:md5(to_list(S)),
    lists:flatten(list_to_hex(to_list(MD5Bin))).

list_to_hex(L) ->
    lists:map(fun(X) -> int_to_hex(X) end, L).

%% @doc 单个字节的16进制字符串表达
-spec int_to_hex(integer()) -> string().
int_to_hex(N) when N < 256 ->
    [hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
    $0 + N;
hex(N) when N >= 10, N < 16 ->
    $a + (N - 10).
%%%===================================================================
%%% cfile end
%%%===================================================================
set_base_dir(RunDir) ->
    erlang:put({?MODULE, base_dir}, RunDir).
get_base_dir() ->
    erlang:get({?MODULE, base_dir}).
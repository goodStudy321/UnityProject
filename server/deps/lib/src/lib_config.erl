%%%-------------------------------------------------------------------
%%% @doc
%%%     目前只支持key-value或者record（首字段为key）的配置文件
%%% @end
%%%-------------------------------------------------------------------
-module(lib_config).
-include_lib("kernel/include/file.hrl").

-export([
    init/0,
    reload/1,
    reload_setting/0,
    reload_common_config/0,
    get_common_config_list/0,
    reload_all/0
]).

-export([
    get_version/0,
    get_config_path/0
]).

-export([
    find/2,
    list/1
]).

-export([
    gen_src_code/4,
    do_load_gen_src/3
]).


-define(MAX_CONFIG_FILE_SIZE, 1024*1024). %%不接受超过1M的配置文件, 文件过大会导致编译开销巨大
-define(ERROR_MSG(Format, Args),
        log_entry:error_msg( node(), ?MODULE, ?LINE, Format, Args)).
-define(ERROR_MSG(D), ?ERROR_MSG(D, [])).

%% ====================================================================
%% API Functions
%% ====================================================================
%% @doc 系统启动时将setting目录下的配置加载到内存中
init()->
    reload_setting(),
    ok.

%% @doc 获取当前游戏服的版本号
%% 当前版本若是：B_beta0.2.4.0-20151121.32885.32885，此函数的返回值为：0_2_4
%% @end
get_version() ->
    VersionInfo = common_config:get_server_root() ++ "/version_server.txt",
    {ok, Version} =file:read_file(VersionInfo),
    VerList = erlang:binary_to_list(Version),
    Ver = lists:sublist(VerList,7,5),
    string:join(string:tokens(Ver,"."),"_").

%% @doc 获取配置文件目录
get_config_path() ->
    lists:concat([common_config:get_server_root(), "config/"]).

get_setting_path() ->
    lists:concat([common_config:get_server_root(), "setting/"]).

%% @doc 重新加载setting目录下配置
reload_setting()->
    reload_common_config(),
    ok.

%% common_config生成会有些不同
reload_common_config() ->
    ConfigList = get_common_config_list(),
    do_load_config(common, key_value_consult, ConfigList).

%% @doc 重新加载全部配置
reload_all()->
    reload_setting(),
    ok.

%% @doc 重新加载配置文件
reload(common)->
    reload_common_config(),
    ok;
reload(ConfigName)  ->
    ?ERROR_MSG("unknow config:~w", [ConfigName]),
    error.

%% @doc 根据键值查询配置
find(ConfigName,Key)->
    case ConfigName:find(Key) of
        undefined-> [];
        not_implement -> [];
        Val -> [Val]
    end.

%% @doc 获取配置文件全部键值
list(ConfigName)->
    case ConfigName:list() of
        undefined-> [];
        not_implement -> [];
        Val -> Val
    end.

%% ====================================================================
%% Local Functions
%% ====================================================================
do_load_config(ModuleName, FileType, List) ->
    case do_load_gen_src(ModuleName, FileType, List) of
        {ok, _Code} ->
            clear_exit_info(),
            ok;
        _ ->
            clear_exit_info(),
            error
    end.

%% @doc 生成源代码，执行编译并加载到内存
do_load_gen_src(ModuleName, FileType, List)->
    case catch do_load_gen_src2(ModuleName,FileType,List) of
        {ok, Code} ->
            {ok, Code};
        Reason ->
            ?ERROR_MSG("Error compiling ~p Reason=~w ", [ModuleName, Reason]),
            error
    end.

do_load_gen_src2(ModuleName,FileType,List) ->
    if FileType =:= record_consult ->
            KeyValues =
                [ {element(2,Rec), Rec}  || Rec<- List],
            {_, ValList} = lists:unzip(KeyValues);
       true ->
            KeyValues = List,
            {_, ValList} = lists:unzip(KeyValues)
    end,
    Src = gen_src_code(ModuleName, set, KeyValues,ValList),
    {Mod, Code} = dynamic_compile:from_string(Src),
    code:load_binary(Mod, lib_tool:to_list(ModuleName) ++ ".erl", Code),
    {ok, Code}.

gen_src_code(ConfModuleName,Type,KeyValues,ValList) ->
    KeyValues2 = get_src_key_values(Type, KeyValues),
    KeyValues3 = lists:reverse(KeyValues2),
    check_duplicate_keys(ConfModuleName, KeyValues3),
    Bin0 = gen_src_header(ConfModuleName, <<>>),
    Bin1 = gen_src_list(ValList, Bin0),
    Bin2 = gen_src_all(ConfModuleName, KeyValues, Bin1),
    Bin3 = gen_src_find(KeyValues3, Bin2),
    lib_tool:to_list(Bin3).

gen_src_find([], BinAcc) ->
    <<BinAcc/binary, "find(_) -> undefined.\n">>;
gen_src_find([{Key,Value}|L], BinAcc) ->
    KeyBin = lib_tool:to_binary(io_lib:format("~w", [Key])),
    ValueBin = lib_tool:to_binary(io_lib:format("~w", [Value])),
    BinAcc2 = <<BinAcc/binary, <<"find(">>/binary, KeyBin/binary, <<") -> ">>/binary, ValueBin/binary, <<";">>/binary>>,
    gen_src_find(L, BinAcc2).

gen_src_all(ConfModuleName, KeyValues, BinAcc) ->
    case if_config_all() orelse ConfModuleName =:= common of
        true -> 
            AllBin = lib_tool:to_binary(io_lib:format("~w", [KeyValues]));
        _ -> 
            AllBin = <<"[]">>
    end,
    <<BinAcc/binary, <<"all() -> ">>/binary, AllBin/binary, <<".\n">>/binary>>.

gen_src_list(ValList, BinAcc) ->
    StrList = io_lib:format("~w", [ValList]),
    ListBin = lib_tool:to_binary(StrList),
    <<BinAcc/binary, <<"list() -> ">>/binary, ListBin/binary, <<".\n">>/binary>>.

gen_src_header(ConfModuleName, BinAcc) ->
    HeaderBin = lib_tool:to_binary(lib_tool:to_list(ConfModuleName)),
    <<BinAcc/binary, <<"-module('">>/binary, HeaderBin/binary, <<"').\n-export([list/0,all/0,find/1]).\n">>/binary>>.

get_src_key_values(bag, KeyValues) ->
    lists:foldl(fun({K, V}, Acc) ->
                        case lists:keyfind(K, 1, Acc) of
                            false ->
                                [{K, [V]}|Acc];
                            {K, VO} ->
                                [{K, [V|VO]}|lists:keydelete(K, 1, Acc)]
                        end
                end, [], KeyValues);
get_src_key_values(_, KeyValues) ->
    KeyValues.

check_duplicate_keys(ConfModName, KVs) ->
    ETS = ets:new(check_config_dup_keys, [private,set]),
    check_duplicate_keys(ConfModName, KVs, ETS),
    ets:delete(ETS),
    ok.
check_duplicate_keys(_, [], _) -> done;
check_duplicate_keys(ConfModuleName, [{K,_}|L], ETS) ->
    case ets:lookup(ETS, K) of
        [_] ->
            io:format("WARNING duplicate key! ~w:~w", [ConfModuleName,K]),
            check_duplicate_keys(ConfModuleName, L, ETS);
        _ ->
            ets:insert(ETS, {K,true}),
            check_duplicate_keys(ConfModuleName, L, ETS)
    end.

clear_exit_info() ->
    receive
        {'EXIT', _PID, _Reason} ->
            ignore
    after 0 ->
            ok
    end,
    ok.

if_config_all() ->
    case init:get_argument(conf) of
        {ok,[["all"]] } ->
            true;
        _ ->
            false
    end.

get_common_config_list() ->
    File = common_config:get_common_config(),
    Path = get_setting_path(),
    {ok, List} = file:consult(Path ++ File),
    {id, ServerName} = lists:keyfind(id, 1, List),
    get_config_by_url_body(ServerName, get_config_path() ++ "start_config.json").

get_config_by_url_body(ServerName, FileName) ->
    Time = time_tool:now(),
    MD5 = string:to_lower(lib_tool:md5(lists:concat([Time, "web-auth-key"]))),
    AuthString = "&time=" ++ lib_tool:to_list(Time) ++ "&ticket=" ++ MD5,
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
                "http://api.xj.phantom-u3d001.com/",
                "http://192.168.2.250:82"
            ];
        _ -> %% 正式环境
            UrlList = [
                "http://api.xj.phantom-u3d001.com",
                "http://zc.api-test.phantom-u3d001.com",
                "http://192.168.2.250:82"
            ]
    end,
    case catch get_config_by_url_body2(UrlList, lib_tool:to_list(ServerName), AuthString) of
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
    case httpc:request(get, {Url2, []},  [{timeout, 5000}], [], default) of
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
    Key2 = lib_tool:to_atom(Key),
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
            case lib_tool:to_atom(Value) of
                Bool when erlang:is_boolean(Bool) ->
                    Bool;
                _ ->
                    unicode:characters_to_list(Value)
            end
    end.

decode(Content) ->
    rfc4627:decode(Content).

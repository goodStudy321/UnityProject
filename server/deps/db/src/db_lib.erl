%%%--------------------------------------------------------
%%% @author
%%% @doc
%%%     db内部接口模块
%%% @end
%%%--------------------------------------------------------

-module(db_lib).

-include("emysql.hrl").
-include("common.hrl").

-export([
    connect/0,
    ensure_kv_table/2,
    kv_insert/3,
    kv_delete/2,
    kv_delete_many/2,
    kv_insert_from_ets/2,
    kv_lookup/2,
    kv_lookup_by_pool_id/3,
    kv_lookup_many/2,
    kv_lookup_seq/3,
    delete_all/1,
    all/1,
    all/2,
    all_keys/1,
    all_keys/2,
    fold/3,
    size/1, % 注意：内部实现使用select count(*)获取行数，对于使用innodb引擎的表，如果表的行数很大，那么效率将很低，需谨慎！
    max_id/1,
    get_config/1,
    encode_key/1,
    return/3
]).


-define(POOL, ?MODULE).

is_pool_exists(PoolID) ->
    Pools = emysql_conn_mgr:pools(),
    case emysql_conn_mgr:find_pool(PoolID, Pools) of
        undefined ->
            false;
        _ ->
            true
    end.

del_pool_if_exist(PoolId) ->
    case is_pool_exists(PoolId) of
        true ->
            ?INFO_MSG("----- removing emysql pool ~p --------", [PoolId]),
            emysql:remove_pool(PoolId);
        _ ->
            skip
    end.

connect()->
    application:ensure_all_started(emysql),
    [Host] = lib_config:find(common, db_host),
    [Port] = lib_config:find(common, db_port),
    UserName = ?MYSQL_USER,
    Password = ?MYSQL_PASSWORD,
    Connections = ?DB_CONNECTIONS,
    DBName = ?GAME_DB_NAME,
    DBName2 = common_config:get_database_full_name(DBName),
    del_pool_if_exist(?POOL),
    ?ERROR_MSG("MySQL connecting to ~p:~p ~p:~p ~p ~w", [Host, Port, UserName, Password, DBName2, Connections]),
    emysql:add_pool(?POOL, Connections, UserName, Password, Host, Port, DBName2, utf8mb4).

%% 建表
ensure_kv_table(Table, KeyFormat) ->
    ensure_kv_table(?POOL, Table, KeyFormat).
ensure_kv_table(PoolID, Table, KeyFormat) ->
    TableBin = atom_to_binary(Table, latin1),
    KeyBin = key_format(KeyFormat),
    Cmd = <<"CREATE TABLE IF NOT EXISTS ", TableBin/binary, " ("
            "`id` ", KeyBin/binary, " PRIMARY KEY,",
            "`data` MEDIUMBLOB not null,",
            "`update_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)",
            "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin">>,
    execute(PoolID, Cmd).

key_format(int) ->
    <<"bigint">>;
key_format({varbinary, N}) ->
    <<"varbinary(", (integer_to_binary(N))/binary, ")">>.


%% 直接向数据库中插入, 当数据量过大时自动分段, 全部成功返true
kv_insert(Table, Objects, KeyPos) ->
    kv_insert(?POOL, Table, Objects, KeyPos).

kv_insert(_PoolID, _Table, [], _KeyPos) ->
    true;
kv_insert(PoolID, Table, Objects, KeyPos) ->
    kv_insert_retry(PoolID, Table, Objects, KeyPos, 1, 0).

kv_delete(Table, Key) ->
    kv_delete(?POOL, Table, Key).
kv_delete(PoolID, Table, Key) ->
    TableBin = atom_to_binary(Table, latin1),
    KeyBin = encode_key(Key),
    Cmd = <<"DELETE FROM ", TableBin/binary, " WHERE `id`=", KeyBin/binary>>,
    execute(PoolID, Cmd) =:= ok.

kv_delete_many(Table, Keys) ->
    kv_delete_many(?POOL, Table, Keys).
kv_delete_many(PoolID, Table, Keys) when is_list(Keys) ->
    TableBin = atom_to_binary(Table, latin1),
    KeysBins = [encode_key(K) || K <- Keys],
    KeysBin = bin_join(<<",">>, KeysBins),
    Cmd = <<"DELETE FROM ", TableBin/binary, " WHERE id in (",
            KeysBin/binary, ")">>,
    execute(PoolID, Cmd).


%% 从ETS读取数据向数据库中插入, 传入Key的列表,
%% 当数据量过大时自动分段, 全部成功返true
kv_insert_from_ets(Table, Keys) ->
    kv_insert_from_ets(?POOL, Table, Keys).
kv_insert_from_ets(_PoolID, _Table, []) ->
    true;
kv_insert_from_ets(PoolID, Table, Keys) when is_list(Keys) ->
    KeyPos = ets:info(Table, keypos),
    MaxRetry = get_config(mysql_max_retry),
    kv_insert_from_ets_retry(PoolID, Table, Keys, KeyPos, MaxRetry, 0).

kv_insert_from_ets_retry(PoolID, Table, Keys, KeyPos, MaxRetry, N) ->
    MaxWrite = get_config(mysql_max_write_num),
    F = fun(IDs, Success) -> Success andalso kv_save(PoolID, Table, find_in_est(Table, IDs), KeyPos) =:= ok end,
    case batch(F, true, Keys, MaxWrite) of
        true ->
            true;
        _Error when N < MaxRetry ->
            kv_insert_from_ets_retry(PoolID, Table, Keys, KeyPos, MaxRetry, N+1);
        Error ->
            Error
    end.


find_in_est(Table, IDs) ->
    find_in_est(Table, IDs, []).

find_in_est(_Table, [], AccData) ->
    AccData;
find_in_est(Table, [ID|T], AccData) ->
    case ets:lookup(Table, ID) of
        [Data] ->
            Data1 = [Data|AccData],
            find_in_est(Table, T, Data1);
        _E ->
            ?DEBUG("Error data got in ets ~p for id ~w, got: ~p", [Table, ID, _E]),
            find_in_est(Table, T, AccData)
    end.


kv_insert_retry(PoolID, Table, Objects, KeyPos, MaxRetry, N) ->
    MaxWrite = get_config(mysql_max_write_num),
    F = fun(Data, Success) -> Success andalso kv_save(PoolID, Table, Data, KeyPos) =:= ok end,
    case batch(F, true, Objects, MaxWrite) of
        true ->
            true;
        _Error when N < MaxRetry ->
            kv_insert_retry(PoolID, Table, Objects, KeyPos, MaxRetry, N+1);
        Error ->
            Error
    end.


%% 直接从数据库获取
kv_lookup(Table, Key) ->
    kv_lookup_by_pool_id(?POOL, Table, Key).
kv_lookup_by_pool_id(PoolID, Table, Key) ->
    Data = kv_get_by_pool_id(PoolID, Table, Key),
    [erlang:binary_to_term(D) || D <- Data].

kv_lookup_many(Table, Keys) ->
    kv_lookup_many(?POOL, Table, Keys).
kv_lookup_many(PoolID, Table, Keys) ->
    Data = kv_get_many(PoolID, Table, Keys),
    [erlang:binary_to_term(D) || D <- Data].

kv_lookup_seq(Table, From, Len) ->
    kv_lookup_seq(?POOL, Table, From, Len).
kv_lookup_seq(PoolID, Table, From, Len) ->
    Data = kv_get_seq(PoolID, Table, From, Len),
    [erlang:binary_to_term(D) || D <- Data].

delete_all(Table) ->
    delete_all(?POOL, Table).
delete_all(PoolID, Table) ->
    TableBin = atom_to_binary(Table, latin1),
    Cmd = <<"DELETE FROM ", TableBin/binary>>,
    execute(PoolID, Cmd).

%% 直接从数据库获取 慎用！
all(Table) ->
    all(?POOL, Table).
all(PoolID, Table) ->
    KeyPos = ets:info(Table, keypos),
    MaxRead = get_config(mysql_max_read_num),
    case kv_get_first(PoolID, Table, MaxRead) of
        [] ->
            [];
        Data ->
            Data1 = [erlang:binary_to_term(D) || D <- Data],
            Last = lists:last(Data1),
            LastKey = erlang:element(KeyPos, Last),
            all_1(PoolID, Table, KeyPos, LastKey, MaxRead, Data1)
    end.

all_1(PoolID, Table, KeyPos, LastKey, MaxRead, Acc) ->
    case kv_get_next(PoolID, Table, LastKey, MaxRead) of
        [] ->
            Acc;
        Data ->
            Data1 = [erlang:binary_to_term(D) || D <- Data],
            Last = lists:last(Data1),
            LastKey1 = erlang:element(KeyPos, Last),
            all_1(PoolID, Table, KeyPos, LastKey1, MaxRead, Data1 ++ Acc)
    end.

%% 直接从数据库获取 谨慎使用！
all_keys(Table) ->
    all_keys(?POOL, Table).
all_keys(PoolID, Table) ->
    MaxRead = get_config(mysql_max_read_num),
    case get_first_key(PoolID, Table, MaxRead) of
        [] ->
            [];
        Data ->
            LastKey = lists:last(Data),
            all_keys_1(PoolID, Table, LastKey, MaxRead, Data)
    end.

all_keys_1(PoolID, Table, LastKey, MaxRead, Acc) ->
    case get_next_key(PoolID, Table, LastKey, MaxRead) of
        [] ->
            Acc;
        Data ->
            LastKey2 = lists:last(Data),
            all_keys_1(PoolID, Table, LastKey2, MaxRead, Data ++ Acc)
    end.

fold(Func, Acc0, Table) ->
    fold(Func, Acc0, ?POOL, Table).
fold(Func, Acc0, PoolID, Table) ->
    KeyPos = ets:info(Table, keypos),
    MaxRead = get_config(mysql_max_read_num),
    case kv_get_first(PoolID, Table, MaxRead) of
        [] ->
            Acc0;
        Data ->
            Data1 = [erlang:binary_to_term(D) || D <- Data],
            Acc1 = lists:foldl(Func, Acc0, Data1),
            Last = lists:last(Data1),
            LastKey = erlang:element(KeyPos, Last),
            fold_1(Func, Acc1, PoolID, Table, KeyPos, LastKey, MaxRead)
    end.

fold_1(Func, Acc0, PoolID, Table, KeyPos, LastKey, MaxRead) ->
    case kv_get_next(PoolID, Table, LastKey, MaxRead) of
        [] ->
            Acc0;
        Data ->
            Data1 = [erlang:binary_to_term(D) || D <- Data],
            Acc1 = lists:foldl(Func, Acc0, Data1),
            Last = lists:last(Data1),
            LastKey1 = erlang:element(KeyPos, Last),
            fold_1(Func, Acc1, PoolID, Table, KeyPos, LastKey1, MaxRead)
    end.

size(Table) ->
    size(?POOL, Table).
size(PoolID, Table) ->
    TableBin = atom_to_binary(Table, latin1),
    Cmd = <<"SELECT count(*) FROM ", TableBin/binary>>,
    [Size] = execute(PoolID, Cmd),
    Size.

max_id(Table) ->
    max_id(?POOL, Table).
max_id(PoolID, Table) ->
    TableBin = atom_to_binary(Table, latin1),
    Cmd = <<"SELECT max(id) FROM ", TableBin/binary>>,
    [ID] = execute(PoolID, Cmd),
    ID.

execute(PoolID, Cmd) ->
    Result = emysql:execute(PoolID, Cmd),
    R = return(Result, PoolID, Cmd),
    R.

%% 批量, 每个分段最大为Max, 对每个分段执行Func
batch(Func, Acc0, Data, Max) when is_list(Data)->
    batch(Func, Acc0, Data, Max, [], 0).

batch(Func, Acc0, Remain, Max, AccData, N) when N >= Max ->
    Acc1 = Func(AccData, Acc0),
    batch(Func, Acc1, Remain, Max, [], 0);
batch(Func, Acc0, []=_Remain, _Max, AccData, _) ->
    Func(AccData, Acc0);
batch(Func, Acc0, [H|T], Max, AccData, N) ->
    batch(Func, Acc0, T, Max, [H|AccData], N+1).

%% 直接向数据库中插入, 成功返ok
kv_save(_PoolID, _Table, [], _KeyPos) -> % 为免下方 [KV|Rest] 出错
    ok;
kv_save(PoolID, Table, Objects, KeyPos) ->
    KVBins = [quote_kv(Obj, KeyPos) || Obj <- Objects],
    KeyValuesBin = bin_join(<<",">>, KVBins),
    TableBin = atom_to_binary(Table, latin1),
    Cmd = <<"INSERT INTO ", TableBin/binary,  " (id, data) VALUES ", KeyValuesBin/binary,
            " ON DUPLICATE KEY UPDATE data=VALUES(data)">>,
    execute(PoolID, Cmd).


bin_join(Sep, [H|T]) ->
    TBin = << <<Sep/binary, R/binary >> || R <- T >>,
    <<H/binary, TBin/binary>>;
bin_join(_Sep, []) ->
    <<>>.


quote_kv(Obj, KeyPos) ->
    Key = erlang:element(KeyPos, Obj),
    Value = term_to_binary(Obj),
    erlang:bump_reductions(byte_size(Value) bsr 4), % 除以16
    << "(", (encode_key(Key))/binary, ",",
       (encode(Value))/binary, ")">>.

kv_get_by_pool_id(PoolID, Table, Key) ->
    TableBin = atom_to_binary(Table, latin1),
    KeyBin = encode_key(Key),
    Cmd = <<"SELECT data FROM ", TableBin/binary, " WHERE id = ", KeyBin/binary>>,
    execute(PoolID, Cmd).

kv_get_many(_PoolID, _Table, []) ->
    [];
kv_get_many(PoolID, Table, Keys) when is_list(Keys) ->
    TableBin = atom_to_binary(Table, latin1),
    KeysBins = [encode_key(K) || K <- Keys],
    KeysBin = bin_join(<<",">>, KeysBins),
    Cmd = <<"SELECT data FROM ", TableBin/binary, " WHERE id in (",
            KeysBin/binary, ")">>,
    execute(PoolID, Cmd).

kv_get_seq(PoolID, Table, From, Len) ->
    TableBin = atom_to_binary(Table, latin1),
    FromBin = integer_to_binary(From),
    LenBin = integer_to_binary(Len),
    Cmd = <<"SELECT data FROM ", TableBin/binary, " LIMIT ",
            FromBin/binary, ",", LenBin/binary>>,
    execute(PoolID, Cmd).

kv_get_first(PoolID, Table, Len) ->
    TableBin = atom_to_binary(Table, latin1),
    LenBin = integer_to_binary(Len),
    Cmd = <<"SELECT data FROM ", TableBin/binary,
            " ORDER BY id LIMIT ", LenBin/binary>>,
    execute(PoolID, Cmd).

kv_get_next(PoolID, Table, Key, Len) ->
    TableBin = atom_to_binary(Table, latin1),
    LenBin = integer_to_binary(Len),
    KeyBin = encode_key(Key),
    Cmd = <<"SELECT data FROM ", TableBin/binary,
            " WHERE id > ", KeyBin/binary,
            " ORDER BY id LIMIT ", LenBin/binary>>,
    execute(PoolID, Cmd).

get_first_key(PoolID, Table, Len) ->
    TableBin = atom_to_binary(Table, latin1),
    LenBin = integer_to_binary(Len),
    Cmd = <<"SELECT id FROM ", TableBin/binary,
        " ORDER BY id LIMIT ", LenBin/binary>>,
    execute(PoolID, Cmd).

get_next_key(PoolID, Table, Key, Len) ->
    TableBin = atom_to_binary(Table, latin1),
    LenBin = integer_to_binary(Len),
    KeyBin = encode_key(Key),
    Cmd = <<"SELECT id FROM ", TableBin/binary,
        " WHERE id > ", KeyBin/binary,
        " ORDER BY id LIMIT ", LenBin/binary>>,
    execute(PoolID, Cmd).


encode_key(X) when is_integer(X) ->
    encode(X);
encode_key(X) when is_binary(X) ->
    encode(X);
encode_key(X) when is_atom(X) ->
    encode(X);
encode_key(X) ->
    encode(term_to_binary(X)).


%% 简化返回值格式
return(ok, _PoolID, _Cmd) ->
    ok;
return(#ok_packet{}, _PoolID, _Cmd) ->
    ok;
return(#result_packet{rows=Rows}, _PoolID, _Cmd) ->
    [R || [R] <- Rows];
return(#error_packet{msg=Msg}=_E, PoolID, Cmd) ->
    ?ERROR_MSG("Error in sql, Msg: ~p--------  PoolID: ~w  --------  Cmd: ~s",[Msg, PoolID, Cmd]),
    {error, Msg};
return(_E, PoolID, Cmd) ->
    ?ERROR_MSG("Error return format: ~p--------  PoolID: ~w  --------  Cmd: ~s", [_E, PoolID, Cmd]),
    {error, _E}.

encode(Val) ->
    esql_quote:encode(Val).

%% mysql的配置，写死
get_config(mysql_max_retry) -> %% MySQL 最大重试次数
    3;
get_config(mysql_max_write_num) -> %% MySQL 一次写入最大条数
    500;
get_config(mysql_max_read_num) -> %% MySQL 一次写入最大条数
    500;
get_config(mysql_default_cooldown) -> %% 缓存删除延迟
    4800.

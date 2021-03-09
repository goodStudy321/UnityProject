%%%--------------------------------------------------------
%%% @author 
%%% @doc
%%%     db接口模块
%%% @end
%%%--------------------------------------------------------

-module(db).
-export([
    start/0,
    open/4,
    insert/2,
    delete/2,
    delete_many/2,
    delete_all/1,
    lookup/2,
    lookup_many/2,
    table_all/1,
    sync/2,
    sync_all/1,
    flush/1,
    flush_all/0,
    tables/0,
    size/1,
    keep_hots/2
]).

-export([
    is_node_match/2
]).

start() ->
    db_lib:connect().

%% @doc
%% 创建ets并且start该表对应的server进程
%% EtsOpts -> 常用的ets参数 ets必须是public
%% SqlOpts -> keyformat key值对应的类型，int, {varbinary, N} 默认为int 
%%            cooldown 看db_server
%%            period 对key进行管理，一个是链表，一个是有序平衡二叉树
%% ActiveTime -> XXs之前的数据，先加载到内存表
open(Table, EtsOpts, SqlOpts, _ActiveTime) ->
    EtsOpts2 = [public|lists:delete(procted, lists:delete(private, EtsOpts))],
    ets:new(Table, EtsOpts2),
    SqlOpts2 = [{save_func, {db_lib, kv_insert_from_ets, Table}}|SqlOpts],
    KeyFormat =
        case lists:keyfind(keyformat, 1, SqlOpts2) of
            false ->
                int;
            {_, Format} ->
                Format
        end,
    ok = db_lib:ensure_kv_table(Table, KeyFormat),
    {ok, _} = db_server:start(Table, SqlOpts2).


insert(Table, Data) when is_tuple(Data)->
    insert(Table, [Data]);

insert(Table, Data) when is_list(Data) ->
    KeyPos = keypos(Table),
    IDs = [erlang:element(KeyPos, T) || T <- Data],
    ets:insert(Table, Data),
    sync(Table, IDs).


delete(Table, Key) ->
    ets:delete(Table, Key),
    Server = db_server:server_name(Table),
    gen_server:cast(Server, {delete, Key}).

delete_many(_Table, []) ->
    ok;
delete_many(Table, Keys) ->
    [ets:delete(Table, Key) || Key <- Keys],
    Server = db_server:server_name(Table),
    gen_server:cast(Server, {delete_many, Keys}).

delete_all(Table) ->
    ets:delete_all_objects(Table),
    Server = db_server:server_name(Table),
    gen_server:cast(Server, delete_all).

lookup(Table, Key) ->
    case ets:lookup(Table, Key)  of
        [] ->
            case db_lib:kv_lookup(Table, Key) of
                [] ->
                    [];
                Data ->
                    ets:insert(Table, Data),
                    db_hot:mark_hots(Table, [Key]),
                    Data
            end;
        Data ->
            Data
    end.


lookup_many(Table, Keys) ->
    Keys1 = [K || K <- Keys, not ets:member(Table, K)],
    Objs1 = db_lib:kv_lookup_many(Table, Keys1),
    ets:insert(Table, Objs1),
    db_hot:mark_hots(Table, Keys1),
    Objs2 = [ets:lookup(Table, K) || K <- Keys],
    [Obj || [Obj] <- Objs2].

table_all(Table) ->
    ets:tab2list(Table).

-spec keypos(Table) -> integer()|undefined when
    Table :: atom().

keypos(Table) ->
    ets:info(Table, keypos).

sync(_, []) ->
    ok;
sync(Table, Keys) ->
    Server = db_server:server_name(Table),
    gen_server:cast(Server, {insert, Keys}).

sync_all(Table) ->
    Server = db_server:server_name(Table),
    gen_server:cast(Server, insert_all).

flush(Table) ->
    db_server:flush(Table).

flush_all() ->
    Tables = db_server:all_tables(),
    lists:all(fun db_server:flush/1, Tables).

tables() ->
    db_server:all_tables().

size(Table) ->
    db_lib:size(Table).

keep_hots(_, []) ->
    ok;
keep_hots(Table, Keys) ->
    db_hot:mark_hots(Table, Keys).

is_node_match(NodeType, ServerType) ->
    NodeType =:= ServerType orelse NodeType =:= all.
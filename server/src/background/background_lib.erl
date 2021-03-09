%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 三月 2018 17:20
%%%-------------------------------------------------------------------
-module(background_lib).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    connect/1
]).

connect(PoolID) ->
    application:ensure_all_started(emysql),
    UserName = ?MYSQL_USER,
    Password = ?MYSQL_PASSWORD,
    Connections = ?DB_CONNECTIONS,
    case PoolID of
        ?ADMIN_POOL ->
            [Host] = lib_config:find(common, admin_host),
            [Port] = lib_config:find(common, admin_port),
            DBName = ?ADMIN_DB_NAME,
            DBName2 = common_config:get_database_full_name(DBName);
        ?CENTRAL_POOL ->
            [Host] = lib_config:find(common, central_host),
            [Port] = lib_config:find(common, central_port),
            DBName = ?CENTRAL_DB_NAME,
            DBName2 = DBName
    end,
    del_pool_if_exist(PoolID),
    ?WARNING_MSG("MySQL connecting to ~p:~p ~p:~p ~p ~w", [Host, Port, UserName, Password, DBName2, Connections]),
    emysql:add_pool(PoolID, Connections, UserName, Password, Host, Port, DBName2, utf8mb4).

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
            ?ERROR_MSG("----- removing emysql pool ~p --------", [PoolId]),
            emysql:remove_pool(PoolId);
        _ ->
            ok
    end.
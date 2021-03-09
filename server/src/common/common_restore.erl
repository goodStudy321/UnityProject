%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2017 19:21
%%%-------------------------------------------------------------------
-module(common_restore).
-author("laijichang").
-include("global.hrl").
-include("proto/gateway.hrl").

%% API
-export([
    restore/2
]).

-export([
    read_role_data/5,
    read_role_data/7
]).

restore(DataBaseIP, RoleID) ->
    restore(DataBaseIP, RoleID, all).
restore(DataBaseIP, RoleID, _Options) ->
    PoolID = ?MODULE,
    UserName = ?MYSQL_USER,
    Password = ?MYSQL_PASSWORD,
    Connections = ?DB_CONNECTIONS,
    DBName = ?GAME_DB_NAME,
    DBName2 = common_config:get_database_full_name(DBName),
    [DBPort] = lib_config:find(common, db_port),
    %% 上次操作可能出错
    catch emysql:remove_pool(PoolID),
    ?WARNING_MSG("MySQL connecting to ~p:~p ~p:~p ~p ~w", [DataBaseIP, DBPort, UserName, Password, DBName, Connections]),
    emysql:add_pool(PoolID, Connections, UserName, Password, DataBaseIP, DBPort, DBName2, utf8mb4),
    restore2(RoleID, PoolID),
    emysql:remove_pool(PoolID),
    ok.

restore2(RoleID, PoolID) ->
    TabList = [ Tab || #c_tab{tab = Tab, class = {role, _}} <- ?TABLE_INFO],
    DataList3 = get_role_restore_data(RoleID, PoolID, TabList, []),
    restore3(RoleID, DataList3).

restore3(RoleID, DataList) ->
    role_misc:kick_role(RoleID, ?ERROR_SYSTEM_ERROR_005),
    timer:sleep(1000),
    [begin
         db:insert(Tab, erlang:setelement(2, Value, RoleID))
     end|| {Tab, Value} <- DataList].

get_role_restore_data(_RoleID, _PoolID, [], DataAcc) ->
    DataAcc;
get_role_restore_data(RoleID, PoolID, [Tab|R], DataAcc) ->
    case db_lib:kv_lookup_by_pool_id(PoolID, Tab, RoleID) of
        [Value] ->
            DataAcc2 = [{Tab, Value}|DataAcc],
            get_role_restore_data(RoleID, PoolID, R, DataAcc2);
        _ ->
            get_role_restore_data(RoleID, PoolID, R, DataAcc)
    end.

read_role_data(DataBaseIP, DBPort, DBName, Tab, RoleID) ->
    read_role_data(DataBaseIP, DBPort, DBName, ?MYSQL_USER, ?MYSQL_PASSWORD, Tab, RoleID).
read_role_data(DataBaseIP, DBPort, DBName, UserName, Password, Tab, RoleID) ->
    PoolID = ?MODULE,
    Connections = ?DB_CONNECTIONS,
    %% 上次操作可能出错
    catch emysql:remove_pool(PoolID),
    ?WARNING_MSG("MySQL connecting to ~p:~p ~p:~p ~p ~w", [DataBaseIP, DBPort, UserName, Password, DBName, Connections]),
    emysql:add_pool(PoolID, Connections, UserName, Password, DataBaseIP, DBPort, DBName, utf8mb4),
    db_lib:kv_lookup_by_pool_id(PoolID, Tab, RoleID).
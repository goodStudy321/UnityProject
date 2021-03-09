%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     登录server
%%% @end
%%% Created : 19. 四月 2017 15:45
%%%-------------------------------------------------------------------
-module(login_server).

-behaviour(gen_server).
-include("global.hrl").
-include("proto/role_login.hrl").

%% API
-export([
    start/0,
    start_link/0
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-export([
    login_role/1,
    logout_role/1,
    create_role/1,
    del_role/1,
    role_rename/1,

    ban_account/2
]).

-export([
    get_role_name/1,
    get_account_role/1
]).

-define(SERVER, ?MODULE).
-define(MAX_CREATE_ROLE_NUM, 3).    %% 最大创角数量

-record(state, {}).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

login_role(Info) ->
    pname_server:call(?MODULE, {login_role, Info}).

logout_role(Info) ->
    pname_server:send(?MODULE, {logout_role, Info}).

create_role(Info) ->
    pname_server:call(?MODULE, {create_role, Info}).

del_role(Info) ->
    pname_server:call(?MODULE, {del_role, Info}).

role_rename(Info) ->
    pname_server:call(?MODULE, {role_rename, Info}).

ban_account(FromAccount, ToAccount) ->
    pname_server:call(?MODULE, {ban_account, FromAccount, ToAccount}).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    world_data:init_role_id_counter(),
    {ok, #state{}}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({login_role, Info}) ->
    do_login_role(Info);
do_handle({logout_role, Info}) ->
    do_logout_role(Info);
do_handle({create_role, Info}) ->
    do_create_role(Info);
do_handle({del_role, Info}) ->
    do_del_role(Info);
do_handle({role_rename, Info}) ->
    do_role_rename(Info);
do_handle({ban_account, FromAccount, ToAccount}) ->
    do_ban_account(FromAccount, ToAccount);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_login_role({AccountName, RolePID}) ->
    case catch check_can_login(AccountName, RolePID) of
        {ok, RoleIDList} ->
            set_role_pid(AccountName, [RolePID]),
            {ok, RoleIDList};
        create_account -> %% 第一次登录
            set_role_pid(AccountName, [RolePID]),
            RoleIDList = [],
            set_account_role(#r_account_role{account = AccountName, role_id_list = []}),
            {ok, RoleIDList};
        {login_again, OldRolePIDs} ->
            [?TRY_CATCH(notify_role_offline(OldRolePID))|| OldRolePID <- OldRolePIDs],
            set_role_pid(AccountName, [RolePID|OldRolePIDs]),
            ok;
        ok ->
            ok
    end.

check_can_login(AccountName, RolePID) ->
    OldRolePIDs = get_role_pid(AccountName),
    case OldRolePIDs =:= [RolePID] orelse OldRolePIDs =:= [] of
        true -> %% 只剩下自身的PID或者没有
            case get_account_role(AccountName) of
                [#r_account_role{role_id_list = RoleIDList}] ->
                    {ok, RoleIDList};
                _ ->
                    create_account
            end;
        _ ->
            case lists:member(RolePID, OldRolePIDs) of
                true -> %% 已经发过一次，直接返回ok
                    ok;
                _ ->
                    {login_again, OldRolePIDs}
            end
    end.

do_create_role({AccountName, Name}) ->
    case catch check_can_create(AccountName, Name) of
        {ok, AccountRole} ->
            do_create_role2(AccountRole, Name);
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_create(AccountName, Name) ->
    [#r_account_role{role_id_list = RoleIDList} = AccountRole] = get_account_role(AccountName),
    ?IF(erlang:length(RoleIDList) >= ?MAX_CREATE_ROLE_NUM, ?THROW_ERR(?ERROR_CREATE_ROLE_005), ok),
    check_role_name(Name),
    {ok, AccountRole}.

check_role_name(Name) ->
    case get_role_name(Name) of
        [#r_role_name{}] ->
            ?THROW_ERR(?ERROR_CREATE_ROLE_004);
        _ ->
            ok
    end,
    %% 离线竞技场机器人名字也要做个判断
    RobotNames = world_data:get_offline_solo_robot_names(),
    ?IF(lists:member(Name, RobotNames), ?THROW_ERR(?ERROR_CREATE_ROLE_004), ok),
    ok.

%% 创建一个账号
do_create_role2(AccountRole, Name) ->
    #r_account_role{account = AccountName, role_id_list = RoleIDList} = AccountRole,
    NewRoleID = world_data:update_role_id_counter(),
    RoleIDList2 = RoleIDList ++ [NewRoleID],
    AccountRole2 = AccountRole#r_account_role{role_id_list = RoleIDList2},
    set_role_name(#r_role_name{role_name = Name, role_id = NewRoleID}),
    set_account_role(AccountRole2),
    set_role_account(#r_role_account{role_id = NewRoleID, account = AccountName}),
    family_misc:check_automatic_key(NewRoleID),
    {ok, NewRoleID, RoleIDList2}.

do_del_role({AccountName, RoleID}) ->
    case catch check_del_role(AccountName, RoleID) of
        {ok, AccountRole} ->
            set_account_role(AccountRole),
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_del_role(AccountName, RoleID) ->
    [AccountRole] = get_account_role(AccountName),
    #r_account_role{role_id_list = RoleIDList} = AccountRole,
    ?IF(lists:member(RoleID, RoleIDList), ok, ?THROW_ERR(?ERROR_DEL_ROLE_001)),
    AccountRole2 = AccountRole#r_account_role{role_id_list = lists:delete(RoleID, RoleIDList)},
    {ok, AccountRole2}.

%% 角色重命名
do_role_rename({RoleID, OldRoleName, RoleName}) ->
    case catch check_role_name(RoleName) of
        ok ->
            del_role_name(OldRoleName),
            set_role_name(#r_role_name{role_name = RoleName, role_id = RoleID}),
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

do_logout_role({AccountName, RolePID}) ->
    OldRolePIDs = lists:delete(RolePID, get_role_pid(AccountName)),
    set_role_pid(AccountName, OldRolePIDs),
    case OldRolePIDs of
        [OneRole] -> %%只剩下最新的一个，这个时候可以通知对方进行重新登录了
            notify_role_login(OneRole);
        _ ->
            ok
    end.

do_ban_account(FromAccountName, ToAccountName) ->
    case get_account_role(FromAccountName) of
        [#r_account_role{role_id_list = FromRoleIDList} = FromAccount] ->
            case get_account_role(ToAccountName) of
                [#r_account_role{role_id_list = ToRoleIDList} = ToAccount] ->
                    case erlang:length(FromRoleIDList) + erlang:length(ToRoleIDList) =< ?MAX_CREATE_ROLE_NUM of
                        true ->
                            [ role_misc:kick_role(FromRoleID) || FromRoleID <- FromRoleIDList],
                            do_ban_account2(FromRoleIDList ++ ToRoleIDList, FromAccount, ToAccount);
                        _ ->
                            {error, max_role_num}
                    end;
                _ ->
                    do_ban_account2(FromRoleIDList, FromAccount, #r_account_role{account = ToAccountName})
            end;
        _ ->
            ok
    end.

do_ban_account2(RoleIDList, FromAccount, ToAccount) ->
    set_account_role(FromAccount#r_account_role{role_id_list = []}),
    set_account_role(ToAccount#r_account_role{role_id_list = RoleIDList}),
    ok.

notify_role_offline(RolePID) ->
    ?TRY_CATCH(pname_server:send(RolePID, {mod, role_login, notify_role_offline})).
notify_role_login(RolePID) ->
    pname_server:send(RolePID, {mod, role_login, notify_role_login}).

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_role_name(RoleName) ->
    db:insert(?DB_ROLE_NAME_P, RoleName).
get_role_name(Name) ->
    ets:lookup(?DB_ROLE_NAME_P, Name).
del_role_name(Name) ->
    db:delete(?DB_ROLE_NAME_P, Name).

get_account_role(AccountName) ->
    ets:lookup(?DB_ACCOUNT_ROLE_P, AccountName).
set_account_role(AccountRole) ->
    db:insert(?DB_ACCOUNT_ROLE_P, AccountRole).

set_role_account(RoleAccount) ->
    db:insert(?DB_ROLE_ACCOUNT_P, RoleAccount).

get_role_pid(AccountName) ->
    case erlang:get({?MODULE, role_pid, AccountName}) of
        List when erlang:is_list(List) -> List;
        _ -> []
    end.
set_role_pid(AccountName, RolePID) ->
    erlang:put({?MODULE, role_pid, AccountName}, RolePID).


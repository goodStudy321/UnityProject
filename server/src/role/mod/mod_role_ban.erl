%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     角色封禁
%%% @end
%%% Created : 02. 八月 2018 10:31
%%%-------------------------------------------------------------------
-module(mod_role_ban).
-author("laijichang").
-include("role.hrl").
-include("proto/gateway.hrl").
-include("web.hrl").

%% API
-export([
    handle/2
]).

-export([
    is_login_ban/1,
    is_chat_ban/1,
    is_chat_word_ban/1,
    is_ban/2,
    is_ip_ban/2,
    is_imei_ban/2,
    is_uid_ban/2
]).

-export([
    add_ban/3,
    del_ban/2
]).

handle({web_add_ban, BanType, Args}, State) ->
    do_web_add_ban(BanType, Args, State).

is_login_ban(RoleID) ->
    is_ban(RoleID, [?BAN_TYPE_LOGIN]).

is_chat_ban(RoleID) ->
    is_ban(RoleID, [?BAN_TYPE_CHAT]).

is_chat_word_ban(RoleID) ->
    is_ban(RoleID, [?BAN_TYPE_WORD_CHAT]).

is_ban(RoleID, TypeList) ->
    Now = time_tool:now(),
    case get_role_ban(RoleID) of
        [#r_role_ban{ban_list = BanList}] ->
            is_ban2(BanList, Now, TypeList);
        _ ->
            false
    end.

is_ban2([], _Now, _TypeList) ->
    false;
is_ban2([#r_ban{type = Type, end_time = EndTime}|R], Now, TypeList) ->
    case lists:member(Type, TypeList) of
        true ->
            ?IF(Now < EndTime orelse EndTime =:= 0, true, is_ban2(R, Now, TypeList));
        _ ->
            is_ban2(R, Now, TypeList)
    end.

is_ip_ban(IP, Now) ->
    BanIPs = world_data:get_ban_ips(),
    case lists:keyfind(IP, 1, BanIPs) of
        {IP, EndTime} when Now < EndTime ->
            true;
        _ ->
            false
    end.

is_imei_ban(Imei, Now) ->
    BanIPs = world_data:get_ban_imei(),
    case lists:keyfind(Imei, 1, BanIPs) of
        {Imei, EndTime} when Now < EndTime ->
            true;
        _ ->
            false
    end.

is_uid_ban(UID, Now) ->
    BanIPs = world_data:get_ban_uid(),
    case lists:keyfind(UID, 1, BanIPs) of
        {UID, EndTime} when Now < EndTime ->
            true;
        _ ->
            false
    end.

add_ban(RoleID, BanType, EndTime) ->
    Ban = #r_ban{type = BanType, end_time = EndTime},
    case get_role_ban(RoleID) of
        [#r_role_ban{ban_list = BanList} = RoleBan] ->
            BanList2 = lists:keystore(BanType, #r_ban.type, BanList, Ban),
            RoleBan2 = RoleBan#r_role_ban{ban_list = BanList2},
            set_role_ban(RoleBan2);
        _ ->
            RoleBan = #r_role_ban{role_id = RoleID, ban_list = [Ban]},
            set_role_ban(RoleBan)
    end,
    case BanType of
        ?BAN_TYPE_LOGIN ->
            role_misc:kick_role(RoleID, ?ERROR_SYSTEM_ERROR_026);
        _ ->
            ok
    end.

del_ban(RoleID, BanType) ->
    case get_role_ban(RoleID) of
        [#r_role_ban{ban_list = BanList} = RoleBan] ->
            BanList2 = lists:keydelete(BanType, #r_ban.type, BanList),
            RoleBan2 = RoleBan#r_role_ban{ban_list = BanList2},
            set_role_ban(RoleBan2);
        _ ->
            ok
    end.

do_web_add_ban(BanType, Args, State) ->
    RoleInfo =
        if
            BanType =:= ?BAN_TYPE_IP ->
                mod_role_dict:get_ip();
            BanType =:= ?BAN_TYPE_IMEI ->
                mod_role_dict:get_imei();
            BanType =:= ?BAN_TYPE_UID ->
                mod_role_dict:get_uid();
            true ->
                undefined
        end,
    ?IF(RoleInfo =:= Args, role_misc:kick_role(State#r_role.role_id, ?ERROR_SYSTEM_ERROR_026), ok),
    State.

get_role_ban(RoleID) ->
    ets:lookup(?DB_ROLE_BAN_P, RoleID).
set_role_ban(RoleBan) ->
    db:insert(?DB_ROLE_BAN_P, RoleBan).
%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     送花 收花
%%% @end
%%% Created : 17. 十二月 2018 17:54
%%%-------------------------------------------------------------------
-module(mod_role_flower).
-author("laijichang").
-include("proto/mod_role_flower.hrl").
-include("role.hrl").

%% API
-export([
    online/1,
    handle/2
]).

-export([
    send_other_flower/3
]).
-export([
    do_flower_send2/7
]).

online(State) ->
    #r_role{role_id = RoleID, role_private_attr = RolePrivateAttr} = State,
    #r_role_private_attr{charm = Charm} = RolePrivateAttr,
    common_misc:unicast(RoleID, #m_role_charm_toc{charm = Charm}),
    State.

send_other_flower(FromRoleID, ToRoleID, AddVal) ->
    case role_misc:is_online(ToRoleID) of
        true ->
            role_misc:info_role(ToRoleID, {mod, ?MODULE, {receive_flower, FromRoleID, AddVal}});
        _ ->
            world_offline_event_server:add_event(ToRoleID, {?MODULE, send_other_flower, [FromRoleID, ToRoleID, AddVal]})
    end.

handle({#m_flower_send_tos{to_role_id = ToRoleID, is_anonymous = IsAnonymous, type_id = TypeID, num = Num}, RoleID, _PID}, State) ->
    do_flower_send(RoleID, ToRoleID, IsAnonymous, TypeID, Num, State);
handle({receive_flower, FromRoleID, AddVal}, State) ->
    do_receive_flower(FromRoleID, AddVal, State);
handle({#m_flower_kiss_tos{to_role_id = ToRoleID}, RoleID, _PID}, State) ->
    do_flower_kiss(RoleID, ToRoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]),
    State.

%% 送花
do_flower_send(RoleID, ToRoleID, IsAnonymous, TypeID, Num, State) ->
    case catch check_flower_send(RoleID, ToRoleID, IsAnonymous, TypeID, Num, State) of
        {ok, BagDoings} ->
            State2 = mod_role_bag:do(BagDoings, State),
            do_flower_send2(RoleID, ToRoleID, TypeID, Num, IsAnonymous, true, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_flower_send_toc{err_code = ErrCode}),
            State
    end.

do_flower_send2(RoleID, ToRoleID, TypeID, Num, IsAnonymous, IsSendMsg, State) ->
    case db:lookup(?DB_ROLE_ATTR_P, ToRoleID) of
        [_] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    #r_role{role_attr = #r_role_attr{role_name = RoleName}} = State,
    #c_item{effect_args = EffectArgs} = mod_role_item:get_item_config(TypeID),
    AddVal = lib_tool:to_integer(EffectArgs) * Num,
    State2 = add_charm(AddVal, State),
    DataRecord = #m_flower_send_toc{},
    ?IF(IsSendMsg, common_misc:unicast(RoleID, DataRecord), ok),
    SendRoleName = ?IF(IsAnonymous, ?SEND_FLOWER_ANONYMOUS, RoleName),
    %% 999玫瑰发公告
    ?IF(TypeID =:= 31003, common_broadcast:send_world_common_notice(?NOTICE_FLOWER_999, [SendRoleName, common_role_data:get_role_name(ToRoleID)]), ok),
    case RoleID =/= ToRoleID of
        true ->
            world_friend_server:add_friendly([{RoleID, ToRoleID}], AddVal),
            DataRecord2 = #m_flower_receive_toc{
                is_anonymous = IsAnonymous,
                from_role_id = RoleID,
                from_role_name = RoleName,
                type_id = TypeID,
                num = Num
            },
            common_misc:unicast(ToRoleID, DataRecord2),
            send_other_flower(RoleID, ToRoleID, AddVal),
            act_couple:role_add_charm([{RoleID, AddVal}, {ToRoleID, AddVal}]);
        _ ->
            act_couple:role_add_charm([{RoleID, AddVal}]),
            ok
    end,
    State2.

check_flower_send(RoleID, ToRoleID, IsAnonymous, TypeID, Num, State) ->
    ?IF(RoleID =:= ToRoleID andalso not IsAnonymous, ?THROW_ERR(?ERROR_FLOWER_SEND_001), ok),
    #c_item{effect_type = EffectType} = mod_role_item:get_item_config(TypeID),
    ?IF(EffectType =:= ?ITEM_FLOWER, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    BagDoings = mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_FLOWER_SEND, State),
    {ok, BagDoings}.

%% 收花
do_receive_flower(FromRoleID, AddVal, State) ->
    OldList = mod_role_dict:get_receive_flower(),
    mod_role_dict:set_receive_flower([FromRoleID|OldList]),
    add_charm(AddVal, State).

%% 回吻
do_flower_kiss(RoleID, ToRoleID, State) ->
    case catch check_flower_kill(ToRoleID) of
        {ok, RoleList2} ->
            mod_role_dict:set_receive_flower(RoleList2),
            common_misc:unicast(RoleID, #m_flower_kiss_toc{}),
            DataRecord = #m_common_notice_toc{id = ?NOTICE_FLOWER_KISS_BACK, text_string = [mod_role_data:get_role_name(State)]},
            common_misc:unicast(ToRoleID, DataRecord);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_flower_kiss_toc{err_code = ErrCode})
    end,
    State.

check_flower_kill(ToRoleID) ->
    RoleList = mod_role_dict:get_receive_flower(),
    ?IF(lists:member(ToRoleID, RoleList), ok, ?THROW_ERR(?ERROR_FLOWER_KISS_001)),
    {ok, lists:delete(ToRoleID, RoleList)}.

%% 增加魅力值
add_charm(AddVal, State) ->
    #r_role{role_id = RoleID, role_private_attr = PrivateAttr} = State,
    #r_role_private_attr{charm = Charm} = PrivateAttr,
    Charm2 = Charm + AddVal,
    PrivateAttr2 = PrivateAttr#r_role_private_attr{charm = Charm2},
    common_misc:unicast(RoleID, #m_role_charm_toc{charm = Charm2}),
    State2 = State#r_role{role_private_attr = PrivateAttr2},
    State2.

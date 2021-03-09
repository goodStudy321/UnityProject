%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. 七月 2017 15:30
%%%-------------------------------------------------------------------
-module(mod_role_buff).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_map_actor.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    offline/1,
    loop/2,
    handle/2
]).

-export([
    get_pellet_exp_args/1
]).

-export([
    off_line_add_buff/1,
    off_line_remove_buff/1,
    add_buff/2,
    remove_buff/2,
    remove_buff_cross_server/2,
    add_buff_cross_server/2
]).

-export([
    do_add_buff/2,
    do_remove_buff/2,
    role_dead/1,
    role_quit_map/1,
    role_fight_status_change/1,
    role_leave_team/1,
    member_leave/2,
    remove_by_class/2
]).


add_buff_cross_server(BuffList, RoleID) ->
    node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, add_buff, [BuffList, RoleID]}).

add_buff(BuffList, RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, {add_buff, BuffList}});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, off_line_add_buff, [BuffList]})
    end.


remove_buff_cross_server(BuffList, RoleID) ->
    node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, remove_buff, [BuffList, RoleID]}).

remove_buff(BuffList, RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, {remove_buff, BuffList}});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, off_line_remove_buff, [BuffList]})
    end.

off_line_add_buff(BuffList) ->
    erlang:send(erlang:self(), {mod, ?MODULE, {add_buff, BuffList}}).

off_line_remove_buff(BuffList) ->
    erlang:send(erlang:self(), {mod, ?MODULE, {remove_buff, BuffList}}).

init(#r_role{role_id = RoleID, role_buff = undefined} = State) ->
    RoleBuff = #r_role_buff{role_id = RoleID},
    State#r_role{role_buff = RoleBuff};
init(State) ->
    State.

calc(State) ->
    #r_role{role_buff = RoleBuff, role_fight = #r_role_fight{base_attr = BaseAttr}} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    CalcAttr = common_buff:get_cal_attr(Buffs ++ Debuffs, BaseAttr),
    State#r_role{buff_attr = CalcAttr}.

online(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    OfflineTime = RoleAttr#r_role_attr.last_offline_time,
    Now = time_tool:now(),
    Buffs2 = get_online_buffs(Buffs, OfflineTime, Now, []),
    Debuffs2 = get_online_buffs(Debuffs, OfflineTime, Now, []),
    BuffStatus = common_buff:recal_status(Buffs2 ++ Debuffs2),
    RoleBuff2 = RoleBuff#r_role_buff{buff_status = BuffStatus, buffs = Buffs2, debuffs = Debuffs2},
    PBuffs = [common_misc:make_p_buff(Buff) || Buff <- Buffs2 ++ Debuffs2],
    mod_map_role:update_role_buff_status(mod_role_dict:get_map_pid(), RoleID, BuffStatus),
    common_misc:unicast(RoleID, #m_actor_buff_change_toc{actor_id = RoleID, update_list = PBuffs}),
    State#r_role{role_buff = RoleBuff2}.

offline(State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    Buffs2 = get_offline_buffs(Buffs, []),
    Debuffs2 = get_offline_buffs(Debuffs, []),
    RoleBuff2 = RoleBuff#r_role_buff{buffs = Buffs2, debuffs = Debuffs2},
    State#r_role{role_buff = RoleBuff2}.

loop(Now, State) ->
    #r_role{role_id = RoleID, role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, EffectList, IsCalc, IsStatus, DelIDList} = common_buff:loop(Now, Buffs, Debuffs),
    do_effect(RoleID, State, EffectList),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, [], DelIDList).

handle({add_buff, BuffList}, State) ->
    do_add_buff(BuffList, State);
handle({remove_buff, BuffList}, State) ->
    do_remove_buff(BuffList, State);
handle(shield_remove, State) ->
    do_shield_remove(State).

role_dead(State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, DelIDList, IsCalc, IsStatus} = remove_buff(Buffs, Debuffs, role_dead),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, [], DelIDList).

role_quit_map(State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, DelIDList, IsCalc, IsStatus} = remove_buff(Buffs, Debuffs, role_quit_map),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, [], DelIDList).

role_fight_status_change(State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, DelIDList, IsCalc, IsStatus} = remove_buff(Buffs, Debuffs, role_fight_status_change),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, [], DelIDList).

role_leave_team(State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, DelIDList, IsCalc, IsStatus} = remove_buff(Buffs, Debuffs, role_leave_team),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, [], DelIDList).

member_leave(LeaveRoleID, State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, DelIDList, IsCalc, IsStatus} = remove_buff(Buffs, Debuffs, {member_leave, LeaveRoleID}),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, [], DelIDList).

remove_by_class(BuffClass, State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, DelIDList, IsCalc, IsStatus} = remove_buff(Buffs, Debuffs, {buff_class, BuffClass}),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, [], DelIDList).

remove_buff(Buffs, Debuffs, RemoveFun) ->
    {Buffs2, DelList1, IsCalc1, IsStatus1} = remove_buff2(Buffs, RemoveFun),
    {DeBuffs2, DelList2, IsCalc2, IsStatus2} = remove_buff2(Debuffs, RemoveFun),
    {Buffs2, DeBuffs2, DelList1 ++ DelList2, IsCalc1 orelse IsCalc2, IsStatus1 orelse IsStatus2}.

remove_buff2(Buffs, RemoveFun) ->
    lists:foldl(
        fun(#r_buff{buff_id = BuffID, buff_attr = BuffAttr, from_actor_id = FromActorID} = Buff, {BuffsAcc, DelListAcc, IsCalcAcc, IsStatusAcc}) ->
            [#c_buff{remove_type = RemoveType, buff_class = BuffClassConfig}] = lib_config:find(cfg_buff, BuffID),
            IsRemove =
            case RemoveFun of
                role_dead ->
                    ?IS_BUFF_REMOVE_DEAD(RemoveType);
                role_quit_map ->
                    ?IS_BUFF_REMOVE_MAP(RemoveType);
                role_fight_status_change ->
                    ?IS_BUFF_REMOVE_FIGHT_STATUS(RemoveType);
                role_leave_team ->
                    ?IS_BUFF_REMOVE_TEAM(RemoveType);
                shield_remove ->
                    ?IS_BUFF_SHIELD_REMOVE(RemoveType);
                {member_leave, LeaveRoleID} ->
                    LeaveRoleID =:= FromActorID;
                {buff_class, BuffClass} ->
                    BuffClassConfig =:= BuffClass;
                true ->
                    false
            end,
            case IsRemove of
                true ->
                    IsCalcAcc2 = IsCalcAcc orelse lists:member(BuffAttr, ?BUFF_CALC_LIST),
                    IsStatusAcc2 = IsStatusAcc orelse lists:member(BuffAttr, ?BUFF_STATUS_LIST),
                    {BuffsAcc, [BuffID|DelListAcc], IsCalcAcc2, IsStatusAcc2};
                _ ->
                    {[Buff|BuffsAcc], DelListAcc, IsCalcAcc, IsStatusAcc}
            end
        end, {[], [], false, false}, Buffs).

get_pellet_exp_args(State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs} = RoleBuff,
    case lists:keyfind(?BUFF_PELLET_EXP, #r_buff.buff_class, Buffs) of
        #r_buff{buff_id = BuffID, cover_times = CoverTimes, start_time = StartTime, end_time = EndTime} ->
            [#c_buff{value = ValueArgs}] = lib_config:find(cfg_buff, BuffID),
            Props = common_misc:get_string_props(ValueArgs, CoverTimes),
            case lists:keyfind(?ATTR_MONSTER_EXP, #p_kv.id, Props) of
                #p_kv{val = Val} ->
                    {Val, EndTime - StartTime};
                _ ->
                    {0, 0}
            end;
        _ ->
            {0, 0}
    end.

do_shield_remove(State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, DelIDList, IsCalc, IsStatus} = remove_buff(Buffs, Debuffs, shield_remove),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, [], DelIDList).

do_add_buff(BuffList, State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList} = common_buff:add_buff(BuffList, Buffs, Debuffs),
    State2 = do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList),
    ?IF(UpdateList =/= [], mod_role_skill:buff_trigger(UpdateList, State2), State2).

do_remove_buff(BuffList, State) ->
    #r_role{role_buff = RoleBuff} = State,
    #r_role_buff{buffs = Buffs, debuffs = Debuffs} = RoleBuff,
    {Buffs2, Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList} = common_buff:remove_buff(BuffList, Buffs, Debuffs),
    do_update(State, RoleBuff, Buffs2, Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList).

do_effect(_RoleID, _State, []) ->
    ok;
do_effect(RoleID, State, [Effect|R]) ->
    MapPID = mod_role_dict:get_map_pid(),
    case Effect of
        {?BUFF_POISON, BuffID, FromActorID, Value} ->
            mod_map_role:role_buff_reduce_hp(MapPID, RoleID, FromActorID, Value, ?BUFF_POISON, BuffID);
        {?BUFF_BURN, BuffID, FromActorID, Value} ->
            mod_map_role:role_buff_reduce_hp(MapPID, RoleID, FromActorID, Value, ?BUFF_BURN, BuffID);
        {?BUFF_ADD_HP, BuffID, _FromActorID, Value} ->
            #r_role{role_fight = #r_role_fight{fight_attr = #actor_fight_attr{max_hp = MaxHp}}} = State,
            HealValue = lib_tool:ceil(MaxHp * Value / ?RATE_10000),
            mod_map_role:role_buff_heal(MapPID, RoleID, HealValue, ?BUFF_ADD_HP, BuffID);
        {?BUFF_ATTACK_HEAL, BuffID, _FromActorID, Value} ->
            #r_role{role_fight = #r_role_fight{fight_attr = #actor_fight_attr{attack = Attack}}} = State,
            HealValue = lib_tool:ceil(Attack * Value / ?RATE_10000),
            mod_map_role:role_buff_heal(MapPID, RoleID, HealValue, ?BUFF_ADD_HP, BuffID);
        {?BUFF_LEVEL_HP_BUFF, BuffID, _FromActorID, Value} ->
            Level = mod_role_data:get_role_level(State),
            HealValue = lib_tool:ceil(Level * Value),
            mod_map_role:role_buff_heal(MapPID, RoleID, HealValue, ?BUFF_ADD_HP, BuffID);
        Error ->
            ?ERROR_MSG("unknow match Error :~w", [Error])
    end,
    do_effect(RoleID, State, R).

do_update(State, RoleBuff, Buffs, Debuffs, IsCalc, IsStatus, UpdateList, DelIDList) ->
    #r_role{role_id = RoleID} = State,
    AllBuffs = Buffs ++ Debuffs,
    MapPID = mod_role_dict:get_map_pid(),
    case UpdateList =/= [] orelse DelIDList =/= [] of
        true ->
            PBuffs = [common_misc:make_p_buff(Buff) || Buff <- UpdateList],
            common_misc:unicast(RoleID, #m_actor_buff_change_toc{actor_id = RoleID, update_list = PBuffs, del_list = DelIDList}),
            AllBuffIDs = [BuffID || #r_buff{buff_id = BuffID} <- AllBuffs],
            UpdateIDList = [BuffID || #r_buff{buff_id = BuffID} <- UpdateList],
            mod_map_role:update_role_buffs(MapPID, RoleID, AllBuffIDs, UpdateIDList, DelIDList),
            try_update_shield(UpdateList, DelIDList, State);
        _ ->
            ok
    end,
    case IsStatus of
        true ->
            BuffStatus = common_buff:recal_status(AllBuffs),
            RoleBuff2 = RoleBuff#r_role_buff{buff_status = BuffStatus, buffs = Buffs, debuffs = Debuffs},
            mod_map_role:update_role_buff_status(MapPID, RoleID, BuffStatus);
        _ ->
            RoleBuff2 = RoleBuff#r_role_buff{buffs = Buffs, debuffs = Debuffs}
    end,
    State2 = State#r_role{role_buff = RoleBuff2},
    case IsCalc of
        true ->
            mod_role_fight:calc_attr_and_update(calc(State2));
        _ ->
            State2
    end.

get_online_buffs([], _Offline, _Now, Acc) ->
    Acc;
get_online_buffs([Buff|R], Offline, Now, Acc) ->
    #r_buff{buff_id = BuffID, end_time = EndTime} = Buff,
    [#c_buff{offline_type = OfflineType}] = lib_config:find(cfg_buff, BuffID),
    Acc2 =
    if
        OfflineType =:= ?BUFF_OFFLINE_NOT_COUNT ->  %% 下线的时间再加上EndTime
            EndTime2 = EndTime + (Now - Offline),
            [Buff#r_buff{end_time = EndTime2}|Acc];
        true ->
            [Buff|R]
    end,
    get_online_buffs(R, Offline, Now, Acc2).

get_offline_buffs([], Acc) ->
    Acc;
get_offline_buffs([Buff|R], Acc) ->
    #r_buff{buff_id = BuffID} = Buff,
    [#c_buff{offline_type = OfflineType}] = lib_config:find(cfg_buff, BuffID),
    Acc2 =
    if
        OfflineType =:= ?BUFF_OFFLINE_CLEAR -> %% 下线清掉
            Acc;
        true ->
            [Buff|Acc]
    end,
    get_offline_buffs(R, Acc2).

try_update_shield(UpdateList, DelIDList, State) ->
    RoleID = State#r_role.role_id,
    case is_shied_remove(DelIDList) of
        true ->
            mod_map_role:update_role_shield(mod_role_dict:get_map_pid(), RoleID, 0);
        _ ->
            case lists:keyfind(?BUFF_SHIELD, #r_buff.buff_attr, UpdateList) of
                #r_buff{buff_id = BuffID} ->
                    MaxHp = mod_role_data:get_role_max_hp(State),
                    [#c_buff{value = ValueArgs}] = lib_config:find(cfg_buff, BuffID),
                    Shield = lib_tool:ceil(MaxHp * lib_tool:to_integer(ValueArgs)/?RATE_10000),
                    mod_map_role:update_role_shield(mod_role_dict:get_map_pid(), RoleID, Shield);
                _ ->
                    ok
            end
    end.

is_shied_remove([]) ->
    false;
is_shied_remove([DelID|R]) ->
    [#c_buff{buff_attr = BuffAttr}] = lib_config:find(cfg_buff, DelID),
    ?IF(BuffAttr =:= ?BUFF_SHIELD, true, is_shied_remove(R)).

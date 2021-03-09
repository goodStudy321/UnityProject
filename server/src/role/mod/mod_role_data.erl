-module(mod_role_data).
-include("role.hrl").

-export([
    pre_init/1,
    day_reset/1,
    zero/1,
    loop_min/2,
    loop_10min/2,
    offline/1
]).

-export([
    get_role_level/1,
    get_role_relive_level/1,
    get_role_name/1,
    get_role_game_channel_id/1,
    get_role_map_id/1,
    get_role_max_hp/1,
    get_role_power/1
]).

pre_init(State) ->
    Now = time_tool:now(),
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_private_attr = PrivateAttr, role_fight = RoleFight} = State,
    #r_device{
        device_name = DeviceName,
        os_type = OsType,
        os_ver = OsVer,
        net_type = NetType,
        imei = IMEI,
        package_name = PackageName,
        width = Width,
        height = Height} = mod_role_dict:get_device_args(),
    PrivateAttr2 = PrivateAttr#r_role_private_attr{
        last_login_ip = mod_role_dict:get_ip(),
        device_name = DeviceName,
        os_type = OsType,
        os_ver = OsVer,
        net_type = NetType,
        imei = IMEI,
        package_name = PackageName,
        width = Width,
        height = Height,
        last_login_time = Now,
        online_calc_time = Now
    },
    mod_role_dict:set_category(RoleAttr#r_role_attr.category),
    RoleFight2 = ?IF(RoleFight =:= undefined, #r_role_fight{role_id = RoleID, base_attr = #actor_fight_attr{}}, RoleFight),
    State#r_role{role_private_attr = PrivateAttr2, role_fight = RoleFight2}.

zero(State) ->
    State2 = do_calc_online_time(State),
    #r_role{role_private_attr = PrivateAttr} = State2,
    State2#r_role{role_private_attr = PrivateAttr#r_role_private_attr{today_online_time = 0}}.

day_reset(State) ->
    #r_role{role_private_attr = PrivateAttr} = State,
    State#r_role{role_private_attr = PrivateAttr#r_role_private_attr{today_online_time = 0}}.

loop_min(_Now, State) ->
    role_login:log_role_status(State),
    do_calc_online_time(State).

loop_10min(_Now, State) ->
    role_server:dump_data(State),
    State.

offline(State) ->
    do_calc_online_time(State).

do_calc_online_time(State) ->
    Now = time_tool:now(),
    #r_role{role_private_attr = PrivateAttr} = State,
    #r_role_private_attr{
        total_online_time = TotalOnlineTime,
        today_online_time = TodayOnlineTime,
        online_calc_time = OnlineCalcTime} = PrivateAttr,
    AddTime = Now - OnlineCalcTime,
    PrivateAttr2 = PrivateAttr#r_role_private_attr{
        total_online_time = TotalOnlineTime + AddTime,
        today_online_time = TodayOnlineTime + AddTime,
        online_calc_time = Now},
    State#r_role{role_private_attr = PrivateAttr2}.

get_role_level(State) ->
    State#r_role.role_attr#r_role_attr.level.

get_role_relive_level(State) ->
    State#r_role.role_relive#r_role_relive.relive_level.

get_role_name(State) ->
    State#r_role.role_attr#r_role_attr.role_name.

get_role_game_channel_id(State) ->
    State#r_role.role_attr#r_role_attr.game_channel_id.

get_role_map_id(State) ->
    State#r_role.role_map#r_role_map.map_id.

get_role_max_hp(State) ->
    State#r_role.role_fight#r_role_fight.fight_attr#actor_fight_attr.max_hp.

get_role_power(State) ->
    State#r_role.role_attr#r_role_attr.power.
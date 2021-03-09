%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2019 11:39
%%%-------------------------------------------------------------------
-module(mod_role_bless).
-author("WZP").
-include("role.hrl").
-include("proto/mod_role_bless.hrl").
-include("proto/mod_role_online.hrl").
-include("vip.hrl").
-include("bless.hrl").
-include("role_extra.hrl").

%% API
-export([
    function_open/1,
    online_i/1,
    day_reset/1,
    zero/1,
    handle/2
]).

-export([
    gm_set/3,
    max_power_add/2,
    vip_level_up/1,
    vip_expire/1,
    loop_min/2,
    level_up/2,
    war_god/2,
    get_rate/2
]).

-export([
    add_times/2
]).

-export([
    get_resource_retrieve_times/1,
    get_base_times/0,
    gm_time_add/2,
    calc_rate/1,
    calc_rate_shell/1
]).

calc_rate_shell(RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {?MODULE, calc_rate, []});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, calc_rate_shell, [RoleID]})
    end.

calc_rate(#r_role{role_bless = undefined} = State) ->
    State;
calc_rate(#r_role{role_bless = RoleBless, role_attr = RoleAttr, role_confine = RoleConfine} = State) ->
    [LevelConfig] = lib_config:find(cfg_role_level, RoleAttr#r_role_attr.level),
    PowerAdd = get_rate(1, RoleAttr#r_role_attr.max_power div 10000),
    case RoleConfine =/= undefined of
        true ->
            WarSpiritNum = erlang:length(RoleConfine#r_role_confine.war_spirit_list);
        _ ->
            WarSpiritNum = 0
    end,
    WarSpiritAdd = get_rate(2, WarSpiritNum),
    RoleBless2 = RoleBless#r_role_bless{level_add = LevelConfig#c_role_level.passive_bless_exp, power_add = PowerAdd, war_spirit_add = WarSpiritAdd},
    online_info(State#r_role{role_bless = RoleBless2}).



gm_time_add(#r_role{role_id = RoleID, role_bless = RoleBless} = State, Time) ->
    ExpAdd1 = mod_role_world_level:get_world_level_add(State),
    AddExp2 = get_exp(RoleBless, ExpAdd1, Time),
    State2 = mod_role_level:do_add_exp(State, AddExp2, ?EXP_ADD_FROM_PASSIVE_BLESS),
    common_misc:unicast(RoleID, #m_bless_reward_online_toc{exp = AddExp2, time = Time,
                                                           old_level = State2#r_role.role_attr#r_role_attr.level, now_level = State2#r_role.role_attr#r_role_attr.level}),
    State2.


function_open(#r_role{role_bless = undefined, role_id = RoleID, role_attr = #r_role_attr{level = Level, max_power = MaxPower}, role_confine = RoleConfine} = State) ->
    WarSpiritAdd = case RoleConfine =:= undefined of
                       true ->
                           0;
                       _ ->
                           mod_role_bless:get_rate(2, erlang:length(RoleConfine#r_role_confine.war_spirit_list))
                   end,
    PowerAdd = mod_role_bless:get_rate(1, MaxPower div 10000),
    [LevelConfig] = lib_config:find(cfg_role_level, Level),
    RoleBless = #r_role_bless{role_id = RoleID, war_spirit_add = WarSpiritAdd, power_add = PowerAdd, level_add = LevelConfig#c_role_level.passive_bless_exp, settle_time = time_tool:now()},
    online_info(State#r_role{role_bless = RoleBless});
function_open(State) ->
    State.


online_i(#r_role{role_bless = undefined} = State) ->
    State;
online_i(#r_role{role_bless = RoleBless} = State) ->
    online_info(State),
    Now = time_tool:now(),
    RoleBless2 = RoleBless#r_role_bless{settle_time = Now},
    State2 = State#r_role{role_bless = RoleBless2},
    ExpAdd1 = mod_role_world_level:get_world_level_add(State),
    AddExp2 = get_exp(RoleBless, ExpAdd1, Now - RoleBless#r_role_bless.settle_time),
    State3 = mod_role_level:do_add_exp(State2, AddExp2, ?EXP_ADD_FROM_PASSIVE_BLESS),
    {ok, State3, AddExp2, Now - RoleBless#r_role_bless.settle_time, State2#r_role.role_attr#r_role_attr.level, State3#r_role.role_attr#r_role_attr.level}.

online_info(#r_role{role_bless = undefined} = State) ->
    State;
online_info(#r_role{role_bless = RoleBless, role_id = RoleID} = State) ->
    PowerAddID = get_rate_id(1, RoleBless#r_role_bless.power_add),
    WarSpiritAddID = get_rate_id(2, RoleBless#r_role_bless.war_spirit_add),
    common_misc:unicast(RoleID, #m_bless_info_toc{today_times = RoleBless#r_role_bless.today_times, all_times = RoleBless#r_role_bless.times,
                                                  power_add = PowerAddID, war_spirit_add = WarSpiritAddID, exp = RoleBless#r_role_bless.level_add * 5,
                                                  add_times = RoleBless#r_role_bless.add_times}),
    State.

add_times(_AddTimes, #r_role{role_bless = undefined} = State) ->
    State;
add_times(AddTimes, State) ->
    #r_role{role_bless = RoleBless} = State,
    #r_role_bless{add_times = OldAddTimes} = RoleBless,
    RoleBless2 = RoleBless#r_role_bless{add_times = OldAddTimes + AddTimes},
    State2 = State#r_role{role_bless = RoleBless2},
    online_info(State2).



get_rate_id(Type, Rate) ->
    List = cfg_bless_rate:list(),
    get_rate_id(List, Type, Rate).

get_rate_id([], Type, _Rate) ->
    case Type of
        1 ->
            111;
        _ ->
            206
    end;
get_rate_id([{_, Info}|T], Type, Rate) ->
    case Info#c_bless_rate.type =:= Type andalso Rate =:= Info#c_bless_rate.rate of
        true ->
            Info#c_bless_rate.id;
        _ ->
            get_rate_id(T, Type, Rate)
    end.


get_rate(Type, Arg) ->
    List = cfg_bless_rate:list(),
    get_rate(List, Type, Arg, 0).

get_rate([], _Type, _Arg, Rate) ->
    Rate;
get_rate([{_, Info}|T], Type, Arg, Rate) ->
    case Info#c_bless_rate.type =:= Type andalso Arg >= Info#c_bless_rate.value of
        false ->
            get_rate(T, Type, Arg, Rate);
        _ ->
            case Info#c_bless_rate.rate > Rate of
                true ->
                    get_rate(T, Type, Arg, Info#c_bless_rate.rate);
                _ ->
                    get_rate(T, Type, Arg, Rate)
            end
    end.

loop_min(_Now, #r_role{role_bless = undefined} = State) ->
    State;
loop_min(Now, #r_role{role_bless = RoleBless} = State) ->
    RoleBless2 = RoleBless#r_role_bless{settle_time = Now},
    State2 = State#r_role{role_bless = RoleBless2},
    ExpAdd1 = mod_role_world_level:get_world_level_add(State),
    AddExp2 = get_exp(RoleBless, ExpAdd1, (Now - RoleBless#r_role_bless.settle_time)),
    mod_role_level:do_add_exp(State2, AddExp2, ?EXP_ADD_FROM_PASSIVE_BLESS).


get_exp(RoleBless, WorldAdd, Time) ->
    AddExp = RoleBless#r_role_bless.level_add * Time,
%%    ?WARNING_MSG("-----------RoleBless#r_role_bless.level_add-----~w",[RoleBless#r_role_bless.level_add]),
%%    ?WARNING_MSG("-----------Time----~w",[Time]),
%%    ?WARNING_MSG("----------------~w",[AddExp]),
%%    ?WARNING_MSG("----------------~w",[WorldAdd]),
%%    ?WARNING_MSG("----------------~w",[(WorldAdd + RoleBless#r_role_bless.power_add * 100 + RoleBless#r_role_bless.war_spirit_add * 100 + 10000) / 10000]),
    lib_tool:ceil(AddExp * (WorldAdd + RoleBless#r_role_bless.power_add * 100 + RoleBless#r_role_bless.war_spirit_add * 100 + 10000) / 10000).



day_reset(#r_role{role_bless = undefined} = State) ->
    State;
day_reset(#r_role{role_bless = RoleBless} = State) ->
    RoleBless2 = RoleBless#r_role_bless{today_times = 0, add_times = 0},
    State#r_role{role_bless = RoleBless2}.


level_up(_, #r_role{role_bless = undefined} = State) ->
    State;
level_up(Level, #r_role{role_bless = RoleBless} = State) ->
    [LevelConfig] = lib_config:find(cfg_role_level, Level),
    RoleBless2 = RoleBless#r_role_bless{level_add = LevelConfig#c_role_level.passive_bless_exp},
    State2 = State#r_role{role_bless = RoleBless2},
    online_info(State2).


max_power_add(_, #r_role{role_bless = undefined} = State) ->
    State;
max_power_add(MaxPower, #r_role{role_bless = RoleBless} = State) ->
    PowerAdd = get_rate(1, MaxPower div 10000),
    RoleBless2 = RoleBless#r_role_bless{power_add = PowerAdd},
    State2 = State#r_role{role_bless = RoleBless2},
    online_info(State2).

war_god(_, #r_role{role_bless = undefined} = State) ->
    State;
war_god(WarSpiritNum, #r_role{role_bless = RoleBless} = State) ->
    WarSpiritAdd = get_rate(2, WarSpiritNum),
    RoleBless2 = RoleBless#r_role_bless{war_spirit_add = WarSpiritAdd},
    State2 = State#r_role{role_bless = RoleBless2},
    online_info(State2).


zero(State) ->
    online_info(State).

vip_level_up(State) ->
    online_info(State).

vip_expire(State) ->
    online_info(State).


handle({#m_bless_reward_tos{}, RoleID, _PID}, State) ->
    do_bless(RoleID, State).


do_bless(RoleID, State) ->
    case catch check_can_get(State) of
        {ok, State2, AssetDoing, AddPetExp, BagDoing, PetGoods, AddSilver, GoodsList, Exp, TodayTimes, Times} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_pet:add_exp(AddPetExp, State3),
            State5 = mod_role_bag:do(BagDoing, State4),
            State6 = mod_role_level:do_add_exp(State5, Exp, ?EXP_ADD_FROM_BLESS),
            common_misc:unicast(RoleID, #m_bless_reward_toc{reward = GoodsList, pet_goods = PetGoods, copper = AddSilver, exp = Exp, today_times = TodayTimes, all_times = Times}),
            hook_role:bless(State6, 1);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bless_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get(#r_role{role_bless = RoleBless, role_attr = RoleAttr} = State) ->
    [GlobalConfig] = lib_config:find(cfg_global, ?BLESS_GLOBAL),
    [LevelConfig] = lib_config:find(cfg_role_level, RoleAttr#r_role_attr.level),
    [BaseTimes, AddLimit] = GlobalConfig#c_global.list,
    ?IF(get_all_bless_times(State, BaseTimes, RoleBless#r_role_bless.add_times) > RoleBless#r_role_bless.today_times, ok, ?THROW_ERR(?ERROR_BLESS_REWARD_001)),
    [Config] = lib_config:find(cfg_bless, RoleBless#r_role_bless.today_times + 1),
    AssetDoing = ?IF(RoleBless#r_role_bless.today_times =:= 0, [], mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Config#c_bless.exp_need, ?ASSET_GOLD_REDUCE_FROM_BLESS, State)),
    NowTimes = erlang:min(AddLimit, RoleBless#r_role_bless.times + 1),
    RoleBless2 = RoleBless#r_role_bless{today_times = RoleBless#r_role_bless.today_times + 1, times = NowTimes},
    FightMin = 60 + RoleBless#r_role_bless.times,
    State2 = State#r_role{role_bless = RoleBless2},
    {AddSilver, AddPetExp, PetGoods, GoodsList, State3} = mod_role_world_robot:get_off_line_reward(State2, FightMin),
    BagDoing = [{create, ?ITEM_GAIN_BLESS, GoodsList}],
    mod_role_bag:check_bag_empty_grid(GoodsList, State3),   %%检查包包空间够不够
    AssetDoing2 = [{add_silver, ?ASSET_SILVER_ADD_FROM_BLESS, AddSilver}],
    AssetDoing3 = AssetDoing ++ AssetDoing2,
    ExpAdd1 = mod_role_world_level:get_world_level_add(State3),
    Exp = LevelConfig#c_role_level.bless_exp * (60 + NowTimes) * (ExpAdd1 + 10000) div 600000,  %%  LevelConfig#c_role_level.bless_exp * (60 + NowTimes) /60 * ExpAdd1 / 10000
    {ok, State3, AssetDoing3, AddPetExp, BagDoing, PetGoods, AddSilver, GoodsList, Exp, RoleBless2#r_role_bless.today_times, RoleBless2#r_role_bless.times}.

get_all_bless_times(State, BaseTimes, AddTimes) ->
    BaseTimes + AddTimes + mod_role_vip:get_bless_add_times(State).

get_resource_retrieve_times(State) ->
    #r_role{role_bless = RoleBless} = State,
    case RoleBless of
        #r_role_bless{times = UseTimes, add_times = AddTimes} ->
            BaseTimes = get_base_times(),
            get_all_bless_times(State, BaseTimes, AddTimes) - UseTimes;
        _ ->
            0
    end.

get_base_times() ->
    [BaseTimes|_] = common_misc:get_global_list(?BLESS_GLOBAL),
    BaseTimes.

gm_set(#r_role{role_bless = RoleBless, role_id = RoleID} = State, Times1, Times2) ->
    RoleBless2 = RoleBless#r_role_bless{today_times = Times1, times = Times2},
    common_misc:unicast(RoleID, #m_bless_info_toc{today_times = Times1, all_times = Times2}),
    State#r_role{role_bless = RoleBless2}.

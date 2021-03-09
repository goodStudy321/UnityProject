%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     role_server内部
%%% @end
%%% Created : 12. 六月 2017 11:01
%%%-------------------------------------------------------------------
-module(hook_role).
-author("laijichang").
-include("role.hrl").
-include("mission.hrl").
-include("confine.hrl").
-include("rank.hrl").
-include("bg_act.hrl").
-include("act_oss.hrl").
-include("discount_pay.hrl").
-include("daily_liveness.hrl").
%% API
-export([
    level_up/3,
    mission_complete/3,
    kill_monster/4,
    kill_world_boss/2,
    role_online/1,
    role_dead/1,
    role_quit_map/1,
    role_pre_enter/5,
    role_enter_map/2,
    role_pay/5,
    role_use_gold/3,
    role_use_bind_gold/2,
    role_add_silver/2,
    role_vip_expire/1,
    role_vip_level_up/3,
    role_join_family/1,
    role_leave_family/1,
    role_family_title_change/2,
    role_rename/2,
    role_activity_trigger/2,
    role_first_recharge/1,
    role_solo/1,
    solo_win/2,
    equip_treasure/2,
    rune_treasure/2,
    bless/2,
    trevi_fountain/2,
    limitedtime_buy/1,
    do_fairy/1,
    marry/2,
    divorce/1,
    add_daily_liveness/2,
    skill_open/2,
    learn_skill/2,
    family_task_finish/2,
    escort_finish/2,
    kill_five_elements_boss/2,
    do_solo_trigger/3,
    auction_sell/2,
    money_tree/1,
    rob_escort/2,
    finish_copy_exp/1,
    rob_escort_back/2
]).

level_up(State, OldLevel, NewLevel) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{game_channel_id = GameChannelID}} = State,
    StateFunc =
    [
        fun(StateAcc) -> role_server:dump_table(?DB_ROLE_ATTR_P, StateAcc) end,
        fun(StateAcc) -> mod_role_mission:condition_update(StateAcc) end,
        fun(StateAcc) -> mod_role_friend:update(StateAcc) end,
        fun(StateAcc) -> mod_role_achievement:level_up(NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_equip:level_up(NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_act:level_up(OldLevel, NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_act:level_up2(OldLevel, NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_cycle_act:level_up(OldLevel, NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_act_rank:level_up(StateAcc) end,
        fun(StateAcc) -> mod_role_letter:level_up(StateAcc) end,
        fun(StateAcc) -> mod_role_confine:level_up(NewLevel, OldLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_bg_act:level_up(OldLevel, NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_mythical_equip:level_up(NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_boss_reward:level_up(OldLevel, NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_level_panicbuy:level_up(OldLevel, NewLevel, StateAcc) end, % 等级限时抢购的等级时弹出抢购窗口
        fun(StateAcc) -> mod_role_week_card:level_up(OldLevel, NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_world_boss:level_up(OldLevel, NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_discount_pay:condition_update(StateAcc) end,
        fun(StateAcc) -> mod_role_daily_buy:condition_update(StateAcc) end,
        fun(StateAcc) -> mod_role_day_target:level_up(StateAcc) end,
        fun(StateAcc) -> mod_role_bless:level_up(NewLevel, StateAcc) end
    ],
    State2 = role_server:execute_state_fun(StateFunc, State),   %%先初始化State-> State2   再用State2 执行FuncList    目前只有mod_role_fairy:system_open->mod_role_act:level_up对此有顺序要求
    MapPID = mod_role_dict:get_map_pid(),
    FuncList =
    [
        fun() ->
            gateway_misc:role_level_and_game_channel_id(mod_role_dict:get_gateway_pid(), NewLevel, GameChannelID) end,
        fun() -> mod_map_role:update_role_level(MapPID, RoleID, NewLevel) end,
        fun() -> mod_map_role:role_add_hp(MapPID, RoleID, 100000000) end,
        fun() -> mod_role_function:trigger_function(RoleID, ?FUNCTION_TYPE_LEVEL, NewLevel) end,
        fun() -> mod_role_online:notify_info(State2) end,
        fun() -> mod_role_solo:level_up(State2) end,
        fun() -> mod_role_rank:update_rank(?RANK_ROLE_LEVEL, {RoleID, NewLevel, time_tool:now()}) end,
        fun() -> mod_role_team:role_level(State2) end,
        fun() -> mod_role_survey:level_up(OldLevel, NewLevel, State2) end,
        fun() -> mod_role_activity:level_up(OldLevel, NewLevel, State2) end,
        fun() -> mod_role_immortal_soul:level_up(OldLevel, NewLevel, State2) end,
        fun() -> mod_role_pf:level_up_log(State2) end,
        fun() -> mod_role_marry:level_up(OldLevel, NewLevel, State2) end,
        fun() -> mod_role_node:update_role_cross_data(State2) end,
        fun() -> mod_role_act_accrecharge:level_up(OldLevel, NewLevel, State2) end,
        fun() -> mod_role_demon_boss:level_up(OldLevel, NewLevel, State2) end,
        fun() -> mod_role_chat:level_up(OldLevel, NewLevel, State2) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    State2.

mission_complete(MissionID, Type, State) ->
    #r_role{role_id = RoleID} = State,
    StateFunc =
    [
        fun(StateAcc) ->
            if
                Type =:= ?MISSION_TYPE_RING ->
                    StateAcc2 = mod_role_daily_liveness:trigger_daily_liveness(StateAcc, ?LIVENESS_DAILY_MISSION),
                    StateAcc3 = mod_role_achievement:ring_mission(MissionID, StateAcc2),
                    StateAcc4 = mod_role_day_target:ring_mission(StateAcc3),
                    StateAcc5 = mod_role_bg_act_mission:daily_mission_treasure(StateAcc4),
                    StateAcc6 = mod_role_act_os_second:do_task(StateAcc5, ?OSS_DAILY_TASK, 1),
                    StateAcc7 = mod_role_act_otf:do_task(StateAcc6, ?OSS_DAILY_TASK, 1),
                    mod_role_cycle_mission:daily_mission_treasure(StateAcc7);
                Type =:= ?MISSION_TYPE_BRANCH ->
                    mod_role_relive:mission_complete(MissionID, State);
                Type =:= ?MISSION_TYPE_MAIN ->
                    State2 = mod_role_chapter:add_chapter(MissionID, State),
                    State3 = mod_role_confine:main_mission(State2, MissionID),
                    mod_role_copy:main_mission(MissionID, State3);
                true ->
                    StateAcc
            end
        end
    ],
    FuncList =
    [
        fun() ->
            ?IF(Type =:= ?MISSION_TYPE_MAIN, mod_role_function:trigger_function(RoleID, ?FUNCTION_TYPE_MISSION, MissionID), ok) end,
        fun() -> ?IF(Type =:= ?MISSION_TYPE_RING, mod_role_log_statistics:log_ring_mission(State), ok) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

kill_monster(TypeID, MonsterLevel, MonsterPos, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_mission:kill_monster(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_function:do_trigger_function(?FUNCTION_TYPE_KILL_MONSTER, TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_extra:first_drop(TypeID, MonsterPos, StateAcc) end,
        fun(StateAcc) -> mod_role_achievement:kill_monster(TypeID, MonsterLevel, StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

kill_world_boss(TypeID, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_god_book:kill_world_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_mission:world_boss_trigger(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_act_hunt_boss:kill_world_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_confine:kill_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_day_target:kill_world_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_bg_act_mission:kill_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_cycle_mission:kill_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_act_os_second:kill_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_act_otf:kill_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_boss_reward:kill_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_world_boss:kill_world_boss(TypeID, StateAcc) end,
        fun(StateAcc) -> mod_role_daily_liveness:kill_boss(TypeID, StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

role_online(State) ->
    #r_role{role_id = RoleID} = State,
    FuncList =
    [
        fun() -> world_pay_server:role_online(RoleID) end,
        fun() -> world_log_statistics_server:role_online(RoleID) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList].

role_dead(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_buff:role_dead(StateAcc) end,
        fun(StateAcc) -> mod_role_world_boss:role_dead(StateAcc) end,
        fun(StateAcc) -> mod_role_achievement:add_role_dead(StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

role_quit_map(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_buff:role_quit_map(StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

role_pre_enter(BagDoings, IsFirst, _OldMapID, PreEnterMap, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_daily_liveness:role_pre_enter(StateAcc) end,
        fun(StateAcc) -> mod_role_extra:role_pre_enter(StateAcc) end,
        fun(StateAcc) -> mod_role_hunt_treasure:role_pre_enter(StateAcc) end,
        fun(StateAcc) -> mod_role_bg_act_mission:role_pre_enter(StateAcc, BagDoings, PreEnterMap) end,
        fun(StateAcc) -> mod_role_cycle_mission:role_pre_enter(StateAcc, BagDoings, PreEnterMap) end,
        fun(StateAcc) -> mod_role_act_os_second:role_pre_enter(StateAcc, BagDoings, PreEnterMap) end,
        fun(StateAcc) -> mod_role_act_otf:role_pre_enter(StateAcc, BagDoings, PreEnterMap) end,
        fun(StateAcc) -> mod_role_world_boss:role_pre_enter(IsFirst, StateAcc) end,
        fun(StateAcc) ->
            #c_map_base{sub_type = SubType} = map_misc:get_map_base(mod_role_data:get_role_map_id(StateAcc)),
            if
                SubType =:= ?SUB_TYPE_WORLD_BOSS_4 ->
                    mod_role_day_target:world_boss_time(StateAcc);
                true ->
                    StateAcc
            end
        end
    ],
    FuncList =
    [
        fun() -> mod_role_log_statistics:role_pre_enter(State) end,
        fun() -> mod_role_team:role_enter_map(State) end,
        fun() -> mod_role_bg_treasure_trove:role_pre_enter(PreEnterMap, State) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

role_enter_map(IsFirstEnter, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_fight:role_enter_map(StateAcc) end,
        fun(StateAcc) -> mod_role_world_boss:role_enter_map(IsFirstEnter, StateAcc) end,
        fun(StateAcc) -> mod_role_answer:role_enter_map(StateAcc) end,
        fun(StateAcc) -> mod_role_battle:role_enter_map(StateAcc) end,
        fun(StateAcc) -> mod_role_map_panel:role_enter_map(StateAcc) end,
        fun(StateAcc) -> mod_role_family_bt:role_enter_map(StateAcc) end,
        fun(StateAcc) -> mod_role_confine:role_enter_map(StateAcc) end
    ],
    FuncList =
    [
        fun() -> mod_role_escort:role_enter_map(State) end,
        fun() -> mod_role_copy:role_enter_map(State) end,
        fun() -> mod_role_fgb:check_role_enter(State) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

role_pay(PayGold, ProductID, PayFee, _OldState, State) -> %% PayFee是分
    StateFunc1 =
    %% 大于0元宝才会触发的充值
    case PayGold > 0 of
        true ->
            [
                fun(StateAcc) -> mod_role_act_accrecharge:do_recharge(StateAcc, PayGold) end,
                fun(StateAcc) -> mod_role_act_firstrecharge:do_recharge(StateAcc, PayGold) end,
                fun(StateAcc) -> mod_role_act_dayrecharge:do_recharge(StateAcc, PayGold) end,
                fun(StateAcc) -> mod_role_bg_act:pay(PayGold, StateAcc) end,
                fun(StateAcc) -> mod_role_bg_act_mission:recharge(StateAcc, PayGold) end,
                fun(StateAcc) -> mod_role_cycle_mission:recharge(StateAcc, PayGold) end,
                fun(StateAcc) -> mod_role_act_os_second:do_recharge(StateAcc, PayGold) end,
                fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_RECHARGE, PayGold) end,
                fun(StateAcc) -> mod_role_act_pay:first_recharge(StateAcc, ProductID) end
            ];
        _ ->
            []
    end,
    %% 任意充值都会触发
    StateFunc2 = [
        fun(StateAcc) -> mod_role_day_box:recharge(StateAcc) end,
        fun(StateAcc) -> mod_role_act_trench_ceremony:do_recharge(StateAcc, PayFee) end,
        fun(StateAcc) -> mod_role_act_treasure_chest:do_recharge(StateAcc, PayFee) end
    ],
    FuncList =
    [
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc2 ++ StateFunc1, State).

%% 花费不绑定元宝
role_use_gold(Gold, Action, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_vip:use_gold(Gold, StateAcc) end,
        fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_USE_GOLD, Gold) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_USE_GOLD, Gold) end,
        fun(StateAcc) -> mod_role_bg_act:consume(Gold,Action, StateAcc) end,
        fun(StateAcc) -> mod_role_act_choose:role_use_gold(Gold, StateAcc) end,
        fun(StateAcc) -> mod_role_asset:use_gold(StateAcc, Gold) end
    ],
    FuncList =
    [

    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

%% 花费绑定元宝
role_use_bind_gold(Gold, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_USE_BIND_GOLD, Gold) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_USE_BIND_GOLD, Gold) end,
        fun(StateAcc) -> mod_role_asset:use_bind_gold(StateAcc, Gold) end
    ],
    FuncList =
    [
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).


%% 获得铜钱
role_add_silver(Silver, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_achievement:add_silver(Silver, StateAcc) end
    ],
    FuncList =
    [

    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).


%% 这个接口，升级会调用、过期了重新激活也会调用
role_vip_level_up(OldLevel, NewLevel, State) ->
    StateFunc =
    [
        fun(StateAcc) -> role_server:dump_table(?DB_ROLE_VIP_P, StateAcc) end,
        fun(StateAcc) -> mod_role_vip:send_red_packet(StateAcc, NewLevel) end,
        fun(StateAcc) -> mod_role_god_book:vip_level(NewLevel, StateAcc) end,
        fun(StateAcc) -> mod_role_invest:vip_level_up(StateAcc) end,
        fun(StateAcc) -> mod_role_title:add_vip_title(StateAcc) end,
        fun(StateAcc) -> mod_role_friend:update(StateAcc) end,
        fun(StateAcc) -> mod_role_bless:vip_level_up(StateAcc) end,
        fun(StateAcc) -> mod_role_bg_act_feast:trigger(StateAcc, ?BG_VIP, NewLevel) end,
        fun(StateAcc) -> mod_role_discount_pay:condition_update(StateAcc) end,
        fun(StateAcc) -> mod_role_daily_buy:condition_update(StateAcc) end,
        fun(StateAcc) -> ?IF(OldLevel < 4 andalso NewLevel >= 4, mod_role_vip:v4_reward(StateAcc), StateAcc) end
    ],
    FuncList =
    [
        fun() -> mod_role_copy:update_role_team(State) end,
        fun() -> mod_role_world_boss:cave_times_update(State) end,
        fun() -> mod_role_vip:family_box_update(NewLevel, State) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

%%注意VIP会导致VIP下降
role_vip_expire(State) ->
    StateFunc =
    [
        fun(StateAcc) -> role_server:dump_table(?DB_ROLE_VIP_P, StateAcc) end,
        fun(StateAcc) -> mod_role_equip:role_vip_expire(StateAcc) end,
        fun(StateAcc) -> mod_role_title:del_vip_title(StateAcc) end,
        fun(StateAcc) -> mod_role_discount_pay:condition_update(StateAcc) end,
        fun(StateAcc) -> mod_role_daily_buy:condition_update(StateAcc) end,
        fun(StateAcc) -> mod_role_bless:vip_level_up(StateAcc) end,
        fun(StateAcc) -> mod_role_world_boss:vip_expire(StateAcc) end,
        fun(StateAcc) -> mod_role_copy:vip_expire(StateAcc) end
    ],
    FuncList =
    [
        fun() -> mod_role_copy:update_role_team(State) end,
        fun() -> mod_role_world_boss:cave_times_update(State) end,
        fun() -> mod_role_vip:family_box_update(State#r_role.role_vip#r_role_vip.level, State) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).


role_join_family(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_achievement:family_join(StateAcc) end,
        fun(StateAcc) -> mod_role_act_family:family_join(StateAcc) end,
        fun(StateAcc) -> mod_role_act_family:family_change(StateAcc) end,
        fun(StateAcc) -> mod_role_family_asm:role_join_family(StateAcc) end,
        fun(StateAcc) -> mod_role_mining:role_join_family(StateAcc) end
    ],
    FuncList =
    [
        fun() -> mod_role_family_as:role_join_family(State) end,
        fun() -> mod_role_family_bs:role_join_family(State) end,
        fun() -> mod_role_activity:family_change(State) end,
        fun() -> mod_role_escort:online(State) end,
        fun() ->
            family_escort_server:info({update_family_id, State#r_role.role_id, State#r_role.role_attr#r_role_attr.family_id})
        end

    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

role_leave_family(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_act_family:family_change(StateAcc) end,
        fun(StateAcc) -> mod_role_act_hunt_boss:family_title_change(StateAcc) end,
        fun(StateAcc) -> mod_role_family_asm:role_leave_family(StateAcc) end,
        fun(StateAcc) -> mod_role_mining:role_leave_family(StateAcc) end
    ],
    FuncList =
    [
        fun() -> mod_role_activity:family_change(State) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

role_family_title_change(TitleID, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_act_family:family_title_change(TitleID, StateAcc) end,
        fun(StateAcc) -> mod_role_act_hunt_boss:family_title_change(StateAcc) end,
        fun(StateAcc) -> mod_role_title:family_title_change(TitleID, StateAcc) end,
        fun(StateAcc) -> mod_role_fashion:family_title_change(TitleID, StateAcc) end
    ],
    FuncList =
    [

    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

role_rename(RoleName, State) ->
    #r_role{role_id = RoleID} = State,
    MapPID = mod_role_dict:get_map_pid(),
    StateFunc =
    [
        fun(StateAcc) -> role_server:dump_table(?DB_ROLE_ATTR_P, StateAcc) end,
        fun(StateAcc) -> mod_role_friend:update(StateAcc) end,
        fun(StateAcc) -> mod_role_mining:role_rename(RoleName, StateAcc) end
    ],
    FuncList =
    [
        fun() -> mod_map_role:update_role_name(MapPID, RoleID, RoleName) end,
        fun() -> mod_role_family:role_rename(State) end,
        fun() -> mod_role_online:notify_info(State) end,
        fun() -> mod_role_team:role_rename(State) end,
        fun() -> mod_role_marry:role_rename(State) end,
        fun() -> family_escort_server:role_name_update(RoleID, RoleName) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

role_activity_trigger(MapID, State) ->
    StateFunc =
    [
        fun(StateAcc) ->
            if
                MapID =:= ?MAP_BATTLE -> %% 参与战场
                    StateAcc2 = mod_role_confine:battle(StateAcc),
                    StateAcc3 = mod_role_bg_act_mission:battle(StateAcc2),
                    mod_role_cycle_mission:battle(StateAcc3);
                MapID =:= ?MAP_ANSWER -> %% 参与答题
                    mod_role_day_target:activity_answer(StateAcc);
                MapID =:= ?MAP_FAMILY_TD -> %% 守卫仙盟
                    mod_role_confine:family_td(StateAcc);
                MapID =:= ?MAP_FAMILY_BOSS -> %% 仙盟Boss
                    mod_role_confine:family_bs(StateAcc);
                MapID =:= ?MAP_FAMILY_AS -> %% 仙盟答题
                    mod_role_confine:family_as(StateAcc);
                MapID =:= ?MAP_FAMILY_BT -> %% 仙盟战
                    mod_role_confine:family_bt(StateAcc);
                MapID =:= ?MAP_FIRST_SUMMIT_TOWER -> %% 逍遥
                    StateAcc2 = mod_role_bg_act_mission:summit_tower(StateAcc),
                    mod_role_cycle_mission:summit_tower(StateAcc2);
                MapID =:= ?MAP_DEMON_BOSS -> %% 参与魔域Boss
                    StateAcc2 = mod_role_day_target:demon_boss(StateAcc),
                    mod_role_daily_liveness:trigger_daily_liveness(StateAcc2, ?LIVENESS_MOYU);
                true ->
                    StateAcc
            end
        end
    ],
    FuncList =
    [

    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).




role_first_recharge(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_god_book:first_recharge(StateAcc) end,
        fun(StateAcc) -> mod_role_week_card:role_first_recharge(StateAcc) end,
        fun(StateAcc) -> mod_role_discount_pay:condition_update(StateAcc) end,
        fun(StateAcc) -> mod_role_daily_buy:condition_update(StateAcc) end
    ],
    FuncList =
    [
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).




solo_win(Score, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_confine:solo_step(Score, StateAcc) end,
        fun(StateAcc) -> hook_role:role_solo(StateAcc) end
    ],
    FuncList =
    [
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

role_solo(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_confine:solo_times(StateAcc) end,
        fun(StateAcc) -> mod_role_bg_act_mission:solo(StateAcc) end,
        fun(StateAcc) -> mod_role_cycle_mission:solo(StateAcc) end
    ],
    FuncList =
    [
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

equip_treasure(State, Times) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_bg_act_mission:equip_treasure(StateAcc, Times) end,
        fun(StateAcc) -> mod_role_cycle_mission:equip_treasure(StateAcc, Times) end,
        fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_RUNE_EQUIP, Times) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_RUNE_EQUIP, Times) end

    ],
    role_server:execute_state_fun(StateFunc, State).

rune_treasure(State, Times) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_cycle_mission:rune_treasure(StateAcc, Times) end,
        fun(StateAcc) -> mod_role_bg_act_mission:rune_treasure(StateAcc, Times) end,
        fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_RUNE_TREASURE, Times) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_RUNE_TREASURE, Times) end
    ],
    role_server:execute_state_fun(StateFunc, State).

bless(State, Times) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_cycle_mission:bless_treasure(StateAcc, Times) end,
        fun(StateAcc) -> mod_role_bg_act_mission:bless_treasure(StateAcc, Times) end,
        fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_BLESS, Times) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_BLESS, Times) end,
        fun(StateAcc) -> mod_role_daily_liveness:trigger_daily_liveness(StateAcc, ?LIVENESS_BLESS) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_OFFLINE_BLESS, 1) end,
        fun(StateAcc) -> mod_role_day_target:bless(Times, StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

trevi_fountain(State, Times) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_cycle_mission:trevi_fountain(StateAcc, Times) end,
        fun(StateAcc) -> mod_role_bg_act_mission:trevi_fountain(StateAcc, Times) end,
        fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_TREVI_FOUNTAIN, Times) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_TREVI_FOUNTAIN, Times) end
    ],
    role_server:execute_state_fun(StateFunc, State).

limitedtime_buy(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_LIMITEDTIME_BUY, 1) end
    ],
    role_server:execute_state_fun(StateFunc, State).

do_fairy(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_FAIRY, 1) end
    ],
    role_server:execute_state_fun(StateFunc, State).


marry(Type, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_bg_act_feast:trigger(StateAcc, ?BG_LOVING, 1) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_MARRY, 1) end,
        fun(StateAcc) -> mod_role_skin:online(StateAcc) end,
        fun(StateAcc) -> mod_role_cycle_act_couple:marry(Type, StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

divorce(State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_bg_act_feast:trigger(StateAcc, ?BG_LOVING, 0) end,
        fun(StateAcc) -> mod_role_skin:online(StateAcc) end,
        fun(StateAcc) -> mod_role_fashion:couple_fashion_suit(StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

add_daily_liveness(State, Liveness) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_mission:daily_active_trigger(StateAcc) end,
        fun(StateAcc) ->
            mod_role_bg_turntable:add_liveness(StateAcc, mod_role_daily_liveness:get_daily_liveness(StateAcc)) end,
        fun(StateAcc) ->
            mod_role_asset:do([{add_score, ?ASSET_FROM_LIVENESS, ?ASSET_LIVENESS, Liveness}], StateAcc) end,
        fun(StateAcc) -> mod_role_day_target:daily_active(StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).


skill_open(State, _SkillID) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_confine:open_skill(StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

learn_skill(State, _SkillID) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_confine:learn_skill(StateAcc) end,
        fun(StateAcc) -> mod_role_day_target:skill_up(StateAcc) end
    ],
    role_server:execute_state_fun(StateFunc, State).

family_task_finish(State, TaskID) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_confine:family_mission(StateAcc) end,
        fun(StateAcc) -> mod_role_act_otf:family_mission(StateAcc, TaskID) end,
        fun(StateAcc) -> mod_role_daily_liveness:trigger_daily_liveness(StateAcc, ?LIVENESS_FAMILY_MISSION) end,
        fun(StateAcc) -> mod_role_mission:family_mission(StateAcc) end,
        fun(StateAcc) -> mod_role_achievement:family_mission(StateAcc) end
    ],
    FuncList =
    [
        fun() -> mod_role_log_statistics:log_family_task(State) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).


escort_finish(State, Fairy) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_confine:family_escort(StateAcc) end,
        fun(StateAcc) -> mod_role_daily_liveness:trigger_daily_liveness(StateAcc, ?LIVENESS_ESCORT) end,
        fun(StateAcc) -> mod_role_mission:family_escort(StateAcc) end,
        fun(StateAcc) -> mod_role_act_otf:family_escort(StateAcc, Fairy) end,
        fun(StateAcc) -> mod_role_resource:add_escort_times(StateAcc) end,
        fun(StateAcc) -> mod_role_day_target:family_escort(StateAcc) end
    ],
    FuncList =
    [
        fun() -> mod_role_log_statistics:log_family_escort(State) end
    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).


%% 抢夺
rob_escort(IsWin, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_mission:family_rob_escort(StateAcc) end,
        fun(StateAcc) ->
            case IsWin =:= false  of
                true ->
                    StateAcc2 = mod_role_discount_pay:trigger_condition(?DISCOUNT_CONDITION_FAMILY_ESCORT_FAILED, StateAcc),
                    mod_role_discount_pay:condition_update(StateAcc2);
                _ ->
                    StateAcc
            end end
    ],
    FuncList =
    [

    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

%% 夺回
rob_escort_back(IsWin, State) ->
    StateFunc =
        [
            fun(StateAcc) ->
                case IsWin =:= false  of
                    true ->
                        StateAcc2 = mod_role_discount_pay:trigger_condition(?DISCOUNT_CONDITION_FAMILY_ESCORT_FAILED, StateAcc),
                        mod_role_discount_pay:condition_update(StateAcc2);
                    _ ->
                        StateAcc
                end end
        ],
    FuncList =
        [

        ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).

%% 击杀五行秘境boss
kill_five_elements_boss(TypeID, State) ->
    StateFunc =
    [
        fun(StateAcc) -> mod_role_mission:kill_five_elements_boss(TypeID, StateAcc) end
    ],
    FuncList =
    [

    ],
    [?TRY_CATCH(F()) || F <- FuncList],
    role_server:execute_state_fun(StateFunc, State).


do_solo_trigger(IsWin, Rank, State) ->
    FuncList = [
        fun(StateAcc) -> mod_role_mission:offline_solo_trigger(StateAcc) end,
        fun(StateAcc) -> ?IF(IsWin, mod_role_confine:off_line_solo_win(Rank, StateAcc), StateAcc) end,
        fun(StateAcc) -> mod_role_daily_liveness:trigger_daily_liveness(StateAcc, ?LIVENESS_OFF_SOLO) end,
        fun(StateAcc) -> mod_role_confine:join_off_line_solo(StateAcc) end,
        fun(StateAcc) -> mod_role_day_target:offline_solo(StateAcc) end,
        fun(StateAcc) -> mod_role_cycle_mission:solo(StateAcc) end,
        fun(StateAcc) -> mod_role_bg_act_mission:solo(StateAcc) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_OFFLINE_SOLO, 1) end
    ],
    role_server:execute_state_fun(FuncList, State).


auction_sell(State, SellNum) ->
    FuncList = [
        fun(StateAcc) -> mod_role_day_target:auction_sell(StateAcc) end,
        fun(StateAcc) -> mod_role_daily_liveness:auction_sell(StateAcc, SellNum) end
    ],
    role_server:execute_state_fun(FuncList, State).

money_tree(State) ->
    FuncList = [
        fun(StateAcc) -> mod_role_daily_liveness:trigger_daily_liveness(StateAcc, ?LIVENESS_MONEY_TREE) end
    ],
    role_server:execute_state_fun(FuncList, State).


finish_copy_exp(State) ->
    #r_role{role_copy = #r_role_copy{exp_now_merge_times = Times}} = State,
    finish_copy_exp(State, Times).

finish_copy_exp(State, Times) when Times > 0 ->
    FuncList = [
        fun(StateAcc) -> mod_role_day_target:copy_exp(StateAcc) end,
        fun(StateAcc) -> mod_role_cycle_mission:copy_yard(StateAcc) end,
        fun(StateAcc) -> mod_role_bg_act_mission:copy_yard(StateAcc) end,
        fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_QZY, 1) end,
        fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_QZY, 1) end
    ],
    State2 = role_server:execute_state_fun(FuncList, State),
    finish_copy_exp(State2, Times - 1);
finish_copy_exp(State, _Times) ->
    State.

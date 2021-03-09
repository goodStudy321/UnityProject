%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     成就模块
%%% @end
%%% Created : 27. 六月 2018 12:00
%%%-------------------------------------------------------------------
-module(mod_role_achievement).
-author("laijichang").
-include("achievement.hrl").
-include("role.hrl").
-include("mission.hrl").
-include("suit.hrl").
-include("proto/mod_role_achievement.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    gm_finish_achievement/1
]).

-export([
    family_win/1,
    family_win_champion/1,
    family_end_continuity_victory/1
]).

-export([
    level_up/2,
    wing_level_up/2,
    god_weapon_level_up/2,
    magic_weapon_level_up/2,
    relive_level_up/2,
    use_skin_item/2,
    mount_step/2,
    pet_step/2,
    pet_level/2,
    confine_up/2,
    load_equip/4,
    suit_level/2,
    kill_monster/3,
    kill_monster/4,
    ring_mission/2,
    add_battle_kill/1,
    add_summit_tower_kill/1,
    solo_combo_win/2,
    fairy_times/1,
    answer_times/1,
    copy_three_star/2,
    copy_exp_cheer/2,
    copy_tower/2,
    family_mission/1,
    family_battle_win/1,
    family_battle_champion/1,
    family_end_combo/1,
    family_join/1,
    family_collect/1,
    family_answer/1,
    family_red_packet/1,
    family_donate/1,
    add_kill_red_role/1,
    add_kill_role/1,
    add_role_dead/1,
    add_silver/2,
    sign/1,
    bag_grid_open/2,
    depot_grid_open/2,
    pos_suit/4
]).

init(#r_role{role_id = RoleID, role_achievement = undefined} = State) ->
    RoleAchievement = #r_role_achievement{role_id = RoleID},
    State#r_role{role_achievement = RoleAchievement};
init(State) ->
    State.

online(State) ->
    #r_role{role_id = RoleID, role_achievement = RoleAchievement} = State,
    #r_role_achievement{conditions = Conditions, reward_list = RewardList} = RoleAchievement,
    common_misc:unicast(RoleID, #m_achievement_info_toc{conditions = Conditions, reward_list = RewardList}),
    State.

family_win(RoleID) ->
    MFA = {?MODULE, family_battle_win, []},
    ?IF(role_misc:is_online(RoleID), role_misc:info_role(RoleID, MFA), world_offline_event_server:add_event(RoleID, {?MODULE, family_win, [RoleID]})).

family_win_champion(RoleID) ->
    MFA = {?MODULE, family_battle_champion, []},
    ?IF(role_misc:is_online(RoleID), role_misc:info_role(RoleID, MFA), world_offline_event_server:add_event(RoleID, {?MODULE, family_win_champion, [RoleID]})).

family_end_continuity_victory(RoleID) ->
    MFA = {?MODULE, family_end_combo, []},
    ?IF(role_misc:is_online(RoleID), role_misc:info_role(RoleID, MFA), world_offline_event_server:add_event(RoleID, {?MODULE, family_end_continuity_victory, [RoleID]})).


%% 增加成就点数
add_points(RewardPoints, State) when RewardPoints > 0 ->
    condition_add(?ACHIEVE_CONDITION_POINT, RewardPoints, State);
add_points(_RewardPoints, State) ->
    State.

gm_finish_achievement(State) ->
    lists:foldl(
        fun({Key, Val}, StateAcc) ->
            case Key of
                {max_val, Type, ID} ->
                    condition_replace(Type, ID, Val, StateAcc);
                _ ->
                    StateAcc
            end
        end, State, cfg_achievement:list()).

%% 等级
level_up(Level, State) ->
    condition_replace(?ACHIEVE_CONDITION_LEVEL, Level, State).

%% 翅膀等级
wing_level_up(WingLevel, State) ->
    condition_replace(?ACHIEVE_CONDITION_WING_LEVEL, WingLevel, State).

%% 神兵等级
god_weapon_level_up(GodWeaponLevel, State) ->
    condition_replace(?ACHIEVE_CONDITION_GOD_WEAPON_LEVEL, GodWeaponLevel, State).

%% 法宝等级
magic_weapon_level_up(MagicWeaponLevel, State) ->
    condition_replace(?ACHIEVE_CONDITION_MAGIC_WEAPON_LEVEL, MagicWeaponLevel, State).

%% 转生等级
relive_level_up(ReliveLevel, State) ->
    condition_replace(?ACHIEVE_CONDITION_RELIVE_LEVEL, ReliveLevel, State).

%% 化形
use_skin_item(TypeID, State) ->
    case ?SKIN_BEGIN_ID =< TypeID andalso TypeID =< ?SKIN_END_ID of
        true ->
            condition_add(?ACHIEVE_CONDITION_SKIN, TypeID, 1, State);
        _ ->
            State
    end.

%% 坐骑等阶
mount_step(MountStep, State) ->
    condition_replace(?ACHIEVE_CONDITION_MOUNT_STEP, MountStep, State).

%% 宠物等阶
pet_step(PetStep, State) ->
    condition_replace(?ACHIEVE_CONDITION_PET_STEP, PetStep, State).

pet_level(PetLevel, State) ->
    condition_replace(?ACHIEVE_CONDITION_PET_LEVEL, PetLevel, State).

%% 境界
confine_up(Confine, State) ->
    condition_replace(?ACHIEVE_CONDITION_CONFINE, Confine, 1, State).

%% 穿戴装备
load_equip(Quality, Star, LoadIndex, State) ->
    State2 =
    case Quality >= ?QUALITY_ORANGE andalso Star >= 1 of
        true ->
            condition_add(?ACHIEVE_CONDITION_LOAD_QUALITY_EQUIP, Star, 1, State);
        _ ->
            State
    end,
    condition_add(?ACHIEVE_CONDITION_LOAD_INDEX_EQUIP, LoadIndex, 1, State2).

%% 套装等级
suit_level(SuitLevelList, State) ->
    lists:foldl(
        fun({SuitLevel, SuitNum}, StateAcc) ->
            condition_replace(?ACHIEVE_CONDITION_LOAD_STEP_EQUIP, SuitLevel, SuitNum, StateAcc)
        end, State, SuitLevelList).

%% 杀怪数量
kill_monster(_TypeID, MonsterLevel, State) ->
    kill_monster(_TypeID, MonsterLevel, 1, State).
kill_monster(_TypeID, MonsterLevel, AddNum, State)->
    ?IF(mod_role_data:get_role_level(State) - MonsterLevel =< ?KILL_MONSTER_LEVEL, condition_add(?ACHIEVE_CONDITION_KILL_MONSTER, AddNum, State), State).

%% 赏金任务
ring_mission(MissionID, State) ->
    [#c_mission_excel{listener_type = ListenerType}] = lib_config:find(cfg_mission_excel, MissionID),
    if
        ListenerType =:= ?MISSION_SPEAK ->
            condition_add(?ACHIEVE_CONDITION_RING_MISSION_SPEAK, 1, State);
        ListenerType =:= ?MISSION_FINISH_COPY ->
            condition_add(?ACHIEVE_CONDITION_RING_MISSION_COPY, 1, State);
        true ->
            State
    end.

%% 三界战场击杀玩家
add_battle_kill(State) ->
    condition_add(?ACHIEVE_CONDITION_BATTLE_KILL, 1, State).

%% 青云之巅击杀玩家
add_summit_tower_kill(State) ->
    condition_add(?ACHIEVE_CONDITION_SUMMIT_KILL, 1, State).

%% 巅峰竞技连胜
solo_combo_win(ComboWin, State) ->
    condition_replace(?ACHIEVE_CONDITION_SOLO_COMBO, ComboWin, State).

%% 护送仙女次数
fairy_times(State) ->
    condition_add(?ACHIEVE_CONDITION_FAIRY_TIMES, 1, State).

%% 修仙论道答对题目
answer_times(State) ->
    condition_add(?ACHIEVE_CONDITION_ANSWER_TIMES, 1, State).

%% 三星通关某个副本
copy_three_star(MapID, State) ->
    condition_add(?ACHIEVE_CONDITION_COPY_THREE_STAR, MapID, 1, State).

%% 副本鼓舞
copy_exp_cheer(AddTimes, State) ->
    condition_add(?ACHIEVE_CONDITION_COPY_CHEER, AddTimes, State).

%% 通关通天塔层数
copy_tower(Floor, State) ->
    condition_replace(?ACHIEVE_CONDITION_COPY_TOWER, Floor, State).

%% 仙盟任务
family_mission(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_MISSION, 1, State).

%% 仙盟战获胜
family_battle_win(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_BATTLE_WIN, 1, State).

%% 仙盟战获得冠军
family_battle_champion(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_BATTLE_CHAMPION, 1, State).

%% 仙盟战终结连胜
family_end_combo(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_BATTLE_END_COMBO, 1, State).

%% 加入仙盟
family_join(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_JOIN, 1, State).

%% 仙盟采集
family_collect(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_COLLECT, 1, State).

%% 仙盟答题答对数目
family_answer(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_ANSWER, 1, State).

%% 仙盟红包
family_red_packet(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_RED_PACKET, 1, State).

%% 捐献装备
family_donate(State) ->
    condition_add(?ACHIEVE_CONDITION_FAMILY_DONATE, 1, State).

%% 击杀红名玩家次数
add_kill_red_role(State) ->
    condition_add(?ACHIEVE_CONDITION_KILL_RED_ROLE, 1, State).

%% 击杀玩家次数
add_kill_role(State) ->
    condition_add(?ACHIEVE_CONDITION_KILL_ROLE, 1, State).

%% 玩家死亡次数
add_role_dead(State) ->
    condition_add(?ACHIEVE_CONDITION_ROLE_DEATH, 1, State).

%% 银两增加
add_silver(AddSilver, State) ->
    condition_add(?ACHIEVE_CONDITION_ASSET_SILVER, AddSilver, State).

%% 签到
sign(State) ->
    condition_add(?ACHIEVE_CONDITION_SIGN, 1, State).

%% 背包格子开启
bag_grid_open(Grids, State) ->
    condition_replace(?ACHIEVE_CONDITION_BAG_GRID, Grids, State).

%% 仓库格子开启
depot_grid_open(Grids, State) ->
    condition_replace(?ACHIEVE_CONDITION_DEPOT_GRID, Grids, State).

%% 雷劫装备
pos_suit(SubType, Type, NumStepList, State) ->
    TriggerType =
        if
            Type =:= ?BIG_TYPE_THUNDER andalso SubType =:= ?SUIT_SUB_TYPE_LEFT -> %% 雷劫难
                ?ACHIEVE_CONDITION_SUIT_THUNDER_LEFT;
            Type =:= ?BIG_TYPE_THUNDER andalso SubType =:= ?SUIT_SUB_TYPE_RIGHT -> %% 雷霆
                ?ACHIEVE_CONDITION_SUIT_THUNDER_RIGHT;
            Type =:= ?BIG_TYPE_SUN andalso SubType =:= ?SUIT_SUB_TYPE_LEFT -> %% 阳炎套装
                ?ACHIEVE_CONDITION_SUIT_SUN_LEFT;
            Type =:= ?BIG_TYPE_SUN andalso SubType =:= ?SUIT_SUB_TYPE_RIGHT -> %% 阳元套装
                ?ACHIEVE_CONDITION_SUIT_SUN_RIGHT;
            true ->
                0
        end,
    lists:foldl(
        fun({Num, Step}, StateAcc) ->
            condition_replace(TriggerType, Step, Num, StateAcc)
        end, State, NumStepList).

condition_add(Type, Val, State) ->
    condition_add(Type, 0, Val, State).
condition_add(Type, ID, AddVal, State) ->
    case lib_config:find(cfg_achievement, {max_val, Type, ID}) of
        [MaxVal] ->
            #r_role{role_id = RoleID, role_achievement = RoleAchievement} = State,
            #r_role_achievement{conditions = Conditions} = RoleAchievement,
            OldVal = get_condition(Type, ID, Conditions),
            case OldVal < MaxVal of
                true ->
                    NewVal = OldVal + AddVal,
                    Conditions2 = set_condition(Type, ID, OldVal + AddVal, Conditions),
                    common_misc:unicast(RoleID, #m_achievement_condition_toc{type = Type, id = ID, val = NewVal}),
                    RoleAchievement2 = RoleAchievement#r_role_achievement{conditions = Conditions2},
                    State#r_role{role_achievement = RoleAchievement2};
                _ -> %% 达到最大值
                    State
            end;
        _ ->
            State
    end.

condition_replace(Type, Val, State) ->
    condition_replace(Type, 0, Val, State).
condition_replace(Type, ID, Val, State) ->
    case lib_config:find(cfg_achievement, {max_val, Type, ID}) of
        [MaxVal] ->
            #r_role{role_id = RoleID, role_achievement = RoleAchievement} = State,
            #r_role_achievement{conditions = Conditions} = RoleAchievement,
            OldVal = get_condition(Type, ID, Conditions),
            case OldVal < MaxVal andalso Val > OldVal of
                true ->
                    Conditions2 = set_condition(Type, ID, Val, Conditions),
                    common_misc:unicast(RoleID, #m_achievement_condition_toc{type = Type, id = ID, val = Val}),
                    RoleAchievement2 = RoleAchievement#r_role_achievement{conditions = Conditions2},
                    State#r_role{role_achievement = RoleAchievement2};
                _ -> %% 达到最大值 或者 比原来的值低
                    State
            end;
        _ ->
            State
    end.

get_condition(Type, ID, Conditions) ->
    case lists:keyfind(Type, #p_condition.type, Conditions) of
        #p_condition{id_list = IDList} ->
            case lists:keyfind(ID, #p_dkv.id, IDList) of
                #p_dkv{val = Val} ->
                    Val;
                _ ->
                    0
            end;
        _ ->
            0
    end.

set_condition(Type, ID, Val, Conditions) ->
    KV = #p_dkv{id = ID, val = Val},
    case lists:keyfind(Type, #p_condition.type, Conditions) of
        #p_condition{id_list = IDList} = Condition ->
            IDList2 = lists:keystore(ID, #p_dkv.id, IDList, KV),
            Condition2 = Condition#p_condition{id_list = IDList2},
            lists:keyreplace(Type, #p_condition.type, Conditions, Condition2);
        _ ->
            Condition2 = #p_condition{type = Type, id_list = [KV]},
            [Condition2|Conditions]
    end.

handle({#m_achievement_reward_tos{achievement_id = AchievementID}, RoleID, _PID}, State) ->
    do_reward_achievement(RoleID, AchievementID, State).

%% 领取成就奖励
do_reward_achievement(RoleID, AchievementID, State) ->
    case catch check_reward_achievement(AchievementID, State) of
        {ok, BagDoing, RewardPoints, State2} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = add_points(RewardPoints, State3),
            common_misc:unicast(RoleID, #m_achievement_reward_toc{achievement_id = AchievementID}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_achievement_reward_toc{err_code = ErrCode}),
            State
    end.

check_reward_achievement(AchievementID, State) ->
    case lib_config:find(cfg_achievement, AchievementID) of
        [Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_ACHIEVEMENT_REWARD_001)
    end,
    #r_role{role_achievement = RoleAchievement} = State,
    #r_role_achievement{conditions = Conditions, reward_list = RewardList} = RoleAchievement,
    ?IF(lists:member(AchievementID, RewardList), ?THROW_ERR(?ERROR_ACHIEVEMENT_REWARD_003), ok),
    #c_achievement{
        condition_type = ConditionType,
        condition_id = ConditionID,
        condition_args = ConditionArgs,
        reward_goods = RewardGoods,
        reward_points = RewardPoints
    } = Config,
    Val = get_condition(ConditionType, ConditionID, Conditions),
    ?IF(Val >= ConditionArgs, ok, ?THROW_ERR(?ERROR_ACHIEVEMENT_REWARD_002)),
    GoodsList = [ #p_goods{type_id = TypeID, num = Num, bind = true}|| {TypeID, Num} <- common_misc:get_item_reward(RewardGoods)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACHIEVEMENT, GoodsList}],
    RoleAchievement2 = RoleAchievement#r_role_achievement{reward_list = [AchievementID|RewardList]},
    State2 = State#r_role{role_achievement = RoleAchievement2},
    {ok, BagDoings, RewardPoints, State2}.




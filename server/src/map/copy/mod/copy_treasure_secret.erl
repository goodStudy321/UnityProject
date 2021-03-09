%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 七月 2019 14:39
%%%-------------------------------------------------------------------
-module(copy_treasure_secret).
-author("WZP").
-include("copy.hrl").
-include("map.hrl").
-include("monster.hrl").

-define(GLOBAL_TREASURE_SECRET, 160).

%% API
-export([
    born_monster/3,
    boss_killed/0,
    role_init/1,
    role_dead/1
]).


role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{all_wave = 1},
    copy_data:set_copy_info(CopyInfo2).

boss_killed() ->
    map_server:delay_shutdown(),
    copy_common:do_copy_end(?COPY_SUCCESS),
    mod_role_bg_treasure_trove:copy_win(map_common_dict:get_map_extra_id()),
    ok.

role_dead({_RoleID, _SrcID, _SrcType}) ->
    copy_common:do_copy_end(?COPY_FAILED).


born_monster(BossID, RoleFight, Coefficient) ->
    case erlang:is_integer(get_map_boss()) of
        false ->
            set_map_boss(BossID),
            #c_monster{
                level = Level,
                move_speed = MoveSpeed,
                max_hp = MaxHP,
                attack = Attack,
                min_reduce_rate = Min_reduce_rate,        %% 扣血下限
                max_reduce_rate = Max_reduce_rate        %% 扣血上限
            } = monster_misc:get_monster_config(BossID),
            #actor_fight_attr{
                max_hp = RoleHP,             %% 血量
                attack = RoleAttack,             %% 攻击
                defence = RoleDefence,            %% 防御
                arp = RoleArp,                %% 破甲
                hit_rate = RoleHitRate,           %% 命中
                miss = RoleMiss,               %% 闪避
                double = RoleDouble,             %% 暴击
                double_anti = RoleDoubleAnti,        %% 韧性

                %% 万分比
                hurt_rate = RoleHurtRate,          %% 加伤
                hurt_derate = RoleHurtDerate,        %% 免伤
                double_rate = RoleDoubleRate,        %% 暴击几率
                double_multi = RoleDoubleMulti,         %% 暴伤
                miss_rate = RoleMissRate,          %% 闪避几率
                double_anti_rate = RoleDoubleAntiRate,  %% 暴击抵抗
                armor = RoleArmor,              %% 护甲
                skill_hurt = Skill_hurt,         %% 技能伤害增加
                skill_hurt_anti = Skill_hurt_anti,    %% 技能伤害减少
                skill_dps = Skill_dps,          %% 技能DSP系数
                skill_ehp = Skill_ehp          %% 技能EHP系数
            } = RoleFight,
            HP = erlang:max(MaxHP, RoleHP) * (2 - erlang:min(1.5, erlang:max(0, Coefficient))),
            Attack2 = erlang:max(Attack, RoleAttack) * (2 - erlang:min(1.5, erlang:max(0, Coefficient))),
            BaseAttr2 = #actor_cal_attr{
                max_hp = {HP, 0},             %% 血量
                attack = {Attack2, 0},             %% 攻击
                defence = {RoleDefence, 0},            %% 防御
                arp = {RoleArp, 0},                %% 破甲
                hit_rate = {RoleHitRate, 0},           %% 命中
                miss = {RoleMiss, 0},               %% 闪避
                double = {RoleDouble, 0},             %% 暴击
                double_anti = {RoleDoubleAnti, 0},        %% 韧性
                %% 万分比
                hurt_rate = RoleHurtRate,                %% 加伤
                hurt_derate = RoleHurtDerate,            %% 免伤
                double_rate = {RoleDoubleRate, 0},        %% 暴击几率
                double_multi = {RoleDoubleMulti, 0},       %% 暴伤
                miss_rate = {RoleMissRate, 0},          %% 闪避几率
                double_anti_rate = {RoleDoubleAntiRate, 0},  %% 暴击抵抗
                armor = {RoleArmor, 0},              %% 护甲
                skill_hurt = {Skill_hurt, 0},         %% 技能伤害增加
                skill_hurt_anti = {Skill_hurt_anti, 0},    %% 技能伤害减少
                skill_dps = {Skill_dps, 0},          %% 技能DSP系数
                skill_ehp = {Skill_ehp, 0},          %% 技能EHP系数
                move_speed = {MoveSpeed, 0},         %% 移动速度
                min_reduce_rate = {Min_reduce_rate, 0},    %% 扣血下限
                max_reduce_rate = {Max_reduce_rate, 0}    %% 扣血上限
            },
            [GlobalConfig] = lib_config:find(cfg_global, ?GLOBAL_TREASURE_SECRET),
            [X, Z] = GlobalConfig#c_global.list,
            RecordPos = map_misc:get_pos_by_offset_pos(X, Z, GlobalConfig#c_global.int),
            MonsterData = #r_monster{type_id = BossID, base_attr = BaseAttr2, born_pos = RecordPos, level = Level},
            mod_map_monster:born_monsters([MonsterData], true);
        _ ->
            ok
    end.




set_map_boss(BossID) ->
    erlang:put({?MODULE, boss_id}, BossID).

get_map_boss() ->
    erlang:get({?MODULE, boss_id}).





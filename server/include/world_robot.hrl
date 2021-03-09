%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 五月 2018 20:40
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(WORLD_ROBOT_HRL).
-define(WORLD_ROBOT_HRL, world_robot_hrl).
-include("global.hrl").

-define(ROBOT_LOOP_INTERVAL, 30).   %% 30秒loop一次
-define(ROBOT_REBORN_INTERVAL, 30). %% 死亡30秒后再出生

-define(MAX_ROBOT_NUM, 200).    %% 暂定最多生成200个机器人

-define(FIGHT_STATUS_STAND_BY, 1).  %% 准备状态
-define(FIGHT_STATUS_FIGHTING, 2).  %% 战斗状态
-define(FIGHT_STATUS_END, 3).       %% 结束状态

-define(ROBOT_STATE_BORN, 1).   %% 出生状态
-define(ROBOT_STATE_GUARD, 2).  %% 守卫状态
-define(ROBOT_STATE_FIGHT, 3).  %% 战斗状态

-define(ROBOT_RETURN(Counter, RobotData), erlang:throw({ok, Counter, RobotData})).

-record(r_robot_level, {
    key,        %% {MinLevel, MaxLevel}
    pos_list    %% 坐标列表[#r_map_pos{}|...]
}).

-record(r_robot_pos, {
    map_id,
    monster_type_id,
    min_point,
    max_point
}).

-record(r_robot, {
    robot_id,           %% 机器人id
    robot_name,         %% 机器人Name
    state,              %% 状态
    buff_status=0,      %% buff状态
    next_counter=0,     %% 下一次可执行的counter
    sex,                %% 性别
    category,           %% 职业
    level,              %% 等级
    team_id = 0,        %% 队伍ID
    family_id = 0,      %% 仙盟ID
    family_name="",     %% 仙盟名
    family_title_id=0,  %% 仙盟称号
    power=0,            %% 战力
    skin_list=[],       %% 皮肤列表
    ornament_list = [], %% 装饰列表
    attacked_counter=0, %% 上次被攻击的counter
    last_skill=0,       %% 上次释放的技能
    last_skill_time=0,  %% 上次释放技能的时间 ms
    last_attack_time=0, %% 上次攻击的时间 ms
    last_dest_pos,      %% 上次要抵达的目标点
    min_point,          %% 出生点范围
    max_point,          %% 出生点范围
    fight_args = [],    %% [Fight|...]
    base_attr,          %% #actor_fight_attr{}基础属性
    attr,               %% #actor_fight_attr{}
    skill_list=[],      %% [{SkillFun, [#p_skills{}|...] | ...]
    walk_path=[],       %% 走路路径
    forever_enemies=[], %% 永久仇恨
    enemies=[],         %% 当前仇恨列表
    buffs=[],           %% buff
    debuffs=[]          %% debuff
}).

-record(r_robot_path, {pos, use_time, delay_counter}).

-record(r_robot_skill, {skill_id=0, skill_type=0, time=0}).

-record(c_offline_reward,{
    level,      %% 等级
    exp         %% 每秒经验
}).
-endif.

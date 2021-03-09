%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2018 12:14
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(ACHIEVEMENT_HRL).
-define(ACHIEVEMENT_HRL, achievement_hrl).

-define(ACHIEVE_CONDITION_POINT, 110101).                       %% 成就点
-define(ACHIEVE_CONDITION_LEVEL, 220101).                       %% 等级
-define(ACHIEVE_CONDITION_WING_LEVEL, 220201).                  %% 翅膀等级
-define(ACHIEVE_CONDITION_GOD_WEAPON_LEVEL, 220301).            %% 神兵等级
-define(ACHIEVE_CONDITION_MAGIC_WEAPON_LEVEL, 220401).          %% 法宝
-define(ACHIEVE_CONDITION_RELIVE_LEVEL, 220501).                %% 转生等级
-define(ACHIEVE_CONDITION_SKIN, 220601).                        %% 化形
-define(ACHIEVE_CONDITION_CONFINE, 220701).                     %% 境界
-define(ACHIEVE_CONDITION_MOUNT_STEP, 330101).                  %% 坐骑等阶
-define(ACHIEVE_CONDITION_PET_STEP, 330201).                    %% 宠物等阶
-define(ACHIEVE_CONDITION_PET_LEVEL, 330202).                   %% 宠物等级
-define(ACHIEVE_CONDITION_LOAD_QUALITY_EQUIP, 440101).          %% 穿戴品质>=5 星级取条件id的装备
-define(ACHIEVE_CONDITION_LOAD_INDEX_EQUIP, 440102).            %% 穿戴装备部位
-define(ACHIEVE_CONDITION_LOAD_STEP_EQUIP, 440103).             %% 穿戴装备套装
-define(ACHIEVE_CONDITION_SUIT_THUNDER_LEFT, 440104).           %% 雷劫套装
-define(ACHIEVE_CONDITION_SUIT_THUNDER_RIGHT, 440105).          %% 雷霆套装
-define(ACHIEVE_CONDITION_SUIT_SUN_LEFT, 440106).               %% 阳炎套装
-define(ACHIEVE_CONDITION_SUIT_SUN_RIGHT, 440107).              %% 阳元套装
-define(ACHIEVE_CONDITION_KILL_MONSTER, 550101).                %% 击杀怪物
-define(ACHIEVE_CONDITION_RING_MISSION_SPEAK, 550201).          %% 赏金任务对话
-define(ACHIEVE_CONDITION_RING_MISSION_COPY, 550202).           %% 赏金任务副本
-define(ACHIEVE_CONDITION_BATTLE_KILL, 550301).                 %% 三界战场击杀玩家
-define(ACHIEVE_CONDITION_SUMMIT_KILL, 550302).                 %% 青云之巅击杀玩家
-define(ACHIEVE_CONDITION_SOLO_COMBO, 550303).                  %% 巅峰竞技连胜
-define(ACHIEVE_CONDITION_FAIRY_TIMES, 550304).                 %% 护送美女次数
-define(ACHIEVE_CONDITION_ANSWER_TIMES, 550305).                %% 修仙论道答对题目
-define(ACHIEVE_CONDITION_COPY_THREE_STAR, 550401).             %% 三星通关某个副本
-define(ACHIEVE_CONDITION_COPY_CHEER, 550402).                  %% 经验副本鼓舞次数
-define(ACHIEVE_CONDITION_COPY_TOWER, 550403).                  %% 通关通天塔层数
-define(ACHIEVE_CONDITION_FAMILY_MISSION, 550501).              %% 仙盟任务
-define(ACHIEVE_CONDITION_FAMILY_BATTLE_WIN, 660101).           %% 仙盟战胜利次数
-define(ACHIEVE_CONDITION_FAMILY_BATTLE_CHAMPION, 660102).      %% 仙盟战冠军次数
-define(ACHIEVE_CONDITION_FAMILY_BATTLE_END_COMBO, 660103).     %% 仙盟战终结对方连胜
-define(ACHIEVE_CONDITION_FAMILY_JOIN, 660104).                 %% 加入仙盟
-define(ACHIEVE_CONDITION_FAMILY_COLLECT, 660105).              %% 仙盟答题采集次数
-define(ACHIEVE_CONDITION_FAMILY_ANSWER, 660106).               %% 仙盟答题答对题目个数
-define(ACHIEVE_CONDITION_FAMILY_RED_PACKET, 660107).           %% 仙盟发送红包数量
-define(ACHIEVE_CONDITION_FAMILY_DONATE, 660108).               %% 仙盟捐献装备
-define(ACHIEVE_CONDITION_KILL_RED_ROLE, 660201).               %% 击杀红名玩家
-define(ACHIEVE_CONDITION_KILL_ROLE, 660202).                   %% 击杀玩家次数
-define(ACHIEVE_CONDITION_ROLE_DEATH, 660203).                  %% 死亡次数
-define(ACHIEVE_CONDITION_ASSET_SILVER, 770101).                %% 财富-银两
-define(ACHIEVE_CONDITION_SIGN, 770201).                        %% 签到天数
-define(ACHIEVE_CONDITION_BAG_GRID, 770301).                    %% 背包格子
-define(ACHIEVE_CONDITION_DEPOT_GRID, 770302).                  %% 仓库格子

-define(SKIN_BEGIN_ID, 3010100).
-define(SKIN_END_ID, 3060000).

-define(KILL_MONSTER_LEVEL, 70).    %% 不低于自己70级的怪物

-record(c_achievement, {
    id,                 %% 成就ID
    name,               %% 成就名称
    type,               %% 成就母类型
    condition_type,     %% 成就条件类型
    condition_id,       %% 成就条件ID
    condition_args,     %% 成就条件参数
    reward_goods,       %% 成就奖励道具
    reward_points       %% 成就奖励成就点
}).
-endif.
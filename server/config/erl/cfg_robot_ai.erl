-module(cfg_robot_ai).
-include("config.hrl").
-export([find/1]).
?CFG_H

%% 需要测试的时候才加，不需要的话默认是连本节点的服务器
%%?C(connect, {"134.175.205.196", 40905})

%% ID：ABCDEFG
%% A：1为选择节点 2为顺序节点 3为条件节点 4为行为节点
%% B：无强制要求，最好统一 1.robot_move  2.robot_fight
%% CDEF无特殊含义，最好按照关系顺序延续，看配置时方便识别节点顺序

%% 机器人特定AI行为 优先级：{robot_map, MapID} > {robot_type, 机器人类型}  > normal_ai
%% 根节点都是选择节点
?C({robot_map, 30001}, [1010000]) %% 在战场地图30001的AI
?C({robot_map, 30002}, [1010000]) %% 在战场地图30001的AI

?C({robot_type, 1}, [])             %% 1类型的AI行为 不会动
?C({robot_type, 2}, [1010001])      %% 2类型的AI行为 监听活动状态 进入战场
?C({robot_type, 3}, [1010002])      %% 3类型的AI行为 监听活动状态 进入天梯
?C({robot_type, 4}, [1010003])      %% 战斗 > 移动
?C({robot_type, 5}, [1010004])      %% 5类型的AI行为 监听活动状态 进入巅峰爬塔
?C({robot_type, 6}, [1010003])      %% 战斗 > 移动
?C({robot_type, 7}, [1010005])      %% 7类型的AI行为 监听活动状态 进入魔域Boss

?C({robot_type, 50}, [1020000])     %% 任务 > 战斗 > 移动

%% 通用AI
?C(normal_ai, [1010000])


%% 选择节点
?C({child_nodes, 1010000}, [2010001, 2010002])              %% 战斗 > 移动
?C({child_nodes, 1010001}, [2010003, 2010001, 2010002])     %% 跳转至战场地图 > 战斗 > 移动
?C({child_nodes, 1010002}, [2010004, 2010001, 2010002])     %% 匹配 > 战斗 > 移动
?C({child_nodes, 1010003}, [2010005, 2010002])              %% 一段时间战斗 > 移动
?C({child_nodes, 1010004}, [2010006, 2010001, 2010002])     %% 跳转至青云之巅 > 战斗 > 移动
?C({child_nodes, 1010005}, [2010007, 2010001, 2010002])     %% 跳转至魔域boss > 战斗 > 移动

?C({child_nodes, 1020000}, [2020000, 2010001, 2010002])     %% 一段时间战斗 > 移动

%% 顺序节点对应的子节点（可能会有多层嵌套）
?C({child_nodes, 2010001}, [3120001, 4120001])              %% 战斗
?C({child_nodes, 2010002}, [3110001, 4110001])              %% 移动
?C({child_nodes, 2010003}, [3110002, 3110003, 4110002])     %% 尝试跳转战场地图
?C({child_nodes, 2010004}, [3110004, 3110005, 4110003])     %% 尝试匹配
?C({child_nodes, 2010005}, [3120002, 4120001])              %% 30秒战斗、30秒做其他
?C({child_nodes, 2010006}, [3110006, 3110007, 4110004])     %% 尝试跳转青云之巅
?C({child_nodes, 2010007}, [3110008, 3110009, 4110005])     %% 尝试跳转青云之巅

?C({child_nodes, 2020000}, [4130001])                       %% 执行任务


%% 条件节点 要求一定要返回true或false
?C({actions, 3110001}, {robot_ai_move, move_condition, [1]})            %% 移动 ps参数暂时没有任何意义 只支持单个参数
?C({actions, 3110002}, {robot_ai_normal, activity_condition, [10001]})  %% 战场活动是否开启
?C({actions, 3110003}, {robot_ai_normal, map_condition, [30001]})       %% 不在某张地图内
?C({actions, 3110004}, {robot_ai_normal, activity_condition, [10002]})  %% 决战天梯是否开启
?C({actions, 3110005}, {robot_ai_normal, map_condition, [30002]})       %% 不在决战天梯地图
?C({actions, 3110006}, {robot_ai_normal, activity_condition, [10008]})  %% 青云之巅活动是否开启
?C({actions, 3110007}, {robot_ai_normal, map_condition, [30009]})       %% 不在决战天梯地图
?C({actions, 3110008}, {robot_ai_normal, activity_condition, [10011]})  %% 魔域boss活动是否开启
?C({actions, 3110009}, {robot_ai_normal, map_condition, [30021]})       %% 不在魔域boss地图



?C({actions, 3120001}, {robot_ai_fight, fight_condition, [0]})          %% 战斗检测 0表示一直战斗
?C({actions, 3120002}, {robot_ai_fight, fight_condition, [30]})         %% 战斗检测 >0 表示每次每隔xx秒后才战斗

%% 行为节点 要求一定要返回true或false
?C({actions, 4110001}, {robot_ai_move, move, [1]})              %% 移动 ps参数暂时没有任何意义 只支持单个参数
?C({actions, 4110002}, {robot_ai_normal, enter_map, [30001]})   %% 进入战场
?C({actions, 4110003}, {robot_ai_normal, solo_match, []})       %% 尝试匹配
?C({actions, 4110004}, {robot_ai_normal, enter_map, [30009]})   %% 青云之巅
?C({actions, 4110005}, {robot_ai_normal, enter_map, [30021]})   %% 魔域boss

%%?C({actions, 4110003}, {robot_ai_move, dest_move, [ [{134, 49}] ]}) %% 新手村移动到某几个点
%%?C({actions, 4110005}, {robot_ai_move, dest_move, [ [{285, 20}] ]}) %% 落日谷到某几个点
%%?C({actions, 4110004}, {robot_ai_move, dest_move, [ [{172, 126}] ]}) %% 主城移动到某几个点

%%战斗相关 1为被攻击时反击, 无敌人时自动寻找可攻击的目标 2为被攻击时反击
?C({actions, 4120001}, {robot_ai_fight, fight, [ 1 ]}) %% 战斗

?C({actions, 4130001}, {robot_ai_mission, mission_do, []})
%% ============== 策划配置内容end =============
?CFG_E.
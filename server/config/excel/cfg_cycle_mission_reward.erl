-module(cfg_cycle_mission_reward).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_cycle_mission_reward,1,200,"6100001,20,0;30011,1,0;32016,1,0",20130101})
?C(2, {c_cycle_mission_reward,2,400,"6100002,10,0;30001,1,0;32016,1,0",20130101})
?C(3, {c_cycle_mission_reward,3,600,"6100005,5,0;30012,1,0;32016,1,0",20130101})
?C(4, {c_cycle_mission_reward,4,800,"64012,1,0;30002,1,0;32016,1,0",20130101})
?C(5, {c_cycle_mission_reward,5,1000,"6100006,1,0;30013,1,0;32016,1,0",20130101})
?C(6, {c_cycle_mission_reward,6,1200,"35350,1,0;30003,1,0;32016,1,0",20130101})
?C(7, {c_cycle_mission_reward,7,1400,"3061200,1,1;30014,1,0;32016,1,0",20130101})
?C(8, {c_cycle_mission_reward,8,1700,"64013,1,1;30004,1,0;32016,1,0",20130101})
?C(9, {c_cycle_mission_reward,9,2000,"3019600,1,1;30005,1,0;32016,1,0",20130101})
?CFG_E.
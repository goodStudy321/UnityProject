-module(cfg_cycle_mission).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_cycle_mission,1,100103,1,10,9,20130101})
?C(2, {c_cycle_mission,2,100104,1,5,12,20130101})
?C(3, {c_cycle_mission,3,100105,1,3,150,20130101})
?C(4, {c_cycle_mission,4,100106,1,3,150,20130101})
?C(5, {c_cycle_mission,5,100107,1,10,21,20130101})
?C(6, {c_cycle_mission,6,100108,1,2,60,20130101})
?C(7, {c_cycle_mission,7,100109,1,10,12,20130101})
?C(8, {c_cycle_mission,8,100110,1,5,12,20130101})
?C(9, {c_cycle_mission,9,100111,1,5,12,20130101})
?C(10, {c_cycle_mission,10,100112,1,5,18,20130101})
?C(11, {c_cycle_mission,11,100113,1,20,2,20130101})
?C(12, {c_cycle_mission,12,100114,1,20,2,20130101})
?C(13, {c_cycle_mission,13,100115,1,20,2,20130101})
?C(14, {c_cycle_mission,14,100118,1,5,12,20130101})
?C(15, {c_cycle_mission,15,100120,1,10,18,20130101})
?C(16, {c_cycle_mission,16,100101,60,30,6,20130101})
?C(17, {c_cycle_mission,17,100102,1,2,48,20130101})
?CFG_E.
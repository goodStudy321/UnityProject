-module(cfg_trevi_fountain_reward).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_trevi_fountain_reward,1,15,"30322,1,1;1,300000,0;30324,1,1"})
?C(2, {c_trevi_fountain_reward,2,40,"30322,2,1;1,500000,0;30325,1,1"})
?C(3, {c_trevi_fountain_reward,3,100,"30323,1,1;1,800000,0;30303,1,1;3020100,1,1"})
?C(4, {c_trevi_fountain_reward,4,120,"30323,1,1;1,1000000,0;30302,1,1"})
?C(5, {c_trevi_fountain_reward,5,160,"30323,1,1;1,1200000,0;30303,1,1"})
?C(6, {c_trevi_fountain_reward,6,200,"30323,1,1;1,1500000,0;30324,1,1;3090000,1,1"})
?CFG_E.
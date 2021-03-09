-module(cfg_cycle_act_couple_charm).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_cycle_act_couple_charm,1,"79150,1,1;4000300,1,1;4005600,1,1;30334,5,1;30335,5,1",[1,1],20120101})
?C(2, {c_cycle_act_couple_charm,2,"4000300,1,0;4005600,1,0;30335,4,0;30334,4,0",[2,2],20120101})
?C(3, {c_cycle_act_couple_charm,3,"4000300,1,0;30335,3,0;30334,3,0;31038,10,0",[3,3],20120101})
?C(4, {c_cycle_act_couple_charm,4,"31063,50,0;30335,2,0;30334,2,0;31038,5,0",[4,10],20120101})
?C(5, {c_cycle_act_couple_charm,5,"30335,1,0;30334,1,0;31038,3,0;32017,2,0",[11,30],20120101})
?C(6, {c_cycle_act_couple_charm,6,"30333,1,0;30332,2,0;31038,1,0;32017,1,0",[31,999],20120101})
?CFG_E.
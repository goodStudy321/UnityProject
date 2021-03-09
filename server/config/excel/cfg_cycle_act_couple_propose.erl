-module(cfg_cycle_act_couple_propose).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_cycle_act_couple_propose,1,"64009,1,1;31038,2,0;32016,1,0;32017,1,0",1,20120101})
?C(2, {c_cycle_act_couple_propose,2,"64010,1,1;31038,5,0;32016,2,0;32017,2,0",2,20120101})
?C(3, {c_cycle_act_couple_propose,3,"64011,1,1;31038,10,0;32016,3,0;32017,3,0",3,20120101})
?C(4, {c_cycle_act_couple_propose,4,"79149,1,1",4,20120101})
?CFG_E.
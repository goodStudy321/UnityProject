-module(cfg_cycle_act_couple_login).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_cycle_act_couple_login,1,"32016,1,1;30402,2,1;31000,1,1;31005,1,1",1,20120101})
?C(2, {c_cycle_act_couple_login,2,"32016,1,1;31012,1,1;32017,1,1;103,5,1",2,20120101})
?C(3, {c_cycle_act_couple_login,3,"32016,1,1;30402,2,1;31000,1,1;31005,1,1",1,20120101})
?C(4, {c_cycle_act_couple_login,4,"32016,1,1;31012,1,1;32017,1,1;103,5,1",2,20120101})
?CFG_E.
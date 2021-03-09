-module(cfg_act_firstrecharge).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_act_firstrecharge,1,10,"29999,1,1;35212,1,1;3060100,1,1;31001,1,1;103,10,1;1,1000000,1"})
?C(2, {c_act_firstrecharge,2,0,"31025,1,1;36012,1,1;23537,1,1;31001,1,1;6100001,15,1;1,1000000,1"})
?C(3, {c_act_firstrecharge,3,0,"3065100,1,1;30302,1,1;30303,1,1;31001,1,1;30301,10,1;1,1000000,1"})
?CFG_E.
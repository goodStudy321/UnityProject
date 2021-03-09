-module(cfg_act_online).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(5, {c_act_online,5,[1,1000000,1]})
?C(25, {c_act_online,25,[64303,1,1]})
?C(30, {c_act_online,30,[30301,5,1]})
?C(60, {c_act_online,60,[3,50,1]})
?CFG_E.
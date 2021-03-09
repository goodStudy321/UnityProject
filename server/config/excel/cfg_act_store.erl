-module(cfg_act_store).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_act_store,1,[220053,1],32013,180,1})
?C(2, {c_act_store,2,[6100005,1],32013,100,5})
?C(3, {c_act_store,3,[30344,1],32013,40,2})
?C(4, {c_act_store,4,[30345,1],32013,40,2})
?C(5, {c_act_store,5,[31032,1],32013,30,5})
?C(6, {c_act_store,6,[31008,1],32013,40,10})
?C(7, {c_act_store,7,[103,1],32013,10,10})
?C(8, {c_act_store,8,[6100002,1],32013,60,30})
?C(9, {c_act_store,9,[6100001,1],32013,5,99})
?CFG_E.
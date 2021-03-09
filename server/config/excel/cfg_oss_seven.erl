-module(cfg_oss_seven).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_oss_seven,1,[3,1028,1],1028})
?C(2, {c_oss_seven,2,[3,688,1],1028})
?C(3, {c_oss_seven,3,[3,788,1],1028})
?C(4, {c_oss_seven,4,[3,888,1],1028})
?C(5, {c_oss_seven,5,[3,988,1],1028})
?C(6, {c_oss_seven,6,[3,1188,1],1028})
?C(7, {c_oss_seven,7,[3,1320,1],1028})
?CFG_E.
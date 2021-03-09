-module(cfg_trevi_fountain).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_trevi_fountain,1,1,[3090000,1,1],166666,6})
?C(2, {c_trevi_fountain,2,1,[3090000,1,1],166666,6})
?C(3, {c_trevi_fountain,3,1,[3065400,1,1],166667,6})
?C(4, {c_trevi_fountain,4,1,[3065400,1,1],166667,6})
?C(5, {c_trevi_fountain,5,1,[3060900,1,1],166667,6})
?C(6, {c_trevi_fountain,6,1,[3060900,1,1],166667,6})
?C(7, {c_trevi_fountain,7,0,[30001,8,1],140000,6})
?C(8, {c_trevi_fountain,8,0,[30011,8,1],120000,6})
?C(9, {c_trevi_fountain,9,0,[1,5000000,1],100000,6})
?C(10, {c_trevi_fountain,10,0,[30322,10,1],120000,6})
?C(11, {c_trevi_fountain,11,0,[30402,10,1],120000,6})
?C(12, {c_trevi_fountain,12,0,[6100001,15,1],120000,6})
?C(13, {c_trevi_fountain,13,0,[6100002,4,1],60000,6})
?C(14, {c_trevi_fountain,14,0,[103,10,1],80000,6})
?C(15, {c_trevi_fountain,15,0,[30323,2,1],40000,6})
?C(16, {c_trevi_fountain,16,0,[63005,1,1],100000,6})
?CFG_E.
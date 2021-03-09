-module(cfg_role_level_panicbuy).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_role_level_panicbuy,1,65,1,2000000,20,3,2,24,3})
?C(2, {c_role_level_panicbuy,2,75,30305,1,30,3,2,24,3})
?C(3, {c_role_level_panicbuy,3,85,30369,1,30,3,2,24,3})
?C(4, {c_role_level_panicbuy,4,120,35218,1,12,2,1,24,3})
?C(5, {c_role_level_panicbuy,5,125,35101,1,22,3,5,24,3})
?C(6, {c_role_level_panicbuy,6,125,31013,1,75,2,5,24,3})
?C(8, {c_role_level_panicbuy,8,150,31032,2,24,2,2,24,3})
?C(10, {c_role_level_panicbuy,10,213,31003,1,499,3,5,24,3})
?C(11, {c_role_level_panicbuy,11,213,31038,10,25,3,5,24,3})
?C(12, {c_role_level_panicbuy,12,220,32004,1,25,3,5,24,3})
?C(18, {c_role_level_panicbuy,18,260,103,60,60,3,2,24,3})
?CFG_E.
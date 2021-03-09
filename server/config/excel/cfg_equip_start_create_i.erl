-module(cfg_equip_start_create_i).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_equip_start_create_i,1,100,0,0,0})
?C(2, {c_equip_start_create_i,2,100,0,0,0})
?C(3, {c_equip_start_create_i,3,90,10,0,0})
?C(4, {c_equip_start_create_i,4,0,83,17,0})
?C(5, {c_equip_start_create_i,5,0,92,8,0})
?C(6, {c_equip_start_create_i,6,0,0,0,100})
?CFG_E.
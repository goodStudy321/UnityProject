-module(cfg_equip_star_suit).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(2, {c_equip_refine_suit,2,1500,75,0,0})
?C(4, {c_equip_refine_suit,4,3300,165,0,0})
?C(6, {c_equip_refine_suit,6,5200,260,0,0})
?C(8, {c_equip_refine_suit,8,7300,365,0,0})
?C(10, {c_equip_refine_suit,10,9600,480,0,0})
?C(12, {c_equip_refine_suit,12,12100,605,0,0})
?C(14, {c_equip_refine_suit,14,14900,745,0,0})
?C(16, {c_equip_refine_suit,16,17900,895,0,0})
?C(18, {c_equip_refine_suit,18,21300,1065,0,0})
?C(20, {c_equip_refine_suit,20,25000,1250,0,0})
?C(22, {c_equip_refine_suit,22,29100,1455,0,0})
?C(24, {c_equip_refine_suit,24,33600,1680,0,0})
?C(26, {c_equip_refine_suit,26,38500,1925,0,0})
?C(28, {c_equip_refine_suit,28,44000,2200,0,0})
?C(30, {c_equip_refine_suit,30,50000,2500,0,0})
?CFG_E.
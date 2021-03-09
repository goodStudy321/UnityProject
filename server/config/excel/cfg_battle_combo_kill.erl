-module(cfg_battle_combo_kill).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(0, {c_battle_combo,0,10,5})
?C(3, {c_battle_combo,3,20,10})
?C(5, {c_battle_combo,5,30,15})
?C(8, {c_battle_combo,8,40,20})
?C(10, {c_battle_combo,10,50,25})
?C(20, {c_battle_combo,20,60,30})
?C(50, {c_battle_combo,50,70,35})
?CFG_E.
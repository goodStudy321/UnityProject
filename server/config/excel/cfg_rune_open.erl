-module(cfg_rune_open).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_rune_open,1,0})
?C(2, {c_rune_open,2,40004})
?C(3, {c_rune_open,3,40008})
?C(4, {c_rune_open,4,40012})
?C(5, {c_rune_open,5,40016})
?C(6, {c_rune_open,6,40020})
?C(7, {c_rune_open,7,40024})
?C(8, {c_rune_open,8,40032})
?C(9, {c_rune_open,9,0})
?C(10, {c_rune_open,10,0})
?CFG_E.
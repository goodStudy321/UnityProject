-module(cfg_fbt_region).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_fbt_region,1,[5756,1700,10208],500,1,1})
?C(2, {c_fbt_region,2,[14906,1700,10138],500,1,1})
?C(3, {c_fbt_region,3,[15056,1700,1708],500,1,1})
?C(4, {c_fbt_region,4,[5906,1700,1758],500,1,1})
?C(5, {c_fbt_region,5,[10107,1700,6116],750,2,1})
?CFG_E.
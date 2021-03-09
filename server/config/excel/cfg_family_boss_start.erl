-module(cfg_family_boss_start).
-include("config.hrl").
-export[find/1].
?CFG_H

?C(5, {c_family_boss_start,5,[0,60]})
?C(4, {c_family_boss_start,4,[60,120]})
?C(3, {c_family_boss_start,3,[120,180]})
?C(2, {c_family_boss_start,2,[180,240]})
?C(1, {c_family_boss_start,1,[240,300]})
?CFG_E.
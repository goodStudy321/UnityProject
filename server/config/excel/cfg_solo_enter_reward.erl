-module(cfg_solo_enter_reward).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_solo_enter_reward,1,"30322,1;107,1;26,400"})
?C(5, {c_solo_enter_reward,5,"30322,2;107,2;26,600"})
?C(10, {c_solo_enter_reward,10,"30322,3;107,3;26,1000"})
?CFG_E.
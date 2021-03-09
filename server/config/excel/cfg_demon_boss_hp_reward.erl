-module(cfg_demon_boss_hp_reward).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_demon_boss_hp_reward,1,70,"35721,1"})
?C(2, {c_demon_boss_hp_reward,2,50,"35722,1"})
?C(3, {c_demon_boss_hp_reward,3,30,"35723,1"})
?C(4, {c_demon_boss_hp_reward,4,10,"35724,1"})
?CFG_E.
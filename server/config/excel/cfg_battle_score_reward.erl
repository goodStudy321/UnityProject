-module(cfg_battle_score_reward).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(500, {c_battle_score_reward,500,5,"30322,1"})
?C(800, {c_battle_score_reward,800,10,"30322,1"})
?C(1200, {c_battle_score_reward,1200,15,"30322,1"})
?C(1600, {c_battle_score_reward,1600,20,"30322,2"})
?C(2000, {c_battle_score_reward,2000,25,"30322,2"})
?C(2500, {c_battle_score_reward,2500,30,"30322,2"})
?C(3000, {c_battle_score_reward,3000,35,"30322,2"})
?CFG_E.
-module(cfg_battle_rank_reward).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C({1,1}, {c_battle_rank_reward,1,1,"30322,7;220004,1",100})
?C({2,3}, {c_battle_rank_reward,2,3,"30322,6;220005,1",95})
?C({4,10}, {c_battle_rank_reward,4,10,"30322,5",90})
?C({11,20}, {c_battle_rank_reward,11,20,"30322,4",85})
?C({21,9999}, {c_battle_rank_reward,21,9999,"30322,4",80})
?CFG_E.
-module(cfg_offline_solo_reward).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C({1,1}, {c_offline_solo_reward,1,1,15000,3000000})
?C({2,3}, {c_offline_solo_reward,2,3,13000,3000000})
?C({4,10}, {c_offline_solo_reward,4,10,11000,2500000})
?C({11,20}, {c_offline_solo_reward,11,20,10000,2000000})
?C({21,50}, {c_offline_solo_reward,21,50,8000,1500000})
?C({51,200}, {c_offline_solo_reward,51,200,7000,1000000})
?C({201,99999}, {c_offline_solo_reward,201,99999,5000,1000000})
?CFG_E.
-module(cfg_daily_liveness_reward).
-include("config.hrl").
-export[find/1].
?CFG_H

?C(30, {c_daily_liveness_reward,30,"1,150000"})
?C(60, {c_daily_liveness_reward,60,"30403,10"})
?C(100, {c_daily_liveness_reward,100,"3,100"})
?C(180, {c_daily_liveness_reward,180,"210005,5"})
?C(200, {c_daily_liveness_reward,200,"3,200"})
?CFG_E.
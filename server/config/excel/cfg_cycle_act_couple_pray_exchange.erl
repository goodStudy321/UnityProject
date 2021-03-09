-module(cfg_cycle_act_couple_pray_exchange).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_cycle_act_couple_pray_exchange,1,30,"35272,1,1",20120101})
?C(2, {c_cycle_act_couple_pray_exchange,2,60,"35273,1,1",20120101})
?C(3, {c_cycle_act_couple_pray_exchange,3,100,"35274,1,1",20120101})
?CFG_E.
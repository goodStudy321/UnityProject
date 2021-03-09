-module(cfg_family_td_rank_exp).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C({1,1}, {c_family_td_rank_exp,1,1,13000})
?C({2,2}, {c_family_td_rank_exp,2,2,12000})
?C({3,10}, {c_family_td_rank_exp,3,10,10000})
?C({11,9999}, {c_family_td_rank_exp,11,9999,9000})
?CFG_E.
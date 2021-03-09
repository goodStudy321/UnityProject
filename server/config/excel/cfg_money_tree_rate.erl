-module(cfg_money_tree_rate).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_money_tree_rate,1,8400})
?C(2, {c_money_tree_rate,2,1000})
?C(3, {c_money_tree_rate,3,300})
?C(5, {c_money_tree_rate,5,200})
?C(10, {c_money_tree_rate,10,100})
?CFG_E.
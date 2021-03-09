-module(cfg_bag_content).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_bag_content,1,100,200})
?C(2, {c_bag_content,2,60,100})
?C(3, {c_bag_content,3,200,200})
?C(4, {c_bag_content,4,200,200})
?C(5, {c_bag_content,5,200,200})
?C(6, {c_bag_content,6,200,200})
?C(7, {c_bag_content,7,200,200})
?C(8, {c_bag_content,8,100,100})
?CFG_E.
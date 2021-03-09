-module(cfg_bless_rate).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(101, {c_bless_rate,101,1,10,0})
?C(102, {c_bless_rate,102,1,20,20})
?C(103, {c_bless_rate,103,1,40,40})
?C(104, {c_bless_rate,104,1,100,60})
?C(105, {c_bless_rate,105,1,200,80})
?C(106, {c_bless_rate,106,1,400,100})
?C(107, {c_bless_rate,107,1,1000,120})
?C(108, {c_bless_rate,108,1,2000,140})
?C(109, {c_bless_rate,109,1,4000,160})
?C(110, {c_bless_rate,110,1,10000,180})
?C(111, {c_bless_rate,111,1,20000,200})
?C(201, {c_bless_rate,201,2,0,0})
?C(202, {c_bless_rate,202,2,1,40})
?C(203, {c_bless_rate,203,2,2,80})
?C(204, {c_bless_rate,204,2,3,120})
?C(205, {c_bless_rate,205,2,4,160})
?C(206, {c_bless_rate,206,2,5,200})
?CFG_E.
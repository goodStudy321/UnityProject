-module(cfg_act_dayrecharge_count).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_act_dayrecharge_count,1,"30345,1",300})
?C(2, {c_act_dayrecharge_count,2,"30344,1",300})
?C(3, {c_act_dayrecharge_count,3,"30346,1",300})
?C(4, {c_act_dayrecharge_count,4,"64013,1",300})
?CFG_E.
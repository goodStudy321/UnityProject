-module(cfg_fbt_occupy).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_fbt_occupy,1,10})
?C(2, {c_fbt_occupy,2,20})
?C(3, {c_fbt_occupy,3,30})
?C(4, {c_fbt_occupy,4,40})
?C(5, {c_fbt_occupy,5,50})
?C(6, {c_fbt_occupy,6,60})
?C(7, {c_fbt_occupy,7,70})
?C(8, {c_fbt_occupy,8,80})
?C(9, {c_fbt_occupy,9,90})
?C(10, {c_fbt_occupy,10,100})
?CFG_E.
-module(cfg_week_card).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_week_card,1,1,2,40,[],[],1,1,0,1,1288})
?C(2, {c_week_card,2,2,2,1,[],[],1,999,0,3,0})
?C(3, {c_week_card,3,1,2,100,[],[],3,5,0,1,888})
?CFG_E.
-module(cfg_cycle_act_couple_pray).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_cycle_act_couple_pray,1,"3,100,700,0;30341,10,2500,0;30402,10,2150,0;30003,1,500,0",5850,1,20120101})
?C(2, {c_cycle_act_couple_pray,2,"30346,1,200,1;63008,1,600,1;30344,1,500,0;30345,1,500,0;30343,1,500,0;30342,2,1500,0",3800,2,20120101})
?C(3, {c_cycle_act_couple_pray,3,"3060300,1,350,1",350,3,20120101})
?CFG_E.
-module(cfg_hunt_treasure_event).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(101, {c_hunt_treasure_event,101,"道具奖励",0,"","",0,"","3020300,1;3020200,1","3020300,1;3020200,1"})
?C(201, {c_hunt_treasure_event,201,"boss挑战",600,"210204,1,300,10000|210206,301,500,10000","",60001,"-50,-360;-50,-360","3020300,1;3020200,1",""})
?C(301, {c_hunt_treasure_event,301,"组队挑战",600,"","60002,1,300,10000|60003,301,500,10000",60002,"","3020300,1;3020200,1",""})
?CFG_E.
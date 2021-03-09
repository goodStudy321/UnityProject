-module(cfg_family_td_refresh).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(30, {c_family_td_refresh,30,"291001,5;291009,1","291001,5;291009,1",""})
?C(90, {c_family_td_refresh,90,"291002,5;291010,1","291002,5;291010,1",""})
?C(150, {c_family_td_refresh,150,"291003,5;291011,1","291003,5;291011,1",""})
?C(210, {c_family_td_refresh,210,"291004,5;291012,1","291004,5;291012,1",""})
?C(240, {c_family_td_refresh,240,"","","291017,5"})
?C(270, {c_family_td_refresh,270,"291005,5;291013,1","291005,5;291013,1",""})
?C(330, {c_family_td_refresh,330,"291006,5;291014,1","291006,5;291014,1",""})
?C(360, {c_family_td_refresh,360,"","","291017,5"})
?C(390, {c_family_td_refresh,390,"291007,5;291015,1","291007,5;291015,1",""})
?C(450, {c_family_td_refresh,450,"291008,5;291016,1","291008,5;291016,1",""})
?C(480, {c_family_td_refresh,480,"","","291017,5"})
?CFG_E.
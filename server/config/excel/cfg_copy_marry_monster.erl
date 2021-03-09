-module(cfg_copy_marry_monster).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(3001801, {c_copy_marry_monster,3001801,270301,8,"-1800,-200;-1000,200","1000,-200;1800,200"})
?C(3001802, {c_copy_marry_monster,3001802,270302,15,"-550,3200;600,4300",""})
?C(3001803, {c_copy_marry_monster,3001803,270303,15,"50,11550;1400,12950",""})
?C(3001804, {c_copy_marry_monster,3001804,270304,1,"3050,17550;3050,17550",""})
?CFG_E.
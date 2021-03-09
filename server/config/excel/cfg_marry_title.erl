-module(cfg_marry_title).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_marry_title,1,42,2019,1,0})
?CFG_E.
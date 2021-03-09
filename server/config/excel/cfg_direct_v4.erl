-module(cfg_direct_v4).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(210003, 3017000)
?CFG_E.
-module(cfg_forge_soul_open).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(50001, 1)
?C(50010, 2)
?C(50020, 3)
?C(50028, 4)
?C(50033, 5)
?C(50039, 6)
?C(50041, 7)
?C(50044, 8)
?C(50046, 9)
?C(50048, 10)
?CFG_E.
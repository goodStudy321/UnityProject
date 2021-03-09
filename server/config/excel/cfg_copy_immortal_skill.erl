-module(cfg_copy_immortal_skill).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(10001, {c_copy_immortal_skill,10001,208001,5,20})
?C(10002, {c_copy_immortal_skill,10002,208002,2,90})
?CFG_E.
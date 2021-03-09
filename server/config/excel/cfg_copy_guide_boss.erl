-module(cfg_copy_guide_boss).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_copy_guide_boss,1,210000,[0,300],[910001,910002,910003,910004,910005],[35228]})
?C(2, {c_copy_guide_boss,2,220000,[0,300],[920001,920002,920003,920004,920005,920006],[35228]})
?CFG_E.
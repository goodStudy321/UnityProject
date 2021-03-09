-module(cfg_vip_buy).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(210001, {c_vip_buy,210001,20001,"真仙卡",1,30,"",""})
?C(210002, {c_vip_buy,210002,20002,"仙尊卡",20,90,"",""})
?C(210003, {c_vip_buy,210003,20003,"天帝卡",100,180,"",""})
?CFG_E.
-module(cfg_copy_demon).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_copy_demon,1,203001,1,"-675,18844;-675,18844",[300001]})
?C(2, {c_copy_demon,2,203002,1,"712,19814;712,19814",[301001]})
?C(3, {c_copy_demon,3,203003,1,"424,18705;424,18705",[302001]})
?C(4, {c_copy_demon,4,203004,4,"-675,18844;712,19814",[]})
?C(5, {c_copy_demon,5,203005,5,"-675,18844;712,19814",[]})
?CFG_E.
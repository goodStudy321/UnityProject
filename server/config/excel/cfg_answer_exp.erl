-module(cfg_answer_exp).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_answer_exp,1,[0,5],10,5,4})
?C(2, {c_answer_exp,2,[6,7],8,5,4})
?C(3, {c_answer_exp,3,[8,9],6,5,4})
?C(4, {c_answer_exp,4,[10,11],4,5,4})
?C(5, {c_answer_exp,5,[12,13],3,5,4})
?C(6, {c_answer_exp,6,[14,15],2,5,4})
?C(7, {c_answer_exp,7,[16,17],1,5,4})
?CFG_E.
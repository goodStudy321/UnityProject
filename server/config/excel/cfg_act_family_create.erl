-module(cfg_act_family_create).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_act_family_create,1,"创建道庭可领取",1,30,"13,3000;36011,3"})
?C(2, {c_act_family_create,2,"任命3名副庭主",3,30,"13,3000;36011,3"})
?C(3, {c_act_family_create,3,"道庭成员达到20人",20,20,"13,8000;36011,3;30301,20"})
?C(4, {c_act_family_create,4,"道庭成员达到30人",30,15,"13,10000;36011,3;31019,2"})
?C(5, {c_act_family_create,5,"道庭等级达到2级",2,10,"13,5000;36011,3;23547,1"})
?C(6, {c_act_family_create,6,"道庭等级达到3级",3,5,"13,8000;36012,3;23047,1"})
?C(7, {c_act_family_create,7,"加入道庭可领取",1,0,"13,2000;36011,3"})
?CFG_E.
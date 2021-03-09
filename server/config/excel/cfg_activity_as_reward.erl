-module(cfg_activity_as_reward).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_activity_as_reward,1,[1,1],"30332,6,1;220018,1,1",100,220018})
?C(2, {c_activity_as_reward,2,[2,2],"30332,5,1;220019,1,1",98,220019})
?C(3, {c_activity_as_reward,3,[3,3],"30332,5,1;220020,1,1",96,220020})
?C(4, {c_activity_as_reward,4,[4,10],"30332,4,1",94,0})
?C(5, {c_activity_as_reward,5,[11,20],"30332,3,1",92,0})
?C(6, {c_activity_as_reward,6,[21,999],"30332,3,1",90,0})
?CFG_E.
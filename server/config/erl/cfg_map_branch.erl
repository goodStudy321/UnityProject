-module(cfg_map_branch).
-include("config.hrl").
-export([find/1]).
?CFG_H
%% ============= 策划配置内容start ===========
?C(default_map_num, 50) %% 默认最大人数为300人


?C({map_msg_num, 10000}, 2) %% 10000地图，msg进程数量
?C(default_msg_num, 2) %% 默认msg进程数量

?C(fresh_change_num, 4)
?C(fresh_max_line, 15)
?C(fresh_map_list, [10101, 10001, 10010])
%% ============== 策划配置内容end =============
?CFG_E.

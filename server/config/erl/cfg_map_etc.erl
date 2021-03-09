-module(cfg_map_etc).
-include("config.hrl").
-export([find/1]).
?CFG_H
%% ============= 策划配置内容start ===========
%% 动态调整视野,{slice_size,MapID},{SliceWidth,SliceHeight}
%% 方便以后扩展，比如视野调整之后可见区域调整
%% SliceWidth:可见宽度是3*SliceWidth 单位厘米
%% SliceHeight:可见高度是3*SliceHeight 单位厘米
?C({slice_size, 10001}, {1000, 1000}) %% 测试地图1
?C({slice_size, 10002}, {100000, 100000}) %% 单人地图 全地图广播

?C({slice_size, 20101}, {100000, 100000}) %% 单人地图 全地图广播
?C(home_map_id, 10101)

%% ============== 策划配置内容end =============
?CFG_E.

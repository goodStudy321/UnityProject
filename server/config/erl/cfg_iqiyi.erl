-module(cfg_iqiyi).
-include("config.hrl").
-export([find/1]).
?CFG_H
%% ============= 配置内容start ===========
%% 有充值限制的档位 不配置档位表示不限制
%% [{档位, ProductID}|....]
?C(limit_pay_times, [
{2, 10},
{3, 10}
])

%% ============== 配置内容end =============
?CFG_E.

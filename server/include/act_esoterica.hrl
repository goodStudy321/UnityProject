%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 修炼秘籍系统
%%% @end
%%% Created : 11. 十月 2019 11:13
%%%-------------------------------------------------------------------
-author("huangxiangrui").

-ifndef(ACT_ESOTERICA_HRL).
-define(ACT_ESOTERICA_HRL, act_esoterica_hrl).


-define(ORDINARY, 1).   % 凡
-define(CELESTIAL, 2).  % 仙

%% 修炼秘籍等级奖励
-record(c_act_esoterica_reward, {
    id,
    grade,          %% 等级
    ordinary_award, %% 凡品奖励
    celestial_award,%% 仙品奖励
    config_num      %% 套ID
}).


%% 修炼秘境任务库
-record(c_act_esoterica_task, {
    id,
    judge_id,       %% 条件ID
    parameter,      %% 条件参数
    award_num       %% 奖励修炼点
}).
-endif.

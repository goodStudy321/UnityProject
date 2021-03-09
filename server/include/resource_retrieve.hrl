%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十二月 2018 10:11
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(RESOURCE_RETRIEVE_HRL).
-define(RESOURCE_RETRIEVE_HRL, resource_retrieve_hrl).

-define(RETRIEVE_TYPE_GOLD, 1).     %% 元宝找回
-define(RETRIEVE_TYPE_SILVER, 2).   %% 银两找回

-define(RETRIEVE_TIMES_COPY, 1).            %% 副本次数
-define(RETRIEVE_TIMES_MISSION, 2).         %% 任务类型
-define(RETRIEVE_TIMES_ACTIVITY, 3).        %% 活动ID
-define(RETRIEVE_TIMES_OFFLINE_SOLO, 4).    %% 竞技场
-define(RETRIEVE_TIMES_FAMILY_ESCORT, 5).   %% 道庭护送
-define(RETRIEVE_TIMES_BLESS, 6).           %% 闭关修炼
-define(RETRIEVE_TIMES_WORLD_BOSS_TIMES, 7).%% 世界boss次数

-define(RETRIEVE_TIMES_FAMILY_MISSION, 100).

-record(r_resource, {
    resource_id,                %% id
    base_times = 0,             %% 基础次数
    extra_times = 0,            %% 额外次数
    copy_extra_buy_times = 0    %% 副本额外次数购买
}).

-record(c_resource_retrieve, {
    resource_id,            %% id
    name,                   %% 名称
    times_type,             %% 次数计算
    base_times,             %% 基础上限次数
    extra_days,             %% 额外上限天数
    level_exp_rate,         %% 等级经验倍率
    base_rewards,           %% 奖励
    copy_id,                %% 副本ID
    need_silver,            %% 单次银两
    need_base_gold,         %% 单次绑元
    need_extra_gold_list    %% 额外次数单次绑元
}).

-endif.

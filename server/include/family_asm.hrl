%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 道庭任务
%%% @end
%%% Created : 15. 六月 2019 11:33
%%%-------------------------------------------------------------------
-author("huangxiangrui").

-ifndef(FAMILY_ASM_HRL).
-define(FAMILY_ASM_HRL, family_asm_hrl).

-define(IF_THE_REFRESH(NonsuchTime),(NonsuchTime > 0)). % 是否首次更新

-define(PICK_NAPE(Option), Option > 0). % 挑选

-define(PICK_VIP(VIP), VIP >= 4).   % vip4以上

-define(ACCEPTABLE,0). % 可接

-define(QUICKEN,1). % 可请求加速

-define(ALREADY_QUICKEN, 2). % 已请求加速

-define(RECEIVE_REWARD,3).  % 待领取奖励
-define(RECEIVE_REWARD1,4).  % 已领取奖励

-define(RECEIVE_TASK, 0). % 接任务
-define(SEEK_HELP_MEMBERS, 1). % 向道庭成员求助
-define(ABANDON, 2). % 放弃
-define(RECEIVE_REWARD_ALREADY, 3). % 领取奖励

-define(BADGE_PLACE, 13). % 极品刷新12后刷新标记

-define(REFURBISH_1,0). % 元宝刷新
-define(REFURBISH_2, 1). % 极品刷新

-define(CHOOSE_NUM, 3).

%% 使用整点判断极品刷新和跨天时间检测
-define(JUDGEMENT_TIME(Now),
    begin
        {_, {Hour1, Min, Sec}} = time_tool:timestamp_to_datetime(Now),
        [FixedHour, FixedHour1 | _] = common_misc:get_global_list(?GLOBAL_FAMILY_ASM_RENOVATE),
        not ((Hour1 =:= FixedHour orelse Hour1 =:= FixedHour1 orelse Hour1 =:= ?BADGE_PLACE) andalso Min =:= Sec andalso Sec =:= 0) end).

-record(c_family_asm,{
    id,
    star_level,         %% 星级
    time,               %% 时间（min）
    reward,             %% 奖励
    vip_weight,         %% vip权重
    nonsuch_weight      %% 极品权重
}).

-endif.

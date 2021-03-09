%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 四月 2018 11:53
%%%-------------------------------------------------------------------
-author("WZP").

-ifndef(FAMILY_AS_HRL).
-define(FAMILY_AS_HRL, family_as_hrl).


-define(FAMILY_AS_REFRESH_TIME, 120).                 %%  题目自动刷新间隔
-define(FAMILY_AS_IS_CL, 1).                          %%  已食用
-define(FAMILY_AS_IS_NOT_CL, 0).                      %%  未食用
-define(FAMILY_AS_BINGO_ROLE_ID, 1).                  %%  答对时返回所用系统ID
-define(FAMILY_AS_BINGO_END_ROLE_ID, 2).              %%  全部答对时返回所用系统ID
-define(FAMILY_AS_LEVEL, 110).                        %%  参加等级限制
-define(FAMILY_AS_RANK_INTERVAL, 1).                  %%  排序时间间隔
-define(FAMILY_AS_RANK_START_DELAY, 20).              %%  答题开启延时
-define(FAMILY_QUESTION_NUM, 50).                     %%  答题题数
-define(FAMILY_AS_ADD_EXP_TIME, 18).                  %%  答题增加经验间隔奖励对应global表配置
-define(ETS_FAMILY_AS_RANK, ets_family_as_rank).
-define(ETS_FAMILY_AS_EXP, ets_family_as_exp).
-define(FAMILY_AS_BINGO(Name), Name ++ "学识渊博，为道庭获得了1点积分").
-define(FAMILY_AS_BINGO_AND_END(Name), Name ++ "学识渊博，为道庭获得了1点积分，题目已全部答完").



-record(r_family_as_exp, {role_id, exp = 0, add_daily_liveness = false}).
%%   time到达该积分时的时间戳
-record(r_family_as_rank, {family_id, family_name, score = 0, time = 0, rank = 0}).
-record(c_activity_family_as, {
    id,                     %% 题目ID
    question,               %% 题目
    answer                  %% 答案 1正确 0错误
}).

-record(c_activity_family_as_exp, {
    level,                     %% 等级
    exp                       %% 经验
}).

-record(c_activity_family_as_reward, {
    rank,                       %% 排名
    reward1,                    %% 奖励1
    reward2,                    %% 奖励2
    red_packet                  %% 仙盟红包
}).

-endif.

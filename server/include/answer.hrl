%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 四月 2018 21:28
%%%-------------------------------------------------------------------
-author("WZP").
-include("map.hrl").

-ifndef(ANSWER_HRL).
-define(ANSWER_HRL, answer_hrl).

%%活动状态
-define(WAIT_FOR_ANSWER, 1).    %%答题前1分钟等待答题
-define(ANSWERING, 2).          %%答题中
-define(ANSWERING_FREE, 4).     %%答题中休息期间
-define(ANSWERING_END, 3).      %%不在活动期间

-define(ETS_ANSWER_RANK, ets_answer_rank).    %% 答题排行数据

-define(ANSWERING_BUFF, 305001).                   %%变猪BUFF

-define(ANSWERING_WAIT_TIME, 60).                   %%答题开始后等待时间
-define(ANSWER_TIME, 17).                           %%每道题答题时间
-define(ANSWER_NOTICE_TIME, 3).                     %%提示时间
-define(QUESTION_NUM, 20).                           %%答题题数
-define(MAX_EXTRA_ROLE_NUM, 100).                   %%一条线上只能有100个人
-define(INIT_RANK, {0, {}}).                        %%排行榜数据 {探花积分，{状元信息，榜眼信息，探花信息}}


-define(ANSWER_RIGHT_CIRCLE, 1).       %%正确
-define(ANSWER_WRONG_CIRCLE, 0).       %%错误
-define(ANSWER_LEAVE_MAP, 2).          %%离开地图
-define(ANSWER_IN_MAP, 3).             %%在地图


-define(ANSWER_IS_END, 1).              %%答题结束
-define(ANSWER_IS_NOT_END, 0).          %%答题进行


-define(ANSWER_MX, 3050).   %%比2236小为正确 大为错误


-define(ANSWER_RIGHT_POS, #r_pos{mx = 1842, my = 1459, mdir = 180, tx = 18, ty = 14, dir = 4}).       %%正确X坐标
-define(ANSWER_WRONG_POS, #r_pos{mx = 4225, my = 1545, mdir = 180, tx = 42, ty = 15, dir = 4}).       %%错误X坐标

-define(KICKED_UP, 2).        %%踢飞
-define(KICKED_UP_CD, 60).    %%冷却60
-define(INTERFERE, 1).        %%干扰
-define(INTERFERE_CD, 40).    %%40

-record(c_activity_question, {
    id,                     %% 题目ID
    answer                  %% 答案 1正确 0错误
}).

-record(c_answer_exp, {
    id,                       %% 编号
    section,                  %% 时区
    score,                    %% 积分
    right_exp_rate,           %% 答对积分
    wrong_exp_rate            %% 答错积分
}).

-record(c_activity_as_reward, {
    id,                       %% 编号
    section,                  %% rank区间
    reward,                   %% 奖励
    rate,                     %% 经验倍率
    title                     %% 称号
}).


-record(r_answer_ctrl, {cur_extra_id = 0, cur_role_num = 0, extra_id_list = []}).
-record(r_answer_map, {extra_id, enter_role_info = []}).
-record(r_answer_rank, {role_id, score = 0, add_score = 0, name, rank, in_map = ?ANSWER_IN_MAP}).
-record(r_answer_circle, {role_id, time = 0, type = 1}).

%%   start_time      -  活动开启时间
%%   settlement_time -  单道答题结束开始结算
-record(r_answer_status, {status, start_time, settlement_time}).



-endif.

%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(ROBOT_HRL).
-define(ROBOT_HRL, true).

%% 主sup名称

%% client sup名称
-define(CLIENT_SUP, robot_client_sup).

%% 测试用到的物品id

%% 消息头长度
-define(PACKET_LEN, 2).
-define(RECORD_TAB, record_tab).
%%--------
%% 日志
%%--------

-ifndef(IF).
-define(IF(C, T, F), (case (C) of true -> (T); false -> (F) end)).
-endif.

-define(STATE_LOGIN, 0).
-define(STATE_FINISH, 1).

-define(DEFAULT_EXTRA_INTERVAL, 600).

-define(ROBOT_OP_START_RECORD,1).
-define(ROBOT_OP_STOP_RECORD,2).
-define(ROBOT_OP_RECORD,3).
-define(ROBOT_OP_GET_FILE,99).

-define(ROBOT_FIGHT_FIGHT, 1).  %% 处于战斗状态
-define(ROBOT_FIGHT_OTHER, 2).  %% 处于其他状态

-record(r_role_client, {
    name,               %% 角色名
    socket,             %% 角色socket
    state               %% 角色状态
}).

-record(r_robot_start, {
    robot_type,             %% 启动的类型
    sec_start_num,          %% 每秒启动的个数
    all_sec,                %% 运行的秒数
    now_counter = 0,        %% 当前counter值
    all_robot_counter = 0,  %% 所有的机器人数量
    start_counter
}).

-record(r_robot_stop, {
    stop_robot_type,    %% 0表示所有类型都停止
    stop_num            %% 表示该类型所有的都停止
}).

-endif.
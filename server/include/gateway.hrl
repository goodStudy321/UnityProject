%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 四月 2018 10:02
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(GATEWAY_COMMON_HRL).
-define(GATEWAY_COMMON_HRL, gateway_common_hrl).

-define(ACCEPTOR_NUM, 50).  %% 网关acceptor_num
-define(GATEWAY_AUTH_KEY, "gateway-auth-key").
-define(MAX_ONLINE_NUM, 8000).     %% 每个服最大在线8000人


-define(HEART_BEAT_CHECK_TIME, 60). %% 60秒未接收到协议则认为网络断开

-define(PROTO_SECOND_COUNTER, 10).  %% 每10秒做一次统计
-define(PROTO_CHECK_COUNTER, 3).    %% 第3次对之前超标的包进行检验

%% 每秒发包量检测
-define(PACKET_CHECK_LIST, [
    {all, 40},                      %% 所有包量
    {m_move_role_walk_tos, 5},      %% 走路包（前端是1秒2个）
    {m_stick_move_tos, 8},          %% 摇杆移动（前端是最多1秒5个）
    {m_fight_prepare_tos, 7},       %% prepare
    {m_fight_attack_tos, 8}         %% fight_attack
]).

%%
-record(r_packet_check, {
    loop_counter = 0,   %% 每loop一次counter+1
    counter = 0,        %% 校验counter
    blame_list = [],    %% 超标的列表
    record_list = []    %% [{RecordName, Value}|....]
}).

-endif.
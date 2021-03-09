%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 三月 2018 12:08
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(PLATFORM_HRL).
-define(PLATFORM_HRL, platform_hrl).

-define(AGENT_LOCAL, 1).            %% 本地
-define(AGENT_BANSHU, 2).           %% 版署
-define(AGENT_JUNHAI_AND, 3).       %% 君海安卓平台
-define(AGENT_JUNHAI_IOS, 4).       %% 君海IOS平台
-define(AGENT_IQIYI, 5).            %% 爱奇艺平台
-define(AGENT_SQ, 6).               %% 神起平台
-define(AGENT_GUILD, 7).            %% 公会平台

-define(AGENT_DT, 51).              %% 顶拓


%% 服务器模块列表
-define(PLATFORM_AGENT_MOD_LIST, [
    #c_agent_mod{agent_id = ?AGENT_JUNHAI_AND, common_mod = common_junhai},
    #c_agent_mod{agent_id = ?AGENT_JUNHAI_IOS, common_mod = common_junhai},
    #c_agent_mod{agent_id = ?AGENT_SQ, common_mod = common_sq},
    #c_agent_mod{agent_id = ?AGENT_GUILD, common_mod = common_junhai}
]).


%% 君海平台参数
-define(PLATFORM_JUNHAI_AND, junhai_and).       %% 君海安卓平台
-define(PLATFORM_JUNHAI_IOS, junhai_ios).       %% 君海IOS平台
-define(PLATFORM_IQIYI_IOS, iqiyi_ios).         %% 爱奇艺IOS
-define(PLATFORM_SQ_IOS, sq_ios).               %% 神起IOS
-define(PLATFORM_MUSHAO_IOS, mushao_ios).       %% 木勺IOS
-define(PLATFORM_YOUJING_IOS, youjing_ios).     %% 游境 IOS
-define(PLATFORM_ZHANGYOU_IOS, zhangyou_ios).   %% 掌游 IOS
-define(PLATFORM_XIAOQI_IOS, xiaoqi_ios).       %% 小七IOS
-define(PLATFORM_AND_DT, and_dt).               %% 顶拓

-define(IQIYI_IOS_CHANNEL_ID, 10654).       %% 爱奇艺IOS渠道

-define(SQ_IOS_CHANNEL_ID, 10722).          %% 神起IOS渠道
-define(MUSHAO_IOS_CHANNEL_ID, 10752).      %% 木勺IOS渠道
-define(YOUJING_IOS_CHANNEL_ID, 10751).     %% 游境IOS渠道
-define(ZHANGYOU_IOS_CHANNEL_ID, 10767).    %% 掌游IOS渠道
-define(XIAOQI_IOS_CHANNEL_ID, 10774).      %% 小七IOS

-define(AND_DT_CHANNEL_ID, 20002).          %% AND-顶拓

-define(IOS_OLD_GAME_CHANNEL_ID, "1000").
-define(IOS_NEW_GAME_CHANNEL_ID, "107035").
-define(IOS_JUNHAI_GAME_CHANNEL_ID, 107035).    %% 君海IOS渠道
-define(IOS_XIAOQI_MIX_GAM_CHANNEL_ID, 112775). %% 小7IOS混服
-define(IOS_YOUJIA_GAME_CHANNEL_ID, 112797).    %% 游佳IOS
-define(IOS_JIANGUO_GAME_CHANNEL_ID, 112907).   %% 坚果IOS
-define(IOS_RAIN_GAME_CHANNEL_ID, 113114).      %% 小雨滴IOS
-define(IOS_LINGXIANG_GAME_CHANNEL_ID, 113224). %% 灵响IOS
-define(IOS_JIANGUO2_GAME_CHANNEL_ID, 113428).  %% 坚果IOS2
-define(IOS_JIANGUO3_GAME_CHANNEL_ID, 113805).  %% 坚果IOS2

-define(MUSHAO_AND_GAME_CHANNEL_ID, 112505).    %% 木勺IOS包
-define(MUSHAO_IOS_GAME_CHANNEL_ID, 112541).    %% 木勺安卓包
-define(PENGCHAO_AND_GAME_CHANNEL_ID, 112647).  %% 鹏超安卓1
-define(PENGCHAO_IOS_GAME_CHANNEL_ID, 112689).  %% 鹏超IOS
-define(KUISHE_AND_GAME_CHANNEL_ID, 112774).    %% 蝰蛇安卓1
-define(KUISHE_IOS_GAME_CHANNEL_ID, 112769).    %% 蝰蛇IOS
-define(XIAOQI_AND_GAME_CHANNEL_ID, 112591).    %% 小七专服安卓
-define(XIAOQI_IOS_GAME_CHANNEL_ID, 112733).    %% 小七IOS
-define(LINGXIANG_AND_GAME_CHANNEL_ID_1, 112837).   %% 灵响安卓1
-define(LINGXIANG_AND_GAME_CHANNEL_ID_2, 113022).   %% 灵响安卓2
-define(JIANGUO4_AND_GAME_CHANNEL_ID, 113345).      %% 坚果安卓4
-define(JIANGUO5_GAME_CHANNEL_ID, 114057).          %% 坚果安卓5

-define(XINJI_AND_GAME_CHANNEL_ID, 500019).          %% 心迹and
-define(XINJI_IOS_GAME_CHANNEL_ID, 500021).          %% 心迹ios


-define(HUAWEI_GAME_CHANNEL_ID, 111197).    %% 华为
-define(HUAWEI_XIN_GAME_CHANNEL_ID, 113991).    %% 华为新


%% 平台角色列表
-define(PLATFORM_ROLE_MOD_LIST, [
    #c_pf_mod{platform = ?PLATFORM_JUNHAI_AND, role_mod = mod_role_junhai_andriod},
    #c_pf_mod{platform = ?PLATFORM_JUNHAI_IOS, role_mod = mod_role_junhai_ios},
    #c_pf_mod{platform = ?PLATFORM_IQIYI_IOS, role_mod = mod_role_iqiyi_ios},
    #c_pf_mod{platform = ?PLATFORM_SQ_IOS, role_mod = mod_role_sq_ios},
    #c_pf_mod{platform = ?PLATFORM_MUSHAO_IOS, role_mod = mod_role_mushao_ios},
    #c_pf_mod{platform = ?PLATFORM_YOUJING_IOS, role_mod = mod_role_youjing_ios},
    #c_pf_mod{platform = ?PLATFORM_ZHANGYOU_IOS, role_mod = mod_role_zhangyou_ios},
    #c_pf_mod{platform = ?PLATFORM_XIAOQI_IOS, role_mod = mod_role_xiaoqi_ios}
]).

%% 部分IOS与安卓帐号互通，让IOS的game_channel_id取安卓的game_channel_id
-define(ACCOUNT_GAME_CHANNEL_ID, [
    {?HUAWEI_XIN_GAME_CHANNEL_ID, ?HUAWEI_GAME_CHANNEL_ID},
    {?MUSHAO_IOS_GAME_CHANNEL_ID, ?MUSHAO_AND_GAME_CHANNEL_ID},
    {?KUISHE_AND_GAME_CHANNEL_ID, ?KUISHE_IOS_GAME_CHANNEL_ID},
    {?XIAOQI_IOS_GAME_CHANNEL_ID, ?XIAOQI_AND_GAME_CHANNEL_ID},
    {?LINGXIANG_AND_GAME_CHANNEL_ID_1, ?IOS_RAIN_GAME_CHANNEL_ID},
    {?LINGXIANG_AND_GAME_CHANNEL_ID_2, ?IOS_RAIN_GAME_CHANNEL_ID},
    {?IOS_JIANGUO2_GAME_CHANNEL_ID, ?JIANGUO4_AND_GAME_CHANNEL_ID},
    {?IOS_JIANGUO3_GAME_CHANNEL_ID, ?JIANGUO4_AND_GAME_CHANNEL_ID},
    {?JIANGUO5_GAME_CHANNEL_ID, ?JIANGUO4_AND_GAME_CHANNEL_ID},
    {?XINJI_IOS_GAME_CHANNEL_ID, ?XINJI_AND_GAME_CHANNEL_ID}
]).

-define(JUNHAI_LOG_LOGIN, login).                   %% 登录
-define(JUNHAI_LOG_CREATE, create_role).            %% 创角
-define(JUNHAI_LOG_PAY, order).                     %% 订单
-define(JUNHAI_LOG_EVENT_LEVEL, role_update).       %% 升级
-define(JUNHAI_LOG_ONLINE, online).                 %% 区服在线人数
-define(JUNHAI_LOG_OFFLINE, offline).               %% 在线时长
-define(JUNHAI_LOG_EVENT_GOLD, coin_trade).         %% 元宝获得与消耗
-define(JUNHAI_LOG_CHAT, chat).                     %% 聊天

-define(JUNHAI_WORKER_NUM, 10).         %% 进程数量
-define(JUNHAI_SUB_WORKER_NUM, 3).      %% 子进程3个
-define(JUNHAI_LOG_NUM, 50).            %% 单次循环处理50条
-define(JUNHAI_LOG_LOOP_TIME, 2000).    %% 2秒循环一次
-define(JUNHAI_LOG_LOOP_SEC, 10 * 60).  %% 10分钟循环.
-define(JUNHAI_LOG_LOOP_NUM, 500).      %% 每次拿500条

%% 君海元宝日志类型
-define(GOLD_TYPE_PAY, 0).                %% 充值获得
-define(GOLD_TYPE_BACK_SEND, 1).          %% 游戏内部发放
-define(GOLD_TYPE_EXCHANGE, 2).           %% 交易相关
-define(GOLD_TYPE_PAY_SEND, 3).           %% 充值赠送获得
-define(GOLD_TYPE_CONSUME, 4).            %% 消耗
-define(GOLD_TYPE_OTHER, 5).              %% 其它


-define(ANDRIOD_PAY_URL, andriod_pay_url).          %% 君海IOS AND
-define(IOS_PAY_URL, ios_pay_url).                  %% 君海IOS URL
-define(IQIYI_IOS_PAY_URL, iqiyi_ios_pay_url).      %% IQIYI IOS URL
-define(SQ_IOS_PAY_URL, sq_ios_pay_url).            %% 神奇 IOS URL
-define(MUSHAO_IOS_PAY_URL, mushao_ios_pay_url).    %% 木勺 IOS URL
-define(YOUJING_IOS_PAY_URL, youjing_ios_pay_url).  %% 游境 IOS URL
-define(ZHANGYOU_IOS_PAY_URL, zhangyou_ios_pay_url).%% 掌游 IOS URL

-define(BG_ACT_URL, bg_act_url).

-define(SQ_CHAT_TEXT, 1).   %% 神起-文本
-define(SQ_CHAT_VOICE, 2).  %% 神起-语音

-define(XIAOQI_APP_KEY, "a5379c1a651ea22843997d4296e00b0e").
-define(XIAOQI_PUBLIC_KEY,  "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC3TOWOO0WltwsSTn9ssPB6h+UHjHcKXu/+OK70aYOmuf8LUdFey5bkNZ1aCqShAh6MitgPomiP2fZ6cJX3ZRheeQ9lCM463yYDp5HzZ/I6BqyTUpzuq/Sc7mLbGdPnFZKV8Lc1JwsED0+jj/eSzc62/5Antu4R9zQjJUq7oikN9wIDAQAB").
-define(XIAOQI_PUBLIC_KEY2, "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD5jHF8OXFQLZ6aedmZoQyeFho9NgE0hX+WHWFNfW2fb+Kri2GkucDOpGyJj4KHVbBIt9nc8zC13FbGoPnqS5aGBhOdW7CiAfG4w+FKWzMoMsBDFqx7/7bX0j3aUr+CcY/zEyq1vzvBKYMBOSr1R75G/TwPnfH9mJs6GKgQxATj8QIDAQAB").

-record(r_pf_chat_args, {
    channel_type,
    channel_lang,
    receiver = 0,
    receiver_name = "",
    msg_type = "",
    msg
}).

-record(c_agent_mod, {
    agent_id,
    common_mod
}).

-record(c_pf_mod, {
    platform,
    role_mod
}).

-endif.
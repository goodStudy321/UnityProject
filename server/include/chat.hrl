%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 七月 2017 10:44
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(CHAT_HRL).
-define(CHAT_HRL, chat_hrl).

-define(CHAT_BAN_CHAT_CONFIG, chat_ban_chat_config).    %% 聊天设置
-define(CHAT_BAN_KEY_WORD, chat_ban_key_word).          %% 关键词
-define(CHAT_BAN_SERIES, chat_ban_series).              %% 连续发言封禁
-define(CHAT_BAN_PRIVATE, chat_ban_private).            %% 连续私聊封禁

-define(BAN_TYPE_NORMAL, 1).        %% 封禁
-define(BAN_TYPE_TALK, 2).          %% 禁言

-define(BAN_SUB_TYPE_KEY_WORD, 3).  %% 关键字封禁
-define(BAN_SUB_TYPE_PRIVATE, 4).   %% 连续私聊封禁

%% ("壹","贰","叁","肆","伍","陆","柒","捌","玖")
-define(CHAT_LIST, [22777, 36144, 21441, 32902, 20237, 38470, 26578, 25420, 29590]).

%%(一 二 三 四 五 六 七 八 九)
-define(CHAT_LIST2, [19968, 20108, 19977, 22235, 20116, 20845, 19971, 20843, 20061]).


-define(BAN_WORD, ban_word).    %% 禁言
-define(BAN_ROLE, ban_role).    %% 封角色
-define(BAN_IP, ban_ip).        %% 封IP
-define(BAN_IMEI, ban_imei).    %% 封IMEI

%% 聊天设置
-record(r_ban_chat_config, {
    id,                     %% ID
    min_open_day,           %% 开服天数范围
    max_open_day,           %% 开服天数范围
    channel_list,           %% 禁止发言的频道List
    role_level,             %% 需要的人物等级
    vip_level,              %% 需要的Vip等级
    game_channel_id_list    %% 包渠道
}).

%% 关键词设置
-record(r_ban_key_word, {
    id,                     %% ID
    title,                  %% 关键词
    is_ban_role,            %% 是否封禁角色
    is_ban_imei,            %% 是否封禁imei
    is_ban_ip,              %% 是否封禁ip
    time_duration,          %% 限定时间内
    times,                  %% 多少次
    pay_fee,                %% 累充X分免除
    vip_level,              %% VIP等级达到X级免除
    game_channel_id_list    %% 包渠道ID列表
}).

%% 连续发言禁言
-record(r_ban_series, {
    id,                     %% ID
    time_duration,          %% 限定时间内
    times,                  %% 多少次
    ban_time,               %% 禁言时长
    pay_fee,                %% 累充X分免除
    vip_level,              %% VIP等级达到X级免除
    game_channel_id_list    %% 包渠道ID列表
}).


%% 关键词设置
-record(r_ban_private, {
    id,                     %% ID
    is_ban_role,            %% 是否封禁角色
    is_ban_imei,            %% 是否封禁imei
    is_ban_ip,              %% 是否封禁ip
    time_duration,          %% 限定时间内
    times,                  %% 多少次
    pay_fee,                %% 累充X分免除
    vip_level,              %% VIP等级达到X级免除
    game_channel_id_list    %% 包渠道ID列表
}).

-endif.

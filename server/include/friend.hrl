%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 七月 2017 10:38
%%%-------------------------------------------------------------------
-author("laijichang").

-ifndef(FRIEND_HRL).
-define(FRIEND_HRL, friend_hrl).

-define(MAX_FRIEND_NUM, 50).    %% 好友最大数量
-define(MAX_RECOMMEND_NUM, 9).  %% 好友推荐最大数量
-define(RECOMMEND_TIME, 3).     %% 3秒之后才能刷新

-define(RECENT_CHAT_NUM, 20).   %% 最近聊天

-define(FRIEND_BUFF_CLASS, 303).    %% 组队buff的类型

-define(PRIVATE_CHAT_NUM, 20).  %% 私聊人数

-define(REFUSE, 0). %% 拒绝
-define(AGREE, 1).  %% 同意

-record(c_friendly_level, {
    friendly_level,     %% 亲密度等级
    name,               %% 等级名称
    need_friendly,      %% 需要亲密度
    buff_list           %% 增加buff
}).

-endif.
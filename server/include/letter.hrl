%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 七月 2017 16:06
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(LETTER_HRL).
-define(LETTER_HRL, letter_hrl).
-include("global.hrl").

-define(WORLD_LETTER_CHECK_CD, 3600). %% 一小时检查一次信件过期时间
-define(GM_MAIL_ID, 1).     %% GM信件用的ID
-define(ONE_LETTER_ITEM_NUM, 15).     %% 一封信件最多15个道具

%%信件state
-define(LETTER_NOT_OPEN,  1). %% 信件没有打开
-define(LETTER_HAS_OPEN,  2). %% 信件打开了

%% m_letter_get_tos
-define(GET_LETTER_ALL, 0). %% 获取全部信件
-define(GET_LETTER_NEW, 1). %% 获取新信件

%% m_letter_delete_tos
-define(DELETE_ALL_LETTER, 0).  %% 删除全部已读信件
-define(DELETE_LETTER, 1).      %% 删除指定信件

%% m_letter_accept_goods_tos
-define(RECEIVE_ALL_LETTER, 0). %% 领取所有的信件
-define(RECEIVE_LETTER, 1).     %% 领取指定的信件

-endif.
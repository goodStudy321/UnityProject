%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 七月 2019 14:36
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(WARNING_HRL).
-define(WARNING_HRL, warning_hrl).

-define(WARNING_TYPE_ITEM_ACTION, 1).   %% 道具获取行为警告
-define(WARNING_TYPE_ITEM_GAIN, 2).     %% 道具获取
-define(WARNING_TYPE_ASSET_GAIN, 3).    %% 货币类获得

-define(ITEM_ACTION_WARNING_LANG, "道具获取行为异常").
-define(ITEM_GAIN_WARNING_LANG, "道具数量异常").
-define(ASSET_WARNING_LANG, "货币获得异常").

-endif.

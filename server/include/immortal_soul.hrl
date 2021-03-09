%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十月 2018 11:10
%%%-------------------------------------------------------------------
-author("WZP").

-ifndef(IMMORTAL_SOUL_HRL).
-define(IMMORTAL_SOUL_HRL, immortal_soul_hrl).


-define(IMMORTAL_SOUL_BAG_SIZE, 200).                                                   %%  背包大小

-define(IMMORTAL_SOUL_IS_RIGHT_POS(Pos), (Pos > 900) andalso (908 > Pos) ).            %%  正确镶嵌ID

-define(IMMORTAL_SOUL_GLOBAL_POS,49).            %%开孔等级全局定义

-record(c_immortal_soul_level, {id, level, attr1, val1, attr2, val2, up_dust,dust}).

-record(c_immortal_soul_mix, {id, level, stone, consume1, consume2}).

-record(c_immortal_soul, {id, name, pos, class, type, color}).


-endif.

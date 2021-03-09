%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 九月 2019 15:35
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(LUCKY_TOKEN_HRL).
-define(LUCKY_TOKEN_HRL, lucky_token_hrl).

-define(LUCKY_TOKEN_TIMES_1, 1).
-define(LUCKY_TOKEN_TIMES_10, 10).

-define(LUCKY_TOKEN_BIG_REWARD, 1).
-define(LUCKY_TOKEN_NORMAL, 2).
-record(c_lucky_token, {
    index_id,           %% 序号
    reward_type,        %% 奖励类型
    item_type_id,       %% 道具ID
    item_num,           %% 数量
    weight,             %% 权重
    world_level,
    config_index        %% 套序号
}).

-endif.
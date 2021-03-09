%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 八月 2018 17:41
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(PAY_HRL).
-define(PAY_HRL, pay_hrl).

-define(PACKAGE_TYPE_GOLD, 0).      %% 元宝充值
-define(PACKAGE_PRODUCT_ID, 1).     %% 礼包ID
-define(PAY_PACKAGE_DISCOUNT, 2).   %% 礼包类型--特惠礼包
-define(KING_GUARD, 3).             %% 礼包精灵王
-define(OTHER_PAY_GOLD, 4).         %% 不在充值界面上显示
-define(OPEN_ACT_ESOTERICA, 5).     %% 修炼秘籍购买仙籍

-record(r_pay_back, {
    key,                %% {GameChannelID, UID}
    gold,               %% 元宝
    role_id = 0,        %% 角色ID
    send_open_days = 0  %% 发放奖励天数
}).

-record(c_pay, {
    product_id,             %% 商品ID
    desc,                   %% 商品描述
    game_channel_id_list,   %% 平台ID
    pay_money,              %% 充值金额
    package_type,           %% 礼包类型
    add_gold,               %% 获得元宝数
    first_add_bind_gold,    %% 首充赠送绑定元宝
    other_add_bind_gold,    %% 非首充赠送绑定元宝
    package_days,           %% 礼包持续天数
    package_goods           %% 礼包给的道具
}).

-endif.

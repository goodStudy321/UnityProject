%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 六月 2019 14:40
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(DISCOUNT_PAY_HRL).
-define(DISCOUNT_PAY_HRL, discount_pay_hrl).

-define(DISCOUNT_CONDITION_HAS_FIRST_CHARGE, 1).    %% 完成首充
-define(DISCOUNT_CONDITION_NOT_FIRST_CHARGE, 2).    %% 未完成首充
-define(DISCOUNT_CONDITION_ABOVE_LEVEL, 3).         %% 等级>=
-define(DISCOUNT_CONDITION_BELOW_LEVEL, 4).         %% 等级<=
-define(DISCOUNT_CONDITION_ABOVE_VIP_LEVEL, 5).     %% VIP等级>=
-define(DISCOUNT_CONDITION_BELOW_VIP_LEVEL, 6).     %% VIP等级<=

-define(DISCOUNT_CONDITION_FIVE_ELEMENT_FAILED, 101).     %% 条件参数区间内的五行秘境通关失败
-define(DISCOUNT_CONDITION_FAMILY_ESCORT_FAILED, 102).     %% 道庭护送拦截失败或夺回失败后，且玩家等级>x
-define(DISCOUNT_CONDITION_ENTER_COPY_EXP, 103).     %% 进入青竹院，青竹院门票不足时，且玩家等级>x
-define(DISCOUNT_CONDITION_STRENGTH_COIN_NOT_ENOUGH, 104).     %% 强化金币不足时，且玩家等级>x
-define(DISCOUNT_CONDITION_EQUIP_CONCISE, 105).     %% 洗炼，洗炼丹不足时，且玩家等级>x
-define(DISCOUNT_CONDITION_STONE_HONE, 106).     %% 淬炼材料不足时，且玩家等级>x
-define(DISCOUNT_CONDITION_BUY_DISCOUNT, 107).     %% 已购买特惠礼包x
-define(DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE, 108).     %% 特惠礼包x，已过期Y分钟
-define(DISCOUNT_CONDITION_BUY_CONFINE_CROSSOVER, 109).     %% 点击渡劫渡劫丹不足（已完成任务）


-define(DISCOUNT_CONDITION_LIST, [?DISCOUNT_CONDITION_FIVE_ELEMENT_FAILED, ?DISCOUNT_CONDITION_FAMILY_ESCORT_FAILED, ?DISCOUNT_CONDITION_ENTER_COPY_EXP,
    ?DISCOUNT_CONDITION_STRENGTH_COIN_NOT_ENOUGH, ?DISCOUNT_CONDITION_EQUIP_CONCISE, ?DISCOUNT_CONDITION_STONE_HONE, ?DISCOUNT_CONDITION_BUY_DISCOUNT,
    ?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE, ?DISCOUNT_CONDITION_BUY_CONFINE_CROSSOVER]).


-define(DAILY_GIFT_LIST, [99999]).

-record(c_discount_pay, {
    id,                 %% ID
    days,               %% 天数
    date,               %% 日期
    week_day,           %% 每周开启
    product_id,         %% 商品ID
    cd_time,            %% 出现CD
    condition_type,     %% 开启条件1
    condition_args,     %% 条件参数1
    condition_type2,     %% 开启条件2
    condition_args2,     %% 条件参数2
    condition_type3,     %% 开启条件3
    condition_args3,     %% 条件参数3
    reward,             %% 奖励配置
    old_price,          %% 原价
    now_price,          %% 现价
    limit_num,          %% 限购次数
    limit_time,         %% 限购时间
    package_name        %% 礼包名称
}).

-record(c_daily_buy, {
    id,                 %% ID
    days,               %% 天数
    date,               %% 日期
    condition_type,     %% 限购条件
    condition_args,     %% 条件参数
    reward,             %% 奖励配置
    asset_type,         %% 货币类型
    old_asset_value,    %% 原价
    asset_value,        %% 现价
    discount,           %% 折扣
    limit_time          %% 限购时间(Min)
}).
-endif.
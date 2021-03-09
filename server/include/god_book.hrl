%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 七月 2018 16:42
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(GOD_BOOK_HRL).
-define(GOD_BOOK_HRL, god_book_hrl).

-define(GOD_BOOK_TYPE_DEFENCE, 1).      %% 防御天书
-define(GOD_BOOK_TYPE_EQUIP, 2).        %% 装备天书
-define(GOD_BOOK_TYPE_BOSS, 3).         %% Boss天书
-define(GOD_BOOK_TYPE_WARD, 4).         %% 守护天书
-define(GOD_BOOK_TYPE_GROW, 5).         %% 成长天书

-define(GOD_BOOK_CONDITION_DEFENCE, 1).             %% 防御达到xx
-define(GOD_BOOK_CONDITION_EQUIP, 2).               %% 装备
-define(GOD_BOOK_CONDITION_KILL_MONSTER, 3).        %% 击杀世界boss
-define(GOD_BOOK_CONDITION_FIRST_RECHARGE, 4).      %% 首充
-define(GOD_BOOK_CONDITION_MONTH_CARD, 5).          %% 月卡投资
-define(GOD_BOOK_CONDITION_VIP_LEVEL, 6).           %% VIP等级达到XX
-define(GOD_BOOK_CONDITION_DECORATION, 7).          %% 佩戴经验小鬼或天使
-define(GOD_BOOK_CONDITION_INVEST, 8).              %% 参与投资计划
-define(GOD_BOOK_CONDITION_ACTIVATE_FASHION, 10).   %% 激活武器时装
-define(GOD_BOOK_CONDITION_THUNDER_LEFT_ONE, 11).   %% 一阶雷劫套装
-define(GOD_BOOK_CONDITION_THUNDER_LEFT_TWO, 12).   %% 二阶雷劫套装
-define(GOD_BOOK_CONDITION_THUNDER_LEFT_THREE, 13). %% 三阶雷劫套装
-define(GOD_BOOK_CONDITION_THUNDER_LEFT_FOUR, 14).  %% 四阶雷劫套装
-define(GOD_BOOK_CONDITION_THUNDER_RIGHT_ONE, 15).  %% 一阶雷霆套装
-define(GOD_BOOK_CONDITION_THUNDER_RIGHT_TWO, 16).  %% 二阶雷霆套装



-record(c_god_book, {
    id,                 %% ID
    name,               %% 名称
    type,               %% 类型
    condition_type,     %% 条件类型
    condition_args,     %% 条件参数
    reward_goods        %% 奖励道具
}).

-record(c_god_book_type, {
    type_id,    %% 类型ID
    skill       %% 增加技能
}).

-endif.

%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 一月 2018 20:03
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(VIP_HRL).
-define(VIP_HRL, vip_hrl).

-define(LOGIN_ADD_EXP, 0).  %% 每日登录不加经验
-define(CONFIG_EXP(ConfigExp), (ConfigExp * 100)).
-define(FRONT_EXP(Exp), (Exp div 100)).

-define(CHANGE_LEVEL, 1).       %% 等级变化
-define(CHANGE_EXP, 2).         %% 经验变化

-define(IS_TRANSFER_FREE(IsFree), (IsFree =:= 1)).  %% 免费传送

%% VIP购买表
-record(c_vip_buy, {
    id,                 %% id
    shop_id,            %% 商城id
    name,               %% 名称
    first_add_exp,      %% 购买后增加的经验值
    add_days,           %% 增加天数
    first_gift_list,    %% 礼包
    gift_list           %% 多次购买礼包
}).

%% VIP等级表
-record(c_vip_level, {
    level,                  %% vip等级
    exp,                    %% 所需经验值
    title,                  %% 称号
    equip_stone_num,        %% 装备可镶嵌宝石
    equip_seal_num,         %% 可额外镶嵌纹印
    sign_multi,             %% 签到奖励倍数
    add_props,              %% 专属buff
    copy_exp_times,         %% 经验副本次数
    copy_silver_times,      %% 金币副本次数
    copy_pet_times,         %% 宠物副本次数
    copy_immortal_times,    %% 仙魂副本
    world_boss_times,       %% 套装材料副本次数
    vip_boss,               %% 个人boss
    monster_exp_add,        %% 杀怪经验加成（百分比）
    pet_exp_add,            %% 宠物经验吞噬加成（百分比）
    is_transfer_free,       %% 小飞鞋
    vip_shop,               %% 专属商品
    market_tax_rate,        %% 交易所税率优惠（万分比）
    gift_list,              %% VIP礼包
    day_gift_list,          %% VIP周礼包
    gift_gold,              %% VIP等级礼包扣除元宝
    add_bless_times,        %% 祈福增加次数
    is_resource_retrieve,   %% 资源找回
    is_boss_first_free,     %% boss首次免费
    is_boss_item_half,      %% 消耗减半
%%    copy_war_spirit,        %% 战灵台副本次数
    copy_forge_soul,        %% 铸魂塔
    ancient_enter_times,    %% 远古遗迹
    first_boss_buy,         %% 世界boss购买次数
    cave_times,             %% 洞天福地挑战次数,
    family_box_num,         %% 道庭仓库数量
    family_quicken,         %% 道庭任务加速次数
    world_boss_merge_times, %% 世界boss合并次数
    copy_exp_merge_times,   %% 经验副本合并次数
    money_tree_times,       %% 摇钱树次数
    illusion_buy_times      %% 五行幻境幻力购买
}).

-endif.


%%%-------------------------------------------------------------------
%%% @author yaolun
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 宝座
%%% @end
%%% Created : 27. 二月 2019 15:30
%%%-------------------------------------------------------------------
-author("yaolun").

-ifndef(THRONE_HRL).
-define(THRONE_HRL, throne_hrl).


%% 宝座基础表
-record(c_throne_base, {
    id,
    name,           %% 宝座名称
    level,          %% 宝座等级
    upgrade_goods,  %% 升级消耗道具ID
    skill_list,     %% 拥有的技能id列表
    open_skill      %% 开放技能id
}).


%% 宝座的等级表
-record(c_throne_level, {
    id,             %% 宝容id
    type,           %% 宝座类型
    level,          %% 宝座等级
    expend_essence, %% 升级消耗精华
    add_hp,         %% 生命
    add_attack,     %% 攻击
    add_defense,    %% 防御
    add_arp,        %% 破甲
    speed           %% 坐骑速度
}).

%% 宝座幻化外观表
-record(c_throne_unreal_guise, {
    id,
    level,          %% 宝座等阶
    star,           %% 宝座星级
    upgrade_goods,  %% 升级道具ID
    expend_goods_num, %% 升级物品消耗
    add_hp,         %% 生命
    add_attack,     %% 攻击
    add_defense,    %% 防御
    add_arp,        %% 破甲
    is_broadcast,   %% 是否广播
    skill_list      %% 拥有技能ID列表
}).

-endif.
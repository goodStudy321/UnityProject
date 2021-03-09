%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 天机印系统
%%% @end
%%% Created : 26. 六月 2019 11:38
%%%-------------------------------------------------------------------
-author("huangxiangrui").
-ifndef(NATURE_HRL).
-define(NATURE_HRL, nature_hrl).

-define(DIS_BOARD, 0).  % 卸下
-define(INLAY, 1).      % 镶嵌
-define(SUBSTITUTE, 2). % 替换

-define(GET_LENGTH, 20).


-define(CENTRALITY, 805301). % 两仪印

-define(NATURE_DRUG, 88). % 天机药使用效果

%% 天机印开孔表
-record(c_nature_hole, {
    id,
    type,           % 类型,阴阳
    place,          % 部位
    open_condition, % 开启条件
    open_prop,      % 开启道具
    intensify_id    % 初始强化id
}).

%% 天机印强化表
-record(c_nature_intensify, {
    intensify_id,       % 初始强化id
    next_id,            % 下一级ID
    place,              % 部位
    level,              % 强化等级
    consume_goods,      % 消耗道具
    num,                % 数量
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp,            %% 破甲
    metal,              %% 金
    wood,               %% 木
    water,              %% 水
    fire,               %% 火
    earth               %% 土
}).

%% 天机印属性表
-record(c_nature_seal, {
    id,
    suit,               % 关联套装
    place,              % 部位
    quality,            % 品质
    star_level,         % 星级
    intensify_num,      % 强化次数
    skill1,             % 技能1
    skill2,             % 技能2
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp,            %% 破甲
    metal,              %% 金
    wood,               %% 木
    water,              %% 水
    fire,               %% 火
    earth               %% 土
}).

%% 天机印套装表
-record(c_nature_suit, {
    id,
    number_units,       % 件数
    quality,            % 品质
    nature,             % 组合天机印ID
    max_suit_id,        % 最大套装ID
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp,            %% 破甲
    hp_rate,            %% 生命加成
    attack_rate,        %% 攻击加成
    metal,              %% 金
    wood,               %% 木
    water,              %% 水
    fire,               %% 火
    earth               %% 土
}).

%% 天机印合成表
-record(c_nature_compose, {
    id,
    name,               %% 名字
    need_num,           %% 需要数量
    need_type_id        %% 合成消耗
}).

-endif.
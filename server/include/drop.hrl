%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 九月 2017 10:07
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(DROP_HRL).
-define(DROP_HRL, drop_hrl).

-define(DROP_LEAVE_TIME, 120). %% 场景掉落120秒后清理


-define(IS_OFFSET_SILVER, 1).             %% 金币填充

-define(DROP_MAX_LEAVE_DIFFERENCE, 100).      %% 掉落最大等级差

-define(DROP_WEIGHT, 1000000).  %% 掉落百万分比

-define(DROP_SINGLE, 1).        %% 单人掉落，集体广播
-define(DROP_WILD_TEAM, 2).     %% 野外组队掉落，集体广播，只一份掉落
-define(DROP_FB_TEAM, 3).       %% 副本组队掉落，单薄，掉落N份
-define(DROP_FAMILY_BOSS, 4).   %% 仙盟BOSS，集体广播，只一份掉落

-define(IS_SILVER_FILL(IsSilverFill), (IsSilverFill =:= 1)). %% 是否用金币填充掉落

-define(GET_DROP_ID_COLOR(ItemID), (ItemID div 1000 rem 10)). %% 获取掉落ID的颜色

%% 道具掉落控制权重
-record(r_item_index, {
    index_id,       %% IndexID
    times = 1,      %% 当前第几次掉落
    drop_list       %% drop_list[#p_kv{id = Times, val = DropTime}]
}).

%%  掉落包drop_bag_list  元素结构 {drop_group_list ,times，probability,is_offset_silver,silver_interval}
%%  掉落组drop_group_list  元素结构    {weight ,list}
%%  list结构  {weight，{Item,Num}}
%%-record(c_drop, {
%%    drop_id,               %% 掉落ID
%%    drop_bag_list = []     %% 掉落包List
%%}).

%%掉落包List 结构  {id,num.weight}    %%总权重1000000
-record(c_drop, {
    drop_id,               %% 掉落ID
    drop_times = 0,        %% 掉落次数
    drop_bag_list = []     %% 掉落包List
}).

-record(c_drop_config, {
    drop_id,               %% 掉落ID
    drop_times = 0,        %% 掉落次数
    drop1,
    drop2,
    drop3,
    drop4,
    drop5,
    drop6
}).


-record(c_drop_equip, {
    drop_id,               %% 掉落ID
    start0,                %% 对应0星实体装备ID
    start1,                %% 1星
    start2,
    start3
}).

-record(c_drop_boss, {
    boss_id,               %% 掉落ID
    special_drop_id,       %% 特殊掉落组
    drop1,                 %% 掉落
    drop2,                 %% 掉落
    drop3,                 %% 掉落
    drop4,                 %% 掉落
    drop5,                 %% 掉落
    drop6,                 %% 掉落
    drop7,                 %% 掉落
    drop8,                 %% 掉落
    drop9,                 %% 掉落
    drop10,                %% 掉落
    drop11,                %% 掉落
    drop12,                %% 掉落
    drop13,                %% 掉落
    drop14,                %% 掉落
    drop15,                %% 掉落
    drop16,                %% 掉落
    drop17,                %% 掉落
    drop18,                %% 掉落
    drop19,                %% 掉落
    drop20,                %% 掉落
    drop21,                %% 掉落
    drop22,                %% 掉落
    drop23,                %% 掉落
    drop24,                %% 掉落
    drop25,                %% 掉落
    drop26,                %% 掉落
    drop27,                %% 掉落
    drop28,                %% 掉落
    drop29,                %% 掉落
    drop30,                %% 掉落
    drop31,                %% 掉落
    drop32,                %% 掉落
    drop33,                %% 掉落
    drop34,                %% 掉落
    drop35,                  %% 掉落
    drop36,                  %% 掉落
    drop37,                  %% 掉落
    drop38,                  %% 掉落
    drop39,                  %% 掉落
    drop40                  %% 掉落
}).

-record(c_special_drop, {
    index,          %% 序号
    drop_group,     %% 特殊掉落组ID
    min_times,      %% 次数下限
    max_times,      %% 次数上限
    times,          %% 掉落次数
    drop_id_list    %% 掉落组
}).

-record(c_equip_start_create, {
    color,                 %% 颜色
    list
}).

-record(c_equip_start_create_i, {
    color,                 %% 颜色
    start0,
    start1,
    start2,
    start3
}).

-record(c_drop_bag, {
    id,
    drop_bag_id,           %% 掉落包ID
    drop_group_list,       %% 掉落组
    times,                 %% 抽取次数
    probability,           %% 掉落概率
    is_offset_silver,      %% 补偿金币
    silver_interval        %% 金币区间
}).

-record(c_drop_group, {
    id,
    drop_group_id,          %% 掉落包ID
    item,                   %% 道具
    weight,                 %% 权重
    num,                    %% 数量
    bind                    %% 绑定
}).

%% 道具掉落控制原始结构
-record(c_drop_item_excel, {
    index_id,
    all_num,
    all_refresh_hours,
    personal_num,
    personal_refresh_hours,
    drop_list
}).

%% 转换后的掉落数据
-record(c_drop_item, {
    index_id,               %% 唯一ID
    all_num,                %% 全服掉落数量
    all_refresh_hours,      %% 刷新时间
    personal_num,           %% 个人掉落数量
    personal_refresh_hours  %% 个人掉落刷新时间
}).

-record(drop_args, {
    drop_id_list,       %% 掉落物IDList
    monster_type_id,    %% 怪物type_id
    center_pos,         %% 掉落位置
    drop_role_id,       %% 掉落者相关
    owner_roles = [],   %% 掉落物拥有者
    broadcast_roles = []  %% 广播
}).

-record(c_family_boss_drop, {
    id,                       %% id
    monster_type_id,          %% 怪物id
    start,                    %% 星级
    drop1,                    %% 掉落1
    drop2,                    %% 掉落2
    drop3,                    %% 掉落3
    drop4                     %% 掉落4
}).


-record(c_family_boss_start, {
    start,                    %% id
    region                    %% 区域
}).

-endif.
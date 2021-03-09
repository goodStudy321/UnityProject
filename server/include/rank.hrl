%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十一月 2017 10:56
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(RANK_HRL).
-define(RANK_HRL, rank_hrl).

-define(RANK_ROLE_POWER, 10001).            %% 战力排行
-define(RANK_ROLE_LEVEL, 10002).            %% 等级排行
-define(RANK_MOUNT_POWER, 10003).           %% 坐骑战力排行
-define(RANK_MAGIC_WEAPON_POWER, 10004).    %% 法宝战力排行
-define(RANK_PET_POWER, 10005).             %% 宠物战力排行
-define(RANK_GOD_WEAPON_POWER, 10006).      %% 神兵战力排行
-define(RANK_WING_POWER, 10007).            %% 翅膀战力排行
-define(RANK_OFFLINE_EFFICIENCY, 10008).    %% 离线挂机排行
-define(RANK_COPY_TOWER, 10009).            %% 通关层数排行
-define(RANK_COPY_FIVE_ELEMENTS, 10010).    %% 五行秘境排行
-define(RANK_HANDBOOK_POWER_I, 10012).      %% 开服二阶图鉴战力排行
-define(RANK_MAGIC_WEAPON_POWER_I, 10013).  %% 开服二阶法宝战力排行
-define(RANK_WING_POWER_I, 10014).          %% 开服二阶翅膀战力排行

-define(KEY_ROLE_LEVEL, 101).           %% 角色等级
-define(KEY_POWER, 102).                %% 战力
-define(KEY_MOUNT_ID, 103).             %% 坐骑ID
-define(KEY_PET_ID, 104).               %% 宠物ID
-define(KEY_GOD_WEAPON_ID, 105).        %% 神兵ID
-define(KEY_GOD_WEAPON_LEVEL, 106).     %% 神兵等级
-define(KEY_MAGIC_WEAPON_LEVEL, 108).   %% 法宝等级
-define(KEY_WING_ID, 109).              %% 翅膀ID
-define(KEY_WING_LEVEL, 110).           %% 翅膀等级
-define(KEY_TOWER, 111).                %% 诛仙塔通关层数
-define(KEY_EXP_EFFICIENCY, 112).       %% 离线效率
-define(KEY_HANDBOOK_POWER, 113).       %% 图鉴战力
-define(KEY_MAGIC_WEAPON_POWER, 114).   %% 法宝战力
-define(KEY_WING_POWER, 115).           %% 翅膀战力
-define(KEY_FIVE_ELEMENTS, 116).        %% 五行秘境

-define(KEY_FAMILY_NAME, 201).          %% 仙盟名字


%% 排行榜列表
-define(RANK_LIST, [
    #c_rank_config{rank_id = ?RANK_ROLE_POWER, mod = rank_role_power, show_num = 100, max_num = 200},
    #c_rank_config{rank_id = ?RANK_ROLE_LEVEL, mod = rank_role_level, show_num = 100, max_num = 200},
    #c_rank_config{rank_id = ?RANK_MOUNT_POWER, mod = rank_mount_power},
    #c_rank_config{rank_id = ?RANK_MAGIC_WEAPON_POWER, mod = rank_magic_weapon_power},
    #c_rank_config{rank_id = ?RANK_PET_POWER, mod = rank_pet_power},
    #c_rank_config{rank_id = ?RANK_GOD_WEAPON_POWER, mod = rank_god_weapon_power},
    #c_rank_config{rank_id = ?RANK_WING_POWER, mod = rank_wing_power},
    #c_rank_config{rank_id = ?RANK_COPY_TOWER, mod = rank_copy_tower},
    #c_rank_config{rank_id = ?RANK_COPY_FIVE_ELEMENTS, mod = rank_copy_five_elements},
    #c_rank_config{rank_id = ?RANK_OFFLINE_EFFICIENCY, mod = rank_offline_efficiency},
    #c_rank_config{rank_id = ?RANK_HANDBOOK_POWER_I, mod = rank_handbook_power_i , show_num = 100, max_num = 100},
    #c_rank_config{rank_id = ?RANK_MAGIC_WEAPON_POWER_I, mod = rank_magic_weapon_power_i , show_num = 100, max_num = 100},
    #c_rank_config{rank_id = ?RANK_WING_POWER_I, mod = rank_wing_power_i , show_num = 100, max_num = 100}
]).

%% 战力
-record(r_rank_role_power, {
    role_id,        %% role_id key
    rank,           %% 排名
    power,          %% 战力
    update_time     %% 更新时间
}).

%% 等级
-record(r_rank_role_level, {
    role_id,        %% role_id key
    rank,           %% 排名
    level,          %% 等级
    update_time     %% 更新时间
}).

%% 坐骑战力
-record(r_rank_mount_power, {
    role_id,        %% role_id key
    rank,           %% 排名
    mount_id,       %% 坐骑等阶
    mount_power,    %% 坐骑战力
    update_time     %% 更新时间
}).

%% 坐骑战力
-record(r_rank_pet_power, {
    role_id,        %% role_id key
    rank,           %% 排名
    pet_id,         %% 宠物id
    pet_power,      %% 宠物战力
    update_time     %% 更新时间
}).

%% 神兵战力
-record(r_rank_god_weapon_power, {
    role_id,            %% role_id key
    rank,               %% 排名
    god_weapon_level,   %% 神兵id
    god_weapon_power,   %% 神兵战力
    update_time         %% 更新时间
}).

%% 法宝等级
-record(r_rank_magic_weapon_power, {
    role_id,            %% role_id key
    rank,               %% 排名
    magic_weapon_level, %% 法宝等级
    magic_weapon_power, %% 法宝战力
    update_time         %% 更新时间
}).


%% 翅膀等级
-record(r_rank_wing_power, {
    role_id,        %% role_id key
    rank,           %% 排名
    wing_level,     %% 翅膀id
    wing_power,     %% 翅膀战力
    update_time     %% 更新时间
}).

%% 法宝等级
-record(r_rank_magic_weapon_power_i, {
    role_id,            %% role_id key
    rank,               %% 排名
    magic_weapon_power, %% 法宝战力
    update_time         %% 更新时间
}).

%% 开服二阶活动所用排行翅膀战力
-record(r_rank_wing_power_i, {
    role_id,        %% role_id key
    rank,           %% 排名
    power,          %% 翅膀战力
    update_time     %% 更新时间
}).

%% 开服二阶活动所用排行图鉴战力
-record(r_rank_handbook_power, {
    role_id,            %% role_id key
    rank,               %% 排名
    power,              %% 战力
    update_time         %% 更新时间
}).

%% 诛仙塔排行
-record(r_rank_copy_tower, {
    role_id,        %% role_id key
    rank,           %% 排名
    tower,          %% 通关层数
    update_time     %% 更新时间
}).

%% 五行秘境排行
-record(r_rank_copy_five_elements, {
    role_id,        %% role_id key
    rank,           %% 排名
    cur_id,         %% 通关层数
    update_time     %% 更新时间
}).

%% 离线效率排行
-record(r_rank_offline_efficiency, {
    role_id,        %% role_id key
    rank,           %% 排名
    exp,            %% 离线效率
    update_time     %% 更新时间
}).

-record(c_rank_config, {
    rank_id,        %% 排行榜ID
    mod,            %% 调用模块
    show_num = 50,  %% 排行榜显示人数，默认是50
    max_num = 50    %% 最大人数，默认是50
}).
-endif.
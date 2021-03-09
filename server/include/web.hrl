%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 三月 2018 15:38
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(WEB_HRL).
-define(WEB_HRL, web_hrl).

-define(WEB_DEFAULT_PORT, 30012).   %% 默认端口
-define(WEB_SUPER_KEY, "web-ranger-super-key").     %% superKey
-define(WEB_AUTH_KEY, "web-auth-key").          %% authKey

-define(RETURN_ERROR, 0).
-define(RETURN_SUCCESS, 1).

-define(BAN_TYPE_IP, 1).        %% 封禁-IP
-define(BAN_TYPE_IMEI, 2).      %% 封禁-IMEI
-define(BAN_TYPE_UID, 3).       %% 封禁-UID

-define(ROLE_INFO_BASIC, <<"基础信息"/utf8>>).
-define(ROLE_INFO_EQUIP, <<"装备"/utf8>>).
-define(ROLE_INFO_MOUNT, <<"坐骑"/utf8>>).
-define(ROLE_INFO_PET, <<"宠物"/utf8>>).
-define(ROLE_INFO_GOD_WEAPON, <<"神兵"/utf8>>).
-define(ROLE_INFO_MAGIC_WEAPON, <<"法宝"/utf8>>).
-define(ROLE_INFO_WING, <<"翅膀"/utf8>>).
-define(ROLE_INFO_RUNE, <<"符文"/utf8>>).

-define(CHAT_TYPE_DEL, 2).  %% 删除id

%% 查询信息返回的接口 每个字段的定义在后面
-record(web_role_info, {
    role_basic,         %% web_role_basic结构
    role_equip_list,    %% [web_equip|...]
    role_mount,
    role_pet,
    role_god_weapon,
    role_magic_weapon,
    role_wing,
    role_rune
}).

%% 基础信息
-record(web_role_basic, {
    name,               %% 名称
    role_id,            %% 玩家ID
    account_name,       %% 账号
    uid,                %% UID
    role_name,          %% 角色名
    role_level,         %% 玩家等级
    sex,                %% 性别
    category,           %% 职业
    power,              %% 战斗力
    today_online_time,  %% 当天在线时长
    total_online_time,  %% 总在线时长
    family_id,          %% 帮派ID
    family_name,        %% 帮派名

    vip_level,          %% vip等级
    expire_time,        %% vip过期时间

    gold,               %% 不绑元宝
    bind_gold,          %% 绑定元宝
    silver,             %% 铜钱
    total_pay_gold,     %% 总充值元宝
    total_pay_fee,      %% 总付费额度

    map_id,             %% 当前地图

    relive_level,       %% 转生等级
    relive_progress,    %% 转生第几阶段

    attack,             %% 攻击
    hp,                 %% 生命
    defence,            %% 防御
    arp,                %% 破甲
    hit_rate,           %% 命中
    miss,               %% 闪避
    double,             %% 暴击
    double_anti,        %% 韧性
    %% 万分比
    hurt_rate,          %% 加伤
    hurt_derate,        %% 免伤
    double_rate,        %% 暴击几率
    double_multi,       %% 暴伤
    miss_rate,          %% 闪避几率
    double_anti_rate ,  %% 暴击抵抗
    armor,              %% 护甲
    skill_hurt,         %% 技能伤害增加
    skill_hurt_anti,    %% 技能伤害减少
    skill_dps,          %% 技能DSP系数
    skill_ehp,          %% 技能EHP系数
    role_hurt_reduce,   %% pvp伤害减免
    boss_hurt_add,      %% Boss伤害加深
    rebound             %% 伤害反弹
}).

-record(web_role_equip, {
    name,
    equip_list
}).

%% 装备
-record(web_equip, {
    equip_id,       %% 装备ID
    refine_level,   %% 强化等级
    mastery,        %% 熟练度
    suit_level,     %% 套装等级
    stone_list,     %% 镶嵌灵石[id:部位, val:灵石ID|....]
    excellent_list  %% 属性[id:属性编码, val:值|....]
}).

%% 坐骑
-record(web_role_mount, {
    name,
    mount_id,       %% 当前进度
    exp,            %% 当前经验
    cur_id,         %% 幻化ID
    skin_list,      %% 坐骑拥有的外观
    pellet_list     %% 丹药列表 [id:属性编码, val:值|....]
}).

%% 宠物
-record(web_role_pet, {
    name,
    pet_id,         %% 当前进度
    cur_id,         %% 幻化ID
    level,          %% 宠物等级
    exp,            %% 当前经验
    step_exp,       %% 进阶经验
    skin_list,      %% 宠物拥有的外观
    pellet_list     %% 丹药列表 [id:属性编码, val:值|....]
}).

%% 神兵
-record(web_role_god_weapon, {
    name,
    cur_id,         %% 幻化ID
    level,          %% 等级
    exp,            %% 经验
    skin_list,      %% 拥有的外观
    pellet_list     %% 丹药列表 [id:属性编码, val:值|....]
}).

%% 法宝
-record(web_role_magic_weapon, {
    name,
    cur_id,         %% 幻化ID
    level,          %% 等级
    exp,            %% 经验
    skin_list,      %% 拥有的外观
    pellet_list     %% 丹药列表 [id:属性编码, val:值|....]
}).

%% 翅膀
-record(web_role_wing, {
    name,
    cur_id,         %% 幻化ID
    level,          %% 等级
    exp,            %% 经验
    skin_list,      %% 拥有的外观
    pellet_list     %% 丹药列表 [id:属性编码, val:值|....]
}).

%% 符文
-record(web_role_rune, {
    name,
    exp,            %% 拥有经验
    piece,          %% 碎片
    essence,        %% 精粹
    load_runes      %% 当前装备的符文 [id:部位, val:符文ID|....]
}).

%% 服务器状态
-record(web_info, {
    is_open,            %% 是否开启状态（true：开启）
    is_create_able,     %% 是否允许注册（true：允许）
    agent_id,           %% agentID
    server_id,          %% 服务器ID
    gateway_port        %% 网关端口
}).

-endif.
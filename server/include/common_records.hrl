%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 四月 2017 9:47
%%%-------------------------------------------------------------------
-ifndef(COMMON_RECORDS_HRL).
-define(COMMON_RECORDS_HRL, common_records_hrl).


%% index > 0时，只扣除index位置的数量; index = 0时遍历背包扣除
%% type ---- first_bind 优先扣除绑定
%% type ---- must_bind 只扣除绑定
%% type ---- must_unbind 只扣除不绑定
-record(r_goods_decrease_info, {id=0, id_bind_type = true, type = first_bind, type_id=0, num=0}).

-record(r_goods_delete_info, {id=0}).

%% template_id 模版ID 参考letter_template.hrl
%% days 默认7天
%% condition GM邮件用到，其余的可忽略#r_gm_condition
%% goods_list [#p_goods{}|...]
%% title_string [String1, String2|....]
%% text_string [String1, String2|....]
-record(r_letter_info, {
    template_id=0,
    days = 7,
    condition,
    action=0,
    goods_list=[],
    title_string=[],
    text_string=[]
}).

-record(r_role_online, {
    role_id,
    role_name,
    account_name,
    sex,
    category,
    level,
    channel_id,
    game_channel_id
}).

%% world_data:set_survey_list([#r_survey{survey_id=1,game_channel_id_list=[], questions="喜欢《逍遥九歌行》这个游戏吗？__喜欢++非常喜欢++赛高||你是人生赢家吗？__是++当然++废话",rewards=[#p_kv{id=20000,val=1},#p_kv{id=31008,val=20}]}]).
%% survey_id                -- 问卷ID
%% game_channel_id_list     -- 包渠道IDList
%% min_level                -- 最小等级
%% questions                -- 问题string
%% rewards                  -- 奖励 [#p_kv{}|...]
-record(r_survey, {survey_id=0, game_channel_id_list=[], min_level=0, questions="", rewards=[]}).

%% title            -- 敏感词内容
%% ban_time         -- 禁止时间
-record(r_ban_word, {ban_word, ban_time}).

-record(r_pay_args, {order_id, pf_order_id, role_id, product_id, total_fee}).

-record(r_born_args, {
    map_id,
    camp_id,
    sex
}).

%% 拾取条件
-record(r_pick_condition, {
    is_mythical_equip_full = false,
    is_war_spirit_equip_full = false
}).

%% 扶持号record
-record(r_web_support, {
    id,
    uid_list,           %% UID List
    goods_list,         %% [#p_goods{}|....]
    game_channel_id,    %% 包渠道
    text = ""
}).

%% world_data里的绝版豪礼
-record(r_world_trench_ceremony, {
    reward_role_id = 0,
    accrecharge = 0,
    status = 0
}).

-record(c_common_notice, {id, level}).
-record(c_notice_condition, {action_id, desc, notice_id}).

-record(c_global, {id, string, list, int}).

%% 标准配置表
-record(c_dynamic_standard, {
    level,              %% 等级
    power,              %% 标准战力
    dps,                %% 标准人物DPS
    ehp,                %% 标准人物生存力
    base_exp,           %% 标准怪物经验
    copy_exp            %% 标准九幽经验
}).

%% 道具配置
-record(c_item, {
    type_id,        %% 道具ID;
    name,           %% 道具名称
    item_type,      %% 道具类型
    quality,        %% 物品品质
    cover_num = 1,  %% 叠加数量
    can_use,        %% 能否使用
    use_level,      %% 使用等级
    relive_level,   %% 转生等级
    need_confine,   %% 达到境界
    category,       %% 职业限制
    need_vip,       %% vip 限制
    common_cd,      %% 冷却公共CD
    cd,             %% 冷却CD
    can_drop,       %% 能否丢弃
    auction_sub_class,  %% 拍卖行二级分类
    auction_gold,   %% 起拍价
    auction_buyout, %% 一口价
%%    market_time,    %% 可上架时效期
    protect_time,    %% 购买后上架限制
    shelf_time,     %% 上架时效
    effect_type,    %% 使用效果
    effect_args,    %% 效果参数
    condition_type, %% 使用条件
    condition_args, %% 条件参数
    sell_silver,    %% 出售价格
    effective_time, %% 有效时长
    quick_buy_gold, %% 快速购买价格
    is_notice,      %% 是否公告
    world_boss_drop, %% 是否记录世界boss掉落
    donate_contribution,    %% 捐献贡献值
    exchange_contribution   %% 兑换贡献值
}).

-endif.
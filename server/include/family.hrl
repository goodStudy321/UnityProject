%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十月 2017 17:37
%%%-------------------------------------------------------------------
-author("laijichang").

-ifndef(FAMILY_HRL).
-define(FAMILY_HRL, family_hrl).

-define(ETS_FAMILY_BRIEFS, ets_family_briefs).

-define(HAS_FAMILY(FamilyID), (FamilyID > 0)).

-define(CREATE_FAMILY_GLOBAL, 37).   %% 创建帮派全局配置
-define(FAMILY_DAY_REWARD_GLOBAL, 50).   %% 创建帮派全局配置

-define(TITLE_POPULAR, 5).      %% 人气甜心
-define(TITLE_OWNER, 4).        %% 帮主
-define(TITLE_VICE_OWNER, 3).   %% 副帮主
-define(TITLE_ELDER, 2).        %% 长老
-define(TITLE_MEMBER, 1).       %% 成员

-define(MAX_POPULAR_NUM, 1).    %% 人气甜心的最大数量
-define(MAX_VICE_OWNER_NUM, 3). %% 副帮主最大数量
-define(MAX_ELDER_NUM, 6).      %% 长老最大数量

-define(INVITE_REPLY_ACCEPT, 1).    %% 同意加入帮派
-define(INVITE_REPLY_REFUSE, 2).    %% 拒绝加入帮派

-define(APPLY_REPLY_ACCEPT, 1).     %% 同意加入帮派
-define(APPLY_REPLY_REFUSE, 2).     %% 拒绝加入帮派

-define(ROLE_MAX_APPLY_NUM, 10).    %% 玩家最多同时申请10个
-define(FAMILY_MAX_APPLY_NUM, 50).  %% 帮派最大申请列表

-define(CONFIG_IS_DIRECT, 1).       %% 帮派是否可以直接进入
-define(CONFIG_LIMIT_LEVEL, 2).     %% 申请战力
-define(CONFIG_LIMIT_POWER, 3).     %% 申请战力

-define(CONFIG_NOTICE, 101).        %% 公告
-define(CONFIG_FAMILY_NAME, 102).   %% 名字修改

-define(FAMILY_UPDATE_RANK, 1).     %% 排名
-define(FAMILY_UPDATE_LEVEL, 2).    %% 等级
-define(FAMILY_UPDATE_MONEY, 3).    %% 资金

-define(FAMILY_UPDATE_ROLE_CON, 11).%% 角色贡献更新

-define(GET_FAMILY_SKILL_ID(SkillID), (SkillID div 1000)).
-define(GET_FAMILY_SKILL_LV(SkillID), (SkillID rem 1000)).

-define(MAX_DEPOT_NUM, 200).                %% 仓库最大数量
-define(DEPOT_FIRST_GRID, 700003).           %% 仓库第一格物品ID
-define(FAMILY_DEPOT_DONATE, 1).            %% 仓库捐献
-define(FAMILY_DEPOT_EXCHANGE, 0).          %% 仓库兑换
-define(MAX_DEPOT_LOG_NUM, 50).             %% 仓库最大日志数
-define(DEPOT_FIRST_GRID_GLOBAL, 13).       %% 仓库第一格物品全局表ID

-define(FAMILY_BOSS_MAX_TIMES, 5).                  %% 仙盟BOSS一周最大开启次数
-define(FAMILY_BOSS_GLOBAL, 24).                    %% 仙盟BOSS开启所需兽粮 【需要兽粮，仙盟BOSS一周最大开启次数】
-define(FAMILY_BOSS_GRAIN_ID,32000).                %% 兽粮道具

-define(FAMILY_RED_PACKET_MIN_RATE, 0.5).          %% 仙盟红包最小倍率
-define(FAMILY_RED_PACKET_MAX_RATE, 1.5).          %% 仙盟红包最大倍率
-define(FAMILY_RED_PACKET_EXIST, 1).               %% 红包尚且存在
-define(FAMILY_RED_PACKET_MIX_NUM, 1).             %% 红包最小数量
%%-define(IF_PAY_FOR_RED_PACKET(PacketID), (PacketID =:= 0)).   %%是否从自己资产中发红包
-define(HAS_FAMILY_RED_PACKET_ID(ID), (ID =/= 0)).            %%红包是否从自己
-define(FAMILY_RED_PACKET_DAY_TIMES, 10).                     %%红包每日数量
-define(FAMILY_RED_PACKET_SENT, 1).                           %%仙盟已发
-define(FAMILY_RED_PACKET_NOT_SENT, 2).                       %%自我未发红包
-define(FAMILY_RED_PACKET_OPEN_LEVEL, 44).                    %%红包等级

-define(FAMILY_ACT_HUNT_BOSS_SCORE,0).                        %% 仙盟在猎杀BOSS活动中的分数
-define(FAMILY_ACT_HUNT_BOSS_SCORE_REWARD_STATUS,0).          %% 仙盟在猎杀BOSS活动以后是否领取了奖励

-define(FAMILY_LEAVE_STATUS_1, 1).  % 后台解散仙盟
-define(FAMILY_LEAVE_STATUS_2, 2).  % 帮主离开
-define(FAMILY_LEAVE_STATUS_3, 3).  % 自己离去
-define(FAMILY_LEAVE_STATUS_4, 4).  % 开除

%% 帮派升级配置
-record(c_family_level, {
    level,          %% 等级
    use_money,      %% 升级帮派资金
    max_num,        %% 最大帮派人数
    guild_max_num   %% 公会最大帮派人数
}).

-record(c_family_skill, {
    id,             %% 唯一ID
    name,           %% 名字
    prop_id,        %% 属性编码
    prop_value,     %% 属性值
    use_con         %% 消耗贡献
}).


-record(c_box, {
    id,             %% 唯一ID
    level_region,   %% 等级区域
    type,           %% 任务类型
    value,          %% 任务参数
    box_list        %% 宝箱概率
}).

-record(c_box_notice, {
    id,             %% 唯一ID
    name,
    num          %%
}).

-record(c_family_name, {
    id,             %% 唯一ID
    name,
    last_name          %%
}).
-endif.

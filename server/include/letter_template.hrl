%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 七月 2017 14:44
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(LETTER_TEMPLATE_HRL).
-define(LETTER_TEMPLATE_HRL, letter_template_hrl).

%% 采用~str(字符串) ~num(数字)
%% 内容直接写在后面 格式 %%Title##Text
-define(LETTER_TEMPLATE_COMMON, 0).             %%~str##~str
-define(LETTER_TEMPLATE_TOWER_REWARD, 2).       %%
-define(LETTER_TEMPLATE_MARKET_BUY, 3).         %% 拍卖行购买成功
-define(LETTER_TEMPLATE_ADDICT, 4).             %% 实名认证奖励
-define(LETTER_PAY_GOLD, 5).                    %% 充值成功提示
-define(LETTER_PAY_PACKAGE, 6).                 %% 礼包赠送提示
-define(LETTER_DAY_RECHARGE, 7).                %% 每日充值
-define(LETTER_ANSWER, 8).                      %% 修仙答题奖励
-define(LETTER_BAG_FULL, 9).                    %% 背包满提示
-define(LETTER_FAMILY_ANSWER, 10).              %% 仙盟晚宴答题奖励
-define(LETTER_FAMILY_BT_ROUND, 11).            %% 仙盟战单场
-define(LETTER_FAMILY_BT_RANK, 12).             %% 仙盟战单人积分排名
-define(LETTER_FAMILY_BT_END_CV, 13).           %% 仙盟战终结连胜
-define(LETTER_FAMILY_BT_CV, 14).               %% 仙盟战连胜
-define(LETTER_PAY_GOLD2, 15).                  %% 充值成功提示(没有赠送元宝)
-define(LETTER_ZERO_PANIC_BUY, 16).             %% 零元抢购
-define(LETTER_ZERO_PANIC_BUY_RETURN, 17).      %% 零元抢购返回
-define(LETTER_FAMILY_BT_TITLE, 18).            %% 仙盟战称号
-define(LETTER_JUNHAI_GIFT, 19).                %% 君海礼包接口发放
-define(LETTER_TEMPLATE_MARKET_SELL, 20).       %% 拍卖行出售成功
-define(LETTER_TEMPLATE_PROPOSE_SUCC, 21).      %% 提亲成功
-define(LETTER_TEMPLATE_PROPOSE_FAILED, 22).    %% 提亲被拒
-define(LETTER_TEMPLATE_PROPOSE_TIMEOUT, 23).   %% 提亲超时
-define(LETTER_TEMPLATE_MARRY_ORDER, 24).       %% 预约成功
-define(LETTER_TEMPLATE_MARRY_SUCC, 25).        %% 我们结婚啦！
-define(LETTER_TEMPLATE_MARRY_DIVORCE, 26).                                 %% 离婚成功
-define(LETTER_TEMPLATE_MARKET_OVER_TIME, 27).                              %% 拍卖行超时
-define(LETTER_TEMPLATE_LIMITED_TIME_BUY_START, 28).                        %% 新一轮云购开始
-define(LETTER_TEMPLATE_LIMITED_TIME_BUY_START_I, 29).                      %% 上轮**获得大奖   新一轮云购开始
-define(LETTER_TEMPLATE_LIMITED_TIME_BUY_SEND_REWARD, 30).                  %% 云购大奖发送
-define(LETTER_TEMPLATE_MARKET_DEMAND, 31).                                 %% 拍卖行求购成功
-define(LETTER_TEMPLATE_BATTLE_CAMP, 32).       %% 三界战场排名奖励
-define(LETTER_TEMPLATE_MARRY_TREE, 33).        %% 姻缘树种树邮件
-define(LETTER_TEMPLATE_FAMILY_TEMPLATE, 48).   %% 盟主转移
-define(LETTER_TEMPLATE_CROSS_FORE_NOTICE, 49). %% 跨服分配预告
-define(LETTER_TEMPLATE_CROSS_MATCH_NOTICE, 50).%% 跨服分配完成通知
-define(LETTER_TEMPLATE_COPY_TOWER_REWARD, 51). %% 爬塔通关额外奖励
-define(LETTER_TEMPLATE_PAY_BACK, 64).          %% 封测预充值返还
-define(LETTER_TEMPLATE_FAMILY_TITLE_UP, 65).          %% 仙盟职位提升
-define(LETTER_TEMPLATE_FAMILY_TITLE_DOWN, 66).        %% 仙盟职位下降
-define(LETTER_TEMPLATE_HUNT_TREASURE, 67).     %% 藏宝图奖励邮件
-define(LETTER_TEMPLATE_OSS_SEVEN, 68).         %% 七天
-define(LETTER_TEMPLATE_WORLD_BOSS_REWARD, 70). %% 世界BOSS结算奖励邮件
-define(LETTER_TEMPLATE_FAMILY_KICK, 71).       %% 道庭被踢出
-define(LETTER_TEMPLATE_ACT_RANK_OPEN, 73).     %% 开服冲榜开启
-define(LETTER_TEMPLATE_ACT_RANK_END, 72).      %% 开服冲榜结榜
-define(LETTER_TEMPLATE_KING_GUARD, 74).        %% 精灵王
-define(LETTER_TEMPLATE_ESCORT_BE_ROB, 75).        %% 护送被抢
-define(LETTER_TEMPLATE_ESCORT_BE_ROB_BACK, 76).           %% 护送被夺回
-define(LETTER_TEMPLATE_AUCTION_BUY_SUCC, 77).          %% 竞拍购买成功
-define(LETTER_TEMPLATE_AUCTION_BUY_FAILED, 78).        %% 竞拍失败
-define(LETTER_TEMPLATE_AUCTION_SELL_SUCC, 79).         %% 拍品出售成功
-define(LETTER_TEMPLATE_AUCTION_SELL_FAILED, 80).       %% 拍品流拍
-define(LETTER_TEMPLATE_AUCTION_FAMILY_SELL_SUCC, 81).  %% 行会拍品成功
-define(LETTER_TEMPLATE_AUCTION_FAMILY_SELL_FAILED, 82).%% 行会拍品流拍
-define(LETTER_TEMPLATE_TIP_PAY_BACK, 83).              %% 封测返还
-define(LETTER_DEMON_BOSS_HP_REWARD, 98).               %% 魔域boss奖励返还
-define(LETTER_CONSUME_RANK, 99).               %% 后台消费排行
-define(LETTER_MINING_PLUNDER, 100).               %% 迷境掠夺通知
-define(LETTER_MINING_REWARD, 101).               %% 迷境资源补发
-define(LETTER_OSS_FUNCTION, 102).               %% 系统开启奖励
-define(LETTER_CROSS_ESCORT, 103).               %% 跨服开启时补发以前奖励
-define(LETTER_DAY_BOX, 104).               %%每日宝箱
-define(LETTER_TEMPLATE_FAMILY_POPULAR, 105).   %% 人气甜心任命
-define(LETTER_SOLO_SINGLE_SERVER_AWARD, 106).   %% 单服论剑排名奖励
-define(LETTER_SOLO_SPAN_SERVER_AWARD, 107).   %% 跨服论剑排名奖励
-define(LETTER_FIRST_PAY_GAIN, 108).   %% 首冲返元宝
-define(LETTER_FASHION_GIVE, 109).          %% 时装赠送
-define(LETTER_EGG_REWARD, 110).          %% 砸蛋
-define(LETTER_AUCTION_OBTAIN_GAIN, 111). %% 拍卖行下架
-define(LETTER_ACT_TRENCH_CEREMONY, 112). %% 绝版壕礼
-define(LETTER_UNIVERSE_POWER_SET, 113).    %% 太虚通天塔开启奖励
-define(LETTER_ACT_TREASURE_CHEST, 115).    %% 欢乐宝箱奖励发送
-define(LETTER_ACT_ESOTERICA, 116).    %% 修炼秘籍奖励发送
-define(LETTER_CYCLE_ACT_COUPLE_CHARM, 117).    %% 魅力之王排行邮件
-define(LETTER_MARRY_FAIRY_REWARD, 118).    %% 仙侣互赠邮件

-define(LETTER_MERGE_ROLE_RENAME, 120).     %% 合服 - 角色改名
-define(LETTER_MERGE_FAMILY_RENAME, 121).   %% 合服 - 道庭改名
-endif.

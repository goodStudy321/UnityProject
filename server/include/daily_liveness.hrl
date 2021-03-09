%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 四月 2018 20:04
%%%-------------------------------------------------------------------
-author("WZP").
-ifndef(DAILY_LIVENESS_HRL).
-define(DAILY_LIVENESS_HRL, daily_liveness_hrl).



-define(LIVENESS_DAILY_MISSION, 1).
-define(LIVENESS_EXP_COPY, 2).
-define(LIVENESS_EQUIP_COPY, 3).
-define(LIVENESS_PET_COPY, 4).
%%-define(LIVENESS_HAVE_GOT_REWARD, 5).
-define(LIVENESS_WORLD_BOSS, 6).
-define(LIVENESS_STRENGTHEN_EQUIP, 7).
-define(LIVENESS_SILVER_COPY, 8).
-define(LIVENESS_ANSWER, 9).
%%-define(LIVENESS_HAVE_GOT_REWARD, 10).
-define(LIVENESS_FAMILY_ANSWER, 11).
%%-define(LIVENESS_HAVE_GOT_REWARD, 12).
-define(LIVENESS_ROLE_SOLO, 13).                %%巅峰竞技（1v1）
-define(LIVENESS_ACTIVITY_BATTLE, 15).          %%z阵营战（三界战场）
-define(LIVENESS_ESCORT, 16).                    %%抢夺
-define(LIVENESS_FAMILY_MISSION, 18).           %%帮派任务
-define(LIVENESS_FAMILY_TD, 20).                %%守卫仙盟
-define(LIVENESS_WORLD_BOSS2, 21).              %%福地洞天
-define(LIVENESS_OFF_SOLO, 22).                 %%离线竞技场
-define(LIVENESS_FAMILY_BS, 23).                %%仙盟BOSS
-define(LIVENESS_SUMMIT_TOWER, 24).             %%青云之巅
-define(LIVENESS_PERSONAL_BOSS, 26).            %%个人boss
-define(LIVENESS_FAMILY_BT, 27).                %%仙盟战

-define(LIVENESS_BLESS, 30).
-define(LIVENESS_YUANBAO, 31).                     %%300元宝

-define(LIVENESS_FUDI, 32).                            %%福地洞天             击杀
-define(LIVENESS_YOUMING, 33).                         %%幽冥世界             击杀
-define(LIVENESS_SHENGSHOU, 34).                       %%神兽岛             击杀
-define(LIVENESS_YUANGU, 35).                          %%远古遗迹boss             击杀
-define(LIVENESS_YOUHUNLIN, 37).                       %%幽魂林
-define(LIVENESS_WUXING, 38).                          %%五行秘境
-define(LIVENESS_AUCTION_SELL, 39).                    %%上架
-define(LIVENESS_MONEY_TREE, 40).                      %%摇钱树
-define(LIVENESS_MOYU, 41).                            %%魔域



-endif.

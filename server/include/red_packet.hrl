%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 八月 2018 10:49
%%%-------------------------------------------------------------------
-author("WZP").
-author("WZP").




-ifndef(RED_PACKET).
-define(RED_PACKET, red_packet).


-define(RED_PACKET_FAMILY_AS_FIRST, 1).                          %%  仙盟答题第一名    属于帮派
-define(RED_PACKET_FAMILY_AS_SECOND, 2).                         %%  仙盟答题第二名    属于帮派
-define(RED_PACKET_FAMILY_AS_THIRD, 3).                          %%  仙盟答题第三名    属于帮派
-define(RED_PACKET_FAMILY_MONTH_CARD, 4).                        %%  月卡
-define(RED_PACKET_FAMILY_INVEST, 5).                            %%  投资计划
-define(RED_PACKET_FAMILY_VIP_INVEST, 6).                        %%  VIP投资
-define(RED_PACKET_FAMILY_VIP_FOUR, 7).                          %%  VIP4
-define(RED_PACKET_FAMILY_VIP_FIVE, 8).                          %%  VIP5
-define(RED_PACKET_FAMILY_VIP_SIX, 9).                           %%  VIP6
-define(RED_PACKET_FAMILY_VIP_SEVEN, 10).                        %%  VIP7
-define(RED_PACKET_FAMILY_VIP_EIGHT, 11).                        %%  VIP8
-define(RED_PACKET_FAMILY_VIP_NINE, 12).                         %%  VIP9
-define(RED_PACKET_FAMILY_DAY_ACC_RECHARGE_ONE, 13).             %%  每日累充
-define(RED_PACKET_FAMILY_DAY_ACC_RECHARGE_TWO, 14).             %%  每日累充
-define(RED_PACKET_GM, 100).                                     %%  官网
-define(RED_PACKET_HUNT_BOSS_AS_FIRST, 15).                      %%  猎杀Boss仙盟排名第一奖励
-define(RED_PACKET_HUNT_BOSS_AS_SECOND, 16).                     %%  猎杀BOSS仙盟排名第二奖励
-define(RED_PACKET_HUNT_BOSS_AS_THIRD, 17).                      %%  猎杀BOSS仙盟排名第三奖励



%%红包
-record(c_red_packet, {id,param, amount,name}).


-endif.

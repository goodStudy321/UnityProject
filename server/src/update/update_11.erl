%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十二月 2019 14:08
%%%-------------------------------------------------------------------
-module(update_11).
-author("WZP").
-include("db.hrl").
-include("role.hrl").
-include("family.hrl").


%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_addict/1,
    update_family/1,
    update_role_discount_pay/1
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_ROLE_ADDICT_P, update_addict},
        {?DB_FAMILY_P, update_family},
        {?DB_ROLE_DISCOUNT_PAY_P,update_role_discount_pay}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    List = [
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 中央服数据更新
update_center() ->
    List = [
    ],
    update_common:data_update(?MODULE, List),
    ok.

update_addict(RoleAddictList) ->
    [begin
         case RoleAddict of
             {r_role_addict, ROLE_ID, IS_AUTH, IS_PASSED, LAST_REMAIN_MIN, REDUCE_RATE, Age} ->
                 {r_role_addict, ROLE_ID, IS_AUTH, IS_PASSED, LAST_REMAIN_MIN, REDUCE_RATE, Age, false, true, 0, 0,0};
             _ ->
                 RoleAddict
         end
     end || RoleAddict <- RoleAddictList].

update_family(FamilyList) ->
    [begin
         case Family of
             {p_family, FamilyID, FamilyName, Level, Money, IsDirectJoin, LimitLevel, LimitPower, Rank, CvReward, MaxCv, EndCv, Notice, RedPacket, RedPacketLog, PacketId, Members, ApplyList} ->
                 Members2 = update_family_members(Members),
                 Depot = [#p_goods{id = 1, type_id = ?DEPOT_FIRST_GRID}],
                 {p_family, FamilyID, FamilyName, Level, Money, IsDirectJoin, LimitLevel, LimitPower, Rank, CvReward, MaxCv, EndCv, Notice, RedPacket, RedPacketLog, PacketId, Members2, ApplyList, Depot, []};
             _ ->
                 Family
         end
     end || Family <- FamilyList].


update_family_members(Members) ->
    update_family_members(Members, []).

update_family_members([], List) ->
    List;
update_family_members([Member|T], List) ->
    Member2 = case Member of
                  {p_family_member, RoleId, RoleName, RoleLevel, Category, Title, Sex, Salary, Power, IsOnline, Last_offline_time} ->
                      {p_family_member, RoleId, RoleName, RoleLevel, Category, Title, Sex, Salary, 0, Power, IsOnline, Last_offline_time};
                  _ ->
                      Member
              end,
    update_family_members(T, [Member2|List]).

update_role_discount_pay(RoleList) ->
    [begin
         case RoleDiscountPay of
             {r_role_discount_pay, RoleID, CUR_PAY_ID, TODAY_DISCOUNTS, TODAY_DAILY_GIFTS, FINISH_IDS} ->
                 {r_role_discount_pay, RoleID, CUR_PAY_ID, TODAY_DISCOUNTS, TODAY_DAILY_GIFTS, FINISH_IDS, [], []};
             _ ->
                 RoleDiscountPay
         end
     end || RoleDiscountPay <- RoleList].


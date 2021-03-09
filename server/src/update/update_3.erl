%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 三月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_3).
-author("laijichang").
-include("db.hrl").
-include("role.hrl").
-include("all_pb.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_ranks/1,
    update_role_act_sign/1,
    update_role_act_seven/1,
    update_function/1
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_RANK_P, update_ranks},
        {?DB_ROLE_ACT_SIGN_P, update_role_act_sign},
        {?DB_ROLE_SEVEN_DAY_P, update_role_act_seven},
        {?DB_ROLE_FUNCTION_P, update_function}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    ok.

%% 中央服数据更新
update_center() ->
    ok.

update_ranks(RankList) ->
    [begin
         case Rank of
             {r_rank, RankID, RankItemList} ->
                 RankItemList2 = update_ranks2(RankItemList),
                 {r_rank, RankID, RankItemList2};
             _ ->
                 Rank
         end
     end || Rank <- RankList].

update_ranks2(RankItemList) ->
    [begin
         case RankItem of
             {r_rank_mount_power, RoleID, RANK, ID, UPDATE_TIME} ->
                 {r_rank_mount_power, RoleID, RANK, ID, 0, UPDATE_TIME};
             {r_rank_pet_power, RoleID, RANK, ID, UPDATE_TIME} ->
                 {r_rank_pet_power, RoleID, RANK, ID, 0, UPDATE_TIME};
             {r_rank_god_weapon_power, RoleID, RANK, ID, UPDATE_TIME} ->
                 {r_rank_god_weapon_power, RoleID, RANK, ID, 0, UPDATE_TIME};
             {r_rank_magic_weapon_power, RoleID, RANK, ID, UPDATE_TIME} ->
                 {r_rank_magic_weapon_power, RoleID, RANK, ID, 0, UPDATE_TIME};
             {r_rank_wing_power, RoleID, RANK, ID, UPDATE_TIME} ->
                 {r_rank_wing_power, RoleID, RANK, ID, 0, UPDATE_TIME};
             _ ->
                 RankItem
         end
     end || RankItem <- RankItemList].

update_role_act_sign(RoleActSignList) ->
    [begin
         case RoleActSign of
             {r_role_act_sign, ROLE_ID, _IS_SIGN, _IS_REPLENISH_SIGN, _SIGN_LIST, _REPLENISH_SIGN_LIST, _TIMES_REWARD_LIST} ->
                 {r_role_act_sign, ROLE_ID, false, -1, []};
             _ ->
                 RoleActSign
         end
     end || RoleActSign <- RoleActSignList].

update_role_act_seven(List) ->
    [begin
         case RoleInfo of
             {r_role_seven_day, ROLE_ID, InfoList} ->
                 IsBc = not lists:all(fun(Pkv) -> Pkv#p_kv.val =:= ?ACT_REWARD_GOT end, InfoList),
                 {r_role_seven_day, ROLE_ID, InfoList, IsBc};
             _ ->
                 RoleInfo
         end
     end || RoleInfo <- List].


update_function(List)->
    [begin
         case Info of
             {r_role_function, RoleID, FunctionList} ->
                 {r_role_function, RoleID, FunctionList,[]};
             _ ->
                 Info
         end
     end || Info <- List].
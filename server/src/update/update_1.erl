%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2019 0:25
%%%-------------------------------------------------------------------
-module(update_1).
-author("laijichang").
-include("db.hrl").
-include("god_book.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_role_world_boss/1,
    update_world_boss/1,
    update_role_relive/1,
    update_role_act_reward/1,
    update_role_mount/1,
    update_role_map/1,
    update_role_attr/1,
    update_role_act_dayrecharge/1,
    update_role_god_book/1
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {db_world_boss_p, update_world_boss},
        {db_role_world_boss_p, update_role_world_boss},
        {db_role_relive_p, update_role_relive},
        {?DB_ROLE_EXTRA_P, update_role_act_reward},
        {?DB_ROLE_MOUNT_P, update_role_mount},
        {?DB_ROLE_MAP_P, update_role_map},
        {?DB_ROLE_ATTR_P, update_role_attr},
        {?DB_ROLE_ACT_DAYRECHARGE_P, update_role_act_dayrecharge},
        {?DB_ROLE_GOD_BOOK_P, update_role_god_book}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    ok.

%% 中央服数据更新
update_center() ->
    ok.

update_role_world_boss(RoleList) ->
    [begin
         case RoleWorldBoss of
             {r_role_world_boss, ROLE_ID, TIMES, ITEM_ADD_TIMES, QUIT_TIME, CARE_LIST} ->
                 {r_role_world_boss, ROLE_ID, TIMES, ITEM_ADD_TIMES, QUIT_TIME, 0, 0, 0, 0, [], CARE_LIST};
             _ ->
                 RoleWorldBoss
         end
     end || RoleWorldBoss <- RoleList].

update_world_boss(BossList) ->
    [begin
         case WorldBoss of
             {r_world_boss, TYPE_ID, IS_REMIND, IS_ALIVE, NEXT_REFRESH_TIME} ->
                 {r_world_boss, TYPE_ID, IS_REMIND, IS_ALIVE, NEXT_REFRESH_TIME, []};
             _ ->
                 WorldBoss
         end
     end || WorldBoss <- BossList].

update_role_relive(RoleList) ->
    [begin
         case RoleRelive of
             {r_role_relive, ROLE_ID, RELIVE_LEVEL, PROGRESS} ->
                 {r_role_relive, ROLE_ID, RELIVE_LEVEL, PROGRESS, 0, 0};
             _ ->
                 RoleRelive
         end
     end || RoleRelive <- RoleList].

update_role_act_reward(RoleList) ->
    Key = 3,
    [begin
         #r_role_extra{data = List} = RoleExtra,
         List2 =
         case lists:keyfind(Key, 1, List) of
             {Key, Value} ->
                 Value2 = update_role_act_reward2(Value),
                 lists:keystore(Key, 1, List, {Key, Value2});
             _ ->
                 List
         end,
         RoleExtra#r_role_extra{data = List2}
     end || RoleExtra <- RoleList].

update_role_act_reward2(ActRanks) ->
    [begin
         case ActRank of
             {r_act_rank, ROLE_ID, RANK, CONDITION} ->
                 {r_act_rank, ROLE_ID, RANK, CONDITION, []};
             _ ->
                 ActRank
         end
     end || ActRank <- ActRanks].

update_role_mount(RoleList) ->
    [begin
         case RoleMount of
             {r_role_mount, ROLE_ID, EXP, MOUNT_ID, CUR_ID, STATUS, SKIN_LIST, QUALITY_LIST} ->
                 CUR_ID2 = get_mount_normal_id(CUR_ID),
                 {r_role_mount, ROLE_ID, EXP, MOUNT_ID, CUR_ID2, STATUS, SKIN_LIST, QUALITY_LIST, []};
             _ ->
                 RoleMount
         end
     end || RoleMount <- RoleList].

update_role_map(RoleList) ->
    [begin
         case RoleMap of
             {r_role_map, ROLE_ID, HP, SERVER_ID, MAP_ID, EXTRA_ID, MAP_PNAME, POS, OLD_SERVER_ID, OLD_MAP_ID,
              OLD_MAP_PNAME, OLD_POS, CAMP_ID, PK_MODE, PK_VALUE, VALUE_TIME, DEAD_TIME, RELIVE_LIST, ENTER_LIST, LOCK} ->
                 {r_role_map, ROLE_ID, HP, SERVER_ID, MAP_ID, EXTRA_ID, MAP_PNAME, POS, OLD_SERVER_ID, OLD_MAP_ID, 1,
                  OLD_MAP_PNAME, OLD_POS, CAMP_ID, PK_MODE, PK_VALUE, VALUE_TIME, DEAD_TIME, RELIVE_LIST, ENTER_LIST, LOCK};
             _ ->
                 RoleMap
         end
     end || RoleMap <- RoleList].

update_role_attr(RoleList) ->
    [begin
         case RoleAttr of
             {r_role_attr, ROLE_ID, ROLE_NAME, ACCOUNT_NAME, UID, SEX, LEVEL, EXP, TEAM_ID, CATEGORY, FAMILY_ID, FAMILY_NAME,
              SERVER_ID, CHANNEL_ID, GAME_CHANNEL_ID, SKIN_LIST, POWER, MAX_POWER, LAST_OFFLINE_TIME} ->
                 {r_role_attr, ROLE_ID, ROLE_NAME, ACCOUNT_NAME, UID, SEX, LEVEL, EXP, TEAM_ID, CATEGORY, FAMILY_ID, FAMILY_NAME,
                  SERVER_ID, CHANNEL_ID, GAME_CHANNEL_ID, SKIN_LIST, POWER, MAX_POWER, LAST_OFFLINE_TIME, []};
             _ ->
                 RoleAttr
         end
     end || RoleAttr <- RoleList].

update_role_act_dayrecharge(RoleList) ->
    [begin
         case RoleActDayrecharge of
             {r_role_act_dayrecharge, ROLE_ID, Recharge, DayReward, CountReward, HaveCount} ->
                 {r_role_act_dayrecharge, ROLE_ID, Recharge, DayReward, CountReward, HaveCount, 0};
             _ ->
                 RoleActDayrecharge
         end
     end || RoleActDayrecharge <- RoleList].

update_role_god_book(RoleList) ->
    [begin
         case RoleGodBook of
             {r_role_god_book, ROLE_ID, DoingList, RewardList, TypeRewardList} ->
                 DoingList2 = modify_god_book_doings(DoingList, RewardList, []),
                 {r_role_god_book, ROLE_ID, DoingList2, RewardList, TypeRewardList};
             _ ->
                 RoleGodBook
         end
     end || RoleGodBook <- RoleList].

-record(p_kvl,{id=0,list=[]}).
modify_god_book_doings([], _RewardList, Acc) ->
    Acc;
modify_god_book_doings([#p_kvl{id = ID, list = DoingArgs} = Doing|R], RewardList, Acc) ->
    case catch lib_config:find(cfg_god_book, ID) of
        [#c_god_book{condition_args = ConditionArgs}] ->
            case lists:member(ID, RewardList) of
                true ->
                    modify_god_book_doings(R, RewardList, [Doing#p_kvl{list = ConditionArgs}|Acc]);
                _ ->
                    DoingArgs2 = DoingArgs -- ConditionArgs,
                    modify_god_book_doings(R, RewardList, [Doing#p_kvl{list = DoingArgs2}|Acc])
            end;
        _ ->
            modify_god_book_doings(R, RewardList, [Doing|Acc])
    end.

get_mount_normal_id(0) ->
    0;
get_mount_normal_id(CurID) when CurID > 10000 andalso CurID < 90000 ->
    CurID * 100 + 1;
get_mount_normal_id(CurID) ->
    CurID.

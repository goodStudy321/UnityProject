%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     脚本
%%% @end
%%% Created : 12. 四月 2018 17:46
%%%-------------------------------------------------------------------
-module(common_shell).
-author("laijichang").
-include("role.hrl").
-include("rank.hrl").
-include("global.hrl").
-include("family_td.hrl").
-include("mission.hrl").
-include("platform.hrl").
-include("letter.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_equip.hrl").
-include("proto/mod_role_rune.hrl").
-include("proto/mod_role_immortal_soul.hrl").
-include("proto/mod_role_confine.hrl").
-include("proto/mod_role_skill.hrl").
-include("proto/mod_role_mythical_equip.hrl").
-include("proto/gateway.hrl").
-include("proto/mod_role_relive.hrl").
-include("proto/mod_role_bag.hrl").
-include("bg_act.hrl").
-include("role_extra.hrl").
-include("cycle_act.hrl").
-include("offline_solo.hrl").


%% API
-export([
    create_banshu_goods/0,
    create_banshu_goods/1,
    send_pingce_goods/2,
    modify_stones/0,
    modify_role_attr/0,
    modify_role_skill/0,
    modify_p_family_member/0

]).

-export([
    modify_ios_data/0,
    modify_ios_account/0,
    modify_local_account/0,
    modify_local_account/1,
    modify_data/0,
    modify_mythical_equip/0,
    modify_equip_concise/0,
    modify_reset_data/0,
    modify_ios_v7/0,
    update_role_act_dayrecharge/0,
    update_family_box/0,
    update_confine_mission/0,
    update_confine_status/0,
    update_confine_status/1,
    stat_red_packet_num/0
]).

-export([
    stat_pay_info/0,
    stat_talent_list/0,
    modify_talent/0,
    modify_talent2/1,
    update_role_pay/1,
    stat_vip_titles/0,
    modify_vip_titles/0,
    modify_recharge/1,
    update_bless_data/0,
    update_bless_data/1,
    init_family_td_new_ets/0,
    act_accrecharge_repair/0,
    act_accrecharge_repair/1,
    open_first_recharge_table/0,
    cycle_data_change/0,
    modify_solo_buy_times/0
]).

create_banshu_goods() ->
    %% {10059,1},{10559,1},{11059,1},{11559,1},{12059,1},{12559,1},{13059,1},{13559,1},{14059,1},{14559,1},
    GoodsList = [{10046, 5}, {10056, 5}, {10066, 5}, {10076, 5}, {10086, 5}, {10096, 5}, {10106, 5}, {20001, 299}, {20002, 299}, {20003, 299}, {20004, 299}, {20013, 299}, {20014, 299}, {20015, 299}, {20016, 299}, {20031, 299}, {20032, 299}, {20033, 299}, {20034, 299}, {20061, 299}, {20062, 299}, {20063, 299}, {20101, 299}, {20102, 299}, {20103, 299}, {20104, 299}, {20201, 299}, {20202, 299}, {20203, 299}, {20204, 299}, {20205, 299}, {20206, 299}, {20207, 299}, {20208, 299}, {20209, 299}, {20210, 299}, {20211, 299}, {20212, 299}, {20213, 299}, {20214, 299}, {20215, 299}, {20216, 299}, {20217, 299}, {20218, 299}, {20219, 299}, {20220, 299}, {30009, 10}, {30019, 10}],
    GoodsList2 = [#p_goods{type_id = TypeID, num = ItemNum} || {TypeID, ItemNum} <- GoodsList],
    [begin
         AccountName = lib_tool:to_binary(lib_tool:concat(["test", Num])),
         case db:lookup(?DB_ACCOUNT_ROLE_P, AccountName) of
             [#r_account_role{role_id_list = [RoleID|_]}] ->
                 role_misc:give_goods(RoleID, ?ITEM_GAIN_GM, GoodsList2),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_function, gm_trigger_function, []}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_level, gm_set_level, [180]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_copy, gm_set_copy_tower, [40008]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_essence, [10000000]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_piece, [10000000]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_exp, [100000000]}]}),
                 AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_GM, 100000, 100000}, {add_silver, ?ASSET_SILVER_ADD_FROM_GM, 10000000}, {add_score, ?ASSET_GLORY_ADD_FROM_ITEM, ?CONSUME_GLORY, 1000000}],
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_asset, do, [AssetDoing]}]});
             _ ->
                 ignore
         end
     end || Num <- lists:seq(11, 13)],

    %% {10059,1},{10559,1},{11059,1},{11559,1},{12059,1},{12559,1},{13059,1},{13559,1},{14059,1},{14559,1},
    GoodsList3 = [{10046, 5}, {10056, 5}, {10066, 5}, {10076, 5}, {10086, 5}, {10096, 5}, {10106, 5}, {20001, 299}, {20002, 299}, {20003, 299}, {20004, 299}, {20013, 299}, {20014, 299}, {20015, 299}, {20016, 299}, {20031, 299}, {20032, 299}, {20033, 299}, {20034, 299}, {20061, 299}, {20062, 299}, {20063, 299}, {20101, 299}, {20102, 299}, {20103, 299}, {20104, 299}, {20201, 299}, {20202, 299}, {20203, 299}, {20204, 299}, {20205, 299}, {20206, 299}, {20207, 299}, {20208, 299}, {20209, 299}, {20210, 299}, {20211, 299}, {20212, 299}, {20213, 299}, {20214, 299}, {20215, 299}, {20216, 299}, {20217, 299}, {20218, 299}, {20219, 299}, {20220, 299}, {30009, 10}, {30019, 10}],
    GoodsList4 = [#p_goods{type_id = TypeID, num = ItemNum} || {TypeID, ItemNum} <- GoodsList3],
    [begin
         AccountName = lib_tool:to_binary(lib_tool:concat(["test", Num])),
         case db:lookup(?DB_ACCOUNT_ROLE_P, AccountName) of
             [#r_account_role{role_id_list = [RoleID|_]}] ->
                 role_misc:give_goods(RoleID, ?ITEM_GAIN_GM, GoodsList4),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_function, gm_trigger_function, []}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_level, gm_set_level, [300]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_copy, gm_set_copy_tower, [40008]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_essence, [10000000]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_piece, [10000000]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_exp, [100000000]}]}),
                 AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_GM, 100000, 100000}, {add_silver, ?ASSET_SILVER_ADD_FROM_GM, 10000000}, {add_score, ?ASSET_GLORY_ADD_FROM_ITEM, ?CONSUME_GLORY, 1000000}],
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_asset, do, [AssetDoing]}]});
             _ ->
                 ignore
         end
     end || Num <- lists:seq(21, 23)].

create_banshu_goods(AccountList) ->
    GoodsList = [{10046, 5}, {10056, 5}, {10066, 5}, {10076, 5}, {10086, 5}, {10096, 5}, {10106, 5}, {20001, 299}, {20002, 299}, {20003, 299}, {20004, 299}, {20013, 299}, {20014, 299}, {20015, 299}, {20016, 299}, {20031, 299}, {20032, 299}, {20033, 299}, {20034, 299}, {20061, 299}, {20062, 299}, {20063, 299}, {20101, 299}, {20102, 299}, {20103, 299}, {20104, 299}, {20201, 299}, {20202, 299}, {20203, 299}, {20204, 299}, {20205, 299}, {20206, 299}, {20207, 299}, {20208, 299}, {20209, 299}, {20210, 299}, {20211, 299}, {20212, 299}, {20213, 299}, {20214, 299}, {20215, 299}, {20216, 299}, {20217, 299}, {20218, 299}, {20219, 299}, {20220, 299}, {30009, 10}, {30019, 10}],
    GoodsList2 = [#p_goods{type_id = TypeID, num = ItemNum} || {TypeID, ItemNum} <- GoodsList],
    [begin
         case db:lookup(?DB_ACCOUNT_ROLE_P, AccountName) of
             [#r_account_role{role_id_list = [RoleID|_]}] ->
                 role_misc:give_goods(RoleID, ?ITEM_GAIN_GM, GoodsList2),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_function, gm_trigger_function, []}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_level, gm_set_level, [180]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_copy, gm_set_copy_tower, [40008]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_essence, [10000000]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_piece, [10000000]}]}),
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_rune, add_exp, [100000000]}]}),
                 AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_GM, 100000, 100000}, {add_silver, ?ASSET_SILVER_ADD_FROM_GM, 10000000}, {add_score, ?ASSET_GLORY_ADD_FROM_ITEM, ?CONSUME_GLORY, 1000000}],
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_asset, do, [AssetDoing]}]});
             _ ->
                 ignore
         end
     end || AccountName <- AccountList].

send_pingce_goods(RoleID, Degree) when erlang:is_integer(RoleID) ->
    send_pingce_goods([RoleID], Degree);
send_pingce_goods(RoleList, Degree) ->
    if
        Degree =:= 1 -> %% 低级
            Level = 1,
            Goods2 = [];
        Degree =:= 2 ->
            Level = 180,
            Goods2 = [{1, 10000000}, {2, 10000}, {3, 10000}, {70050, 1}, {70550, 1}, {71050, 1}, {71550, 1}, {72050, 1}, {72550, 1},
                      {23050, 1}, {23550, 1}, {24070, 1}, {24570, 1}, {30004, 10}, {30014, 10}, {30301, 99}, {30302, 99}, {30303, 99}, {30304, 99},
                      {30321, 99}, {30322, 99}, {30323, 99}, {30324, 99}, {30325, 99}, {30326, 99}, {30331, 99}, {30332, 99},
                      {30333, 99}, {30334, 99}, {30335, 99}, {30336, 99}, {30341, 99}, {30342, 99}, {30343, 99},
                      {30344, 99}, {30345, 99}, {30346, 99}, {30360, 99}, {30361, 99}, {30364, 99}, {30365, 99}, {30366, 99}, {30367, 99}, {30368, 99}];
        Degree =:= 3 ->
            Level = 300,
            Goods2 = [{1, 10000000}, {2, 10000}, {3, 10000}, {70070, 1}, {70570, 1}, {71070, 1}, {71570, 1}, {72070, 1}, {72570, 1}, {23070, 1},
                      {23570, 1}, {24070, 1}, {24570, 1}, {30004, 10}, {30014, 10}, {30301, 99}, {30302, 99}, {30303, 99}, {30304, 99},
                      {30321, 99}, {30322, 99}, {30323, 99}, {30324, 99}, {30325, 99}, {30326, 99}, {30331, 99},
                      {30332, 99}, {30333, 99}, {30334, 99}, {30335, 99}, {30336, 99}, {30341, 99},
                      {30342, 99}, {30343, 99}, {30344, 99}, {30345, 99}, {30346, 99}, {30360, 99}, {30361, 99}, {30364, 99}, {30365, 99}, {30366, 99},
                      {30367, 99}, {30368, 99}]
    end,
    [begin
         GoodsList2 = [#p_goods{type_id = TypeID, num = ItemNum} || {TypeID, ItemNum} <- Goods2],
         role_misc:give_goods(RoleID, ?ITEM_GAIN_GM, GoodsList2),
         role_misc:info_role(RoleID, {mod_role_function, gm_trigger_function, []}),
         role_misc:info_role(RoleID, {mod_role_level, gm_set_level, [Level]}),
         role_misc:info_role(RoleID, {mod_role_copy, gm_set_copy_tower, [40040]}),
         role_misc:info_role(RoleID, {mod_role_rune, add_essence, [10000000]}),
         role_misc:info_role(RoleID, {mod_role_rune, add_piece, [10000000]}),
         role_misc:info_role(RoleID, {mod_role_rune, add_exp, [100000000]}),
         role_misc:info_role(RoleID, {mod_role_relive, gm_set_relive_level, [3, 0]}),
         AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_GM, 100000, 100000}, {add_silver, ?ASSET_SILVER_ADD_FROM_GM, 10000000},
                       {add_score, ?ASSET_GLORY_ADD_FROM_ITEM, ?CONSUME_GLORY, 1000000}],
         role_misc:info_role(RoleID, {mod_role_asset, do, [AssetDoing]})
     end || RoleID <- RoleList].

modify_stones() ->
    EquipList2 =
    [begin
         #r_role_equip{equip_list = EquipList} = RoleEquip,
         EquipList2 = [erlang:setelement(6, Equip, []) || Equip <- EquipList],
         RoleEquip#r_role_equip{equip_list = EquipList2}
     end || RoleEquip <- db_lib:all(?DB_ROLE_EQUIP_P)],
    db:insert(?DB_ROLE_EQUIP_P, EquipList2).

modify_role_attr() ->
    [begin
         RoleID = erlang:element(2, Attr),
         Attr2 = erlang:delete_element(20, Attr),
         [PrivateAttr] = db:lookup(?DB_ROLE_PRIVATE_ATTR_P, RoleID),
         PrivateAttr2 = erlang:insert_element(27, PrivateAttr, 0),
         db:insert(?DB_ROLE_ATTR_P, Attr2),
         db:insert(?DB_ROLE_PRIVATE_ATTR_P, PrivateAttr2)
     end || Attr <- db_lib:all(?DB_ROLE_ATTR_P)].

modify_role_skill() ->
    [begin
         #r_role_attr{role_id = RoleID, level = RoleLevel} = Attr,
         case RoleLevel >= 210 of
             true ->
                 MFA = {mod_role_skill, skill_open, [1105001]},
                 case role_misc:is_online(RoleID) of
                     true ->
                         role_misc:info_role(RoleID, MFA);
                     _ ->
                         world_offline_event_server:add_event(RoleID, MFA)
                 end;
             _ ->
                 ok
         end
     end || Attr <- db_lib:all(?DB_ROLE_ATTR_P)].



modify_p_family_member() ->
    [begin
         #p_family{members = Members} = Family,
         NewMembers = lists:foldl(
             fun(Member, List) ->
                 RoleID = erlang:element(2, Member),
                 #r_role_attr{
                     sex = Sex} = common_role_data:get_role_attr(RoleID),
                 NewMember = erlang:insert_element(7, Member, Sex),
                 [NewMember|List]
             end,
             [], Members),
         NewFamily = Family#p_family{members = NewMembers},
         db:insert(?DB_FAMILY_P, NewFamily)
     end || Family <- db_lib:all(?DB_FAMILY_P)].

modify_ios_data() ->
    TabList = [
        ?DB_ROLE_MAP_P,
        ?DB_ROLE_ADDICT_P
    ],
    [db:delete_all(Tab) || Tab <- TabList],
    [begin
         case RoleAttr of
             {r_role_attr, ROLE_ID, ROLE_NAME, ACCOUNT_NAME, UID, SEX, LEVEL, EXP, STATUS,
              RESET_TIME, TEAM_ID, CATEGORY, FAMILY_ID, FAMILY_NAME, FAMILY_SKILLS, FAMILY_DAY_REWARD, SERVER_ID, CHANNEL_ID, _GAME_CHANNEL_ID,
              SKIN_LIST, OFFLINE_FIGHT_TIME, _COUPLE_ID, _COUPLE_NAME, POWER, MAX_POWER, _CONFINE, GUIDE_ID_LIST,
              DEVICE_NAME, OS_TYPE, OS_VER, NET_TYPE, IMEI, PACKAGE_NAME, WIDTH, HEIGHT, CREATE_TIME, TODAY_ONLINE_TIME,
              TOTAL_ONLINE_TIME, ONLINE_CALC_TIME, LAST_LEVEL_TIME, LAST_LOGIN_IP, LAST_LOGIN_TIME,
              LAST_OFFLINE_TIME, IS_INSIDER, INSIDER_TIME, INSIDER_GOLD} ->
                 RoleAttr2 = {r_role_attr, ROLE_ID, ROLE_NAME, ACCOUNT_NAME, UID, SEX, LEVEL, EXP,
                              TEAM_ID, CATEGORY, FAMILY_ID, FAMILY_NAME, SERVER_ID, CHANNEL_ID, 1000,
                              SKIN_LIST, POWER, MAX_POWER, LAST_OFFLINE_TIME},
                 PrivateAttr = {r_role_private_attr, ROLE_ID, STATUS, RESET_TIME, FAMILY_SKILLS, FAMILY_DAY_REWARD, OFFLINE_FIGHT_TIME,
                                GUIDE_ID_LIST, DEVICE_NAME, OS_TYPE, OS_VER, NET_TYPE, IMEI, PACKAGE_NAME, WIDTH, HEIGHT,
                                CREATE_TIME, TODAY_ONLINE_TIME, TOTAL_ONLINE_TIME, ONLINE_CALC_TIME, LAST_LEVEL_TIME, LAST_LOGIN_IP,
                                LAST_LOGIN_TIME, IS_INSIDER, INSIDER_TIME, INSIDER_GOLD, 0},
                 db:insert(?DB_ROLE_ATTR_P, RoleAttr2),
                 db:insert(?DB_ROLE_PRIVATE_ATTR_P, PrivateAttr);
             _ ->
                 ok
         end
     end || RoleAttr <- db_lib:all(?DB_ROLE_ATTR_P)].

modify_ios_account() ->
    [begin
         case string:tokens(lib_tool:to_list(Account), "_") of
             [ServerID, UID] ->
                 AccountRole = #r_account_role{account = lib_tool:to_binary(ServerID ++ "_1000_" ++ UID), role_id_list = RoleIDList},
                 db:delete(?DB_ACCOUNT_ROLE_P, Account),
                 db:insert(?DB_ACCOUNT_ROLE_P, AccountRole);
             _ ->
                 ok
         end
     end || #r_account_role{account = Account, role_id_list = RoleIDList} <- db_lib:all(?DB_ACCOUNT_ROLE_P), RoleIDList =/= []].

modify_local_account() ->
    modify_local_account(0).
modify_local_account(GameChannelID) ->
    [begin
         case string:tokens(lib_tool:to_list(Account), "_") of
             [_OldServerID, _OldGameChannelID, UID] ->
                 ServerIDString = lib_tool:to_list(common_config:get_server_id()),
                 GameChannelIDString = lib_tool:to_list(GameChannelID),
                 AccountRole = #r_account_role{account = lib_tool:to_binary(ServerIDString ++ "_" ++ GameChannelIDString ++ "_" ++ UID), role_id_list = RoleIDList},
                 db:delete(?DB_ACCOUNT_ROLE_P, Account),
                 db:insert(?DB_ACCOUNT_ROLE_P, AccountRole);
             _ ->
                 ok
         end
     end || #r_account_role{account = Account, role_id_list = RoleIDList} <- db_lib:all(?DB_ACCOUNT_ROLE_P)],
    [db:insert(?DB_ROLE_ATTR_P, RoleAttr#r_role_attr{game_channel_id = GameChannelID}) || RoleAttr <- db_lib:all(?DB_ROLE_ATTR_P)].

modify_data() ->
    db:delete_all(?DB_ACCOUNT_ROLE_P),
    db:delete_all(?DB_ROLE_ACCOUNT_P),
    ServerID = common_config:get_server_id(),
    ServerIDString = lib_tool:to_list(common_config:get_server_id()),
    [begin
         GameChannelIDString = lib_tool:to_list(0),
         RoleIDString = lib_tool:to_list(RoleID),
         Account = lib_tool:to_binary(ServerIDString ++ "_" ++ GameChannelIDString ++ "_" ++ RoleIDString),
         db:insert(?DB_ACCOUNT_ROLE_P, #r_account_role{account = Account, role_id_list = [RoleID]}),
         db:insert(?DB_ROLE_ACCOUNT_P, #r_role_account{role_id = RoleID, account = Account}),
         %% 离线挂机清理
         [PrivateAttr] = db:lookup(?DB_ROLE_PRIVATE_ATTR_P, RoleID),
         db:insert(?DB_ROLE_PRIVATE_ATTR_P, PrivateAttr#r_role_private_attr{offline_fight_time = 0})
     end || #r_role_attr{role_id = RoleID} <- db_lib:all(?DB_ROLE_ATTR_P)],
    [begin
         ExtraID = 1,
         db:insert(db_role_map_p, RoleMap#r_role_map{server_id = ServerID, map_pname = map_misc:get_map_pname(MapID, ExtraID, ServerID)})
     end || #r_role_map{server_id = MapServerID, map_id = MapID} = RoleMap <- db_lib:all(?DB_ROLE_MAP_P), MapServerID =/= ServerID].


modify_reset_data() ->
    [begin
         world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_mission, day_reset, []}]}),
         world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_mission, zero, []}]}),
         world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_shop, day_reset, []}]}),
         world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_shop, zero, []}]}),
         world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_daily_liveness, day_reset, []}]}),
         world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_daily_liveness, zero, []}]})
     end || #r_role_private_attr{role_id = RoleID, reset_time = ResetTime} <- db_lib:all(?DB_ROLE_PRIVATE_ATTR_P), time_tool:is_same_date(ResetTime)].

modify_mythical_equip() ->
    [begin
         case role_misc:is_online(RoleID) of
             true ->
                 role_misc:info_role(RoleID, {mod, mod_role_mythical_equip, modify_mythical_equip});
             _ ->
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod, mod_role_mythical_equip, modify_mythical_equip}]})
         end
     end || #r_role_attr{role_id = RoleID, level = Level} <- db_lib:all(?DB_ROLE_ATTR_P), Level >= 330].

modify_equip_concise() ->
    [begin
         case role_misc:is_online(RoleID) of
             true ->
                 role_misc:info_role(RoleID, {mod, mod_role_equip, modify_role_equip_concise});
             _ ->
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod, mod_role_equip, modify_role_equip_concise}]})
         end
     end || #r_role_attr{role_id = RoleID, level = Level} <- db_lib:all(?DB_ROLE_ATTR_P), Level >= 260].

%% V7一次性脚本（不能重复跑）
%% 天赋点数数据修正
%% 主线任务数据修正
modify_ios_v7() ->
    [begin
         #r_role_relive{relive_level = ReliveLevel, talent_points = TalentPoints} = RoleRelive,
         case ReliveLevel =:= 4 of
             true ->
                 db:insert(?DB_ROLE_RELIVE_P, RoleRelive#r_role_relive{talent_points = TalentPoints + common_misc:get_global_int(?GLOBAL_RELIVE_TALENT_PINTS)});
             _ ->
                 ok
         end
     end || RoleRelive <- db_lib:all(?DB_ROLE_RELIVE_P)],
    [begin
         #r_role_mission{doing_list = DoingList} = RoleMission,
         DoingList2 = modify_doing_mission(DoingList, []),
         RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2},
         db:insert(?DB_ROLE_MISSION_P, RoleMission2)
     end || RoleMission <- db_lib:all(?DB_ROLE_MISSION_P)],
    update_role_act_dayrecharge(),
    update_world_gm_letter(),
    modify_local_account(lib_tool:to_integer(?IOS_NEW_GAME_CHANNEL_ID)),
    ok.

modify_doing_mission([], Acc) ->
    Acc;
modify_doing_mission([#r_mission_doing{id = ID, type = Type} = Doing|R], Acc) ->
    case lib_config:find(cfg_mission, ID) of
        [_Config] ->
            modify_doing_mission(R, [Doing|Acc]);
        _ ->
            case Type =:= ?MISSION_TYPE_MAIN of
                true -> %% 主线任务不存在，直接设置为第一个任务
                    MissionID = 10001,
                    [#c_mission{auto_accept = AutoAccept, listeners = Listeners}] = lib_config:find(cfg_mission, 10001),
                    Listens = [#r_mission_listen{type = ListenerType, val = ListenVal, need_num = NeedNum, num = 0, rate = Rate} ||
                        {ListenerType, ListenVal, NeedNum, Rate} <- Listeners],
                    MissionStatus = ?IF(?IS_AUTO_ACCEPT(AutoAccept), ?MISSION_STATUS_DOING, ?MISSION_STATUS_ACCEPT),
                    Doing2 = #r_mission_doing{id = MissionID, type = ?MISSION_TYPE_MAIN, status = MissionStatus, listens = Listens},
                    modify_doing_mission(R, [Doing2|Acc]);
                _ ->
                    modify_doing_mission(R, Acc)
            end
    end.

%%删除日冲1280档位
update_role_act_dayrecharge() ->
    [begin
         #r_role_act_dayrecharge{day_reward = DayReward} = RoleActDayRecharge,
         case lists:keytake(1280, #p_kv.id, DayReward) of
             {value, _, Other} ->
                 RoleActDayRecharge#r_role_act_dayrecharge{day_reward = Other};
             _ ->
                 RoleActDayRecharge
         end
     end || RoleActDayRecharge <- db_lib:all(?DB_ROLE_ACT_DAYRECHARGE_P)].

update_world_gm_letter() ->
    WorldLetter = world_letter_server:get_world_letter(?GM_MAIL_ID),
    world_letter_server:set_world_letter(WorldLetter#r_world_letter{receive_box = []}).

%%
stat_pay_info() ->
    RolePayList = db_lib:all(?DB_ROLE_PAY_P),
    stat_pay_info2(RolePayList, []).

stat_pay_info2([], Acc) ->
    Acc;
stat_pay_info2([RolePay|R], Acc) ->
    #r_role_pay{role_id = RoleID, total_pay_gold = TotalPayGold} = RolePay,
    [#r_role_attr{game_channel_id = GameChannelID, uid = UID}] = db:lookup(?DB_ROLE_ATTR_P, RoleID),
    Key = {GameChannelID, UID},
    case TotalPayGold > 0 of
        true ->
            case lists:keytake(Key, 1, Acc) of
                {value, {Key, OldGold}, Acc2} ->
                    stat_pay_info2(R, [{Key, OldGold + TotalPayGold}|Acc2]);
                _ ->
                    stat_pay_info2(R, [{Key, TotalPayGold}|Acc])
            end;
        _ ->
            stat_pay_info2(R, Acc)
    end.

update_family_box() ->
    FamilyList = db_lib:all(?DB_FAMILY_P),
    FamilyBoxList = db_lib:all(?DB_FAMILY_BOX_P),
    case FamilyList =/= [] andalso FamilyBoxList =:= [] of
        false ->
            [];
        _ ->
            BoxList = [begin
                           case lists:keyfind(Family#p_family.family_id, #r_family_box.family_id, FamilyBoxList) of
                               false ->
                                   RoleBoxList = [
                                       begin
                                           MaxNum = mod_role_vip:get_box_max_num(Member#p_family_member.role_id),
                                           #r_box_list{role_id = Member#p_family_member.role_id, max_num = MaxNum}
                                       end
                                       || Member <- Family#p_family.members],
                                   #r_family_box{family_id = Family#p_family.family_id, role_box_list = RoleBoxList};
                               Info ->
                                   Info
                           end
                       end || Family <- FamilyList],
            ?ERROR_MSG("------~w", [BoxList]),
            db:insert(?DB_FAMILY_BOX_P, BoxList)
    end.


update_confine_mission() ->
    RoleList = db_lib:all(?DB_ROLE_ACCOUNT_P),
    lists:map(fun(#r_role_account{role_id = RoleID}) ->
        mod_role_confine:update_mission(RoleID)
              end, RoleList).


update_confine_status() ->
    RoleList = db_lib:all(?DB_ROLE_ACCOUNT_P),
    lists:map(fun(#r_role_account{role_id = RoleID}) ->
        mod_role_confine:update_confine_status(RoleID)
              end, RoleList).

update_confine_status(RoleID) ->
    mod_role_confine:update_confine_status(RoleID).

stat_talent_list() ->
    lists:flatten(
        [begin
             case lists:keyfind(1, #p_tab_skill.tab_id, TabList) of
                 #p_tab_skill{skills = SkillIDList} ->
                     case stat_talent_list2(SkillIDList) of
                         true ->
                             RoleID;
                         _ ->
                             []
                     end;
                 _ ->
                     []
             end
         end || #r_role_relive{role_id = RoleID, talent_skills = TabList} <- db_lib:all(db_role_relive_p)]).

stat_talent_list2([]) ->
    false;
stat_talent_list2([SkillID|R]) ->
    case SkillID div 1000 =:= 11007 of
        true ->
            true;
        _ ->
            stat_talent_list2(R)
    end.

modify_talent() ->
    RoleIDList = stat_talent_list(),
    [begin
         case role_misc:is_online(RoleID) of
             true ->
                 role_misc:info_role(RoleID, {?MODULE, modify_talent2, []});
             _ ->
                 world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {?MODULE, modify_talent2, []}]})
         end
     end || RoleID <- RoleIDList].

modify_talent2(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{power = Power} = RoleAttr,
    RoleAttr2 = RoleAttr#r_role_attr{max_power = Power},
    mod_role_rank:update_rank(?RANK_ROLE_POWER, {RoleID, Power, time_tool:now()}),
    State2 = State#r_role{role_attr = RoleAttr2},
    mod_role_act_rank:power_change(State2).

stat_red_packet_num() ->
    lists:flatten(
        [begin
             RoleBag =
             case role_misc:is_online(RoleID) of
                 true ->
                     role_server:i(RoleID, role_bag);
                 _ ->
                     case db:lookup(?DB_ROLE_BAG_P, RoleID) of
                         [RoleBagT] ->
                             RoleBagT;
                         _ ->
                             #r_role_bag{bag_list = []}
                     end
             end,
             #r_role_bag{bag_list = BagList} = RoleBag,
             GoodsList2 = lists:flatten([GoodsList || #p_bag_content{bag_id = BagID, goods_list = GoodsList} <- BagList,
                                         lists:member(BagID, [?BAG_ID_BAG, ?BAG_ID_DEPOT])]),
             search_bag_red_packet(RoleID, GoodsList2)
         end || RoleID <- db_lib:all_keys(?DB_ROLE_ATTR_P)]).

search_bag_red_packet(RoleID, GoodsList) ->
    RedPacketList = [32009, 32010, 32011],
    case search_bag_red_packet(GoodsList, RedPacketList, false, []) of
        {true, NumList} ->
            {RoleID, NumList};
        _ ->
            []
    end.

search_bag_red_packet([], _RedPacketList, IsDanger, NumAcc) ->
    {IsDanger orelse erlang:length(NumAcc) >= 2, NumAcc};
search_bag_red_packet([#p_goods{type_id = TypeID, num = Num}|R], RedPacketList, IsDanger, NumAcc) ->
    case lists:member(TypeID, RedPacketList) of
        true ->
            case lists:keytake(TypeID, 1, NumAcc) of
                {value, {TypeID, OldVal}, NumAcc2} ->
                    NewVal = OldVal + Num,
                    search_bag_red_packet(R, RedPacketList, NewVal >= 2, [{TypeID, NewVal}|NumAcc2]);
                _ ->
                    search_bag_red_packet(R, RedPacketList, Num >= 2, [{TypeID, Num}|NumAcc])
            end;
        _ ->
            search_bag_red_packet(R, RedPacketList, IsDanger, NumAcc)
    end.

update_role_pay(RoleIDList) when erlang:is_list(RoleIDList) ->
    [update_role_pay(RoleID) || RoleID <- RoleIDList];
update_role_pay(RoleID) ->
    role_misc:kick_role(RoleID),
    timer:sleep(500),
    [RolePay] = db:lookup(db_role_pay_p, RoleID),
    RolePay2 =
    case RolePay of
        {r_role_pay, ROLE_ID, TODAY_PAY_GOLD, TOTAL_PAY_GOLD, TOTAL_PAY_FEE, PACKAGE_TIME, PACKAGE_DAYS, FIRST_PAY_LIST} ->
            {r_role_pay, ROLE_ID, TODAY_PAY_GOLD, TOTAL_PAY_GOLD, TOTAL_PAY_FEE, PACKAGE_TIME, PACKAGE_DAYS, FIRST_PAY_LIST, []};
        _ ->
            RolePay
    end,
    db:insert(db_role_pay_p, RolePay2).

%% 统计vip称号异常问题
stat_vip_titles() ->
    lists:flatten(
        [begin
             {RoleVip, RoleTitle} =
             case role_misc:is_online(RoleID) of
                 true ->
                     RoleVipT2 = role_server:i(RoleID, role_vip),
                     RoleTitleT = role_server:i(RoleID, role_title),
                     {RoleVipT2, RoleTitleT};
                 _ ->
                     [RoleTitleT] = db:lookup(?DB_ROLE_TITLE_P, RoleID),
                     {RoleVipT, RoleTitleT}
             end,
             #r_role_vip{level = NowLevel} = RoleVip,
             #r_role_title{titles = Titles} = RoleTitle,
             case NowLevel >= 6 of
                 true ->
                     IsMiss = not lists:keymember(3, #p_kv.id, Titles),
                     IsFit = NowLevel >= 11,
                     IsHas = lists:keymember(55, #p_kv.id, Titles),
                     {RoleID, IsMiss, IsFit, IsHas};
                 _ ->
                     []
             end
         end || #r_role_vip{role_id = RoleID, level = Level} = RoleVipT <- db_lib:all(?DB_ROLE_VIP_P), Level >= 4]).

modify_vip_titles() ->
    List = stat_vip_titles(),
    lists:flatten(
        [begin
             ?IF(IsMiss, world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_title, gm_add_title, [3]}]}), ok),
             ?IF(not IsFit andalso IsHas, world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_title, gm_del_title, [55]}]}), ok),
             ?IF((not IsFit andalso IsHas), RoleID, [])
         end || {RoleID, IsMiss, IsFit, IsHas} <- List]).

%%   后台累充   8月7号用
modify_recharge(RoleID) ->
    [#r_role_pay{today_pay_gold = PayGold}] = db:lookup(db_role_pay_p, RoleID),
    [RoleActFeast] = db:lookup(db_role_act_feast_p, RoleID),
    ?WARNING_MSG("-----PayRewardList2--~w", [RoleActFeast]),
    #r_role_act_feast{pay_gold = PayGold2, pay_reward_list = PayRewardList} = RoleActFeast,
    case PayGold >= PayGold2 of
        false ->
            ok;
        _ ->
            {PayRewardList2, _UpdateList} = get_change_list(PayGold2, PayRewardList, [], []),
            ?WARNING_MSG("-----PayRewardList2--~w", [PayRewardList2]),
            RoleActFeast2 = RoleActFeast#r_role_act_feast{pay_gold = PayGold, pay_reward_list = PayRewardList2},
            db:insert(db_role_act_feast_p, RoleActFeast2)
    end.

get_change_list(_Gold, [], PayRewardList, UpdateList) ->
    {PayRewardList, UpdateList};

get_change_list(Gold, [Info|T], PayRewardList, UpdateList) ->
    case Info#p_kvt.type =:= ?ACT_REWARD_CANNOT_GET of
        true ->
            case Gold >= Info#p_kvt.val of
                true ->
                    get_change_list(Gold, T, [Info#p_kvt{type = ?ACT_REWARD_CAN_GET}|PayRewardList], [Info#p_kvt{type = ?ACT_REWARD_CAN_GET, val = Info#p_kvt.val}|UpdateList]);
                _ ->
                    get_change_list(Gold, T, [Info|PayRewardList], [Info#p_kvt{type = ?ACT_REWARD_CANNOT_GET, val = Gold}|UpdateList])
            end;
        _ ->
            get_change_list(Gold, T, [Info|PayRewardList], UpdateList)
    end.

update_bless_data() ->
    RoleList = db_lib:all(?DB_ROLE_ACCOUNT_P),
    lists:map(fun(#r_role_account{role_id = RoleID}) ->
        mod_role_bless:calc_rate_shell(RoleID)
              end, RoleList).
update_bless_data(RoleID) ->
    mod_role_bless:calc_rate_shell(RoleID).



init_family_td_new_ets() ->
    lib_tool:init_ets(?ETS_FAMILY_TD_REWARD, #p_kv.id),
    ets:give_away(?ETS_FAMILY_TD_REWARD, pname_server:pid(world_activity_server), []).



act_accrecharge_repair() ->
    RoleList = db_lib:all(?DB_ROLE_ACCOUNT_P),
    lists:map(fun(#r_role_account{role_id = RoleID}) ->
        mod_role_act_accrecharge:act_accrecharge_repair(RoleID)
              end, RoleList).
act_accrecharge_repair(RoleID) ->
    mod_role_act_accrecharge:act_accrecharge_repair(RoleID).


open_first_recharge_table() ->
    [db:open(Table, EtsOpts, SqlOpts, ActiveTime) || #c_tab{tab = Table, ets_opts = EtsOpts, sql_opts = SqlOpts, active_time = ActiveTime} <- ?TABLE_INFO, Table =:= ?DB_ROLE_ACT_FIRSTRECHARGE_P].



cycle_data_change()->
    case time_tool:date() =:= {2019, 11, 4} of
        true ->
            [begin
                 case CycleAct#r_cycle_act.status =:= ?CYCLE_ACT_STATUS_OPEN of
                     true ->
                         db:insert(?DB_R_CYCLE_ACT_P, CycleAct);
                     _ ->
                         ok
                 end
             end || CycleAct <- ets:tab2list(?DB_R_CYCLE_ACT_P)];
        _ ->
            ok
    end.

modify_solo_buy_times() ->
    [begin
            case world_offline_solo_server:get_offline_solo(RoleID) of
                [#r_role_offline_solo{buy_times = BuyTimes} = OfflineSolo] ->
                    BuyTimes2 = ?IF(BuyTimes < ?DEFAULT_BUY_TIMES, ?DEFAULT_BUY_TIMES - BuyTimes, 0),
                    OfflineSolo2 = OfflineSolo#r_role_offline_solo{buy_times = BuyTimes2},
                    world_offline_solo_server:set_offline_solo(OfflineSolo2);
                _ ->
                    ok
            end
     end  || RoleID <- db_lib:all_keys(db_role_offline_solo_p)],
    ok.
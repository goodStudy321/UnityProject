%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     执行脚本
%%% @end
%%% Created : 12. 四月 2018 17:46
%%%-------------------------------------------------------------------
-module(common_execute_cmd).
-include("rank.hrl").
-include("global.hrl").
-include("copy.hrl").
-include("demon_boss.hrl").
-include("confine.hrl").
-include("pay.hrl").
-include("proto/mod_role_confine.hrl").

-export([
    test/0,
    test/1,
    test/2
]).

-export([
    set_db_version/1
]).

-export([
    v8_update/0,
    modify_illusion/0,
    modify_role_level/0,
    modify_demon_boss_and_boss/0
]).

-export([
    v9_update/0,
    update_armor_lock_data/0
]).

-export([
    add_role_function/0,
    modify_role_achievement/0,
    modify_tower_rank/0,
    stat_pay_log/0,
    send_pay_log/0
]).

-export([
    delete_cross_log/0,
    solo_reset_date/0,
    add_world_hour_change/0
]).

test() ->
    ok.

test(Args1) ->
    {ok, Args1}.

test(Args1, Args2) ->
    {ok, [Args1, Args2]}.

set_db_version(Version) ->
    world_data:set_db_version(lib_tool:to_integer(Version)),
    ok.

modify_illusion() ->
    [ db:insert(?DB_ROLE_COPY_P, RoleCopy#r_role_copy{illusion = 0, last_add_time = 0}) || RoleCopy <- db_lib:all(?DB_ROLE_COPY_P)],
    ok.

modify_role_level() ->
    AllList = [{32006400000043,182},{32006400000030,210},{32006400000012,214},{32006400000062,173},{32006400000055,165},{32006300000009,232},
        {32006300000130,209},{32006300000023,223},{32006300000016,236},{32006300000029,218},{32006300000098,211},{32006200000115,251},
        {32006200000161,232},{32006200000177,216},{32006200000013,249},{32006200000052,268},{32006100000104,271},{32006100000167,257},
        {32006100000014,272},{32006100000096,257},{33005100000186,213},{33005100000039,230},{33005100000004,229},{33005100000242,197},
        {33005000000003,248},{33005000000257,248},{33005000000067,251},{33005000000234,238},{33005000000035,257},{33005000000176,199},
        {33004900000110,243},{33004900000006,247},{33004900000127,255},{33004900000032,267},{33004900000016,254},{33004900000324,236},
        {33004800000063,270},{33004700000072,302},{33004700000288,276},{33004700000051,288},{33004700000176,262},{33004600000267,289},
        {33004600000110,312},{33004500000379,279},{33004500000123,287},{33004500000364,289},{33004400000060,298},{33004400000243,320},
        {33004400000212,310},{33004400000210,349},{33004300000220,350},{33004300000210,320},{33004300000315,290},{33004200000425,307},
        {33004200000396,326},{33004100000339,317},{33004000000299,330},{33004000000358,332},{33003900000314,348},{33003900000040,338},
        {33003800000480,326},{33003800000526,362},{33003700000334,376},{33003700000594,341},{33003700000270,369},{33003500000242,362},
        {33003400000001,356},{33003300000419,343},{33003200000022,412},{32006000000128,260},{32006000000017,291},{32006000000069,302},
        {32005900000109,277},{32005900000032,276},{32005800000039,293},{32005800000114,317},{32005800000097,292},{32005700000077,299},
        {32005600000022,308},{32005400000003,370},{32005400000027,329},{32005300000183,353},{32005200000800,323},{32005200000014,397},
        {32005200000302,354},{32005200000121,337},{32005200000145,365},{32005200000878,315},{32005200000218,376},{32005100000369,393},
        {32005100000802,380},{32005100000525,376},{32005100000182,400},{32005100000077,398},{32005000000103,426},{32005000000137,401},
        {32004900000015,446},{32004900000646,371},{32004900000027,433},{32004900000052,406},{32004800000108,368},{32004800000379,407},
        {32004700001046,350},{32004700001452,386},{32004700000679,477},{32004600000246,416},{32004600000126,466},{32004600000410,367},
        {32004600001068,406},{32004600000180,354},{32004500000126,485},{32004500000932,374},{32004500001582,364},{32004500000948,363},
        {32004400000033,451},{32004300000782,445},{32004200000483,373},{32004200001748,284},{32004200001606,376},{32004200001147,415},
        {32004200000189,521},{32004100000797,441},{32004100000086,396},{32004100000984,394},{32004100000163,452},{32004100000352,433},
        {32003900000921,416},{32003900000255,438},{32003900000084,393},{32003700000358,424},{32003700000985,428},{32003600000012,464},
        {32003500000060,483},{32003400000064,449},{32003300001225,525},{32003200001146,410},{32003200000762,436},{32003100001440,538},
        {33003000000457,365},{33002800000014,391},{33002700000052,379},{33002700000513,367},{33002600000043,365},{33002400000001,485},
        {33002300000242,432},{33002200000202,457},{33002000000159,432},{33002000000888,396},{33001900001487,402},{33001900001611,375},
        {33001900000975,368},{33001300002145,442},{33001300000297,630},{33001300001545,431},{33001300002510,428},{33001200002508,463},
        {33001200002101,569},{33001100000014,487},{33001000001627,462},{33001000002135,576},{33000900000704,408},{33000700002280,350},
        {33000700002295,355},{33000700002296,353},{33000700000418,476},{33000700002290,358},{33000700002288,359},{33000400001001,462},
        {33000400002160,451},{33000100000008,485},{33000100008023,316},{32003000000109,467},{32003000000768,484},{32002800001061,474},
        {32002800001219,491},{32002800000620,586},{32002600001333,402},{32002600000226,441},{32002600001471,560},{32002600000374,541},
        {32002600001612,406},{32002500000573,408},{32002500000119,436},{32002200001219,438},{32002200000078,627},{32002200001484,448},
        {32002000006097,334},{32002000001550,474},{32002000002182,442},{32001800002092,439},{32001800001698,513},{32001800000880,394},
        {32001700000351,420},{32001700000400,415},{32001700001319,426},{32001700000181,447},{32001700000793,438},{32001400000981,394},
        {32001400001919,488},{32001100001818,463},{32001100002381,315},{32001100000447,410},{32001100002058,499},{32001100001682,485},
        {32001100000298,474},{32001000000014,498},{32001000000477,552},{32001000000914,541},{32001000000464,437},{32000800001350,538},
        {32000700000350,466},{32000700001347,465},{32000600000528,493},{32000600001165,481},{32000600000098,620},{32000500001774,432},
        {32000500000215,482},{32000500002297,520},{32000400000351,500},{32000400000599,481},{32000400001500,526},{32000400002382,347},
        {32000300002343,471},{32000300001170,422},{32000200001476,450},{32000200000916,457},{32000100004328,472},{32000100000622,416},
        {32000100003952,408},{32000100004471,447},{32000100003503,433},{32000100004615,415}],
    [ begin
          Level2 = Level + 2,
          case db:lookup(?DB_ROLE_ATTR_P, RoleID) of
              [#r_role_attr{}] ->
                  case role_misc:is_online(RoleID) of
                      true ->
                          role_misc:info_role(RoleID, {mod_role_level, gm_set_level, [Level2]});
                      _ ->
                          world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_level, gm_set_level, [Level2]}]})
                  end,
                  rank_misc:rank_insert_elements(?RANK_ROLE_LEVEL, {RoleID, Level2, time_tool:now()}),
                  ok;
              _ ->
                  ok
          end
      end || {RoleID, Level} <- AllList],
    rank_server:gm_all_rank(),
    ok.

modify_demon_boss_and_boss() ->
    #r_demon_boss_ctrl{next_level = NextLevel} = DemonBossCtrl = world_data:get_demon_boss_ctrl(),
    Level2 = erlang:max(180, erlang:min(NextLevel, world_data:get_world_level())),
    world_data:set_demon_boss_ctrl(DemonBossCtrl#r_demon_boss_ctrl{next_level = Level2}),
    [ db:insert(?DB_ROLE_ROBOT_P, RoleRobot#r_role_robot{has_time = 0})|| #r_role_robot{} = RoleRobot <- world_robot_server:get_all_robot()],
    ok.

modify_role_achievement() ->
    [ begin
          case has_magic_weapon(SkinList) of
              true ->
                  world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_achievement, use_skin_item, [3021100]}]});
              _ ->
                  ok
          end
      end|| #r_role_magic_weapon{role_id = RoleID, skin_list = SkinList} <- db_lib:all(?DB_ROLE_MAGIC_WEAPON_P)],
    ok.

has_magic_weapon([]) ->
    false;
has_magic_weapon([#p_kv{id = ID}|R]) ->
    case ID div 1000 =:= 30211 of
        true ->
            true;
        _ ->
            has_magic_weapon(R)
    end.

modify_tower_rank() ->
    Now = time_tool:now(),
    [ rank_misc:rank_insert_elements(?RANK_COPY_TOWER, {RoleID, ?GET_TOWER_FLOOR(TowerID), Now})
        || #r_role_copy{role_id = RoleID, tower_id = TowerID}<- db_lib:all(?DB_ROLE_COPY_P), TowerID > 0],
    rank_server:gm_all_rank(),
    ok.

%% V8更新调用的一次性脚本
v8_update() ->
    db:delete_all(?DB_ROLE_DAY_TARGET_P),
    add_day_target(),
    add_role_function(),
    modify_act_rank(),
    modify_role_max_power(),
    modify_rank(),
    modify_nature_and_five_elements(),
    ok.

add_day_target() ->
    Now = time_tool:now(),
    [world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod_role_day_target, function_open, []}]})
        || #r_role_attr{last_offline_time = LastOfflineTime, role_id = RoleID, level = Level} <- db_lib:all(?DB_ROLE_ATTR_P),
        Level >= 140 andalso erlang:abs(Now - LastOfflineTime) =< ?ONE_DAY].

add_role_function() ->
    [world_offline_event_server:add_event(RoleID, {mod_role_function, trigger_function, [RoleID, 1, Level]})
        || #r_role_attr{role_id = RoleID, level = Level} <- db_lib:all(?DB_ROLE_ATTR_P), Level >= 150],
    ok.

%% v8更新时，修正开服冲榜
modify_act_rank() ->
    OpenDays = common_config:get_open_days(),
    if
        OpenDays =:= 3 -> %% 坐骑榜修正
            world_data:set_act_ranks(2, []);
        OpenDays =:= 5 -> %% 宠物榜修正
            world_data:set_act_ranks(4, []);
        OpenDays =:= 7 -> %% 战力榜修正
            world_data:set_act_ranks(6, []);
        true ->
            ok
    end.

modify_role_max_power() ->
    [ begin
          db:insert(?DB_ROLE_ATTR_P, RoleAttr#r_role_attr{max_power = 0})
      end || RoleAttr <- db_lib:all(?DB_ROLE_ATTR_P)],
    db:delete(?DB_RANK_P, ?RANK_ROLE_POWER).

modify_rank() ->
    rank_server:gm_del_rank(?RANK_ROLE_POWER).

%% v8更新时，修正玩家的天机印和爬塔层数
modify_nature_and_five_elements() ->
    [ begin
          #r_role_nature{role_id = RoleID, nature = NatureList, book_list = OldBookList} = RoleNature,
          BookList = lib_tool:list_filter_repeat(OldBookList ++ get_book_by_nature(NatureList, [])),
          RoleNature2 = RoleNature#r_role_nature{book_list = BookList},
          db:insert(?DB_ROLE_NATURE_P, RoleNature2),
          modify_role_copy(RoleID, BookList)
      end || RoleNature <- db_lib:all(?DB_ROLE_NATURE_P)],
    ok.

get_index_list([], _WarSpiritID,_ArmorOpenList,_ConfineID, Acc) ->
    Acc;
get_index_list([Index|R], WarSpiritID, ArmorOpenList, ConfineID, Acc) ->
    Acc2 =
        case ConfineID >= lists:nth(Index, ArmorOpenList) of
            true -> [#p_war_armor_lock_info{index = Index, is_open = true} | Acc];
            _ -> Acc
        end,
    get_index_list(R, WarSpiritID, ArmorOpenList, ConfineID, Acc2).

modify_role_copy(RoleID, BookList) ->
    case db:lookup(?DB_ROLE_COPY_P, RoleID) of
        [#r_role_copy{cur_five_elements = CurFive, unlock_floor = UnlockFloor} = RoleCopy] ->
            NowFloor = get_now_floor(BookList, 1),
            NowCurFive = 70000 + NowFloor * 100 + 1,
            RoleCopy2 = RoleCopy#r_role_copy{cur_five_elements = erlang:max(CurFive, NowCurFive), unlock_floor = erlang:max(UnlockFloor, NowFloor)},
            db:insert(?DB_ROLE_COPY_P, RoleCopy2);
        _ ->
            ok
    end.

get_book_by_nature([], Acc) ->
    Acc;
get_book_by_nature([Nature|R], Acc) ->
    #r_nature{goods = GoodList, history = History} = Nature,
    TypeIDList1 = [ GoodsTypeID || #p_goods{type_id = GoodsTypeID} <- GoodList],
    TypeIDList2 = [ TypeID2 || {_, TypeID2} <- History],
    get_book_by_nature(R, TypeIDList1 ++ TypeIDList2 ++ Acc).

get_now_floor(BookList, NowFloor) ->
    Floor2 = NowFloor + 1,
    case lib_config:find(cfg_five_elements_floor, Floor2) of
        [#c_five_elements_floor{need_list = NeedList}] ->
            case (NeedList -- BookList) =:= NeedList of
                true ->
                    NowFloor;
                _ ->
                    get_now_floor(BookList, Floor2)
            end;
        _ ->
            NowFloor
    end.

%%%===================================================================
%%% v9版本    start
%%%===================================================================
v9_update() ->
    update_armor_lock_data(),
    ok.

update_armor_lock_data() ->
    [ begin
          #r_role_confine{confine = ConfineID, war_spirit_list = WarSpiritList} = RoleConfine,
          WarSpiritIDList = [WarSpiritID||#p_war_spirit{id = WarSpiritID} <- WarSpiritList],
          IndexList = lists:seq(1, 10),
          ArmorsList = lists:foldl(
              fun(WarSpiritID, Acc) ->
                  [#c_war_spirit_base{armor_open_list = ArmorOpenList}] = lib_config:find(cfg_war_spirit_base, WarSpiritID),
                  List = get_index_list(IndexList, WarSpiritID, ArmorOpenList, ConfineID, []),
                  [#p_war_armor_lock{war_spirit_id = WarSpiritID, list = List}|Acc]
              end, [], WarSpiritIDList),
          RoleConfine2 = RoleConfine#r_role_confine{lock_info = ArmorsList},
          db:insert(?DB_ROLE_CONFINE_P, RoleConfine2)
      end || RoleConfine <- db_lib:all(?DB_ROLE_CONFINE_P)],
    ok.

%%%===================================================================
%%% v9版本    end
%%%===================================================================

%%%===================================================================
%%% modify    start
%%%===================================================================
stat_pay_log() ->
    TimeStamp = time_tool:timestamp({{2019, 9, 10}, {22, 23, 0}}),
    [ begin
          #r_pay_log{
              role_id = RoleID,
              order_id = OrderID,
              pf_order_id = PFOrderID,
              product_id = ProductID,
              total_fee = TotalFee,
              time = PayTime} = PayLog,
            [RoleAttr] = db:lookup(?DB_ROLE_ATTR_P, RoleID),
            [RolePrivateAttr] = db:lookup(?DB_ROLE_PRIVATE_ATTR_P, RoleID),
          #r_role_attr{
              role_id = RoleID,
              account_name = AccountName,
              level = RoleLevel,
              uid = UID,
              channel_id = ChannelID,
              game_channel_id = GameChannelID} = RoleAttr,
          #r_role_private_attr{
              imei = IMEI
          } = RolePrivateAttr,
          [#c_pay{add_gold = AddGold}] = lib_config:find(cfg_pay, ProductID),
          {PayTime, #log_role_pay{
              role_id = RoleID,
              account_name = AccountName,
              imei = IMEI,
              order_id = OrderID,
              pf_order_id = PFOrderID,
              product_id = ProductID,
              pay_fee = TotalFee,
              pay_gold = AddGold,
              role_level = RoleLevel,
              uid = UID,
              pay_times = 0,
              channel_id = ChannelID,
              game_channel_id = GameChannelID
          }}
      end|| #r_pay_log{product_id = ProductID, time = PayTime} = PayLog <- db_lib:all(?DB_PAY_LOG_P),
        PayTime =< TimeStamp andalso ProductID >= 29 andalso ProductID =< 33].

send_pay_log() ->
    LogList = stat_pay_log(),
    [ gen_server:cast(background_log_server, {modify_log, Time, [Log]}) || {Time, Log} <- LogList].

delete_cross_log() ->
    case common_config:is_cross_node() of
        true ->
            db:delete_all(?DB_BACKGROUND_LOG_P);
        _ ->
            ok
    end.

solo_reset_date() ->
    case common_config:is_cross_node() of
        true ->
            world_data:set_solo_reset_date(ok),
            world_data:init_solo_reset_date();
        _ ->
            none
    end.

add_world_hour_change() ->
    time_tool:reset_hour_change(world),
    ok.
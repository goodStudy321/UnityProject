%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%% 角色零碎数据
%%% @end
%%% Created : 24. 八月 2017 20:34
%%%-------------------------------------------------------------------
-module(mod_role_extra).
-author("laijichang").
-include("web.hrl").
-include("activity.hrl").
-include("role.hrl").
-include("node.hrl").
-include("role_extra.hrl").
-include("world_boss.hrl").
-include("monster.hrl").
-include("pay.hrl").
-include("act.hrl").
-include("proto/mod_role_extra.hrl").
-include("proto/mod_role_act.hrl").
%% API
-export([
    init/1,
    day_reset/1,
    zero/1,
    online/1,
    handle/2,
    role_pre_enter/1
]).

-export([
    add_special_drop/2,
    add_item_drop/2
]).

-export([
    first_drop/3
%%    first_recharge/2
]).

-export([
    get_compose_log/3
]).

-export([
    set_data/3,
    get_data/3
]).

-export([
    gm_set_guide/2,
    gm_set_comment/1,
    get_confine_log/3
]).

-export([
    do_cross_observer/1,
    do_add_special_drop/2,
    do_item_control/2,
    do_world_boss_drop/3
]).

init(#r_role{role_id = RoleID, role_extra = undefined} = State) ->
    RoleExtra = #r_role_extra{role_id = RoleID},
    State#r_role{role_extra = RoleExtra};
init(State) ->
    State.

day_reset(State) ->
    #r_role{role_extra = RoleExtra} = State,
    #r_role_extra{data = Data} = RoleExtra,
    Data2 = [{Key, Value} || {Key, Value} <- Data, not lists:member(Key, ?RESET_KEY_LIST)],
    RoleExtra2 = RoleExtra#r_role_extra{data = Data2},
    State#r_role{role_extra = RoleExtra2}.

zero(State) ->
    online(State).

online(State) ->
    #r_role{role_id = RoleID} = State,
    DataRecord = #m_role_extra_info_toc{
        feedback_times = get_data(?FEEDBACK_TIMES, 0, State),
        exp_efficiency = get_data(?EXTRA_KEY_EXP_EFFICIENCY, 0, State)
        },
    common_misc:unicast(RoleID, DataRecord),
    CommentStatus = get_data(?EXTRA_KEY_COMMENT_STATUS, ?COMMENT_STATUS_NOT, State),
    common_misc:unicast(RoleID, #m_comment_status_toc{status = CommentStatus}),
    DownloadStatus = get_data(?EXTRA_KEY_DOWNLOAD_STATUS, false, State),
    common_misc:unicast(RoleID, #m_download_reward_toc{is_reward = DownloadStatus}),
    WindowOpenList = get_data(?EXTRA_KEY_WIND_OPEN_LIST, [], State),
    common_misc:unicast(RoleID, #m_window_open_toc{window_open_list = WindowOpenList}),
    State.

role_pre_enter(State) ->
    do_role_pre_enter(State).

add_special_drop(RoleID, AddList) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {add_special_drop, AddList}}).

add_item_drop(RoleID, ItemDrops) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {update_item_drops, ItemDrops}}).

handle({#m_goods_compose_tos{compose_id = ComposeID, add_rate_num = AddRateNum}, RoleID, _PID}, State) ->
    do_compose(RoleID, ComposeID, AddRateNum, State);
handle({#m_pick_drop_tos{drop_id = DropID}, RoleID, _PID}, State) ->
    do_pick_drop(RoleID, DropID, State);
handle({#m_role_auto_tos{op_type = OpType}, RoleID, _PID}, State) ->
    do_role_auto(RoleID, OpType, State);
handle({#m_role_guide_tos{guide_id = GuideID}, _RoleID, _PID}, State) ->
    do_role_guide(GuideID, State);
handle({#m_activation_code_tos{code = Code}, RoleID, _PID}, State) ->
    do_activation_code(RoleID, Code, State);
handle({#m_role_observe_tos{role_id = DestRoleID}, RoleID, _PID}, State) ->
    do_observe(RoleID, DestRoleID),
    State;
handle({#m_role_rename_tos{name = Name}, RoleID, _PID}, State) ->
    do_role_rename(RoleID, Name, State);
handle({#m_package_select_tos{goods_id = GoodsID, index = Index}, RoleID, _PID}, State) ->
    do_package_select(RoleID, GoodsID, Index, State);
handle({#m_comment_status_tos{}, RoleID, _PID}, State) ->
    do_comment_status(RoleID, State);
handle({#m_comment_reward_tos{}, RoleID, _PID}, State) ->
    do_comment_reward(RoleID, State);
handle({#m_download_reward_tos{}, RoleID, _PID}, State) ->
    do_download_reward(RoleID, State);
handle({#m_window_open_tos{type = Type}, RoleID, _PID}, State) ->
    do_window_open(RoleID, Type, State);
handle({web_role_rename, NewName}, State) ->
    do_web_role_rename(NewName, State);
handle({other_observe, OBRoleID}, State) ->
    do_other_observe(OBRoleID, State),
    State;
handle({cross_observer, Args}, State) ->
    do_role_cross_observer(Args, State),
    State;
handle({add_special_drop, AddList}, State) ->
    do_add_special_drop(AddList, State);
handle({update_item_drops, ItemDropList}, State) ->
    mod_role_extra:set_data(?EXTRA_KEY_ITEM_DROP_LIST, ItemDropList, State).

gm_set_guide(GuideID, State) ->
    do_role_guide(GuideID, State).

gm_set_comment(State) ->
    Status = ?COMMENT_STATUS_NOT,
    common_misc:unicast(State#r_role.role_id, #m_comment_status_toc{status = Status}),
    set_data(?EXTRA_KEY_COMMENT_STATUS, Status, State).

do_role_pre_enter(State) ->
    MapID = mod_role_data:get_role_map_id(State),
    case lists:keyfind(MapID, #c_activity_mod.map_id, ?ACTIVITY_MOD_LIST) of
        #c_activity_mod{activity_id = ActivityID} -> %% 活动相关地图
            #r_activity{start_time = StartTime} = world_activity_server:get_activity(ActivityID),
            do_role_pre_enter2(MapID, StartTime, State);
        _ ->
            if
                MapID =:= ?MAP_MARRY_FEAST ->
                    StartTime = mod_marry_feast:get_feast_start_time(),
                    do_role_pre_enter2(MapID, StartTime, State);
                true ->
                    State
            end
    end.

do_role_pre_enter2(MapID, StartTime, State) ->
    MapList = get_data(?EXTRA_KEY_ACTIVITY_MAP, [], State),
    case lists:keyfind(MapID, #p_kv.id, MapList) of
        #p_kv{val = OldVal} when OldVal >= StartTime ->
            State;
        _ ->
            MapList2 = lists:keystore(MapID, #p_kv.id, MapList, #p_kv{id = MapID, val = StartTime}),
            State2 = set_data(?EXTRA_KEY_ACTIVITY_MAP, MapList2, State),
            hook_role:role_activity_trigger(MapID, State2)
    end.

first_drop(MonsterTypeID, MonsterPos, State) ->
    DropList = get_data(?EXTRA_KEY_FIRST_DROP, [], State),
    case lists:member(MonsterTypeID, DropList) of
        true ->
            State;
        _ ->
            #c_monster{first_drop = TypeString} = monster_misc:get_monster_config(MonsterTypeID),
            case TypeString =/= "" of
                true ->
                    TypeIDList = lib_tool:string_to_intlist(TypeString),
                    mod_map_role:role_first_drop(mod_role_dict:get_map_pid(), State#r_role.role_id, MonsterTypeID, TypeIDList, MonsterPos),
                    set_data(?EXTRA_KEY_FIRST_DROP, [MonsterTypeID|DropList], State);
                _ ->
                    State
            end
    end.

%%first_recharge(State, PayFee) ->
%%    #r_role{role_id = RoleID} = State,
%%    List = get_data(?EXTRA_KEY_FIRST_CHARGE, [] ,State),
%%    [_Value, _Power, _TitleID, Multiple] = common_misc:get_global_list(?GLOBAL_FIRST_CHARGE),
%%    GoodsList = common_misc:get_global_string_list(?GLOBAL_FIRST_CHARGE),
%%    GoodsList1 = [#p_goods{type_id = TypeID, num = Num}||{TypeID, Num} <- GoodsList],
%%    ProductID = mod_role_pay:get_product_id_by_pay_fee(PayFee),
%%    case lists:member(ProductID,[34,35,36,37]) of
%%        true ->
%%            LetterInfo = #r_letter_info{
%%                template_id = ?LETTER_FIRST_PAY_GAIN,
%%                action = ?ITEM_GAIN_FIRST_RECHARGE,
%%                goods_list = GoodsList1
%%            },
%%            common_letter:send_letter(RoleID, LetterInfo),
%%            [#c_pay{add_gold = AddGold}] = lib_config:find(cfg_pay, ProductID),
%%            common_misc:unicast(RoleID, #m_act_update_toc{act = #p_act{id = ?ACT_FIRST_CHARGE, is_visible = false}}),
%%            AssetDoings = [{add_gold, ?ASSET_GOLD_ADD_FROM_PAY, AddGold * Multiple, 0}],
%%            State2 = mod_role_asset:do(AssetDoings, State),
%%            set_data(?EXTRA_KEY_FIRST_CHARGE, [GoodsList1|List], State2);
%%        _ ->
%%            State
%%    end.


%% 拾取掉落物成功
do_pick_drop(RoleID, DropID, State) ->
    case catch check_can_pick(State) of
        {ok, PickCondition} ->
            case catch mod_map_role:role_pick_drop(mod_role_dict:get_map_pid(), RoleID, DropID, PickCondition) of
                {ok, GoodsList, MapDrop} ->
                    GoodsList2 = [#p_kv{id = TypeID, val = Num} || #p_goods{type_id = TypeID, num = Num} <- GoodsList],
                    State2 = mod_role_map_panel:add_drop(GoodsList2, State),
                    do_world_boss_drop(GoodsList, MapDrop#p_map_drop.monster_type_id, State2),
                    role_misc:create_goods(State2, ?ITEM_GAIN_PICK, GoodsList);
                {error, ErrCode} when erlang:is_integer(ErrCode) ->
                    common_misc:unicast(RoleID, #m_pick_drop_toc{err_code = ErrCode, drop_id = DropID}),
                    State;
                Error ->
                    ?WARNING_MSG("Waning: ~w", [Error]),
                    common_misc:unicast(RoleID, #m_pick_drop_toc{err_code = ?ERROR_PICK_DROP_001, drop_id = DropID}),
                    State
            end;
        {error, ErrCode} when erlang:is_integer(ErrCode) ->
            common_misc:unicast(RoleID, #m_pick_drop_toc{err_code = ErrCode, drop_id = DropID}),
            State;
        Error ->
            ?ERROR_MSG("Error: ~w", [Error]),
            common_misc:unicast(RoleID, #m_pick_drop_toc{err_code = ?ERROR_PICK_DROP_001, drop_id = DropID}),
            State
    end.

check_can_pick(State) ->
    PickCondition =
    #r_pick_condition{
        is_mythical_equip_full = mod_role_mythical_equip:is_bag_full(1, State),
        is_war_spirit_equip_full = mod_role_confine:is_bag_full(1, State)
    },
    {ok, PickCondition}.

do_world_boss_drop(GoodsList, MonsterTypeID, State) ->
    case lib_config:find(cfg_world_boss, MonsterTypeID) of
        [#c_world_boss{boss_type = BossType, map_id = MapID}] when ?IS_WORLD_BOSS_TYPE(BossType) ->
            #r_role{role_id = RoleID} = State,
            Time = time_tool:now(),
            {LogGoods, RareLogs, NormalLogs} =
            lists:foldl(
                fun(#p_goods{type_id = TypeID} = Goods, {LogGoodsAcc, RareLogsAcc, NormalLogsAcc}) ->
                    case mod_role_item:get_item_config(TypeID) of
                        #c_item{world_boss_drop = DropInteger} when DropInteger > 0 ->
                            Log = #r_world_boss_log{
                                role_id = RoleID,
                                map_id = MapID,
                                monster_type_id = MonsterTypeID,
                                item_type_id = TypeID,
                                time = Time},
                            {RareLogsAcc2, NormalLogsAcc2} = ?IF(DropInteger > 1, {[Log|RareLogsAcc], NormalLogsAcc}, {RareLogsAcc, [Log|NormalLogsAcc]}),
                            {[Goods|LogGoodsAcc], RareLogsAcc2, NormalLogsAcc2};
                        _ ->
                            {LogGoodsAcc, RareLogsAcc, NormalLogsAcc}
                    end
                end, {[], [], []}, GoodsList),
            ?IF(LogGoods =/= [], ?TRY_CATCH(log_world_boss_pick(MonsterTypeID, GoodsList, State)), ok),
            ?IF(RareLogs =/= [] orelse NormalLogs =/= [], world_boss_server:add_drop_lop(RareLogs, NormalLogs), ok);
        _ ->
            ok
    end.

% 合成
do_compose(RoleID, ComposeID, AddRateNum, State) ->
    case catch check_can_compose(ComposeID, AddRateNum, State) of
        {ok, IsSuccess, ItemTypeID, BagDoing, Log} ->
            common_misc:unicast(RoleID, #m_goods_compose_toc{is_success = IsSuccess}),
            State2 = mod_role_bag:do(BagDoing, State),
            State3 = ?IF(IsSuccess, mod_role_mission:compose_trigger(ItemTypeID, State2), State2),
            mod_role_dict:add_background_logs(Log),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_goods_compose_toc{err_code = ErrCode}),
            State
    end.

check_can_compose(ComposeID, AddRateNum, State) ->
    [Config] = lib_config:find(cfg_compose, ComposeID),
    #c_compose{
        need_items = NeedItems,
        compose_items = ComposeList,
        compose_rate = ComposeRate,
        add_rate_item = AddRateItem,
        add_rate = AddRate
    } = Config,
    DecreaseList1 =
    lists:foldl(
        fun(String, Acc) ->
            [TypeID, Num] = string:tokens(String, ","),
            TypeID2 = lib_tool:to_integer(TypeID),
            Num2 = lib_tool:to_integer(Num),
            mod_role_bag:get_decrease_goods_by_num(TypeID2, Num2, State) ++ Acc
        end, [], string:tokens(NeedItems, "|")),
    case AddRateItem > 0 andalso AddRateNum > 0 of
        true ->
            Rate = ComposeRate + AddRate * AddRateNum,
            DecreaseList2 = mod_role_bag:get_decrease_goods_by_num(AddRateItem, AddRateNum, State) ++ DecreaseList1;
        _ ->
            Rate = ComposeRate,
            DecreaseList2 = DecreaseList1
    end,
    LogGoods = [#p_goods{type_id = TypeID, num = Num} || #r_goods_decrease_info{type_id = TypeID, num = Num} <- DecreaseList2],
    case Rate >= lib_tool:random(?RATE_10000) of
        true -> %% 生成
            IsSuccess = true,
            WeightList =
            [begin
                 [TypeID, Num, RandomRate] = string:tokens(String, ","),
                 RateNum = lib_tool:to_integer(Num),
                 mod_role_bag:check_bag_empty_grid(RateNum, State),
                 {lib_tool:to_integer(RandomRate), {lib_tool:to_integer(TypeID), RateNum}}
             end || String <- string:tokens(ComposeList, "|")],
            {ItemTypeID, ItemNum} = lib_tool:get_weight_output(WeightList),
            Bind = lists:keymember(true, #r_goods_decrease_info.id_bind_type, DecreaseList2),
            CreateList = [#p_goods{type_id = ItemTypeID, num = ItemNum, bind = Bind}],
            Log = get_compose_log(ItemTypeID, LogGoods, State),
            BagDoing = [{decrease, ?ITEM_REDUCE_EXTRA_COMPOSE, DecreaseList2}, {create, ?ITEM_GAIN_EXTRA_COMPOSE, CreateList}];
        _ ->
            Log = get_compose_log(0, LogGoods, State),
            IsSuccess = false,
            ItemTypeID = 0,
            BagDoing = [{decrease, ?ITEM_REDUCE_EXTRA_COMPOSE, DecreaseList2}]
    end,
    {ok, IsSuccess, ItemTypeID, BagDoing, Log}.

-define(MOVE_SPEED_BUFF, 202001).
-define(AUTO_START, 1).
-define(AUTO_STOP, 0).
do_role_auto(RoleID, OpType, State) ->
    if
        OpType =:= ?AUTO_START ->
            role_misc:add_buff(RoleID, #buff_args{buff_id = ?MOVE_SPEED_BUFF, from_actor_id = RoleID});
        true ->
            role_misc:remove_buff(RoleID, ?MOVE_SPEED_BUFF)
    end,
    common_misc:unicast(RoleID, #m_role_auto_toc{op_type = ?AUTO_START}),
    State.

%% 记录
do_role_guide(GuideID, State) ->
    #r_role{role_private_attr = PrivateAttr} = State,
    #r_role_private_attr{guide_id_list = GuideIDList} = PrivateAttr,
    PrivateAttr2 = PrivateAttr#r_role_private_attr{guide_id_list = [GuideID|lists:delete(GuideID, GuideIDList)]},
    State#r_role{role_private_attr = PrivateAttr2}.

do_activation_code(RoleID, Code, State) ->
    case catch check_activation_code(Code, State) of
        {ok, GoodsList} ->
            common_misc:unicast(RoleID, #m_activation_code_toc{}),
            role_misc:create_goods(State, ?ITEM_GAIN_ACTIVATION_CODE, GoodsList);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_activation_code_toc{err_code = ErrCode}),
            State
    end.

check_activation_code(Code, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        account_name = Account,
        uid = UID,
        level = RoleLevel,
        channel_id = ChannelID
    } = RoleAttr,
    ServerID = common_config:get_server_id(),
    AgentID = common_config:get_agent_id(),
    URL = web_misc:get_web_url(activation_code_url),
    Time = time_tool:now(),
    Ticket = web_misc:get_key(Time),
    Body =
    [
        {account_name, Account},
        {uid, UID},
        {code_name, unicode:characters_to_binary(Code)},
        {role_id, RoleID},
        {role_name, RoleName},
        {role_level, RoleLevel},
        {channel_id, ChannelID},
        {agent_id, AgentID},
        {server_id, ServerID},
        {time, Time},
        {ticket, Ticket}
    ],
    case ibrowse:send_req(URL, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 2000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Obj2} = mochijson2:decode(Body2),
            Ret2 = lib_tool:to_integer(proplists:get_value(<<"code">>, Obj2)),
            case Ret2 of
                200 ->
                    Rewards = proplists:get_value(<<"rewards">>, Obj2),
                    GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- lib_tool:string_to_intlist(lib_tool:to_list(Rewards), "|", ",")],
                    {ok, GoodsList};
                101 ->
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_001);
                102 ->
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_002);
                305 ->
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_003);
                202 ->
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_004);
                401 ->
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_005);
                402 ->
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_006);
                301 ->
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_007);
                302 ->
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_008);
                _ ->
                    ?ERROR_MSG("激活码编码异常: ~w", [Ret2]),
                    ?THROW_ERR(?ERROR_ACTIVATION_CODE_001)
            end;
        Error ->
            ?ERROR_MSG("Error: ~w", [Error]),
            ?THROW_ERR(?ERROR_ACTIVATION_CODE_001)
    end.

do_observe(RoleID, DestRoleID) ->
    case db:lookup(?DB_ROLE_ATTR_P, DestRoleID) of
        [_RoleAttr] ->
            case role_misc:is_online(DestRoleID) of
                true ->
                    role_misc:info_role(DestRoleID, {mod, ?MODULE, {other_observe, RoleID}});
                _ ->
                    DataRecord = get_offline_observe(DestRoleID),
                    common_misc:unicast(RoleID, DataRecord)
            end;
        _ ->
            node_interchange_server:cross_observe(RoleID, DestRoleID)
    end.

do_other_observe(OBRoleID, State) ->
    #r_role{
        role_attr = RoleAttr,
        role_private_attr = PrivateAttr,
        role_fight = RoleFight,
        role_relive = RoleRelive,
        role_vip = RoleVip,
        role_guard = RoleGuard,
        role_equip = RoleEquip,
        role_marry = RoleMarry,
        role_pet = RolePet,
        role_title = RoleTitle,
        role_mount = RoleMount,
        role_magic_weapon = RoleMagicWeapon,
        role_god_weapon = RoleGodWeapon
    } = State,
    DataRecord = get_observer_record(RoleAttr, PrivateAttr, RoleFight, RoleRelive, RoleVip, RoleGuard, RoleEquip, RoleMarry, RolePet, RoleTitle, RoleMount, RoleMagicWeapon, RoleGodWeapon),
    common_misc:unicast(OBRoleID, DataRecord).

get_offline_observe(RoleID) ->
    List = [
        {?DB_ROLE_ATTR_P, #r_role_attr{}},
        {?DB_ROLE_PRIVATE_ATTR_P, #r_role_private_attr{}},
        {?DB_ROLE_FIGHT_P, #r_role_fight{base_attr = #actor_fight_attr{}, fight_attr = #actor_fight_attr{}}},
        {?DB_ROLE_RELIVE_P, #r_role_relive{}},
        {?DB_ROLE_VIP_P, #r_role_vip{}},
        {?DB_ROLE_GUARD_P, #r_role_guard{}},
        {?DB_ROLE_EQUIP_P, #r_role_equip{}},
        {?DB_ROLE_PET_P, #r_role_pet{}},
        {?DB_ROLE_TITLE_P, #r_role_title{}},
        {?DB_ROLE_MOUNT_P, #r_role_mount{}},
        {?DB_ROLE_MAGIC_WEAPON_P, #r_role_magic_weapon{}},
        {?DB_ROLE_GOD_WEAPON_P, #r_role_god_weapon{}},
        {?DB_ROLE_MARRY_P, #r_role_marry{}}
    ],
    [RoleAttr, PrivateAttr, RoleFight, RoleRelive, RoleVip, RoleDecoration, RoleEquip, RolePet, RoleTitle, RoleMount,
        RoleMagicWeapon, RoleGodWeapon, RoleMarry] =
        [begin
             case db:lookup(DBKey, RoleID) of
                 [Value] ->
                     Value;
                 _ ->
                     Default
             end
         end || {DBKey, Default} <- List],
    get_observer_record(RoleAttr, PrivateAttr, RoleFight, RoleRelive, RoleVip, RoleDecoration, RoleEquip, RoleMarry, RolePet, RoleTitle, RoleMount, RoleMagicWeapon, RoleGodWeapon).

get_observer_record(RoleAttr, PrivateAttr, RoleFight, RoleRelive, RoleVip, RoleGuard, RoleEquip, RoleMarry, RolePet, RoleTitle, RoleMount, RoleMagicWeapon, RoleGodWeapon) ->
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        level = Level,
        sex = Sex,
        category = Category,
        power = Power,
        skin_list = SkinList,
        ornament_list = OrnamentList} = RoleAttr,
    #r_role_private_attr{charm = Charm} = PrivateAttr,
    #r_role_relive{relive_level = ReliveLevel} = RoleRelive,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    #r_role_guard{guard = Guard, big_guard = BigGuard} = RoleGuard,
    RGuard = ?IF(undefined =:= Guard, #p_kv{id = 0}, #p_kv{id = Guard#p_goods.type_id, val = Guard#p_goods.end_time}),
    LGuard = ?IF(erlang:is_record(BigGuard, p_goods), #p_kv{id = BigGuard#p_goods.type_id, val = BigGuard#p_goods.end_time}, #p_kv{id = BigGuard}),
    #r_role_marry{knot_id = KnotID} = RoleMarry,
    RoleBase = mod_role_fight:make_role_base(RoleFight),
    {FamilyID, FamilyName, FamilyTitle} = mod_role_family:get_observe_args(RoleID),
    #m_role_observe_toc{
        role_id = RoleID,
        role_name = RoleName,
        level = Level,
        vip_level = mod_role_vip:get_vip_level_by_role_vip(RoleVip),
        sex = Sex,
        category = Category,
        relive_level = ReliveLevel,
        family_id = FamilyID,
        family_name = FamilyName,
        family_title = FamilyTitle,
        power = Power,
        skin_list = SkinList,
        role_base = RoleBase,
        equip_list = EquipList,
        charm = Charm,
        title = RoleTitle#r_role_title.cur_title,
        mount = RoleMount#r_role_mount.cur_id,
        magic_weapon = RoleMagicWeapon#r_role_magic_weapon.cur_id,
        god_weapon = RoleGodWeapon#r_role_god_weapon.cur_id,
        pet = RolePet#r_role_pet.cur_id,
        r_guard = RGuard,
        l_guard = LGuard,
        knot_id = KnotID,
        ornament_list = OrnamentList}.

do_cross_observer(Args) ->
    #r_interchange_args{
        to_args = ToRoleID
    } = Args,
    case role_misc:is_online(ToRoleID) of
        true ->
            role_misc:info_role(ToRoleID, {mod, ?MODULE, {cross_observer, Args}});
        _ ->
            DataRecord = get_offline_observe(ToRoleID),
            Args2 = Args#r_interchange_args{call_back_info = DataRecord},
            node_interchange_server:return_req(Args2)
    end.

do_role_cross_observer(Args, State) ->
    #r_role{
        role_attr = RoleAttr,
        role_private_attr = PrivateAttr,
        role_fight = RoleFight,
        role_relive = RoleRelive,
        role_vip = RoleVip,
        role_guard = RoleGuard,
        role_equip = RoleEquip,
        role_marry = RoleMarry,
        role_pet = RolePet,
        role_title = RoleTitle,
        role_mount = RoleMount,
        role_magic_weapon = RoleMagicWeapon,
        role_god_weapon = RoleGodWeapon
    } = State,
    DataRecord = get_observer_record(RoleAttr, PrivateAttr, RoleFight, RoleRelive, RoleVip, RoleGuard, RoleEquip, RoleMarry, RolePet, RoleTitle, RoleMount, RoleMagicWeapon, RoleGodWeapon),
    Args2 = Args#r_interchange_args{call_back_info = DataRecord},
    node_interchange_server:return_req(Args2).

do_add_special_drop([], State) ->
    State;
do_add_special_drop(AddList, State) ->
    DropList = get_data(?EXTRA_KEY_SPECIAL_DROP_LIST, [], State),
    DropList2 = do_add_special_drop2(AddList, DropList),
    mod_map_role:update_role_special_drop(mod_role_dict:get_map_pid(), State#r_role.role_id, DropList2),
    set_data(?EXTRA_KEY_SPECIAL_DROP_LIST, DropList2, State).

do_add_special_drop2([], DropList) ->
    DropList;
do_add_special_drop2([{Index, IsDrop}|R], DropList) ->
    case lists:keytake(Index, #p_kvt.id, DropList) of
        {value, #p_kvt{val = Times, type = DropTimes} = KVT, DropList2} ->
            DropTimes2 = ?IF(IsDrop, DropTimes + 1, DropTimes),
            KVT2 = KVT#p_kvt{val = Times + 1, type = DropTimes2},
            do_add_special_drop2(R, [KVT2|DropList2]);
        _ ->
            DropTimes = ?IF(IsDrop, 1, 0),
            KVT = #p_kvt{id = Index, val = 1, type = DropTimes},
            do_add_special_drop2(R, [KVT|DropList])
    end.

do_item_control(RoleIndexList, State) ->
    mod_map_role:update_role_item_control(mod_role_dict:get_map_pid(), State#r_role.role_id, RoleIndexList),
    set_data(?EXTRA_KEY_ITEM_DROP_LIST, RoleIndexList, State).

do_role_rename(RoleID, RoleName, State) ->
    case catch check_role_rename(RoleName, State) of
        {ok, OldRoleName, BagDoings, State2} ->
            case catch login_server:role_rename({RoleID, OldRoleName, RoleName}) of
                ok ->
                    common_misc:unicast(RoleID, #m_role_rename_toc{name = RoleName}),
                    State3 = mod_role_bag:do(BagDoings, State2),
                    log_role_rename(OldRoleName, RoleName, State3),
                    hook_role:role_rename(RoleName, State3);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_role_rename_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_rename_toc{err_code = ErrCode}),
            State
    end.

check_role_rename(RoleName, State) ->
    ?IF(common_misc:is_rename_ban(?WEB_BAN_ROLE_RENAME), ?THROW_ERR(?ERROR_COMMON_FUNCTION_BAN), ok),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_name = OldRoleName} = RoleAttr,
    ExtraTypeID = common_misc:get_global_int(?GLOBAL_ROLE_RENAME),
    [TypeID, Num] = common_misc:get_global_list(?GLOBAL_ROLE_RENAME),
    BagDoings =
        case catch mod_role_bag:check_num_by_type_id(ExtraTypeID, Num, ?ITEM_REDUCE_ROLE_RENAME, State) of
            BagDoingsT when erlang:is_list(BagDoingsT) ->
                BagDoingsT;
            _ ->
                mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_ROLE_RENAME, State)
        end,
    role_login:check_role_name_valid(RoleName),
    RoleAttr2 = RoleAttr#r_role_attr{role_name = RoleName},
    State2 = State#r_role{role_attr = RoleAttr2},
    {ok, OldRoleName, BagDoings, State2}.

%% call
do_web_role_rename(RoleName, State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = OldRoleName} = RoleAttr} = State,
    case catch login_server:role_rename({RoleID, OldRoleName, RoleName}) of
        ok ->
            common_misc:unicast(RoleID, #m_role_rename_toc{name = RoleName}),
            RoleAttr2 = RoleAttr#r_role_attr{role_name = RoleName},
            State2 = State#r_role{role_attr = RoleAttr2},
            State3 = hook_role:role_rename(RoleName, State2),
            {ok, State3};
        {error, _ErrCode} ->
            {{error, "role name exist"}, State}
    end.

do_package_select(RoleID, GoodsID, Index, State) ->
    case catch check_package_select(GoodsID, Index, State) of
        {ok, BagDoing} ->
            common_misc:unicast(RoleID, #m_package_select_toc{}),
            mod_role_bag:do(BagDoing, State);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_package_select_toc{err_code = ErrCode}),
            State
    end.

check_package_select(GoodsID, Index, State) ->
    {ok, Goods} = mod_role_bag:check_bag_by_id(GoodsID, State),
    #p_goods{bind = IsBind, type_id = TypeID} = Goods,
    case lib_config:find(cfg_select_item, TypeID) of
        [#c_select_item{item_list = ItemList}] ->
            ItemList2 = lib_tool:string_to_intlist(ItemList),
            {ItemID, Num} =
            case erlang:length(ItemList2) >= Index of
                true ->
                    lists:nth(Index, ItemList2);
                _ ->
                    ?THROW_ERR(?ERROR_PACKAGE_SELECT_002)
            end,
            DecreaseDoing = [{decrease, ?ITEM_REDUCE_SELECT_ITEM, [#r_goods_decrease_info{id = GoodsID, num = 1}]}],
            GoodsList = [#p_goods{type_id = ItemID, num = Num, bind = IsBind}],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            CreateDoing = [{create, ?ITEM_GAIN_SELECT_ITEM, GoodsList}],
            BagDoing = DecreaseDoing ++ CreateDoing,
            {ok, BagDoing};
        _ ->
            ?THROW_ERR(?ERROR_PACKAGE_SELECT_001)
    end.

do_comment_status(RoleID, State) ->
    CommentStatus = get_data(?EXTRA_KEY_COMMENT_STATUS, ?COMMENT_STATUS_NOT, State),
    case CommentStatus =:= ?COMMENT_STATUS_NOT of
        true ->
            CommentStatus2 = ?COMMENT_STATUS_HAS,
            common_misc:unicast(RoleID, #m_comment_status_toc{status = CommentStatus2}),
            set_data(?EXTRA_KEY_COMMENT_STATUS, CommentStatus2, State);
        _ ->
            common_misc:unicast(RoleID, #m_comment_status_toc{status = CommentStatus}),
            State
    end.

do_comment_reward(RoleID, State) ->
    case catch check_comment_reward(State) of
        {ok, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_comment_reward_toc{}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_comment_reward_toc{err_code = ErrCode}),
            State
    end.

check_comment_reward(State) ->
    #r_role{role_attr = #r_role_attr{game_channel_id = GameChannelID}} = State,
    CommentStatus = get_data(?EXTRA_KEY_COMMENT_STATUS, ?COMMENT_STATUS_NOT, State),
    ?IF(CommentStatus =:= ?COMMENT_STATUS_HAS, ok, ?THROW_ERR(?ERROR_COMMENT_REWARD_001)),
    case lib_config:find(cfg_comment, GameChannelID) of
        [GoodsString] ->
            ok;
        _ ->
            GoodsString = ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end,
    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind} <- common_misc:get_item_reward(GoodsString)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_COMMENT_REWARD, GoodsList}],
    State2 = set_data(?EXTRA_KEY_COMMENT_STATUS, ?COMMENT_STATUS_REWARD, State),
    {ok, BagDoings, State2}.

%% 资源下载状态
do_download_reward(RoleID, State) ->
    case catch check_download_reward(State) of
        {ok, GoodsList, State2} ->
            State3 = role_misc:create_goods(State2, ?ITEM_GAIN_DOWNLOAD_STATUS, GoodsList),
            common_misc:unicast(RoleID, #m_download_reward_toc{is_reward = true}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_download_reward_toc{err_code = ErrCode}),
            State
    end.

check_download_reward(State) ->
    IsReward = get_data(?EXTRA_KEY_DOWNLOAD_STATUS, false, State),
    ?IF(IsReward, ?THROW_ERR(?ERROR_DOWNLOAD_REWARD_001), ok),
    GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_global_string_list(?GLOBAL_DOWNLOAD_REWARD)],
    State2 = set_data(?EXTRA_KEY_DOWNLOAD_STATUS, true, State),
    {ok, GoodsList, State2}.

do_window_open(RoleID, Type, State) ->
    WindowOpenList = get_data(?EXTRA_KEY_WIND_OPEN_LIST, [], State),
    WindowOpenList2 = [Type|lists:delete(Type, WindowOpenList)],
    common_misc:unicast(RoleID, #m_window_open_toc{window_open_list = WindowOpenList2}),
    set_data(?EXTRA_KEY_WIND_OPEN_LIST, WindowOpenList2, State).

log_world_boss_pick(MonsterTypeID, GoodsList, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{role_name = RoleName, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    Log =
    #log_world_boss_pick{
        role_id = RoleID,
        role_name = unicode:characters_to_binary(RoleName),
        boss_type_id = MonsterTypeID,
        pick_goods_list = common_misc:to_goods_string(GoodsList),
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log).

get_compose_log(TypeID, GoodsList, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_role_compose{
        role_id = RoleID,
        type_id = TypeID,
        goods_list = common_misc:to_goods_string(GoodsList),
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_confine_log(Confine, Confine2, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_role_confine{
        role_id = RoleID,
        old_confine_id = Confine,
        new_confine_id = Confine2,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

log_role_rename(OldRoleName, RoleName, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        level = RoleLevel,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    Log =
    #log_role_rename{
        role_id = RoleID,
        old_name = unicode:characters_to_binary(OldRoleName),
        new_name = unicode:characters_to_binary(RoleName),
        role_level = RoleLevel,
        channel_id = ChannelID,
        game_channel_id = GameChannelID},
    mod_role_dict:add_background_logs(Log).

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_data(Key, Value, State) ->
    #r_role{role_extra = RoleExtra} = State,
    #r_role_extra{data = Data} = RoleExtra,
    Data2 = lists:keystore(Key, 1, Data, {Key, Value}),
    RoleExtra2 = RoleExtra#r_role_extra{data = Data2},
    State#r_role{role_extra = RoleExtra2}.

get_data(Key, Default, State) ->
    #r_role{role_extra = #r_role_extra{data = Data}} = State,
    case lists:keyfind(Key, 1, Data) of
        {_, Value} ->
            Value;
        _ ->
            Default
    end.

%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 十二月 2018 16:04
%%%-------------------------------------------------------------------
-module(mod_role_marry).
-author("laijichang").
-include("proto/mod_role_marry.hrl").
-include("proto/mod_role_item.hrl").
-include("proto/mod_map_marry.hrl").
-include("proto/mod_role_map.hrl").
-include("marry.hrl").
-include("bg_act.hrl").
-include("role.hrl").
-include("act.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    zero/1,
    handle/2
]).

-export([
    add_knot/4,
    fireworks/4,
    role_rename/1,
    level_up/3
]).

-export([
    is_able/1,
    has_couple/1,
    check_enter_feast/1,
    get_born_pos/2
]).

-export([
    gm_feast_heat/2,
    gm_bow_time/2
]).

init(#r_role{role_id = RoleID, role_marry = undefined} = State) ->
    RoleMarry = #r_role_marry{role_id = RoleID},
    init(State#r_role{role_marry = RoleMarry});
init(State) ->
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    #r_marry_data{couple_id = CoupleID} = marry_misc:get_marry_data(RoleID),
    CoupleName = ?IF(?HAS_COUPLE(CoupleID), common_role_data:get_role_name(CoupleID), ""),
    RoleMarry2 = RoleMarry#r_role_marry{couple_id = CoupleID, couple_name = CoupleName},
    State#r_role{role_marry = RoleMarry2}.

calc(State) ->
    #r_role{role_marry = RoleMarry} = State,
    #r_role_marry{couple_id = CoupleID, knot_id = KnotID} = RoleMarry,
    case KnotID > 0 of
        true ->
            [#c_marry_knot{base_props = BaseProps, extra_props = ExtraProps}] = lib_config:find(cfg_marry_knot, KnotID),
            BaseAttr = common_misc:get_attr_by_kv([ #p_kv{id = ID, val = Val}|| {ID, Val}<- lib_tool:string_to_intlist(BaseProps)]),
            Attr =
                case ?HAS_COUPLE(CoupleID) of
                    true ->
                        LevelAttr = mod_role_level:get_level_attr(State),
                        ExtraAttr = get_level_attr(lib_tool:string_to_intlist(ExtraProps), LevelAttr, #actor_cal_attr{}),
                        common_misc:sum_calc_attr2(BaseAttr, ExtraAttr);
                    _ ->
                        BaseAttr
                end,
            mod_role_fight:get_state_by_kv(State, ?CALC_MARRY_KNOT, Attr);
        _ ->
            State
    end.

get_level_attr([], _LevelAttr, Attr) ->
    Attr;
get_level_attr([{Key, Val}|R], LevelAttr, Attr) ->
    #actor_cal_attr{
        max_hp = {MaxHp, MaxHpRate},
        defence = {Defence, DefenceRate},
        attack = {Attack, AttackRate},
        arp = {Arp, ArpRate}
    } = Attr,
    #actor_cal_attr{
        max_hp = {LevelHp, _},
        attack = {LevelAttack, _},
        defence = {LevelDefence, _},
        arp = {LevelArp, _}
    } = LevelAttr,
    if
        Key =:= ?ATTR_BASE_ARP_RATE ->
            Attr2 = Attr#actor_cal_attr{arp =  {LevelArp * Val/?RATE_10000 + Arp, ArpRate}};
        Key =:= ?ATTR_BASE_HP_RATE ->
            Attr2 = Attr#actor_cal_attr{max_hp = {LevelHp * Val/?RATE_10000 + MaxHp, MaxHpRate}};
        Key =:= ?ATTR_BASE_DEF_RATE ->
            Attr2 = Attr#actor_cal_attr{defence =  {LevelDefence * Val/?RATE_10000 + Defence, DefenceRate}};
        Key =:= ?ATTR_BASE_ATTACK_RATE ->
            Attr2 = Attr#actor_cal_attr{attack =  {LevelAttack * Val/?RATE_10000 + Attack, AttackRate}};
        true ->
            Attr2 = Attr
    end,
    get_level_attr(R, LevelAttr, Attr2).

zero(#r_role{role_marry = undefined} = State) ->
    State;
zero(State) ->
    online(State).

online(State) ->
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    #r_role_marry{
        couple_id = CoupleID,
        knot_id = KnotID,
        knot_exp = KnotExp,
        marry_title_ids = MarryTitleIDs,
        act_marry_three_life = ActMarryThreeLife,
        three_life_achieve = ThreeLifeAchieve
    } = RoleMarry,
    #r_marry_data{
        tree_end_time = TreeEndTime,
        tree_active_reward = IsActive,
        tree_daily_time = TreeDailyTime,
        be_propose_list = BeProposeList
    } = marry_misc:get_marry_data(RoleID),
    #r_marry_data{
        tree_end_time = CoupleTreeEndTime
    } = marry_misc:get_marry_data(CoupleID),
    #r_marry_share{
        marry_time = MarryTime,
        feast_start_time = FeastStartTime,
        feast_times = FeastTimes,
        extra_guest_num = ExtraGuestNum,
        is_buy_join = IsBuyJoin,
        guest_list = GuestList,
        apply_guest_list = ApplyGuestList
    } = marry_misc:get_share_marry(marry_misc:get_share_id(RoleID, CoupleID)),
    DataRecord = #m_marry_info_toc{
        tree_end_time = TreeEndTime,
        tree_active_reward = IsActive,
        tree_daily_time = TreeDailyTime,
        couple_tree_end_time = CoupleTreeEndTime,
        knot_id = KnotID,
        knot_exp = KnotExp,
        couple_id = CoupleID,
        marry_time = MarryTime,
        marry_title_ids = MarryTitleIDs
    },
    common_misc:unicast(RoleID, DataRecord),
    DataRecord2 = #m_marry_feast_info_toc{
        feast_start_time = FeastStartTime,
        feast_times = FeastTimes,
        extra_guest_num = ExtraGuestNum,
        is_buy_join = IsBuyJoin,
        guest_list = marry_misc:trans_to_p_guest(GuestList),
        apply_guest_list = marry_misc:trans_to_p_apply_guest(ApplyGuestList)
    },
    common_misc:unicast(RoleID, DataRecord2),
    [ begin
          #r_marry_data{propose_type = ProposeType, propose_end_time = EndTime} = mod_marry_data:get_marry_data(ProposeID),
          ProposeRecord = #m_marry_propose_toc{
              from_role_id = ProposeID,
              from_role_name = common_role_data:get_role_name(ProposeID),
              type = ProposeType,
              propose_end_time = EndTime},
          common_misc:unicast(RoleID, ProposeRecord)
      end|| ProposeID <- BeProposeList],
    ?IF(mod_role_data:get_role_level(State) >= ?FEAST_MIN_LEVEL, marry_server:role_online(RoleID), ok),

    case mod_role_act:is_act_open2(?ACT_MARRY_THREE_LIFE, State) of  %% 三生三世活动信息的推送
        true ->
            common_misc:unicast(RoleID, #m_act_marry_three_life_info_toc{act_marry_info = ActMarryThreeLife, marry_three_life_achieve = ThreeLifeAchieve});
        _ ->
            ok
    end,

    update_marry_title(State).

role_rename(State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = RoleName}, role_marry = RoleMarry} = State,
    #r_role_marry{couple_id = CoupleID} = RoleMarry,
    ?IF(?HAS_COUPLE(CoupleID), role_misc:info_role(CoupleID, {mod, ?MODULE, {couple_rename, RoleID, RoleName}}), ok),
    ok.

level_up(OldLevel, NewLevel, State) ->
    ?IF(OldLevel < ?FEAST_MIN_LEVEL andalso ?FEAST_MIN_LEVEL =< NewLevel, marry_server:role_online(State#r_role.role_id), ok).

add_knot(TypeID, Num, AddExp, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_marry = RoleMarry} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #r_role_marry{knot_id = KnotID, knot_exp = KnotExp} = RoleMarry,
    case lib_config:find(cfg_marry_knot, KnotID + 1) of
        [_Config] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_ITEM_USE_013)
    end,
    {NewKnotID, NewExp} = add_knot2(KnotID, KnotExp, AddExp),
    common_misc:unicast(RoleID, #m_marry_knot_update_toc{knot_id = NewKnotID, knot_exp = NewExp}),
    RoleMarry2 = RoleMarry#r_role_marry{knot_id = NewKnotID, knot_exp = NewExp},
    Log = #log_marry_knot{
        role_id = RoleID,
        item_type_id = TypeID,
        item_num = Num,
        add_exp = AddExp,
        old_knot_id = KnotID,
        new_knot_id = NewKnotID,
        new_exp = NewExp,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log),
    State2 = State#r_role{role_marry = RoleMarry2},
    ?IF(KnotID =/= NewKnotID, update_marry_title(mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_MARRY_KNOT, NewKnotID)), State2).

add_knot2(KnotID, KnotExp, AddExp) ->
    KnotID2 = KnotID + 1,
    case lib_config:find(cfg_marry_knot, KnotID2) of
        [#c_marry_knot{need_exp = NeedExp}] ->
            KnotExpT = KnotExp + AddExp,
            case KnotExpT >= NeedExp of
                true ->
                    KnotExp2 = KnotExpT - NeedExp,
                    add_knot2(KnotID2, KnotExp2, 0);
                _ ->
                    {KnotID, KnotExpT}
            end;
        _ ->
            {KnotID, 0}
    end.

%% 放烟火
fireworks(TypeID, EffectArgs, Num, State) ->
    MapID = mod_role_data:get_role_map_id(State),
    ?IF(?IS_MAP_MARRY_FEAST(MapID), ok, ?THROW_ERR(?ERROR_ITEM_USE_014)),
    [AddHeat, AddExp] = string:tokens(EffectArgs, ","),
    AddHeat2 = lib_tool:to_integer(AddHeat),
    AddExp2 = lib_tool:to_integer(AddExp),
    #c_item{name = ItemName} = mod_role_item:get_item_config(TypeID),
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = RoleName}} = State,
    mod_map_marry:role_fireworks(mod_role_dict:get_map_pid(), RoleID, RoleName, TypeID, ItemName, AddHeat2 * Num),
    mod_role_level:do_add_exp(State, AddExp2, ?EXP_ADD_FROM_MARRY_FIREWORKS).

gm_feast_heat(AddHeat, State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = RoleName}} = State,
    [_ConfigHeat1, _ConfigHeat2, ConfigHeat3] = common_misc:get_global_list(?GLOBAL_MARRY_WISH),
    AddHeat2 = erlang:min(AddHeat, ConfigHeat3),
    mod_map_marry:role_fireworks(mod_role_dict:get_map_pid(), RoleID, RoleName, 31040, "GM", AddHeat2),
    State.

gm_bow_time(RemainTime, State) ->
    #r_role{role_id = RoleID} = State,
    mod_map_marry:gm_bow_time(mod_role_dict:get_map_pid(), RoleID, RemainTime),
    State.


update_marry_title(State) ->
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    #r_role_marry{
        couple_id = CoupleID,
        knot_id = KnotID,
        marry_title_ids = MarryTitleIDs} = RoleMarry,
    case ?HAS_COUPLE(CoupleID) of
        true ->
            #r_world_friend{friend_list = FriendList} = world_friend_server:get_role_info(RoleID),
            Friendly =
                case lists:keyfind(CoupleID, #r_friend.role_id, FriendList) of
                    #r_friend{friendly = FriendlyT} ->
                        FriendlyT;
                    _ ->
                        0
                end,
            {NewMarryTitleIDs, AddTitles} = get_marry_titles(Friendly, KnotID, MarryTitleIDs),
            case AddTitles =/= [] of
                true ->
                    common_misc:unicast(RoleID, #m_marry_title_update_toc{marry_title_ids = NewMarryTitleIDs}),
                    RoleMarry2 = RoleMarry#r_role_marry{marry_title_ids = NewMarryTitleIDs},
                    State2 = State#r_role{role_marry = RoleMarry2},
                    lists:foldl(
                        fun(TitleID, StateAcc) ->
                            mod_role_title:add_title(0, TitleID, StateAcc)
                    end, State2, AddTitles);
                _ ->
                    State
            end;
        _ ->
            State
    end.

handle({get_marry, CoupleID, CoupleName, Type}, State) ->
    do_get_marry(CoupleID, CoupleName, Type, State);
handle({offline_propose_accept, Type}, State) ->
    do_propose_achieve(Type, State);
handle(divorce, State) ->
    do_divorce(State);
handle({couple_rename, CoupleID, CoupleName}, State) ->
    do_couple_rename(CoupleID, CoupleName, State);
handle({online_couple_info, OBRoleID}, State) ->
    do_online_couple_info(OBRoleID, State),
    State;
handle(marry_friendly_change, State) ->
    update_marry_title(State);
handle({#m_marry_couple_tos{}, RoleID, _PID}, State) ->
    do_couple_info(RoleID, State);
handle({#m_marry_propose_tos{propose_id = ProposeID, type = Type}, RoleID, _PID}, State) ->
    do_propose(RoleID, ProposeID, Type, State);
handle({#m_marry_propose_reply_tos{to_propose_id = SrcRoleID, answer_type = AnswerType}, RoleID, _PID}, State) ->
    do_propose_reply(RoleID, SrcRoleID, AnswerType, State);
handle({#m_marry_tree_request_tos{}, RoleID, _PID}, State) ->
    do_tree_request(RoleID, State);
handle({#m_marry_tree_buy_tos{}, RoleID, _PID}, State) ->
    do_tree_buy(RoleID, State);
handle({#m_marry_tree_reward_tos{type = Type}, RoleID, _PID}, State) ->
    do_tree_reward(RoleID, Type, State);
handle({#m_marry_copy_request_tos{}, RoleID, _PID}, State) ->
    do_copy_request(RoleID, State);
handle({#m_marry_add_guest_tos{add_num = AddNum}, RoleID, _PID}, State) ->
    do_add_guest(RoleID, AddNum, State);
handle({#m_marry_map_wish_tos{index_id = IndexID, to_role_id = ToRoleID}, RoleID, _PID}, State) ->
    do_wish(RoleID, IndexID, ToRoleID, State);
handle({#m_marry_buy_join_tos{}, RoleID, _PID}, State) ->
    do_buy_join(RoleID, State);
handle({#m_act_marry_three_life_achieve_tos{}, RoleID, _PID}, State) ->  % 处理三生三世活动客户端返回给服务器的信息
    do_act_marry_three_life(RoleID, State);
handle({#m_act_marry_three_life_rank_info_tos{}, RoleID, _PID}, State) ->  % T 三生三世活动亲密度排行
    do_act_marry_three_life_rank(RoleID, State);
handle({#m_marry_fairy_tos{goods_list = GoodsIDList, text = Text}, RoleID, _PID}, State) ->
    do_marry_fairy(RoleID, GoodsIDList, Text, State);
handle(Info, State) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]),
    State.

do_get_marry(CoupleID, CoupleName, Type, State) ->  % T 传入的时候增加了一个Type字段 用于三生三世开服活动 用于鉴别哪类的提亲
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    RoleMarry2 = RoleMarry#r_role_marry{couple_id = CoupleID, couple_name = CoupleName},
    State2 = State#r_role{role_marry = RoleMarry2},
    mod_map_role:update_role_couple(mod_role_dict:get_map_pid(), RoleID, CoupleID, CoupleName),
    State3 = mod_role_friend:update(State2),
    State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_MARRY_CHANGE, 1),
    do_propose_achieve(Type, State4).

%% 在线、离线都会触发
do_propose_achieve(Type, State) ->
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    #r_role_marry{act_marry_three_life = ActMarryThreeLife, three_life_achieve = ThreeLifeAchieve} = RoleMarry,
    State2 =
        case mod_role_act:is_act_open2(?ACT_MARRY_THREE_LIFE, State) of
            true ->
                {NewActMarryThreeLife, NewThreeLifeAchieve} = do_marry_act(Type, ActMarryThreeLife,ThreeLifeAchieve),
                common_misc:unicast(RoleID, #m_act_marry_three_life_info_toc{act_marry_info = NewActMarryThreeLife, marry_three_life_achieve = NewThreeLifeAchieve}),
                RoleMarry2 = RoleMarry#r_role_marry{act_marry_three_life = NewActMarryThreeLife, three_life_achieve = NewThreeLifeAchieve},
                State#r_role{role_marry = RoleMarry2};
            _ ->
                State
        end,
    hook_role:marry(Type, State2).

do_marry_act(Type, ActMarryThreeLife, ThreeLifeAchieve) ->   %% T 三生三世活动 ：提亲成功以后的活动状态修改
    NewActMarryLife =
        case lists:member(Type, ActMarryThreeLife) of
            true ->
                ActMarryThreeLife;
            _ ->
                [Type|ActMarryThreeLife]
        end,
    AchieveList = [1,2,3],
    Achieve = AchieveList -- NewActMarryLife,
    NewThreeLifeAchieve = ?IF(ThreeLifeAchieve =:= 2, 2, ?IF(Achieve =:= [], 1, 0)),
    {NewActMarryLife, NewThreeLifeAchieve}.

do_divorce(State) ->
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    CoupleID = 0,
    CoupleName = "",
    RoleMarry2 = RoleMarry#r_role_marry{couple_id = CoupleID, couple_name = CoupleName},
    State2 = State#r_role{role_marry = RoleMarry2},
    State3 = online(State2),
    State4 = mod_role_friend:update(State3),
    mod_map_role:update_role_couple(mod_role_dict:get_map_pid(), RoleID, CoupleID, CoupleName),
    State5 = mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_UPDATE_MARRY_CHANGE, 0),
    hook_role:divorce(State5).

do_couple_rename(CoupleID, CoupleName, State) ->
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    RoleMarry2 = RoleMarry#r_role_marry{couple_name = CoupleName},
    State2 =  State#r_role{role_marry = RoleMarry2},
    mod_map_role:update_role_couple(mod_role_dict:get_map_pid(), RoleID, CoupleID, CoupleName),
    State2.

do_couple_info(RoleID, State) ->
    #r_role{role_marry = #r_role_marry{couple_id = CoupleID}} = State,
    case ?HAS_COUPLE(CoupleID) of
        true ->
            case role_misc:is_online(CoupleID) of
                true ->
                    role_misc:info_role(CoupleID, {mod, ?MODULE, {online_couple_info, RoleID}});
                _ ->
                    do_offline_couple_info(RoleID, CoupleID)
            end;
        _ ->
            common_misc:unicast(RoleID, #m_marry_couple_toc{err_code = ?ERROR_MARRY_COUPLE_001})
    end,
    State.

do_online_couple_info(OBRoleID, State) ->
    #r_role{
        role_attr = RoleAttr,
        role_vip = RoleVip
    } = State,
    do_couple_info2(OBRoleID, RoleAttr, RoleVip).

do_offline_couple_info(OBRoleID, RoleID) ->
    [RoleAttr] = db:lookup(?DB_ROLE_ATTR_P, RoleID),
    [RoleVip] = db:lookup(?DB_ROLE_VIP_P, RoleID),
    do_couple_info2(OBRoleID, RoleAttr, RoleVip).

do_couple_info2(OBRoleID, RoleAttr, RoleVIP) ->
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        level = Level,
        sex = Sex,
        category = Category,
        skin_list = SkinList,
        ornament_list = OrnamentList} = RoleAttr,
    DataRecord =
        #m_marry_couple_toc{
            role_id = RoleID,
            role_name = RoleName,
            level = Level,
            vip_level = mod_role_vip:get_vip_level_by_role_vip(RoleVIP),
            sex = Sex,
            category = Category,
            skin_list = SkinList,
            ornament_list = OrnamentList},
    common_misc:unicast(OBRoleID, DataRecord).

do_propose(RoleID, ProposeID, Type, State) ->  % T 提亲
    case catch check_propose(ProposeID, Type, State) of
        {ok, AssetDoings, RoleName} ->
            case mod_marry_propose:propose(RoleID, ProposeID, Type) of
                {ok, ProposeEndTime} ->
                    DataRecord = #m_marry_propose_toc{
                        from_role_id = RoleID,
                        from_role_name = RoleName,
                        type = Type,
                        propose_end_time = ProposeEndTime},
                    common_misc:unicast(RoleID, DataRecord),
                    common_misc:unicast(ProposeID, DataRecord),
                    mod_role_asset:do(AssetDoings, State);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_marry_propose_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_propose_toc{err_code = ErrCode}),
            State
    end.

check_propose(ProposeID, Type, State) ->
    #r_role_attr{sex = DestSex, level = DestLevel} = common_role_data:get_role_attr(ProposeID),
    #r_role{role_attr = #r_role_attr{role_name = RoleName, sex = MySex, level = MyLevel}} = State,
    ?IF(DestSex =/= MySex, ok, ?THROW_ERR(?ERROR_MARRY_PROPOSE_001)),
    MinLevel = common_misc:get_global_int(?GLOBAL_PROPOSE_LEVEL),
    ?IF(DestLevel >= MinLevel andalso MyLevel >= MinLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(role_misc:is_online(ProposeID), ok, ?THROW_ERR(?ERROR_MARRY_PROPOSE_002)),
    [#c_marry_propose{
        consume_type = ConsumeType,
        consume_fee = ConsumeFee
    }] = lib_config:find(cfg_marry_propose, Type),
    AssetDoings = mod_role_asset:check_asset_by_type(ConsumeType, ConsumeFee, ?ASSET_GOLD_REDUCE_FROM_MARRY_PROPOSE, State),
    {ok, AssetDoings, RoleName}.

do_propose_reply(RoleID, SrcRoleID, AnswerType, State) ->
    mod_marry_propose:propose_reply(RoleID, SrcRoleID, AnswerType),
    State.

%% 请求对方购买姻缘树
do_tree_request(RoleID, State) ->
    case catch check_tree_request(RoleID, State) of
        {ok, CoupleID} ->
            DataRecord = #m_marry_tree_request_toc{from_role_id = RoleID},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(CoupleID, DataRecord),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_tree_request_toc{err_code = ErrCode}),
            State
    end.

check_tree_request(RoleID, State) ->
    #r_role{role_marry = #r_role_marry{couple_id = CoupleID}} = State,
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_TREE_REQUEST_001)),
    #r_marry_data{tree_end_time = TreeEndTime} = mod_marry_data:get_marry_data(RoleID),
    ?IF(mod_marry_tree:is_marry_tree_end(TreeEndTime), ok, ?THROW_ERR(?ERROR_MARRY_TREE_REQUEST_002)),
    ?IF(role_misc:is_online(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_TREE_REQUEST_003)),
    {ok, CoupleID}.

%% 为对方购买姻缘树
do_tree_buy(RoleID, State) ->
    case catch check_tree_buy(State) of
        {ok, AssetDoing} ->
            case mod_marry_tree:tree_buy(RoleID) of
                {ok, TreeEndTime} ->
                    #r_role{role_marry = #r_role_marry{couple_name = CoupleName}} = State,
                    common_broadcast:send_world_common_notice(?NOTICE_MARRY_TREE_BUY, [mod_role_data:get_role_name(State), CoupleName]),
                    common_misc:unicast(RoleID, #m_marry_tree_buy_toc{couple_tree_end_time = TreeEndTime}),
                    mod_role_asset:do(AssetDoing, State);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_marry_tree_buy_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_tree_buy_toc{err_code = ErrCode}),
            State
    end.

check_tree_buy(State) ->
    NeedGold = common_misc:get_global_int(?GLOBAL_MARRY_TREE),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_MARRY_TREE, State),
    {ok, AssetDoing}.

%% 领取激活奖励
do_tree_reward(RoleID, Type, State) ->
    case mod_marry_tree:tree_reward(RoleID, Type) of
        {ok, GoodsList, IsActive, DailyTime} ->
            common_misc:unicast(RoleID, #m_marry_tree_reward_toc{type = Type, tree_active_reward = IsActive, tree_daily_time = DailyTime}),
            role_misc:create_goods(State, ?ITEM_GAIN_MARRY_TREE_REWARD, GoodsList);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_tree_reward_toc{err_code = ErrCode}),
            State
    end.

%%%===================================================================
%%% 副本
%%%===================================================================
%% 请求购买次数
do_copy_request(RoleID, State) ->
    case catch check_copy_request(State) of
        {ok, CoupleID} ->
            DataRecord = #m_marry_copy_request_toc{from_role_id = RoleID},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(CoupleID, DataRecord),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_copy_request_toc{err_code = ErrCode}),
            State
    end.

check_copy_request(State) ->
    #r_role{role_marry = #r_role_marry{couple_id = CoupleID}} = State,
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_COPY_REQUEST_001)),
    ?IF(role_misc:is_online(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_COPY_REQUEST_002)),
    {ok, CoupleID}.


%%%===================================================================
%%% 婚礼
%%%===================================================================
do_add_guest(RoleID, AddNum, State) ->
    case catch check_add_guest(AddNum, State) of
        {ok, AssetDoings} ->
            case catch mod_marry_feast:add_guest_num(RoleID, AddNum) of
                {ok, CoupleID, ExtraGuestNum} ->
                    common_misc:unicast(RoleID, #m_marry_add_guest_toc{extra_guest_num = ExtraGuestNum}),
                    common_misc:unicast(CoupleID, #m_marry_add_guest_toc{extra_guest_num = ExtraGuestNum}),
                    mod_role_asset:do(AssetDoings, State);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_marry_add_guest_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_add_guest_toc{err_code = ErrCode}),
            State
    end.

check_add_guest(AddNum, State) ->
    ?IF(AddNum > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    [_DefaultNum, _MaxExtraNum, UseGold] = common_misc:get_global_list(?GLOBAL_MARRY_FEAST_APPOINT),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, UseGold * AddNum, ?ASSET_GOLD_REDUCE_FROM_MARRY_ADD_GUEST, State),
    {ok, AssetDoings}.

do_wish(RoleID, IndexID, ToRoleID, State) ->
    case catch check_wish(RoleID, IndexID, ToRoleID, State) of
        {ok, AssetDoing, BagDoing, CallBack, WishLog} ->
            case catch mod_map_marry:role_wish(mod_role_dict:get_map_pid(), ToRoleID, WishLog) of
                ok ->
                    common_misc:unicast(RoleID, #m_marry_map_wish_toc{}),
                    State2 = mod_role_asset:do(AssetDoing, mod_role_bag:do(BagDoing, State)),
                    CallBack(State2);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_marry_map_wish_toc{err_code = ErrCode})
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_map_wish_toc{err_code = ErrCode})
    end.

check_wish(RoleID, IndexID, ToRoleID, State) ->
    #r_role{role_attr = #r_role_attr{role_name = RoleName}} = State,
    [#c_marry_wish{type = Type, val = Val}] = lib_config:find(cfg_marry_wish, IndexID),
    ?IF(?IS_MAP_MARRY_FEAST(mod_role_data:get_role_map_id(State)), ok, ?THROW_ERR(?ERROR_MARRY_MAP_WISH_001)),
    ?IF(RoleID =:= ToRoleID, ?THROW_ERR(?ERROR_MARRY_MAP_WISH_002), ok),
    case Type of
        1 -> %% 元宝
            AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Val, ?ASSET_GOLD_REDUCE_FROM_MARRY_WISH, State),
            BagDoing = [],
            CallBack = fun(StateAcc) -> role_misc:give_goods(ToRoleID, ?ASSET_GOLD_ADD_FROM_MARRY_WISH, [#p_goods{type_id = ?ITEM_GOLD, num = Val}]), StateAcc end;
        _ ->
            AssetDoing = [],
            BagDoing = mod_role_bag:check_num_by_type_id(Val, 1, ?ITEM_REDUCE_MARRY_WISH, State),
            CallBack = fun(StateAcc) -> mod_role_flower:do_flower_send2(RoleID, ToRoleID, Val, 1, false, false, StateAcc) end
    end,
    WishLog = #p_marry_wish{
        wish_time = time_tool:now(),
        role_id = RoleID,
        role_name = RoleName,
        to_role_id = ToRoleID,
        to_role_name = common_role_data:get_role_name(ToRoleID),
        index_id = IndexID
    },
    {ok, AssetDoing, BagDoing, CallBack, WishLog}.

do_buy_join(RoleID, State) ->
    case catch check_buy_join(State) of
        {ok, AssetDoing} ->
            case catch mod_marry_feast:buy_join(RoleID) of
                ok ->
                    mod_role_asset:do(AssetDoing, State);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_marry_buy_join_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_buy_join_toc{err_code = ErrCode}),
            State
    end.

check_buy_join(State) ->
    NeedGold = common_misc:get_global_int(?GLOBAL_MARRY_BUY_JOIN),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_MARRY_BUY_JOIN, State),
    {ok, AssetDoing}.

get_born_pos(MapID, State) ->
    #r_role{role_attr = #r_role_attr{sex = Sex}} = State,
    {ok, BornPos} = map_misc:get_born_pos(#r_born_args{map_id = MapID, sex = Sex}),
    BornPos.

is_able(State) ->
    mod_marry_feast:check_enter_feast(State#r_role.role_id) =:= true.

has_couple(State) ->
    #r_role{role_marry = RoleMarry} = State,
    #r_role_marry{couple_id = CoupleID} = RoleMarry,
    ?HAS_COUPLE(CoupleID).

check_enter_feast(RoleID) ->
    case catch mod_marry_feast:check_enter_feast(RoleID) of
        true ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_026)
    end.

get_marry_titles(Friendly, KnotID, MarryTitleIDs) ->
    get_marry_titles2(cfg_marry_title:list(), Friendly, KnotID, MarryTitleIDs, []).

get_marry_titles2([], _Friendly, _KnotID, MarryTitleIDs, AddTitles) ->
    {MarryTitleIDs, AddTitles};
get_marry_titles2([{ID, Config}|R], Friendly, KnotID, MarryTitleIDs, AddTitles) ->
    case lists:member(ID, MarryTitleIDs) of
        true ->
            get_marry_titles2(R, Friendly, KnotID, MarryTitleIDs, AddTitles);
        _ ->
            #c_marry_title{
                title_id = TitleID,
                friendly = NeedFriendly,
                knot_id = NeedKnotID} = Config,
            case Friendly >= NeedFriendly andalso KnotID >= NeedKnotID of
                true ->
                    get_marry_titles2(R, Friendly, KnotID, [ID|MarryTitleIDs], [TitleID|AddTitles]);
                _ ->
                    {MarryTitleIDs, AddTitles}
            end
    end.


do_act_marry_three_life(RoleID, State) ->
    case catch check_act_marry_three_life(RoleID, State) of
        {ok, BagDoings, State2} ->   %%
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_act_marry_three_life_achieve_toc{}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_marry_three_life_achieve_toc{err_code = ErrCode}),
            State
    end.

check_act_marry_three_life(RoleID, State) ->
    ?IF(mod_role_act:is_act_open2(?ACT_MARRY_THREE_LIFE, State), ok, ?THROW_ERR(?ACT_STATUS_CLOSE)),
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    #r_role_marry{act_marry_three_life = ActMarryThreeLife, three_life_achieve = ThreeLifeAchieve} = RoleMarry,
    ?IF(ThreeLifeAchieve =:= 2, ?THROW_ERR(?REWARD_STATUS_GET), ok),
    AchieveList = [1,2,3],
    Achieve = AchieveList -- ActMarryThreeLife,
    NewThreeLifeAchieve = ?IF(Achieve =:= [] andalso ThreeLifeAchieve =:= 1, 2, ThreeLifeAchieve),
    GoodsList = [#p_goods{type_id = 220049, num = 1}], %% 三生三世的称号
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_MARRY_THREE_LIFE, GoodsList}],
    RoleMarry2 = RoleMarry#r_role_marry{three_life_achieve = NewThreeLifeAchieve},
    State2 = State#r_role{role_marry = RoleMarry2},
    {ok, BagDoings, State2}.


do_marry_fairy(RoleID, GoodsIDList, Text, State) ->
    case catch check_marry_fairy(RoleID, GoodsIDList, Text, State) of
        {ok, BagDoing, State} ->
            State2 = mod_role_bag:do(BagDoing, State),
            common_misc:unicast(RoleID, #m_marry_fairy_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_fairy_toc{err_code = ErrCode}),
            State
    end.

check_marry_fairy(RoleID, GoodsIDList, Text, State) ->
    #r_role{role_attr = RoleAttr, role_private_attr = PrivateAttr} = State,
    #r_role_attr{role_name = RoleName} = RoleAttr,
    #r_role_private_attr{create_time = CreateTime} = PrivateAttr,
    Now = time_tool:now(),
    CreateTime2 = time_tool:midnight(CreateTime),
    DiffTime = Now - CreateTime2,
    #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
    ShareID = marry_misc:get_share_id(RoleID, CoupleID),
    #r_marry_share{marry_time = MarryTime} = mod_marry_data:get_share_marry(ShareID),
    List = common_misc:get_global_string_list(?GLOBAL_ACT_MARRY_CREATE_TIME),
    [{IsGreatCreateTime, CoolDownTime}, {IsGreatCreateTime2, CoolDownTime2}] = List,
    ?IF(IsGreatCreateTime =/= IsGreatCreateTime2, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR), ok),
    ?IF(string:len(Text) > 50, ?THROW_ERR(?ERROR_MARRY_FAIRY_002), ok),
    ?IF(erlang:length(GoodsIDList) < 1, ?THROW_ERR(?ERROR_MARRY_FAIRY_001), ok),
    ?IF(erlang:length(GoodsIDList) > 6, ?THROW_ERR(?ERROR_MARRY_FAIRY_003), ok),
    case DiffTime =< ?ONE_DAY * IsGreatCreateTime of
        true ->
            ?IF(?HAS_COUPLE(CoupleID) andalso Now - MarryTime > CoolDownTime * ?AN_HOUR, ok, ?THROW_ERR(?ERROR_MARRY_FAIRY_001));
        _ ->
            ?IF(?HAS_COUPLE(CoupleID) andalso Now - MarryTime > CoolDownTime2 * ?AN_HOUR, ok, ?THROW_ERR(?ERROR_MARRY_FAIRY_001))
    end,
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(GoodsIDList, State),
    DecreaseList = [#r_goods_decrease_info{id = ID, num = Num} || #p_goods{id = ID, num = Num} <- GoodsList],
    BagDoings = [{decrease, ?ITEM_REDUCE_MARRY_FAIRY, DecreaseList}],
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_MARRY_FAIRY_REWARD,
        action = ?ITEM_GAIN_MARRY_FAIRY_REWARD,
        text_string = [RoleName, Text],
        goods_list = GoodsList
    },
    common_letter:send_letter(CoupleID, LetterInfo),
    {ok, BagDoings, State}.


%%  @doc T 处理三生三世活动【排行榜】的信息
do_act_marry_three_life_rank(RoleID, State) ->
    ?IF(mod_role_act:is_act_open2(?ACT_MARRY_THREE_LIFE, State), ok, ?THROW_ERR(?ACT_STATUS_CLOSE)),
    AllMarriedData = mod_marry_data:get_all_share_marry(),
    Ranks = get_married_friendly_rank_list(AllMarriedData),
    SortedRanks = sort_marry_three_life_rank(Ranks),
    CleanedSortedRanks = clean_sorted_ranks(SortedRanks),  %% 清理数据清除掉同心结之和一项
    GetMaxTwentyRanks = get_max_twenty_ranks(CleanedSortedRanks, 20), %% T 取前20个数据上榜
    common_misc:unicast(RoleID, #m_act_marry_three_life_rank_info_toc{ranks = GetMaxTwentyRanks}),
    State.

%% @doc T  前N对夫妻上榜
get_max_twenty_ranks([], _Num) ->
    [];
get_max_twenty_ranks(_CleanedSortedRanks, 0) ->
    [];
get_max_twenty_ranks([A|R], Num) ->
    {Name1, Name2, Friendly} = A,
    [#p_friendly_rank{rank = 21 - Num, name_man = Name1, name_woman = Name2, friendly = Friendly}|get_max_twenty_ranks(R, Num - 1)].

%% @doc T 清理数据清除掉同心结之和一项
clean_sorted_ranks([]) ->
    [];
clean_sorted_ranks([A|R]) ->
    {Name1, Name2, Friendly, _} = A,
    [{Name1, Name2, Friendly}|clean_sorted_ranks(R)].

%% @doc T 把三生三世活动排行榜排序根据亲密度由高到低，亲密度相同同心结（之和）高则高
sort_marry_three_life_rank(Ranks) ->
    SortFun = fun(A, B) ->
        {_, _, Friendly1, Knot1} = A,
        {_, _, Friendly2, Knot2} = B,
        if Friendly1 =:= Friendly2 ->
            Knot1 >= Knot2;
            true ->
                Friendly1 > Friendly2
        end end,
    lists:sort(SortFun, Ranks).

%% @doc T 取到已经结婚的人姓名(男女)+亲密度+同心结(id之和)
get_married_friendly_rank_list([]) ->
    [];
get_married_friendly_rank_list([MarryData|R]) ->
    #r_marry_share{share_id = {RoleID1, RoleID2}} = MarryData,
    #r_role_attr{role_name = RoleName1,sex = Sex1} = common_role_data:get_role_attr(RoleID1),
    #r_role_attr{role_name = RoleName2} = common_role_data:get_role_attr(RoleID2),
    {Man, Woman} = ?IF(Sex1 =:= 1,{RoleName1, RoleName2}, {RoleName2, RoleName1}), %% T 拿到男女的名字
    #r_world_friend{friend_list = FriendList} = world_friend_server:get_role_info(RoleID1), %% T 拿到朋友列表
    #r_friend{friendly = Friendly} = lists:keyfind(RoleID2, #r_friend.role_id, FriendList), %% T 拿到他们的亲密度 --排序
    [#r_role_marry{knot_id = Knot1}] = db:lookup(?DB_ROLE_MARRY_P, RoleID1),
    [#r_role_marry{knot_id = Knot2}] = db:lookup(?DB_ROLE_MARRY_P, RoleID2),
    SumKnot = Knot1 + Knot2,   %% T  拿到两个人的同心结等级之和（id之和） --排序
    [{Man, Woman, Friendly, SumKnot}|get_married_friendly_rank_list(R)].
%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     坐骑
%%% @end
%%% Created : 13. 七月 2017 9:59
%%%-------------------------------------------------------------------
-module(mod_role_mount).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_role_mount.hrl").
-include("proto/mod_role_item.hrl").
-include("rank.hrl").
-define(MOUNT_MOVE_SPEED, 100).
-define(MOUNT_SPEED_ITEM, 30301).   %%进阶精华bag_create_goods,30301;100
-define(MOUNT_MAX_LEVEL, 10).       %%最高等级与等阶


%% API
-export([
    init/1,
    calc/1,
    online/1,
    handle/2
]).

-export([
    add_skin/2,
    add_quality/3,
    function_open/2,
    do_mount_step/4,

    get_base_skins/1,
    get_mount_step/1,
    get_mount_id/1
]).

-export([
    force_mount_down/1,
    gm_set_seed/3
]).

init(#r_role{role_id = RoleID, role_mount = undefined} = State) ->
    RoleMount = #r_role_mount{role_id = RoleID},
    State#r_role{role_mount = RoleMount};
init(State) ->
    State.

calc(State) ->
    #r_role{role_mount = RoleMount} = State,
    #r_role_mount{mount_id = MountID} = RoleMount,
    ?IF(MountID > 0, calc2(RoleMount, State), State).

calc2(RoleMount, State) ->
    #r_role_mount{
        mount_id = MountID,
        status = Status,
        quality_list = QualityList,
        surface_list = SurFaceList} = RoleMount,
    [Config] = lib_config:find(cfg_mount_up, MountID),
    #c_mount_up{
        add_hp = AddHp1,                  %% 生命
        add_attack = AddAttack1,          %% 攻击
        add_defence = AddDefence1,        %% 防御
        add_arp = AddArp1,                %% 破甲
        speed = Speed
    } = Config,
    AddMoveSpeed = ?IF(Status =:= ?MOUNT_STATUS_DOWN, 0, Speed),
    BaseAttr = #actor_cal_attr{
        max_hp = {AddHp1, 0},
        attack = {AddAttack1, 0},
        defence = {AddDefence1, 0},
        arp = {AddArp1, 0},
        move_speed = {AddMoveSpeed, 0}
    },
    {QualityAttr, AddRate} = role_misc:get_pellet_attr(cfg_mount_quality, QualityList),
    AddRate2 = role_misc:get_skill_prop_rate(?ATTR_MOUNT_ADD, State),
    RateAttr = common_misc:pellet_attr(common_misc:sum_calc_attr([BaseAttr, QualityAttr]), AddRate + AddRate2),
    SurfaceAttr = calc_mount_surface_attr(SurFaceList, #actor_cal_attr{}),
    CalcAttr = common_misc:sum_calc_attr2(RateAttr, SurfaceAttr),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_MOUNT, CalcAttr).

calc_mount_surface_attr([], Acc) ->
    Acc;
calc_mount_surface_attr([#p_kv{id = SurFaceID}|R], Acc) ->
    Acc2 = common_misc:sum_calc_attr2(calc_mount_surface_attr2(SurFaceID), Acc),
    calc_mount_surface_attr(R, Acc2).

calc_mount_surface_attr2(MountSurfaceID) -> % T 计算单个皮肤的属性
    case lib_config:find(cfg_mount_surface, MountSurfaceID) of
        [Config] ->
            #c_mount_surface{
                add_hp = AddHp,
                add_attack = AddAttack,
                add_defence = AddDefence,
                add_arp = AddArp
            } = Config,
            #actor_cal_attr{
                max_hp = {AddHp, 0},
                attack = {AddAttack, 0},
                defence = {AddDefence, 0},
                arp = {AddArp, 0}
            };
        _ ->
            #actor_cal_attr{}
    end.

online(State) ->
    #r_role{role_id = RoleID, role_mount = RoleMount} = State,
    DataRecord = #m_mount_info_toc{op_type = ?GROW_INFO_ONLINE, mount_info = trans_to_p_mount(RoleMount)},
    common_misc:unicast(RoleID, DataRecord),
    State.

add_skins([], State) ->
    State;
add_skins([NewSkinID|T], State) ->
    State2 = add_skin(NewSkinID, State, false),
    add_skins(T, State2).

add_skin(NewSkinID, State) when erlang:is_integer(NewSkinID) ->
    add_skin(NewSkinID, State, true).
add_skin(NewSkinID, State, IsBroadcast) ->
    #r_role{role_id = RoleID, role_mount = RoleMount} = State,
    #r_role_mount{skin_list = SkinList} = RoleMount,
    case lists:keymember(NewSkinID, #p_kv.id, SkinList) of
        true ->
            ?ERROR_MSG("bug:      repeat mount_skin_id          ~w", [NewSkinID]),
            State;
        _ ->
            case lib_config:find(cfg_mount_base, NewSkinID) of
                [#c_mount_base{mount_name = MountName, broadcast_id = BroadcastID}] ->
                    ok;
                _ ->
                    MountName = BroadcastID = ?THROW_ERR(?ERROR_ITEM_USE_008)
            end,
            Skin = #p_kv{id = NewSkinID},
            SkinList2 = [Skin|SkinList],
            ?IF(IsBroadcast andalso BroadcastID > 0, common_broadcast:send_world_common_notice(BroadcastID, [mod_role_data:get_role_name(State), MountName]), ok),
            common_misc:unicast(RoleID, #m_mount_skin_toc{skin = Skin}),
            RoleMount2 = RoleMount#r_role_mount{skin_list = SkinList2},
            State#r_role{role_mount = RoleMount2}
    end.



add_quality(TypeID, AddNum, State) ->
    #r_role{role_id = RoleID, role_mount = RoleMount} = State,
    #r_role_mount{quality_list = QualityList} = RoleMount,
    case lists:keyfind(TypeID, #p_kv.id, QualityList) of
        #p_kv{} = Quality ->
            ok;
        _ ->
            Quality = #p_kv{id = TypeID, val = 0}
    end,
    #p_kv{val = UseNum} = Quality,
    [#c_pellet{max_num = MaxNum}] = lib_config:find(cfg_mount_quality, TypeID),
    NewUseNum = ?IF(role_misc:pellet_max_num(UseNum + AddNum, MaxNum, State), ?THROW_ERR(?ERROR_ITEM_USE_005), UseNum + AddNum),
    Quality2 = Quality#p_kv{val = NewUseNum},
    QualityList2 = lists:keystore(TypeID, #p_kv.id, QualityList, Quality2),
    RoleMount2 = RoleMount#r_role_mount{quality_list = QualityList2},
    common_misc:unicast(RoleID, #m_mount_quality_toc{quality = Quality2}),
    State2 = State#r_role{role_mount = RoleMount2},
    role_misc:pellet_broadcast(?NOTICE_MOUNT_PELLET, TypeID, State2),
    mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_MOUNT_QUALITY, TypeID).

force_mount_down(State) ->
    #r_role{role_id = RoleID} = State,
    Status = ?MOUNT_STATUS_DOWN,
    case catch check_can_change(Status, State) of
        {ok, State2} ->
            State3 = mod_role_skin:update_skin(State2),
            common_misc:unicast(RoleID, #m_mount_status_change_toc{status = Status}),
            mod_role_fight:calc_attr_and_update(calc(State3));
        {error, _ErrCode} ->
            State
    end.

get_base_skins(undefined) ->
    [];
get_base_skins(RoleMount) ->
    #r_role_mount{surface_list = SurfaceList} = RoleMount,
    [?GET_BASE_ID(SurfaceID) || #p_kv{id = SurfaceID} <- SurfaceList].

get_mount_step(State) ->
    #r_role{role_mount = #r_role_mount{mount_id = MountID}} = State,
    case lib_config:find(cfg_mount_up, MountID) of
        [#c_mount_up{mount_step = MountStep}] ->
            MountStep;
        _ ->
            0
    end.

get_mount_id(State) ->
    #r_role{role_mount = #r_role_mount{mount_id = MountID}} = State,
    MountID.

get_mount_name_by_id(MountID) ->
    [#c_mount_up{mount_name = MountName}] = lib_config:find(cfg_mount_up, MountID),
    MountName.

handle({#m_mount_change_tos{cur_id = CurID}, RoleID, _PID}, State) ->
    do_mount_change(RoleID, CurID, State);
handle({#m_mount_status_change_tos{status = Status}, RoleID, _PID}, State) ->
    do_status_change(RoleID, Status, State);
handle({#m_mount_skin_tos{skin_id = SkinID}, RoleID, _PID}, State) ->
    do_mount_skin(RoleID, SkinID, State);
handle({#m_mount_surface_active_tos{base_id = BaseID}, RoleID, _PID}, State) ->
    do_mount_surface_active(RoleID, BaseID, State);
handle({#m_mount_surface_step_tos{base_id = BaseID, item_id = ItemID, item_num = ItemNum}, RoleID, _PID}, State) ->
    do_mount_surface_step(RoleID, BaseID, ItemID, ItemNum, State).


function_open(MountID, State) ->
    #r_role{role_id = RoleID, role_mount = RoleMount} = State,
    #r_role_mount{mount_id = OldMountID} = RoleMount,
    case OldMountID =:= 0 of
        true ->
            SkinID = ?GET_BASE_ID(MountID),
            Skin = #p_kv{id = SkinID},
            RoleMount2 = RoleMount#r_role_mount{mount_id = MountID, cur_id = 0, skin_list = [Skin]},
            notice_info(RoleID, RoleMount2),
            State2 = State#r_role{role_mount = RoleMount2},
            State3 = calc(State2),
            State4 = mod_role_skin:update_skin(State3),
            State5 = do_mount_step_skill(0, MountID, State4),
            State6 = mod_role_fight:calc_attr_and_update(State5, ?POWER_UPDATE_MOUNT_STEP, MountID),
            MountStep = get_mount_step(State6),
            State7 = mod_role_achievement:mount_step(MountStep, State6),
            mod_role_day_target:mount_step(State7);
        _ ->
            State
    end.

notice_info(RoleID, RoleMount) ->
    common_misc:unicast(RoleID, #m_mount_info_toc{op_type = ?GROW_INFO_UPDATE, mount_info = trans_to_p_mount(RoleMount)}).

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_mount_step(AddExp, TypeID, Num, #r_role{role_id = RoleID} = State) ->
    case catch check_can_step(State, AddExp, TypeID, Num) of
        {ok, State2, _OpenSkills, OldMountID, MountID, NewExp, Log} ->
            mod_role_dict:add_background_logs(Log),
            State3 = do_mount_step_skill(OldMountID, MountID, State2),
            ?IF(?GET_BASE_ID(OldMountID) =/= ?GET_BASE_ID(MountID),
                common_broadcast:send_world_common_notice(?NOTICE_MOUNT_STEP_UP, [mod_role_data:get_role_name(State), get_mount_name_by_id(MountID)]),
                ok),
            common_misc:unicast(RoleID, #m_mount_step_toc{mount_id = MountID, exp = NewExp}),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_MOUNT_STEP, MountID),
            MountStep = get_mount_step(State4),
            State5 = mod_role_achievement:mount_step(MountStep, State4),
            State6 = mod_role_day_target:mount_step(State5),
            State7 = mod_role_confine:mount_step_up(MountStep , State6),
            State8 = mod_role_act_rank:mount_step(State7),
            State8;
        {keep, RoleMount, MountID, NewExp, Log} ->
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_mount_step_toc{mount_id = MountID, exp = NewExp}),
            State#r_role{role_mount = RoleMount};
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mount_step_toc{err_code = ErrCode}),
            State
    end.

check_can_step(State, AddExp, TypeID, Num) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_mount = RoleMount} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #r_role_mount{mount_id = MountID, exp = Exp} = RoleMount,
    case lib_config:find(cfg_mount_up, MountID + 1) of
        [#c_mount_up{}] ->
            ok;
        _ ->
            NewBaseID = ?GET_BASE_ID(MountID) + 1,
            case lib_config:find(cfg_mount_base, NewBaseID) of
                [_Config] ->
                    ok;
                _ ->
                    ?THROW_ERR(?ERROR_MOUNT_STEP_001)
            end
    end,
    {NewMountID, NewExp, OpenSkills, NewSkins} = check_can_step2(MountID, AddExp, Exp, [], []),
    NewRoleMount = RoleMount#r_role_mount{mount_id = NewMountID, exp = NewExp},
    State2 = State#r_role{role_mount = NewRoleMount},
    Log = #log_mount_step{
        role_id = RoleID,
        add_step_exp = AddExp,
        item_id = TypeID,
        item_num = Num,
        old_mount_id = MountID,
        new_mount_id = NewMountID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    case NewMountID =/= MountID of
        true ->
            State4 =
            case catch add_skins(NewSkins, State2) of
                #r_role{} = State3 ->
                    State3;
                Error ->
                    ?ERROR_MSG("Error:~w", [Error]),
                    State2
            end,
            {ok, State4, OpenSkills, MountID, NewMountID, NewExp, Log};
        _ ->
            {keep, NewRoleMount, NewMountID, NewExp, Log}
    end.

check_can_step2(NowMountID, Exp, AddExp, OpenSkills, Skins) ->
    [Config] = lib_config:find(cfg_mount_up, NowMountID),
    SumExp = Exp + AddExp,
    if
        SumExp > Config#c_mount_up.step_item_num ->
            {NewMountID, NewOpenSkills, NewSkins, IsMax} = check_can_step3(Config, OpenSkills, Skins),
            ?IF(IsMax, {NewMountID, 0, NewOpenSkills, NewSkins}, check_can_step2(NewMountID, 0, SumExp - Config#c_mount_up.step_item_num, NewOpenSkills, NewSkins));
        SumExp =:= Config#c_mount_up.step_item_num ->
            {NewMountID, NewOpenSkills, NewSkins, _IsMax} = check_can_step3(Config, OpenSkills, Skins),
            {NewMountID, 0, NewOpenSkills, NewSkins};
        true ->
            {NowMountID, SumExp, OpenSkills, Skins}
    end.

check_can_step3(Config, OpenSkills, Skins) ->
    if
        (Config#c_mount_up.mount_star) =:= ?MOUNT_MAX_LEVEL ->
            NewBaseID = ?GET_BASE_ID(Config#c_mount_up.mount_id) + 1,
            case lib_config:find(cfg_mount_base, NewBaseID) of
                [] ->
                    ?THROW_ERR(?ERROR_MOUNT_STEP_001);
                [BaseConfig] ->
                    ?IF(BaseConfig#c_mount_base.open_skill =:= 0,
                        {NewBaseID * 100 + 1, OpenSkills, [NewBaseID|Skins], false},
                        {NewBaseID * 100 + 1, [BaseConfig#c_mount_base.open_skill|OpenSkills], [NewBaseID|Skins], false})
            end;
        (Config#c_mount_up.mount_star) =:= ?MOUNT_MAX_LEVEL - 1 ->
            NewBaseID = ?GET_BASE_ID(Config#c_mount_up.mount_id) + 1,
            case lib_config:find(cfg_mount_base, NewBaseID) of
                [] ->
                    {Config#c_mount_up.mount_id + 1, OpenSkills, Skins, true};
                _ ->
                    {Config#c_mount_up.mount_id + 1, OpenSkills, Skins, false}
            end;
        true ->
            {Config#c_mount_up.mount_id + 1, OpenSkills, Skins, false}
    end.


%% 幻化坐骑外观
do_mount_change(RoleID, BaseID, State) ->
    case catch check_mount_change(BaseID, State) of
        {ok, MountID, State2} ->
            common_misc:unicast(RoleID, #m_mount_change_toc{cur_id = BaseID}),
            State3 = do_mount_surface_skill(MountID, State, State2),
            mod_role_skin:update_skin(State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mount_change_toc{err_code = ErrCode}),
            State
    end.

check_mount_change(BaseID, State) ->
    #r_role{role_mount = RoleMount} = State,
    #r_role_mount{cur_id = OldCurID, mount_id = MountID, surface_list = SurFaceList} = RoleMount,
    ?IF(?GET_BASE_ID(OldCurID) =:= BaseID, ?THROW_ERR(?ERROR_MOUNT_CHANGE_001), ok), % T %%已经是该伙伴
    case lib_config:find(cfg_mount_up, ?GET_NORMAL_ID(BaseID) + 1) of
        [_ConfigMount] ->
            ?IF(BaseID =< ?GET_BASE_ID(MountID), ok, ?THROW_ERR(?ERROR_MOUNT_CHANGE_002)),
            RoleMount2 = RoleMount#r_role_mount{cur_id = get_mount_normal_id(BaseID)},
            State2 = State#r_role{role_mount = RoleMount2},
            State2;
        _ ->
            NewSurfaceIDList = lists:foldl(
                fun(X,Acc1) ->
                    #p_kv{id = SurfaceID} = X,
                    ?IF(BaseID =:= ?GET_BASE_ID(SurfaceID), [SurfaceID|Acc1], Acc1) end, [], SurFaceList),
            ?IF(NewSurfaceIDList =:= [], ?THROW_ERR(?ERROR_MOUNT_CHANGE_002), ok), %%没有该伙伴，不能幻化
            [CurID] = NewSurfaceIDList,
            RoleMount2 = RoleMount#r_role_mount{cur_id = CurID},
            State2 = State#r_role{role_mount = RoleMount2}
    end,
    {ok, MountID, State2}.

do_status_change(RoleID, Status, State) ->
    case catch check_can_change(Status, State) of
        {ok, State2} ->
            State3 = mod_role_skin:update_skin(State2),
            common_misc:unicast(RoleID, #m_mount_status_change_toc{status = Status}),
            mod_role_fight:calc_attr_and_update(calc(State3));
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mount_status_change_toc{err_code = ErrCode}),
            State
    end.

check_can_change(Status, State) ->
    #r_role{role_mount = RoleMount} = State,
    #r_role_mount{mount_id = MountID, status = OldStatus} = RoleMount,
    ?IF(OldStatus =:= Status, ?THROW_ERR(?ERROR_MOUNT_STATUS_CHANGE_002), ok),
    ?IF(MountID > 0, ok, ?THROW_ERR(?ERROR_MOUNT_STATUS_CHANGE_001)),
    ?IF(Status =:= ?MOUNT_STATUS_DOWN orelse Status =:= ?MOUNT_STATUS_UP, ok, ?THROW_ERR(?ERROR_MOUNT_STATUS_CHANGE_003)),
    RoleMount2 = RoleMount#r_role_mount{status = Status},
    State2 = State#r_role{role_mount = RoleMount2},
    {ok, State2}.

do_mount_surface_active(RoleID, BaseID, State) ->
    case catch check_mount_surface_active(BaseID, State) of
        {ok, IsNew, BagDoings, SurfaceID, Surface, RoleMount, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_mount_surface_active_toc{surface = Surface}),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_MOUNT_SKIN_ACTIVE, SurfaceID),

            case IsNew of
                true ->
                    [#c_mount_base{mount_name = MountName, broadcast_id = BroadcastID}] = lib_config:find(cfg_mount_base, ?GET_BASE_ID(SurfaceID)),
                    BroadcastID2 = ?IF(BroadcastID > 0, BroadcastID, ?NOTICE_MOUNT_SKIN),
                    common_broadcast:send_world_common_notice(BroadcastID2, [mod_role_data:get_role_name(State), MountName]),
                    #r_role_mount{mount_id = MountID} = RoleMount,
                    State5 = do_mount_surface_skill(MountID, State, State4),
                    common_misc:unicast(RoleID, #m_mount_change_toc{cur_id = ?GET_BASE_ID(SurfaceID)}),
                    State6 = mod_role_skin:update_skin(State5),
                    mod_role_skin:update_couple_skin(?DB_ROLE_MOUNT_P, ?GET_BASE_ID(SurfaceID), State6);
                _ ->
                    State4
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mount_surface_active_toc{err_code = ErrCode}),
            State
    end.

check_mount_surface_active(BaseID, State) ->
    #r_role{role_mount = RoleMount} = State,
    #r_role_mount{cur_id = OldCurID, surface_list = SurfaceList} = RoleMount,
    {TypeID, Num, IsNew, Surface, SurfaceList2} = check_mount_surface_active2(SurfaceList, BaseID, []),
    BagDoings = mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_MOUNT_SURFACE_ACTIVATE, State),
    SurfaceID = Surface#p_kv.id,
    IsNew2 = IsNew orelse ?GET_BASE_ID(OldCurID) =:= ?GET_BASE_ID(SurfaceID),
    RoleMount2 = RoleMount#r_role_mount{surface_list = SurfaceList2},
    RoleMount3 = ?IF(IsNew2, RoleMount2#r_role_mount{cur_id = SurfaceID}, RoleMount2),
    State2 = State#r_role{role_mount = RoleMount3},
    {ok, IsNew2, BagDoings, SurfaceID, Surface, RoleMount3, State2}.

check_mount_surface_active2([], BaseID, SurfaceAcc) -> %% 全新激活
    ID = ?GET_NORMAL_ID(BaseID),
    [#c_mount_surface{need_item = TypeID, item_num = ItemNum}] = lib_config:find(cfg_mount_surface, ID),
    Surface = #p_kv{id = ID, val = 0},
    {TypeID, ItemNum, true, Surface, [Surface|SurfaceAcc]};
check_mount_surface_active2([Surface|R], BaseID, SurfaceAcc) ->
    #p_kv{id = SurfaceID} = Surface,
    case ?GET_BASE_ID(SurfaceID) =:= BaseID of %% 升阶
        true ->
            [#c_mount_surface{
                need_item = TypeID,
                item_num = ItemNum,
                step = OldStep}] = lib_config:find(cfg_mount_surface, SurfaceID),
            SurfaceID2 = SurfaceID + 1,
            case lib_config:find(cfg_mount_surface, SurfaceID2) of
                [Config] ->
                    #c_mount_surface{step = NewStep} = Config,
                    ?IF(NewStep > OldStep, ok, ?THROW_ERR(?ERROR_MOUNT_SURFACE_ACTIVE_001)),
                    Surface2 = #p_kv{id = SurfaceID2, val = 0},
                    {TypeID, ItemNum, false, Surface2, [Surface2|R] ++ SurfaceAcc};
                _ ->
                    ?THROW_ERR(?ERROR_MOUNT_SURFACE_ACTIVE_002)
            end;
        _ ->
            check_mount_surface_active2(R, BaseID, [Surface|SurfaceAcc])
    end.

do_mount_surface_step(RoleID, BaseID, ItemID, ItemNum, State) ->
    case catch check_mount_surface_step(BaseID, ItemID, ItemNum, State) of
        {ok, IsLevelUp, IsChange, BagDoings, SurfaceID, Surface, RoleMount, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_mount_surface_step_toc{surface = Surface}),
            State4 = ?IF(IsLevelUp, mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_MOUNT_SKIN_STEP, SurfaceID), State3),
            case IsChange of
                true ->
                    #r_role_mount{cur_id = NewCurID, mount_id = MountID} = RoleMount,
                    common_misc:unicast(RoleID, #m_mount_change_toc{cur_id  = ?GET_BASE_ID(NewCurID)}),
                    State5 = do_mount_surface_skill(MountID, State, State4),
                    mod_role_skin:update_skin(State5);
                _ ->
                    State4
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mount_surface_step_toc{err_code = ErrCode}),
            State
    end.

check_mount_surface_step(BaseID, TypeID, ItemNumT, State) ->
    #r_role{role_mount = RoleMount} = State,
    #r_role_mount{cur_id = OldCurID, surface_list = SurfaceList} = RoleMount,
    ItemNum = erlang:max(1, ItemNumT),
    OneExp =
        case mod_role_item:get_item_config(TypeID) of
            #c_item{effect_type = ?ITEM_MOUNT_STEP_EXP, effect_args = AddStepExpT} ->
                lib_tool:to_integer(AddStepExpT);
            _ ->
                ?THROW_ERR(?ERROR_MOUNT_SURFACE_STEP_001)
        end,
    {IsLevelUp, UseExp, Surface, SurfaceList2} = check_mount_surface_step2(SurfaceList, BaseID, OneExp * ItemNum, []),
    SurfaceID = Surface#p_kv.id,
    ItemNum2 = lib_tool:ceil(UseExp/OneExp),
    BagDoings = mod_role_bag:check_num_by_type_id(TypeID, ItemNum2, ?ITEM_REDUCE_MOUNT_SURFACE_STEP, State),
    IsChange = IsLevelUp andalso ?GET_BASE_ID(OldCurID) =:= ?GET_BASE_ID(SurfaceID),
    RoleMount2 = RoleMount#r_role_mount{surface_list = SurfaceList2},
    RoleMount3 = ?IF(IsChange, RoleMount2#r_role_mount{cur_id = SurfaceID}, RoleMount2),
    State2 = State#r_role{role_mount = RoleMount3},
    {ok, IsLevelUp, IsChange, BagDoings, SurfaceID, Surface, RoleMount3, State2}.

check_mount_surface_step2([], _BaseID, _AddStep, _SurfaceAcc) ->
    ?THROW_ERR(?ERROR_MOUNT_SURFACE_STEP_002);
check_mount_surface_step2([Surface|R], BaseID, AddExp, SurfaceAcc) ->
    #p_kv{id = SurfaceID, val = OldExp} = Surface,
    case ?GET_BASE_ID(SurfaceID) =:= BaseID of %% 升阶
        true ->
            [#c_mount_surface{step = OldStep}] = lib_config:find(cfg_mount_surface, SurfaceID),
            SurfaceID2 = SurfaceID + 1,
            case lib_config:find(cfg_mount_surface, SurfaceID2) of
                [#c_mount_surface{step = NewStep}] when OldStep =:= NewStep -> %% 同一阶，能继续升
                    {Surface2, UseExp} = get_mount_surface_step_exp(SurfaceID, OldStep, OldExp, AddExp, 0),
                    IsLevelUp = Surface2#p_kv.id =/= Surface#p_kv.id,
                    {IsLevelUp, UseExp, Surface2, [Surface2|R] ++ SurfaceAcc};
                _ ->
                    ?THROW_ERR(?ERROR_MOUNT_SURFACE_STEP_003)
            end;
        _ ->
            check_mount_surface_step2(R, BaseID, AddExp, [Surface|SurfaceAcc])
    end.

get_mount_surface_step_exp(SurfaceID, OldStep, Exp, AddExp, UseExp) ->
    SurfaceID2 = SurfaceID + 1,
    case lib_config:find(cfg_mount_surface, SurfaceID2) of
        [#c_mount_surface{step = Step}] when OldStep =:= Step ->
            Exp2 = Exp + AddExp,
            [#c_mount_surface{step_exp = NeedStepExp}] = lib_config:find(cfg_mount_surface, SurfaceID),
            case Exp2 >= NeedStepExp of
                true ->
                    UseExpAcc = NeedStepExp - Exp,
                    get_mount_surface_step_exp(SurfaceID2, OldStep, 0, AddExp - UseExpAcc, UseExpAcc + UseExp);
                _ ->
                    {#p_kv{id = SurfaceID, val = Exp2}, UseExp + (Exp2 - Exp)}
            end;
        _ ->
            {#p_kv{id = SurfaceID, val = 0}, UseExp}
    end.

do_mount_step_skill(OldMountID, NewMountID, State) ->
    OldSkills = get_mount_step_skills(OldMountID),
    NewSkills = get_mount_step_skills(NewMountID),
    case OldSkills =/= NewSkills of
        true ->
            SkillNames = common_skill:get_skill_names(NewSkills -- OldSkills),
            common_broadcast:send_world_common_notice(?NOTICE_MOUNT_SKILL_OPEN, [mod_role_data:get_role_name(State), SkillNames]),
            SurfaceSkills = get_surface_skill_by_state(State),
            mod_role_skill:skill_fun_change(?SKILL_FUN_MOUNT, SurfaceSkills ++ NewSkills, State);
        _ ->
            State
    end.

%% 幻化ID变化，可能会有新技能
do_mount_surface_skill(MountID, OldState, State) ->
    OldSkills = get_surface_skill_by_state(OldState),
    NewSkills = get_surface_skill_by_state(State),
    case OldSkills =/= NewSkills of
        true ->
            StepSkills = get_mount_step_skills(MountID),
            mod_role_skill:skill_fun_change(?SKILL_FUN_MOUNT, NewSkills ++ StepSkills, State);
        _ ->
            State
    end.

get_mount_step_skills(0) ->
    [];
get_mount_step_skills(MountID) ->
    [#c_mount_base{have_skills = Skills}] = lib_config:find(cfg_mount_base, ?GET_BASE_ID(MountID)),
    lists:sort(Skills).

get_surface_skill_by_state(State) ->
    #r_role{role_mount = #r_role_mount{surface_list = SurfaceList}} = State,
    lists:sort(lists:flatten([ get_mount_surface_skills(SurfaceID) || #p_kv{id = SurfaceID} <- SurfaceList])).

%% 皮肤带来的技能
get_mount_surface_skills(0) ->
    [];
get_mount_surface_skills(SurfaceID) ->
    case lib_config:find(cfg_mount_surface, SurfaceID) of
        [#c_mount_surface{skill_list = SkillList}] ->
            SkillList;
        _ ->
            []
    end.

trans_to_p_mount(RoleMount) ->
    #r_role_mount{
        mount_id = GrowID,
        cur_id = CurID,
        skin_list = SkinList,
        exp = Exp,
        quality_list = QualityList,
        surface_list = SurFaceList
    } = RoleMount,
    #p_mount{
        mount_id = GrowID,
        cur_id = ?GET_BASE_ID(CurID),
        exp = Exp,
        skin_list = SkinList,
        quality_list = QualityList,
        surface_list = SurFaceList
    }.


%% 坐骑皮肤升星
do_mount_skin(RoleID, SkinID, State) ->
    case catch check_mount_skin(SkinID, State) of
        {ok, BagDoings, IsStep, MountSkin2, State2, NewStep} ->
            common_misc:unicast(RoleID, #m_mount_skin_toc{skin = MountSkin2}),
            State3 = mod_role_bag:do(BagDoings, State2),
            case IsStep of
                true ->
                    State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_MOUNT_SKIN, 0),
                    State5 = mod_role_skin:update_skin(State4),
                    mod_role_confine:mount_step_up(NewStep,State5);
                _ ->
                    State3
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mount_skin_toc{err_code = ErrCode}),
            ErrCode
    end.

check_mount_skin(SkinID, State) ->
    #r_role{role_mount = RoleMount} = State,
    #r_role_mount{cur_id = CurID, skin_list = SkinList} = RoleMount,
    case lists:keyfind(SkinID, #p_kv.id, SkinList) of
        #p_kv{} = MountSkin ->
            ok;
        _ ->
            MountSkin = ?THROW_ERR(?ERROR_MOUNT_SKIN_001)
    end,
    #p_kv{val = Bless} = MountSkin,
    SkinID2 = SkinID + 1,
    case lib_config:find(cfg_mount_skin, SkinID2) of
        [NextConfig] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_MOUNT_SKIN_002),
            NextConfig  = ok
    end,
    [#c_mount_skin{
        mount_step = MountStep,
        step_item = StepItem,
        step_item_num = StepItemNum,
        need_bless = NeedBless,
        add_min_bless = AddMinBless,
        add_max_bless = AddMaxBless
    }] = lib_config:find(cfg_mount_skin, SkinID),
    BagDoings = mod_role_bag:check_num_by_type_id(StepItem, StepItemNum, ?ITEM_REDUCE_MOUNT_SKIN, State),
    Bless2 = Bless + lib_tool:random(AddMinBless, AddMaxBless),
    case Bless2 >= NeedBless of
        true ->
            IsStep = true,
            NewStep = NextConfig#c_mount_skin.mount_step,
            CurID2 = ?IF(CurID =:= SkinID, SkinID2, CurID),
            MountSkin2 = MountSkin#p_kv{id = SkinID2, val = 0};
        _ ->
            IsStep = false,
            NewStep = MountStep,
            CurID2 = CurID,
            MountSkin2 = MountSkin#p_kv{val = Bless2}
    end,
    SkinList2 = lists:keyreplace(SkinID, #p_kv.id, SkinList, MountSkin2),
    RoleMount2 = RoleMount#r_role_mount{cur_id = CurID2, skin_list = SkinList2},
    State2 = State#r_role{role_mount = RoleMount2},
    {ok, BagDoings, IsStep, MountSkin2, State2, NewStep}.




gm_set_seed(State, Num, Type) ->
    Speed = case Type =:= 1 of
                true ->
                    lib_tool:to_integer(Num);
                _ ->
                    0 - lib_tool:to_integer(Num)
            end,
    BaseAttr = #actor_cal_attr{
        max_hp = {0, 0},
        attack = {0, 0},
        defence = {0, 0},
        arp = {0, 0},
        move_speed = {Speed, 0}
    },
    RateAttr = common_misc:pellet_attr(common_misc:sum_calc_attr([BaseAttr]), 0),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_GM, RateAttr).

get_mount_normal_id(0) ->
    0;
get_mount_normal_id(CurID) when CurID > 10000 andalso CurID < 90000 ->
    ?GET_NORMAL_ID(CurID) + 1;
get_mount_normal_id(CurID) ->
    CurID.
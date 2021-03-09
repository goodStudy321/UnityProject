%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 七月 2017 12:26
%%%-------------------------------------------------------------------
-module(mod_role_pet).
-author("laijichang").
-include("role.hrl").
-include("rank.hrl").
-include("proto/mod_role_pet.hrl").
-include("proto/mod_role_item.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    handle/2
]).
-export([
    add_step_exp/4,
    add_exp/2,
    add_spirit/3,
    function_open/2
]).

-export([
    get_base_skins/1,
    get_pet_step/1,
    get_pet_id/1
]).

init(#r_role{role_id = RoleID, role_pet = undefined} = State) ->
    RolePet = #r_role_pet{role_id = RoleID},
    State#r_role{role_pet = RolePet};
init(State) ->
    State.

calc(State) ->
    #r_role{role_pet = RolePet} = State,
    #r_role_pet{pet_id = PetID, pet_spirits = PetSpirits, surface_list = SurFaceList} = RolePet,
    Attr2 = calc_pet_attr(PetID),
    {Attr3, AddRate} = role_misc:get_pellet_attr(cfg_pet_spirit, PetSpirits),
    AddRate2 = role_misc:get_skill_prop_rate(?ATTR_PET_ADD, State),
    CalcAttr = common_misc:pellet_attr(common_misc:sum_calc_attr([Attr2, Attr3]), AddRate + AddRate2),
    Attr4 = calc_pet_surface_attr(SurFaceList, #actor_cal_attr{}), % T 计算皮肤属性 Attr4
    CalcAttr2 = common_misc:sum_calc_attr2(CalcAttr, Attr4),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_PET, CalcAttr2).

calc_pet_attr(0) ->
    #actor_cal_attr{};
calc_pet_attr(PetID) ->
    [#c_pet{
        add_hp = AddHp,
        add_attack = AddAttack,
        add_defence = AddDefence,
        add_arp = AddArp
    }] = lib_config:find(cfg_pet, PetID),
    #actor_cal_attr{
        max_hp = {AddHp, 0},
        attack = {AddAttack, 0},
        defence = {AddDefence, 0},
        arp = {AddArp, 0}
    }.

calc_pet_surface_attr([], Acc) ->
    Acc;
calc_pet_surface_attr([#p_kv{id = SurFaceID}|R], Acc) ->
    Acc2 = common_misc:sum_calc_attr2(calc_pet_surface_attr2(SurFaceID), Acc),
    calc_pet_surface_attr(R, Acc2).

calc_pet_surface_attr2(PetSurfaceID) -> % T 计算单个皮肤的属性
    case lib_config:find(cfg_pet_surface, PetSurfaceID) of
        [Config] ->
            #c_pet_surface{
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
    #r_role{role_id = RoleID, role_pet = RolePet} = State,
    #r_role_pet{exp = Exp, step_exp = StepExp, cur_id = CurID, pet_id = PetID, pet_spirits = PetSpirits, surface_list = SurfaceList} = RolePet,
    ?IF(PetID > 0, common_misc:unicast(RoleID, #m_pet_info_toc{cur_id = CurID, pet_id = PetID, pet_spirits = PetSpirits, exp = Exp, step_exp = StepExp, pet_surface = SurfaceList}), ok),
    State.

handle({#m_pet_level_up_tos{goods_list = GoodsList}, RoleID, _PID}, State) ->
    do_pet_level_up(RoleID, GoodsList, State);
handle({#m_pet_change_tos{cur_id = CurID}, RoleID, _PID}, State) ->
    do_pet_change(RoleID, CurID, State);
handle({#m_pet_surface_active_tos{base_id = BaseID}, RoleID, _PID}, State) ->
    do_pet_surface_active(RoleID, BaseID, State);
handle({#m_pet_surface_step_tos{base_id = BaseID, item_id = ItemID, item_num = ItemNum}, RoleID, _PID}, State) ->
    do_pet_surface_step(RoleID, BaseID, ItemID, ItemNum, State).

add_step_exp(AddExp, TypeID, Num, State) ->    % 进阶
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_pet = RolePet} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #r_role_pet{pet_id = OldPetID, step_exp = StepExp} = RolePet,
    StepExp2 = StepExp + AddExp,
    RolePet2 = RolePet#r_role_pet{step_exp = StepExp2},
    State2 = State#r_role{role_pet = RolePet2},
    State3 = do_pet_step(State2),
    #r_role{role_pet = #r_role_pet{pet_id = NewPetID}} = State3,   % T  进阶改的是pet_id
    Log = #log_pet_step{
        role_id = RoleID,
        add_step_exp = AddExp,
        item_id = TypeID,
        item_num = Num,
        old_pet_id = OldPetID,
        new_pet_id = NewPetID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log),
    State3.

add_exp(AddExp, #r_role{role_id = RoleID} = State) ->
    case catch check_can_level_up(AddExp, State) of
        {ok, BagDoing, AddGoodsList, NewExp, Log, State2} ->
            do_pet_level_up2(BagDoing, AddGoodsList, NewExp, Log, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_pet_level_up_toc{err_code = ErrCode}),
            State
    end.

add_spirit(TypeID, AddNum, State) ->
    #r_role{role_id = RoleID, role_pet = RolePet} = State,
    #r_role_pet{pet_spirits = PetSpirits} = RolePet,
    case lists:keyfind(TypeID, #p_kv.id, PetSpirits) of
        #p_kv{} = PetSpirit ->
            ok;
        _ ->
            PetSpirit = #p_kv{id = TypeID, val = 0}
    end,
    #p_kv{val = UseNum} = PetSpirit,
    [#c_pellet{max_num = MaxNum}] = lib_config:find(cfg_pet_spirit, TypeID),
    NewUseNum = ?IF(role_misc:pellet_max_num(UseNum + AddNum, MaxNum, State), ?THROW_ERR(?ERROR_ITEM_USE_005), UseNum + AddNum),
    PetSpirit2 = PetSpirit#p_kv{val = NewUseNum},
    PetSpirits2 = lists:keystore(TypeID, #p_kv.id, PetSpirits, PetSpirit2),
    RolePet2 = RolePet#r_role_pet{pet_spirits = PetSpirits2},
    common_misc:unicast(RoleID, #m_pet_spirit_update_toc{pet_spirit = PetSpirit2}),
    State2 = State#r_role{role_pet = RolePet2},
    role_misc:pellet_broadcast(?NOTICE_PET_PELLET, TypeID, State2),
    mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_PET_SOUL, TypeID).

function_open(PetID, State) ->  % T 功能第一次开启
    #r_role{role_id = RoleID, role_pet = RolePet} = State,
    #r_role_pet{pet_id = OldPetID, step_exp = StepExp} = RolePet,
    case OldPetID > 0 of
        true ->
            State;
        _ ->
            RolePet2 = RolePet#r_role_pet{cur_id = PetID, pet_id = PetID},
            common_misc:unicast(RoleID, #m_pet_step_toc{new_pet_id = PetID, new_step_exp = StepExp}),
            common_misc:unicast(RoleID, #m_pet_change_toc{cur_id = PetID}),
            State2 = State#r_role{role_pet = RolePet2},
            State3 = mod_role_skin:update_skin(State2),
            State4 = do_pet_step_skill(0, PetID, State3),
            State5 = mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_UPDATE_PET_STEP, PetID),
            PetStep = get_pet_step(State5),
            State6 = mod_role_achievement:pet_step(PetStep, State5),
            mod_role_day_target:pet_step(State6)
    end.

get_base_skins(undefined) ->
    [];
get_base_skins(RolePet) ->
    #r_role_pet{surface_list = SurfaceList} = RolePet,
    [?GET_BASE_ID(SurfaceID) || #p_kv{id = SurfaceID} <- SurfaceList].

get_pet_step(State) ->
    #r_role{role_pet = #r_role_pet{pet_id = PetID}} = State,
    case lib_config:find(cfg_pet, PetID) of
        [#c_pet{pet_step = PetStep}] ->
            PetStep;
        _ ->
            0
    end.

get_pet_id(State) ->
    #r_role{role_pet = #r_role_pet{pet_id = PetID}} = State,
    PetID.

get_pet_name_by_id(PetID) ->
    [#c_pet{pet_name = PetName}] = lib_config:find(cfg_pet, PetID),
    PetName.

%% 宠物分解装备
do_pet_level_up(RoleID, GoodsList, State) ->
    case catch check_can_level_up(GoodsList, State) of
        {ok, BagDoing, AddGoodsList, NewExp, Log, State2} ->
            do_pet_level_up2(BagDoing, AddGoodsList, NewExp, Log, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_pet_level_up_toc{err_code = ErrCode}),
            State
    end.

do_pet_level_up2(DelBagDoing, AddGoodsList, NewExp, Log, State) ->
    mod_role_dict:add_background_logs(Log),
    State2 = mod_role_bag:do(DelBagDoing, State),
    State3 = role_misc:create_goods(State2, ?ITEM_GAIN_PET_SWALLOW, AddGoodsList),
    common_misc:unicast(State3#r_role.role_id, #m_pet_level_up_toc{exp = NewExp}),
    State3.

check_can_level_up(GoodsList, State) when erlang:is_list(GoodsList) ->
    #r_role{role_pet = RolePet} = State,
    #r_role_pet{pet_id = PetID, exp = Exp} = RolePet,
    ?IF(GoodsList =/= [] andalso PetID > 0, ok, ?THROW_ERR(?ERROR_PET_LEVEL_UP_001)),
    {ok, GoodsList2} = mod_role_bag:check_bag_by_ids(GoodsList, State),
    AddExp =
    [begin
         case mod_role_item:get_item_config(TypeID) of
             #c_item{effect_type = ?ITEM_PTE_EXP, effect_args = EffectArgs} ->
                 lib_tool:to_integer(EffectArgs) * Num;
             _ ->
                 [#c_equip{pet_exp = PetExp}] = lib_config:find(cfg_equip, TypeID),
                 PetExp
         end
     end || #p_goods{type_id = TypeID, num = Num} <- GoodsList2],
    AddExp2 = lists:sum(AddExp),
    AddExp3 = lib_tool:ceil(AddExp2 * (1 + (mod_role_vip:get_pet_exp_rate(State) / ?RATE_10000))),
    {AddGoodsList, NewExp} = check_can_level_up2(Exp, AddExp3),
    BagDoing = [{delete, ?ITEM_REDUCE_PET_LEVEL, GoodsList}],
    RolePet2 = RolePet#r_role_pet{exp = NewExp},
    State2 = State#r_role{role_pet = RolePet2},
    Log = get_pet_level_up_log(AddExp2, GoodsList2, Exp, NewExp, State2),
    {ok, BagDoing, AddGoodsList, NewExp, Log, State2};
check_can_level_up(AddExp, State) when erlang:is_integer(AddExp) ->
    #r_role{role_pet = RolePet} = State,
    #r_role_pet{exp = Exp} = RolePet,
    {AddGoodsList, NewExp} = check_can_level_up2(Exp, AddExp),
    RolePet2 = RolePet#r_role_pet{exp = NewExp},
    State2 = State#r_role{role_pet = RolePet2},
    Log = get_pet_level_up_log(AddExp, [], Exp, NewExp, State2),
    {ok, [], AddGoodsList, NewExp, Log, State2}.

check_can_level_up2(Exp, AddExp) ->
    NewExp = Exp + AddExp,
    [NeedExp|_] = common_misc:get_global_list(?GLOBAL_PET_SWALLOW),
    case NewExp >= NeedExp of
        true ->
            ItemNum = NewExp div NeedExp,
            Exp2 = NewExp rem NeedExp,
            {[#p_goods{type_id = common_misc:get_global_int(?GLOBAL_PET_SWALLOW), num = ItemNum}], Exp2};
        _ ->
            {[], NewExp}
    end.

%% 某一只宠物进阶哇！！
do_pet_step(State) ->
    RoleID = State#r_role.role_id,
    case check_can_step(State) of
        {ok, IsChange, OldPetID, NewPetID, NewStepExp, State2} ->
            State3 = do_pet_step_skill(OldPetID, NewPetID, State2),
            State4 = mod_role_skin:update_skin(State3),
            ?IF(IsChange, common_misc:unicast(RoleID, #m_pet_change_toc{cur_id = NewPetID}), ok),
            common_misc:unicast(RoleID, #m_pet_step_toc{new_pet_id = NewPetID, new_step_exp = NewStepExp}),
            State5 = mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_UPDATE_PET_STEP, NewPetID),
            Step = get_pet_step(State5),
            FuncList = [
                fun(StateAcc) -> mod_role_achievement:pet_step(Step, StateAcc) end,
                fun(StateAcc) -> mod_role_day_target:pet_star(StateAcc) end,
                fun(StateAcc) -> mod_role_confine:pet_step_up(Step, StateAcc) end,
                fun(StateAcc) -> mod_role_act_rank:pet_step(StateAcc) end
            ],
            FuncList2 =
                case ?GET_BASE_ID(OldPetID) =/= ?GET_BASE_ID(NewPetID) of
                    true -> %% 进大阶
                        [
                            fun(StateAcc) -> mod_role_day_target:pet_step(StateAcc) end,
                            fun(StateAcc) -> common_broadcast:send_world_common_notice(?NOTICE_PET_STEP_UP, [mod_role_data:get_role_name(State),
                                get_pet_name_by_id(NewPetID)]), StateAcc end
                        ] ++ FuncList;
                    _ ->
                        FuncList
                end,
            role_server:execute_state_fun(FuncList2, State5);
        {ok, PetID, StepExp} ->
            common_misc:unicast(RoleID, #m_pet_step_toc{new_pet_id = PetID, new_step_exp = StepExp}),
            State
    end.

check_can_step(State) ->  % T 进阶
    #r_role{role_pet = RolePet} = State,
    #r_role_pet{cur_id = CurID, pet_id = PetID, step_exp = StepExp} = RolePet,
    %% 看看能不能进行第一次升级
    case lib_config:find(cfg_pet, PetID + 1) of
        [#c_pet{}] ->
            ok;
        _ ->
            NewBaseID = ?GET_BASE_ID(PetID) + 1,
            case lib_config:find(cfg_pet_base, NewBaseID) of
                [#c_pet_base{}] ->
                    ok;
                _ ->
                    ?THROW_ERR(?ERROR_PET_LEVEL_UP_001)  % T  %%不能升级
            end
    end,
    [#c_pet{use_step_exp = UseStepExp}] = lib_config:find(cfg_pet, PetID),  % T %% 进阶消耗精华
    case StepExp >= UseStepExp of
        true ->
            {NewPetID, NewStepExp} = check_can_step2(PetID, StepExp), % T 可以进阶 返回升阶后的宠物ID和等级经验
            {IsChange, CurID2} = ?IF(?GET_BASE_ID(NewPetID) =/= ?GET_BASE_ID(PetID), {true, NewPetID}, {false, CurID}),
            RolePet2 = RolePet#r_role_pet{cur_id = CurID2, pet_id = NewPetID, step_exp = NewStepExp},
            State2 = State#r_role{role_pet = RolePet2},
            {ok, IsChange, PetID, NewPetID, NewStepExp, State2};
        _ ->
            {ok, PetID, StepExp}
    end.

%% 获取升级后的宠物ID和等阶经验
check_can_step2(PetID, StepExp) ->
    [#c_pet{use_step_exp = UseStepExp}] = lib_config:find(cfg_pet, PetID),
    case StepExp >= UseStepExp of
        true ->
            StepExp2 = StepExp - UseStepExp,
            case lib_config:find(cfg_pet, PetID + 1) of
                [#c_pet{}] ->
                    check_can_step2(PetID + 1, StepExp2);  %
                _ ->
                    NewBaseID = ?GET_BASE_ID(PetID) + 1,
                    NewPetID = ?GET_NORMAL_ID(NewBaseID) + 1,
                    case lib_config:find(cfg_pet, NewPetID) of
                        [#c_pet{}] ->
                            check_can_step2(NewPetID, StepExp2);  % T (BaseID * 100)).
                        _ ->
                            {PetID, 0}
                    end
            end;
        _ ->
            {PetID, StepExp}
    end.

%% 进阶导致宠物ID变化，可能会有新技能，先做检测
do_pet_step_skill(OldPetID, NewPetID, State) ->
    OldSkills = get_pet_step_skills(OldPetID),
    NewSkills = get_pet_step_skills(NewPetID),
    case OldSkills =/= NewSkills of
        true ->
            SkillNames = common_skill:get_skill_names(NewSkills -- OldSkills),
            common_broadcast:send_world_common_notice(?NOTICE_PET_SKILL_OPEN, [mod_role_data:get_role_name(State), SkillNames]),
            SurfaceSkills = get_surface_skill_by_state(State),
            mod_role_skill:skill_fun_change(?SKILL_FUN_PET, SurfaceSkills ++ NewSkills, State);
        _ ->
            State
    end.

%% 幻化ID变化，可能会有新技能
do_pet_surface_skill(PetID, OldState, State) ->
    OldSkills = get_surface_skill_by_state(OldState),
    NewSkills = get_surface_skill_by_state(State),
    case OldSkills =/= NewSkills of
        true ->
            StepSkills = get_pet_step_skills(PetID),
            mod_role_skill:skill_fun_change(?SKILL_FUN_PET, NewSkills ++ StepSkills, State);
        _ ->
            State
    end.

%% 宠物进阶带来的技能
get_pet_step_skills(0) ->
    [];
get_pet_step_skills(PetID) ->
    [#c_pet{skills = Skills}] = lib_config:find(cfg_pet, PetID),
    lists:sort(Skills).

get_surface_skill_by_state(State) ->
    #r_role{role_pet = #r_role_pet{surface_list = SurfaceList}} = State,
    lists:sort(lists:flatten([get_pet_surface_skills(SurfaceID) || #p_kv{id = SurfaceID} <- SurfaceList])).

%% 皮肤带来的技能
get_pet_surface_skills(0) ->
    [];
get_pet_surface_skills(SurfaceID) ->
    case lib_config:find(cfg_pet_surface, SurfaceID) of
        [#c_pet_surface{skill_list = SkillList}] ->
            SkillList;
        _ ->
            []
    end.

%% 幻化当前宠物
do_pet_change(RoleID, CurID, State) ->  % T 幻化宠物是已经激活了并且升级了的~~
    case catch check_can_change(CurID, State) of
        {ok, PetID, State2} ->
            common_misc:unicast(RoleID, #m_pet_change_toc{cur_id = CurID}),
            State3 = do_pet_surface_skill(PetID, State, State2),
            mod_role_skin:update_skin(State3);
        {error, ?ERROR_PET_CHANGE_002} ->
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_pet_change_toc{err_code = ErrCode}),
            State
    end.

check_can_change(CurID, State) ->
    #r_role{role_pet = RolePet} = State,
    #r_role_pet{cur_id = OldCurID, pet_id = PetID, surface_list = SurFaceList} = RolePet,
    ?IF(?GET_BASE_ID(OldCurID) =:= ?GET_BASE_ID(CurID), ?THROW_ERR(?ERROR_PET_CHANGE_001), ok), % T %%已经是该伙伴
    case lib_config:find(cfg_pet, CurID) of
        [_ConfigPet] ->
            ?IF(CurID =< PetID, ok, ?THROW_ERR(?ERROR_PET_CHANGE_002)),
            RolePet2 = RolePet#r_role_pet{cur_id = CurID},
            State2 = State#r_role{role_pet = RolePet2},
            State2;
        _ ->
            NewSurfaceIDList = lists:foldl(
                fun(X, Acc1) ->
                    #p_kv{id = SurfaceID} = X,
                    ?IF(?GET_BASE_ID(CurID) =:= ?GET_BASE_ID(SurfaceID) andalso CurID =< SurfaceID, [SurfaceID|Acc1], Acc1) end, [], SurFaceList),
            ?IF(NewSurfaceIDList =:= [], ?THROW_ERR(?ERROR_PET_CHANGE_002), ok), %%没有该伙伴，不能幻化
            [NewSurfaceID] = NewSurfaceIDList,
            RolePet2 = RolePet#r_role_pet{cur_id = NewSurfaceID},
            State2 = State#r_role{role_pet = RolePet2}
    end,
    {ok, PetID, State2}.

do_pet_surface_active(RoleID, BaseID, State) ->
    case catch check_pet_surface_active(BaseID, State) of
        {ok, IsNew, BagDoings, SurfaceID, Surface, RolePet, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_pet_surface_active_toc{surface = Surface}),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_PET_SKIN_ACTIVE, SurfaceID),
            case IsNew of
                true ->
                    [#c_pet_base{name = Name, broadcast_id = BroadcastID}] = lib_config:find(cfg_pet_base, ?GET_BASE_ID(SurfaceID)),
                    ?IF(BroadcastID > 0, common_broadcast:send_world_common_notice(BroadcastID, [mod_role_data:get_role_name(State), Name]), ok),
                    #r_role_pet{pet_id = PetID} = RolePet,
                    State5 = do_pet_surface_skill(PetID, State, State3),
                    common_misc:unicast(RoleID, #m_pet_change_toc{cur_id = SurfaceID}),
                    State6 = mod_role_skin:update_skin(State5),
                    mod_role_skin:update_couple_skin(?DB_ROLE_PET_P, ?GET_BASE_ID(SurfaceID), State6);
                _ ->
                    State4
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_pet_surface_active_toc{err_code = ErrCode}),
            State
    end.

check_pet_surface_active(BaseID, State) ->
    #r_role{role_pet = RolePet} = State,
    #r_role_pet{cur_id = OldCurID, surface_list = SurfaceList} = RolePet,
    {TypeID, Num, IsNew, Surface, SurfaceList2} = check_pet_surface_active2(SurfaceList, BaseID, []),
    BagDoings = mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_PET_SURFACE_ACTIVATE, State),
    SurfaceID = Surface#p_kv.id,
    IsNew2 = IsNew orelse ?GET_BASE_ID(OldCurID) =:= ?GET_BASE_ID(SurfaceID),
    RolePet2 = RolePet#r_role_pet{surface_list = SurfaceList2},
    RolePet3 = ?IF(IsNew2, RolePet2#r_role_pet{cur_id = SurfaceID}, RolePet2),
    State2 = State#r_role{role_pet = RolePet3},
    {ok, IsNew2, BagDoings, SurfaceID, Surface, RolePet3, State2}.

check_pet_surface_active2([], BaseID, SurfaceAcc) -> %% 全新激活
    ID = ?GET_NORMAL_ID(BaseID),
    [#c_pet_surface{need_item = TypeID, item_num = ItemNum}] = lib_config:find(cfg_pet_surface, ID),
    Surface = #p_kv{id = ID, val = 0},
    {TypeID, ItemNum, true, Surface, [Surface|SurfaceAcc]};
check_pet_surface_active2([Surface|R], BaseID, SurfaceAcc) ->
    #p_kv{id = SurfaceID} = Surface,
    case ?GET_BASE_ID(SurfaceID) =:= BaseID of %% 升阶
        true ->
            [#c_pet_surface{
                step = OldStep,
                need_item = TypeID,
                item_num = ItemNum}] = lib_config:find(cfg_pet_surface, SurfaceID),
            SurfaceID2 = SurfaceID + 1,
            case lib_config:find(cfg_pet_surface, SurfaceID2) of
                [Config] ->
                    #c_pet_surface{step = NewStep} = Config,
                    ?IF(NewStep > OldStep, ok, ?THROW_ERR(?ERROR_PET_SURFACE_ACTIVE_001)),
                    Surface2 = #p_kv{id = SurfaceID2, val = 0},
                    {TypeID, ItemNum, false, Surface2, [Surface2|R] ++ SurfaceAcc};
                _ ->
                    ?THROW_ERR(?ERROR_PET_SURFACE_ACTIVE_002)
            end;
        _ ->
            check_pet_surface_active2(R, BaseID, [Surface|SurfaceAcc])
    end.

do_pet_surface_step(RoleID, BaseID, ItemID, ItemNum, State) -> % T 宠物皮肤进阶
    case catch check_pet_surface_step(BaseID, ItemID, ItemNum, State) of
        {ok, IsLevelUp, IsChange, BagDoings, SurfaceID, Surface, RolePet, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_pet_surface_step_toc{surface = Surface}),
            State4 = ?IF(IsLevelUp, mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_PET_SKIN_STEP, SurfaceID), State3),
            case IsChange of
                true ->
                    #r_role_pet{cur_id = NewCurID, pet_id = PetID} = RolePet,
                    State5 = do_pet_surface_skill(PetID, State, State4),
                    common_misc:unicast(RoleID, #m_pet_change_toc{cur_id = NewCurID}),
                    mod_role_skin:update_skin(State5);
                _ ->
                    State4
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_pet_surface_step_toc{err_code = ErrCode}),
            State
    end.

check_pet_surface_step(BaseID, TypeID, ItemNumT, State) ->
    #r_role{role_pet = RolePet} = State,
    #r_role_pet{cur_id = OldCurID, surface_list = SurfaceList} = RolePet,
    ItemNum = erlang:max(1, ItemNumT),
    OneExp =
        case mod_role_item:get_item_config(TypeID) of
            #c_item{effect_type = ?ITEM_PTE_STEP_EXP, effect_args = AddStepExpT} ->
                lib_tool:to_integer(AddStepExpT);
            _ ->
                ?THROW_ERR(?ERROR_PET_SURFACE_STEP_001)
        end,
    {IsLevelUp, UseExp, Surface, SurfaceList2} = check_pet_surface_step2(SurfaceList, BaseID, OneExp * ItemNum, []),
    SurfaceID = Surface#p_kv.id,
    ItemNum2 = lib_tool:ceil(UseExp/OneExp),
    BagDoings = mod_role_bag:check_num_by_type_id(TypeID, ItemNum2, ?ITEM_REDUCE_PET_SURFACE_STEP, State),
    IsChange = IsLevelUp andalso ?GET_BASE_ID(OldCurID) =:= ?GET_BASE_ID(SurfaceID),
    RolePet2 = RolePet#r_role_pet{surface_list = SurfaceList2},
    RolePet3 = ?IF(IsChange, RolePet2#r_role_pet{cur_id = SurfaceID}, RolePet2),
    State2 = State#r_role{role_pet = RolePet3},
    {ok, IsLevelUp, IsChange, BagDoings, SurfaceID, Surface, RolePet3, State2}.

check_pet_surface_step2([], _BaseID, _AddStep, _SurfaceAcc) ->
    ?THROW_ERR(?ERROR_PET_SURFACE_STEP_002);
check_pet_surface_step2([Surface|R], BaseID, AddExp, SurfaceAcc) ->
    #p_kv{id = SurfaceID, val = OldExp} = Surface,
    case ?GET_BASE_ID(SurfaceID) =:= BaseID of %% 升阶
        true ->
            [#c_pet_surface{step = OldStep}] = lib_config:find(cfg_pet_surface, SurfaceID),
            SurfaceID2 = SurfaceID + 1,
            case lib_config:find(cfg_pet_surface, SurfaceID2) of
                [#c_pet_surface{step = NewStep}] when OldStep =:= NewStep -> %% 同一阶，能继续升
                    {Surface2, UseExp} = get_pet_surface_step_exp(SurfaceID, OldStep, OldExp, AddExp, 0),
                    IsLevelUp = Surface2#p_kv.id =/= Surface#p_kv.id,
                    {IsLevelUp, UseExp, Surface2, [Surface2|R] ++ SurfaceAcc};
                _ ->
                    ?THROW_ERR(?ERROR_PET_SURFACE_STEP_003)
            end;
        _ ->
            check_pet_surface_step2(R, BaseID, AddExp, [Surface|SurfaceAcc])
    end.

get_pet_surface_step_exp(SurfaceID, OldStep, Exp, AddExp, UseExp) ->
    SurfaceID2 = SurfaceID + 1,
    case lib_config:find(cfg_pet_surface, SurfaceID2) of
        [#c_pet_surface{step = Step}] when OldStep =:= Step ->
            [#c_pet_surface{step_exp = NeedStepExp}] = lib_config:find(cfg_pet_surface, SurfaceID),
            Exp2 = Exp + AddExp,
            case Exp2 >= NeedStepExp of
                true ->
                    UseExpAcc = NeedStepExp - Exp,
                    get_pet_surface_step_exp(SurfaceID2, OldStep, 0, AddExp - UseExpAcc, UseExpAcc + UseExp);
                _ ->
                    {#p_kv{id = SurfaceID, val = Exp2}, UseExp + (Exp2 - Exp)}
            end;
        _ ->
            {#p_kv{id = SurfaceID, val = 0}, UseExp}
    end.

get_pet_level_up_log(AddExp, GoodsList, Level, NewLevel, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_pet_level{
        role_id = RoleID,
        add_exp = AddExp,
        goods_list = common_misc:to_goods_string(GoodsList),
        old_level = Level,
        new_level = NewLevel,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.
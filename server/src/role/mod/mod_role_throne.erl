%%%-------------------------------------------------------------------
%%% @author yaolun
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 宝座系统
%%% @end
%%% Created : 28. 二月 2019 15:17
%%%-------------------------------------------------------------------
-module(mod_role_throne).
-author("yaolun").

-include("role.hrl").
-include("common.hrl").
-include("proto/mod_role_throne.hrl").
-include("throne.hrl").

-export([
    function_open/1,
    calc/1,
    online/1,
    handle/2
]).

-export([
    get_base_skins/1,
    add_throne_essence/2            %% 获取精华
]).


function_open(#r_role{role_id = RoleID, role_throne = undefined} = State) ->
    [{_,#c_throne_level{id = ThroneLevelId}}|_] = lib_config:list(cfg_throne_level),
    ThroneBaseId = ?GET_BASE_ID(ThroneLevelId),
    ThroneMap = maps:new(),
    ThroneMap2 = maps:put(ThroneBaseId, ThroneLevelId, ThroneMap),
    Status = 1,
    RoleThrone = #r_role_throne{role_id = RoleID, throne_id = ThroneLevelId,  status = Status, cur_id = ThroneBaseId, throne_map = ThroneMap2},
    State2 = State#r_role{role_throne = RoleThrone},
    State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_THRONE_ACTIVATE, RoleThrone#r_role_throne.throne_id),
    State4 = mod_role_skin:update_skin(State3),  %% 广播场景
    common_misc:unicast(RoleID, #m_throne_surface_toc{throne_id = ThroneLevelId}),
    common_misc:unicast(RoleID, #m_throne_upgrade_toc{throne_id = ThroneLevelId, total_essence = 0}),
    common_misc:unicast(RoleID, #m_throne_set_status_toc{status = Status}),
    State4;
function_open(State) ->
    State.

calc(#r_role{role_throne = undefined} = State) ->
    State;
calc(#r_role{role_throne = RoleThrone} = State) ->
    #r_role_throne{throne_map = ThroneMap, surface_map = SurFaceMap} = RoleThrone,
    {SkillList3, AddParam3} = maps:fold(fun(ThroneBaseId, ThroneId, {SkillList, [Hp, Attack, Defence, Arp]}) ->
        SkillList2 = case lib_config:find(cfg_throne_base, ThroneBaseId) of
            [] ->
                SkillList;
            [#c_throne_base{skill_list = ThroneSkill}] ->
                SkillList ++ ThroneSkill
        end,

        AddParam = case lib_config:find(cfg_throne_level, ThroneId) of
            [] ->
                [Hp, Attack, Defence, Arp];
            [#c_throne_level{add_hp = AddHp, add_attack = AddAttack, add_defense = AddDefense, add_arp = Addarp}] ->
                [AddHp + Hp, Attack + AddAttack, Defence + AddDefense, Arp + Addarp]
        end,
        {SkillList2, AddParam}
    end, {[], [0, 0, 0, 0]}, ThroneMap),

    {SkillList5, AddParam5} = maps:fold(fun(_K, #p_kv{id = SurfaceId}, {SkillList4, [Hp, Attack, Defence, Arp]}) ->
        case lib_config:find(cfg_throne_unreal_guise, SurfaceId) of
            [] ->
                {SkillList4, [Hp, Attack, Defence, Arp]};
            [#c_throne_unreal_guise{add_hp = AddHp, add_attack = AddAttack, add_defense = AddDefense, add_arp = Addarp, skill_list = UnrealSkills}] ->
                {SkillList4 ++ UnrealSkills, [AddHp + Hp, Attack + AddAttack, Defence + AddDefense, Arp + Addarp]}
        end
    end, {SkillList3, AddParam3}, SurFaceMap),
    [AddHp, AddAttack, AddDefence, AddArp] = AddParam5,
    CalAttr = #actor_cal_attr{
        max_hp = {AddHp, 0},
        attack = {AddAttack, 0},
        defence = {AddDefence, 0},
        arp = {AddArp, 0}
    },
    State2 = mod_role_skill:skill_fun_change(?SKILL_FUN_THRONE, SkillList5, State), %% 添加技能
    State3 = mod_role_fight:get_state_by_kv(State2, ?CALC_KEY_THRONE, CalAttr), %% 推送宝座的战力
    State3.

online(#r_role{role_throne = undefined} = State) ->
    State;
online(#r_role{role_id = RoleID } = State) ->
    Pthrone = get_throne(State),
    common_misc:unicast(RoleID, #m_throne_info_toc{op_type = 0, throne_info = Pthrone}),
    State.


%% 宝座升级
handle({#m_throne_upgrade_tos{}, RoleID, _PID}, State) ->
    do_throne_upgrade(RoleID, State);
%% 宝座道具分解精华
handle({#m_throne_resolve_tos{resolve_item_id = ItemIdList}, RoleID, _PID}, State) ->
    do_throne_resolve(RoleID, ItemIdList, State);
%% 宝座幻化激活
handle({#m_throne_surface_act_tos{surface_id = SurfaceId}, RoleID, _PID}, State) ->
    do_throne_surface_act(RoleID, SurfaceId, State);
%% 宝座幻化升级
handle({#m_throne_surface_upgarde_tos{surface_id = SurfaceId}, RoleID, _PID}, State) ->
    do_throne_surface_upgarde(RoleID, SurfaceId, State);
%% 宝座幻化使用,改变场景的形象
handle({#m_throne_surface_tos{throne_id = ThroneId}, RoleID, _PID}, State) ->
    do_throne_surface(RoleID, ThroneId, State);
%% 设置状态
handle({#m_throne_set_status_tos{status = UseStatus}, RoleID, _PID}, State) ->
    do_throne_set_status(RoleID, UseStatus, State);
handle(_, State) ->
    State.


get_throne(#r_role{role_throne = undefined}) ->
    #p_throne{};
get_throne(#r_role{role_throne = RoleThroneBook}) ->
    #r_role_throne{throne_id = ThroneId, cur_id = CurId, status = Status, throne_essence = ThroneEssence, accum_essence = AccumpEssence,
        throne_map = ThroneMap, surface_map = SurfaceMap} = RoleThroneBook,

    PvaList = maps:fold(fun(_K, Pkv, List) ->
        [Pkv|List]
    end, [], SurfaceMap),
    Pthrone = #p_throne{
        throne_id = ThroneId, cur_id = ?GET_NORMAL_ID(CurId) + 1, status = Status, throne_essence = ThroneEssence,
        throne_base_list = maps:keys(ThroneMap) ++ maps:keys(SurfaceMap), accum_essence = AccumpEssence,
        surface_list = lists:reverse(PvaList)
    },
    Pthrone.


%% 宝座升级
do_throne_upgrade(_RoleID, #r_role{role_throne = undefined} = State) ->
    State;
do_throne_upgrade(RoleID, #r_role{role_throne = RoleThrone} = State) ->
    #r_role_throne{status = Status} = RoleThrone,
    case catch check_throne_upgrade(State) of
        {ok, State2, ThroneEssence2, NextThroneId2, IsUp, AccumEssence2} ->
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_THRONE_UPGRADE, RoleThrone#r_role_throne.throne_id),
            State4 = ?IF(IsUp andalso Status =:= ?THRONE_STATUS_USE, mod_role_skin:update_skin(State3), State3),  %% 广播场景
            common_misc:unicast(RoleID, #m_throne_upgrade_toc{throne_id = NextThroneId2, total_essence = ThroneEssence2, accum_essence = AccumEssence2}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_throne_upgrade_toc{err_code = ErrCode}),
            State
    end.


check_throne_upgrade(#r_role{role_throne = RoleThrone} = State) ->
    #r_role_throne{throne_id = ThroneId, throne_map = ThroneMap, throne_essence = ThroneEssence, accum_essence = AccumEssence} = RoleThrone,
    BaseThroneId = ?GET_BASE_ID(ThroneId),
    [#c_throne_level{expend_essence = ExpendEssence}] = lib_config:find(cfg_throne_level, ThroneId),
    ?IF(ExpendEssence > 0, ok, ?THROW_ERR(?ERROR_THRONE_UPGRADE_001)),  %% 已到达满级
    ?IF(ThroneEssence >= 1, ok, ?THROW_ERR(?ERROR_THRONE_UPGRADE_002)), %% 精华不足

    case maps:find(BaseThroneId, ThroneMap) of
        {ok, ThroneId} ->
            NeedEssence = ExpendEssence - AccumEssence,
            case ThroneEssence >= NeedEssence of
                true -> %% 可以直接升级
                    ThroneEssence2 = ThroneEssence - NeedEssence,
                    {RoleThrone3, Isup} =
                        case lib_config:find(cfg_throne_level, ThroneId + 1) of
                            [] -> %% 到达一下个阶段
                                NextThroneId = (BaseThroneId + 1) * 100 + 1,
                                ThroneMap2 = maps:put(BaseThroneId + 1, NextThroneId, ThroneMap),

                                RoleThrone2 = RoleThrone#r_role_throne{throne_id = NextThroneId,
                                    throne_essence = ThroneEssence2, accum_essence = 0, throne_map = ThroneMap2},
                                {RoleThrone2, true};
                            [#c_throne_level{id = NextThroneId}] ->
                                ThroneMap2 = maps:put(BaseThroneId, NextThroneId, ThroneMap),
                                RoleThrone2 = RoleThrone#r_role_throne{throne_id = NextThroneId, throne_essence = ThroneEssence2,
                                    accum_essence = 0, throne_map = ThroneMap2},
                                {RoleThrone2, false}
                        end,
                    {ok, State#r_role{role_throne = RoleThrone3}, ThroneEssence2, RoleThrone3#r_role_throne.throne_id, Isup, 0};
                _ ->
                    AccumEssence2 = AccumEssence + ThroneEssence,
                    RoleThrone2 = RoleThrone#r_role_throne{throne_essence = 0, accum_essence = AccumEssence2},
                    {ok, State#r_role{role_throne = RoleThrone2}, 0, RoleThrone2#r_role_throne.throne_id, false, AccumEssence2}
            end;
        error ->
            ?THROW_ERR(?ERROR_THRONE_UPGRADE_003)
    end.



%% 宝座道具分解精华
do_throne_resolve(_RoleId, _ItemIdList, #r_role{role_throne = undefined} = State) ->
    State;
do_throne_resolve(RoleId, ItemIdList, State) ->
    case catch check_throne_resolve(ItemIdList, State) of
        {ok, BagDoing, State2, TotalEssence} ->
            %% 删除物品
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleId, #m_throne_resolve_toc{total_essence = TotalEssence}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleId, #m_throne_resolve_toc{err_code = ErrCode}),
            State
    end.


check_throne_resolve(ItemIdList, #r_role{role_throne = RoleThrone} = State) ->
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(ItemIdList, State),
    GetEssence = lists:foldl(fun(Goods, ToEssence) ->
        #p_goods{type_id = TypeId, num = Gnum} = Goods,
        case lib_config:find(cfg_item, TypeId) of
            [] ->
                ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM);
            [#c_item{effect_args = AddEssence}] ->
                TotalEssence = lib_tool:to_integer(AddEssence) * Gnum + ToEssence,
                TotalEssence
        end
    end, 0, GoodsList),
    BagDoing = [{delete, ?ITEM_REDUCE_THRONE_RESOLVE, ItemIdList}],

    #r_role_throne{throne_essence = Essence} = RoleThrone,
    Essence2 = GetEssence + Essence,
    State2 = State#r_role{role_throne = RoleThrone#r_role_throne{throne_essence = Essence2}},
    {ok, BagDoing, State2, Essence2}.



%% 宝座幻化激活
do_throne_surface_act(_, _, #r_role{role_throne = undefined} = State) ->
    State;
do_throne_surface_act(RoleID, SurfaceId, #r_role{role_throne = RoleThrone} = State) ->
    case catch check_throne_surface_act(SurfaceId, State) of
        {ok, BagDoing, State2, SurfaceId2} ->
            #r_role_throne{status = Status} = RoleThrone,
            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATA_THRONE_UNREAL_ACTIVATE, SurfaceId),
            State5 = ?IF(Status =:= ?THRONE_STATUS_USE, mod_role_skin:update_skin(State4), State4),  %% 广播场景
            common_misc:unicast(RoleID, #m_throne_surface_act_toc{surface = #p_kv{id = SurfaceId2, val = 0}}),
            State5;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_throne_surface_act_toc{err_code = ErrCode}),
            State
    end.


check_throne_surface_act(SurfaceId, #r_role{role_throne = RoleThrone} = State) ->
    SurfaceBaseId = ?GET_BASE_ID(SurfaceId),
    #r_role_throne{surface_map = SurfaceMap} = RoleThrone,
    ?IF(maps:find(SurfaceBaseId, SurfaceMap) =:= error, ok, ?THROW_ERR(?ERROR_THRONE_SURFACE_ACT_001)),

    CfgThroneUnreal = lib_config:find(cfg_throne_unreal_guise, SurfaceId),
    ?IF(CfgThroneUnreal =:= [], ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR), ok),

    [#c_throne_unreal_guise{upgrade_goods = ItemId, expend_goods_num = ItemNum}] = CfgThroneUnreal,
    %% 物品是否足够
    BagDoing = mod_role_bag:check_num_by_item_list([{ItemId, ItemNum}], ?ITEM_REDUCE_THRONE_SURFACE_ACT, State),

    SurfaceId2 = SurfaceId + 1,
    SurfaceMap2 = maps:put(SurfaceBaseId, #p_kv{id = SurfaceId2, val = 0}, SurfaceMap),
    RoleThrone2 = RoleThrone#r_role_throne{cur_id = ?GET_BASE_ID(SurfaceId2), surface_map = SurfaceMap2},

    State2 = State#r_role{role_throne = RoleThrone2},
    {ok, BagDoing, State2, SurfaceId2}.



%% 宝座幻化升级
do_throne_surface_upgarde(_RoleID, _SurfaceId, #r_role{role_throne = undefined} = State) ->
    State;
do_throne_surface_upgarde(RoleID, SurfaceId, State) ->
    case catch check_throne_surface_upgarde(SurfaceId, State) of
        {ok, BagDoing, State2} ->
            #r_role{role_throne = RoleThrone} = State2,
            #r_role_throne{surface_map = SurfaceMap} = RoleThrone,

            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATA_THRONE_UNREAL_ACTIVATE, SurfaceId),

            {ok, Pkv} = maps:find(?GET_BASE_ID(SurfaceId), SurfaceMap),
            common_misc:unicast(RoleID, #m_throne_surface_upgarde_toc{surface = Pkv}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_throne_surface_upgarde_toc{err_code = ErrCode}),
            State
    end.


check_throne_surface_upgarde(SurfaceId, #r_role{role_throne = RoleThrone} = State) ->
    SurfaceBaseId = ?GET_BASE_ID(SurfaceId),
    #r_role_throne{surface_map = SurfaceMap} = RoleThrone,
    SurfaceInfo = maps:find(SurfaceBaseId, SurfaceMap),
    ?IF(SurfaceInfo == error, ?THROW_ERR(?ERROR_THRONE_SURFACE_UPGARDE_001), ok),   %%还未激活，不能升级
    {ok, #p_kv{id = SurfaceId2, val = ConsumeNum}} = SurfaceInfo,
    ?IF(SurfaceId2 =:= SurfaceId, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)), %%参数有误

    CfgThroneUnreal = lib_config:find(cfg_throne_unreal_guise, SurfaceId),
    ?IF(CfgThroneUnreal =:= [], ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR), ok),

    [#c_throne_unreal_guise{upgrade_goods = ItemId, expend_goods_num = ItemNum}] = CfgThroneUnreal,
    ?IF(ItemId =:= 0 andalso ItemNum =:= 0, ?THROW_ERR(?ERROR_THRONE_SURFACE_UPGARDE_002), ok), %% 已经满级，不能再升级

    %% 物品是否足够
    BagDoing = mod_role_bag:check_num_by_item_list([{ItemId, 1}], ?ITEM_REDUCE_THRONE_SURFACE_UPGRADE, State),

    SurfaceMap2 = case ConsumeNum + 1 >= ItemNum of
        true -> %% 升级
            SurfaceId3 = SurfaceId + 1,
            maps:put(SurfaceBaseId, #p_kv{id = SurfaceId3, val = 0}, SurfaceMap);
        false ->
            maps:put(SurfaceBaseId, #p_kv{id = SurfaceId, val = ConsumeNum + 1}, SurfaceMap)
    end,

    RoleThrone2 = RoleThrone#r_role_throne{surface_map = SurfaceMap2},

    State2 = State#r_role{role_throne = RoleThrone2},
    {ok, BagDoing, State2}.



%% 宝座幻化使用,改变场景的形象
do_throne_surface(_RoleID, _ThroneId, #r_role{role_throne = undefined} = State) ->
    State;
do_throne_surface(RoleID, ThroneId, #r_role{role_throne = RoleThrone} = State) ->
    ThroneBaseId = ?GET_BASE_ID(ThroneId),
    #r_role_throne{status = Status} = RoleThrone,

    case catch check_throne_surface(ThroneBaseId, State) of
        {ok, State2} ->
            State3 = ?IF(Status =:= ?THRONE_STATUS_USE, mod_role_skin:update_skin(State2), State2),  %% 广播场景
            common_misc:unicast(RoleID, #m_throne_surface_toc{throne_id = ThroneId}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_throne_surface_toc{err_code = ErrCode}),
            State
    end.



check_throne_surface(ThroneBaseId, #r_role{role_throne = RoleThrone} = State) ->
    ?IF(lib_config:find(cfg_throne_base, ThroneBaseId) =:= [], ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok), %% 参数错误

    #r_role_throne{throne_map = ThroneMap, surface_map = SurfaceMap} = RoleThrone,
    ActList = lists:append(maps:keys(ThroneMap), maps:keys(SurfaceMap)),
    ?IF(lists:member(ThroneBaseId, ActList), ok, ?THROW_ERR(?ERROR_THRONE_SURFACE_001)), %% 此宝座还没激活，不能幻化

    RoleThrone2 = RoleThrone#r_role_throne{cur_id = ThroneBaseId},
    {ok, State#r_role{role_throne = RoleThrone2}}.



do_throne_set_status(_RoleID, _UseStatue, #r_role{role_throne = undefined} = State) ->
    State;
do_throne_set_status(RoleID, UseStatue, #r_role{role_throne = RoleThrone} = State) ->
    #r_role_throne{status = Statue} = RoleThrone,
    case UseStatue of
        Statue ->
            State;
        _ ->
            RoleThrone2 = RoleThrone#r_role_throne{status = UseStatue},
            State2 = State#r_role{role_throne = RoleThrone2},
            State3 = mod_role_skin:update_skin(State2),  %% 广播场景
            common_misc:unicast(RoleID, #m_throne_set_status_toc{status = UseStatue}),
            State3
    end.
get_base_skins(undefined) ->
    [];
get_base_skins(RoleThrone) ->
    #r_role_throne{surface_map = SurfaceMap} = RoleThrone,
    maps:fold(
        fun(_K, #p_kv{id = ID}, List) ->
            [?GET_BASE_ID(ID)|List]
        end, [], SurfaceMap).

%% 获取精华
add_throne_essence(AddEssence, #r_role{role_id = RoleID, role_throne = RoleThrone} = State) when AddEssence > 0 ->
    #r_role_throne{throne_essence = ThroneEssence} = RoleThrone,
    TotalEssence = ThroneEssence + AddEssence,
    RoleThrone2 = RoleThrone#r_role_throne{throne_essence = TotalEssence},
    common_misc:unicast(RoleID, #m_throne_essence_toc{total_essence = TotalEssence}),
    State#r_role{role_throne = RoleThrone2};
add_throne_essence(_AddEssence, State) ->
    State.
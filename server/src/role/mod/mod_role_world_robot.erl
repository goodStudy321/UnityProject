%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 五月 2018 10:44
%%%-------------------------------------------------------------------
-module(mod_role_world_robot).
-author("laijichang").
-include("rank.hrl").
-include("role.hrl").
-include("world_robot.hrl").
-include("role_extra.hrl").
-include("drop.hrl").
-include("proto/mod_role_world_robot.hrl").
-include("proto/mod_role_item.hrl").

%% API

-export([
    add_time/2,
    get_off_line_reward/2
]).

-export([
    gm_reward/2
]).

%%pre_enter(State) ->
%%    #r_role{role_id = RoleID, role_private_attr = PrivateAttr} = State,
%%    #r_role_private_attr{offline_fight_time = OfflineFightTime} = PrivateAttr,
%%    case OfflineFightTime > 0 andalso is_fit_level(State) of
%%        true ->
%%            world_robot_server:role_pre_enter(RoleID),
%%            State;
%%        _ ->
%%            State
%%    end.
%%
%%pre_online(State) ->
%%    #r_role{role_id = RoleID, role_private_attr = PrivateAttr} = State,
%%    #r_role_private_attr{offline_fight_time = OfflineFightTime} = PrivateAttr,
%%    case OfflineFightTime > 0 andalso is_fit_level(State) of
%%        true ->
%%            {ok, FightTime, TypeID} = world_robot_server:role_online(RoleID),
%%            case FightTime > 0 of
%%                true ->
%%                    FightMin = erlang:max(1, FightTime div 60),
%%                    do_reward(FightMin, TypeID, State);
%%                _ ->
%%                    State
%%            end;
%%        _ ->
%%            State
%%    end.

do_reward(FightMin, TypeID, State) ->
    FightMin2 = erlang:min(FightMin, common_misc:get_global_int(?GLOBAL_WORLD_ROBOT_HOUR) * 60),
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_private_attr = PrivateAttr, role_fight = RoleFight} = State,
    #r_role_attr{level = RoleLevel} = RoleAttr,
    #r_role_private_attr{offline_fight_time = OfflineFightTime} = PrivateAttr,
        OfflineFightTime2 = erlang:max(0, OfflineFightTime - FightMin2 * ?ONE_MINUTE),
    DpsEfficiency = mod_role_fight:get_dps_efficiency(State),
    [#c_dynamic_standard{dps = Dps}] = lib_config:find(cfg_dynamic_standard, RoleLevel),
    KillMonster = erlang:round(erlang:min(4, DpsEfficiency/Dps) * ?ONE_MINUTE * FightMin2),
    #r_role_fight{base_attr = #actor_fight_attr{monster_exp_add = ExpAdd}} = RoleFight,
    {AddExp, GoodsList, State2} = get_exp_and_goods(TypeID, KillMonster, State),
    KillExpEfficiency = erlang:round(AddExp/FightMin2),

    {AddSilver, AddPetExp, PetGoods, GoodsList2} = modify_goods(GoodsList, 0, 0, [], []),
    AddPetExp2 = lib_tool:ceil(AddPetExp * (1 + (mod_role_vip:get_pet_exp_rate(State) / ?RATE_10000))),
    MissionGoods = mod_role_mission:get_offline_mission_goods(TypeID, KillMonster, State),
    GoodsList3 = MissionGoods ++ GoodsList2,
    AddExp2 = lib_tool:ceil(AddExp * (1 + ExpAdd/?RATE_10000)),
    {BuffRate, BuffTime} = mod_role_buff:get_pellet_exp_args(State),
    BuffMinuteRate = erlang:min((BuffTime div ?ONE_MINUTE)/FightMin2, 1),
    BuffExp = lib_tool:ceil(AddExp * BuffMinuteRate * BuffRate/?RATE_10000),
    AddExp3 = AddExp2 + BuffExp,
    DataRecord = #m_role_attr_change_toc{kv_list = [#p_dkv{id = ?ATTR_OFFLINE_FIGHT_TIME, val = OfflineFightTime2}]},
    common_misc:unicast(RoleID, DataRecord),
    PrivateAttr2 = PrivateAttr#r_role_private_attr{offline_fight_time = OfflineFightTime2},
    State3 = State2#r_role{role_private_attr = PrivateAttr2},
    #r_role{role_attr = #r_role_attr{level = NewLevel}} = State4 = mod_role_level:do_add_exp(State3, AddExp3, ?EXP_ADD_FROM_WORLD_ROBOT),
    DataRecord2 = #m_offline_reward_toc{
        offline_min = FightMin2,
        old_level = RoleLevel,
        new_level = NewLevel,
        exp = AddExp3,
        add_silver = AddSilver,
        pet_exp = AddPetExp2,
        pet_goods = PetGoods,
        goods = GoodsList3},
    common_misc:unicast(RoleID, DataRecord2),
    mod_role_rank:update_rank(?RANK_OFFLINE_EFFICIENCY, {RoleID, KillExpEfficiency, time_tool:now()}),
    %% emmmm 从online顺序上来说，不用再回调了。。
    State5 = mod_role_extra:set_data(?EXTRA_KEY_EXP_EFFICIENCY, KillExpEfficiency, State4),
    AssetDoing = [{add_silver, ?ASSET_SILVER_ADD_FROM_WORLD_ROBOT, AddSilver}],
    State6 = mod_role_asset:do(AssetDoing, State5),
    State7 = mod_role_pet:add_exp(AddPetExp2, State6),
    State8 = mod_role_achievement:kill_monster(TypeID, NewLevel, KillMonster, State7),
    role_misc:create_goods(State8, ?ITEM_GAIN_WORLD_ROBOT, GoodsList3).


%%offline(State) ->
%%    #r_role{role_id = RoleID, role_private_attr = PrivateAttr} = State,
%%    #r_role_private_attr{offline_fight_time = OfflineFightTime} = PrivateAttr,
%%    case OfflineFightTime > 0 andalso is_fit_level(State) of
%%        true ->
%%            world_robot_server:role_offline(RoleID, OfflineFightTime);
%%        _ ->
%%            State
%%    end,
%%    State.

add_time(Min, State) ->
    #r_role{role_id = RoleID, role_private_attr = PrivateAttr} = State,
    #r_role_private_attr{offline_fight_time = OfflineFightTime} = PrivateAttr,
    MaxTime = common_misc:get_global_int(?GLOBAL_WORLD_ROBOT_HOUR) * ?AN_HOUR,
    ?IF(OfflineFightTime >= MaxTime, ?THROW_ERR(?ERROR_ITEM_USE_012), ok),
    OfflineFightTime2 = erlang:min(OfflineFightTime + Min * ?ONE_MINUTE, MaxTime),
    DataRecord = #m_role_attr_change_toc{kv_list = [#p_dkv{id = ?ATTR_OFFLINE_FIGHT_TIME, val = OfflineFightTime2}]},
    common_misc:unicast(RoleID, DataRecord),
    PrivateAttr2 = PrivateAttr#r_role_private_attr{offline_fight_time = OfflineFightTime2},
    State#r_role{role_private_attr = PrivateAttr2}.

gm_reward(Min, State) ->
    #r_role{role_attr = #r_role_attr{level = RoleLevel}} = State,
    TypeID = get_level_monster(RoleLevel, cfg_map_base:list()),
    do_reward(Min, TypeID, State).

modify_goods([], AddSilver, AddPetExp, PetGoods, GoodsList) ->
    {AddSilver, AddPetExp, PetGoods, GoodsList};
modify_goods([Goods|R], AddSilver, AddPetExp, PetGoods, GoodsList) ->
    #p_goods{type_id = TypeID, num = Num} = Goods,
    case lib_config:find(cfg_equip, TypeID) of
        [Equip] ->
            #c_equip{quality = Quality, star = Star, pet_exp = PetExp} = Equip,
            if
                Quality < ?RUNE_QUALITY_PURPLE -> %% 紫色以下直接出售
                    #c_item{sell_silver = Silver} = mod_role_item:get_item_config(TypeID),
                    modify_goods(R, AddSilver + lib_tool:ceil(Silver * Num), AddPetExp, PetGoods, GoodsList);
                Quality =:= ?RUNE_QUALITY_PURPLE andalso Star =:= 0 -> %% 0星装备直接变成宠物经验
                    modify_goods(R, AddSilver, AddPetExp + lib_tool:ceil(PetExp * Num), [Goods|PetGoods], GoodsList);
                true ->
                    modify_goods(R, AddSilver, AddPetExp, PetGoods, [Goods|GoodsList])
            end;
        _ ->
            modify_goods(R, AddSilver, AddPetExp, PetGoods, [Goods|GoodsList])
    end.

get_level_monster(_RoleLevel, []) ->
    200105;
get_level_monster(RoleLevel, [{_MapID, Config}|R]) ->
    #c_map_base{seqs = Seqs} = Config,
    case get_level_monster2(RoleLevel, Seqs) of
        {ok, TypeID} ->
            TypeID;
        _ ->
            get_level_monster(RoleLevel, R)
    end.

get_level_monster2(_RoleLevel, []) ->
    false;
get_level_monster2(RoleLevel, [SeqID|R]) ->
    case lib_config:find(cfg_map_seq, SeqID) of
        [Seq] ->
            #c_map_seq{
                monster_type_id = TypeID,
                min_level = MinLevel,
                max_level = MaxLevel} = Seq,
            case TypeID > 0 andalso MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel of
                true ->
                    {ok, TypeID};
                _ ->
                    get_level_monster2(RoleLevel, R)
            end;
        _ ->
            get_level_monster2(RoleLevel, R)
    end.

%%is_fit_level(State) ->
%%    NeedLevel = common_misc:get_global_int(?GLOBAL_ROBOT_LEVEL),
%%    mod_role_data:get_role_level(State) >= NeedLevel.



get_off_line_reward(#r_role{ role_attr = RoleAttr} = State,FightMin)->
    #r_robot_pos{ monster_type_id = TypeID} = world_robot_server:call_get_level_pos(RoleAttr#r_role_attr.level),
    FightMin2 = erlang:min(FightMin, common_misc:get_global_int(?GLOBAL_WORLD_ROBOT_HOUR) * 60),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{level = RoleLevel} = RoleAttr,
    DpsEfficiency = mod_role_fight:get_dps_efficiency(State),
    [#c_dynamic_standard{dps = Dps}] = lib_config:find(cfg_dynamic_standard, RoleLevel),
    KillMonster = erlang:round(erlang:min(4, DpsEfficiency/Dps) * ?ONE_MINUTE * FightMin2),
    {_AddExp, GoodsList, State2} = get_exp_and_goods(TypeID, KillMonster, State),
    {AddSilver, AddPetExp, PetGoods, GoodsList2} = modify_goods(GoodsList, 0, 0, [], []),
    {AddSilver, AddPetExp, PetGoods, GoodsList2, State2}.

get_exp_and_goods(TypeID, KillMonster, State) ->
    {Exp, DropIDList} = monster_misc:get_monster_exp_drop(TypeID),
    RoleIndexList = mod_role_extra:get_data(?EXTRA_KEY_ITEM_DROP_LIST, [], State),
    {GoodsList, RoleIndexList2} = get_world_robot_drop(DropIDList, KillMonster, RoleIndexList),
    State2 = mod_role_extra:set_data(?EXTRA_KEY_ITEM_DROP_LIST, RoleIndexList2, State),
    GoodsList2 = mod_role_bag:get_create_list(GoodsList),
    {Exp * KillMonster, GoodsList2, State2}.

get_world_robot_drop(DropIDList, KillMonster, RoleIndexList) ->
    get_world_robot_drop2(DropIDList, KillMonster, RoleIndexList, []).

get_world_robot_drop2([], _KillMonster, RoleIndexList, Acc) ->
    {Acc, RoleIndexList};
get_world_robot_drop2([DropID|R], KillMonster, RoleIndexList, GoodsAcc) ->
    [#c_drop{drop_bag_list = DropBagList}] = lib_config:find(cfg_drop, DropID),
    {MaxGenNum, GoodsList} = get_world_robot_drop3(DropBagList, KillMonster, 0, []),
    case MaxGenNum > 0 andalso GoodsList =/= [] of
        true ->
            MaxGenNum2 =
                case lib_config:find(cfg_drop_item, DropID) of
                    [#c_drop_item{personal_num = PersonalNum}] ->
                        erlang:min(PersonalNum, MaxGenNum);
                    _ ->
                        MaxGenNum
                end,
            {IsDrop,RoleIndexList2} =
                lists:foldl(
                    fun(_GenNumIndex, {IsDropAcc, RoleIndexAcc}) ->
                        {IsDropT, RoleIndexAcc2} = mod_map_drop:do_role_item_control(DropID, RoleIndexAcc),
                        {IsDropT orelse IsDropAcc, RoleIndexAcc2}
                    end, {false, RoleIndexList}, lists:seq(1, erlang:min(100, MaxGenNum2))), %% 这里最多取100
            case IsDrop of
                true ->
                    get_world_robot_drop2(R, KillMonster, RoleIndexList2, GoodsList ++ GoodsAcc);
                _ ->
                    get_world_robot_drop2(R, KillMonster, RoleIndexList2, GoodsAcc)
            end;
        _ ->
            get_world_robot_drop2(R, KillMonster, RoleIndexList, GoodsAcc)
    end.

get_world_robot_drop3([], _KillMonster, MaxGenNum, GoodsAcc) ->
    {MaxGenNum, GoodsAcc};
get_world_robot_drop3([{Weight, {Num, ItemID}}|R], KillMonster, MaxGenNum, GoodsAcc) ->
    Weight2 = Weight * KillMonster,
    GenNum = Weight2 div ?DROP_WEIGHT,
    RemainWeight =  Weight2 rem ?DROP_WEIGHT,
    GenNum2 = ?IF(RemainWeight >= lib_tool:random(?DROP_WEIGHT), GenNum + 1, GenNum),
    case GenNum2 > 0 of
        true ->
            MaxGenNum2 = erlang:max(GenNum2, MaxGenNum),
            case catch mod_map_drop:get_really_id(ItemID) of
                {ok, TypeID} when TypeID > 0 ->
                    Goods = #p_goods{type_id = TypeID, num = GenNum2 * Num, bind = false},
                    get_world_robot_drop3(R, KillMonster, MaxGenNum2, [Goods|GoodsAcc]);
                _ ->
                    get_world_robot_drop3(R, KillMonster, MaxGenNum2, GoodsAcc)
            end;
        _ ->
            get_world_robot_drop3(R, KillMonster, MaxGenNum, GoodsAcc)
    end.

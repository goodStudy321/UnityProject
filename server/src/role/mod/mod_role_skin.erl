%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 九月 2017 12:04
%%%-------------------------------------------------------------------
-module(mod_role_skin).
-author("laijichang").
-include("role.hrl").
-include("marry.hrl").
-include("proto/mod_role_skin.hrl").
-include("proto/mod_role_wing.hrl").

%% API
-export([
    online/1
]).

-export([
    update_skin/1,
    update_skin/2,

    update_couple_skin/3
]).

-export([
    get_base_skins_by_state/1,
    get_base_skins_by_role_id/1
]).

-export([
    gm_set_ornament/2,
    gm_add_skin_id/2,
    update_ornament/1
]).

online(State) ->
    #r_role{role_id = RoleID, role_marry = RoleMarry} = State,
    #r_role_marry{couple_id = CoupleID} = RoleMarry,
    BaseIDs = ?IF(?HAS_COUPLE(CoupleID), get_base_skins_by_role_id(CoupleID), []),
    common_misc:unicast(RoleID, #m_couple_skin_info_toc{base_id_list = BaseIDs}),
    State.

update_skin(State, IsFashionFirst) ->
    #r_role{role_fashion = RoleFashion} = State,
    update_skin(State#r_role{role_fashion = RoleFashion#r_role_fashion{is_fashion_first = IsFashionFirst}}).

update_skin(State) ->
    #r_role{role_attr = RoleAttr, role_id = RoleID} = State,
    OldSkins = RoleAttr#r_role_attr.skin_list,
    NewSkins = get_skin_list(State),
    case OldSkins =/= NewSkins of
        true ->
            mod_map_role:update_role_skin_list(mod_role_dict:get_map_pid(), RoleID, NewSkins),
            RoleAttr2 = RoleAttr#r_role_attr{skin_list = NewSkins},
            State2 = State#r_role{role_attr = RoleAttr2},
            mod_role_team:update_role_info(State2),
            mod_role_node:update_role_cross_data(State2),
            State2;
        _ ->
            State
    end.

get_skin_list(State) ->
    #r_role{
        role_fashion = RoleFashion,
        role_mount = RoleMount,
        role_magic_weapon = RoleMagicWeapon,
        role_pet = RolePet,
        role_god_weapon = RoleGodWeapon,
        role_wing = RoleWing,
        role_throne = RoleThrone
        } = State,
    #r_role_fashion{is_fashion_first = IsFashionFirst} = RoleFashion,
    List1 = get_weapon_fashion_list(get_cur_id(RoleFashion), get_cur_id(RoleGodWeapon), IsFashionFirst),
    List2 =
        [
            get_cur_id(RoleMount),
            get_cur_id(RoleMagicWeapon),
            get_cur_id(RolePet),
            get_cur_id(RoleWing),
            get_cur_id(RoleThrone)
        ],
    [ SkinID || SkinID <- List1 ++ List2, SkinID > 0].

get_cur_id(#r_role_fashion{cur_id_list = CurIDList}) ->
    CurIDList;
get_cur_id(#r_role_throne{cur_id = CurID, status = Status}) ->  % 宝座
    ?IF(Status =:= ?THRONE_STATUS_HIDE, 0, ?GET_NORMAL_ID(CurID) + 1);
get_cur_id(#r_role_mount{cur_id = CurID, mount_id = MountID, status = Status}) ->  % T 坐骑
    ?IF(Status =:= ?MOUNT_STATUS_DOWN, 0, ?IF(CurID > 0, CurID, MountID));
get_cur_id(#r_role_magic_weapon{cur_id = CurID, skin_list = SkinList}) ->
    get_common_cur_id(CurID, SkinList);
get_cur_id(#r_role_pet{cur_id = CurID, pet_id = PetID}) ->   % T 宠物（伙伴）
    ?IF(CurID > 0, CurID, PetID);
get_cur_id(#r_role_god_weapon{cur_id = CurID, skin_list = SkinList}) -> % T 法宝
    get_common_cur_id(CurID, SkinList);
get_cur_id(#r_role_wing{cur_id = CurID, skin_list = SkinList}) ->
    get_common_cur_id(CurID, SkinList);
get_cur_id(undefined) ->
    0.


get_weapon_fashion_list(FashionList, GodWeaponID, IsFashionFirst) ->
    {WeaponID, OtherList} = mod_role_fashion:skin_filter(FashionList),
    if
        WeaponID =:= 0 ->
            [GodWeaponID|OtherList];
        GodWeaponID =:= 0 ->
            [WeaponID|OtherList];
        IsFashionFirst ->
            [WeaponID|OtherList];
        true ->
            [GodWeaponID|OtherList]
    end.


get_common_cur_id(CurID, SkinList) ->
    case CurID > 0 orelse SkinList =:= [] of
        true ->
            CurID;
        _ ->
            [#p_kv{id = ID}|_] = lists:sort(fun(#p_kv{id = ID1}, #p_kv{id = ID2}) -> ID1 >= ID2 end, SkinList),
            ID
    end.

update_couple_skin(Table, BaseID, State) ->
    #r_role{role_marry = #r_role_marry{couple_id = CoupleID}} = State,
    ?IF(?HAS_COUPLE(CoupleID), common_misc:unicast(CoupleID, #m_couple_skin_update_toc{base_id = BaseID}), ok),
    role_server:dump_table(Table, State).

get_base_skins_by_state(State) ->
    List = [
        {#r_role.role_fashion, mod_role_fashion},
        {#r_role.role_mount, mod_role_mount},
        {#r_role.role_pet, mod_role_pet},
        {#r_role.role_magic_weapon, mod_role_magic_weapon},
        {#r_role.role_god_weapon, mod_role_god_weapon},
        {#r_role.role_wing, mod_role_wing},
        {#r_role.role_throne, mod_role_throne}
    ],
    lists:foldl(
        fun({Index, Mod}, Acc) ->
            get_base_skins(Mod, erlang:element(Index, State)) ++ Acc
        end, [], List).

get_base_skins_by_role_id(0) ->
    [];
get_base_skins_by_role_id(RoleID) ->
    List = [
        {?DB_ROLE_FASHION_P, mod_role_fashion},
        {?DB_ROLE_MOUNT_P, mod_role_mount},
        {?DB_ROLE_PET_P, mod_role_pet},
        {?DB_ROLE_MAGIC_WEAPON_P, mod_role_magic_weapon},
        {?DB_ROLE_GOD_WEAPON_P, mod_role_god_weapon},
        {?DB_ROLE_WING_P, mod_role_wing},
        {?DB_ROLE_THRONE_P, mod_role_throne}
    ],
    lists:foldl(
        fun({Tab, Mod}, Acc) ->
            case db:lookup(Tab, RoleID) of
                [Tuple] ->
                    get_base_skins(Mod, Tuple) ++ Acc;
                _ ->
                    Acc
            end
        end, [], List).

get_base_skins(Mod, Tuple) ->
    case erlang:function_exported(Mod, get_base_skins, 1) of
        true ->
            erlang:apply(Mod, get_base_skins, [Tuple]);
        _ ->
            ?WARNING_MSG("Mod not exported function:get_base_skins/1"),
            []
    end.

gm_set_ornament(IDList, State) ->
    #r_role{role_attr = RoleAttr} = State,
    RoleAttr2 = RoleAttr#r_role_attr{ornament_list = IDList},
    State2 = State#r_role{role_attr = RoleAttr2},
    update_ornament(State2).

gm_add_skin_id(ID, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{skin_list = SkinList} = RoleAttr,
    SkinList2 = [ID|SkinList],
    RoleAttr2 = RoleAttr#r_role_attr{skin_list = SkinList2},
    State2 = State#r_role{role_attr = RoleAttr2},
    mod_map_role:update_role_skin_list(mod_role_dict:get_map_pid(), RoleID, SkinList2),
    State2.

update_ornament(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{ornament_list = OrnamentList} = RoleAttr,
    mod_map_role:update_role_ornament_list(mod_role_dict:get_map_pid(), RoleID, OrnamentList),
    mod_role_team:update_role_info(State),
    State.


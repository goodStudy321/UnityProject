%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 一月 2018 19:21
%%%-------------------------------------------------------------------
-module(mod_family_depot).
-author("laijichang").
-include("role.hrl").
-include("family.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    family_donate/5,
    family_del_depot/2,
    family_exchange_depot/5
]).

-export([
    handle/1
]).

-export([
    change_member_integral/4,
    gm_update_family_int/2
]).


family_donate(RoleID, FamilyID, GoodsList, DonateInt, RoleName) ->
    family_misc:call_family({mod, ?MODULE, {family_donate, RoleID, FamilyID, GoodsList, DonateInt, RoleName}}).
family_del_depot(RoleID, GoodsIDList) ->
    family_misc:info_family({mod, ?MODULE, {family_del_depot, RoleID, GoodsIDList}}).
family_exchange_depot(RoleID, FamilyID, GoodsID, Num, RoleName) ->
    family_misc:call_family({mod, ?MODULE, {family_exchange_depot, RoleID, FamilyID, GoodsID, Num, RoleName}}).

handle({gm_update_integral, RoleID, Integral}) ->
    do_update_integral(RoleID, Integral);
handle({family_donate, RoleID, FamilyID, GoodsList, DonateInt, RoleName}) ->
    do_family_donate(RoleID, FamilyID, GoodsList, DonateInt, RoleName);
handle({family_del_depot, RoleID, GoodsIDList}) ->
    do_family_del_depot(RoleID, GoodsIDList);
handle({family_exchange_depot, RoleID, FamilyID, GoodsID, Num, RoleName}) ->
    do_family_exchange_depot(RoleID, FamilyID, GoodsID, Num, RoleName).

%% 捐献装备
do_family_donate(RoleID, FamilyID, GoodsList, DonateInt, RoleName) ->
    case catch check_family_donate(RoleID, FamilyID, GoodsList, DonateInt, RoleName) of
        {ok, UpdateGoods, NewInt, OldInt, FamilyID, FamilyData} ->
            DataRecord = #m_family_depot_update_toc{update_goods = UpdateGoods},
            common_broadcast:bc_record_to_family(FamilyID, DataRecord),
            mod_family_data:set_family(FamilyData),
            {ok, NewInt, OldInt};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_family_donate(RoleID, FamilyID, GoodsList, DonateInt, RoleName) ->
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_DONATE_001)),
    #p_family{depot = Depot, members = Members} = FamilyData = mod_family_data:get_family(FamilyID),
    {NewMembers, NewIntegral, OldInt} = change_member_integral(Members, RoleID, DonateInt, add),
    ?IF(erlang:length(Depot) + erlang:length(GoodsList) > ?MAX_DEPOT_NUM, ?THROW_ERR(?ERROR_FAMILY_DONATE_004), ok),
    AllID = lists:seq(1, ?MAX_DEPOT_NUM),
    GoodsIDList = [ID || #p_goods{id = ID} <- Depot],
    RemainList = AllID -- GoodsIDList,
    GoodsList2 = check_family_donate2(GoodsList, RemainList, []),
    Depot2 = GoodsList2 ++ Depot,
    FamilyData2 = FamilyData#p_family{depot = Depot2, members = NewMembers},
    FamilyData3 = add_family_depot_log(FamilyData2, RoleName, GoodsList, ?FAMILY_DEPOT_DONATE),
    {ok, GoodsList2, NewIntegral, OldInt, FamilyID, FamilyData3}.

check_family_donate2([], _RemainList, GoodsAcc) ->
    GoodsAcc;
check_family_donate2([Goods | R], [ID | R2], GoodsAcc) ->
    GoodsAcc2 = [Goods#p_goods{id = ID} | GoodsAcc],
    check_family_donate2(R, R2, GoodsAcc2).

%% 删除装备
do_family_del_depot(RoleID, GoodsIDList) ->
    case catch check_del_depot(RoleID, GoodsIDList) of
        {ok, FamilyID, FamilyData} ->
            common_broadcast:bc_record_to_family(FamilyID, #m_family_depot_update_toc{del_goods = GoodsIDList}),
            common_misc:unicast(RoleID, #m_family_del_depot_toc{}),
            mod_family_data:set_family(FamilyData);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_del_depot_toc{err_code = ErrCode})
    end.

check_del_depot(RoleID, GoodsIDList) ->
    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_DEL_DEPOT_001)),
    #p_family{depot = Depot} = FamilyData = mod_family_data:get_family(FamilyID),
    ?IF(family_misc:is_owner_or_vice_owner(RoleID, FamilyData), ok, ?THROW_ERR(?ERROR_FAMILY_DEL_DEPOT_002)),
    Depot2 = check_del_depot2(GoodsIDList, Depot),
    FamilyData2 = FamilyData#p_family{depot = Depot2},
    {ok, FamilyID, FamilyData2}.

check_del_depot2([], Depot) ->
    Depot;
check_del_depot2([GoodsID | R], Depot) ->
    case lists:keytake(GoodsID, #p_goods.id, Depot) of
        {value, _, Depot2} ->
            check_del_depot2(R, Depot2);
        _ ->
            ?THROW_ERR(?ERROR_FAMILY_DEL_DEPOT_003)
    end.

%% 兑换装备
do_family_exchange_depot(RoleID, FamilyID, GoodsID, Num, RoleName) ->
    case catch check_exchange_depot(RoleID, FamilyID, GoodsID, Num, RoleName) of
        {ok, Goods, NewInt, OldInt, FamilyID, FamilyData} ->
            mod_family_data:set_family(FamilyData),
            ?IF(GoodsID =:= 1, ok, common_broadcast:bc_record_to_family(FamilyID, #m_family_depot_update_toc{del_goods = [GoodsID]})),
            {ok, Goods, NewInt, OldInt};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_exchange_depot(RoleID, FamilyID, GoodsID, Num, RoleName) ->
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_EXCHANGE_DEPOT_001)),
    #p_family{depot = Depot, members = Members} = FamilyData = mod_family_data:get_family(FamilyID),
    if
        GoodsID =:= 1 ->
            Depot2 = Depot,
            Goods = #p_goods{type_id = ?DEPOT_FIRST_GRID, num = Num ,bind = true},
            [#c_global{int = OneNeedCon}] = lib_config:find(cfg_global, ?DEPOT_FIRST_GRID_GLOBAL),
            NeedCon = OneNeedCon * Num;
        true ->
            case lists:keytake(GoodsID, #p_goods.id, Depot) of
                {value, Goods, Depot2} ->
                    #p_goods{type_id = TypeID} = Goods,
                    [#c_item{exchange_contribution = NeedCon}] = lib_config:find(cfg_item, TypeID);
                _ ->
                    NeedCon = Goods = Depot2 = ?THROW_ERR(?ERROR_FAMILY_DEL_DEPOT_003)
            end
    end,
    {NewMembers, NewInt, OldInt} = change_member_integral(Members, RoleID, NeedCon, reduce),
    case NewInt >= 0 of
        true ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_FAMILY_EXCHANGE_DEPOT_005)
    end,
    ?IF(NewInt >= 0, ok, ?THROW_ERR(?ERROR_FAMILY_EXCHANGE_DEPOT_005)),
    FamilyData2 = FamilyData#p_family{depot = Depot2, members = NewMembers},
    FamilyData3 = add_family_depot_log(FamilyData2, RoleName, [Goods], ?FAMILY_DEPOT_EXCHANGE),
    {ok, Goods, NewInt, OldInt, FamilyID, FamilyData3}.



add_family_depot_log(#p_family{depot_log = DepotLog, family_id = FamilyID} = FamilyData, RoleName, GoodsList, Type) ->
    NewLogs = [#p_family_depot_log{role_name = RoleName, type = Type, goods = Goods} || Goods <- GoodsList],
    BcInfo = #m_family_depot_log_update_toc{depot_log = NewLogs},
    common_broadcast:bc_record_to_family(FamilyID, BcInfo),
    NewLogs2 = NewLogs ++ DepotLog,
    DepotLog2 = depot_log_delete(erlang:length(NewLogs2), lists:reverse(NewLogs2)),
    FamilyData#p_family{depot_log = DepotLog2}.

depot_log_delete(Num, Logs) when Num < ?MAX_DEPOT_LOG_NUM ->
    lists:reverse(Logs);
depot_log_delete(Num, [_ | Logs]) ->
    depot_log_delete(Num - 1, Logs).


gm_update_family_int(#r_role{role_id = RoleID} = State, Integral) ->
    FamilyData = family_misc:call_family({mod, ?MODULE, {gm_update_integral, RoleID, Integral}}),
    common_misc:unicast(RoleID, #m_family_info_toc{family_info = FamilyData, integral = Integral}),
    State.

do_update_integral(RoleID, Integral) ->
    RoleFamily = mod_family_data:get_role_family(RoleID),
    Family = mod_family_data:get_family(RoleFamily#r_role_family.family_id),
    {NewMembers, _NewInt, _OldInt} = mod_family_depot:change_member_integral(Family#p_family.members, RoleID, Integral, set),
    Family2 = Family#p_family{members = NewMembers},
    mod_family_data:set_family(Family2),
    Family2.

change_member_integral(Members, RoleID, Num, Type) ->
    case lists:keytake(RoleID, #p_family_member.role_id, Members) of
        {value, PFMember, T} ->
            OldInt = PFMember#p_family_member.integral,
            NewPFMember =
                case Type of
                    add ->
                        PFMember#p_family_member{integral = OldInt + Num};
                    reduce ->
                        PFMember#p_family_member{integral = OldInt - Num};
                    set ->
                        PFMember#p_family_member{integral = Num}
                end,
            {[NewPFMember | T], NewPFMember#p_family_member.integral,OldInt};
        _ ->
            {Members, 0, 0}
    end.
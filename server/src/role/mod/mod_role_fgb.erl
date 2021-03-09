%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 六月 2019 14:40
%%%-------------------------------------------------------------------
-module(mod_role_fgb).
-author("WZP").
-include("global.hrl").
-include("family_god_beast.hrl").
-include("proto/mod_role_fgb.hrl").
-include("act.hrl").
-include("family.hrl").
-include("family_boss.hrl").
-include("activity.hrl").
-include("proto/mod_role_family.hrl").

%% API        道庭神兽
-export([
    check_role_pre_enter/1,
    check_role_enter/1,
    do_get_info/2,
    send_reward/3,
    handle/2,
    add_buff/2
]).

add_buff(BuffID, #r_role{} = State) ->
    mod_role_buff:do_add_buff([#buff_args{buff_id = BuffID, from_actor_id = 0}], State);
add_buff(BuffID, RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {?MODULE, add_buff, [BuffID]});
        _ ->
            ok
    end.

check_role_pre_enter(#r_role{role_attr = Attr}) ->
    #r_role_attr{family_id = FamilyID} = Attr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_DEL_DEPOT_001)),
    {ok, RecordPos} = map_misc:get_born_pos(?MAP_FAMILY_BOSS),
    {1, ?DEFAULT_CAMP_ROLE, RecordPos}.



check_role_enter(#r_role{role_map = RoleMap, role_attr = RoleAttr, role_id = RoleID}) ->
    case ?IS_MAP_FAMILY_GOD_BEAST(RoleMap#r_role_map.map_id) of
        true ->
            {Type, List, TableName} = case world_data:get_fgb() of
                                          1 ->
                                              {1, ets:tab2list(?ETS_FAMILY_GOD_BEAST_RANK_A), ?ETS_FAMILY_GOD_BEAST_RANK_A};
                                          _ ->
                                              {2, ets:tab2list(?ETS_FAMILY_GOD_BEAST_RANK_B), ?ETS_FAMILY_GOD_BEAST_RANK_B}
                                      end,
            List2 = to_p_fgb_rank(List, []),
            {InspireNum2, InspireNumAll2} = case mod_family_god_beast:get_family_data_by_name(TableName, RoleAttr#r_role_attr.family_id) of
                                                [] ->
                                                    {0, 0};
                                                Data ->
                                                    InspireNum = case lists:keyfind(RoleID, #p_kv.id, Data#r_family_god_beast_rank.inspire_member) of
                                                                     #p_kv{val = Val} ->
                                                                         Val;
                                                                     _ ->
                                                                         0
                                                                 end,
                                                    InspireNumAll = mod_map_family_god_beast:get_all_inspire(Data#r_family_god_beast_rank.inspire_member),
                                                    {InspireNum, InspireNumAll}
                                            end,
            common_misc:unicast(RoleID, #m_role_fgb_rank_i_toc{inspire = InspireNum2, all_inspire = InspireNumAll2, type = Type, self = RoleAttr#r_role_attr.family_name, list = List2}),
            ok;
        _ ->
            ok
    end.



send_reward(DropID, FamilyGoodList, RoleID) when erlang:is_integer(RoleID) ->
    case role_misc:info_role(RoleID, {?MODULE, send_reward, [DropID, FamilyGoodList]}) of
        {error, not_exist} ->
            {error, not_exist};
        _ ->
            ok
    end;
send_reward(SelfDrop, FamilyGoodList, #r_role{role_id = RoleID, role_map = RoleMap} = State) ->
    GoodList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- lib_tool:string_to_intlist(SelfDrop)],
    ?IF(?IS_MAP_FAMILY_GOD_BEAST(RoleMap#r_role_map.map_id), common_misc:unicast(RoleID, #m_role_fgb_end_toc{role = GoodList, family = FamilyGoodList}), ok),
    role_misc:create_goods(State, ?ITEM_GAIN_FGB_SELF, GoodList);
send_reward(DropID, FamilyGoodList, RoleInfo) ->
    ?WARNING_MSG("--------------DropID, RoleInfo---------~", [{DropID, FamilyGoodList, RoleInfo}]).


handle({#m_role_fgb_tos{}, RoleID, _PID}, State) ->
    do_get_info(RoleID, State),
    State;
handle({#m_role_fgb_rank_tos{type = Type}, RoleID, _PID}, State) ->
    do_get_rank_info(RoleID, Type),
    State;
handle({#m_role_fgb_inspire_tos{}, RoleID, _PID}, State) ->
    do_fgb_inspire(RoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info : ~w", [Info]),
    State.



do_get_info(RoleID, #r_role{role_attr = RoleAttr}) ->
    case ?HAS_FAMILY(RoleAttr#r_role_attr.family_id) of
        true ->
            case world_activity_server:get_activity(?ACTIVITY_FAMILY_GOD_BEAST) of
                #r_activity{status = ?STATUS_OPEN} ->
                    case map_misc:get_map_pid(map_misc:get_map_pname(?MAP_FAMILY_BOSS, 1)) of
                        {ok, MapPID} ->
                            mod_map_family_god_beast:get_activity_info(RoleAttr#r_role_attr.family_id, RoleID, MapPID);
                        _ ->
                            world_activity_server:info({mod, mod_family_god_beast, {role_info, RoleAttr#r_role_attr.family_id, RoleID}})
                    end;
                _ ->
                    send_info(RoleID, RoleAttr)
            end;
        _ ->
            common_misc:unicast(RoleID, #m_role_fgb_toc{})
    end.


send_info(RoleID, RoleAttr) ->
    case ets:tab2list(?ETS_FAMILY_GOD_BEAST_RANK_A) of
        [] ->
            AHP = 100, BHP = 100;
        _ ->
            {AHP, BHP} = case ets:tab2list(?ETS_FAMILY_GOD_BEAST_RANK_B) of
                             [] ->
                                 {0, 100};
                             _ ->
                                 {0, 0}
                         end
    end,
    case ets:lookup(?ETS_FAMILY_GOD_BEAST_RANK_A, RoleAttr#r_role_attr.family_id) of
        #r_family_god_beast_rank{member_num = InsertNumA} ->
            InsertNumA;
        _ ->
            InsertNumA = 0
    end,
    case ets:lookup(?ETS_FAMILY_GOD_BEAST_RANK_B, RoleAttr#r_role_attr.family_id) of
        #r_family_god_beast_rank{member_num = InsertNumB} ->
            InsertNumB;
        _ ->
            InsertNumB = 0
    end,
    common_misc:unicast(RoleID, #m_role_fgb_toc{type = 0, a_num = InsertNumA, a_hp = AHP, b_num = InsertNumB, b_hp = BHP}).

do_get_rank_info(RoleID, Type) ->
    List = case Type =:= 1 of
               true ->
                   ets:tab2list(?ETS_FAMILY_GOD_BEAST_RANK_A);
               _ ->
                   ets:tab2list(?ETS_FAMILY_GOD_BEAST_RANK_B)
           end,
    List2 = to_p_fgb_rank(List, []),
    common_misc:unicast(RoleID, #m_role_fgb_rank_toc{type = Type, list = List2}).

to_p_fgb_rank([], List) ->
    List;
to_p_fgb_rank([RankInfo|T], List) ->
    PRankInfo = #p_fgb_rank{family_name = RankInfo#r_family_god_beast_rank.family_name, hurt_num = RankInfo#r_family_god_beast_rank.hurt,
                            rank = RankInfo#r_family_god_beast_rank.rank, num = RankInfo#r_family_god_beast_rank.member_num},
    to_p_fgb_rank(T, [PRankInfo|List]).


do_fgb_inspire(RoleID, State) ->
    case catch check_can_inspire(State, RoleID) of
        {ok, State2, AssetDoing, AllTimes2, OneTimes2, BagDoing} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            common_misc:unicast(RoleID, #m_role_fgb_inspire_toc{inspire = OneTimes2, all_inspire = AllTimes2}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_fgb_inspire_toc{err_code = ErrCode}),
            State;
        Res ->
            ?ERROR_MSG("-----Res_---------~w", [Res]),
            State
    end.



check_can_inspire(#r_role{role_attr = RoleAttr} = State, RoleID) ->
    [GlobalConfig] = lib_config:find(cfg_global, ?FAMILY_GOD_BEAST_GLOBAL),
    [X, _|Z] = string:tokens(GlobalConfig#c_global.string, lib_tool:to_list(",")),
    [_, Price|_] = string:tokens(X, lib_tool:to_list(":")),
    GoodList = [begin [TypeID, Num] = string:tokens(Reward, ":"), #p_goods{type_id = lib_tool:to_integer(TypeID), num = lib_tool:to_integer(Num)} end || Reward <- Z],
    BagDoing = [{create, ?ITEM_GAIN_FGB_INSPIRE, GoodList}],
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, lib_tool:to_integer(Price), ?ASSET_GOLD_REDUCE_FROM_FGB_INSPIRE, State),
    case mod_map_family_god_beast:role_inspire(RoleID, RoleAttr#r_role_attr.family_id) of
        {ok, AllTimes2, OneTimes2} ->
            {ok, State, AssetDoing, AllTimes2, OneTimes2, BagDoing};
        {error, ErrCode} ->
            {error, ErrCode}
    end.




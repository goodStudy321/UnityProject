%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     玩家地图面板相关模块
%%% @end
%%% Created : 30. 三月 2018 17:49
%%%-------------------------------------------------------------------
-module(mod_role_map_panel).
-author("laijichang").
-include("role.hrl").
-include("copy.hrl").
-include("team.hrl").
-include("proto/mod_role_map_panel.hrl").
-include("proto/copy_immortal.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    role_enter_map/1,
    add_exp/2,
    add_drop/2
]).

-export([
    copy_success/2
]).

init(#r_role{role_id = RoleID, role_map_panel = undefined} = State) ->
    State#r_role{role_map_panel = #r_role_map_panel{role_id = RoleID}};
init(State) ->
    State.

online(State) ->
    #r_role{role_map_panel = RoleMapPanel} = State,
    #r_role_map_panel{panel_list = PanelList} = RoleMapPanel,
    Now = time_tool:now(),
    PanelList2 = [ MapPanel|| #r_map_panel{enter_time = EnterTime} = MapPanel <- PanelList, Now - EnterTime =< ?AN_HOUR],
    RoleMapPanel2 = RoleMapPanel#r_role_map_panel{panel_list = PanelList2},
    State#r_role{role_map_panel = RoleMapPanel2}.

copy_success(RoleID, MapID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {copy_success, MapID}}).

handle({copy_success, MapID}, State) ->
    do_copy_success(State, MapID).

role_enter_map(State) ->
    State2 = add_exp(0, State),
    add_drop([], State2).

add_exp(AddExp, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_map_panel = RoleMapPanel} = State,
    MapID = RoleMap#r_role_map.map_id,
    IsCopy = not map_misc:is_copy_front(MapID) andalso map_misc:is_copy(MapID),
    IsFamilyTD = ?IS_MAP_FAMILY_TD(MapID),
    IsMarry = ?IS_MAP_MARRY_FEAST(MapID),
    if
        IsCopy orelse IsFamilyTD orelse IsMarry -> %% 经验变化要在面板上更新
            #r_role_map_panel{panel_list = PanelList} = RoleMapPanel,
            MapPID = mod_role_dict:get_map_pid(),
            case map_misc:is_copy_team(MapID) of
                true ->
                    [#c_copy{copy_type = CopyType, times = ConfigTimes}] = lib_config:find(cfg_copy, MapID),
                    #r_role_team{copy_list = CopyList} = mod_team_data:get_role_team(RoleID),
                    Times =
                    case lists:keyfind(CopyType, #p_kv.id, CopyList) of
                        #p_kvt{type = Times0} -> Times0;
                        _ -> 0
                    end,
                    case ConfigTimes + Times > 0 of
                        true ->
                            {Exp2, MapPanel2} = add_exp2(MapID, PanelList, AddExp, MapPID);
                        _ ->
                            {Exp2, MapPanel2} = add_exp2(MapID, PanelList, 0, MapPID)
                    end;
                _ ->
                    {Exp2, MapPanel2} = add_exp2(MapID, PanelList, AddExp, MapPID)
            end,
            PanelList2 = lists:keystore(MapID, #r_map_panel.map_id, PanelList, MapPanel2),
            RoleMapPanel2 = RoleMapPanel#r_role_map_panel{panel_list = PanelList2},
            IsCopyExp = copy_data:is_copy_exp_map(MapID),
            if
                IsCopyExp ->
                    common_misc:unicast(RoleID, #m_copy_exp_toc{exp = Exp2});
                IsFamilyTD ->
                    common_misc:unicast(RoleID, #m_family_td_exp_toc{exp = Exp2});
                IsMarry ->
                    common_misc:unicast(RoleID, #m_marry_map_exp_toc{exp = Exp2});
                true ->
                    ok
            end,
            State2 = State#r_role{role_map_panel = RoleMapPanel2},
            State3 = ?IF(map_misc:is_copy_exp(MapID), mod_role_mission:exp_trigger(Exp2, State2), State2),
            State3;
        true ->
            State
    end.

add_exp2(MapID, PanelList, AddExp, MapPID) ->
    case lists:keyfind(MapID, #r_map_panel.map_id, PanelList) of
        #r_map_panel{map_pid = MapPID, exp = Exp} = MapPanel ->
            Exp2 = Exp + AddExp,
            MapPanel2 = MapPanel#r_map_panel{exp = Exp2},
            {Exp2, MapPanel2};
        _ ->
            Exp2 = AddExp,
            MapPanel2 = #r_map_panel{map_id = MapID, map_pid = MapPID, exp = AddExp, enter_time = time_tool:now()},
            {Exp2, MapPanel2}
    end.

add_drop(GoodsList, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_map_panel = RoleMapPanel} = State,
    MapID = RoleMap#r_role_map.map_id,
    IsCopy = map_misc:is_copy(MapID),
    if
        IsCopy -> %% 道具是所有副本都要有
            #r_role_map_panel{panel_list = PanelList} = RoleMapPanel,
            MapPID = mod_role_dict:get_map_pid(),
            MapPanel2 =
                case lists:keyfind(MapID, #r_map_panel.map_id, PanelList) of
                    #r_map_panel{map_pid = MapPID, goods_list = OldGoodsList} = MapPanel ->
                        GoodsList2 = add_role_drop(GoodsList, OldGoodsList),
                        MapPanel#r_map_panel{goods_list = GoodsList2};
                    _ ->
                        #r_map_panel{map_id = MapID, map_pid = MapPID, goods_list = GoodsList}
                end,
            PanelList2 = lists:keystore(MapID, #r_map_panel.map_id, PanelList, MapPanel2),
            RoleMapPanel2 = RoleMapPanel#r_role_map_panel{panel_list = PanelList2},
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            if
                CopyType =:= ?COPY_IMMORTAL ->
                    common_misc:unicast(RoleID, #m_copy_immortal_drop_toc{drop_list = MapPanel2#r_map_panel.goods_list});
                true ->
                    ok
            end,
            State#r_role{role_map_panel = RoleMapPanel2};
        true ->
            State
    end.


add_role_drop([], GoodsList) ->
    GoodsList;
add_role_drop([#p_kv{id = TypeID, val = Num} = KV|R], GoodsList) ->
    case lists:keyfind(TypeID, #p_kv.id, GoodsList) of
        #p_kv{val = OldVal} = OldKV->
            GoodsList2 = lists:keyreplace(TypeID, #p_kv.id, GoodsList, OldKV#p_kv{val = OldVal + Num}),
            add_role_drop(R, GoodsList2);
        _ ->
            add_role_drop(R, [KV|GoodsList])
    end.


do_copy_success(State, MapID) ->
    #r_role{role_id = RoleID, role_map_panel = RoleMapPanel} = State,
    #r_role_map_panel{panel_list = PanelList} = RoleMapPanel,
    case lists:keyfind(MapID, #r_map_panel.map_id, PanelList) of
        #r_map_panel{exp = Exp, goods_list = GoodsList} ->
            DataRecord = #m_copy_success_toc{exp = Exp, goods_list = GoodsList},
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            common_misc:unicast(RoleID, #m_copy_success_toc{})
    end,
    State.
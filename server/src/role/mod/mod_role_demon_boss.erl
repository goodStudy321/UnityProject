%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 五月 2019 11:22
%%%-------------------------------------------------------------------
-module(mod_role_demon_boss).
-author("laijichang").
-include("activity.hrl").
-include("demon_boss.hrl").
-include("role.hrl").
-include("proto/mod_map_demon_boss.hrl").
-include("proto/mod_role_demon_boss.hrl").
-include("proto/mod_role_map.hrl").

%% API
-export([
    online/1,
    level_up/3,
    handle/2
]).

-export([
    is_able/3,
    check_enter_demon_boss/2
]).

online(State) ->
    case is_level_fit(mod_role_data:get_role_level(State)) of
        true ->
            #r_demon_boss_ctrl{level = NowLevel, next_level = NextLevel, rooms = RoomList} = world_data:get_demon_boss_ctrl(),
            #r_activity{status = Status} = world_activity_server:get_activity(?ACTIVITY_DEMON_BOSS),
            Level = ?IF(Status =:= ?STATUS_OPEN, NowLevel, NextLevel),
            common_misc:unicast(State#r_role.role_id, #m_demon_boss_info_toc{level = Level, rooms = RoomList});
        _ ->
            ok
    end,
    State.

level_up(OldLevel, NewLevel, State) ->
    case not is_level_fit(OldLevel) andalso is_level_fit(NewLevel) of
        true ->
            online(State);
        _ ->
            ok
    end,
    ok.

is_able(MapID, ExtraID, State) ->
    case catch mod_map_demon_boss:role_get_cheer(State#r_role.role_id, map_misc:get_map_pname(MapID, ExtraID)) of
        {ok, true, _CheerTimes, _AddBuffTimes} ->
            case catch check_enter_demon_boss(ExtraID, State) of
                ok ->
                    true;
                _ ->
                    false
            end;
        _ ->
            false
    end.

check_enter_demon_boss(ExtraID, State) ->
    ?IF(mod_role_activity:is_activity_open(?ACTIVITY_DEMON_BOSS, State), ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    case world_data:get_demon_boss_ctrl() of
        #r_demon_boss_ctrl{level = BossLevel, rooms = Rooms} ->
            ?IF(BossLevel - mod_role_data:get_role_level(State) =< common_misc:get_global_int(?GLOBAL_DEMON_BOSS_LEVEL), ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
            case lists:keyfind(ExtraID, #p_demon_boss_room.room_id, Rooms) of
                #p_demon_boss_room{is_alive = true} ->
                    ok;
                _ ->
                    ?THROW_ERR(?ERROR_PRE_ENTER_016)
            end;
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_011)
    end,
    ok.

handle({#m_demon_boss_cheer_tos{}, RoleID, _PID}, State) ->
    do_cheer(RoleID, State);
handle({#m_demon_boss_hp_reward_tos{reward_id = RewardID}, RoleID, _PID}, State) ->
    do_hp_reward(RoleID, RewardID, State);
handle({demon_boss_owner, ExtraID, DropIDList}, State) ->
    do_demon_boss_owner(ExtraID, DropIDList, State).

do_cheer(RoleID, State) ->
    case catch check_cheer(RoleID, State) of
        {ok, MapPID, AssetDoings} ->
            State2 = mod_role_asset:do(AssetDoings, State),
            mod_map_demon_boss:role_cheer(RoleID, MapPID),
            common_misc:unicast(RoleID, #m_demon_boss_cheer_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_demon_boss_cheer_toc{err_code = ErrCode}),
            State
    end.

check_cheer(RoleID, State) ->
    MapPID = mod_role_dict:get_map_pid(),
    {ok, _IsEnter, CheerTimes, AddBuffTimes} = mod_map_demon_boss:role_get_cheer(RoleID, MapPID),
    ?IF(CheerTimes > AddBuffTimes, ok, ?THROW_ERR(?ERROR_DEMON_BOSS_CHEER_001)),
    AddBuffTimes2 = AddBuffTimes + 1,
    NeedGold = get_cheer_gold(common_misc:get_global_string_list(?GLOBAL_DEMON_BOSS), AddBuffTimes2),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_DEMON_BOSS_CHEER, State),
    {ok, MapPID, AssetDoings}.

get_cheer_gold([], _AddBuffTimes) ->
    ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR);
get_cheer_gold([{MaxTime, NeedGold}|R], AddBuffTimes) ->
    case AddBuffTimes =< MaxTime of
        true ->
            NeedGold;
        _ ->
            get_cheer_gold(R, AddBuffTimes)
    end.

do_hp_reward(RoleID, RewardID, State) ->
    case catch mod_demon_boss:hp_reward(RoleID, RewardID) of
        {ok, KV2} ->
            [#c_demon_boss_hp_reward{rewards = RewardString}] = lib_config:find(cfg_demon_boss_hp_reward, RewardID),
            GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(RewardString)),
            common_misc:unicast(RoleID, #m_demon_boss_hp_reward_toc{hp_reward_status = KV2}),
            role_misc:create_goods(State, ?ITEM_GAIN_DEMON_BOSS_HP_REWARD, GoodsList);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_demon_boss_hp_reward_toc{err_code = ErrCode}),
            State
    end.

do_demon_boss_owner(ExtraID, DropIDList, State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{role_name = RoleName}} = State,
    {GoodsList, PanelGoods, State2} = mod_role_world_boss:get_drop_and_panel_goods(DropIDList, State),
    map_misc:info(mod_role_dict:get_map_pid(), {func, map_server, send_all_gateway, [#m_boss_end_panel_toc{role_name = RoleName, goods = PanelGoods}]}),
    mod_demon_boss:monster_dead(ExtraID, RoleID, RoleName, PanelGoods),
    State3 = role_misc:create_goods(State2, ?ITEM_GAIN_DEMON_BOSS, GoodsList),
    FunList = [
        fun(StateAcc) -> mod_role_day_target:demon_boss_owner(StateAcc) end
    ],
    role_server:execute_state_fun(FunList, State3).

is_level_fit(Level) ->
    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ?ACTIVITY_DEMON_BOSS),
    Level >= MinLevel.
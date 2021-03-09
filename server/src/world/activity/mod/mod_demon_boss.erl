%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 五月 2019 10:11
%%%-------------------------------------------------------------------
-module(mod_demon_boss).
-author("laijichang").
-include("activity.hrl").
-include("global.hrl").
-include("demon_boss.hrl").
-include("log_statistics.hrl").
-include("proto/mod_role_demon_boss.hrl").
-include("proto/mod_map_demon_boss.hrl").

%% API
%% API
-export([
    init/0,
    handle/1,
    activity_prepare/0,
    activity_start/0,
    activity_end/0
]).

-export([
    role_active_rewards/2,
    role_active_rewards/3,
    monster_dead/4,

    hp_reward/2
]).

%% 进程启动时的init
init() ->
    #r_demon_boss_ctrl{next_level = NextLevel, rooms = Rooms} = DemonBossCtrl = world_data:get_demon_boss_ctrl(),
    Rooms2 = lists:foldl(
        fun(ExtraID, Acc) ->
            case lists:keyfind(ExtraID, #p_demon_boss_room.room_id, Rooms) of
                #p_demon_boss_room{} = OldRoom ->
                    [OldRoom#p_demon_boss_room{is_alive = false}|Acc];
                _ ->
                    [#p_demon_boss_room{room_id = ExtraID, is_alive = false}|Acc]
            end
        end, [], get_extra_id_list()),
    DemonBossCtrl2 =
        case NextLevel =:= 0 of
            true ->
                [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ?ACTIVITY_DEMON_BOSS),
                DemonBossCtrl#r_demon_boss_ctrl{next_level = MinLevel, rooms = Rooms2};
            _ ->
                DemonBossCtrl#r_demon_boss_ctrl{rooms = Rooms2}
        end,
    world_data:set_demon_boss_ctrl(DemonBossCtrl2),
    lib_tool:init_ets(?ETS_DEMON_BOSS_REWARD, #r_role_demon_boss_reward.role_id),
    ok.

handle(Info) ->
    do_handle_info(Info).

activity_prepare() ->
    cancel_time_ref(),
    close_all_maps(),
    ets:delete_all_objects(?ETS_DEMON_BOSS_REWARD),
    ok.

activity_start() ->
    #r_demon_boss_ctrl{next_level = NextLevel} = DemonBossCtrl = world_data:get_demon_boss_ctrl(),
    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ?ACTIVITY_DEMON_BOSS),
    DemonBossCtrl2 = DemonBossCtrl#r_demon_boss_ctrl{level = NextLevel, next_level = erlang:max(MinLevel, world_data:get_world_level())},
    DemonBossCtrl3 =
        lists:foldl(
            fun(ExtraID, DemonBossCtrlAcc) ->
                #r_demon_boss_ctrl{level = Level, rooms = Rooms} = DemonBossCtrlAcc,
                start_map(ExtraID, Level),
                Rooms2 = lists:keystore(ExtraID, #p_demon_boss_room.room_id, Rooms, #p_demon_boss_room{room_id = ExtraID, is_alive = true}),
                DemonBossCtrlAcc#r_demon_boss_ctrl{rooms = Rooms2}
            end, DemonBossCtrl2, get_extra_id_list()),
    world_data:set_demon_boss_ctrl(DemonBossCtrl3),
    %% 通知各个角色进程调用online方法
    common_broadcast:bc_role_info_to_world({mod_role_demon_boss, online, []}),
    ok.

activity_end() ->
    TimeRef = world_activity_server:info_mod_by_time(?ONE_MINUTE * 1000, ?MODULE, close_all_maps),
    cancel_time_ref(),
    set_time_ref(TimeRef),
    send_activity_end(),
    #r_demon_boss_ctrl{rooms = Rooms} = DemonBossCtrl = world_data:get_demon_boss_ctrl(),
    Rooms2 = [ Room#p_demon_boss_room{is_alive = false} || #p_demon_boss_room{} = Room <- Rooms],
    world_data:set_demon_boss_ctrl(DemonBossCtrl#r_demon_boss_ctrl{rooms = Rooms2}),
    %% 通知各个角色进程调用online方法
    common_broadcast:bc_role_info_to_world({mod_role_demon_boss, online, []}),
    do_letter_hp_reward(),
    ok.

role_active_rewards(RoleList, ActiveIDs) ->
    role_active_rewards(RoleList, ActiveIDs, false).
role_active_rewards(RoleList, ActiveIDs, IsForce) ->
    world_activity_server:info_mod(?MODULE, {role_active_rewards, RoleList, ActiveIDs, IsForce}).

monster_dead(ExtraID, RoleID, RoleName, PanelGoods) ->
    world_activity_server:info_mod(?MODULE, {monster_dead, ExtraID, RoleID, RoleName, PanelGoods}).

hp_reward(RoleID, RewardID) ->
    world_activity_server:call_mod(?MODULE, {hp_reward, RoleID, RewardID}).

start_map(ExtraID, Level) ->
    {ok, _MapPID} = map_sup:start_map(?MAP_DEMON_BOSS, ExtraID, common_config:get_server_id(), Level),
    ok.

close_all_maps() ->
    [ pname_server:send(pname_server:pid(map_misc:get_map_pname(?MAP_DEMON_BOSS, ExtraID)), {map_shutdwon, shutdown}) || ExtraID <- get_extra_id_list()].

send_activity_end() ->
    [ mod_map_demon_boss:activity_end(ExtraID) || ExtraID <- get_extra_id_list()].

do_handle_info(i) ->
    do_i();
do_handle_info(close_all_maps) ->
    close_all_maps();
do_handle_info({role_active_rewards, RoleList, ActiveIDs, IsForce}) ->
    do_role_active_rewards(RoleList, ActiveIDs, IsForce);
do_handle_info({monster_dead, ExtraID, RoleID, RoleName, PanelGoods}) ->
    do_monster_dead(ExtraID, RoleID, RoleName, PanelGoods);
do_handle_info({hp_reward, RoleID, RewardID}) ->
    do_hp_reward(RoleID, RewardID);
do_handle_info(Info) ->
    ?ERROR_MSG("unkonw info : ~w", [Info]).

do_i() ->
    world_data:get_demon_boss_ctrl().

do_role_active_rewards(RoleList, ActiveIDs, IsForce) ->
    [ do_role_active_rewards2(RoleID, ActiveIDs, IsForce) || RoleID <- RoleList].

do_role_active_rewards2(RoleID, ActiveIDs, IsForce) ->
    #r_role_demon_boss_reward{is_enter = IsEnter, status_list = StatusList} = DemonBossReward = get_role_demon_boss_reward(RoleID),
    {IsChange1, StatusList2} = check_all_ids(StatusList),
    {ChangeList, StatusList3} = check_active_ids(ActiveIDs, StatusList2, []),
    set_role_demon_boss_reward(DemonBossReward#r_role_demon_boss_reward{is_enter = true, status_list = StatusList3}),
    case IsChange1 orelse IsForce of
        true ->
            common_misc:unicast(RoleID, #m_demon_boss_hp_reward_status_toc{hp_reward_status = StatusList3});
        _ ->
            ?IF(ChangeList =/= [], common_misc:unicast(RoleID, #m_demon_boss_hp_reward_status_toc{hp_reward_status = ChangeList}), ok)
    end,
    ?IF(IsEnter, ok, world_log_statistics_server:log_add_times(RoleID, ?LOG_STAT_DEMON_BOSS, 1, 1)).

check_all_ids([]) ->
    StatusList = [#p_kv{id = ID, val = ?HP_REWARD_NOT_GET} || {ID, _Config} <- lib_config:list(cfg_demon_boss_hp_reward)],
    {true, StatusList};
check_all_ids(StatusList) ->
    {false, StatusList}.

check_active_ids([], StatusList, ChangeAcc) ->
    {ChangeAcc, StatusList};
check_active_ids([ActiveID|R], StatusList, ChangeAcc) ->
    case lists:keytake(ActiveID, #p_kv.id, StatusList) of
        {value, #p_kv{val = Status} = KV, StatusListT} ->
            case Status of
                ?HP_REWARD_NOT_GET ->
                    KV2 = KV#p_kv{val = ?HP_REWARD_CAN_GET},
                    check_active_ids(R, [KV2|StatusListT], [KV2|ChangeAcc]);
                _ ->
                    check_active_ids(R, StatusList, ChangeAcc)
            end;
        _ ->
            KV = #p_kv{id = ActiveID, val = ?HP_REWARD_CAN_GET},
            check_active_ids(R, [KV|StatusList], [KV|ChangeAcc])
    end.

do_monster_dead(ExtraID, RoleID, RoleName, PanelGoods) ->
    #r_demon_boss_ctrl{rooms = Rooms} = DemonBossCtrl = world_data:get_demon_boss_ctrl(),
    Room = #p_demon_boss_room{
        room_id = ExtraID,
        is_alive = false,
        role_id = RoleID,
        role_name = RoleName,
        panel_goods = PanelGoods},
    Rooms2 = lists:keystore(ExtraID, #p_demon_boss_room.room_id, Rooms, Room),
    DemonBossCtrl2 = DemonBossCtrl#r_demon_boss_ctrl{rooms = Rooms2},
    world_data:set_demon_boss_ctrl(DemonBossCtrl2),
    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ?ACTIVITY_DEMON_BOSS),
    common_broadcast:bc_record_to_world_by_condition(#m_demon_boss_info_update_toc{room = Room}, #r_broadcast_condition{min_level = MinLevel}).

do_hp_reward(RoleID, RewardID) ->
    #r_role_demon_boss_reward{status_list = StatusList} = DemonBossReward = get_role_demon_boss_reward(RoleID),
    case lists:keytake(RewardID, #p_kv.id, StatusList) of
        {value, #p_kv{val = ?HP_REWARD_CAN_GET} = KV, StatusListT} ->
            KV2 = KV#p_kv{val = ?HP_REWARD_HAS_GOT},
            StatusList2 = [KV2|StatusListT],
            DemonBossReward2 = DemonBossReward#r_role_demon_boss_reward{status_list = StatusList2},
            set_role_demon_boss_reward(DemonBossReward2),
            {ok, KV2};
        _ ->
            {error, ?ERROR_DEMON_BOSS_HP_REWARD_001}
    end.

do_letter_hp_reward() ->
    [ begin
          GoodsList = lists:flatten(
              [ begin
                    [#c_demon_boss_hp_reward{rewards = Rewards}] = lib_config:find(cfg_demon_boss_hp_reward, ID),
                    common_misc:get_reward_p_goods(common_misc:get_item_reward(Rewards))
                end|| #p_kv{id = ID, val = ?HP_REWARD_CAN_GET} <- StatusList]),
          case GoodsList =/= [] of
              true ->
                  LetterInfo = #r_letter_info{
                      template_id = ?LETTER_DEMON_BOSS_HP_REWARD,
                      action = ?ITEM_GAIN_DEMON_BOSS_HP_REWARD,
                      goods_list = GoodsList
                  },
                  common_letter:send_letter(RoleID, LetterInfo);
              _ ->
                  ok
          end
      end || #r_role_demon_boss_reward{role_id = RoleID, status_list = StatusList} <- ets:tab2list(?ETS_DEMON_BOSS_REWARD)].
%%%===================================================================
%%% dict || data
%%%===================================================================
get_extra_id_list() ->
    lists:seq(1, ?DEMON_BOSS_ROOM_NUM).

cancel_time_ref() ->
    case erlang:erase({?MODULE, time_ref}) of
        TimeRef when erlang:is_reference(TimeRef) ->
            erlang:cancel_timer(TimeRef);
        _ ->
            ok
    end.
set_time_ref(TimeRef) ->
    erlang:put({?MODULE, time_ref}, TimeRef).

get_role_demon_boss_reward(RoleID) ->
    case ets:lookup(?ETS_DEMON_BOSS_REWARD, RoleID) of
        [#r_role_demon_boss_reward{} = DemonBossReward] ->
            DemonBossReward;
        _ ->
            #r_role_demon_boss_reward{role_id = RoleID}
    end.
set_role_demon_boss_reward(DemonBossReward) ->
    ets:insert(?ETS_DEMON_BOSS_REWARD, DemonBossReward).
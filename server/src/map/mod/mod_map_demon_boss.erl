%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 五月 2019 10:04
%%%-------------------------------------------------------------------
-module(mod_map_demon_boss).
-author("laijichang").
-include("demon_boss.hrl").
-include("global.hrl").
-include("monster.hrl").
-include("role.hrl").
-include("proto/mod_map_demon_boss.hrl").

%% API
-export([
    i/1,
    init/0,
    loop/1,
    handle/1,
    role_enter_map/1,
    role_dead/3,
    role_relive_normal/1,
    role_leave_map/2,
    monster_enter_map/1,
    monster_reduce_hp/3,
    monster_dead/3
]).

-export([
    activity_end/1
]).

-export([
    role_get_cheer/2,
    role_cheer/2
]).

-export([
    sort_panel_goods/1
]).

i(ExtraID) ->
    map_misc:call_mod(map_misc:get_map_pname(?MAP_DEMON_BOSS, ExtraID), ?MODULE, i).

init() ->
    Level = mod_map_dict:get_map_params(),
    #c_demon_boss{type_id = TypeID, pos = [Mx, Mz, MDir]} = get_level_config(Level),
    BornPos = map_misc:get_pos_by_offset_pos(Mx, Mz, MDir),
    MonsterData = monster_misc:get_dynamic_monster(Level, TypeID),
    MonsterData2 = MonsterData#r_monster{born_pos = BornPos},
    mod_map_monster:born_monsters([MonsterData2]),
    set_map_demon_boss(#r_map_demon_boss{}),
    set_hp_reward_rate(?RATE_100),
    ok.

loop(Now) ->
    #r_map_demon_boss{
        all_occupy_time = AllOccupyTime,
        occupy_role = OccupyRole,
        time_list = TimeList,
        clear_time = ClearTime
    } = MapDemonBoss = get_map_demon_boss(),
    case OccupyRole of
        #p_demon_boss_role{role_id = RoleID, occupy_time = OccupyTime, cur_occupy_time = CurOccupyTime} = OccupyRole ->
            CurOccupyTime2 = CurOccupyTime + 1,
            OccupyRole2 = OccupyRole#p_demon_boss_role{occupy_time = OccupyTime + 1, cur_occupy_time = CurOccupyTime2, time = Now},
            try_reduce_boss_hp(RoleID, AllOccupyTime),
            try_role_add_buff(RoleID, CurOccupyTime, CurOccupyTime2),
            map_server:send_all_gateway(#m_demon_boss_occupy_toc{occupy_role = OccupyRole2}),
            TimeList2 = lists:keystore(RoleID, #p_demon_boss_role.role_id, TimeList, OccupyRole2),
            {TimeList3, RankList2} = sort_time_list(TimeList2),
            MapDemonBoss2 = MapDemonBoss#r_map_demon_boss{
                all_occupy_time = AllOccupyTime + 1,
                occupy_role = OccupyRole2,
                rank_list = RankList2,
                time_list = TimeList3},
            MapDemonBoss3 = ?IF(Now >= ClearTime, change_occupy_role(undefined, MapDemonBoss2), MapDemonBoss2),
            set_map_demon_boss(MapDemonBoss3);
        _ ->
            ok
    end.

activity_end(ExtraID) ->
    map_misc:info_mod(pname_server:pid(map_misc:get_map_pname(?MAP_DEMON_BOSS, ExtraID)), ?MODULE, activity_end).

role_get_cheer(RoleID, MapPID) ->
    map_misc:call_mod(MapPID, ?MODULE, {role_get_cheer, RoleID}).

role_cheer(RoleID, MapPID) ->
    map_misc:info_mod(MapPID, ?MODULE, {role_cheer, RoleID}).

handle(i) ->
    do_i();
handle(activity_end) ->
    do_activity_end();
handle({role_get_cheer, RoleID}) ->
    do_role_get_cheer(RoleID);
handle({role_cheer, RoleID}) ->
    do_role_cheer(RoleID);
handle({#m_demon_boss_enter_safe_tos{}, RoleID, _PID}) ->
    do_enter_safe(RoleID);
handle(Info) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]).


%% 进入地图，推送数据
role_enter_map(RoleID) ->
    #r_map_demon_boss{
        occupy_role = OccupyRole,
        rank_list = RankList} = get_map_demon_boss(),
    #r_role_demon_boss{
        cheer_times = CheerTimes,
        add_buff_times = AddBuffTimes
    } = RoleDemonBoss = get_role_demon_boss(RoleID),
    DataRecord = #m_demon_boss_enter_toc{
        occupy_role = OccupyRole,
        rank_roles = RankList,
        cheer_times = CheerTimes,
        add_buff_times = AddBuffTimes
    },
    common_misc:unicast(RoleID, DataRecord),
    BuffID = common_misc:get_global_int(?GLOBAL_DEMON_BOSS),
    CommonBuffID = common_misc:get_global_int(?GLOBAL_DEMON_BOSS_BUFF),
    CommonBuffList = [#buff_args{buff_id = CommonBuffID, from_actor_id = RoleID}],
    BuffList =
        case AddBuffTimes > 0 of
            true ->
                CommonBuffList ++ [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || _Add <- lists:seq(1, AddBuffTimes)];
            _ ->
                CommonBuffList
        end,
    role_misc:add_buff(RoleID, BuffList),
    set_role_demon_boss(RoleID, RoleDemonBoss#r_role_demon_boss{is_enter = true}),
    role_enter_map_hp_reward(RoleID),
    ok.

%% 角色死亡会短暂移除占领状态
role_dead(RoleID, _SrcID, _SrcType) ->
%%    #r_map_demon_boss{occupy_role = OccupyRole} = MapDemonBoss = get_map_demon_boss(),
%%    case OccupyRole of
%%        #p_demon_boss_role{role_id = RoleID} -> %% 死亡的是占领者
%%            MapDemonBoss3 =
%%                case SrcType of
%%                    ?ACTOR_TYPE_ROLE ->
%%                        #r_map_actor{actor_name = SrcRoleName, role_extra = SrcMapRole} = mod_map_ets:get_actor_mapinfo(SrcID),
%%                        #p_map_role{sex = SrcSex, category = SrcCategory} = SrcMapRole,
%%                        DemonRole = #p_demon_boss_role{
%%                            role_id = SrcID,
%%                            role_name = SrcRoleName,
%%                            sex = SrcSex,
%%                            category = SrcCategory,
%%                            time = time_tool:now()},
%%                        change_occupy_role(DemonRole, MapDemonBoss);
%%                    _ ->
%%                        change_occupy_role(undefined, MapDemonBoss)
%%                end,
%%            set_map_demon_boss(MapDemonBoss3);
%%        _ ->
%%            ok
%%    end,
    #r_role_demon_boss{cheer_times = CheerTimes, add_buff_times = AddBuffTimes} = RoleDemonBoss = get_role_demon_boss(RoleID),
    [_RankNum, CheerMaxNum] = common_misc:get_global_list(?GLOBAL_DEMON_BOSS),
    CheerTimes2 = erlang:min(CheerTimes + 1, CheerMaxNum),
    case CheerTimes =/= CheerTimes2 of
        true ->
            set_role_demon_boss(RoleID, RoleDemonBoss#r_role_demon_boss{cheer_times = CheerTimes2}),
            common_misc:unicast(RoleID, #m_demon_boss_cheer_times_toc{cheer_times = CheerTimes2, add_buff_times = AddBuffTimes});
        _ ->
            ok
    end.

%% 出生点复活，清空时间
role_relive_normal(RoleID) ->
    #r_map_demon_boss{occupy_role = OccupyRole} = MapDemonBoss = get_map_demon_boss(),
    case OccupyRole of
        #p_demon_boss_role{role_id = RoleID} -> %% 死亡的是占领者
            MapDemonBoss2 = change_occupy_role(undefined, MapDemonBoss),
            set_map_demon_boss(MapDemonBoss2),
            del_role_rank(RoleID, MapDemonBoss2);
        _ ->
            del_role_rank(RoleID, MapDemonBoss)
    end.

role_leave_map(RoleID, IsOnline) ->
    #r_map_demon_boss{occupy_role = OccupyRole} = MapDemonBoss = get_map_demon_boss(),
    MapDemonBoss2 =
    case OccupyRole of
        #p_demon_boss_role{role_id = RoleID} -> %% 离开的是占领者
            change_occupy_role(undefined, MapDemonBoss);
        _ ->
            MapDemonBoss
    end,
    ?IF(IsOnline, role_leave_map2(RoleID, MapDemonBoss2), set_map_demon_boss(MapDemonBoss2)).

%% 玩家强制离开
role_leave_map2(RoleID, MapDemonBoss) ->
    del_role_demon_boss(RoleID),
    del_role_rank(RoleID, MapDemonBoss).

del_role_rank(RoleID, MapDemonBoss) ->
    #r_map_demon_boss{
        rank_list = RankList,
        time_list = TimeList
    } = MapDemonBoss,
    TimeList2 = lists:keydelete(RoleID, #p_demon_boss_role.role_id, TimeList),
    MapDemonBoss2 =
    case lists:keymember(RoleID, #p_demon_boss_role.role_id, RankList) of
        true -> %% 排行上的走了，要更新
            {TimeList3, RankList2} = sort_time_list(TimeList2),
            map_server:send_all_gateway(#m_demon_boss_rank_toc{rank_roles = RankList2}),
            MapDemonBoss#r_map_demon_boss{
                rank_list = RankList2,
                time_list = TimeList3
            };
        _ ->
            MapDemonBoss#r_map_demon_boss{time_list = TimeList2}
    end,
    set_map_demon_boss(MapDemonBoss2).

monster_enter_map(MapInfo) ->
    #r_map_actor{actor_id = MonsterID} = MapInfo,
    set_monster_id(MonsterID),
    [ role_enter_map(RoleID) || RoleID <- mod_map_ets:get_in_map_roles()].

%% 怪物掉血
monster_reduce_hp(MapInfo, ReduceSrc, _ReduceHp) ->
    #r_reduce_src{actor_id = RoleID, actor_type = ActorType} = ReduceSrc,
    case ActorType of
        ?ACTOR_TYPE_ROLE ->
            #r_map_actor{actor_name = RoleName, role_extra = MapRole} = mod_map_ets:get_actor_mapinfo(RoleID),
            #p_map_role{sex = Sex, category = Category} = MapRole,
            #r_map_demon_boss{occupy_role = OccupyRole} = MapDemonBoss = get_map_demon_boss(),
            DemonRole = #p_demon_boss_role{
                role_id = RoleID,
                role_name = RoleName,
                sex = Sex,
                category = Category,
                time = time_tool:now()},
            MapDemonBoss2 =
            case OccupyRole of
                undefined ->
                    change_occupy_role(DemonRole, MapDemonBoss);
                #p_demon_boss_role{role_id = RoleID} -> %% 造成伤害的是占领者，更新时间
                    MapDemonBoss#r_map_demon_boss{clear_time = time_tool:now() + ?CLEAR_HURT_TIME};
                _ ->
                    MapDemonBoss
            end,
            set_map_demon_boss(MapDemonBoss2);
        _ ->
            ok
    end,
    #r_map_actor{hp = Hp, max_hp = MaxHp} = MapInfo,
    monster_reduce_hp_reward(lib_tool:ceil(?RATE_100 * Hp/MaxHp)).

%% 怪物死亡，可能会直接
monster_dead(MapInfo, SrcID, _SrcType) ->
    #r_map_actor{actor_id = MonsterID, monster_extra = #p_map_monster{type_id = TypeID}} = MapInfo,
    case MonsterID =/= SrcID of
        true ->
            #r_map_demon_boss{rank_list = RankList} = get_map_demon_boss(),
            [#p_demon_boss_role{role_id = RoleID}|_] = RankList,
            ?WARNING_MSG("排行列表 RankList : ~w, 获取奖励RoleID: ~w", [RankList, RoleID]),
            #c_demon_boss{drop_list = DropIDList} = get_level_config(mod_map_dict:get_map_params()),
            role_misc:info_role(RoleID, mod_role_demon_boss, {demon_boss_owner, map_common_dict:get_map_extra_id(), DropIDList}),
            family_server:add_box_by_role(?GLOBAL_FAMILY_BOX_MOYU_BOSS, TypeID, RoleID),
            set_map_demon_boss(#r_map_demon_boss{}),
            map_server:delay_kick_roles(),
            monster_reduce_hp_reward(0),
            ok;
        _ ->
            ok
    end.

sort_panel_goods(Goods) ->
    lists:sort(
        fun(#p_kv{id = ItemID1}, #p_kv{id = ItemID2}) ->
            #c_item{quality = Quality1} = mod_role_item:get_item_config(ItemID1),
            #c_item{quality = Quality2} = mod_role_item:get_item_config(ItemID2),
            Quality1 > Quality2
        end, Goods).

do_i() ->
    RoleList = mod_map_ets:get_in_map_roles(),
    {get_map_demon_boss(), [get_role_demon_boss(RoleID) || RoleID <- RoleList]}.

%% 活动结束
do_activity_end() ->
    set_map_demon_boss(#r_map_demon_boss{}),
    mod_map_monster:delete_monsters(),
    map_server:kick_all_roles().

%% 获取当前玩家鼓舞次数
do_role_get_cheer(RoleID) ->
    #r_role_demon_boss{is_enter = IsEnter, cheer_times = CheerTimes, add_buff_times = AddBuffTimes} = get_role_demon_boss(RoleID),
    {ok, IsEnter, CheerTimes, AddBuffTimes}.

do_role_cheer(RoleID) ->
    #r_role_demon_boss{cheer_times = CheerTimes, add_buff_times = AddBuffTimes} = RoleDemonBoss = get_role_demon_boss(RoleID),
    AddBuffTimes2 = AddBuffTimes + 1,
    set_role_demon_boss(RoleID, RoleDemonBoss#r_role_demon_boss{add_buff_times = AddBuffTimes2}),
    common_misc:unicast(RoleID, #m_demon_boss_cheer_times_toc{cheer_times = CheerTimes, add_buff_times = AddBuffTimes2}),
    BuffID = common_misc:get_global_int(?GLOBAL_DEMON_BOSS),
    role_misc:add_buff(RoleID, #buff_args{buff_id = BuffID}).

%% 进入安全区，清除归属
do_enter_safe(RoleID) ->
    #r_map_demon_boss{occupy_role = OccupyRole} = MapDemonBoss = get_map_demon_boss(),
    case OccupyRole of
        #p_demon_boss_role{role_id = RoleID} ->
            MapDemonBoss2 = change_occupy_role(undefined, MapDemonBoss),
            set_map_demon_boss(MapDemonBoss2);
        _ ->
            ok
    end.

%% 改变拥有者
change_occupy_role(undefined, MapDemonBoss) ->
    ?TRY_CATCH(clear_occupy_buff(MapDemonBoss)),
    map_server:send_all_gateway(#m_demon_boss_occupy_toc{occupy_role = undefined}),
    mod_map_monster:do_update_world_boss_owner(get_monster_id(), undefined),
    MapDemonBoss#r_map_demon_boss{occupy_role = undefined, clear_time = 0};
change_occupy_role(DestRole, MapDemonBoss) ->
    ?TRY_CATCH(clear_occupy_buff(MapDemonBoss)),
    #p_demon_boss_role{
        role_id = DestRoleID,
        role_name = DestRoleName,
        level = DestLevel} = DestRole,
    #r_map_demon_boss{time_list = TimeList} = MapDemonBoss,
    OccupyRole2 =
    case lists:keyfind(DestRoleID, #p_demon_boss_role.role_id, TimeList) of
        #p_demon_boss_role{} = TimeRole -> %% 之前已经有数据了，延用之前数据
            TimeRole;
        _ ->
            DestRole#p_demon_boss_role{time = 0}
    end,
    map_server:send_all_gateway(#m_demon_boss_occupy_toc{occupy_role = OccupyRole2}),
    NewOwner =
    case mod_map_ets:get_actor_mapinfo(DestRoleID) of
        #r_map_actor{role_extra = #p_map_role{family_id = FamilyID, team_id = TeamID}} ->
            #p_world_boss_owner{
                owner_id = DestRoleID,
                owner_name = DestRoleName,
                owner_level = DestLevel,
                family_id = FamilyID,
                team_id = TeamID};
        _ ->
            #p_world_boss_owner{
                owner_id = DestRoleID,
                owner_name = DestRoleName,
                owner_level = DestLevel}
    end,
    mod_map_monster:do_update_world_boss_owner(get_monster_id(), NewOwner),
    MapDemonBoss#r_map_demon_boss{occupy_role = OccupyRole2, clear_time = time_tool:now() + ?CLEAR_HURT_TIME}.


sort_time_list(TimeList) ->
    TimeList2 = lists:sort(
        fun(#p_demon_boss_role{occupy_time = OT1, time = T1}, #p_demon_boss_role{occupy_time = OT2, time = T2}) ->
            ?IF(OT1 =:= OT2, T1 < T2, OT1 > OT2)
        end, TimeList),
    [RankNum|_] = common_misc:get_global_list(?GLOBAL_DEMON_BOSS),
    RankList = lists:sublist(TimeList2, RankNum),
    {TimeList2, RankList}.

%% boss掉血
try_reduce_boss_hp(RoleID, Time) ->
    MonsterID = get_monster_id(),
    case mod_map_ets:get_actor_mapinfo(MonsterID) of
        #r_map_actor{hp = Hp, max_hp = MaxHp} ->
            HpRate = Hp / MaxHp,
            AllTime = common_misc:get_global_int(?GLOBAL_DEMON_BOSS_LOOP),
            ConfigRate = 1 - Time / AllTime,
            case HpRate > ConfigRate of
                true ->
                    mod_map_actor:reduce_hp(RoleID, MonsterID, lib_tool:ceil((1 / AllTime) * MaxHp));
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

%% 尝试给玩家加buff
try_role_add_buff(RoleID, CurOccupyTime, CurOccupyTime2) ->
    List2 = lists:reverse(common_misc:get_global_string_list(?GLOBAL_DEMON_BOSS_LOOP)),
    OldBuffID = get_occupy_buff_id2(CurOccupyTime, List2),
    NewBuffID = get_occupy_buff_id2(CurOccupyTime2, List2),
    case OldBuffID =/= NewBuffID of
        true ->
            role_misc:add_buff(RoleID, #buff_args{buff_id = NewBuffID, from_actor_id = RoleID});
        _ ->
            ok
    end.

%% 清理占领者buff
clear_occupy_buff(MapDemonBoss) ->
    #r_map_demon_boss{occupy_role = OccupyRole} = MapDemonBoss,
    case OccupyRole of
        #p_demon_boss_role{role_id = RoleID, cur_occupy_time = CurOccupyTime} ->
            BuffID = get_occupy_buff_id(CurOccupyTime),
            ?IF(BuffID > 0, role_misc:remove_buff(RoleID, BuffID), ok);
        _ ->
            ok
    end.

%% 通过单次占领时间，获取对应的BuffID
get_occupy_buff_id(CurOccupyTime) ->
    List = lists:reverse(common_misc:get_global_string_list(?GLOBAL_DEMON_BOSS_LOOP)),
    get_occupy_buff_id2(CurOccupyTime, List).

get_occupy_buff_id2(_CurOccupyTime, []) ->
    0;
get_occupy_buff_id2(CurOccupyTime, [{Time, BuffID}|R]) ->
    case CurOccupyTime >= Time of
        true ->
            BuffID;
        _ ->
            get_occupy_buff_id2(CurOccupyTime, R)
    end.

monster_reduce_hp_reward(HpRate) ->
    OldRate = get_hp_reward_rate(),
    ConfigList = lib_config:list(cfg_demon_boss_hp_reward),
    {ActiveIDs, RewardHpRate} = monster_reduce_hp_reward2(ConfigList, OldRate, HpRate, [], 0),
    case ActiveIDs =/= [] of
        true ->
            RoleIDList = mod_map_ets:get_in_map_roles(),
            set_hp_reward_rate(RewardHpRate),
            mod_demon_boss:role_active_rewards(RoleIDList, ActiveIDs);
        _ ->
            ok
    end.

monster_reduce_hp_reward2([], _OldRate, _HpRate, ActiveIDAcc, RewardHpRate) ->
    {ActiveIDAcc, RewardHpRate};
monster_reduce_hp_reward2([{ID, Config}|R], OldRate, HpRate, ActiveIDAcc, RewardHpRate) ->
    #c_demon_boss_hp_reward{hp_rate = NeedHpRate} = Config,
    case OldRate > NeedHpRate andalso NeedHpRate >= HpRate of
        true ->
            monster_reduce_hp_reward2(R, OldRate, HpRate, [ID|ActiveIDAcc], NeedHpRate);
        _ ->
            monster_reduce_hp_reward2(R, OldRate, HpRate, ActiveIDAcc, RewardHpRate)
    end.

role_enter_map_hp_reward(RoleID) ->
    MonsterID = get_monster_id(),
    case mod_map_ets:get_actor_mapinfo(MonsterID) of
        #r_map_actor{hp = Hp, max_hp = MaxHp} ->
            HpRate = lib_tool:ceil(?RATE_100 * Hp/MaxHp),
            ConfigList = lib_config:list(cfg_demon_boss_hp_reward),
            ActiveIDs = role_enter_map_hp_reward2(ConfigList, HpRate, []),
            mod_demon_boss:role_active_rewards([RoleID], ActiveIDs, true);
        _ ->
            ok
    end.

role_enter_map_hp_reward2([], _HpRate, Acc) ->
    Acc;
role_enter_map_hp_reward2([{ID, Config}|R], HpRate, ActiveIDAcc) ->
    #c_demon_boss_hp_reward{hp_rate = NeedHpRate} = Config,
    case NeedHpRate >= HpRate of
        true ->
            role_enter_map_hp_reward2(R, HpRate, [ID|ActiveIDAcc]);
        _ ->
            ActiveIDAcc
    end.



%%%===================================================================
%%% dict || data
%%%===================================================================
get_level_config(Level) ->
    ConfigList = lib_config:list(cfg_demon_boss),
    get_level_config2(ConfigList, Level).

get_level_config2([{{MinLevel, MaxLevel}, Config}|R], Level) ->
    case MinLevel =< Level andalso Level =< MaxLevel of
        true ->
            Config;
        _ ->
            get_level_config2(R, Level)
    end.


get_role_demon_boss(RoleID) ->
    case erlang:get({?MODULE, role_demon_boss, RoleID}) of
        #r_role_demon_boss{} = RoleDemonBoss ->
            RoleDemonBoss;
        _ ->
            #r_role_demon_boss{}
    end.
set_role_demon_boss(RoleID, RoleDemonBoss) ->
    erlang:put({?MODULE, role_demon_boss, RoleID}, RoleDemonBoss).
del_role_demon_boss(RoleID) ->
    erlang:erase({?MODULE, role_demon_boss, RoleID}).

get_map_demon_boss() ->
    erlang:get({?MODULE, map_demon_boss}).
set_map_demon_boss(MapDemonBoss) ->
    erlang:put({?MODULE, map_demon_boss}, MapDemonBoss).

get_monster_id() ->
    erlang:get({?MODULE, monster_id}).
set_monster_id(MonsterID) ->
    erlang:put({?MODULE, monster_id}, MonsterID).

get_hp_reward_rate() ->
    erlang:get({?MODULE, hp_reward_rate}).
set_hp_reward_rate(Rate) ->
    erlang:put({?MODULE, hp_reward_rate}, Rate).


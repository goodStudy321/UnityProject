%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     地图战场模块
%%% @end
%%% Created : 07. 三月 2018 15:43
%%%-------------------------------------------------------------------
-module(mod_map_battle).
-author("laijichang").
-include("battle.hrl").
-include("global.hrl").
-include("monster.hrl").
-include("proto/mod_map_actor.hrl").

%% API
-export([
    init/0,
    handle/1,
    battle_monster_dead/3,
    role_reduce_hp/2,
    role_be_killed/2,
    del_buffs/2
]).

-export([
    is_battle_monster/1,
    is_battle_monster/2,
    get_battle_monster_reduce/2
]).

init() ->
    MonsterDatas = [
        #r_monster{
            type_id = ?BATTLE_MONSTER,
            camp_id = CampID,
            born_pos = map_misc:get_pos_by_offset_pos(Mx, My, MDir)
        } || {CampID, Mx, My, MDir} <- ?MONSTER_POS_LIST],
    mod_map_monster:born_monsters(MonsterDatas).

handle(kick_roles) ->
    do_kick_roles().

battle_monster_dead(MonsterID, SrcID, _SrcType) ->
    #r_map_actor{pos = IntPos, camp_id = MonsterCampID, monster_extra = MapMonster} = MapInfo = mod_map_ets:get_actor_mapinfo(MonsterID),
    case MonsterCampID =:= ?BATTLE_CAMP_NORMAL of %% 这里可能会触发多次，对阵营进行判断
        true ->
            ok;
        _ ->
            BuffID = ?BATTLE_BUFF_UNBEATABLE,
            [#c_buff{last_time = LastTime}] = lib_config:find(cfg_buff, BuffID),
            #r_map_actor{camp_id = CampID} = mod_map_ets:get_actor_mapinfo(SrcID),
            MonsterCampID2 = ?BATTLE_CAMP_NORMAL,
            Time = time_tool:now() + LastTime,
            MapMonster2 = MapMonster#p_map_monster{battle_owner = CampID, countdown = Time},
            mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{camp_id = MonsterCampID2, monster_extra = MapMonster2}),
            ChangeList = [
                #p_dkv{id = ?MAP_ATTR_CAMP_ID, val = MonsterCampID2},
                #p_dkv{id = ?MONSTER_BATTLE_OWNER, val = CampID},
                #p_dkv{id = ?MONSTER_COUNTDOWN, val = Time}
            ],
            DataRecord = #m_map_actor_attr_change_toc{actor_id = MonsterID, kv_list = ChangeList},
            map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord),
            mod_map_monster:add_buff(MonsterID, #buff_args{buff_id = BuffID, from_actor_id = MonsterID}),
            mod_battle:monster_dead(map_common_dict:get_map_extra_id(), MonsterCampID, CampID),
            mod_map_actor:add_hp(MonsterID, 9999999999),
            case CampID of
                ?BATTLE_CAMP_IMMORTAL ->
                    map_server:send_all_gateway(#m_common_notice_toc{id = ?NOTICE_MONSTER_CONQUERED, text_string = [?MOD_BATTLE_IMMORTAL]});
                ?BATTLE_CAMP_DEMON->
                    map_server:send_all_gateway(#m_common_notice_toc{id = ?NOTICE_MONSTER_CONQUERED, text_string = [?MOD_BATTLE_DEMON] });
                ?BATTLE_CAMP_BUDDHA ->
                    map_server:send_all_gateway(#m_common_notice_toc{id = ?NOTICE_MONSTER_CONQUERED, text_string = [?MOD_BATTLE_BUDDHA]});
                _ ->
                    ?ERROR_MSG("Wrong CampId!")
            end
    end.

%% 掉血，蹭助攻
role_reduce_hp(RoleID, ReduceSrc) ->
    #r_reduce_src{actor_id = SrcID, actor_type = SrcType} = ReduceSrc,
    case SrcType of
        ?ACTOR_TYPE_ROLE ->
            ReduceRoles = get_assist_roles(RoleID),
            case lists:member(SrcID, ReduceRoles) of
                true ->
                    ok;
                _ ->
                    set_assist_roles(RoleID, [SrcID|ReduceRoles])
            end;
        _ ->
            ok
    end.

role_be_killed(RoleID, SrcID) ->
    AssistRoles = get_assist_roles(RoleID),
    mod_battle:role_be_killed(RoleID, SrcID, lists:delete(SrcID, AssistRoles)).

del_buffs(MonsterID, DelIDList) ->
    case lists:member(?BATTLE_BUFF_UNBEATABLE, DelIDList) of
        true ->
            #r_map_actor{pos = IntPos, monster_extra = #p_map_monster{battle_owner = BattleOwner} = MapMonster} = MapInfo = mod_map_ets:get_actor_mapinfo(MonsterID),
            MapMonster2 = MapMonster#p_map_monster{countdown = 0},
            mod_map_ets:set_actor_mapinfo(MapInfo#r_map_actor{camp_id = BattleOwner, monster_extra = MapMonster2}),
            ChangeList = [
                #p_dkv{id = ?MAP_ATTR_CAMP_ID, val = BattleOwner},
                #p_dkv{id = ?MONSTER_COUNTDOWN, val = 0}
            ],
            DataRecord = #m_map_actor_attr_change_toc{actor_id = MonsterID, kv_list = ChangeList},
            map_server:broadcast_by_pos(map_misc:pos_decode(IntPos), DataRecord);
        _ ->
            ok
    end.

is_battle_monster(#r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}}) ->
    TypeID =:= ?BATTLE_MONSTER;
is_battle_monster(_) ->
    false.

is_battle_monster(?ACTOR_TYPE_MONSTER, #r_map_actor{monster_extra = #p_map_monster{type_id = TypeID}}) ->
    TypeID =:= ?BATTLE_MONSTER;
is_battle_monster(_ActorType, _MapInfo) ->
    false.

get_battle_monster_reduce(TypeID, Value) ->
    case TypeID of
        ?BATTLE_MONSTER ->
            ?BATTLE_MONSTER_REDUCE_HP;
        _ ->
            Value
    end.

do_kick_roles() ->
    erlang:send_after((?ONE_MINUTE div 2) * 1000, erlang:self(), {func, fun() -> map_server:kick_all_roles() end}).

get_assist_roles(RoleID) ->
    case erlang:get({?MODULE, reduce_roles, RoleID}) of
        [_|_] = RoleList ->
            RoleList;
        _ ->
            []
    end.
set_assist_roles(RoleID, RoleList) ->
    erlang:put({?MODULE, reduce_roles, RoleID}, RoleList).
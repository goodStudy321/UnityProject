%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 五月 2018 20:17
%%%-------------------------------------------------------------------
-module(world_robot_server).
-author("laijichang").
-include("world_robot.hrl").
-include("proto/mod_role_skill.hrl").

%% API
-export([
    i/0,
    start/0,
    start_link/0
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    info/1,
    call/1,
    role_pre_enter/1,
    role_online/1,
    role_offline/2,
    init_level_list/0,
    call_get_level_pos/1
]).

-export([
    get_robot_by_role_id/1
]).

-export([
    get_all_robot/0
]).

i() ->
    call(i).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

call_get_level_pos(Level) ->
    call({get_level_pos, Level}).

role_pre_enter(RoleID) ->
    call({role_pre_enter, RoleID}).

role_online(RoleID) ->
    call({role_online, RoleID}).

role_offline(RoleID, OfflineTime) ->
    info({role_offline, RoleID, OfflineTime}).

init_level_list() ->
    pname_server:send(?MODULE, init_level_list).

info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    set_robot_num(0),
    set_level_list([]),
    do_modify_robots(),
    do_init_level_list(),
    do_loop_ref(),
    {ok, []}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle(i) ->
    do_i();
do_handle({role_pre_enter, RoleID}) ->
    do_pre_enter(RoleID);
do_handle({role_online, RoleID}) ->
    do_role_online(RoleID);
do_handle({get_level_pos, Level}) ->
    do_get_level_pos(Level);
do_handle({role_offline, RoleID, OfflineTime}) ->
    do_role_offline(RoleID, OfflineTime);
do_handle(init_level_list) ->
    do_init_level_list();
do_handle(loop) ->
    do_loop_ref(),
    do_loop();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_i() ->
    {get_robot_num()}.

do_pre_enter(RoleID) ->
    RoleRobot = get_role_robot(RoleID),
    do_kick_robot(RoleRobot).

do_role_online(RoleID) ->
    #r_role_robot{start_fight_time = StartFightTime, monster_type_id = TypeID, has_time = HasTime} = get_role_robot(RoleID),
    del_role_robot(RoleID),
    FightTime = ?IF(StartFightTime > 0, erlang:min(HasTime, time_tool:now() - StartFightTime), 0),
    {ok, FightTime, TypeID}.

do_role_offline(RoleID, OfflineTime) ->
    RoleRobot2 =
        case get_role_robot(RoleID) of
            #r_role_robot{last_offline_time = LastOfflineTime} = RoleRobot when LastOfflineTime > 0 -> %% 之前有数据
                RoleRobot#r_role_robot{fight_status = ?FIGHT_STATUS_STAND_BY, has_time = OfflineTime};
            _ ->
                #r_role_robot{role_id = RoleID, fight_status = ?FIGHT_STATUS_STAND_BY, last_offline_time = time_tool:now(), has_time = OfflineTime}
        end,
    set_role_robot(RoleRobot2).

do_modify_robots() ->
    List = [ RoleRobot#r_role_robot{fight_status = ?FIGHT_STATUS_STAND_BY} ||
        #r_role_robot{fight_status = FightStatus}  = RoleRobot <- get_all_robot(), FightStatus =:= ?FIGHT_STATUS_FIGHTING],
    set_role_robot(List).

do_init_level_list() ->
    MapList = cfg_map_base:list(),
    set_level_list([]),
    [ begin
          #c_map_base{map_type = MapType, seqs = Seqs} = Config,
          ?IF(MapType =:= ?MAP_TYPE_NORMAL, do_init_level_list2(MapID, Seqs), ok)
      end|| {MapID, Config}<- MapList].

do_init_level_list2(_MapID, []) ->
    ok;
do_init_level_list2(MapID, [SeqID|R]) ->
    case lib_config:find(cfg_map_seq, SeqID) of
        [Seq] ->
            #c_map_seq{
                monster_type_id = TypeID,
                min_point = MinPoint,
                max_point = MaxPoint,
                min_level = MinLevel,
                max_level = MaxLevel} = Seq,
            case TypeID > 0 of
                true ->
                    LevelList = get_level_list(),
                    RobotPos = #r_robot_pos{map_id = MapID, monster_type_id = TypeID, min_point = MinPoint, max_point = MaxPoint},
                    case lists:keyfind({MinLevel, MaxLevel}, #r_robot_level.key, LevelList) of
                        #r_robot_level{pos_list = PosList} = RobotLevel ->
                            RobotLevel2 = RobotLevel#r_robot_level{pos_list = [RobotPos|PosList]};
                        _ ->
                            RobotLevel2 = #r_robot_level{key = {MinLevel, MaxLevel}, pos_list = [RobotPos]}
                    end,
                    LevelList2 = lists:keystore({MinLevel, MaxLevel}, #r_robot_level.key, LevelList, RobotLevel2),
                    set_level_list(LevelList2);
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    do_init_level_list2(MapID, R).

do_loop_ref() ->
    erlang:send_after(?ROBOT_LOOP_INTERVAL * 1000, erlang:self(), loop).

do_loop() ->
    RobotNum = get_robot_num(),
    Now = time_tool:now(),
    AllRobot = get_all_robot(),
    RobotNum2 = do_loop2(AllRobot, Now, RobotNum),
    set_robot_num(RobotNum2).

do_loop2([], _Now, RobotNum) ->
    RobotNum;
do_loop2([RoleRobot|R], Now, RobotNum) ->
    #r_role_robot{
        role_id = RoleID,
        last_offline_time = LastOfflineTime,
        start_fight_time = StartFightTime,
        has_time = HasTime,
        fight_status = FightStatus} = RoleRobot,
    if
        FightStatus =:= ?FIGHT_STATUS_STAND_BY -> %% 准备状态
            if
                StartFightTime > 0 andalso Now - StartFightTime < HasTime -> %% 之前挂机过，并且还有剩余时间
                    IsCreateRobot = true,
                    IsUpdate = true,
                    RoleRobot2 = RoleRobot#r_role_robot{fight_status = ?FIGHT_STATUS_FIGHTING};
                Now >= LastOfflineTime + 3 * ?ONE_MINUTE -> %% 3分钟后开始离线挂机
                    IsCreateRobot = true,
                    IsUpdate = true,
                    RoleRobot2 = RoleRobot#r_role_robot{fight_status = ?FIGHT_STATUS_FIGHTING, start_fight_time = Now};
                true ->
                    IsCreateRobot = false,
                    IsUpdate = false,
                    RoleRobot2 = RoleRobot
            end,
            #r_role_attr{level = Level} = common_role_data:get_role_attr(RoleID),
            #r_robot_pos{map_id = MapID, monster_type_id = TypeID, min_point = MinPoint, max_point = MaxPoint} = get_level_pos(Level),
            ExtraID = map_branch_manager:get_map_cur_extra_id(MapID),
            RoleRobot3 = RoleRobot2#r_role_robot{map_id = MapID, monster_type_id = TypeID, extra_id = ExtraID, min_point = MinPoint, max_point = MaxPoint},
            case IsCreateRobot andalso RobotNum < ?MAX_ROBOT_NUM of
                true ->
                    %% 下面这里会设置数据
                    do_start_robot(RoleRobot3),
                    do_loop2(R, Now, RobotNum + 1);
                _ ->
                    ?IF(IsUpdate, set_role_robot(RoleRobot3), ok),
                    do_loop2(R, Now, RobotNum)
            end;
        FightStatus =:= ?FIGHT_STATUS_FIGHTING ->
            case Now - StartFightTime > HasTime of
                true ->
                    do_kick_robot(RoleRobot),
                    do_loop2(R, Now, RobotNum - 1);
                _ ->
                    do_loop2(R, Now, RobotNum)
            end;
        true ->
            do_loop2(R, Now, RobotNum)
    end.

do_start_robot(RoleRobot) ->
    #r_role_robot{map_id = MapID, extra_id = ExtraID, min_point = MinPoint, max_point = MaxPoint, role_id = RoleID} = RoleRobot,
    Robot = get_robot_by_role_id(RoleID),
    RobotID = update_robot_id(MapID),
    set_role_robot(RoleRobot#r_role_robot{robot_id = RobotID}),
    Robot2 = Robot#r_robot{
        robot_id = RobotID,
        min_point = MinPoint,
        max_point = MaxPoint
    },
    ?WARNING_MSG("create robot:~w", [{RoleID, RobotID}]),
    ?TRY_CATCH(map_misc:info(map_misc:get_map_pname(MapID, ExtraID), {func, fun() -> mod_map_robot:born_robots([Robot2]) end})).

do_kick_robot(RoleRobot) ->
    #r_role_robot{robot_id = RobotID, map_id = MapID, extra_id = ExtraID, min_point = MinPoint, max_point = MaxPoint} = RoleRobot,
    ?IF(MapID =:= undefined orelse MapID =:= 0,
        ok,
        ?TRY_CATCH(map_misc:info(map_misc:get_map_pname(MapID, ExtraID), {func, fun() -> mod_map_robot:delete_robot(RobotID) end}))),
    set_role_robot(RoleRobot#r_role_robot{fight_status = ?FIGHT_STATUS_END}),
    {ok, MapID, ExtraID, MinPoint, MaxPoint}.

%% 根据等级获取对应坐标
get_level_pos(Level) ->
    LevelList = get_level_list(),
    get_level_pos2(Level, LevelList).

get_level_pos2(_Level, []) ->
    [#c_map_seq{min_point = MinPoint, max_point = MaxPoint, monster_type_id = TypeID}] = lib_config:find(cfg_map_seq, 10101),
    #r_robot_pos{map_id = map_misc:get_home_map_id(), monster_type_id = TypeID, min_point = MinPoint, max_point = MaxPoint};
get_level_pos2(Level, [RobotLevel|R]) ->
    #r_robot_level{key = {MinLevel, MaxLevel}, pos_list = PosList} = RobotLevel,
    case MinLevel =< Level andalso Level =< MaxLevel of
        true ->
            lib_tool:random_element_from_list(PosList);
        _ ->
            get_level_pos2(Level, R)
    end.

get_robot_by_role_id(RoleID) ->
    #r_role_attr{
        role_name = RoleName,
        level = Level,
        sex = Sex,
        power = Power,
        category = Category,
        family_id = FamilyID,
        family_name = FamilyName,
        skin_list = SkinList,
        ornament_list = OrnamentList
    } = common_role_data:get_role_attr(RoleID),
    FamilyTitle = mod_role_family:get_family_title_id(RoleID),
    #r_role_fight{fight_attr = FightAttr} = common_role_data:get_role_fight(RoleID),
    #r_role_skill{attack_list = AttackList} = common_role_data:get_role_skill(RoleID),
    #r_robot{
        robot_name = RoleName,
        sex = Sex,
        category = Category,
        level = Level,
        family_id = FamilyID,
        family_name = FamilyName,
        family_title_id = FamilyTitle,
        power = Power,
        skin_list = modify_skin_list(SkinList, []),
        skill_list = modify_skill_list(AttackList, []),
        ornament_list = OrnamentList,
        base_attr = FightAttr
    }.

modify_skin_list([], Acc) ->
    Acc;
modify_skin_list([SkinID|R], Acc) ->
    case catch is_skin_filter(SkinID) of
        true ->
            modify_skin_list(R, Acc);
        _ ->
            modify_skin_list(R, [SkinID|Acc])
    end.

modify_skill_list([], Acc) ->
    Acc;
modify_skill_list([Skill|R], Acc) ->
    #p_skill{skill_id = SkillID} = Skill,
    #c_skill{skill_type = SkillType} = common_skill:get_skill_config(SkillID),
    case SkillType =:= ?SKILL_ATTACK orelse SkillType =:= ?SKILL_NORMAL andalso
        ?GET_SKILL_FUN(SkillID) =/= ?SKILL_FUN_PET andalso ?GET_SKILL_FUN(SkillID) =/= ?SKILL_FUN_MAGIC of
        true ->
            Acc2 = [#r_robot_skill{skill_id = SkillID, skill_type = SkillType, time = 0}|Acc];
        _ ->
            Acc2 = Acc
    end,
    modify_skill_list(R, Acc2).


is_skin_filter(SkinID) ->
    case lib_config:find(cfg_pet, SkinID) of
        [_Config] ->
            erlang:throw(true);
        _ ->
            ok
    end,
    case lib_config:find(cfg_throne_level, SkinID) of
        [_ThroneConfig] ->
            erlang:throw(true);
        _ ->
            ok
    end,
    case lib_config:find(cfg_magic_weapon_skin, SkinID) of
        [_Config2] ->
            erlang:throw(true);
        _ ->
            fasle
    end,
    case lib_config:find(cfg_mount_up, SkinID) of
        [_Config3] ->
            erlang:throw(true);
        _ ->
            fasle
    end,
    case lib_config:find(cfg_mount_skin, SkinID) of
        [_Config4] ->
            erlang:throw(true);
        _ ->
            fasle
    end.
%%%===================================================================
%%% 数据操作
%%%===================================================================
get_all_robot() ->
    ets:tab2list(?DB_ROLE_ROBOT_P).
get_role_robot(RoleID) ->
    case ets:lookup(?DB_ROLE_ROBOT_P, RoleID) of
        [#r_role_robot{} = RoleRobot] ->
            RoleRobot;
        _ ->
            #r_role_robot{role_id = RoleID}
    end.
set_role_robot(RoleRobot) ->
    db:insert(?DB_ROLE_ROBOT_P, RoleRobot).
del_role_robot(RoleID) ->
    db:delete(?DB_ROLE_ROBOT_P, RoleID).

get_robot_num() ->
    erlang:get({?MODULE, robot_num}).
set_robot_num(Num) ->
    erlang:put({?MODULE, robot_num}, Num).

update_robot_id(MapID) ->
    RobotID =
    case erlang:get({?MODULE, map_id, MapID}) of
        ID when erlang:is_integer(ID) ->
            ID;
        _ ->
            common_id:get_robot_start_id(MapID)
    end,
    NextID = common_id:get_robot_next_id(RobotID),
    erlang:put({?MODULE, map_id, MapID}, NextID),
    RobotID.



get_level_list() ->
    erlang:get({?MODULE, level_list}).
set_level_list(LevelList) ->
    erlang:put({?MODULE, level_list}, LevelList).



do_get_level_pos(Level)->
    get_level_pos(Level).
-module(map_misc).
-include("global.hrl").
-include("copy.hrl").

-export([
    is_copy/1,
    is_normal_copy/1,
    is_copy_front/1,
    is_copy_tower/1,
    is_copy_confine/1,
    is_copy_offline_solo/1,
    is_copy_exp/1,
    is_copy_equip/1,
    is_copy_treasure/1,
    is_copy_guide_boss/1,
    is_copy_team/1,
    is_same_map_data/2,
    is_cross_map/1,
    is_world_boss_map/1,
    is_world_boss_tired_map/1,
    is_world_boss_family_map/1,
    is_world_boss_time_map/1,
    is_personal_boss_map/1,
    is_mythical_map/1,
    is_condition_map/1,
    is_normal_relive_map/1,
    is_map_node_match/1,
    is_map_node_match/2,
    modify_pos/2,
    call/2,
    call_mod/3,
    info/2,
    info_mod/3
]).

-export([
    get_map_pid/1,
    get_map_pname/2,
    get_map_pname/3
]).

-export([
    get_home_map_id/0,
    get_born_pos/1,
    get_map_seq_born_pos/3,
    get_seq_born_pos/2,
    get_dis/2,
    get_dis/4,
    get_direction/2,
    check_same_tile/2
]).

-export([
    get_enter_bc_filter/1,
    get_enter_bc_roles/2
]).

-export([
    get_random_pos_by_offset_meter/2,
    get_random_pos_by_meter/2
]).

-export([
    is_safe_tile/1,
    get_map_base/1,
    get_map_name/1,
    get_pos_by_offset_pos/2,
    get_pos_by_offset_pos/3,
    get_pos_by_map_offset_pos/3,
    get_pos_by_map_offset_pos/4,
    get_offset_meter/2,
    get_offset_meter_by_map_id/3,
    get_pos_by_tile/2,
    get_pos_by_tile/3,
    get_pos_by_meter/2,
    get_pos_by_meter/3,
    pos_decode/1,
    pos_encode/1,
    dir_m2t/1,
    dir_t2m/1
]).

-export([
    make_p_map_actor/1
]).

%%%===================================================================
%%% API
%%%===================================================================
is_copy(MapID) ->
    case map_base_data:get_map_type(MapID) of
        ?MAP_TYPE_COPY ->
            true;
        _ ->
            false
    end.

%% 正常副本
is_normal_copy(MapID) ->
    case lib_config:find(cfg_copy, MapID) of
        [#c_copy{copy_type = CopyType}] ->
            not lists:member(CopyType, [?COPY_FRONT, ?SPECIAL_COPY_FRONT]);
        _ ->
            false
    end.

is_copy_front(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            ?IS_COPY_FRONT(CopyType);
        _ ->
            false
    end.

is_copy_tower(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            ?IS_COPY_TOWER(CopyType);
        _ ->
            false
    end.

is_copy_offline_solo(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            ?IS_COPY_OFFLINE_SOLO(CopyType);
        _ ->
            false
    end.


is_copy_confine(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            ?IS_COPY_CONFINE(CopyType);
        _ ->
            false
    end.

is_copy_exp(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            ?IS_COPY_EXP(CopyType);
        _ ->
            false
    end.

is_copy_equip(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            ?IS_COPY_EQUIP(CopyType);
        _ ->
            false
    end.

is_copy_treasure(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            ?IS_COPY_TREASURE(CopyType);
        _ ->
            false
    end.

is_copy_guide_boss(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
            ?IS_COPY_GUIDE_BOSS(CopyType);
        _ ->
            false
    end.

is_copy_team(MapID) ->
    case is_copy(MapID) of
        true ->
            [#c_copy{is_team_map = IsTeamMap}] = lib_config:find(cfg_copy, MapID),
            ?IS_TEAM_MAP(IsTeamMap);
        _ ->
            false
    end.

is_same_map_data(OldMapID, NewMapID) ->
    [#c_map_base{data_id = DataID1}] = lib_config:find(cfg_map_base, OldMapID),
    [#c_map_base{data_id = DataID2}] = lib_config:find(cfg_map_base, NewMapID),
    DataID1 =:= DataID2.

is_cross_map(MapID) ->
    [#c_map_base{is_cross_map = IsCrossMap}] = lib_config:find(cfg_map_base, MapID),
    ?IS_CROSS_MAP(IsCrossMap).

is_world_boss_map(MapArgs) ->
    #c_map_base{sub_type = SubType} = get_map_base(MapArgs),
    ?IS_WORLD_BOSS_SUB_TYPE(SubType).

is_world_boss_tired_map(MapArgs) ->
    #c_map_base{sub_type = SubType} = get_map_base(MapArgs),
    SubType =:= ?SUB_TYPE_WORLD_BOSS_1.

is_world_boss_family_map(MapArgs) ->
    #c_map_base{sub_type = SubType} = get_map_base(MapArgs),
    SubType =:= ?SUB_TYPE_WORLD_BOSS_2.

is_world_boss_time_map(MapArgs) ->
    #c_map_base{sub_type = SubType} = get_map_base(MapArgs),
    SubType =:= ?SUB_TYPE_WORLD_BOSS_4.

is_personal_boss_map(MapArgs) ->
    #c_map_base{sub_type = SubType} = get_map_base(MapArgs),
    SubType =:= ?SUB_TYPE_WORLD_BOSS_3.

is_mythical_map(MapArgs) ->
    #c_map_base{sub_type = SubType} = get_map_base(MapArgs),
    SubType =:= ?SUB_TYPE_MYTHICAL_BOSS.

%% 部分有特殊限制的地图
is_condition_map(MapArgs) ->
    #c_map_base{is_special_open = IsSpecialOpen, sub_type = SubType} = get_map_base(MapArgs),
    lists:member(SubType, ?WILD_CONDITION_SUB_TYPE) orelse ?IS_SPECIAL_OPEN(IsSpecialOpen).

%% 是不是可以回出生点复活的地图
is_normal_relive_map(MapID) ->
    case is_copy(MapID) andalso not is_copy_front(MapID) of
        true ->
            case catch lib_config:find(cfg_copy_relive, {copy_misc:get_copy_type(MapID), 1}) of
                [#c_copy_relive{is_normal_relive = IsNormalRelive}] ->
                    ?IS_NORMAL_RELIVE(IsNormalRelive);
                _ ->
                    true
            end;
        _ ->
            [#c_map_base{is_normal_relive = IsNormalRelive}] = lib_config:find(cfg_map_base, MapID),
            ?IS_NORMAL_RELIVE(IsNormalRelive)
    end.

is_map_node_match(MapID) ->
    is_map_node_match(MapID, common_config:is_cross_node()).
is_map_node_match(MapID, IsCrossNode) ->
    not (IsCrossNode xor map_misc:is_cross_map(MapID)).

modify_pos(MapID, Pos) ->
    #r_pos{tx = Tx, ty = Ty} = Pos,
    case map_base_data:is_exist(MapID, Tx, Ty) of
        true ->
            Pos;
        _ ->
            {ok, Pos2} = get_born_pos(MapID),
            Pos2
    end.

%% @doc call地图,执行func
%% Request:fun() | {func,fun()} | {func,M,F,A} | {mod,Module,Request}
call(MapArg, Request) ->
    case get_map_pid(MapArg) of
        {ok, MapPID} ->
            Request2 =
            case erlang:is_function(Request) of
                true -> {func, Request};
                _ -> Request
            end,
            pname_server:call(MapPID, Request2);
        _ ->
            {error, map_process_not_found}
    end.

call_mod(MapArg, Mod, Request) ->
    call(MapArg, {mod, Mod, Request}).

info(MapArg, Request) ->
    case get_map_pid(MapArg) of
        {ok, MapPID} ->
            Request2 =
            case erlang:is_function(Request) of
                true -> {func, Request};
                _ -> Request
            end,
            pname_server:send(MapPID, Request2);
        _ ->
            {error, map_process_not_found}
    end.

info_mod(MapArg, Mod, Request) ->
    info(MapArg, {mod, Mod, Request}).


get_map_pid(MapPID) when erlang:is_pid(MapPID) ->
    {ok, MapPID};
get_map_pid(MapPName) when erlang:is_atom(MapPName) ->
    case pname_server:pid(MapPName) of
        undefined ->
            {error, map_process_not_found};
        MapPID ->
            {ok, MapPID}
    end.

get_map_pname(MapID, ExtraID) ->
    %% 游戏服节点获取跨服地图ServerID时的处理
    ServerID = ?IF(common_config:is_game_node() andalso map_misc:is_cross_map(MapID), global_data:get_cross_server_id(), common_config:get_server_id()),
    get_map_pname(MapID, ExtraID, ServerID).
get_map_pname(MapID, ExtraID, ServerID) ->
    lib_tool:list_to_atom(lists:concat(["map_", MapID, "_", ExtraID, "_", ServerID])).


%% @doc 获取回城点
get_home_map_id() ->
    [MapID] = lib_config:find(cfg_map_etc, home_map_id),
    MapID.

%% 获取出生点信息
%% {ok, RecordPos}
get_born_pos(MapID) when erlang:is_integer(MapID) ->
    get_born_pos(#r_born_args{map_id = MapID});
get_born_pos(#r_born_args{} = BornArgs) ->
    #r_born_args{
        map_id = MapID,
        camp_id = CampIDT,
        sex = SexT
    } = BornArgs,
    case map_base_data:get_born_points(MapID) of
        [PointList] ->
            #c_map_base{sub_type = SubType} = get_map_base(MapID),
            {CampID, Index} =
                if
                    ?IS_MAP_BATTLE(MapID) orelse ?IS_MAP_SUMMIT_TOWER(MapID) ->
                        {CampIDT, 1};
                    ?IS_MAP_FAMILY_BT(MapID) ->
                        {CampIDT, 1};
                    ?IS_MAP_COPY_MARRY(MapID) ->
                        {undefined, ?IF(SexT =:= ?SEX_BOY, 1, 2)};
                    SubType =:= ?SUB_TYPE_WORLD_BOSS_1 ->
                        {undefined, lib_tool:random(1, erlang:length(PointList))};
                    true ->
                        {CampIDT, 1}
                end,
            case lists:keyfind(CampID, #c_born_point.camp_id, PointList) of
                #c_born_point{mx = Mx, my = My, mdir = MDir} ->
                    ok;
                _ ->
                    #c_born_point{mx = Mx, my = My, mdir = MDir} = lists:nth(Index, PointList)
            end,
            {ok, get_pos_by_meter(Mx, My, MDir)};
        _ ->
            ?ERROR_MSG("no born point, map:~w", [MapID]),
            error
    end.


get_map_seq_born_pos(MapID, [MinMx, MinMy], [MaxMx, MaxMy]) ->
    {MinMx2, MaxMx2} = modify_born_pos(MinMx, MaxMx),
    {MinMy2, MaxMy2} = modify_born_pos(MinMy, MaxMy),
    get_map_seq_born_pos2(MapID, MinMx2, MinMy2, MaxMx2, MaxMy2, 40).

get_map_seq_born_pos2(MapID, _MinMx, _MinMy, MaxMx, MaxMy, 0) ->
    map_misc:get_pos_by_map_offset_pos(MapID, MaxMx, MaxMy);
get_map_seq_born_pos2(MapID, MinMx, MinMy, MaxMx, MaxMy, TryTimes) ->
    Mx = lib_tool:random(MinMx, MaxMx),
    My = lib_tool:random(MinMy, MaxMy),
    MDir = lib_tool:random(1, ?MAX_MDIR),
    #r_pos{tx = Tx2, ty = Ty2} = Pos = map_misc:get_pos_by_map_offset_pos(MapID, Mx, My, MDir),
    case map_base_data:is_exist(MapID, Tx2, Ty2) of
        true ->
            Pos;
        _ ->
            get_map_seq_born_pos2(MapID, MinMx, MinMy, MaxMx, MaxMy, TryTimes - 1)
    end.

%% map 与 collection 调用，坐标都是前端的真实坐标，这边需要偏移一下
get_seq_born_pos([MinMx, MinMy], [MaxMx, MaxMy]) ->
    {MinMx2, MaxMx2} = modify_born_pos(MinMx, MaxMx),
    {MinMy2, MaxMy2} = modify_born_pos(MinMy, MaxMy),
    get_seq_born_pos2(MinMx2, MinMy2, MaxMx2, MaxMy2, 40).

get_seq_born_pos2(_MinMx, _MinMy, MaxMx, MaxMy, 0) ->
    map_misc:get_pos_by_offset_pos(MaxMx, MaxMy);
get_seq_born_pos2(MinMx, MinMy, MaxMx, MaxMy, TryTimes) ->
    Mx = lib_tool:random(MinMx, MaxMx),
    My = lib_tool:random(MinMy, MaxMy),
    MDir = lib_tool:random(1, ?MAX_MDIR),
    #r_pos{tx = Tx2, ty = Ty2} = Pos = map_misc:get_pos_by_offset_pos(Mx, My, MDir),
    case map_base_data:is_exist(Tx2, Ty2) of
        true ->
            Pos;
        _ ->
            get_seq_born_pos2(MinMx, MinMy, MaxMx, MaxMy, TryTimes - 1)
    end.

modify_born_pos(Min, Max) ->
    case Min =< Max of
        true ->
            {Min, Max};
        _ ->
            ?ERROR_MSG("数据点配置反了 : ~w", [{Min, Max}]),
            {Max, Min}
    end.

get_dis(#r_pos{mx = Mx1, my = My1}, #r_pos{mx = Mx2, my = My2}) ->
    get_dis(Mx1, My1, Mx2, My2).
get_dis(X1, Y1, X2, Y2) ->
    math:sqrt((X1 - X2) * (X1 - X2) + (Y1 - Y2) * (Y1 - Y2)).

get_direction(#r_pos{mx = Mx1, my = My1}, #r_pos{mx = Mx2, my = My2}) ->
    RMx = Mx1 - Mx2,
    RMy = My1 - My2,
    if %% RMX=RMZ=0 时,角度任意
        RMx =:= 0 -> MDir = ?IF(RMy > 0, 180, 0); %% 竖直方向
        RMy =:= 0 -> MDir = ?IF(RMx > 0, 270, 90); %% 竖直方向
        true ->
            if
                RMy > 0 andalso RMx > 0 ->
                    MDir = 180 + math:atan(RMx / RMy) * 180 / math:pi();
                RMy > 0 andalso RMx < 0 ->
                    MDir = 180 + (math:atan(RMx / RMy) * 180 / math:pi());
                RMy < 0 andalso RMx < 0 ->
                    MDir = 360 + math:atan(RMx / RMy) * 180 / math:pi();
                RMy < 0 andalso RMx > 0 ->
                    MDir = 360 + math:atan(RMx / RMy) * 180 / math:pi()
            end
    end,
    lib_tool:to_integer(MDir).

get_pos_by_tile(Tx, Ty) ->
    get_pos_by_tile(Tx, Ty, ?DEFAULT_DIR).
get_pos_by_tile(Tx, Ty, Dir) ->
    {Mx, My, MDir} = pos_t2m(Tx, Ty, Dir),
    #r_pos{mx = Mx, my = My, mdir = MDir, tx = Tx, ty = Ty, dir = Dir}.

% 检查是否同一个格子
check_same_tile(#r_pos{tx = Tx, ty = Ty}, #r_pos{tx = Tx, ty = Ty}) ->
    true;
check_same_tile(Pos1, Pos2) when is_integer(Pos1) andalso is_integer(Pos2) ->
    (Pos1 band 16#ffff) div ?TILE_SIZE =:= (Pos2 band 16#ffff) div ?TILE_SIZE
    andalso
    ((Pos1 bsr 20) band 16#ffff) div ?TILE_SIZE =:= ((Pos2 bsr 20) band 16#ffff) div ?TILE_SIZE;
check_same_tile(_, _) ->
    false.

%% 部分场景单元进入地图后需要过滤广播
get_enter_bc_filter([]) ->
    [];
get_enter_bc_filter(BcRoles) ->
    {enter_filter, BcRoles}.

%% 场景单元进入地图后需要广播的Roles
get_enter_bc_roles(Slices, ExtraArgs) ->
    Roles = mod_map_slice:get_roleids_by_slices(Slices),
    case ExtraArgs of
        {enter_filter, BcRoles} ->
            Roles -- (Roles -- BcRoles);
        _ ->
            Roles
    end.

get_random_pos_by_offset_meter(Mx, My) ->
    [{OffsetX, OffsetY}] = map_base_data:offset(),
    get_random_pos_by_meter(Mx - OffsetX, My - OffsetY).

%% 获取Mx, My 300 * 300 范围的点
get_random_pos_by_meter(Mx, My) ->
    get_random_pos_by_meter2(Mx, My, 20).

get_random_pos_by_meter2(Mx, My, 0) ->
    get_pos_by_meter(Mx, My);
get_random_pos_by_meter2(Mx, My, Times) ->
    AddMx = lib_tool:random(-400, 400),
    AddMy = lib_tool:random(-400, 400),
    Mx2 = Mx + AddMx,
    My2 = My + AddMy,
    case map_base_data:is_exist(?M2T(Mx + AddMx), ?M2T(My + AddMy)) of
        true ->
            get_pos_by_meter(Mx2, My2);
        _ ->
            get_random_pos_by_meter2(Mx, My, Times - 1)
    end.


is_safe_tile(IntPos) when erlang:is_integer(IntPos) ->
    is_safe_tile(pos_decode(IntPos));
is_safe_tile(#r_pos{tx = Tx, ty = Ty}) ->
    case map_base_data:get_tile(Tx, Ty) of
        #c_map_tile{is_safe = IsSafe} ->
            IsSafe;
        _ ->
            false
    end.

get_map_base(Args) ->
    case Args of
        #c_map_base{} ->
            Args;
        _ -> %% MapID
            [Config] = lib_config:find(cfg_map_base, Args),
            Config
    end.

get_map_name(MapID) ->
    #c_map_base{map_name = MapName} = get_map_base(MapID),
    MapName.

%% 前端部分配置坐标是真实坐标，需要转换一下
get_pos_by_offset_pos(Mx, My) ->
    get_pos_by_offset_pos(Mx, My, ?DEFAULT_MDIR).
get_pos_by_offset_pos(Mx, My, MDir) ->
    [{OffsetX, OffsetY}] = map_base_data:offset(),
    get_pos_by_meter(Mx - OffsetX, My - OffsetY, MDir).

get_pos_by_map_offset_pos(MapID, Mx, My) ->
    get_pos_by_map_offset_pos(MapID, Mx, My, ?DEFAULT_MDIR).
get_pos_by_map_offset_pos(MapID, Mx, My, MDir) ->
    [{OffsetX, OffsetY}] = lib_config:find(map_base_data:get_map_module(MapID), offset),
    get_pos_by_meter(Mx - OffsetX, My - OffsetY, MDir).

get_offset_meter(Mx, My) ->
    [{OffsetX, OffsetY}] = map_base_data:offset(),
    {Mx + OffsetX, My + OffsetY}.

get_offset_meter_by_map_id(MapID, Mx, My) ->
    [{OffsetX, OffsetY}] = map_base_data:offset(MapID),
    {Mx + OffsetX, My + OffsetY}.

%% 根据点获得r_pos
get_pos_by_meter(Mx, My) ->
    get_pos_by_meter(Mx, My, ?DEFAULT_MDIR).
get_pos_by_meter(Mx, My, MDir) ->
    {Tx, Ty, Dir} = pos_m2t(Mx, My, MDir),
    #r_pos{mx = Mx, my = My, mdir = MDir, tx = Tx, ty = Ty, dir = Dir}.

%% 坐标数据解码  double->r_pos
pos_decode(Pos) ->
    {Mx, My, MDir} = pos_long2m(Pos),
    {TX, TY, Dir} = pos_m2t(Mx, My, MDir),
    #r_pos{
        mx = Mx, my = My, mdir = MDir,
        tx = TX, ty = TY, dir = Dir
    }.

%% 坐标数据编码 r_pos->double
pos_encode(RecordPos) ->
    #r_pos{mx = Mx, my = My, mdir = MDir} = RecordPos,
    pos_m2long(Mx, My, MDir).

%% 前端 Pos = (Dir << 40) + (My << 20) + Mx.
%% return {Mx,My,M_Dir}
pos_long2m(Pos) ->
    {
        (Pos band 16#3ffff),                 %%Mx 20位
        ((Pos bsr 20) band 16#3ffff),        %%My 20位
        ((Pos bsr 40) band 16#3ff)           %%M_DIR 剩余位数
    }.

pos_m2long(Mx, My, MDir) ->
    (MDir bsl 40) + (My bsl 20) + Mx.

pos_m2t(Mx, My, MDir) ->
    {
        ?M2T(Mx),
        ?M2T(My),
        dir_m2t(MDir)
    }.

dir_m2t(MDirT) ->
    MDir = ?IF(MDirT > 0, MDirT, 360 + MDirT),
    if
        MDir >= 23 andalso MDir =< 67 -> 1;
        MDir >= 68 andalso MDir =< 112 -> 2;
        MDir >= 113 andalso MDir =< 157 -> 3;
        MDir >= 158 andalso MDir =< 202 -> 4;
        MDir >= 203 andalso MDir =< 247 -> 5;
        MDir >= 248 andalso MDir =< 292 -> 6;
        MDir >= 293 andalso MDir =< 337 -> 7;
        true -> 0
    end.

pos_t2m(Tx, Ty, Dir) ->
    {
        ?T2M(Tx),
        ?T2M(Ty),
        dir_t2m(Dir)
    }.

dir_t2m(MDir) ->
    MDir * 45.

make_p_map_actor(#r_map_actor{} = MapInfo) ->
    #r_map_actor{
        actor_id = ActorID,
        actor_type = ActorType,
        actor_name = ActorName,
        buffs = Buffs,
        status = Status,
        hp = Hp,
        max_hp = MaxHp,
        move_speed = MoveSpeed,
        pos = Pos,
        target_pos = TargetPos,
        camp_id = CampID,
        pk_mode = PKMode,
        role_extra = RoleExtra,
        monster_extra = MonsterExtra,
        collection_extra = CollectionExtra,
        trap_extra = TrapExtra,
        drop_extra = DropExtra
    } = MapInfo,
    ActorType2 = ?IF(ActorType =:= ?ACTOR_TYPE_ROBOT, ?ACTOR_TYPE_ROLE, ActorType),
    #p_map_actor{
        actor_id = ActorID,
        actor_type = ActorType2,
        actor_name = ActorName,
        buff_id_list = Buffs,
        status = Status,
        hp = Hp,
        max_hp = MaxHp,
        move_speed = MoveSpeed,
        pos = Pos,
        target_pos = TargetPos,
        camp_id = CampID,
        pk_mode = PKMode,
        role_extra = RoleExtra,
        monster_extra = MonsterExtra,
        collection_extra = CollectionExtra,
        trap_extra = TrapExtra,
        drop_extra = DropExtra
    }.

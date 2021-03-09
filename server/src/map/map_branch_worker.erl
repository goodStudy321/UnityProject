%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 十一月 2017 16:18
%%%-------------------------------------------------------------------
-module(map_branch_worker).
-author("laijichang").
-include("global.hrl").

-behaviour(gen_server).

%% API
-export([
    start_link/1
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    role_enter_map/2,
    role_leave_map/2,
    get_map_cur_extra_id/1,
    info/2,
    call/2
]).

-export([
    is_map_fresh/1,
    get_max_role_num/1
]).
%%%===================================================================
%%% API
%%%===================================================================
start_link(MapID) ->
    gen_server:start_link({local, get_worker_pname(MapID)}, ?MODULE, [MapID], []).

init([MapID]) ->
    erlang:process_flag(trap_exit, true),
    set_map_id(MapID),
    pname_server:send(erlang:self(), init),
    ?IF(common_config:is_cross_node(), pname_server:reg(get_worker_pname(MapID), erlang:self()), ok),
    {ok, []}.

handle_call(Request, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Request,State),
    {reply, Reply, State}.

handle_cast(Request, State) ->
    ?DO_HANDLE_INFO(Request, State),
    {noreply, State}.

handle_info(exit, State) ->
    {stop, bad, State};
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ?IF(common_config:is_cross_node(), pname_server:dereg(get_worker_pname(get_map_id())), ok),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

role_enter_map(MapID, ExtraID) ->
    info(MapID, {role_enter_map, MapID, ExtraID}).

role_leave_map(MapID, ExtraID) ->
    info(MapID, {role_leave_map, MapID, ExtraID}).

get_worker_pname(MapID) ->
    lib_tool:to_atom(lists:concat([?MODULE, "_", MapID])).

get_map_cur_extra_id(MapID) ->
    call(MapID, {role_get_extra_id, MapID}).

info(MapID, Info) ->
    pname_server:send(pname_server:pid(get_worker_pname(MapID)), Info).

call(MapID, Info) ->
    pname_server:call(pname_server:pid(get_worker_pname(MapID)), Info).
%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({mod,Mod,Info})->
    Mod:handle(Info);
do_handle({func,Fun})->
    Fun();
do_handle(init) ->
    do_init();
do_handle(loop) ->
    erlang:send_after(?CHECK_EXTRA_CD, erlang:self(), loop),
    do_loop();
do_handle({role_enter_map, MapID, ExtraID}) ->
    do_role_enter_map(MapID, ExtraID);
do_handle({role_leave_map, MapID, ExtraID}) ->
    do_role_leave_map(MapID, ExtraID);
do_handle({role_get_extra_id, MapID}) ->
    do_role_get_extra_id(MapID);
do_handle({func,M,F,A})->
    erlang:apply(M,F,A);
do_handle(Info)->
    ?INFO_MSG("Unknow Message ~w",[Info]).

do_init() ->
    MapID = get_map_id(),
    MapBranch =
        case is_map_fresh(MapID) of
            true -> %% 开服第一天要开多几个分线进行分流
                FirstExtraID = ?DEFAULT_EXTRA_ID,
                [MaxExtraID] = lib_config:find(cfg_map_branch, fresh_max_line),
                CloseTime = get_map_fresh_close_time(),
                ExtraList =
                    [ begin
                          {ok, ExtraID} = start_map(MapID, ExtraID),
                          CloseTime2 = ?IF(ExtraID > FirstExtraID, CloseTime, 0),
                          #r_map_extra{extra_id = ExtraID, role_num = 0, close_time = CloseTime2}
                      end || ExtraID <- lists:seq(FirstExtraID, MaxExtraID)],
                #r_map_branch{
                    map_id = MapID,
                    cur_extra_id = FirstExtraID,
                    max_extra_id = MaxExtraID,
                    extra_list = ExtraList};
            _ ->
                ExtraID = ?DEFAULT_EXTRA_ID,
                {ok, ExtraID} = start_map(MapID, ExtraID),
                #r_map_branch{
                    map_id = MapID,
                    cur_extra_id = ExtraID,
                    max_extra_id = ExtraID,
                    extra_list = [#r_map_extra{extra_id = ExtraID, role_num = 0}]}
        end,
    map_branch_manager:set_map_branch(MapBranch),
    erlang:send_after(?CHECK_EXTRA_CD, erlang:self(), loop).

%% 关闭分线
do_loop() ->
    MapID = get_map_id(),
    Now = time_tool:now(),
    [#r_map_branch{max_extra_id = MaxExtraID, extra_list = ExtraList}] = [MapBranch] = map_branch_manager:get_map_branch(MapID),
    {IsClose, ExtraList2} = do_loop2(ExtraList, MapID, Now, [], false),
    case IsClose of
        true ->
            MaxExtraID2 = ?IF(IsClose, get_max_extra_id(ExtraList2), MaxExtraID),
            MapBranch2 = MapBranch#r_map_branch{max_extra_id = MaxExtraID2, extra_list = ExtraList2},
            map_branch_manager:set_map_branch(MapBranch2),
            do_change_branch(MapBranch2, is_map_fresh(MapID));
        _ ->
            ok
    end.

do_loop2([], _MapID, _Now, ExtraAcc, IsClose) ->
    {IsClose, ExtraAcc};
do_loop2([MapExtra|R], MapID, Now, ExtraAcc, IsClose) ->
    #r_map_extra{
        extra_id = ExtraID,
        close_time = CloseTime,
        role_num = RoleNum} = MapExtra,
    case CloseTime =/= 0 andalso Now > CloseTime andalso RoleNum =< 0 andalso ExtraID =/= ?DEFAULT_EXTRA_ID of
        true ->
            map_sup:stop_map(MapID, ExtraID),
            do_loop2(R, MapID, Now, ExtraAcc, true);
        _ ->
            do_loop2(R, MapID, Now, [MapExtra|ExtraAcc], IsClose)
    end.

%% 玩家进入某个地图分线
do_role_enter_map(MapID, ExtraID) ->
     case map_branch_manager:get_map_branch(MapID) of
         [MapBranch] ->
             ok;
         _ ->
             NowMapExtra = #r_map_extra{extra_id = ExtraID, fresh_enter_num = 0, role_num = 0},
             MapBranch = #r_map_branch{map_id = MapID, cur_extra_id = ExtraID, max_extra_id = ExtraID, extra_list = [NowMapExtra]}
     end,
    #r_map_branch{cur_extra_id = CurExtraID, extra_list = ExtraList} = MapBranch,
    #r_map_extra{role_num = RoleNum, fresh_enter_num = FreshEnterNum} = MapExtra = lists:keyfind(ExtraID, #r_map_extra.extra_id, ExtraList),
    MaxRoleNum = get_max_role_num(MapID),
    RoleNum2 = RoleNum + 1,
    IsMapRefresh = is_map_fresh(MapID),
    {IsFreshChange, FreshEnterNum2} = ?IF(IsMapRefresh, ?IF(FreshEnterNum + 1 >= get_map_fresh_change_num(), {true, 0}, {false, FreshEnterNum + 1}), {false, 0}),
    MapExtra2 = MapExtra#r_map_extra{role_num = RoleNum2, fresh_enter_num = FreshEnterNum2},
    ExtraList2 = lists:keyreplace(ExtraID, #r_map_extra.extra_id, ExtraList, MapExtra2),
    MapBranch2 = MapBranch#r_map_branch{extra_list = ExtraList2},
    map_branch_manager:set_map_branch(MapBranch2),
    ?IF((CurExtraID =:= ExtraID andalso RoleNum2 >= MaxRoleNum) orelse IsFreshChange, do_change_branch(MapBranch2, IsMapRefresh), ok).

%% 玩家退出某个地图分线
do_role_leave_map(MapID, ExtraID) ->
    [#r_map_branch{cur_extra_id = CurExtraID, extra_list = ExtraList}] = [MapBranch] = map_branch_manager:get_map_branch(MapID),
    #r_map_extra{role_num = RoleNum} = MapExtra = lists:keyfind(ExtraID, #r_map_extra.extra_id, ExtraList),
    RoleNum2 = RoleNum - 1,
    IsMapRefresh = is_map_fresh(MapID),
    case RoleNum2 =< 0 andalso ExtraID =/= ?DEFAULT_EXTRA_ID andalso not IsMapRefresh of
        true -> %% 人数为0且不是默认分线，并且不是开服第一天的新手地图时，要考虑转换分线并设置关闭时间
            MapExtra2 = MapExtra#r_map_extra{role_num = 0, close_time = time_tool:now() + ?CLOSE_TIME},
            ExtraList2 = lists:keyreplace(ExtraID, #r_map_extra.extra_id, ExtraList, MapExtra2),
            MapBranch2 = MapBranch#r_map_branch{extra_list = ExtraList2},
            map_branch_manager:set_map_branch(MapBranch2),
            ?IF(CurExtraID =:= ExtraID, do_change_branch(MapBranch2, false), ok);
        _ ->
            MapExtra2 = MapExtra#r_map_extra{role_num = RoleNum2},
            ExtraList2 = lists:keyreplace(ExtraID, #r_map_extra.extra_id, ExtraList, MapExtra2),
            MapBranch2 = MapBranch#r_map_branch{extra_list = ExtraList2},
            map_branch_manager:set_map_branch(MapBranch2)
    end.

do_change_branch(MapBranch, IsMapRefresh) ->
    #r_map_branch{map_id = MapID, extra_list = ExtraList, max_extra_id = MaxExtraID} = MapBranch,
    SortKey = ?IF(IsMapRefresh, #r_map_extra.role_num, #r_map_extra.extra_id),
    ExtraList2 = lists:keysort(SortKey, ExtraList),
    MaxRoleNum = get_max_role_num(MapID),
    case do_change_branch2(ExtraList2, MaxRoleNum, IsMapRefresh, [], []) of
        {change_branch, ExtraID, ExtraList3} ->
            MapBranch2 = MapBranch#r_map_branch{cur_extra_id = ExtraID, extra_list = ExtraList3},
            map_branch_manager:set_map_branch(MapBranch2);
        _ ->
            ExtraIDList = [ ExtraID || #r_map_extra{extra_id = ExtraID} <- ExtraList2],
            AllExtraID = lists:seq(1, MaxExtraID + 1),
            [NewID|_] = AllExtraID -- ExtraIDList,
            {ok, NewID} = start_map(MapID, NewID),
            MaxExtraID2 = ?IF(NewID > MaxExtraID, NewID, MaxExtraID),
            CloseTime = ?IF(IsMapRefresh, get_map_fresh_close_time(), 0),
            NewExtra = #r_map_extra{extra_id = NewID, role_num = 0, close_time = CloseTime},
            ExtraList3 = [NewExtra|ExtraList2],
            MapBranch2 = MapBranch#r_map_branch{cur_extra_id = NewID, max_extra_id = MaxExtraID2, extra_list = ExtraList3},
            map_branch_manager:set_map_branch(MapBranch2)
    end.

%% 先在分线中找一个
do_change_branch2([], _MaxRoleNum, _IsMapRefresh, CloseList, ExtraAcc) ->
    do_change_branch3(lists:keysort(#r_map_extra.extra_id, CloseList), ExtraAcc);
do_change_branch2([MapExtra|R], MaxRoleNum, IsMapRefresh, CloseList, ExtraAcc) ->
    #r_map_extra{extra_id = ExtraID, role_num = RoleNum, close_time = CloseTime} = MapExtra,
    if
        not IsMapRefresh andalso CloseTime > 0 -> %% 新手地图设置了个默认关闭的时间。。这里要另外判断一下
            CloseList2 = [MapExtra|CloseList],
            do_change_branch2(R, MaxRoleNum, IsMapRefresh, CloseList2, ExtraAcc);
        true ->
            case MaxRoleNum > RoleNum of
                true ->
                    ExtraList = CloseList ++ [MapExtra|R] ++ ExtraAcc,
                    {change_branch, ExtraID, ExtraList};
                _ ->
                    do_change_branch2(R, MaxRoleNum, IsMapRefresh, CloseList, [MapExtra|ExtraAcc])
            end
    end.

%% 从要关闭的列表中找一个
do_change_branch3([], _ExtraAcc) ->
    false;
do_change_branch3([CloseExtra|R], ExtraAcc) ->
    #r_map_extra{extra_id = ExtraID} = CloseExtra,
    CloseExtra2 = CloseExtra#r_map_extra{close_time = 0},
    {change_branch, ExtraID, [CloseExtra2|R] ++ ExtraAcc}.

do_role_get_extra_id(MapID) ->
    [#r_map_branch{cur_extra_id = CurExtraID}] = map_branch_manager:get_map_branch(MapID),
    CurExtraID.

start_map(MapID, ExtraID) ->
    {ok, _PID} = map_sup:start_map(MapID, ExtraID),
    {ok, ExtraID}.

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_map_id(MapID) ->
    erlang:put({?MODULE, map_id}, MapID).
get_map_id() ->
    erlang:get({?MODULE, map_id}).

get_max_role_num(MapID) ->
    case lib_config:find(cfg_map_base, MapID) of
        [#c_map_base{max_num = MaxRoleNum}] when MaxRoleNum > 0 ->
            ok;
        _  ->
            [MaxRoleNum] = lib_config:find(cfg_map_branch, default_map_num)
    end,
    MaxRoleNum.

get_max_extra_id(ExtraList) ->
    [#r_map_extra{extra_id = MaxExtraID}|_] =
        lists:sort(fun(#r_map_extra{extra_id = ExtraID1}, #r_map_extra{extra_id = ExtraID2}) -> ExtraID1 > ExtraID2 end, ExtraList),
    MaxExtraID.

is_map_fresh(MapID) ->
    [MapList] = lib_config:find(cfg_map_branch, fresh_map_list),
    common_config:get_open_days() =:= 1 andalso lists:member(MapID, MapList).

get_map_fresh_close_time() ->
    Now = time_tool:now(),
    OpenTime = common_config:get_open_time(),
    DiffDays = time_tool:diff_date(OpenTime + ?ONE_DAY, Now),
    Now + time_tool:diff_next_hoursec(Now, 0, 0) + (?ONE_DAY * (DiffDays - 1)).

get_map_fresh_change_num() ->
    [FreshChangeNum] = lib_config:find(cfg_map_branch, fresh_change_num),
    FreshChangeNum.
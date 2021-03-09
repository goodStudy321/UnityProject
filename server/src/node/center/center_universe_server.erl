%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     中央服-太虚通天塔排行进程
%%% @end
%%% Created : 17. 九月 2019 10:40
%%%-------------------------------------------------------------------
-module(center_universe_server).
-author("laijichang").
-include("global.hrl").
-include("universe.hrl").

%% API
-export([
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
    game_get_center_data/1,
    role_finish_copy/1,
    role_update_info/1,
    gm_clear_universe_rank/0
]).

-export([
    is_rank_update/2
]).

%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------
start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

game_get_center_data(NodeID) ->
    pname_server:send(?MODULE, {game_get_center_data, NodeID}).

role_finish_copy(Info) ->
    pname_server:call(?MODULE, {role_finish_copy, Info}).

role_update_info(Info) ->
    pname_server:send(?MODULE, {role_update_info, Info}).

gm_clear_universe_rank() ->
    pname_server:send(?MODULE, gm_clear_universe_rank).
%%%-------------------------------------------------------------------
%%% gen_server callbacks
%%%-------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    pname_server:reg(?MODULE, erlang:self()),
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
    pname_server:dereg(?MODULE),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({game_get_center_data, NodeID}) ->
    do_game_get_center_data(NodeID);
do_handle({role_finish_copy, Info}) ->
    do_role_finish_copy(Info);
do_handle({role_update_info, Info}) ->
    do_role_update_info(Info);
do_handle(gm_clear_universe_rank) ->
    do_gm_clear_universe_rank();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_game_get_center_data(NodeID) ->
    AllData = get_all_data(),
    node_msg_manager:send_msg_by_node(node_misc:get_node_name_by_node_id(NodeID), game_universe_server, {center_send_data, AllData}).

do_role_finish_copy(Info) ->
    #universe_info{
        update_list = UpdateList
    } = Info,
    ResultList =
        [
            if
            UpdateKey =:= ?UNIVERSE_UPDATE_KEY_FLOOR ->
                Result = do_update_floor(Info),
                {?UNIVERSE_UPDATE_KEY_FLOOR, Result};
            UpdateKey =:= ?UNIVERSE_UPDATE_FLOOR_RANK ->
                do_update_rank(Info),
                ok;
            true ->
                ?ERROR_MSG("unknow UpdateKey : ~w", [UpdateKey]),
                ok
        end|| UpdateKey <- UpdateList],
    ResultList.

do_role_update_info(Info) ->
    #universe_role_info{
        role_id = RoleID,
        role_name = RoleName,
        confine_id = ConfineID,
        category = Category,
        sex = Sex,
        level = Level,
        skin_list = SkinList
    } = Info,
    Ranks = get_ranks(),
    case lists:keytake(RoleID, #r_universe_rank.role_id, Ranks) of
        {value, Rank, Ranks2} ->
            Rank2 = Rank#r_universe_rank{
                role_name = RoleName,
                confine_id = ConfineID,
                category = Category,
                sex = Sex,
                level = Level,
                skin_list = SkinList
            },
            Ranks3 = lists:reverse(lists:keysort(#r_universe_rank.rank, [Rank2|Ranks2])),
            set_ranks(Ranks3),
            broadcast_update_data(?UNIVERSE_FLOOR_RANK, Ranks3);
        _ ->
            ok
    end.


%% 更新层数信息
do_update_floor(Info) ->
    #universe_info{
        role_id = RoleID,
        role_name = RoleName,
        server_name = ServerName,
        copy_id = CopyID,
        use_time = UseTime,
        power = Power
    } = Info,
    case get_floor(CopyID) of
        #r_universe_floor{use_time = OldUseTime, power = OldPower} = UniverseFloorT ->
            {Status, UniverseFloor} =
                if
                    UseTime < OldUseTime andalso Power < OldPower ->
                        {?UNIVERSE_ROLE_BOTH, UniverseFloorT#r_universe_floor{
                            fast_role_id = RoleID,
                            fast_role_name = RoleName,
                            fast_server_name = ServerName,
                            use_time = UseTime,
                            power = Power,
                            power_role_id = RoleID,
                            power_role_name = RoleName,
                            power_server_name = ServerName
                        }};
                    UseTime < OldUseTime ->
                        {?UNIVERSE_ROLE_FAST, UniverseFloorT#r_universe_floor{
                            fast_role_id = RoleID,
                            fast_role_name = RoleName,
                            fast_server_name = ServerName,
                            use_time = UseTime
                        }};
                    Power < OldPower ->
                        {?UNIVERSE_ROLE_MIN_POWER, UniverseFloorT#r_universe_floor{
                            power = Power,
                            power_role_id = RoleID,
                            power_role_name = RoleName,
                            power_server_name = ServerName}};
                    true ->
                        {0, UniverseFloorT}
                end,
            ?IF(Status > 0, do_update_floor2(UniverseFloor), ok),
            Status;
        _ ->
            UniverseFloor = #r_universe_floor{
                copy_id = CopyID,
                fast_role_id = RoleID,
                fast_role_name = RoleName,
                fast_server_name = ServerName,
                use_time = UseTime,
                power = Power,
                power_role_id = RoleID,
                power_role_name = RoleName,
                power_server_name = ServerName
            },
            do_update_floor2(UniverseFloor),
            ?UNIVERSE_ROLE_BOTH
    end.

do_update_floor2(UniverseFloor) ->
    #r_universe_floor{copy_id = CopyID} = UniverseFloor,
    set_floor(CopyID, UniverseFloor),
    broadcast_update_data({?UNIVERSE_KEY_FLOOR, CopyID}, UniverseFloor).

%% 更新排行榜
do_update_rank(Info) ->
    #universe_info{
        role_id = RoleID,
        role_name = RoleName,
        server_name = ServerName,
        copy_id = CopyID,
        confine_id = ConfineID,
        use_time = UseTime,
        category = Category,
        sex = Sex,
        level = Level,
        skin_list = SkinList
    } = Info,
    Ranks = get_ranks(),
    case is_rank_update(Info, Ranks) of
        true ->
            Rank = #r_universe_rank{
                role_id = RoleID,
                role_name = RoleName,
                server_name = ServerName,
                copy_id = CopyID,
                confine_id = ConfineID,
                use_time = UseTime,
                category = Category,
                sex = Sex,
                level = Level,
                skin_list = SkinList
            },
            Rank2 = lists:keystore(RoleID, #r_universe_rank.role_id, Ranks, Rank),
            Ranks3 = get_sort_ranks(Rank2),
            set_ranks(Ranks3),
            ?INFO_MSG("get_sort_ranks : ~w", [Ranks3]),
            broadcast_update_data(?UNIVERSE_FLOOR_RANK, Ranks3);
        _ ->
            ok
    end.

is_rank_update(Info, Ranks) ->
    #universe_info{
        role_id = RoleID,
        copy_id = CopyID,
        use_time = UseTime
    } = Info,
    case lists:keyfind(RoleID, #r_universe_rank.role_id, Ranks) of
        #r_universe_rank{copy_id = OldCopyID, use_time = OldUseTime} -> %% 在排行榜中，更新
            is_value_need_update(CopyID, UseTime, OldCopyID, OldUseTime);
        _ ->
            case Ranks of
                [#r_universe_rank{rank = Rank, copy_id = RankCopyID, use_time = RankUseTime}|_] ->
                    case Rank < ?UNIVERSE_RANK_NUM of
                        true ->
                            true;
                        _ ->
                            is_value_need_update(CopyID, UseTime, RankCopyID, RankUseTime)
                    end;
                _ ->
                    true
            end
    end.

%% 获取前三名和最新的排行榜
get_sort_ranks(Ranks) ->
    Ranks2 = lists:sublist(lists:sort(
        fun(#r_universe_rank{copy_id = CopyID1, use_time = UseTime1}, #r_universe_rank{copy_id = CopyID2, use_time = UseTime2}) ->
            is_value_need_update(CopyID1, UseTime1, CopyID2, UseTime2)
        end, Ranks), ?UNIVERSE_RANK_NUM),
    {_Index, Rank3} =
    lists:foldl(
        fun(Rank, {IndexAcc, RanksAcc}) ->
            Rank2 = Rank#r_universe_rank{rank = IndexAcc},
            RanksAcc2 = [Rank2|RanksAcc],
            {IndexAcc + 1, RanksAcc2}
        end, {1, []}, Ranks2),
    Rank3.


is_value_need_update(CopyID1, UseTime1, CopyID2, UseTime2) ->
    CopyID1 > CopyID2 orelse (CopyID1 =:= CopyID2 andalso UseTime1 < UseTime2).

broadcast_update_data(Key, Value) ->
    node_misc:center_send_mfa_to_all_game_node({game_universe_server, center_update_data, [Key, Value]}).

do_gm_clear_universe_rank() ->
    db:delete_all(?DB_COPY_UNIVERSE_P),
    node_misc:center_send_server_info_to_all_game_node( game_universe_server, {center_send_data, []}).

%%%===================================================================
%%% data
%%%===================================================================
get_floor(CopyID) ->
    get_data({?UNIVERSE_KEY_FLOOR, CopyID}).
set_floor(CopyID, Value) ->
    set_data({?UNIVERSE_KEY_FLOOR, CopyID}, Value).

%% 有序，最后一名是在第一个数据
get_ranks() ->
    case get_data(?UNIVERSE_FLOOR_RANK) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.
set_ranks(List) ->
    set_data(?UNIVERSE_FLOOR_RANK, List).

get_data(Key) ->
    case ets:lookup(?DB_COPY_UNIVERSE_P, Key) of
        [#r_universe{value = Value}] ->
            Value;
        _ ->
            undefined
    end.
get_all_data() ->
    ets:tab2list(?DB_COPY_UNIVERSE_P).
set_data(Key, Value) ->
    db:insert(?DB_COPY_UNIVERSE_P, #r_universe{key = Key, value = Value}).
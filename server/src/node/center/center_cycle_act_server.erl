%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     中央服-太虚通天塔排行进程
%%% @end
%%% Created : 17. 九月 2019 10:40
%%%-------------------------------------------------------------------
-module(center_cycle_act_server).
-author("laijichang").
-include("global.hrl").
-include("cycle_act_couple.hrl").
-include("cycle_act.hrl").

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
    game_get_center_data/2,
    upload/2,

    gm_clear_charm_rank/0
]).

-export([
    is_rank_update/3
]).

%%%-------------------------------------------------------------------
%%% API
%%%-------------------------------------------------------------------
start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

game_get_center_data(Date, NodeID) ->
    pname_server:send(?MODULE, {game_get_center_data, Date, NodeID}).

upload(Date, UploadList) ->
    pname_server:send(?MODULE, {upload, Date, UploadList}).

gm_clear_charm_rank() ->
    pname_server:send(?MODULE, gm_clear_charm_rank).
%%%-------------------------------------------------------------------
%%% gen_server callbacks
%%%-------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    pname_server:reg(?MODULE, erlang:self()),
    time_tool:reg(world, [0]),
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
do_handle({game_get_center_data, Date, NodeID}) ->
    do_game_get_center_data(Date, NodeID);
do_handle({upload, Date, UploadList}) ->
    do_upload(Date, UploadList);
do_handle(?TIME_ZERO) ->
    do_zero();
do_handle(gm_clear_charm_rank) ->
    do_gm_clear_charm_rank();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_game_get_center_data(Date, NodeID) ->
    List = [ {{Date, Sex}, get_ranks({Date, Sex})} || Sex <- [?SEX_BOY, ?SEX_GIRL]],
    node_misc:send_mfa_to_game_node_by_node_id(NodeID, {act_couple, center_send_data, [List]}).

%% 更新排行榜
do_upload(_Date, []) ->
    ok;
do_upload(Date, [CharmRank|R]) ->
    #r_charm_rank{
        role_id = RoleID,
        charm = NowCharm,
        sex = Sex
    } = CharmRank,
    Key = {Date, Sex},
    Ranks = get_ranks({Date, Sex}),
    case is_rank_update(RoleID, NowCharm, Ranks) of
        true ->
            Rank2 = lists:keystore(RoleID, #r_charm_rank.role_id, Ranks, CharmRank),
            Ranks3 = get_sort_ranks(Rank2),
            set_ranks(Key, Ranks3),
            ?INFO_MSG("get_sort_ranks : ~w", [Ranks3]),
            broadcast_update_data([{Key, Ranks3}]);
        _ ->
            ok
    end,
    do_upload(Date, R).

do_zero() ->
    Now = time_tool:now(),
    %% 昨天的进行结算
    {Date, _} = time_tool:timestamp_to_datetime(Now - ?AN_HOUR),
    BoyRanks = get_ranks({Date, ?SEX_BOY}),
    GirlRanks = get_ranks({Date, ?SEX_GIRL}),
    node_misc:center_send_mfa_to_all_game_node({act_couple, send_rank_reward, [BoyRanks ++ GirlRanks]}).

%% 获取前三名和最新的排行榜
get_sort_ranks(Ranks) ->
    Ranks2 = lists:sublist(lists:sort(
        fun(#r_charm_rank{charm = Charm1, update_time = UpdateTime1}, #r_charm_rank{charm = Charm2, update_time = UpdateTime2}) ->
            ?IF(Charm1 =:= Charm2, UpdateTime1 < UpdateTime2, Charm1 > Charm2)
        end, Ranks), ?CYCLE_ACT_COUPLE_CHARM_LEN),
    {_Index, Rank3} =
        lists:foldl(
            fun(Rank, {IndexAcc, RanksAcc}) ->
                Rank2 = Rank#r_charm_rank{rank = IndexAcc},
                RanksAcc2 = [Rank2|RanksAcc],
                {IndexAcc + 1, RanksAcc2}
            end, {1, []}, Ranks2),
    Rank3.

is_rank_update(RoleID, NowCharm, Ranks) ->
    case lists:keymember(RoleID, #r_charm_rank.role_id, Ranks) of
        true ->
            true;
        _ ->
            case Ranks of
                [#r_charm_rank{rank = Rank, charm = RankCharm}] when Rank >= ?CYCLE_ACT_COUPLE_CHARM_LEN ->
                    NowCharm > RankCharm;
                _ ->
                    true
            end
    end.

broadcast_update_data(List) ->
    node_misc:center_send_mfa_to_all_game_node({act_couple, center_update_data, [List]}).

do_gm_clear_charm_rank() ->
    Date = erlang:date(),
    Key1 = {Date, ?SEX_BOY},
    Key2 = {Date, ?SEX_GIRL},
    set_ranks(Key1, []),
    set_ranks(Key2, []),
    broadcast_update_data([{Key1, []}, {Key2, []}]).

%%%===================================================================
%%% data
%%%===================================================================
get_ranks(Key) ->
    case ets:lookup(?DB_CYCLE_ACT_COUPLE_RANK_P, Key) of
        [#r_cycle_act_couple_rank{rank_list = RankList}] ->
            RankList;
        _ ->
            []
    end.
set_ranks(Key, RankList) ->
    db:insert(?DB_CYCLE_ACT_COUPLE_RANK_P, #r_cycle_act_couple_rank{key = Key, rank_list = RankList}).
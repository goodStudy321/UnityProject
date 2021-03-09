%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     游戏服拓扑管理进程
%%% @end
%%% Created : 26. 二月 2019 16:38
%%%-------------------------------------------------------------------
-module(game_topology_server).
-author("laijichang").
-include("node.hrl").
-include("rank.hrl").

%% API
-export([
    start/0,
    start_link/0
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
    info/1
]).

start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

info(Info) ->
    pname_server:send(?MODULE, Info).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    erlang:send_after(15 * 1000, erlang:self(), get_cross_topology),
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
do_handle(get_cross_topology) ->
    do_get_cross_topology();

do_handle(center_match_get_data) ->
    do_center_match_get_data();
do_handle({center_send_cross, CrossID, CrossIP, NextMatchTime}) ->
    do_center_send_cross(CrossID, CrossIP, NextMatchTime);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_get_cross_topology() ->
    erlang:send_after(?ONE_MINUTE * 1000, erlang:self(), get_cross_topology),
    ServerID = global_data:get_cross_server_id(),
    case common_config:is_cross_server_id(ServerID) of
        true -> %% 已经连上了
            ok;
        _ ->
            ServerPower = get_server_power(),
            NodeID = node_misc:get_node_id(),
            PublicIP = common_config:get_server_public_ip(),
            center_topology_server:game_get_cross_topology(NodeID, PublicIP, ServerPower)
    end.


do_center_match_get_data() ->
    global_data:set_cross_server_id(0),
    global_data:set_cross_server_ip(""),
    ServerPower = get_server_power(),
    NodeID = node_misc:get_node_id(),
    PublicIP = common_config:get_server_public_ip(),
    OpenDays = common_config:get_open_days(),
    center_topology_server:game_match_send_data(NodeID, PublicIP, OpenDays, ServerPower).

do_center_send_cross(CrossID, CrossIP, NextMatchTime) ->
    global_data:set_cross_server_id(CrossID),
    global_data:set_cross_server_ip(CrossIP),
    global_data:set_cross_next_match_time(NextMatchTime).

get_server_power() ->
    PowerList =
        [ begin
              Power1 = math:pow(((Power/1000000) + 5), 2),
              Power2 =
                  case db:lookup(?DB_ROLE_PAY_P, RoleID) of
                      [#r_role_pay{total_pay_gold = TotalPayGold}] ->
                          TotalPayGold/1000;
                      _ ->
                          0
                  end,
              Power1 - Power2
          end || #r_rank_role_power{role_id = RoleID, power = Power}<- rank_misc:get_rank(?RANK_ROLE_POWER)],
    lib_tool:ceil(lists:sum(PowerList)).
%%%===================================================================
%%% data
%%%===================================================================

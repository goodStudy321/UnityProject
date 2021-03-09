%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     中央拓扑管理进程
%%% @end
%%% Created : 26. 二月 2019 16:38
%%%-------------------------------------------------------------------
-module(center_topology_server).
-author("laijichang").
-include("node.hrl").
-include("letter.hrl").

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
    game_get_cross_topology/3,
    game_match_send_data/4,
    reload_config/0
]).

-export([
    i/0,
    info/1,
    call/1
]).

-export([
    get_next_diff_days/2,
    get_next_topology_start_time/0,
    get_next_topology_start_time/1,
    get_next_topology_start_time/2,
    get_web_ip_area_list/0,
    get_game_group_and_num/1,
    get_game_group_server_list/2
]).

-export([
    gm_center_reset_match/0,
    gm_start_match/0,
    get_game_topology/1,
    get_cross_topology/1,
    get_all_cross_topology/0,
    get_all_game_topology/0
]).

-export([
    test_match/0,
    test_new_game/0
]).

start() ->
    node_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

i() ->
    call(i).

game_get_cross_topology(NodeID, PublicIP, ServerPower) ->
    info({game_get_cross_topology, NodeID, PublicIP, ServerPower}).

game_match_send_data(NodeID, PublicIP, OpenDays, ServerPower) ->
    info({game_match_send_data, NodeID, PublicIP, OpenDays, ServerPower}).

reload_config() ->
    info(reload_config).

info(Info) ->
    pname_server:send(pname_server:pid(?MODULE), Info).

call(Info) ->
    pname_server:call(pname_server:pid(?MODULE), Info).

gm_center_reset_match() ->
    world_data:set_center_topology_args(#r_center_topology_args{last_match_time = 0, is_send_letter = false, broadcast_min_list = []}).

gm_start_match() ->
    info(gm_start_match).

test_match() ->
    IPRegionList = get_web_ip_area_list(),
    TestIPList = ["127.0.0.1", "192.168.2.250", "192.168.2.243"],
    AgentID = common_config:get_agent_id(),
    RandomNum1 = lib_tool:random(100, 200),
    RandomNum2 = lib_tool:random(10, 20),
    GameList = [
        #r_game_topology_info{
            node_id = node_misc:get_node_id_by_agent_server_id(AgentID, GameIndex),
            public_ip = lib_tool:random_element_from_list(TestIPList),
            open_days = lib_tool:random(1, 90),
            power = lib_tool:random(1, 5000)
        }
    || GameIndex <- lists:seq(1, RandomNum1)],
    CrossNodeList = [
        begin
            IP = lib_tool:random_element_from_list(TestIPList),
            #r_cross_topology_info{
                node_id = node_misc:get_node_id_by_agent_server_id(AgentID, 90000 + CrossIndex),
                ip = IP,
                public_ip = IP
            }
        end || CrossIndex <- lists:seq(1, RandomNum2)],
    VersionList = get_version_list(),
    CrossRegionList = do_topology_cross_sort(CrossNodeList, IPRegionList, VersionList, []),
    GameRegionList = do_topology_game_sort(GameList, IPRegionList, VersionList, []),
    del_all_game_topology(),
    del_all_cross_topology(),
    do_topology_match2(GameRegionList, CrossRegionList).

test_new_game() ->
    #r_center_topology_args{last_match_time = LastMatchTime} = world_data:get_center_topology_args(),
    NextMatchTime = get_next_topology_start_time(LastMatchTime),
    TestIPList = ["127.0.0.1", "192.168.2.250", "192.168.2.243"],
    AgentID = common_config:get_agent_id(),
    NodeID = node_misc:get_node_id_by_agent_server_id(AgentID, lib_tool:random(2000, 3000)),
    do_new_game_match(NodeID, lib_tool:random_element_from_list(TestIPList), lib_tool:random(1, 5000), NextMatchTime).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    pname_server:reg(?MODULE, erlang:self()),
    time_tool:reg(node, [5000]),
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
    time_tool:dereg(node, [5000]),
    pname_server:dereg(?MODULE),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle(i) ->
    get_match_status();
do_handle({loop_msec, NowMs}) ->
    do_loop(NowMs div 1000);
do_handle({game_get_cross_topology, NodeID, PublicIP, ServerPower}) ->
    do_game_get_cross_topology(NodeID, PublicIP, ServerPower);
do_handle({game_match_send_data, NodeID, PublicIP, OpenDays, ServerPower}) ->
    do_game_match_send_data(NodeID, PublicIP, OpenDays, ServerPower);
do_handle(reload_config) ->
    do_reload_config();
do_handle(gm_start_match) ->
    do_gm_start_match();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_gm_start_match() ->
    Now = time_tool:now(),
    TopologyArgs = #r_center_topology_args{
        last_match_time = time_tool:now(),
        is_send_letter = false,
        broadcast_min_list = []
    },
    world_data:set_center_topology_args(TopologyArgs),
    MatchStatus = #r_center_topology_status{status = ?TOPOLOGY_STATUS_INIT, next_status_time = Now + ?ONE_MINUTE},
    set_match_status(MatchStatus).

do_loop(Now) ->
    case get_match_status() of
        #r_center_topology_status{} = MatchStatus -> %% 正在匹配
            do_match(Now, MatchStatus);
        _ ->
            do_loop2(Now)
    end.

do_loop2(Now) ->
    {Date, {Hour, Min, _Sec}} = time_tool:timestamp_to_datetime(Now),
    #r_center_topology_args{last_match_time = LastMatchTime} = TopologyArgs = world_data:get_center_topology_args(),
    DiffDays = get_next_diff_days(LastMatchTime, Now),
    case DiffDays =:= 0 of
        true -> %% 当天可以匹配咯
            [{{BeginHour, BeginMin}, {EndHour, EndMin}}] = lib_config:find(cfg_topology, topo_time),
            if
                {BeginHour, BeginMin} =< {Hour, Min} andalso {Hour, Min} < {EndHour, EndMin} -> %% 可以匹配了
                    TopologyArgs2 = TopologyArgs#r_center_topology_args{
                        last_match_time = Now,
                        is_send_letter = false,
                        broadcast_min_list = []
                    },
                    world_data:set_center_topology_args(TopologyArgs2),
                    MatchStatus = #r_center_topology_status{status = ?TOPOLOGY_STATUS_INIT, next_status_time = Now + ?ONE_MINUTE},
                    set_match_status(MatchStatus);
                {Hour, Min} < {BeginHour, BeginMin} -> %% 可以广播
                    do_send_broadcast((BeginHour - Hour) * 60 + BeginMin - Min, TopologyArgs);
                true ->
                    ok
            end;
        _ ->
            do_send_letter(Date, Hour, DiffDays, TopologyArgs)
    end.

%% 发送信件
do_send_letter(Date, Hour, DiffDays, TopologyArgs) ->
    #r_center_topology_args{is_send_letter = IsSendLetter} = TopologyArgs,
    [{BeforeDays, SendHour}] = lib_config:find(cfg_topology, letter_send_time),
    case IsSendLetter of
        true -> %% 已经发送邮件了
            ok;
        _ ->
            case DiffDays =< BeforeDays andalso Hour =:= SendHour of
                true -> %% 发送邮件
                    LetterInfo =
                        #r_letter_info{
                            template_id = ?LETTER_TEMPLATE_CROSS_FORE_NOTICE,
                            text_string = [time_tool:timestamp_to_datetime_str(get_next_topology_start_time(Date, DiffDays))],
                            days = BeforeDays + 1,
                            condition = #r_gm_condition{min_level = ?ROLE_CROSS_LEVEL}},
                    node_misc:center_send_mfa_to_all_game_node({common_letter, send_letter, [?GM_MAIL_ID, LetterInfo]}),
                    world_data:set_center_topology_args(TopologyArgs#r_center_topology_args{is_send_letter = true});
                _ ->
                    ok
            end
    end.

%% 发送广播
do_send_broadcast(Min, TopologyArgs) ->
    #r_center_topology_args{broadcast_min_list = MinList} = TopologyArgs,
    [ConfigMinList] = lib_config:find(cfg_topology, broadcast_min),
    ConfigMinList2 = lists:reverse(lists:sort(ConfigMinList)),
    case (not lists:member(Min, MinList)) andalso do_send_broadcast2(ConfigMinList2 -- MinList, Min) of
        {ok, BroadcastMin} ->
            TopologyArgs2 = TopologyArgs#r_center_topology_args{broadcast_min_list = [BroadcastMin|MinList]},
            world_data:set_center_topology_args(TopologyArgs2),
            common_broadcast:send_world_common_notice(?NOTICE_FORE_TOPOLOGY, [lib_tool:to_list(BroadcastMin)]);
        _ ->
            ok
    end.

do_send_broadcast2([], _Min) ->
    false;
do_send_broadcast2([ConfigMin|R], Min) ->
    case Min =< ConfigMin of
        true ->
            {ok, ConfigMin};
        _ ->
            do_send_broadcast2(R, Min)
    end.

%% 匹配
do_match(Now, MatchStatus) ->
    #r_center_topology_status{status = Status} = MatchStatus,
    case Status of
        ?TOPOLOGY_STATUS_INIT ->
            do_topology_init(Now, MatchStatus);
        ?TOPOLOGY_STATUS_GET_DATA ->
            do_topology_get_data(Now, MatchStatus);
        ?TOPOLOGY_STATUS_MATCH ->
            do_topology_match(MatchStatus);
        ?TOPOLOGY_STATUS_PUSH ->
            do_topology_push(Now, MatchStatus)
    end.

do_topology_init(Now, MatchStatus) ->
    node_misc:center_send_server_info_to_all_game_node(game_topology_server, center_match_get_data),
    GameList =
        [ #r_game_topology_info{
            node_id = NodeID,
            public_ip = PublicIP
        } || #r_connect_node{node_id = NodeID, public_ip = PublicIP} <- node_base:get_all_node(),
            NodeID =/= undefined andalso erlang:is_integer(NodeID) andalso node_misc:is_game_node_id(NodeID)],
    MatchStatus2 = MatchStatus#r_center_topology_status{
        status = ?TOPOLOGY_STATUS_GET_DATA,
        game_list = GameList,
        next_status_time = Now + ?ONE_MINUTE},
    set_match_status(MatchStatus2).

do_topology_get_data(Now, MatchStatus) ->
    #r_center_topology_status{
        game_list = GameList,
        next_status_time = NextStatusTime
    } = MatchStatus,
    case Now > NextStatusTime of
        true -> %% 强行进入下一个阶段
            GameList2 = [ GameInfo || #r_game_topology_info{open_days = OpenDays} = GameInfo <- GameList, OpenDays =/= undefined],
            MatchStatus2 = MatchStatus#r_center_topology_status{
                status = ?TOPOLOGY_STATUS_MATCH,
                game_list = GameList2,
                next_status_time = Now + ?ONE_MINUTE},
            set_match_status(MatchStatus2);
        _ ->
            case check_topology_data(GameList) of
                ok ->
                    MatchStatus2 = MatchStatus#r_center_topology_status{
                        status = ?TOPOLOGY_STATUS_MATCH,
                        next_status_time = Now + ?ONE_MINUTE},
                    set_match_status(MatchStatus2);
                _ ->
                    ok
            end
    end.

check_topology_data([]) ->
    ok;
check_topology_data([#r_game_topology_info{open_days = OpenDays}|R]) ->
    ?IF(OpenDays =:= undefined, false, check_topology_data(R)).


%% 匹配
do_topology_match(MatchStatus) ->
    #r_center_topology_status{game_list = GameList} = MatchStatus,
    IPRegionList = get_web_ip_area_list(),
    CrossNodeList =
        [ begin
              #r_cross_topology_info{
                  node_id = NodeID,
                  ip = IP,
                  public_ip = PublicIP}
          end ||#r_connect_node{node_id = NodeID, ip = IP, public_ip = PublicIP} <- node_base:get_all_node(),
            NodeID =/= undefined andalso erlang:is_integer(NodeID) andalso node_misc:is_cross_node_id(NodeID)],
    VersionList = get_version_list(),
    CrossRegionList = do_topology_cross_sort(CrossNodeList, IPRegionList, VersionList, []),
    GameRegionList = do_topology_game_sort(GameList, IPRegionList, VersionList, []),
    del_all_game_topology(),
    del_all_cross_topology(),
    do_topology_match2(GameRegionList, CrossRegionList),
    [{{_BeginHour, _BeginMin}, {EndHour, EndMin}}] = lib_config:find(cfg_topology, topo_time),
    NextStatusTime = time_tool:timestamp({time_tool:date(), {EndHour, EndMin, 0}}) - 5 * ?ONE_MINUTE,
    MatchStatus2 = MatchStatus#r_center_topology_status{status = ?TOPOLOGY_STATUS_PUSH, next_status_time = NextStatusTime},
    set_match_status(MatchStatus2).

do_topology_cross_sort([], _IPRegionList, _VersionList, Acc) ->
    Acc;
do_topology_cross_sort([CrossNode|R], IPRegionList, VersionList, Acc) ->
    #r_cross_topology_info{node_id = NodeID, public_ip = PublicIP} = CrossNode,
    case lists:keyfind(PublicIP, #r_ip_region.ip, IPRegionList) of
        #r_ip_region{region_id = RegionID} ->
            {_AgentID, ServerID} = node_misc:get_agent_server_id_by_node_id(NodeID),
            RegionID2 = get_region_version_id(VersionList, ServerID, RegionID),
            Acc2 =
                case lists:keytake(RegionID2, #r_cross_topology_region.region_id, Acc) of
                    {value, #r_cross_topology_region{cross_list = OldCrossList} = Group, AccT} ->
                        Group2 = Group#r_cross_topology_region{cross_list = [CrossNode|OldCrossList]},
                        [Group2|AccT];
                    _ ->
                        [#r_cross_topology_region{region_id = RegionID2, cross_list = [CrossNode]}|Acc]
                end,
            do_topology_cross_sort(R, IPRegionList, VersionList, Acc2);
        _ ->
            ?ERROR_MSG("找不到该公网IP对应的区域 : ~s", [PublicIP]),
            do_topology_cross_sort(R, IPRegionList, VersionList, Acc)
    end.

do_topology_game_sort([], _IPRegionList, _VersionList, Acc) ->
    Acc;
do_topology_game_sort([GameNode|R], IPRegionList, VersionList, Acc) ->
    #r_game_topology_info{node_id = NodeID, public_ip = PublicIP, open_days = OpenDays} = GameNode,
    {GroupID, MatchNum} = get_game_group_and_num(OpenDays),
    case lists:keyfind(PublicIP, #r_ip_region.ip, IPRegionList) of
        #r_ip_region{region_id = RegionID} ->
            {_AgentID, ServerID} = node_misc:get_agent_server_id_by_node_id(NodeID),
            RegionID2 = get_region_version_id(VersionList, ServerID, RegionID),
            Acc2 =
                case lists:keytake(RegionID2,  #r_game_topology_region.region_id, Acc) of
                    {value, #r_game_topology_region{game_group_list = OldGameGroupList} = Region, RegionAccT} ->
                        GameGroupList =
                            case lists:keytake(GroupID, #r_game_topology_group.group_id, OldGameGroupList) of
                                {value, #r_game_topology_group{game_list = OldGameList} = Group, OldGameGroupList2} ->
                                    GameList = [GameNode|OldGameList],
                                    [Group#r_game_topology_group{game_list = GameList}|OldGameGroupList2];
                                _ ->
                                    [#r_game_topology_group{group_id = GroupID, match_num = MatchNum, game_list = [GameNode]}|OldGameGroupList]
                            end,
                        [Region#r_game_topology_region{game_group_list = GameGroupList}|RegionAccT];
                    _ ->
                        GroupList = [#r_game_topology_group{group_id = GroupID, match_num = MatchNum, game_list = [GameNode]}],
                        [#r_game_topology_region{region_id = RegionID2, game_group_list = GroupList}|Acc]
                end,
            do_topology_game_sort(R, IPRegionList, VersionList, Acc2);
        _ ->
            ?ERROR_MSG("找不到该公网IP对应的区域 : ~s", [PublicIP]),
            do_topology_game_sort(R, IPRegionList, VersionList, Acc)
    end.

do_topology_match2([], _CrossRegionList) ->
    ok;
do_topology_match2(GameGroupList, []) ->
    ?ERROR_MSG("剩余区域没有对应的跨服服务器分组 : ~w", [GameGroupList]);
do_topology_match2([GameRegion|R], CrossRegionList) ->
    #r_game_topology_region{
        region_id = RegionID,
        game_group_list = GameGroupList
        } = GameRegion,
    case lists:keytake(RegionID, #r_cross_topology_region.region_id, CrossRegionList) of
        {value, #r_cross_topology_region{cross_list = CrossList}, CrossRegionList2} ->
            CrossNum = erlang:length(CrossList),
            {AllGameList, NeedServerNum, GameGroupList2} = get_game_group_args(GameGroupList),
            ?ERROR_MSG("NeedServerNum : ~w, CrossNum : ~w", [NeedServerNum, CrossNum]),
            ?ERROR_MSG("AllGameList : ~w", [AllGameList]),
            ?ERROR_MSG("CrossList : ~w", [CrossList]),
            if
                CrossNum >= NeedServerNum -> %% 服务器充足，搞起
                    do_topology_total_match(GameGroupList2, CrossList);
                true -> %% 不充足，按战力从低到高，先看看一组4个分配够不够服务器，不够再重新规划
                    do_topology_group_match(AllGameList, CrossNum, CrossList)
            end,
            do_topology_match2(R, CrossRegionList2);
        _ ->
            ?ERROR_MSG("游戏服区域 ID：~w 没有配置跨服节点", [RegionID]),
            do_topology_match2(R, CrossRegionList)
    end.

%% 按策划的分组分配
do_topology_total_match([], _CrossList) ->
    ok;
do_topology_total_match([#r_game_topology_group{server_num_list = ServerNumList, game_list = GameList}|R], CrossList) ->
    GameList2 = lists:keysort(#r_game_topology_info.power, GameList),
    CrossList2 = do_topology_game_cross_topology(ServerNumList, GameList2, CrossList),
    do_topology_total_match(R, CrossList2).


%% 跨服服务器不足
do_topology_group_match(AllGameList, CrossNum, CrossList) ->
    AllGameNum = erlang:length(AllGameList),
    ServerList = get_game_group_server_list(AllGameNum, 4),
    case CrossNum >= erlang:length(ServerList) of
        true ->
            do_topology_game_cross_topology(ServerList, AllGameList, CrossList);
        _ ->
            ServerList2 = get_game_group_server_list(AllGameNum, (AllGameNum div CrossNum) + 1),
            do_topology_game_cross_topology(ServerList2, AllGameList, CrossList)
    end.

do_topology_game_cross_topology([_ServerNum], GameList, [CrossInfo|CrossList]) ->
    do_topology_game_cross_topology2(GameList, CrossInfo),
    CrossList;
do_topology_game_cross_topology([ServerNum|R], GameList, [CrossInfo|CrossList]) ->
    {MatchGameList, GameList2} = lib_tool:split(ServerNum, GameList),
    do_topology_game_cross_topology2(MatchGameList, CrossInfo),
    do_topology_game_cross_topology(R, GameList2, CrossList).

do_topology_game_cross_topology2(GameList, CrossNodes) ->
    #r_cross_topology_info{
        node_id = CrossNodeID,
        ip = CrossIP
    } = CrossNodes,
    {_AgentID, ServerID} = node_misc:get_agent_server_id_by_node_id(CrossNodeID),
    {AllPower, GameNodeIDList}=
        lists:foldl(
            fun(GameInfo, {PowerAcc, GameNodeIDAcc}) ->
                #r_game_topology_info{node_id = GameNodeID, power = Power} = GameInfo,
                GameTopology = #r_game_topology{node_id = GameNodeID, cross_id = ServerID, cross_ip = CrossIP},
                set_game_topology(GameTopology),
                {PowerAcc + Power, [GameNodeID|GameNodeIDAcc]}
            end, {0, []}, GameList),
    CrossTopology = #r_cross_topology{node_id = CrossNodeID, power = AllPower, game_node_id_list = GameNodeIDList},
    set_cross_topology(CrossTopology).


%% 推送cross匹配信息
do_topology_push(Now, MatchStatus) ->
    #r_center_topology_status{next_status_time = NextStatusTime} = MatchStatus,
    case Now >= NextStatusTime of
        true ->
            do_all_game_topology_push(),
            del_match_status();
        _ ->
            ok
    end.

do_all_game_topology_push() ->
    #r_center_topology_args{last_match_time = LastMatchTime} = world_data:get_center_topology_args(),
    NextMatchTime = get_next_topology_start_time(LastMatchTime),
    [ do_game_topology_push(GameTopology, NextMatchTime) || GameTopology <- get_all_game_topology()].

do_game_topology_push(GameTopology, NextMatchTime) ->
    #r_game_topology{node_id = NodeID, cross_id = CrossID, cross_ip = CrossIP} = GameTopology,
    node_msg_manager:send_msg_by_node(node_misc:get_node_name_by_node_id(NodeID), game_topology_server, {center_send_cross, CrossID, CrossIP, NextMatchTime}).

do_game_get_cross_topology(NodeID, PublicIP, ServerPower) ->
    case get_match_status() of
        #r_center_topology_status{} -> %% 匹配中，不能获取
            ok;
        _ ->
            #r_center_topology_args{last_match_time = LastMatchTime} = world_data:get_center_topology_args(),
            NextMatchTime = get_next_topology_start_time(LastMatchTime),
            case get_game_topology(NodeID) of
                [GameTopology] ->
                    do_game_topology_push(GameTopology, NextMatchTime);
                _ ->
                    do_new_game_match(NodeID, PublicIP, ServerPower, NextMatchTime)
            end
    end.

%% 新服连接，进行匹配
do_new_game_match(NodeID, PublicIP, ServerPower, NextMatchTime) ->
    IPRegionList = get_web_ip_area_list(),
    case lists:keyfind(PublicIP, #r_ip_region.ip, IPRegionList) of
        #r_ip_region{region_id = RegionID} ->
            VersionList = get_version_list(),
            {_GameAgentID, GameServerID} = node_misc:get_agent_server_id_by_node_id(NodeID),
            RegionID2 = get_region_version_id(VersionList, GameServerID, RegionID),
            CrossNodeList =
                lists:foldl(
                    fun(ConnectNode, Acc) ->
                        #r_connect_node{node_id = CrossNodeID, ip = CrossIP, public_ip = CrossPublicIP} = ConnectNode,
                        case CrossNodeID =/= undefined andalso erlang:is_integer(CrossNodeID) andalso node_misc:is_cross_node_id(CrossNodeID) of
                            true ->
                                case lists:keyfind(PublicIP, #r_ip_region.ip, IPRegionList) of
                                    #r_ip_region{region_id = RegionID} ->
                                        {_CrossAgentID, CrossServerID} = node_misc:get_agent_server_id_by_node_id(CrossNodeID),
                                        ?IF(get_region_version_id(VersionList, CrossServerID, RegionID) =:= RegionID2,
                                            [#r_cross_topology_info{node_id = CrossNodeID, ip = CrossIP, public_ip = CrossPublicIP}|Acc],
                                            Acc);
                                    _ ->
                                        Acc
                                end;
                            _ ->
                                Acc
                        end
                    end, [], node_base:get_all_node()),
            case CrossNodeList =/= [] of
                true ->
                    case do_new_game_match2(NodeID, ServerPower, CrossNodeList) of
                        {ok, GameTopology, CrossTopology} ->
                            ?ERROR_MSG("new game topology:~w", [{GameTopology, CrossTopology}]),
                            set_game_topology(GameTopology),
                            set_cross_topology(CrossTopology),
                            do_game_topology_push(GameTopology, NextMatchTime);
                        _ ->
                            ?ERROR_MSG("找不到服务器 NodeID: ~w 公网IP: ~s 对应的的内网跨服", [NodeID, PublicIP]),
                            case common_config:is_debug() of
                                true ->
                                    GameTopology =
                                        case node_misc:get_agent_server_id_by_node_id(NodeID) of
                                            {_, ServerID} when 91 =< ServerID andalso ServerID =< 92 ->
                                                #r_game_topology{node_id = NodeID, cross_id = 90002, cross_ip = "127.0.0.1"};
                                            _ ->
                                                #r_game_topology{node_id = NodeID, cross_id = 90001, cross_ip = "127.0.0.1"}
                                        end,
                                    set_game_topology(GameTopology),
                                    do_game_topology_push(GameTopology, NextMatchTime);
                                _ ->
                                    ok
                            end
                    end;
                _ ->
                    ?ERROR_MSG("找不到服务器 NodeID: ~w 公网IP: ~s 对应的内网跨服", [NodeID, PublicIP])
            end;
        _ ->
            ?ERROR_MSG("找不到服务器 NodeID: ~w, 公网IP: ~s 的配置", [NodeID, PublicIP]),
            ok
    end.

do_new_game_match2(GameNodeID, ServerPower, CrossNodeList) ->
    AllCrossTopology = get_all_cross_topology(),
    {TopologyList, RemainList} =
    lists:foldl(
        fun(CrossNoe, {Acc1, Acc2}) ->
            #r_cross_topology_info{node_id = CrossNodeID} = CrossNoe,
            case lists:keyfind(CrossNodeID, #r_cross_topology.node_id, AllCrossTopology) of
                #r_cross_topology{} = CrossTopology ->
                    {[CrossTopology|Acc1], Acc2};
                _ ->
                    {Acc1, [CrossNoe|Acc2]}
            end
            end, {[], []}, CrossNodeList),
    case do_new_game_match3(ServerPower, TopologyList) of
        {ok, #r_cross_topology{node_id = CrossNodeID, game_node_id_list = GameNodeIDList} = CrossTopology} ->
            CrossTopology2 = CrossTopology#r_cross_topology{game_node_id_list = [GameNodeID|GameNodeIDList]},
            #r_cross_topology_info{ip = CrossIP} = lists:keyfind(CrossNodeID, #r_cross_topology_info.node_id, CrossNodeList),
            {_AgentID, CrossID} = node_misc:get_agent_server_id_by_node_id(CrossNodeID),
            GameTopology = #r_game_topology{node_id = GameNodeID, cross_id = CrossID, cross_ip = CrossIP},
            {ok, GameTopology, CrossTopology2};
        _ ->
            case RemainList of
                [#r_cross_topology_info{node_id = CrossNodeID, ip = CrossIP}|_] ->
                    CrossTopology2= #r_cross_topology{node_id = CrossNodeID, power = ServerPower, game_node_id_list = [GameNodeID]},
                    {_AgentID, CrossID} = node_misc:get_agent_server_id_by_node_id(CrossNodeID),
                    GameTopology = #r_game_topology{node_id = GameNodeID, cross_id = CrossID, cross_ip = CrossIP},
                    {ok, GameTopology, CrossTopology2};
                _ ->
                    false
            end
    end.

do_new_game_match3(ServerPower, TopologyList) ->
    ConfigLen = 3,
    TopologyList2 =
        lists:sort(
            fun(Topology1, Topology2) ->
                #r_cross_topology{power = Power1, game_node_id_list = GameNodeList1} = Topology1,
                #r_cross_topology{power = Power2, game_node_id_list = GameNodeList2} = Topology2,
                Len1 = erlang:length(GameNodeList1),
                Len2 = erlang:length(GameNodeList2),
                if
                    Len1 =< ConfigLen andalso Len2 =< ConfigLen -> %% 都OK的话，取战力相近
                        erlang:abs(ServerPower - Power1) < erlang:abs(ServerPower - Power2);
                    Len1 =< ConfigLen ->
                        true;
                    Len2 =< ConfigLen ->
                        false;
                    true ->
                        Len1 < Len2
                end
            end, TopologyList),
    case TopologyList2 of
        [#r_cross_topology{game_node_id_list = GameNodeList} = CrossTopology|_] when erlang:length(GameNodeList) =< 3 ->
            {ok, CrossTopology};
        _ ->
            false
    end.


do_reload_config() ->
    do_all_game_topology_push().

%% 游戏服推送数据过来
do_game_match_send_data(NodeID, PublicIP, OpenDays, ServerPower) ->
    #r_center_topology_status{game_list = GameList} = MatchStatus = get_match_status(),
    GameInfo = #r_game_topology_info{
        node_id = NodeID,
        public_ip = PublicIP,
        open_days = OpenDays,
        power = ServerPower},
    GameList2 = lists:keystore(NodeID, #r_game_topology_info.node_id, GameList, GameInfo),
    set_match_status(MatchStatus#r_center_topology_status{game_list = GameList2}).


get_next_diff_days(LastMatchTime, Now) ->
    [{CDDays, OpenWeekDay}] = lib_config:find(cfg_topology, topo_days),
    %% 已经结束了的话，时间要推迟一天
    WeekDay = time_tool:weekday(Now),
    DiffDays = time_tool:diff_date(Now, LastMatchTime),
    WeekDayDiffs = time_tool:get_diff_days_by_weekday(WeekDay, OpenWeekDay),
    Days =  DiffDays + WeekDayDiffs,
    case Days > CDDays of
        true ->
            case WeekDayDiffs =:= 0 of
                true -> %% 当天举行的话，要对比时间是不是超了
                    {_Date, {NowHour, NowMin, _NowSec}} = time_tool:timestamp_to_datetime(Now),
                    [{{_BeginHour, _BeginMin}, {EndHour, EndMin}}] = lib_config:find(cfg_topology, topo_time),
                    ?IF({NowHour, NowMin} >= {EndHour, EndMin}, WeekDayDiffs + 7, WeekDayDiffs);
                _ ->
                    WeekDayDiffs
            end;
        _ ->
            WeekDayDiffs + 7 * ((CDDays - Days) div 7 + 1)
    end.

get_next_topology_start_time() ->
    get_next_topology_start_time(time_tool:now()).
get_next_topology_start_time(LastMatchTime) ->
    Now = time_tool:now(),
    DiffDays = get_next_diff_days(LastMatchTime, Now),
    get_next_topology_start_time(time_tool:date(), DiffDays).
get_next_topology_start_time(Date, DiffDays) ->
    [{{BeginHour, BeginMin}, {_EndHour, _EndMin}}] = lib_config:find(cfg_topology, topo_time),
    time_tool:timestamp(Date) + DiffDays * ?ONE_DAY + BeginHour * ?AN_HOUR + BeginMin * ?ONE_MINUTE.

get_web_ip_area_list() ->
    Time = time_tool:now(),
    Ticket = web_misc:get_key(Time),
    URL = web_misc:get_web_url(topology_url),
    Body =
        [
            {ip, ""},
            {time, Time},
            {ticket, Ticket}
        ],
    case catch ibrowse:send_req(URL, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 2000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Obj2} = mochijson2:decode(Body2),
            {_, Status} = proplists:get_value(<<"status">>, Obj2),
            Code = lib_tool:to_integer(proplists:get_value(<<"code">>, Status)),
            case Code of
                10200 ->
                    case proplists:get_value(<<"data">>, Obj2) of
                        List when erlang:is_list(List) ->
                            get_web_ip_area_list2(List, []);
                        _ ->
                            []
                    end;
                _ ->
                    ?ERROR_MSG("Code : ~w", [Code]),
                    []
            end;
        Error ->
            ?ERROR_MSG("Error:~p", [Error]),
            []
    end.

get_web_ip_area_list2([], Acc) ->
    Acc;
get_web_ip_area_list2([{_, ValueList}|R], Acc) ->
    IP = lib_tool:to_list(proplists:get_value(<<"public_ip">>, ValueList)),
    RegionID = lib_tool:to_integer(proplists:get_value(<<"region_id">>, ValueList)),
    Acc2 = [#r_ip_region{ip = IP, region_id = RegionID}|Acc],
    get_web_ip_area_list2(R, Acc2).

get_version_list() ->
    case lib_config:find(cfg_topology, {center_topology_verion, common_config:get_agent_id()}) of
        [Config] ->
            Config;
        _ ->
            []
    end.

get_region_version_id([], _ServerID, RegionID) ->
    RegionID * ?TOPOLOGY_REGION_INDEX;
get_region_version_id([{MinServerID, MaxSeverID, Version}|R], ServerID, RegionID) ->
    case MinServerID =< ServerID andalso ServerID =< MaxSeverID of
        true ->
            RegionID * ?TOPOLOGY_REGION_INDEX + Version;
        _ ->
            get_region_version_id(R, ServerID, RegionID)
    end;
get_region_version_id([DisMatch|R], ServerID, RegionID) ->
    ?ERROR_MSG("DisMatch : ~w", [DisMatch]),
    get_region_version_id(R, ServerID, RegionID).

get_game_group_and_num(OpenDays) ->
    [List] = lib_config:find(cfg_topology, topp_groups),
    get_game_group_and_num2(List, OpenDays).

get_game_group_and_num2([{GroupID, MinDays, MaxDays, Num}|R], OpenDays) ->
    case MinDays =< OpenDays andalso OpenDays =< MaxDays of
        true ->
            {GroupID, Num};
        _ ->
            get_game_group_and_num2(R, OpenDays)
    end.

get_game_group_args(GameGroupList) ->
    GameGroupList2 = get_modify_game_group_list(lists:reverse(lists:keysort(#r_game_topology_group.group_id, GameGroupList)), []),
    {AllGameList, ServerNum, GameGroupList3} =
        lists:foldl(
            fun(#r_game_topology_group{match_num = MatchNum, game_list = GameList} = GameGroup, {Acc1, Acc2, Acc3}) ->
                ServerNumList = get_game_group_server_list(erlang:length(GameList), MatchNum),
                NeedNum = erlang:length(ServerNumList),
                GameGroup2 = GameGroup#r_game_topology_group{server_num_list = ServerNumList},
                {GameList ++ Acc1, Acc2 + NeedNum, [GameGroup2|Acc3]}
            end, {[], 0, []}, GameGroupList2),
    {AllGameList, ServerNum, GameGroupList3}.

get_modify_game_group_list([], Acc) ->
    Acc;
get_modify_game_group_list([GameGroup], Acc) ->
    [GameGroup|Acc];
get_modify_game_group_list([GameGroup1, GameGroup2|R], Acc) ->
    #r_game_topology_group{game_list = GameList} = GameGroup1,
    case erlang:length(GameList) > 1 of
        true ->
            get_modify_game_group_list([GameGroup2|R], [GameGroup1|Acc]);
        _ ->
            #r_game_topology_group{game_list = GameList2} = GameGroup2,
            NewGameGroup2 = GameGroup2#r_game_topology_group{game_list = GameList ++ GameList2},
            get_modify_game_group_list([NewGameGroup2|R], Acc)
    end.

%% 匹配的时候，低战力 -> 高战力组
get_game_group_server_list(GameNum, MatchNum) when GameNum =< MatchNum ->
    [GameNum];
get_game_group_server_list(GameNum, MatchNum) ->
    if
        MatchNum =:= 2 ->
            ?IF(GameNum rem 2 =:= 0, lists:duplicate(GameNum div 2, 2), [3|lists:duplicate((GameNum div 2 - 1), 2)]);
        MatchNum =:= 4 ->
            Value1 = GameNum div 4,
            Value2 = GameNum rem 4,
            if
                Value2 =:= 0 ->
                    lists:duplicate(Value1, 4);
                Value2 =:= 1 ->
                    [5|lists:duplicate(Value1 - 1, 4)];
                true ->
                    [Value2|lists:duplicate(Value1, 4)]
            end;
        true ->
            GroupNum = lib_tool:floor(GameNum/MatchNum + 0.99),
            Value1 = GameNum div GroupNum,
            Value2 = GameNum rem GroupNum,
            lists:duplicate(GroupNum - Value2, Value1) ++ lists:duplicate(Value2, Value1 + 1)
    end.

%%%===================================================================
%%% data
%%%===================================================================
get_match_status() ->
    erlang:get({?MODULE, match_status}).
set_match_status(MatchStatus) ->
    erlang:put({?MODULE, match_status}, MatchStatus).
del_match_status() ->
    erlang:erase({?MODULE, match_status}).

del_all_game_topology() ->
    db:delete_all(?DB_GAME_TOPOLOGY_P).
set_game_topology(GameTopology) ->
    db:insert(?DB_GAME_TOPOLOGY_P, GameTopology).
get_game_topology(NodeID) ->
    ets:lookup(?DB_GAME_TOPOLOGY_P, NodeID).
get_all_game_topology() ->
    db:table_all(?DB_GAME_TOPOLOGY_P).


del_all_cross_topology() ->
    db:delete_all(?DB_CROSS_TOPOLOGY_P).
set_cross_topology(CrossTopology) ->
    db:insert(?DB_CROSS_TOPOLOGY_P, CrossTopology).
get_cross_topology(NodeID) ->
    ets:lookup(?DB_CROSS_TOPOLOGY_P, NodeID).
get_all_cross_topology() ->
    db:table_all(?DB_CROSS_TOPOLOGY_P).

%%%-------------------------------------------------------------------
%%% @doc
%%%     获取一些通用配置
%%% @end

-module(common_config).

-include("common.hrl").
-include("platform.hrl").


%% 必须提供的函数列表 请勿修改
-export([
    get_common_config/0,        %% 获取common.config的配置
    is_debug/0,                 %% 是否测试环境
    is_gm_open/0,               %% 是否可以用GM命令的环境
    is_test_server/0,           %% 测试服
    is_center_node/0,           %% 是否中央服节点
    is_center_node/1,           %% 是否中央服节点
    is_center_id/1,             %% 是否中央服ID
    is_cross_node/0,            %% 当前节点是不是跨服节点
    is_cross_node/1,            %% 该节点是不是跨服节点
    is_cross_server_id/1,       %% 是否跨服服务器
    is_game_node/0,             %% 是否游戏服节点
    is_game_node/1,             %% 是否游戏服节点
    is_game_server_id/1,        %% 是否游戏服节点
    get_version/0,              %% 获取版本号
    get_open_time/0,            %% 获取开服时间
    get_open_days/0,            %% 获取当前开服天数
    get_open_days_by_time/1,    %% 获取此时间点开服天数
    is_open_7days/0,            %% 开服前7天
    get_agent_code/0,           %% 获取代理商代号 例如:tx
    get_agent_id/0,             %% 获取代理商id
    get_server_id/0,            %% 获取游戏服id
    get_server_name/0,          %% 获取当前服务器的名字
    get_server_type/0,          %% 根据server_id获取对应type
    get_game_code/0,            %% 获取游戏代号
    get_cookie/0,               %% 获取cookie
    is_merge/0,                 %% 是否已经合服
    get_merge_time/0,           %% 时间戳
    is_overseas/0,              %% 是否海外服
    get_server_root/0,          %% 获取游戏运行代码目录
    get_server_ip/0,            %% 获取服务器连接IP
    get_server_public_ip/0,     %% 获取服务器公网IP
    is_lite/0,                  %% 是否轻量级模式,即仅启动db
    get_web_port/0,             %% 获取mochiweb端口
    get_database_full_name/1    %% 获取数据库全名
]).

%% game 游戏服调用
-export([
    get_gateway_port/0,         %% 获取本节点网关端口
    get_center_server_id/0,     %% 游戏服 || 跨服 调用---获取中央服的server_id
    get_center_ip/0,            %% 游戏服 || 跨服---获取中央服的IP
    get_center_node/0,          %% 游戏服 || 跨服---获取中央服节点
    get_center_node/2           %% 游戏服 || 跨服---获取中央服节点
]).

%% =======================================================
%% 游戏服必须提供的函数
%% =======================================================
%% 支持2种文件类型: record_consult,key_value_consult
get_common_config() ->
    case init:get_argument(os) of
        {ok, [["windows"]]} ->
            "common_windows.config";
        _ ->
            "common.config"
    end.

is_debug() ->
    [Val] = lib_config:find(common, is_debug),
    Val.

is_gm_open() ->
    is_debug() andalso is_test_server().

is_test_server() ->
    AgentID = get_agent_id(),
    ServerID = get_server_id(),
    if
        AgentID =:= ?AGENT_LOCAL ->
            true;
        true ->
            69900 =< ServerID andalso ServerID =< 69999
    end.

is_center_node() ->
    is_cross_node(erlang:node()).
is_center_node(Node) ->
    is_center_id(get_node_server_id(Node)).

is_cross_node() ->
    is_cross_server_id(get_server_id()).
is_cross_node(Node) ->
    ServerID = get_node_server_id(Node),
    is_cross_server_id(ServerID).

is_game_node() ->
    is_game_server_id(get_server_id()).
is_game_node(Node) ->
    ServerID = get_node_server_id(Node),
    is_game_server_id(ServerID).

%% 1-89999为游戏服节点
%% 1-69900为正式服
%% 69900-69999 提审、测试用
%% 70000-89999为合服区间

%% 90000-99989位跨服节点 90000-99949为正式跨服节点  99950-99989为测试跨服节点
%% 99990-99999为中央服节点 99990位线上测试中央服节点 99999为正式中央服节点
is_game_server_id(ServerID) ->
    0 < ServerID andalso ServerID < 90000.
is_cross_server_id(ServerID) ->
    90000 =< ServerID andalso ServerID < 99990.
is_center_id(ServerID) ->
    99990 =< ServerID andalso ServerID =< 99999.

get_node_server_id(Node) ->
    case string:tokens(erlang:atom_to_list(Node), "@") of
        [List1, _List2] ->
            case string:tokens(List1, "_") of
                [_GameCode, _AgentCode, ServerID] ->
                    lib_tool:to_integer(ServerID);
                _ ->
                    0
            end;
        _ ->
            0
    end.

get_version() ->
    VersionInfo = get_server_root() ++ "/server_version.txt",
    case file:read_file(VersionInfo) of
        {ok, Version}->
            String = erlang:binary_to_list(Version),
            case string:tokens(String, "-") of
                [DataVersion, _SvnVersion] ->
                    lib_tool:to_integer(DataVersion);
                _ ->
                    not_found
            end;
        _->
            not_found
    end.

get_open_time() ->
    [String] = lib_config:find(common, server_start_time),
    time_tool:str_to_timestamp(String).

%% 获得当前为开服第几天,如果今天是6月28日,开服日期为6月28日,则今天为开服第一天,返回1
get_open_days() ->
    TimeStamp = get_open_time(),
    Date1 = time_tool:timestamp_to_date(TimeStamp),
    Date2 = time_tool:date(),
    OpenDays = time_tool:diff_date(Date2, Date1) + 1,
    case OpenDays < 1 of
        true ->
            1;
        false ->
            OpenDays
    end.

get_open_days_by_time(Time) ->
    TimeStamp = get_open_time(),
    Date1 = time_tool:timestamp_to_date(TimeStamp),
    Date2 = time_tool:timestamp_to_date(Time),
    OpenDays = time_tool:diff_date(Date2, Date1) + 1,
    case OpenDays < 1 of
        true ->
            1;
        false ->
            OpenDays
    end.


is_open_7days() ->
    get_open_days() =< 7.


%% 获取代理商名字
get_agent_code() ->
    [Val] = lib_config:find(common, agent_code),
    Val.
get_agent_id() ->
    [Val] = lib_config:find(common, agent_id),
    Val.

%% 获取游戏服ID%% 正式服区服相关设定
%% 1-89999为游戏服节点
%% 1-69900为正式服
%% 69900-69999 提审、测试用
%% 70000-89999为合服区间

%% 90000-99989位跨服节点 90000-99949为正式跨服节点  99950-99989为测试跨服节点
%% 99990-99999为中央服节点 99990为线上测试中央服节点 99999为正式中央服节点
get_server_id() ->
    [Val] = lib_config:find(common, server_id),
    Val.

get_server_name() ->
    [ServerName] = lib_config:find(common, server_name),
    ServerName.

get_server_type() ->
    Node = erlang:node(),
    case is_center_node(Node) of
        true ->
            ?NODE_TYPE_CENTER;
        _ ->
            case is_cross_node(Node) of
                true ->
                    ?NODE_TYPE_CROSS;
                _ ->
                    ?NODE_TYPE_GAME
            end
    end.

get_game_code() ->
    [GameCode] = lib_config:find(common, game_code),
    GameCode.

get_cookie() ->
    GameCode = get_game_code(),
    [Val] = lib_config:find(common, cookie_extend),
    lib_tool:list_to_atom(lists:concat([GameCode, "_", Val])).

%% 本服务器是否是合服后的服务器
is_merge() ->
    case lib_config:find(common, is_merge) of
        [IsMerge] when IsMerge > 0 ->
            true;
        _ ->
            false
    end.

%% 获取合服时间
get_merge_time() ->
    case lib_config:find(common, merge_time) of
        [MergeTime] ->
            MergeTime;
        _ ->
            undefined
    end.

%% 是否海外
is_overseas() ->
    case lib_config:find(common, is_overseas) of
        [1] ->
            true;
        _ ->
            false
    end.

%% @doc 获取节点运行的代码目录
%% 此参数在系统启动时由启动脚本决定
%% @end
get_server_root() ->
    {ok, [[ServerRoot]]} = init:get_argument(server_root),
    ServerRoot.

get_server_ip() ->
    [IP] = lib_config:find(common, server_ip),
    IP.

get_server_public_ip() ->
    [PublicIP] = lib_config:find(common, server_ip_public),
    PublicIP.

%% @doc
is_lite() ->
    case init:get_argument(lite) of
        {ok, _} ->
            true;
        _ ->
            false
    end.


get_web_port() ->
    [WebPort] = lib_config:find(common, web_port),
    WebPort.

get_gateway_port() ->
    [GatewayPort] = lib_config:find(common, gateway_port),
    GatewayPort.

get_center_server_id() ->
    case lib_config:find(common, center_id) of
        [CenterID] ->
            CenterID;
        _ ->
            99999
    end.

get_center_ip() ->
    case lib_config:find(common, center_ip) of
        [Value] ->
            Value;
        _ ->
            "127.0.0.1"
    end.

get_center_node() ->
    ServerID = get_center_server_id(),
    IP = get_center_ip(),
    get_center_node(ServerID, IP).

get_center_node(ServerID, IP) ->
    lib_tool:to_atom(lists:concat([get_game_code(), "_", "center", "_", ServerID, "@", IP])).

get_database_full_name(DataBase) ->
    AgentCode = get_agent_code(),
    ServerID = get_server_id(),
    lists:concat([DataBase, "_", AgentCode, "_",  ServerID]).

%%%-------------------------------------------------------------------
%%% @doc
%%%
%%% @end
%%% Created : 13. Mar 2015 22:02
%%%-------------------------------------------------------------------
-module(log_misc).


%% API
-export([
    get_log_level/0,
    get_log_dir/0,
    get_log_basename/0,
    get_mgr_log/0,
    get_log_header/1,
    get_log_file/3
]).

get_log_level() ->
    [LogLv] = lib_config:find(common,log_level),
    LogLv.

get_log_dir() ->
    [LogDir] = lib_config:find(common,log_dir),
    LogDir.

get_log_basename() ->
    AgentCode = common_config:get_agent_code(),
    ServerID  = common_config:get_server_id(),
    GameCode  = common_config:get_game_code(),
    lists:concat([GameCode,"_",AgentCode,"_",ServerID]).

%% @doc 生成日志文件名
get_mgr_log() ->
    io_lib:format("/data/logs/~s_manager_~s_~p.log", [common_config:get_game_code(),
        common_config:get_agent_code(),
        common_config:get_server_id()]).

get_log_header({{Y,Mo,D},{H,Mi,S}}) ->
    AgentCode = common_config:get_agent_code(),
    ServerID  = common_config:get_server_id(),
    io_lib:format("system_info ~p S~p ==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ===",
        [AgentCode, ServerID , Y, Mo, D, H, Mi, S]).

get_log_file(BaseDir, FileBaseName, IsMf) ->
    ok = filelib:ensure_dir(BaseDir),
    case IsMf of
        true ->
            {Year, Month, Day} = time_tool:date(),
            {io_lib:format("~s/~s_~p_~p_~p.log", [BaseDir, FileBaseName, Year, Month, Day]),
                io_lib:format("~s/crit_~s_~p_~p.log", [BaseDir, FileBaseName, Year, Month]),
                io_lib:format("~s/err_~s_~p_~p.log", [BaseDir, FileBaseName, Year, Month])};
        false ->
            {io_lib:format("~s/~s.log", [BaseDir, FileBaseName]),
                io_lib:format("~s/crit_~s.log", [BaseDir, FileBaseName]),
                io_lib:format("~s/err_~s.log", [BaseDir, FileBaseName])}
    end.

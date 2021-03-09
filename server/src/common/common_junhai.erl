%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2018 19:20
%%%-------------------------------------------------------------------
-module(common_junhai).
-author("laijichang").
-include("platform.hrl").
-include("global.hrl").

%% API
-export([
    pf_log/1,
    online_log/1
]).

-export([
    get_log_common/1
]).

pf_log(Logs) ->
    junhai_misc:log(Logs).

online_log(GameChannelList) ->
    CommonList = get_log_common(?JUNHAI_LOG_ONLINE),
    {{Y, M, D}, {HH, MM, _SS}} = erlang:localtime(),
    TimeValue = lists:flatten(io_lib:format("~w~2..0B~2..0B~2..0B~2..0B", [Y, M, D, HH, MM])),
    ServerID = common_config:get_server_id(),
    LogList =
        [ begin
              Agent = {agent, [{channel_id, ChannelID}, {game_channel_id, GameChannelID}]},
              OnlineList = [
                  {time_value, TimeValue},
                  {user_cnt, Num},
                  {server_id, ServerID},
                  {server_name, ""}
              ],
              Online = {online, OnlineList},
              #r_junhai_log{log = [Agent, Online] ++ CommonList}
          end || {GameChannelID, ChannelID, Num} <- GameChannelList],
    common_pf:pf_log(LogList).

get_log_common(EventType) ->
    IsTest = ?IF(common_config:is_debug() orelse common_config:is_test_server(), "test", "regular"),
    [GameID] = lib_config:find(cfg_junhai, game_id),
    GameList = [{game_id, GameID}, {game_ver, 1}],
    [
        {event, EventType},
        {data_ver, "1.3"},
        {server_ts, time_tool:now()},
        {is_test, IsTest},
        {game, GameList}
    ].
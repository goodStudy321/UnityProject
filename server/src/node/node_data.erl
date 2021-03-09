%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 八月 2019 17:01
%%%-------------------------------------------------------------------
-module(node_data).
-author("laijichang").
-include("node.hrl").

%% API
-export([
    set_merge_server/1,
    get_merge_server/2
]).

set_merge_server(#r_merge_server{} = MergeServer) ->
    ets:insert(?ETS_MERGE_SERVER, MergeServer).

get_merge_server(AgentID, ServerID) ->
    case ets:lookup(?ETS_MERGE_SERVER, {AgentID, ServerID}) of
        [#r_merge_server{} = MergeServer] ->
            MergeServer;
        _ ->
            undefined
    end.
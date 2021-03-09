%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     角色地图的其他协议处理
%%% @end
%%% Created : 27. 五月 2017 15:43
%%%-------------------------------------------------------------------
-module(mod_map_role_handle).
-author("laijichang").
-include("global.hrl").
-include("proto/mod_map_actor.hrl").

%% API
-export([
    handle/1
]).

handle(Info) ->
    ?ERROR_MSG("unknow info : ~w", [Info]).

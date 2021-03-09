-module(server_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    server_sup:start_link(),
    Pres = get_config(pre_starts),
    Mods = get_config(starts),
    start_mods(Pres),
    start_mods(Mods).

stop(_State) ->
    ok.

start_mods(Mods) ->
    lists:foreach(
        fun ({M, F, A}) ->
            erlang:apply(M, F, A);
            (Mod) ->
                Mod:start()
        end, Mods).

get_config(Key) ->
    case lib_config:find(cfg_server, Key) of
        [List] -> List;
        _ -> []
    end.
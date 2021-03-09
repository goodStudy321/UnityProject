
%% Copyright (c) jg_513@163.com, https://github.com/jg513

-module(enif_protobuf).

-export([
    start/0,
    set_opts/1,
    load_cache/1,
    purge_cache/0,
    encode/1,
    encode_msg/2,
    decode/2,
    decode_msg/3,
    debug_term/1
]).

-define(NOT_LOADED, not_loaded(?LINE)).

-compile([no_native]).

-on_load(init/0).

init() ->
    Path = common_config:get_server_root() ++ "ebin/enif_protobuf",
    Processors = erlang:system_info(logical_processors),
    ok = erlang:load_nif(Path, Processors).

not_loaded(Line) ->
    erlang:nif_error({not_loaded, [{module, ?MODULE}, {line, Line}]}).

start() ->
    ok = enif_protobuf:load_cache(proto:get_msg_defs()),
    enif_protobuf:set_opts([{string_as_list, true}]).

set_opts(_Opts) ->
    ?NOT_LOADED.

load_cache(_List) ->
    ?NOT_LOADED.

purge_cache() ->
    ?NOT_LOADED.

encode(_Tuple) ->
    ?NOT_LOADED.

decode(_Binary, _Name) ->
    ?NOT_LOADED.

debug_term(_Term) ->
    ?NOT_LOADED.

encode_msg(Msg, Defs) ->
    ok = load_cache(Defs),
    encode(Msg).

decode_msg(Bin, Name, Defs) ->
    ok = load_cache(Defs),
    decode(Bin, Name).

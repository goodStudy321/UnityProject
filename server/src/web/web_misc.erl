%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 三月 2018 15:08
%%%-------------------------------------------------------------------
-module(web_misc).
-author("laijichang").
-include("web.hrl").
-include("common.hrl").

-export([
    get_web_port/0,
    auth_req/1,
    get_record_fields/1,
    get_func/2]).

-export([
    call_role/2,
    call_role/3,
    call_role/4
]).

-export([
    get_key/1,
    get_web_url/1
]).

%% @doc get web port
-spec get_web_port() -> Res when
    Res :: [pos_integer()] | [].
get_web_port() ->
    case lib_config:find(common, web_port) of
        [WebPort] ->
            WebPort;
        _ ->
            ?WEB_DEFAULT_PORT
    end.

%% @doc get handle_module for path
-spec handle_module(Path) -> Res when
    Path :: string(),
    Res :: atom().
%%handle_module("crossdomain.xml")->
%%    mweb_crossdomain_service;
%%handle_module("tx/pay")->
%%    mweb_txpay_service;
%%handle_module("account/" ++ _RemainPath)->
%%    mweb_account_service;
%%handle_module("api/" ++ _RemainPath)->
%%    mweb_api_service;
%%handle_module("data/" ++ _RemainPath)->
%%    mweb_data_service;
%%handle_module("nodes/" ++ _RemainPath)->
%%    mweb_game_service;
%%handle_module("baseinfo/" ++ _RemainPath)->
%%    mweb_game_service;
%%handle_module("mod_proto_ban_service/" ++ _RemainPath)->
%%    mweb_proto_ban_service;
%%handle_module("test/" ++ _RemainPath)->
%%    mweb_test_service;
handle_module(_Path) ->
    undefined.

%% @doc auth the http request
-spec auth_req(_Req) -> Res when
    Res :: ok | {error, any()}.
auth_req(Req) ->
    Method = Req:get(method),
    Params =
        case Method of
            'GET' -> Req:parse_qs();
            'POST' -> Req:parse_post()
        end,
    auth_req_normal(Params).


auth_req_normal(Params) ->
    case proplists:get_value("ticket", Params) of
        undefined ->
            {error, no_ticket};
        Ticket ->
            case Ticket =:= ?WEB_SUPER_KEY of
                true ->
                    ok;
                _ ->
                    case proplists:get_value("time", Params) of
                        undefined ->
                            {error, no_time};
                        Time ->
                            case string:to_lower(get_key(Time)) =:= string:to_lower(Ticket) of
                                true ->
                                    ok;
                                _ ->
                                    ?ERROR_MSG("web request err, time out:~w; now time:~w; Ticket:~w", [Time, time_tool:now(), Ticket]),
                                    {error, timeout}
                            end
                    end
            end
    end.

get_func([], Req)->
    case Req:get(method) of
        'GET'  ->
            ReqString = Req:parse_qs();
        'POST' ->
            ReqString = Req:parse_post()
    end,
    Action = proplists:get_value("action", ReqString),
    action_module(Action, Req);
get_func(Path, Req)->
    case handle_module(Path) of
        undefined->
            undefined;
        Module->
            case Req:get(method) of
                'GET'  -> {Module, get, [Path,Req]};
                'POST' -> {Module, post, [Path,Req]}
            end
    end.

action_module(Action, Req) ->
    case lib_config:find(cfg_web, Action) of
        [{Mod, Func}] ->
            {Mod, Func, [Req]};
        _ ->
            undefined
    end.

%% @doc get record fields for RecordName,refer to gen_record_info.es
-spec get_record_fields(RecordName) -> Res when
    RecordName :: atom(),
    Res :: list().
get_record_fields(RecordName) ->
    record_info:fields(RecordName).

call_role(RoleArg, Request) ->
    call_role(RoleArg, Request, ?CALL_TIMETOUT).
call_role(RoleArg, Request, TimeOut) ->
    case role_misc:get_role_pid(RoleArg) of
        {ok, RolePID} ->
            Request2 =
                case erlang:is_function(Request) of
                    true ->
                        {func, Request};
                    _ ->
                        Request
                end,
            pname_server:call(RolePID, Request2, TimeOut);
        _ ->
            {error, not_exist}
    end.
call_role(RoleArg, M, F, A) when erlang:is_list(A) ->
    call_role(RoleArg, {func, M, F, A}).

get_key(Time) ->
    lib_tool:md5(lists:concat([Time, ?WEB_AUTH_KEY])).

get_web_url(Key) ->
    [API] = lib_config:find(cfg_web, Key),
    [WebURL] = lib_config:find(common, web_url),
    WebURL ++ API.
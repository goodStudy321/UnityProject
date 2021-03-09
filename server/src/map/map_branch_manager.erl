%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 十一月 2017 16:18
%%%-------------------------------------------------------------------
-module(map_branch_manager).
-author("laijichang").
-include("global.hrl").
-include("cross.hrl").
-include("proto/mod_role_map.hrl").

-behaviour(gen_server).

%% API
-export([
    i/0,
    start_link/0,
    start/0
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
    info/1,
    get_map_cur_extra_id/1,
    get_cross_extra_id/1,
    is_branch_map/1,
    check_map_extra/2
]).

-export([
    set_map_branch/1,
    get_map_branch/1,
    get_map_all_extra_id/1
]).

start() ->
    map_sup:start_child(?MODULE, get_mod_name()).

start_link() ->
    ModName = get_mod_name(),
    gen_server:start_link({local, ModName}, ?MODULE, [], []).


i()->
    ets:tab2list(?ETS_MAP_BRANCH).

info(Info) ->
    pname_server:send(get_mod_name(), Info).

get_map_cur_extra_id(MapID) ->
    case get_map_branch(MapID) of
        [#r_map_branch{cur_extra_id = CurExtraID}] ->
            CurExtraID;
        _ ->
            ?DEFAULT_EXTRA_ID
    end.

get_map_all_extra_id(MapID) ->
    case get_map_branch(MapID) of
        [#r_map_branch{extra_list = ExtraList}] ->
            [ ExtraID || #r_map_extra{extra_id = ExtraID} <- ExtraList];
        _ ->
            []
    end.

check_map_extra(MapID, ExtraID) ->
    case get_map_branch(MapID) of
        [#r_map_branch{extra_list = ExtraList}] ->
            case lists:keyfind(ExtraID, #r_map_extra.extra_id, ExtraList) of
                #r_map_extra{role_num = RoleNum} ->
                    ?IF(RoleNum >= map_branch_worker:get_max_role_num(MapID), ?THROW_ERR(?ERROR_PRE_ENTER_028), ok);
                _ ->
                    ?THROW_ERR(?ERROR_PRE_ENTER_027)
            end;
        _ ->
            false
    end.

get_cross_extra_id(MapID) ->
    case catch pname_server:call(?CROSS_MAP_BRANCH_MANAGER, {get_cross_extra_id, MapID}) of
        {ok, ExtraID} ->
            ExtraID;
        _ ->
            ?DEFAULT_EXTRA_ID
    end.

is_branch_map(MapArgs) ->
    #c_map_base{map_type = MapType, is_cross_map = IsCrossMap} = Config = map_misc:get_map_base(MapArgs),
    MapType =:= ?MAP_TYPE_NORMAL andalso not (common_config:is_cross_node() xor ?IS_CROSS_MAP(IsCrossMap)) andalso not map_misc:is_condition_map(Config).

get_mod_name() ->
    ?IF(common_config:is_cross_node(), ?CROSS_MAP_BRANCH_MANAGER, ?MODULE).
%%%===================================================================
%%% API
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    lib_tool:init_ets(?ETS_MAP_BRANCH, #r_map_branch.map_id),
    ?IF(common_config:is_cross_node(), pname_server:reg(?CROSS_MAP_BRANCH_MANAGER, erlang:self()), ok),
    init_workers(),
    {ok, []}.

handle_call(Request, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Request,State),
    {reply, Reply, State}.

handle_cast(Request, State) ->
    ?DO_HANDLE_INFO(Request, State),
    {noreply, State}.

handle_info(exit, State) ->
    {stop, bad, State};
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ?IF(common_config:is_cross_node(), pname_server:dereg(?CROSS_MAP_BRANCH_MANAGER), ok),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

init_workers() ->
    [ map_branch_worker:start_link(MapID) || {MapID, Config} <- cfg_map_base:list(), is_branch_map(Config)].

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({mod,Mod,Info})->
    Mod:handle(Info);
do_handle({func,Fun})->
    Fun();
do_handle({func,M,F,A})->
    erlang:apply(M,F,A);
do_handle({get_cross_extra_id, MapID}) ->
    do_get_cross_extra_id(MapID);
do_handle(Info)->
    ?INFO_MSG("Unknow Message ~w",[Info]).

do_get_cross_extra_id(MapID) ->
    case get_map_branch(MapID) of
        [#r_map_branch{cur_extra_id = CurExtraID}] ->
            {ok, CurExtraID};
        _ ->
            not_found
    end.

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_map_branch(BranchInfo) ->
    ets:insert(?ETS_MAP_BRANCH, BranchInfo).
get_map_branch(MapID) ->
    ets:lookup(?ETS_MAP_BRANCH, MapID).
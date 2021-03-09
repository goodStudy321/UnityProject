%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     map server
%%% @end
%%% Created : 21. 四月 2017 15:00
%%%-------------------------------------------------------------------
-module(map_monster_server).

-behaviour(gen_server).
-include("global.hrl").

%% API
-export([
    i/1,
    i/2,
    monster_i/2,
    monster_i/3,
    key_i/2,
    key_i/3,
    start_link/4
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-export([
    is_immortal_map/0
]).

-define(SERVER, ?MODULE).
-record(state, {}).

i(MapID) ->
    pname_server:call(get_name(map_misc:get_map_pname(MapID, map_branch_manager:get_map_cur_extra_id(MapID))), i).
i(MapID, ExtraID) ->
    pname_server:call(get_name(map_misc:get_map_pname(MapID, ExtraID)), i).

monster_i(MapID, MonsterID) ->
    pname_server:call(get_name(map_misc:get_map_pname(MapID, map_branch_manager:get_map_cur_extra_id(MapID))), {monster_i, MonsterID}).
monster_i(MapID, ExtraID, MonsterID) ->
    pname_server:call(get_name(map_misc:get_map_pname(MapID, ExtraID)), {monster_i, MonsterID}).

key_i(MapID, Key) ->
    pname_server:call(get_name(map_misc:get_map_pname(MapID, map_branch_manager:get_map_cur_extra_id(MapID))), {key_i, Key}).
key_i(MapID, ExtraID, Key) ->
    pname_server:call(get_name(map_misc:get_map_pname(MapID, ExtraID)), {key_i, Key}).

start_link(MapID, MapPName, MapPID, ExtraID) ->
    Name = get_name(MapPName),
    gen_server:start_link({local, Name}, ?MODULE, [MapID, MapPName, MapPID, ExtraID], []).

get_name(MapPName) ->
    lib_tool:list_to_atom(lists:concat([lib_tool:to_list(MapPName), "_monster"])).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([MapID, MapPName, MapPID, ExtraID]) ->
    erlang:process_flag(trap_exit, true),
    time_tool:reg(map, [100, 1000]),
    map_common_dict:init(MapID, MapPName, MapPID, ExtraID),
    mod_monster_data:init(MapID),
    mod_monster:init(MapID),
    hook_monster:init_act_drop(MapID),
    set_is_td_map(?IS_MAP_FAMILY_TD(MapID)),
    set_is_immortal_map(copy_data:is_immortal_map(MapID)),
    {ok, #state{}}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info({'EXIT', PID, _Reason}, State) ->
    ?INFO_MSG("map monster server receive exit msg from ~p, resaon: ~p", [PID, _Reason]),
    case map_common_dict:get_map_pid() =:= PID of
        true ->
            {stop, normal, State};
        false ->
            {noreply, State}
    end;
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    time_tool:dereg(map, [100, 1000]),
    catch world_act_server:info({monster_server_close, map_common_dict:get_map_id(), erlang:self()}),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%% 怪物每帧的循环
do_handle({loop_msec, NowMS}) ->
    time_tool:now_ms_cached(NowMS),
    ?IF(catch mod_map_ets:get_in_map_roles() =/= [] orelse is_td_map(), mod_monster:loop_ms(NowMS), ok);
do_handle({guide_loop_msec, NowMS}) ->
    mod_monster:loop_ms(NowMS);
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    do_loop(Now);
%%对指定的模块发送消息,通用,建议使用
do_handle({drop, ActID, Status}) ->
    hook_monster:drop_act_change(ActID, Status);
do_handle({mod, Module, Info}) ->
    Module:handle(Info);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(i) ->
    do_i();
do_handle({monster_i, MonsterID}) ->
    do_monster_i(MonsterID);
do_handle({key_i, Key}) ->
    do_key_i(Key);
do_handle(_Request) ->
    ?ERROR_MSG("Unknow msg:~p", [_Request]).


do_i() ->
    {dictionary, List} = erlang:process_info(self(), dictionary),
    lists:foldl(
        fun(Dict, Acc) ->
            case Dict of
                {{_, slice, _}, _} ->
                    Acc;
                _ ->
                    [Dict | Acc]
            end
        end, [], lists:sort(List)).

do_loop(Now) ->
    mod_monster_world_boss:loop(Now),
    mod_monster_buff:loop(Now),
    mod_monster_silver:loop(Now).

do_monster_i(MonsterID) ->
    mod_monster_data:get_monster_data(MonsterID).

do_key_i(Key) ->
    erlang:get(Key).

is_td_map() ->
    erlang:get({?MODULE, is_td_map}).
set_is_td_map(Bool) ->
    erlang:put({?MODULE, is_td_map}, Bool).

is_immortal_map() ->
    erlang:get({?MODULE, is_immortal_map}).
set_is_immortal_map(Bool) ->
    erlang:put({?MODULE, is_immortal_map}, Bool).




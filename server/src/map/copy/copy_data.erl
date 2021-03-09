%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 六月 2017 20:02
%%%-------------------------------------------------------------------
-module(copy_data).
-author("laijichang").
-include("global.hrl").
-include("copy.hrl").

-export([
    is_copy_exp_map/1,
    is_single_td_map/1,
    is_immortal_map/1
]).

%% API
-export([
    get_success_info/2,
    get_copy_mod/1,
    set_copy_do/0,
    get_copy_do/0,
    erase_copy_do/0,
    set_copy_info/1,
    get_copy_info/0,
    cancel_start_ref/0,
    set_start_ref/1,
    cancel_shutdown_ref/0,
    set_shutdown_ref/1,
    get_copy_role/1,
    set_copy_role/2
]).

is_copy_exp_map(MapID) ->
    case lib_config:find(cfg_copy, MapID) of
        [#c_copy{copy_type = CopyType}] ->
            CopyType =:= ?COPY_EXP;
        _ ->
            false
    end.

is_single_td_map(MapID) ->
    case lib_config:find(cfg_copy, MapID) of
        [#c_copy{copy_type = CopyType}] ->
            CopyType =:= ?COPY_SINGLE_TD;
        _ ->
            false
    end.

is_immortal_map(MapID) ->
    case lib_config:find(cfg_copy, MapID) of
        [#c_copy{copy_type = CopyType}] ->
            CopyType =:= ?COPY_IMMORTAL;
        _ ->
            false
    end.

get_success_info(SuccessType, SuccessArgs) ->
    if
        SuccessType =:= ?SUCCESS_FRONT ->
            {SuccessType, 0};
        SuccessType =:= ?SUCCESS_MONSTER ->
            [MonsterType, Num] = SuccessArgs,
            {SuccessType, {lib_tool:to_integer(MonsterType), lib_tool:to_integer(Num)}};
        SuccessType =:= ?SUCCESS_WAVE ->
            [WaveNum] = SuccessArgs,
            {SuccessType, WaveNum};
        SuccessType =:= ?SUCCESS_TIME ->
            [WaveTime] = SuccessArgs,
            {SuccessType, WaveTime};
        SuccessType =:= ?SUCCESS_DEFENCE ->
            [TypeID] = SuccessArgs,
            {SuccessType, TypeID}
    end.

get_copy_mod(CopyType) ->
    case lists:keyfind(CopyType, 1, ?COPY_MOD_LIST) of
        {_, CopyMod} ->
            CopyMod;
        _ ->
            undefined
    end.

set_copy_do() ->
    erlang:put({?MODULE, copy_do}, true).
get_copy_do() ->
    erlang:get({?MODULE, copy_do}).
erase_copy_do() ->
    erlang:erase({?MODULE, copy_do}).

set_copy_info(CopyInfo) ->
    erlang:put({?MODULE, copy_info}, CopyInfo).
get_copy_info() ->
    erlang:get({?MODULE, copy_info}).

cancel_start_ref() ->
    case get_start_ref() of
        Ref when erlang:is_reference(Ref) ->
            erlang:cancel_timer(Ref),
            set_start_ref(undefined),
            true;
        _ ->
            false
    end.
set_start_ref(Ref) ->
    erlang:put({?MODULE, start_ref}, Ref).
get_start_ref() ->
    erlang:get({?MODULE, start_ref}).


cancel_shutdown_ref() ->
    case get_shutdown_ref() of
        Ref when erlang:is_reference(Ref) ->
            erlang:cancel_timer(Ref),
            set_shutdown_ref(undefined);
        _ ->
            ok
    end.
set_shutdown_ref(Ref) ->
    erlang:put({?MODULE, shutdown_ref}, Ref).
get_shutdown_ref() ->
    erlang:get({?MODULE, shutdown_ref}).

get_copy_role(RoleID) ->
    case erlang:get({?MODULE, copy_role, RoleID}) of
        #r_copy_role{} = CopyRole ->
            CopyRole;
        _ ->
            #r_copy_role{role_id = RoleID}
    end.
set_copy_role(RoleID, CopyRole) ->
    erlang:put({?MODULE, copy_role, RoleID}, CopyRole).
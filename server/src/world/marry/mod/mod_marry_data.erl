%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 十二月 2018 11:57
%%%-------------------------------------------------------------------
-module(mod_marry_data).
-author("laijichang").
-include("marry.hrl").
-include("global.hrl").

%% API
-export([
    init/0
]).

-export([
    add_loop_propose/1,
    del_loop_propose/1,
    get_loop_propose/0,
    set_loop_propose/1,

    get_feast_state/0,
    set_feast_state/1
]).

-export([
    get_all_marry_data/0,
    set_marry_data/1,
    get_marry_data/1,
    del_marry_data/1,
    get_all_share_marry/0,
    set_share_marry/1,
    get_share_marry/1,
    del_share_marry/1
]).

init() ->
    mod_marry_propose:init(),
    mod_marry_feast:init().

%%%===================================================================
%%% marry_server dict
%%%===================================================================
add_loop_propose(RoleID) ->
    set_loop_propose([RoleID|get_loop_propose()]).
del_loop_propose(RoleID) ->
    set_loop_propose(lists:delete(RoleID, get_loop_propose())).
get_loop_propose() ->
    erlang:get({?MODULE, loop_propose}).
set_loop_propose(List) ->
    erlang:put({?MODULE, loop_propose}, List).

get_feast_state() ->
    case erlang:get({?MODULE, feast_state}) of
        #r_feast_state{} = FeastState ->
            FeastState;
        _ ->
            #r_feast_state{}
    end.
set_feast_state(FeastState) ->
    erlang:put({?MODULE, feast_state}, FeastState).

%%%===================================================================
%%% ets
%%%===================================================================
get_all_marry_data() ->
    ets:tab2list(?DB_MARRY_DATA_P).
set_marry_data(MarryData) ->
    db:insert(?DB_MARRY_DATA_P, MarryData).
get_marry_data(RoleID) ->
    case ets:lookup(?DB_MARRY_DATA_P, RoleID) of
        [MarryData] ->
            MarryData;
        _ ->
            #r_marry_data{role_id = RoleID}
    end.
del_marry_data(RoleID) ->
    db:delete(?DB_MARRY_DATA_P, RoleID).

get_all_share_marry() ->
    ets:tab2list(?DB_SHARE_MARRY_P).
set_share_marry(ShareMarry) ->
    db:insert(?DB_SHARE_MARRY_P, ShareMarry).
get_share_marry(ShareID) ->
    case ets:lookup(?DB_SHARE_MARRY_P, ShareID) of
        [ShareMarry] ->
            ShareMarry;
        _ ->
            #r_marry_share{share_id = ShareID}
    end.
del_share_marry(ShareID) ->
    db:delete(?DB_SHARE_MARRY_P, ShareID).


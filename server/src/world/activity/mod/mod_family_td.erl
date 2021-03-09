%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 三月 2018 14:31
%%%-------------------------------------------------------------------
-module(mod_family_td).
-author("laijichang").
-include("global.hrl").
-include("activity.hrl").
-include("family_td.hrl").
-include("proto/world_activity_server.hrl").

%% API
-export([
    init/0,
    activity_start/0,
    activity_end/0,
    handle/1
]).

-export([
    is_activity_open/0,
    get_activity/0,
    get_family_td/1
]).

-export([
    start_family_td/1,
    map_end/1
]).

init() ->
    lib_tool:init_ets(?ETS_FAMILY_TD, #r_family_td.family_id),
    lib_tool:init_ets(?ETS_FAMILY_TD_REWARD, #p_kv.id).

activity_start() ->
    ets:delete_all_objects(?ETS_FAMILY_TD),
    ets:delete_all_objects(?ETS_FAMILY_TD_REWARD).

activity_end() ->
    [mod_map_family_td:activity_end(FamilyID) || #r_family_td{family_id = FamilyID} <- ets:tab2list(?ETS_FAMILY_TD)].

start_family_td(FamilyID) ->
    world_activity_server:call_mod(?MODULE, {start_family_td, FamilyID}).

map_end(FamilyID) ->
    world_activity_server:info_mod(?MODULE, {map_end, FamilyID}).

handle({start_family_td, FamilyID}) ->
    do_start_family_td(FamilyID);
handle({family_member_leave, FamilyID, RoleID}) ->
    do_family_member_leave(FamilyID, RoleID);
handle({map_end, FamilyID}) ->
    do_map_end(FamilyID);
handle(Info) ->
    ?ERROR_MSG("Info : ~w", [Info]).

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_start_family_td(FamilyID) ->
    #r_family_td{is_map_open = IsOpen} = FamilyTD = get_family_td(FamilyID),
    case IsOpen of
        false ->
            map_sup:start_map(?MAP_FAMILY_TD, FamilyID),
            set_family_td(FamilyTD#r_family_td{is_map_open = true});
        _ ->
            ok
    end.


do_family_member_leave(FamilyID, RoleID) ->
    PName = map_misc:get_map_pname(?MAP_FAMILY_TD, FamilyID),
    pname_server:send(PName, {family_member_leave, RoleID}).


do_map_end(FamilyID) ->
    FamilyTD = get_family_td(FamilyID),
    set_family_td(FamilyTD#r_family_td{is_end = true}),
    DataRecord = #m_activity_info_toc{activity_list = [#p_activity{id = ?ACTIVITY_FAMILY_TD, status = ?STATUS_CLOSE}]},
    common_broadcast:bc_record_to_family(FamilyID, DataRecord).

%%%===================================================================
%%% dict
%%%===================================================================
is_activity_open() ->
    #r_activity{status = Status} = get_activity(),
    Status =:= ?STATUS_OPEN.

get_activity() ->
    world_activity_server:get_activity(?ACTIVITY_FAMILY_TD).

set_family_td(FamilyTD) ->
    ets:insert(?ETS_FAMILY_TD, FamilyTD).
get_family_td(FamilyID) ->
    case ets:lookup(?ETS_FAMILY_TD, FamilyID) of
        [#r_family_td{} = FamilyTD] ->
            FamilyTD;
        _ ->
            #r_family_td{family_id = FamilyID}
    end.
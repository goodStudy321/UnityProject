%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 九月 2017 17:32
%%%-------------------------------------------------------------------
-module(copy_misc).
-author("laijichang").
-include("copy.hrl").
-include("global.hrl").

%% API
-export([
    get_pos_list/1,
    get_pos/1,
    get_average_level/0,
    get_copy_type/1,
    get_copy_min_level/1,
    is_copy_marry/1,
    is_copy_five_elements/1,
    is_copy_relive/1,
    get_map_list_bg_copy_type/1
]).

%% 获取刷怪的
get_pos_list(PosString) ->
    [begin
         [Mx, My] = string:tokens(String, ","),
         {lib_tool:to_integer(Mx), lib_tool:to_integer(My)}
     end || String <- string:tokens(PosString, ";")].

get_pos(BornPosList) ->
    [{MinMx, MinMy}, {MaxMx, MaxMy}] = BornPosList,
    map_misc:get_seq_born_pos([MinMx, MinMy], [MaxMx, MaxMy]).

get_average_level() ->
    Roles = mod_map_ets:get_in_map_roles(),
    case Roles =/= [] of
        true ->
            LevelList =
                [ begin
                      #r_map_actor{role_extra = #p_map_role{level = Level}} = mod_map_ets:get_actor_mapinfo(RoleID),
                      Level
                  end || RoleID <- Roles],
            lib_tool:floor(lists:sum(LevelList) / erlang:length(Roles));
        _ ->
            1
    end.

get_copy_type(CopyID) ->
    case lib_config:find(cfg_copy, CopyID) of
        [#c_copy{copy_type = CopyType}] ->
            CopyType;
        _ ->
            ?ERROR_MSG("unknow CopyID : ~w", [CopyID]),
            0
    end.


get_map_list_bg_copy_type(Type) ->
     [MapID || {_, #c_copy{map_id = MapID, copy_type = CopyType}} <- lib_config:list(cfg_copy) , Type =:= CopyType].


get_copy_min_level(CopyID) ->
    case lib_config:find(cfg_copy, CopyID) of
        [#c_copy{enter_level = MinLevel}] ->
            MinLevel;
        _ ->
            1
    end.

is_copy_marry(MapID) ->
    case lib_config:find(cfg_copy, MapID) of
        [#c_copy{copy_type = CopyType}] ->
            CopyType =:= ?COPY_MARRY;
        _ ->
            false
    end.

is_copy_five_elements(MapID) ->
    case lib_config:find(cfg_copy, MapID) of
        [#c_copy{copy_type = CopyType}] ->
            CopyType =:= ?COPY_FIVE_ELEMENTS;
        _ ->
            false
    end.

is_copy_relive(_CopyID) ->
    false.
%%    case map_misc:is_copy(CopyID) andalso not map_misc:is_copy_front(CopyID) of
%%        true ->
%%            case lib_config:find(cfg_copy_relive, {get_copy_type(CopyID), 1}) of
%%                [_Config] ->
%%                    true;
%%                _ ->
%%                    false
%%            end;
%%        _ ->
%%            false
%%    end.
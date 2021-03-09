%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     副本双倍活动
%%% @end
%%% Created : 16. 七月 2018 10:58
%%%-------------------------------------------------------------------
-module(act_double_copy).
-author("laijichang").
-include("copy.hrl").
-include("act.hrl").
-include("global.hrl").

%% API
-export([
    reload/0
]).

-export([
    get_drop_multi/1,
    get_drop_multi_by_type/1
]).

reload() ->
    #r_act{status = Status, start_time = StartTime} = world_act_server:get_act(?ACT_DOUBLE_COPY),
    case Status of
        ?ACT_STATUS_OPEN ->
            Days = time_tool:diff_date(time_tool:now(), StartTime) + 1,
            case lib_config:find(cfg_act_double_copy, Days) of
                [#c_act_double_copy{copy_type_list = TypeList, multi = Multi}] ->
                    List = [#p_kv{id = CopyType, val = erlang:max(Multi, 1)} || CopyType <- TypeList],
                    world_data:set_double_copy(List);
                _ ->
                    world_data:set_double_copy([])
            end;
        _ ->
            world_data:set_double_copy([])
    end.

get_drop_multi(MapID) ->
    case lib_config:find(cfg_copy, MapID) of
        [#c_copy{copy_type = CopyType}] ->
            get_drop_multi_by_type(CopyType);
        _ ->
            1
    end.

get_drop_multi_by_type(CopyType) ->
    List = world_data:get_double_copy(),
    case lists:member(CopyType, List) of
        true ->
            2;
        _ ->
            1
    end.
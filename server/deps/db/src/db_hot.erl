%%%--------------------------------------------------------
%%% @author 
%%% @doc
%%%     维护活跃数据
%%% @end
%%%--------------------------------------------------------

-module(db_hot).
-include_lib("stdlib/include/ms_transform.hrl").
-export([
        start/1,
        del_cools/3,
        raw_mark_hots/2
    ]).

-export([
        mark_hots/2
        ]).

start(Table) ->
    HotMarker = hot_marker_name(Table),
    ets:new(HotMarker, [named_table, private, {keypos, 1}]).

hot_marker_name(Table) ->
    list_to_atom(lists:concat([?MODULE, "_", Table])).


mark_hots(Table, Keys) when is_list(Keys)->
    Server = db_server:server_name(Table),
    gen_server:cast(Server, {hot, Keys}).

raw_mark_hots(HotMarker, Keys) ->
    Now = time_tool:now(),
    ets:insert(HotMarker, [{Key, Now} || Key <- Keys]).

%% 清理访问时间早于CoolTime的记录
del_cools(Table, HotMarker, CoolTime) ->
    MS = ets:fun2ms(fun({ID, Time}) when Time < CoolTime -> ID end),
    CoolIDs = ets:select(HotMarker, MS),
    [ets:delete(Table, ID) || ID <- CoolIDs],

    MS2 = ets:fun2ms(fun({_, Time}) when Time < CoolTime -> true end),
    ets:select_delete(HotMarker, MS2).
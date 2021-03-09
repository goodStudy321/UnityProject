%%%%%-------------------------------------------------------------------
%%%%% @author WZP
%%%%% @copyright (C) 2018, <COMPANY>
%%%%% @doc
%%%%%
%%%%% @end
%%%%% Created : 25. 十二月 2018 16:26
%%%%%-------------------------------------------------------------------
-module(world_bg_act_server).
-author("WZP").
-behaviour(gen_server).
-include("global.hrl").
-include("bg_act.hrl").
-include("proto/mod_role_bg_act.hrl").


%% API
-export([
    start/0,
    start_link/0
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
    call/1,
    info_mod/2,
    call_mod/2
]).

-export([
    bg_update_bg_act/1,
    bg_delete_bg_act/1,
    bg_add_bg_act/1,
    do_bg_delete_bg_act/1
]).


-export([
    is_bg_act_open/1,
    get_all_bg_act/0,
    get_open_bg_act_front/1,
    get_open_bg_act_back/1,
    get_bg_act/1,
    get_bg_act_reward/2
]).



bg_update_bg_act(Info) ->
    %%    info({bg_delete_bg_act, ID}).
    Info2 = Info:parse_post(),
    ?ERROR_MSG("----------------bg_update_bg_act------------~w", [Info2]),
    call({bg_update_bg_act, Info2}).
%%    call({bg_update_bg_act, Info}).

bg_add_bg_act(Info) ->
    Info2 = Info:parse_post(),
    ?ERROR_MSG("----------------bg_add_bg_act------------~w", [Info2]),
    call({bg_add_bg_act, Info2}).

bg_delete_bg_act(Info) ->
    Info2 = Info:parse_post(),
    List = proplists:get_value("type", Info2),
    List2 = string:tokens(List, ","),
    ?ERROR_MSG("----------------bg_delete_bg_act------------~w", [List2]),
    List3 = [lib_tool:to_integer(ID) || ID <- List2],
    call({bg_delete_bg_act, List3}).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).

info_mod(Mod, Info) ->
    info({mod, Mod, Info}).

call_mod(Mod, Info) ->
    call({mod, Mod, Info}).


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    case catch bg_act_misc:init_bg_act_data(time_tool:now()) of
        ok ->
            ok;
        Err ->
            ?ERROR_MSG("----------------Err------------~w", [Err])
    end,
    time_tool:reg(world, [0, 1000]),
    {ok, []}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ?ERROR_MSG("-----------_Reason----------------~w", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
%%do_handle({monster_server_open, ActDropList, Pid}) ->
%%    do_monster_server_open(ActDropList, Pid);
%%do_handle({monster_server_close, MapID, Pid}) ->
%%    do_monster_server_close(MapID, Pid);
do_handle(zeroclock) ->
    do_reload_config_zeroclock();
do_handle({time_store_buy, EntryID}) ->
    hook_bg_act:time_store_buy(EntryID);
do_handle({bg_update_bg_act, Info}) ->
    do_bg_update_bg_act(Info);
do_handle({bg_delete_bg_act, List}) ->
    do_bg_delete_bg_act(List);
do_handle({bg_add_bg_act, Info}) ->
    do_bg_add_bg_act(Info);
do_handle({loop_sec, Now}) ->
    do_loop_sec(Now);
%%do_handle({gm_start, ID}) ->
%%    do_gm_status(ID, ?BG_ACT_STATUS_TWO);
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
%%do_handle({gm_stop, ID}) ->
%%    do_gm_status(ID, ?BG_ACT_STATUS_CLOSE);
do_handle({gm_end_time, EndTime, ID}) ->
    do_gm_end_time(EndTime, ID);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).


do_reload_config_zeroclock() ->
    ?ERROR_MSG("----------------Err------------~w", [1]),
    List = get_all_bg_act(),
    Now = time_tool:now(),
    List2 = [hook_bg_act:zero_clock_before_init(Info, Now) || Info <- List],
    do_loop_sec(List2, Now),
    bg_act_misc:init_bg_act_data(Now),
    List3 = get_all_bg_act(),
    [hook_bg_act:zero_clock_after_init(Info, Now) || Info <- List3].

do_loop_sec(Now) ->
    List = get_all_bg_act(),
    do_loop_sec(List, Now).

do_loop_sec([], _Now) ->
    ok;
do_loop_sec([BcAct|T], Now) ->
    do_check_bg_act(BcAct, Now),
    do_loop_sec(T, Now).


do_check_bg_act(BcActInfo, Now) ->
    #r_bg_act{
        id = ID,
%%        is_gm_set = IsGmSet,
        start_time = StartTime,
        end_time = EndTime,
        start_day_time = StartDayTime,
        end_day_time = EndDayTime,
        start_date = StartDate,
        end_date = EndDate,
        status = Status,
        is_visible = Visible
    } = BcActInfo,
    IsVisible = ?INT2BOOL(Visible),
    if
        Status =:= ?BG_ACT_STATUS_FOUR ->
            OpenServerTime = time_tool:midnight(common_config:get_open_time()),
            CdTime = OpenServerTime + ?BG_CD,
            if
                Now >= EndDate ->
                    NowStatus = ?BG_ACT_STATUS_THREE;
                Now >= StartTime ->
                    NowStatus = ?BG_ACT_STATUS_TWO;
                Now >= CdTime andalso Now >= StartDate ->
                    NowStatus = ?BG_ACT_STATUS_ONE;
                true ->
                    NowStatus = Status
            end;
        Status =:= ?BG_ACT_STATUS_THREE ->
            if
                Now >= StartTime ->
                    NowStatus = ?BG_ACT_STATUS_TWO;
                Now >= StartDate ->
                    NowStatus = ?BG_ACT_STATUS_ONE;
                true ->
                    NowStatus = Status
            end;
        Status =:= ?BG_ACT_STATUS_ONE ->
            if
                Now >= EndDate ->
                    NowStatus = ?BG_ACT_STATUS_THREE;
                Now >= StartTime ->
                    NowStatus = ?BG_ACT_STATUS_TWO;
                true ->
                    NowStatus = Status
            end;
        true -> %%Status =:= ?BG_ACT_STATUS_TWO
            if
                Now >= EndDate ->
                    NowStatus = ?BG_ACT_STATUS_THREE;
                Now >= EndTime ->
                    NowStatus = ?BG_ACT_STATUS_ONE;
                true ->
                    NowStatus = Status
            end
    end,
    case NowStatus =/= Status of
        true ->
            if
                NowStatus =:= ?BG_ACT_STATUS_THREE andalso Status =:= ?BG_ACT_STATUS_TWO ->
                    ?ERROR_MSG("---------1--------~w", [ID]),
                    hook_bg_act:do_bg_act_close_action(ID),
                    ?IF(IsVisible, common_broadcast:bc_record_to_world(#m_bg_act_close_toc{act_id = ID}), ok),
                    delete_bg_act(ID);
                NowStatus =:= ?BG_ACT_STATUS_THREE andalso Status =:= ?BG_ACT_STATUS_ONE ->
                    ?ERROR_MSG("---------2--------~w", [ID]),
                    ?IF(IsVisible, common_broadcast:bc_record_to_world(#m_bg_act_close_toc{act_id = ID}), ok),
                    delete_bg_act(ID);
                NowStatus =:= ?BG_ACT_STATUS_THREE andalso Status =:= ?BG_ACT_STATUS_FOUR ->
                    ?ERROR_MSG("---------7--------~w", [ID]),
                    delete_bg_act(ID);
                NowStatus =:= ?BG_ACT_STATUS_TWO andalso (Status =:= ?BG_ACT_STATUS_THREE orelse Status =:= ?BG_ACT_STATUS_FOUR) ->
                    ?ERROR_MSG("---------3--------~w", [ID]),
                    IsInit = true,
                    BcActInfo2 = BcActInfo#r_bg_act{status = NowStatus},
                    hook_bg_act:do_bg_act_open_action(BcActInfo2, Now),
                    set_bg_act(BcActInfo2),
                    ?IF(IsVisible orelse IsInit, hook_bg_act:bc_bg_act(ID, IsInit), ok),
                    do_check_bg_act_i(BcActInfo2, Now);  %%非初始化非可视不广播;
                NowStatus =:= ?BG_ACT_STATUS_TWO andalso Status =:= ?BG_ACT_STATUS_ONE ->
                    ?ERROR_MSG("---------4--------~w", [ID]),
                    BcActInfo2 = BcActInfo#r_bg_act{status = NowStatus},
                    hook_bg_act:do_bg_act_open_action(BcActInfo2, Now),
                    set_bg_act(BcActInfo2),
                    do_check_bg_act_i(BcActInfo2, Now);
                NowStatus =:= ?BG_ACT_STATUS_ONE andalso Status =:= ?BG_ACT_STATUS_TWO ->
                    {StartTime2, EndTime2} = bg_act_misc:cal_time(StartDate, EndDate, StartDayTime, EndDayTime, Now),
                    ?ERROR_MSG("---------5-- StartDate, EndDate, StartDayTime, EndDayTime, Now ------~w", [{StartDate, EndDate, StartDayTime, EndDayTime, Now}]),
                    ?ERROR_MSG("---------5-- {StartTime2, EndTime2} ------~w", [{StartTime2, EndTime2}]),
                    BcActInfo2 = BcActInfo#r_bg_act{status = NowStatus, start_time = StartTime2, end_time = EndTime2},
                    hook_bg_act:do_bg_act_close_action(ID),
                    ?IF(IsVisible, common_broadcast:bc_record_to_world(#m_bg_act_close_toc{act_id = ID}), ok),
                    set_bg_act(BcActInfo2);
                NowStatus =:= ?BG_ACT_STATUS_ONE andalso (Status =:= ?BG_ACT_STATUS_THREE orelse Status =:= ?BG_ACT_STATUS_FOUR) ->
                    ?ERROR_MSG("---------6--------~w", [ID]),
                    IsInit = true,
                    BcActInfo2 = BcActInfo#r_bg_act{status = NowStatus},
                    set_bg_act(BcActInfo2),
                    ?IF(IsVisible orelse IsInit, hook_bg_act:bc_bg_act(ID, IsInit), ok);  %%非初始化非可视不广播;
                true ->
                    ok
            end;
        _ ->
            ok
    end.

do_check_bg_act_i(BcActInfo, Now) ->
    {_, {Hour, Min, Sec}} = time_tool:timestamp_to_datetime(Now),
    case Min =:= 0 andalso Sec =:= 0 of
        true ->
            hook_bg_act:hour(Now, Hour, BcActInfo);
        _ ->
            ok
    end,
    case Sec =:= 0 andalso (Min =:= 0 orelse Min =:= 30) of
        true ->
            hook_bg_act:half_hour(Now, Hour, BcActInfo);
        _ ->
            ok
    end.


%%
%%do_gm_status(ID, NowStatus) ->
%%    #r_bg_act{status = Status} = BgAct = get_bg_act(ID),
%%    case Status =:= NowStatus of
%%        true ->
%%            ok;
%%        _ ->
%%            Now = time_tool:now(),
%%            {StartTime, EndTime} =
%%            if
%%                NowStatus =:= ?BG_ACT_STATUS_TWO ->
%%                    {Now, 0};
%%                NowStatus =:= ?BG_ACT_STATUS_CLOSE ->
%%                    {0, Now - 10}
%%            end,
%%            set_bg_act(BgAct#r_bg_act{is_gm_set = true, start_time = StartTime, end_time = EndTime}),
%%            do_loop_sec(ID, Now)
%%    end.

do_gm_end_time(EndTime, ID) ->
    BgAct = get_bg_act(ID),
    set_bg_act(BgAct#r_bg_act{end_time = EndTime}).

%%更新后台活动信息
do_bg_update_bg_act(Info) ->
    case catch bg_act_update:bg_update_bg_act(Info) of
        ok ->
            ok;
        {error, ErrInfo} ->
            ?ERROR_MSG("---------ErrInfo---------------~w", [ErrInfo]),
            {error, ErrInfo};
        Res ->
            ?ERROR_MSG("---------ErrInfo---------------~w", [Res]),
            {error, 1}
    end.

%%后台活动删除
do_bg_delete_bg_act(List) when erlang:is_list(List) ->
    [?TRY_CATCH(do_bg_delete_bg_act(ID)) || ID <- List],
    ok;

do_bg_delete_bg_act(ID) when erlang:is_integer(ID) ->
    case db:lookup(?DB_R_BG_ACT_P, ID) of
        [#r_bg_act{is_visible = IsVisible, status = Status}] ->
            case Status of
                ?BG_ACT_STATUS_TWO ->
                    ?IF(IsVisible, common_broadcast:bc_record_to_world(#m_bg_act_close_toc{act_id = ID}), ok),
                    hook_bg_act:do_bg_act_close_action(ID);
                _ ->
                    ok
            end;
        _ ->
            ?ERROR_MSG("-----------do_bg_delete_bg_act------no id--------------~w", [ID]),
            ok
    end,
    delete_bg_act(ID);

do_bg_delete_bg_act(ID) ->
    do_bg_delete_bg_act(lib_tool:to_integer(ID)).


%%后台增加活动
do_bg_add_bg_act(Info) ->
    case catch bg_act_misc:bg_add_bg_act(Info) of
        ok ->
            ok;
        {error, ErrInfo} ->
            ?ERROR_MSG("----ErrInfo--1--------~w", [ErrInfo]),
            {error, ErrInfo};
        Res ->
            ?ERROR_MSG("----ErrInfo----------~w", [Res]),
            {error, 1}
    end.

%%%===================================================================
%%% 数据操作
%%%===================================================================


is_bg_act_open(ID) ->
    #r_bg_act{status = Status} = get_bg_act(ID),
    Status =:= ?BG_ACT_STATUS_TWO.

%%is_bg_visible(ID) ->
%%    #r_bg_act{is_visible = IsVisible} = get_bg_act(ID),
%%    IsVisible.

get_all_bg_act() ->
    db:table_all(?DB_R_BG_ACT_P).

%% 活动开启期间，尚未真实开启
get_open_bg_act_front(#r_role{role_attr = RoleAttr}) ->
    get_open_bg_act_front(RoleAttr#r_role_attr.level);

get_open_bg_act_front(Level) when erlang:is_integer(Level) ->
    List = db:table_all(?DB_R_BG_ACT_P),
    [Info || Info <- List, Info#r_bg_act.status < ?BG_ACT_STATUS_THREE, Level >= Info#r_bg_act.min_level].

%% 活动开启期间，并且已真实开启
get_open_bg_act_back(#r_role{role_attr = RoleAttr}) ->
    get_open_bg_act_back(RoleAttr#r_role_attr.level);

get_open_bg_act_back(Level) when erlang:is_integer(Level) ->
    List = db:table_all(?DB_R_BG_ACT_P),
    [Info || Info <- List, Info#r_bg_act.status =:= ?BG_ACT_STATUS_TWO, Level >= Info#r_bg_act.min_level].

set_bg_act(BgAct) ->
    db:insert(?DB_R_BG_ACT_P, BgAct).
get_bg_act(ID) ->
    case db:lookup(?DB_R_BG_ACT_P, ID) of
        [#r_bg_act{} = BgAct] ->
            BgAct;
        _ ->
            #r_bg_act{id = ID}
    end.

delete_bg_act(ID) ->
    db:delete(?DB_R_BG_ACT_P, ID).

get_bg_act_reward(ID, EntryID) ->
    #r_bg_act{config_list = ConfigList} = get_bg_act(ID),
    case lists:keyfind(EntryID, #bg_act_config_info.sort, ConfigList) of
        false ->
            [];
        #bg_act_config_info{items = Items} ->
            [begin
                 case EntryInfo of
                     {TypeID, Num, Bind, _} ->
                         #p_goods{type_id = TypeID, num = Num, bind = Bind};
                     #p_item_i{type_id = TypeID, num = Num, is_bind = Bind} ->
                         #p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)}
                 end
             end || EntryInfo <- Items]
    end.




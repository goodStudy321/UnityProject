%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 六月 2019 14:15
%%%-------------------------------------------------------------------
-module(family_escort_server).
-author("WZP").
-include("family_escort.hrl").
-include("proto/mod_role_escort.hrl").
-include("global.hrl").
-include("family.hrl").
-include("role.hrl").
-include("proto/mod_role_family.hrl").
-behaviour(gen_server).
%%-include_lib("stdlib/include/ms_transform.hrl").

%% API
-export([
    start/0,
    start_link/0,
    handle/1
]).

%%test
-export([
    init_test_data/0,
    test/0
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3,
    get_escort_data/1,
    set_escort_data/1,
    info/1,
    rob/4,
    rob_back/3,
    log_time_text/0,
    family_title_update/2,
    role_name_update/2,
    get_escort_server/0,
    ask_help/1
]).


ask_help(RoleID) ->
    pname_server:call(?MODULE, {ask_help, RoleID}).


family_title_update(RoleID, Title) ->
    info({family_title_update, RoleID, Title}).

role_name_update(RoleID, Name) ->
    info({role_name_update, RoleID, Name}).

rob_back(RoleID, Power, DestRole) ->
    pname_server:call(?MODULE, {rob_back, RoleID, Power, DestRole}).

rob(RoleID, MyPower, MyName, DestRole) ->
    pname_server:call(?MODULE, {rob, RoleID, MyPower, MyName, DestRole}).

info(Info) ->
    pname_server:send(?MODULE, Info).


%% API
start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

handle(Info) ->
    do_handle(Info).


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    time_tool:reg(world, [0, 1000]),
    ets:new(?ETS_TIME_LOOP, [named_table, ordered_set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_time_loop.time}]),
    Now = time_tool:now(),
    IS_SAME_DAY = time_tool:is_same_date(world_data:get_escort_zeroclock(), Now),
    ?IF(IS_SAME_DAY, ok, world_data:set_escort_zeroclock(Now)),
    [begin
         Info2 = ?IF(IS_SAME_DAY, Info, Info#r_role_escort{escort_times = 0, rob_times = 0}),
         case Info2#r_role_escort.escort_id =/= 0 of
             true ->
                 case Info2#r_role_escort.end_time =< Now of
                     true ->
                         PLog = #p_escort_log{type = ?ESCORT_LOG_END, text = [log_time_text(Info2#r_role_escort.end_time)]},
                         LogList = add_log_list(PLog, Info2#r_role_escort.log),
                         Info3 = Info2#r_role_escort{escort_id = 0, reward = 1, log = LogList, end_time = 0},
                         db:insert(?DB_ROLE_ESCORT_P, Info3);
                     _ ->
                         insert_time_loop(Info2#r_role_escort.role_id, Info2#r_role_escort.end_time),
                         db:insert(?DB_ROLE_ESCORT_P, Info2)
                 end;
             _ ->
                 db:insert(?DB_ROLE_ESCORT_P, Info2),
                 ok
         end
     end || Info <- db:table_all(?DB_ROLE_ESCORT_P)],
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
    time_tool:dereg(world, [0]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


do_handle({role_name_update, RoleID, Name}) ->
    do_role_name_update(RoleID, Name);
do_handle({family_title_update, RoleID, Title}) ->
    do_family_title_update(RoleID, Title);
do_handle({update_fight, RoleID, Power}) ->
    do_update_fight(RoleID, Power);
do_handle({update_family_id, RoleID, Family}) ->
    do_update_family_id(RoleID, Family);
do_handle(zeroclock) ->
    do_zeroclock();
do_handle({loop_sec, Now}) ->
    do_loop(Now);
do_handle({rob, RoleID, MyPower, MyName, DestRole}) ->
    do_rob(RoleID, MyPower, MyName, DestRole);
do_handle({rob_back, RoleID, Power, DestRole}) ->
    do_rob_back(RoleID, Power, DestRole);
do_handle({ask_help, RoleID}) ->
    ask_help_i(RoleID);
do_handle({fairy_start, RoleID, RoleName, EndTime, Name, Fight, FamilyID, Title, _}) ->
    do_fairy(RoleID, RoleName, EndTime, Name, Fight, FamilyID, Title);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).


do_family_title_update(RoleID, Title) ->
    Data = get_escort_data(RoleID),
    set_escort_data(Data#r_role_escort{family_title = Title}).

do_role_name_update(RoleID, Name) ->
    Data = get_escort_data(RoleID),
    set_escort_data(Data#r_role_escort{name = Name}).

do_update_fight(RoleID, Power) ->
    Data = get_escort_data(RoleID),
    set_escort_data(Data#r_role_escort{fight = Power}).

do_update_family_id(RoleID, Family) ->
    Data = get_escort_data(RoleID),
    set_escort_data(Data#r_role_escort{family = Family}).


do_zeroclock() ->
    world_data:set_escort_zeroclock(time_tool:now()),
    case world_data:get_world_level() >= common_misc:get_global_int(?GLOBAL_CROSS_ACTIVITY_LEVEL) of
        false ->
            List = db:table_all(?DB_ROLE_ESCORT_P),
            [begin
                 db:insert(?DB_ROLE_ESCORT_P, Data#r_role_escort{rob_times = 0, escort_times = 0})
             end || Data <- List];
        _ ->
            case world_data:get_escort_mod() of
                family_escort_server ->
                    world_data:set_escort_mod(family_escort_cross_server),
                    List = db:table_all(?DB_ROLE_ESCORT_P),
                    [GlobalConfig] = lib_config:find(cfg_global, ?ESCORT_GLOBAL),
                    [FairyTimes, RobTimes|_] = GlobalConfig#c_global.list,
                    [
                        begin
                            case Data#r_role_escort.end_time =/= 0 orelse Data#r_role_escort.fairy_type =/= ?INIT_FAIRY of
                                true ->
                                    Rate = ?IF(Data#r_role_escort.rob_role_id > 0, 0.7, 1),
                                    [Config] = lib_config:find(cfg_escort, Data#r_role_escort.fairy_type),
                                    GoodsList = [#p_goods{type_id = Type, num = lib_tool:ceil(Num * Rate)} || {Type, Num} <- lib_tool:string_to_intlist(Config#c_escort.reward)],
                                    [LevelConfig] = lib_config:find(cfg_role_level, common_role_data:get_role_level(Data#r_role_escort.role_id)),
                                    Exp = lib_tool:ceil(LevelConfig#c_role_level.base_exp * Config#c_escort.exp_rate / 10000 * Rate),
                                    GoodsList2 = [#p_goods{type_id = 100, num = Exp}|GoodsList],
                                    LetterInfo = #r_letter_info{
                                        template_id = ?LETTER_CROSS_ESCORT,
                                        action = ?ITEM_GAIN_FAIRY,
                                        goods_list = GoodsList2},
                                    common_letter:send_letter(Data#r_role_escort.role_id, LetterInfo),
                                    Data2 = Data#r_role_escort{fairy_type = ?INIT_FAIRY, reward = 0, end_time = 0, log = [], help = 0, rob_role_id = 0},
                                    set_escort_data(Data2),
                                    catch common_misc:unicast(Data#r_role_escort.role_id, #m_role_escort_info_toc{
                                        escort_times = FairyTimes - Data2#r_role_escort.escort_times,
                                        rob_times = RobTimes - Data2#r_role_escort.rob_times,
                                        escort_end_time = Data2#r_role_escort.end_time, type = Data2#r_role_escort.fairy_type,
                                        rob = ?IF(Data2#r_role_escort.rob_role_id > 10, 1, Data2#r_role_escort.rob_role_id),
                                        reward = Data2#r_role_escort.reward, log_list = Data2#r_role_escort.log}),
                                    ok;
                                _ ->
                                    ok
                            end
                        end
                        || Data <- List];
                _ ->
                    ok
            end
    end.


do_fairy(RoleID, RoleName, EndTime, Name, Fight, FamilyID, Title) ->
    Data = get_escort_data(RoleID),
    NewEscort = world_data:get_escort_id(),
    PLog = #p_escort_log{type = ?ESCORT_LOG_START, text = [log_time_text(), Name]},
    LogList = add_log_list(PLog, Data#r_role_escort.log),
    common_misc:unicast(RoleID, #m_role_escort_log_toc{log_list = PLog}),
    EscortTimes = Data#r_role_escort.escort_times + 1,
    Data2 = Data#r_role_escort{end_time = EndTime, escort_id = NewEscort, help = 0, fight = Fight, log = LogList, escort_times = EscortTimes, reward = 0, rob_role_id = 0,
                               family = FamilyID, family_title = Title, name = RoleName},
    set_escort_data(Data2),
    TimeData = get_loop_time(EndTime),
    NewList = [RoleID|TimeData#r_time_loop.check_list],
    set_loop_time(TimeData#r_time_loop{time = EndTime, check_list = NewList}),
    Log = #log_family_escort{role_id = RoleID, type = Data2#r_role_escort.fairy_type, escort_type = 1},
    background_misc:log(Log).


ask_help_i(RoleID) ->
    case catch do_ask_help(RoleID) of
        ok ->
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

do_ask_help(RoleID) ->
    Data = family_escort_server:get_escort_data(RoleID),
    ?IF(Data#r_role_escort.rob_role_id > 10, ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_FOR_HELP_002)),
    ?IF(Data#r_role_escort.help + 1 < time_tool:now(), ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_FOR_HELP_001)),
    EnemyData = family_escort_server:get_escort_data(Data#r_role_escort.rob_role_id),
    BcInfo = #m_common_notice_toc{id = ?NOTICE_ESCORT_ASK_FOR_HELP,
                                  text_string = [Data#r_role_escort.name, EnemyData#r_role_escort.name, lib_tool:to_list(Data#r_role_escort.rob_role_id) ++ "_" ++ common_config:get_server_name(), lib_tool:to_list(RoleID)]},
    common_broadcast:bc_record_to_family(Data#r_role_escort.family, BcInfo),
    Data2 = Data#r_role_escort{help = time_tool:now()},
    family_escort_server:set_escort_data(Data2),
    ok.



do_loop(Now) ->
    [
        case Info#r_time_loop.time =< Now of
            true ->
                ets:delete(?ETS_TIME_LOOP, Info#r_time_loop.time),
                do_end_time(Info#r_time_loop.check_list);
            _ ->
                ok
        end
        || Info <- ets:tab2list(?ETS_TIME_LOOP)].




do_end_time(IDList) when erlang:is_list(IDList) ->
    [
        begin
            case db:lookup(?DB_ROLE_ESCORT_P, RoleID) of
                [Info] ->
                    do_end_time(Info);
                _ ->
                    ok
            end
        end
        || RoleID <- IDList];
do_end_time(Info) ->
    PLog = #p_escort_log{type = ?ESCORT_LOG_END, text = [log_time_text(Info#r_role_escort.end_time)]},
    LogList = add_log_list(PLog, Info#r_role_escort.log),
    Info2 = Info#r_role_escort{escort_id = 0, reward = 1, log = LogList, end_time = 0},
    set_escort_data(Info2),
    common_misc:unicast(Info2#r_role_escort.role_id, #m_role_escort_log_toc{log_list = PLog}),
    common_misc:unicast(Info2#r_role_escort.role_id, #m_role_escort_status_toc{value = [#p_kv{id = 6, val = 1}, #p_kv{id = 3, val = 0}]}).

log_time_text() ->
    log_time_text(time_tool:now()).
log_time_text(Now) ->
    {{Year, Month, Day}, {Hour, Min, Sec}} = time_tool:timestamp_to_datetime(Now),
    lib_tool:to_list(Year) ++ "年" ++ lib_tool:to_list(Month) ++ "月" ++ lib_tool:to_list(Day) ++ "日" ++ lib_tool:to_list(Hour) ++ "时" ++ lib_tool:to_list(Min) ++ "分" ++ lib_tool:to_list(Sec) ++ "秒".

add_log_list(Log, List) ->
    [Log|List].
%%    NewList = [Log|List],
%%    case erlang:length(NewList) > ?MAX_FAIRY_LOG of
%%        true ->
%%            lists:droplast(NewList);
%%        _ ->
%%            NewList
%%    end.



insert_time_loop(RoleID, EndTime) ->
    case ets:lookup(?ETS_TIME_LOOP, EndTime) of
        [] ->
            ets:insert(?ETS_TIME_LOOP, #r_time_loop{time = EndTime, check_list = [RoleID]});
        [Data] ->
            ets:insert(?ETS_TIME_LOOP, Data#r_time_loop{check_list = [RoleID|Data#r_time_loop.check_list]})
    end.




get_escort_data(RoleID) ->
    case db:lookup(?DB_ROLE_ESCORT_P, RoleID) of
        [#r_role_escort{} = RoleData] -> RoleData;
        _ -> #r_role_escort{role_id = RoleID}
    end.

set_escort_data(Data) ->
    db:insert(?DB_ROLE_ESCORT_P, Data).


get_loop_time(EndTime) ->
    case ets:lookup(?ETS_TIME_LOOP, EndTime) of
        [] ->
            #r_time_loop{time = EndTime, check_list = []};
        [Data] ->
            Data
    end.


set_loop_time(Data) ->
    ets:insert(?ETS_TIME_LOOP, Data).






init_test_data() ->
    [begin
         EndTime = time_tool:now() + ?ONE_DAY,
         Data = #r_role_escort{role_id = ID * 1000, escort_id = ID, end_time = EndTime, name = lib_tool:to_list(ID)},
         set_escort_data(Data),
         TimeData = get_loop_time(EndTime),
         NewList = [ID * 1000|TimeData#r_time_loop.check_list],
         set_loop_time(TimeData#r_time_loop{time = EndTime, check_list = NewList})
     end || ID <- lists:seq(1, 50)].

test() ->
    Ms = ets:fun2ms(
        fun(#r_role_escort{escort_id = EscortID, end_time = EndTime} = Data) when EscortID > 1 andalso EndTime > 1 ->
            Data end
    ),
    ?ERROR_MSG("-----------------~w", [Ms]),
    {List, Continuation} = ets:select(?DB_ROLE_ESCORT_P, Ms, 10),
    ?ERROR_MSG("-----------List------~w", [List]),
    List2 = ets:select(Continuation),
    ?ERROR_MSG("-----------List2------~w", [List2]),
    ok.



do_rob(RoleID, Power, MyName, DestRole) ->
    case catch check_rob(RoleID, Power, MyName, DestRole) of
        {error, ErrCode} ->
            {error, ErrCode};
        {ok, win, Type, Times, EnemyInfo} ->
            {ok, win, Type, Times, EnemyInfo};
        {ok, fail, EnemyInfo} ->
            {ok, fail, EnemyInfo};
        Err ->
            ?ERROR_MSG("-----------do_rob------~w", [Err])
    end.


check_rob(RoleID, Power, MyName, DestRole) ->
    Data = family_escort_server:get_escort_data(RoleID),
    [GlobalConfig] = lib_config:find(cfg_global, ?ESCORT_GLOBAL),
    [_FairyTimes, RobTimes|_] = GlobalConfig#c_global.list,
    ?IF(RobTimes - Data#r_role_escort.rob_times > 0, ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_ROB_BACK_002)),
    DestData = family_escort_server:get_escort_data(DestRole),
    ?IF(DestData#r_role_escort.rob_role_id =:= 0, ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_ROB_BACK_003)),
    ?IF(DestData#r_role_escort.end_time >= time_tool:now(), ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_ROB_001)),
    ?IF(DestData#r_role_escort.fairy_type =/= ?MAX_FAIRY, ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_ROB_BACK_004)),
    EnemyAttr = common_role_data:get_role_attr(DestRole),
    #actor_fight_attr{max_hp = EnemyHp, move_speed = EnemySpeed} = common_role_data:get_role_fight_attr(DestRole),
    EnemyInfo = {DestRole, EnemyHp, EnemySpeed, DestData#r_role_escort.name, EnemyAttr#r_role_attr.sex, EnemyAttr#r_role_attr.category,
                 EnemyAttr#r_role_attr.level, EnemyAttr#r_role_attr.skin_list, EnemyAttr#r_role_attr.power},
    ?WARNING_MSG("-----------------~w", [DestRole]),
    ?WARNING_MSG("-----------EnemyAttr------~w", [EnemyAttr]),
    case Power > DestData#r_role_escort.fight of
        true ->
            Data2 = Data#r_role_escort{rob_times = Data#r_role_escort.rob_times + 1, fight = Power, name = MyName},
            NewLog = #p_escort_log{type = ?ESCORT_LOG_ROB_SUC, text = [log_time_text(), MyName, lib_tool:to_list(RoleID), lib_tool:to_list(DestRole), MyName]},
            FromLetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_ESCORT_BE_ROB,
                text_string = [MyName, lib_tool:to_list(RoleID), lib_tool:to_list(DestRole), MyName]
            },
            common_letter:send_letter(DestRole, FromLetterInfo),
            DestData2 = DestData#r_role_escort{rob_role_id = RoleID, log = add_log_list(NewLog, DestData#r_role_escort.log)},
            set_escort_data(Data2),
            set_escort_data(DestData2),
            common_misc:unicast(DestRole, #m_role_escort_log_toc{log_list = NewLog}),
            common_misc:unicast(DestRole, #m_role_escort_status_toc{value = [#p_kv{id = 5, val = 1}]}),
            case DestData#r_role_escort.family_title >= ?TITLE_VICE_OWNER of
                true ->
                    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(DestRole),
                    #p_family{family_name = FamilyName} = mod_family_data:get_family(FamilyID),
                    common_broadcast:send_world_common_notice(?NOTICE_ESCORT_OWNER_BE_ROB, [FamilyName, DestData#r_role_escort.name, Data#r_role_escort.name]);
                _ ->
                    ok
            end,
            Log = #log_family_escort{role_id = RoleID, type = Data2#r_role_escort.fairy_type, escort_type = 2},
            background_misc:log(Log),
            {ok, win, DestData#r_role_escort.fairy_type, Data2#r_role_escort.rob_times, EnemyInfo};
        _ ->
            NewLog = #p_escort_log{type = ?ESCORT_LOG_ROB_FAIL, text = [log_time_text(), MyName, lib_tool:to_list(RoleID)]},
            DestData2 = DestData#r_role_escort{log = add_log_list(NewLog, DestData#r_role_escort.log)},
            set_escort_data(DestData2),
            common_misc:unicast(DestRole, #m_role_escort_log_toc{log_list = NewLog}),
            {ok, fail, EnemyInfo}
    end.



do_rob_back(RoleID, Power, DestRole) ->
    case catch check_rob_back(RoleID, Power, DestRole) of
        {error, ErrCode} ->
            {error, ErrCode};
        {ok, win, FairyType, EnemyInfo} ->
            {ok, win, FairyType, EnemyInfo};
        {ok, fail, EnemyInfo} ->
            {ok, fail, EnemyInfo};
        Err ->
            ?ERROR_MSG("-----------do_rob------~w", [Err])
    end.


check_rob_back(RoleID, Power, DestRole) ->
    BeHelpData = family_escort_server:get_escort_data(DestRole),
    #r_role_escort{name = RoleName} = family_escort_server:get_escort_data(RoleID),
    ?IF(BeHelpData#r_role_escort.rob_role_id > 10, ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_FOR_HELP_002)),
    EnemyData = family_escort_server:get_escort_data(BeHelpData#r_role_escort.rob_role_id),
    #r_role_attr{role_name = DestName} = common_role_data:get_role_attr(BeHelpData#r_role_escort.rob_role_id),
    EnemyAttr = common_role_data:get_role_attr(BeHelpData#r_role_escort.rob_role_id),
    #actor_fight_attr{max_hp = EnemyHp, move_speed = EnemySpeed} = common_role_data:get_role_fight_attr(BeHelpData#r_role_escort.rob_role_id),
    EnemyInfo = {BeHelpData#r_role_escort.rob_role_id, EnemyHp, EnemySpeed, EnemyData#r_role_escort.name, EnemyAttr#r_role_attr.sex, EnemyAttr#r_role_attr.category,
                 EnemyAttr#r_role_attr.level, EnemyAttr#r_role_attr.skin_list, EnemyAttr#r_role_attr.power},
    ?WARNING_MSG("-----------------~w", [BeHelpData#r_role_escort.rob_role_id]),
    ?WARNING_MSG("-----------EnemyAttr------~w", [EnemyAttr]),
    case Power >= EnemyData#r_role_escort.fight of
        true ->
            case RoleID =:= DestRole of
                true ->
                    NewLog = #p_escort_log{type = ?ESCORT_LOG_ROB_BACK, text = [log_time_text(), DestName]},
                    common_misc:unicast(BeHelpData#r_role_escort.role_id, #m_role_escort_status_toc{value = [#p_kv{id = 5, val = 2}]}),
                    BeHelpData2 = BeHelpData#r_role_escort{rob_role_id = 2, log = [NewLog|BeHelpData#r_role_escort.log]};
                _ ->
                    NewLog = #p_escort_log{type = ?ESCORT_LOG_HELP, text = [log_time_text(), RoleName, lib_tool:to_list(RoleID), DestName]},
                    common_misc:unicast(BeHelpData#r_role_escort.role_id, #m_role_escort_status_toc{value = [#p_kv{id = 5, val = 3}]}),
                    BeHelpData2 = BeHelpData#r_role_escort{rob_role_id = 3, log = [NewLog|BeHelpData#r_role_escort.log]},
                    FromLetterInfo = #r_letter_info{
                        template_id = ?LETTER_TEMPLATE_ESCORT_BE_ROB_BACK,
                        text_string = [RoleName, lib_tool:to_list(RoleID), DestName]
                    },
                    common_letter:send_letter(DestRole, FromLetterInfo)
            end,
            set_escort_data(BeHelpData2),
            case EnemyData#r_role_escort.family_title >= ?TITLE_VICE_OWNER of
                true ->
                    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(BeHelpData#r_role_escort.rob_role_id),
                    #p_family{family_name = FamilyName} = mod_family_data:get_family(FamilyID),
                    #r_role_escort{name = MyName} = family_escort_server:get_escort_data(RoleID),
                    common_broadcast:send_world_common_notice(?NOTICE_ESCORT_OWNER_BE_HELP, [MyName, FamilyName, EnemyData#r_role_escort.name]);
                _ ->
                    ok
            end,
            common_misc:unicast(BeHelpData#r_role_escort.role_id, #m_role_escort_log_toc{log_list = NewLog}),
            {ok, win, BeHelpData#r_role_escort.fairy_type, EnemyInfo};
        _ ->
            {ok, fail, EnemyInfo}
    end.


get_escort_server() ->
    world_data:get_escort_mod().



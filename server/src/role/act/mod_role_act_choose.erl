%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 黑市鉴宝
%%% @end
%%% Created : 10. 九月 2019 20:11
%%%-------------------------------------------------------------------
-module(mod_role_act_choose).
-author("huangxiangrui").
-include("common.hrl").
-include("role.hrl").
-include("cycle_act.hrl").
-include("act_choose.hrl").
-include("mod_role_act_os_second.hrl").
-include("mod_role_act_choose.hrl").

%% API
%% 只要在模块里定义了，gen_cfg_module.es就会在
%% cfg_module_etc里生成，role_server每次对应
%% 的操作都调用,还可以在gen_cfg_module.es设置优先级
-export([
    init/1,               %% role初始化
    loop/2,               %% 秒循环
    offline/1,
    online/1             %% 上线
]).

-export([
    handle/2,
    send/2
]).

-export([
    role_use_gold/2,
    init_data/2
]).

send(RoleID, Msg) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {Msg, RoleID, 0}}).

init(#r_role{role_id = RoleID, role_choose = undefined} = State) ->
    RoleChoose = #r_role_choose_p{role_id = RoleID},
    State#r_role{role_choose = RoleChoose};
init(State) ->
    State.

init_data(StartTime, #r_role{role_id = RoleID, role_choose = #r_role_choose_p{open_time = OpenTime} = RoleChoose} = State) ->
    RoleChooseNow = ?IF(OpenTime =/= 0, #r_role_choose_p{role_id = RoleID, open_time = StartTime}, RoleChoose#r_role_choose_p{role_id = RoleID, open_time = StartTime}),
    do_choose_count(State#r_role{role_choose = RoleChooseNow}).

loop(Now, State) ->
    do_loop_check_gifts_group(Now, State).

online(State) ->
    do_choose_count(State).

offline(State) ->
    ?IF(get_gifts_time() =/= undefined, do_loop_check_gifts_group(get_gifts_time(), State), State).

%% @doc 元宝消费
%% 要在hook_role模块里添加才生效
role_use_gold(Gold, #r_role{role_choose = RoleChoose} = State) ->
    case world_cycle_act_server:is_act_open(?CYCLE_ACT_CHOOSE) of
        true ->
            #r_role_choose_p{consume = Consume} = RoleChoose,
            do_choose_count(State#r_role{role_choose = RoleChoose#r_role_choose_p{consume = Consume + Gold}});
        _ ->
            State
    end.

handle({#m_role_act_choose_info_tos{}, RoleID, _PID}, State) ->
    do_choose_info(RoleID, State);
handle({#m_role_act_choose_extract_tos{id = ID}, RoleID, _PID}, State) ->
    do_choose_extract(ID, RoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

%% @doc 抽取次数
do_choose_count(#r_role{role_id = RoleID, role_choose = RoleChoose} = State) ->
    #r_role_choose_p{use_count = UseCount, consume = Consume} = RoleChoose,
    Univalent = common_misc:get_global_int(?GLOBAL_ACT_CHOOSE_CONSUME),
    Count = erlang:max(Consume div Univalent - UseCount, 0),
    DataRecord = #m_role_act_choose_count_toc{count = Count},
    common_misc:unicast(RoleID, DataRecord),
    State.

%% @doc 开始鉴宝
do_choose_info(RoleID, State) ->
    case catch check_choose_info(State) of
        {ok, Count, List, State2} ->
            DataRecord = #m_role_act_choose_info_toc{count = Count, goods_list = List},
            common_misc:unicast(RoleID, DataRecord),
            State2;
        {error, ErrCode} ->
            DataRecord = #m_role_act_choose_info_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.
check_choose_info(#r_role{role_id = _RoleID, role_choose = RoleChoose} = State) ->
    Now = time_tool:now(),
    #r_cycle_act{end_time = EndTime} = world_cycle_act_server:get_act(?CYCLE_ACT_CHOOSE),
    [Time] = common_misc:get_global_list(?GLOBAL_ACT_CHOOSE_LAST_TIME_OR_NUM),
    ?IF(Now + Time + 2 >= EndTime, ?THROW_ERR(?ERROR_OSS_RANK_REWARD_004), ok),

    ?IF(is_battle_open(State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    #r_role_choose_p{use_count = UseCount, consume = Consume} = RoleChoose,
    Univalent = common_misc:get_global_int(?GLOBAL_ACT_CHOOSE_CONSUME),
    Count = erlang:max(Consume div Univalent - UseCount, 0),

    ?IF(Count > 0, ok, ?THROW_ERR(?ERROR_ROLE_ACT_CHOOSE_EXTRACT_002)),
    List = get_gifts_group(),
    Now = time_tool:now(),

    keep_gifts_group(List),
    keep_gifts_time(Now),

    State2 = State#r_role{role_choose = RoleChoose#r_role_choose_p{use_count = UseCount + 1}},

    {ok, Count - 1, List, State2}.

get_gifts_group() ->
    ConfigNum = world_cycle_act_server:get_act_config_num(?CYCLE_ACT_CHOOSE),
    Number = common_misc:get_global_int(?GLOBAL_ACT_CHOOSE_LAST_TIME_OR_NUM),

    Lists = lists:foldl(fun({ID, #c_act_choose{config_num = ConfigNumI, upper_limit = UpperLimit, weight = Weight}}, Acc) ->
        case ConfigNum =:= ConfigNumI of
            true when UpperLimit =:= 0 ->
                [{ID, Weight, 9999}|Acc];
            true ->
                [{ID, Weight, UpperLimit}|Acc];
            _ ->
                Acc
        end end,        [], cfg_act_choose:list()),
    get_gifts_group(Lists, Number, []).
get_gifts_group(_Lists, 0, AccLists) ->
    lib_tool:random_reorder_list(AccLists);
get_gifts_group(Lists, Number, AccLists) ->
    AllList = [{Weight, {ID, Weight, UpperLimit}} || {ID, Weight, UpperLimit} <- Lists, UpperLimit > 0],
    {OptID, OptWeight, OptUpperLimit} = lib_tool:get_weight_output(AllList),
    NewLists = lists:keyreplace(OptID, 1, Lists, {OptID, OptWeight, OptUpperLimit - 1}),
    get_gifts_group(NewLists, Number - 1, [OptID|AccLists]).

%% @doc 开始抽取
do_choose_extract(ID, RoleID, State) ->
    case catch check_choose_extract(ID, State) of
        {ok, Count, GoodsList, State2} ->
            DataRecord = #m_role_act_choose_extract_toc{count = Count, reward = GoodsList},
            common_misc:unicast(RoleID, DataRecord),
            role_misc:create_goods(State2, ?ITEM_GAIN_ACT_CHOOSE_REWARD, GoodsList);
        {error, ErrCode} ->
            DataRecord = #m_role_act_choose_extract_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

check_choose_extract(ID, #r_role{role_id = _RoleID, role_choose = RoleChoose} = State) ->

    ?IF(is_battle_open(State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    #r_role_choose_p{history = History, use_count = UseCount, consume = Consume} = RoleChoose,
    Lists = obtain_gifts_group(),

    ?IF(lists:member(ID, Lists), ok, ?THROW_ERR(?ERROR_ROLE_ACT_CHOOSE_EXTRACT_001)),

    #c_act_choose{drop = Drop} = get_act_choose(ID),
    List = [{Weight, {TypeID, Num, Bind}} || {TypeID, Num, Bind, Weight} <- lib_tool:string_to_intlist(Drop)],
    {OptTypeID, OptNum, OptBind} = lib_tool:get_weight_output(List),
    GoodsList = [#p_goods{type_id = OptTypeID, num = OptNum, bind = ?IS_BIND(OptBind)}],

    del_gifts_group(),
    del_gifts_time(),
    Now = time_tool:now(),

    NewRoleChoose = RoleChoose#r_role_choose_p{history = lists:sublist([{ID, Now}|History], 20)},

    Univalent = common_misc:get_global_int(?GLOBAL_ACT_CHOOSE_CONSUME),
    Count = erlang:max(Consume div Univalent - UseCount, 0),
    {ok, Count, GoodsList, State#r_role{role_choose = NewRoleChoose}}.

%% @doc 时间限时检测
do_loop_check_gifts_group(Now, #r_role{role_id = RoleID} = State) ->
    case is_battle_open(State) of
        false ->
            State;
        _ ->
            GiftsTime = get_gifts_time(),
            case GiftsTime =/= undefined andalso Now >= GiftsTime of
                true ->
                    ID = lib_tool:random_element_from_list(obtain_gifts_group()),
                    do_choose_extract(ID, RoleID, State);
                _ ->
                    State
            end
    end.

get_act_choose(ID) ->
    [Config] = lib_config:find(cfg_act_choose, ID),
    Config.

is_battle_open(State) ->
    mod_role_cycle_act:is_act_open(?CYCLE_ACT_CHOOSE, State).

%% @doc 记录礼包组
keep_gifts_group(Lists) ->
    erlang:put({?MODULE, gifts_group}, Lists).
obtain_gifts_group() ->
    case erlang:get({?MODULE, gifts_group}) of
        undefined ->
            [];
        Val ->
            Val
    end.
del_gifts_group() ->
    erlang:erase({?MODULE, gifts_group}).

%% @doc 记录时间限时
keep_gifts_time(Now) ->
    [Time] = common_misc:get_global_list(?GLOBAL_ACT_CHOOSE_LAST_TIME_OR_NUM),
    erlang:put({?MODULE, gifts_time}, Now + Time).
get_gifts_time() ->
    erlang:get({?MODULE, gifts_time}).
del_gifts_time() ->
    erlang:erase({?MODULE, gifts_time}).

%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 鉴宝活动
%%% @end
%%% Created : 09. 九月 2019 12:30
%%%-------------------------------------------------------------------
-module(mod_role_act_identify_treasure).
-author("huangxiangrui").
-include("common.hrl").
-include("role.hrl").
-include("act.hrl").
-include("cycle_act.hrl").
-include("identify_treasure.hrl").
-include("mod_role_bag.hrl").
-include("mod_role_nature.hrl").
-include("mod_role_act_identify_treasure.hrl").

%% API
%% 只要在模块里定义了，gen_cfg_module.es就会在
%% cfg_module_etc里生成，role_server每次对应
%% 的操作都调用,还可以在gen_cfg_module.es设置优先级
-export([
    init/1,               %% role初始化
    loop/2,               %% 秒循环
    online/1             %% 上线
]).

-export([
    handle/2,
    send/2
]).

-export([
    get_role_info/1,
    init_data/2,
    get_rare_reward/1,
    do_it_info/2
]).

send(RoleID, Msg) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {Msg, RoleID, 0}}).

init(#r_role{role_id = RoleID, role_it = undefined} = State) ->
    RoleIt = #r_role_it{role_id = RoleID},
    do_it_info(RoleID, up_role_info(State#r_role{role_it = RoleIt}));
init(State) ->
    State.

%% @doc 活动初始化
init_data(StartTime, #r_role{role_id = RoleID} = State) ->
    RoleIt = #r_role_it{role_id = RoleID, open_time = StartTime},
    do_it_info(RoleID, up_role_info(State#r_role{role_it = RoleIt})).

loop(_Now, State) ->
    do_loop_begin(State).

online(#r_role{role_attr = #r_role_attr{role_id = RoleID}} = State) ->
    do_it_info(RoleID, State).

handle({#mod_role_act_it_info_tos{}, RoleID, _PID}, State) ->
    do_it_info(RoleID, State);
handle({#mod_role_act_it_begin_tos{type = Type}, RoleID, _PID}, State) ->
    do_it_begin(Type, RoleID, State);
handle({#mod_role_act_it_cease_tos{}, RoleID, _PID}, State) ->
    do_it_cease(RoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

%% @doc 获取信息
do_it_info(RoleID, #r_role{role_it = #r_role_it{it_num = ItNum, luck = Luck}} = State) ->
    FruitID = get_rare_reward(ItNum),
    DataRecord = #mod_role_act_it_info_toc{id = FruitID, luck = Luck},
    common_misc:unicast(RoleID, DataRecord),
    State.

%% @doc 获取当前稀有id
get_rare_reward(ItNum) ->
    List = cfg_act_identify_treasure:list(),
    ConfigNum = world_cycle_act_server:get_act_config_num(?CYCLE_ACT_IDENTIFY_TREASURE),
    RetList = lists:filter(
        fun({_ID, #c_act_identify_treasure{is_rare = IsRare, config_num = ConfigNumI}}) ->
            IsRare =:= ?IS_RARE andalso ConfigNum =:= ConfigNumI end, List),
    get_rare_reward(RetList, ItNum, 0).
get_rare_reward([], _ItNum, FruitID) ->
    FruitID;
get_rare_reward([{ID, #c_act_identify_treasure{show = Show}}|RetList], ItNum, _FruitID) ->
    case Show =:= ItNum of
        true ->
            ID;
        _ ->
            get_rare_reward(RetList, ItNum, ID)
    end.


%% @doc 开始鉴宝
do_it_begin(?VOLUNTARILY, RoleID, State) ->
    case is_battle_open(State) of
        true ->
            set_voluntarily_info(true),
            #r_role{role_it = #r_role_it{it_num = ItNum, luck = Luck}} = State,
            FruitID = get_rare_reward(ItNum),
            DataRecord = #mod_role_act_it_begin_toc{type = ?VOLUNTARILY, id = FruitID, luck = Luck},
            common_misc:unicast(RoleID, DataRecord),
            State;
        _ ->
            DataRecord = #mod_role_act_it_begin_toc{err_code = ?ERROR_COMMON_FUNCTION_NOT_OPEN},
            common_misc:unicast(RoleID, DataRecord),
            State
    end;

do_it_begin(Type, RoleID, State) ->
    case catch check_it_begin(Type, State) of
        {ok, IsRare, AddLuck, AssetDoings, State2} ->
            #r_role{role_it = RoleIt} = State3 = mod_role_asset:do(AssetDoings, State2),
            #r_role_it{it_num = ItNum, luck = Luck} = NewRoleIt = get_role_it(IsRare, AddLuck, RoleIt),
            FruitID = get_rare_reward(ItNum),
            DataRecord = #mod_role_act_it_begin_toc{type = ?IF(Type =:= ?LOOP_VOLUNTARILY, ?VOLUNTARILY, Type), id = FruitID, luck = Luck},
            common_misc:unicast(RoleID, DataRecord),
            State4 = State3#r_role{role_it = NewRoleIt},
            ?IF(IsRare =:= ?IS_RARE, do_it_cease(RoleID, State4), State4);
        {error, ErrCode} when Type =:= ?LOOP_VOLUNTARILY ->
            set_voluntarily_info(false),
            DataRecord = #mod_role_act_it_begin_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            DataRecord = #mod_role_act_it_cease_toc{},
            common_misc:unicast(RoleID, DataRecord),
            State;
        {error, _ErrCode} when Type =:= ?LOOP_VOLUNTARILY ->
            DataRecord = #mod_role_act_it_cease_toc{},
            common_misc:unicast(RoleID, DataRecord),
            set_voluntarily_info(false);
        {error, ErrCode} ->
            DataRecord = #mod_role_act_it_begin_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

check_it_begin(Type, #r_role{role_it = RoleIt} = State) ->
    #r_role_it{it_num = ItNum, luck = Luck, limit = Limit} = RoleIt,
    ?IF(is_battle_open(State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    ?IF(get_voluntarily_info() andalso Type =/= ?LOOP_VOLUNTARILY, ?THROW_ERR(?ERROR_MOD_ROLE_ACT_IT_BEGIN_TOC_002), ok),
    [AssetType, NeedGold, AddLuck, LimitLuck, MaxLimit|_] = common_misc:get_global_list(?GLOBAL_IDENTIFY_TREASURE),
    AssetDoings = mod_role_asset:check_asset_by_type(AssetType, NeedGold, ?ASSET_GOLD_IDENTIFY_TREASURE_BEGIN, State),
    OldFruitID = get_rare_reward(ItNum),

    case Luck >= LimitLuck of
        true ->
            #c_act_identify_treasure{reward = Reward, is_rare = IsRare} = get_identify_treasure(OldFruitID),
            AddGoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind} <- lib_tool:string_to_intlist(Reward)],
            #r_role{role_bag = RoleBag} = State,
            #p_bag_content{bag_grid = BagGrid, goods_list = GoodsList} = mod_role_bag:get_bag(?BAG_ID_BAG, RoleBag),
            ?IF(BagGrid >= erlang:length(GoodsList ++ AddGoodsList), ok, ?THROW_ERR(?ERROR_MOD_ROLE_ACT_IT_BEGIN_TOC_001)),
            State2 = role_misc:create_goods(State, ?ITEM_GAIN_IDENTIFY_TREASURE_RARE_REWARD, AddGoodsList);
        _ ->
            FruitID = filtrate_task(OldFruitID, Limit, MaxLimit),

            #c_act_identify_treasure{is_rare = IsRare, reward = Reward} = get_identify_treasure(FruitID),

            AddGoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind} <- lib_tool:string_to_intlist(Reward)],
            #r_role{role_bag = RoleBag} = State,
            #p_bag_content{bag_grid = BagGrid, goods_list = GoodsList} = mod_role_bag:get_bag(?BAG_ID_BAG, RoleBag),
            ?IF(BagGrid >= erlang:length(GoodsList ++ AddGoodsList), ok, ?THROW_ERR(?ERROR_MOD_ROLE_ACT_IT_BEGIN_TOC_001)),

            case IsRare =:= ?IS_RARE of
                true ->
                    State2 = role_misc:create_goods(State, ?ITEM_GAIN_IDENTIFY_TREASURE_RARE_REWARD, AddGoodsList);
                _ ->
                    State2 = role_misc:create_goods(State, ?ITEM_GAIN_IDENTIFY_TREASURE_ONE_REWARD, AddGoodsList)
            end
    end,
    {ok, IsRare, AddLuck, AssetDoings, State2}.

get_role_it(?IS_RARE, _AddLuck, RoleIt) ->
    set_voluntarily_info(false),
    #r_role_it{it_num = ItNum} = RoleIt,
    RoleIt#r_role_it{it_num = ItNum + 1, luck = 0, limit = 0};
get_role_it(_, AddLuck, RoleIt) ->
    #r_role_it{luck = Luck, limit = Limit} = RoleIt,
    RoleIt#r_role_it{luck = Luck + AddLuck, limit = Limit + 1}.

filtrate_task(FruitID, Limit, MaxLimit) ->
    NeedConfigNum = world_cycle_act_server:get_act_config_num(?CYCLE_ACT_IDENTIFY_TREASURE),
    AllList = lists:foldl(fun({ID, #c_act_identify_treasure{is_rare = IsRare, config_num = ConfigNum, weight = Weight}}, Acc) ->
        case ConfigNum =:= NeedConfigNum of
            true when IsRare =:= ?IS_RARE andalso Limit >= MaxLimit andalso FruitID =:= ID ->
                [{Weight, ID}|Acc];
            true when IsRare =:= ?IS_RARE andalso Limit < MaxLimit ->
                Acc;
            true when IsRare =/= ?IS_RARE ->
                [{Weight, ID}|Acc];
            _ ->
                Acc
        end end,          [], cfg_act_identify_treasure:list()),

    lib_tool:get_weight_output(AllList).

%% @doc 自动鉴宝
do_loop_begin(#r_role{role_attr = #r_role_attr{role_id = RoleID}} = State) ->
    case get_voluntarily_info() of
        true ->
            case is_battle_open(State) of
                true ->
                    do_it_begin(?LOOP_VOLUNTARILY, RoleID, State);
                _ ->
                    set_voluntarily_info(false),
                    State
            end;
        _ ->
            State
    end.

do_it_cease(RoleID, State) ->
    set_voluntarily_info(false),
    DataRecord = #mod_role_act_it_cease_toc{},
    common_misc:unicast(RoleID, DataRecord),
    State.

up_role_info(State) ->
    role_server:dump_table(?DB_ROLE_IT_P, State).
get_role_info(RoleID) ->
    case db:lookup(?DB_ROLE_IT_P, RoleID) of
        [#r_role_nature{} = RoleNature] ->
            RoleNature;
        _ ->
            #r_role_nature{role_id = RoleID}
    end.


get_identify_treasure(ID) ->
    [Config] = lib_config:find(cfg_act_identify_treasure, ID),
    Config.

is_battle_open(State) ->
    mod_role_cycle_act:is_act_open(?CYCLE_ACT_IDENTIFY_TREASURE, State).

%% @doc 设置自动鉴宝
set_voluntarily_info(Bool) ->
    erlang:put({?MODULE, voluntarily_info}, Bool).
get_voluntarily_info() ->
    case erlang:get({?MODULE, voluntarily_info}) of
        undefined ->
            false;
        Val ->
            Val
    end.
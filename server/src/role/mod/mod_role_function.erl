%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%% 系统功能开启
%%% @end
%%% Created : 10. 七月 2017 15:23
%%%-------------------------------------------------------------------
-module(mod_role_function).
-author("laijichang").
-include("role.hrl").
-include("confine.hrl").
-include("mission.hrl").
-include("proto/mod_role_function.hrl").
-define(DABAO_GLOBAL_ONE, 128).
-define(DABAO_GLOBAL_TWO, 129).

%% API
-export([
    init/1,
    pre_enter/1,
    handle/2
]).

-export([
    is_function_open/2,
    get_is_function_open/2,
    do_trigger_function/3
]).

-export([
    gm_trigger_function/1,
    gm_skill_open/1,
    gm_trigger_function2/2,
    gm_del_function/2,
    trigger_function/3
]).

-export([
    get_function_level/2
]).

init(#r_role{role_id = RoleID, role_function = undefined} = State) ->
    RoleFunction = #r_role_function{role_id = RoleID},
    State#r_role{role_function = RoleFunction};
init(State) ->
    State.

pre_enter(#r_role{role_id = RoleID, role_function = RoleFunction, role_attr = RoleAttr} = State) ->
    #r_role_function{id_list = IDList, reward_list = RewardList, got_dabao_reward = GotDabaoReward} = RoleFunction,
    common_misc:unicast(RoleID, #m_function_list_toc{op_type = ?FUNCTION_INFO_ONLINE, id_list = IDList, reward_list = RewardList}),
    [BanList] = lib_config:find(common, item_ban_list),
    case BanList =/= "" of
        true ->
            BanIDList = [lib_tool:to_integer(ItemString) || ItemString <- string:tokens(BanList, ",")],
            common_misc:unicast(RoleID, #m_ban_function_list_toc{id_list = BanIDList});
        _ ->
            ok
    end,
    [Config] = lib_config:find(cfg_global, ?DABAO_GLOBAL_TWO),
    CanGet = RoleAttr#r_role_attr.level >= Config#c_global.int andalso not GotDabaoReward,%%前端显示开了，没有领取 返回true"
    common_misc:unicast(RoleID, #m_da_bao_toc{can_get = CanGet}),
    State.

trigger_function(RoleID, Type, Args) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {trigger_function, Type, Args}}).

gm_trigger_function(State) ->
    AllList = cfg_function:list(),
    IDList = [ID || {ID, _Config} <- AllList],
    gm_trigger_function2(IDList, State).

gm_skill_open(State) ->
    AllList = cfg_function:list(),
    IDList = [ID || {ID, _Config} <- AllList, ID >= ?FUNCTION_SKILL_BEGIN andalso ID =< ?FUNCTION_SKILL_END],
    gm_trigger_function2(IDList, State).

gm_trigger_function2([], State) ->
    State;
gm_trigger_function2([ID|R], State) ->
    [Config] = lib_config:find(cfg_function, ID),
    #c_function{activate_type = ActivateType, activate_args = ActivateArgs} = Config,
    State2 = do_trigger_function(ActivateType, ActivateArgs, State),
    gm_trigger_function2(R, State2).

gm_del_function(FunctionID, State) ->
    #r_role{role_id = RoleID, role_function = RoleFunction} = State,
    #r_role_function{id_list = IDList} = RoleFunction,
    IDList2 = lists:delete(FunctionID, IDList),
    RoleFunction2 = RoleFunction#r_role_function{id_list = IDList2},
    State2 = State#r_role{role_function = RoleFunction2},
    common_misc:unicast(RoleID, #m_function_list_toc{op_type = ?FUNCTION_INFO_UPDATE, id_list = IDList2}),
    State2.

is_function_open(FunctionID, State) ->
    ?IF(get_is_function_open(FunctionID, State), true, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN)).

get_is_function_open(FunctionID, State) ->
    #r_role{role_function = RoleFunction} = State,
    #r_role_function{id_list = IDList} = RoleFunction,
    lists:member(FunctionID, IDList).

handle({#m_function_reward_tos{id = ID}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, State, ID);
handle({#m_da_bao_reward_tos{}, RoleID, _PID}, State) ->
    do_get_dabao_reward(RoleID, State);
handle({trigger_function, Type, Args}, State) ->
    do_trigger_function(Type, Args, State).


do_trigger_function(Type, Args, State) ->
    #r_role{role_id = RoleID, role_function = RoleFunction} = State,
    #r_role_function{id_list = IDList} = RoleFunction,
    AllList = cfg_function:list(),
    {IDList2, State2} = do_trigger_function2(AllList, State, Type, Args, IDList),
    case IDList2 =/= IDList of
        true ->
            common_misc:unicast(RoleID, #m_function_list_toc{op_type = ?FUNCTION_INFO_UPDATE, id_list = IDList2}),
            RoleFunction2 = RoleFunction#r_role_function{id_list = IDList2},
            State3 = State2#r_role{role_function = RoleFunction2},
            mod_role_mission:condition_update(State3);
        _ ->
            State2
    end.


do_trigger_function2([], State, _Type, _Args, IDList) ->
    {IDList, State};
do_trigger_function2([{ID, Config}|R], State, Type, Args, IDList) ->
    #c_function{
        activate_type = ActivateType,
        activate_args = ActivateArgs,
        function_args = FunctionArgs,
        letter_template_id = LetterTemplateID
    } = Config,
    case ActivateType =:= Type andalso (not lists:member(ID, IDList)) of
        true ->
            if
                ActivateType =:= ?FUNCTION_TYPE_LEVEL andalso Args >= ActivateArgs ->
                    case ID =:= ?FUNCTION_FAMILY_TEMPLE of
                        false ->

                            IDList2 = [ID|IDList],
                            State2 = do_trigger_function3(ID, FunctionArgs, LetterTemplateID, State);
                        _ ->
                            {IDList2, State2} = case world_data:get_family_temple() of
                                                    [] ->
                                                        {IDList, State};
                                                    _ ->
                                                        {[ID|IDList], do_trigger_function3(ID, FunctionArgs, LetterTemplateID, State)}
                                                end
                    end;
                ActivateType =:= ?FUNCTION_TYPE_MISSION andalso Args =:= ActivateArgs ->
                    IDList2 = [ID|IDList],
                    State2 = do_trigger_function3(ID, FunctionArgs, LetterTemplateID, State);
                ActivateType =:= ?FUNCTION_TYPE_KILL_MONSTER andalso Args =:= ActivateArgs ->
                    IDList2 = [ID|IDList],
                    State2 = do_trigger_function3(ID, FunctionArgs, LetterTemplateID, State);
                ActivateType =:= ?FUNCTION_TYPE_GOD_BOOK andalso Args =:= ActivateArgs ->
                    IDList2 = [ID|IDList],
                    State2 = do_trigger_function3(ID, FunctionArgs, LetterTemplateID, State);
                ActivateType =:= ?FUNCTION_TYPE_ITEM andalso Args =:= ActivateArgs ->
                    IDList2 = [ID|IDList],
                    State2 = do_trigger_function3(ID, FunctionArgs, LetterTemplateID, State);
                ActivateType =:= ?FUNCTION_TYPE_CONFINE andalso Args >= ActivateArgs ->
                    IDList2 = [ID|IDList],
                    State2 = do_trigger_function3(ID, FunctionArgs, LetterTemplateID, State);
                true -> %% 未定义的激活类型
                    IDList2 = IDList,
                    State2 = State
            end,
            do_trigger_function2(R, State2, Type, Args, IDList2);
        _ ->
            do_trigger_function2(R, State, Type, Args, IDList)
    end.


do_trigger_function3(ID, FunctionArgList, LetterTemplateID, #r_role{role_id = RoleID, role_attr = Attr} = State) ->
    [#c_function{open_reward = Reward}] = lib_config:find(cfg_function, ID),
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    State2 = role_misc:create_goods(State, ?ITEM_GAIN_OSS_FUNCTION, GoodsList),
    FunctionArgs = get_functionargs_id(FunctionArgList, Attr#r_role_attr.sex),
    ?IF(LetterTemplateID > 0, common_letter:send_letter(RoleID, #r_letter_info{template_id = LetterTemplateID}), ok),
    if
        ID =:= ?FUNCTION_MOUNT -> %% 坐骑
            mod_role_mount:function_open(FunctionArgs, State2);
        ID =:= ?FUNCTION_MAGIC_WEAPON -> %% 法宝
            mod_role_magic_weapon:function_open(FunctionArgs, State2);
        ID =:= ?FUNCTION_PET -> %% 宠物
            mod_role_pet:function_open(FunctionArgs, State2);
        ID =:= ?FUNCTION_GOD_WEAPON -> %% 神兵
            mod_role_god_weapon:function_open(FunctionArgs, State2);
        ID =:= ?FUNCTION_WING -> %% 翅膀
            mod_role_wing:function_open(FunctionArgs, State2);
%%        ID =:= ?FUNCTION_CONFINE -> %% 境界                  别删
%%            mod_role_confine:function_open(State2);
        ID =:= ?FUNCTION_BLESS -> %% 祈福
            mod_role_bless:function_open(State2);
%%        ID =:= ?FUNCTION_ACT_ONLIINE -> %%     在线奖励
%%            mod_role_act_online:function_open(State2);
        ID =:= ?FUNCTION_DAILY_LIVENESS -> %%  日常活跃
            mod_role_daily_liveness:function_open(State2);
        ID =:= ?FUNCTION_ZERO_PANICBUY -> %%  系统开放表
            mod_role_act_zero_panicbuy:function_open(State2);
        ID >= ?FUNCTION_SKILL_BEGIN andalso ID =< ?FUNCTION_SKILL_END -> %% 开启技能
            mod_role_skill:skill_open(FunctionArgs, State2);
        ID =:= ?FUNCTION_HANDBOOK ->                %% 图鉴开启
            mod_role_handbook:function_open(State2);
        ID =:= ?FUNCTION_FAIRY ->
            mod_role_escort:system_open(State2);
        ID =:= ?FUNCTION_THRONE ->                  %% 宝座开启
            mod_role_throne:function_open(State2);
        ID =:= ?FUNCTION_NATURE ->                  %% 天机印开启
            mod_role_nature:function_open(State2);
        ID =:= ?FUNCTION_NEW_ALCHEMY ->                  %% 凡品炼丹炉
            mod_role_bg_new_alchemy:function_open(State2);
        ID =:= ?FUNCTION_MONEY_TREE ->
            mod_role_money_tree:function_open(State2);
        ID =:= ?FUNCTION_UNIVERSE ->
            mod_role_universe:function_open(State2);
        true ->
            State2
    end.


get_functionargs_id(FunctionArgList, Sex) ->
    case FunctionArgList of
        [] ->
            0;
        [FunctionArg] ->
            FunctionArg;
        [FunctionArg2, FunctionArg3] ->
            ?IF(Sex =:= ?SEX_GIRL, FunctionArg2, FunctionArg3)
    end.

get_function_level(FunctionID, DefaultValue) ->
    case lib_config:find(cfg_function, FunctionID) of
        [#c_function{activate_type = ?FUNCTION_TYPE_LEVEL, activate_args = ActiveLevel}] ->
            ActiveLevel;
        [#c_function{activate_type = ?FUNCTION_TYPE_MISSION, activate_args = MissionID}] ->
            case lib_config:find(cfg_mission, MissionID) of
                [#c_mission{min_level = MinLevel}] ->
                    MinLevel;
                _ ->
                    DefaultValue
            end;
        _ ->
            DefaultValue
    end.

do_get_reward(RoleID, State, ID) ->
    case catch check_can_get(State, ID) of
        {ok, State2, BagDoings} ->
            State4 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_function_reward_toc{id = ID}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_function_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get(#r_role{role_function = RoleFunction} = State, ID) ->
    ?IF(lists:member(ID, RoleFunction#r_role_function.id_list), ok, ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN)),
    ?IF(lists:member(ID, RoleFunction#r_role_function.reward_list), ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN), ok),
    [Config] = lib_config:find(cfg_function, ID),
    ?IF(Config#c_function.is_preview =:= 1, ok, ?THROW_ERR(1)),
    GoodsList = [#p_goods{type_id = ItemType, num = ItemNum, bind = true} || {ItemType, ItemNum} <- lib_tool:string_to_intlist(Config#c_function.reward)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_OSS_FUNCTION, GoodsList}],
    RoleFunction2 = RoleFunction#r_role_function{reward_list = [ID|RoleFunction#r_role_function.reward_list]},
    {ok, State#r_role{role_function = RoleFunction2}, BagDoings}.


do_get_dabao_reward(RoleID, State) ->
    case catch check_can_get(State) of
        {ok, State2, BagDoings} ->
            State4 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_da_bao_reward_toc{}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_da_bao_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get(#r_role{role_function = RoleFunction} = State) ->
    ?IF(not RoleFunction#r_role_function.got_dabao_reward andalso lists:member(?FUNCTION_DABAO, RoleFunction#r_role_function.id_list), ok, ?THROW_ERR(?ERROR_DA_BAO_REWARD_001)),
    [Config] = lib_config:find(cfg_global, ?DABAO_GLOBAL_ONE),
    GoodsList = [#p_goods{type_id = ItemType, num = ItemNum} || {ItemType, ItemNum} <- lib_tool:string_to_intlist(Config#c_global.string, ",", ":")],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_DABAO, GoodsList}],
    RoleFunction2 = RoleFunction#r_role_function{got_dabao_reward = true},
    {ok, State#r_role{role_function = RoleFunction2}, BagDoings}.
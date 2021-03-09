%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     天书系统
%%% @end
%%% Created : 03. 七月 2018 17:41
%%%-------------------------------------------------------------------
-module(mod_role_god_book).
-author("laijichang").
-include("role.hrl").
-include("suit.hrl").
-include("god_book.hrl").
-include("proto/mod_role_god_book.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    gm_set_type/2
]).

-export([
    fight_attr_change/3,
    load_equip/2,
    kill_world_boss/2,
    first_recharge/1,
    month_card/1,
    invest/1,
    vip_level/2,
    load_decoration/1,
    activate_fashion/1,
    load_suit_equip/2,
    pos_suit/4
]).

init(#r_role{role_id = RoleID, role_god_book = undefined} = State) ->
    RoleGodBook = #r_role_god_book{role_id = RoleID},
    State#r_role{role_god_book = RoleGodBook};
init(State) ->
    State.

online(State) ->
    #r_role{role_id = RoleID, role_god_book = RoleGodBook} = State,
    #r_role_god_book{doing_list = DoingList, reward_list = RewardList, type_reward_list = TypeRewardList} = RoleGodBook,
    common_misc:unicast(RoleID, #m_god_book_info_toc{doing_list = DoingList, reward_list = RewardList, type_reward_list = TypeRewardList}),
    State.

%% 防御达到xx
fight_attr_change(OldFightAttr, FightAttr, State) ->
    OldDefence = OldFightAttr#actor_fight_attr.defence,
    Defence = FightAttr#actor_fight_attr.defence,
    case Defence > OldDefence of
        true ->
            trigger_god_book(?GOD_BOOK_CONDITION_DEFENCE, Defence, State);
        _ ->
            State
    end.

%% 装备
load_equip(Args, State) ->
    trigger_god_book(?GOD_BOOK_CONDITION_EQUIP, Args, State).

%% 击杀世界boss
kill_world_boss(TypeID, State) ->
    trigger_god_book(?GOD_BOOK_CONDITION_KILL_MONSTER, TypeID, State).

%% 首充
first_recharge(State) ->
    trigger_god_book(?GOD_BOOK_CONDITION_FIRST_RECHARGE, 1, State).

%% 月卡投资
month_card(State) ->
    trigger_god_book(?GOD_BOOK_CONDITION_MONTH_CARD, 1, State).

%% 投资计划
invest(State) ->
    trigger_god_book(?GOD_BOOK_CONDITION_INVEST, 1, State).

%% VIP等级达到XX
vip_level(VipLevel, State) ->
    trigger_god_book(?GOD_BOOK_CONDITION_VIP_LEVEL, VipLevel, State).

activate_fashion(State) ->
    trigger_god_book(?GOD_BOOK_CONDITION_ACTIVATE_FASHION, 1, State).

%% 穿戴饰品
load_decoration(State) ->
    trigger_god_book(?GOD_BOOK_CONDITION_DECORATION, 1, State).

%% 穿戴套装
load_suit_equip(_Args, State) ->
    State.

pos_suit(SubType, Type, NumStepList, State) ->
    lists:foldl(
        fun({Num, Step}, StateAcc) ->
            ConditionType =
                if
                    Type =:= ?BIG_TYPE_THUNDER andalso SubType =:= ?SUIT_SUB_TYPE_LEFT -> %% 雷劫
                        if
                            Step =:= 1 ->
                                ?GOD_BOOK_CONDITION_THUNDER_LEFT_ONE;
                            Step =:= 2 ->
                                ?GOD_BOOK_CONDITION_THUNDER_LEFT_TWO;
                            Step =:= 3 ->
                                ?GOD_BOOK_CONDITION_THUNDER_LEFT_THREE;
                            Step =:= 4 ->
                                ?GOD_BOOK_CONDITION_THUNDER_LEFT_FOUR;
                            true ->
                                0
                        end;
                    Type =:= ?BIG_TYPE_THUNDER andalso SubType =:= ?SUIT_SUB_TYPE_RIGHT -> %% 雷霆
                        if
                            Step =:= 1 ->
                                ?GOD_BOOK_CONDITION_THUNDER_RIGHT_ONE;
                            Step =:= 2 ->
                                ?GOD_BOOK_CONDITION_THUNDER_RIGHT_TWO;
                            true ->
                                0
                        end;
                    true ->
                        0
                end,
            ?IF(ConditionType > 0, trigger_god_book(ConditionType, Num, StateAcc), StateAcc)
        end, State, NumStepList).

gm_set_type(Type, State) ->
    [IDList] = lib_config:find(cfg_god_book, {type, Type}),
    #r_role{role_god_book = RoleGodBook} = State,
    #r_role_god_book{doing_list = DoingList} = RoleGodBook,
    DoingList2 =
        lists:foldl(
            fun(ID, DoingAcc) ->
                [#c_god_book{condition_args = Args}] = lib_config:find(cfg_god_book, ID),
                Doing = #p_kvl{id = ID, list = Args},
                lists:keystore(ID, #p_kvl.id, DoingAcc, Doing)
            end, DoingList, IDList),
    RoleGodBook2 = RoleGodBook#r_role_god_book{doing_list = DoingList2},
    State2 = State#r_role{role_god_book = RoleGodBook2},
    online(State2).

handle({trigger, Type, Args}, State) ->
    trigger_god_book(Type, Args, State);
handle({#m_god_book_reward_tos{id = ID}, RoleID, _PID}, State) ->
    do_reward(RoleID, ID, State);
handle({#m_god_book_type_tos{type_id = TypeID}, RoleID, _PID}, State) ->
    do_type_reward(RoleID, TypeID, State).

do_reward(RoleID, ID, State) ->
    case catch check_reward(ID, State) of
        {ok, BagDoings, _IsAllFinish, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_god_book_reward_toc{id = ID}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_god_book_reward_toc{err_code = ErrCode}),
            State
    end.

check_reward(ID, State) ->
    [#c_god_book{
        type = Type,
        condition_args = ConditionArgs,
        reward_goods = RewardGoods}] = lib_config:find(cfg_god_book, ID),
    #r_role{role_god_book = RoleGodBook} = State,
    #r_role_god_book{doing_list = DoingList, reward_list = RewardList} = RoleGodBook,
    ?IF(lists:member(ID, RewardList), ?THROW_ERR(?ERROR_GOD_BOOK_REWARD_001), ok),
    case lists:keyfind(ID, #p_kvl.id, DoingList) of
        #p_kvl{} = Doing ->
            ok;
        _ ->
            Doing = ?THROW_ERR(?ERROR_GOD_BOOK_REWARD_002)
    end,
    #p_kvl{list = DoingArgs} = Doing,
    ?IF((ConditionArgs -- DoingArgs) =:= [], ok, ?THROW_ERR(?ERROR_GOD_BOOK_REWARD_002)),
    GoodsList = [ #p_goods{type_id = TypeID, num = Num, bind = true}|| {TypeID, Num} <- common_misc:get_item_reward(RewardGoods)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_GOD_BOOK, GoodsList}],
    RewardList2 = [ID|RewardList],
    [AllList] = lib_config:find(cfg_god_book, {type, Type}),
    IsAllFinish = (AllList -- RewardList2) =:= [],
    RoleGodBook2 = RoleGodBook#r_role_god_book{reward_list = RewardList2},
    State2 = State#r_role{role_god_book = RoleGodBook2},
    {ok, BagDoings, IsAllFinish, State2}.

do_type_reward(RoleID, TypeID, State) ->
    case catch check_type_reward(TypeID, State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_god_book_type_toc{type_id = TypeID}),
            State3 = mod_role_function:do_trigger_function(?FUNCTION_TYPE_GOD_BOOK, TypeID, State2),
            [#c_god_book_type{skill = SkillID}] = lib_config:find(cfg_god_book_type, TypeID),
            [SkillDetail] = lib_config:find(cfg_skill, SkillID),
            #c_skill{skill_name = SkillName} = SkillDetail,
            common_broadcast:send_world_common_notice(?NOTICE_GOD_BOOK_OPEN, [mod_role_data:get_role_name(State), SkillName]), %% T 发激活天书技能公告
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_god_book_type_toc{err_code = ErrCode}),
            State
    end.

check_type_reward(TypeID, State) ->
    #r_role{role_god_book = RoleGodBook} = State,
    #r_role_god_book{doing_list = DoingList, type_reward_list = TypeRewardList} = RoleGodBook,
    ?IF(lists:member(TypeID, TypeRewardList), ?THROW_ERR(?ERROR_GOD_BOOK_TYPE_001), ok),
    case lib_config:find(cfg_god_book_type, TypeID) of
        [#c_god_book_type{}] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    [NeedList] = lib_config:find(cfg_god_book, {type, TypeID}),
    [ begin
          case lists:keyfind(ID, #p_kvl.id, DoingList) of
              #p_kvl{list = DoingArgs} ->
                  [#c_god_book{condition_args = ConditionArgs}] = lib_config:find(cfg_god_book, ID),
                  ?IF((ConditionArgs -- DoingArgs) =:= [], ok, ?THROW_ERR(?ERROR_GOD_BOOK_TYPE_002));
              _ ->
                  ?THROW_ERR(?ERROR_GOD_BOOK_TYPE_002)
          end
      end || ID <- NeedList],
    RoleGodBook2 = RoleGodBook#r_role_god_book{type_reward_list = [TypeID|TypeRewardList]},
    State2 = State#r_role{role_god_book = RoleGodBook2},
    {ok, State2}.

trigger_god_book(ConditionType, Args, State) ->
    case catch trigger(ConditionType, Args, State) of
        #r_role{} = State2 ->
            State2;
        Error ->
            ?ERROR_MSG("Error:~w", [Error]),
            State
    end.
trigger(ConditionType, Args, State) ->
    #r_role{role_id = RoleID, role_god_book = RoleGodBook} = State,
    #r_role_god_book{doing_list = DoingList, reward_list = RewardList} = RoleGodBook,
    case lib_config:find(cfg_god_book, {condition_type, ConditionType}) of
        [TypeIDList] ->
            {DoingList2, Updates} = trigger2(TypeIDList, Args, State, RewardList, DoingList, []),
            RoleGodBook2 = RoleGodBook#r_role_god_book{doing_list = DoingList2},
            State2 = State#r_role{role_god_book = RoleGodBook2},
            ?IF(Updates =/= [], common_misc:unicast(RoleID, #m_god_book_update_toc{doing = Updates}), ok),
            State2;
        _ ->
            State
    end.

trigger2([], _Args, _State, _RewardList, DoingAcc, UpdateAcc) ->
    {DoingAcc, UpdateAcc};
trigger2([{_Type, IDList}|R], Args, State, RewardList, DoingAcc, UpdateAcc) ->
    {DoingAcc2, UpdateList} = trigger3(IDList, Args, State, RewardList, DoingAcc, []),
    trigger2(R, Args, State, RewardList, DoingAcc2, UpdateList ++ UpdateAcc).

trigger3([], _Args, _State, _RewardList, DoingAcc, UpdateAcc) ->
    {DoingAcc, UpdateAcc};
trigger3([ID|R], Args, State, RewardList, DoingAcc, UpdateAcc) ->
    case lists:member(ID, RewardList) of
        true ->
            trigger3(R, Args, State, RewardList, DoingAcc, UpdateAcc);
        _ ->
            [#c_god_book{condition_type = ConditionType, condition_args = ConditionArgs}] = lib_config:find(cfg_god_book, ID),
            case lists:keytake(ID, #p_kvl.id, DoingAcc) of
                {value, #p_kvl{list = DoingArgs} = Doing, DoingList} ->
                    case (ConditionArgs -- DoingArgs) =:= [] of %% 已经满足条件了
                        true ->
                            trigger3(R, Args, State, RewardList, DoingAcc, UpdateAcc);
                        _ ->
                            Doing2 = get_condition_doing(ConditionType, ConditionArgs, Args, State, Doing),
                            DoingAcc2 = [Doing2|DoingList],
                            UpdateAcc2 = ?IF(Doing2 =/= Doing, [Doing2|UpdateAcc], UpdateAcc),
                            trigger3(R, Args, State, RewardList, DoingAcc2, UpdateAcc2)
                    end;
                _ ->
                    Doing = #p_kvl{id = ID},
                    Doing2 = get_condition_doing(ConditionType, ConditionArgs, Args, State, Doing),
                    {UpdateAcc2, DoingAcc2} = ?IF(Doing2 =/= Doing, {[Doing2|UpdateAcc], [Doing2|DoingAcc]}, {UpdateAcc, DoingAcc}),
                    trigger3(R, Args, State, RewardList, DoingAcc2, UpdateAcc2)
            end
    end.

get_condition_doing(?GOD_BOOK_CONDITION_DEFENCE, ConditionArgs, Args, _State, Doing) ->
    [NeedDefence] = ConditionArgs,
    ?IF(Args >= NeedDefence, Doing#p_kvl{list = ConditionArgs}, Doing);
get_condition_doing(?GOD_BOOK_CONDITION_EQUIP, [TypeID], [Index, Quality, Step], _State, Doing) ->
    #c_item{type_id = EquipID} = mod_role_item:get_item_config(TypeID),
    [#c_equip{index = NeedIndex, quality = NeedQuality, step = NeedStep}] = lib_config:find(cfg_equip, EquipID),
    case NeedIndex =:= Index andalso Quality >= NeedQuality andalso Step >= NeedStep of
        true ->
            Doing#p_kvl{list = [TypeID]};
        _ ->
            Doing
    end;
get_condition_doing(?GOD_BOOK_CONDITION_KILL_MONSTER, ConditionArgs, Args, _State, Doing) ->
    case lists:member(Args, ConditionArgs) of
        true ->
            #p_kvl{list = DoingArgs} = Doing,
            ?IF(lists:member(Args, DoingArgs), Doing, Doing#p_kvl{list = [Args|DoingArgs]});
        _ ->
            Doing
    end;
get_condition_doing(?GOD_BOOK_CONDITION_FIRST_RECHARGE, ConditionArgs, _Args, _State, Doing) ->
    Doing#p_kvl{list = ConditionArgs};
get_condition_doing(?GOD_BOOK_CONDITION_MONTH_CARD, ConditionArgs, _Args, _State, Doing) ->
    Doing#p_kvl{list = ConditionArgs};
get_condition_doing(?GOD_BOOK_CONDITION_INVEST, ConditionArgs, _Args, _State, Doing) ->
    Doing#p_kvl{list = ConditionArgs};
get_condition_doing(?GOD_BOOK_CONDITION_VIP_LEVEL, ConditionArgs, Args, _State, Doing) ->
    [NeedVipLevel] = ConditionArgs,
    ?IF(Args >= NeedVipLevel, Doing#p_kvl{list = ConditionArgs}, Doing);
get_condition_doing(?GOD_BOOK_CONDITION_DECORATION, ConditionArgs, _Args, _State, Doing) ->
    Doing#p_kvl{list = ConditionArgs};
get_condition_doing(?GOD_BOOK_CONDITION_ACTIVATE_FASHION, ConditionArgs, _Args, _State, Doing) ->
    Doing#p_kvl{list = ConditionArgs};
get_condition_doing(Condition, ConditionArgs, Args, _State, Doing) when ?GOD_BOOK_CONDITION_THUNDER_LEFT_ONE =< Condition andalso Condition =< ?GOD_BOOK_CONDITION_THUNDER_RIGHT_TWO ->
    [NeedNum] = ConditionArgs,
    ?IF(Args >= NeedNum, Doing#p_kvl{list = ConditionArgs}, Doing#p_kvl{list = [Args]}).
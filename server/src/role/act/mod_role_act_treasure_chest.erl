%%%-------------------------------------------------------------------
%%% @author chenqinyong
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 十月 2019 14:10
%%%-------------------------------------------------------------------
-module(mod_role_act_treasure_chest).
-author("chenqinyong").
-include("role.hrl").
-include("cycle_act.hrl").
-include("pay.hrl").
-include("behavior_log.hrl").
-include("treasure_chest.hrl").
-include("proto/mod_role_act_treasure_chest.hrl").
%% API
-export([
    init/1,
    init_data/2,
    do_recharge/2,
    online/1,
    handle/2,
    do_chest_end/1,
    get_config_by_id_and_config_num/4
]).

init(#r_role{role_id = RoleID, role_act_treasure_chest = undefined} = State) ->
    TreasureChest = #r_role_act_treasure_chest{role_id = RoleID},
    State#r_role{role_act_treasure_chest = TreasureChest};
init(State) ->
    State.

init_data(StartTime, State) ->
    RewardStatus = get_reward_status(State),
    case RewardStatus =:= [] of
        false ->
            State2 = do_chest_end(State),
            State3 = init_data2(StartTime, State2),
            online(State3);
        _ ->
            State2 = init_data2(StartTime, State),
            online(State2)
    end.

init_data2(StartTime, State) ->
    ConfigNum = get_config_num(),
    TreasureChest = #r_role_act_treasure_chest{
        role_id = State#r_role.role_id,
        accrecharge = 0,
        reward = get_rewards_by_config_num(ConfigNum),
        config_num = ConfigNum,
        open_time = StartTime
    },
    State#r_role{role_act_treasure_chest = TreasureChest}.

online(#r_role{role_id = RoleID, role_act_treasure_chest = TreasureChest} = State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_TREASURE_CHEST, State) of
        true ->
            case TreasureChest of
                #r_role_act_treasure_chest{role_id = RoleID, accrecharge = AccRecharge, reward = Reward} ->
                    common_misc:unicast(RoleID, #m_treasure_chest_toc{accrecharge = AccRecharge, reward = Reward}),
                    State;
                _ ->
                    State
            end;
        _ ->
            RewardStatus = get_reward_status(State),
            case RewardStatus =:= [] of
                false ->
                    do_chest_end(State);
                _ ->
                    State
            end
    end.

get_change_status(AccRecharge, Reward) ->
    ConfigList = lib_config:list(cfg_act_treasure_chest),
    ConfigNum = get_config_num(),
    List = [Config || {_ID, #c_act_treasure_chest{config_num = NeedConfigNum} = Config} <- ConfigList, ConfigNum =:= NeedConfigNum],
    Reward2 = lists:foldl(
        fun(#c_act_treasure_chest{id = ID}, Acc) ->
            Config = get_config_by_id_and_config_num(ConfigList, ID, #c_act_treasure_chest.id, #c_act_treasure_chest.config_num),
            #c_act_treasure_chest{need_recharge = NeedRecharge} = Config,
            case lists:keyfind(ID, #p_kv.id, Reward) of
                #p_kv{val = Val} ->
                    case AccRecharge >= NeedRecharge andalso Val =:= ?TREASURE_CHEST_CANNOT_REWARD of
                        true ->
                            lists:keystore(ID, #p_kv.id, Acc, #p_kv{id = ID, val = ?TREASURE_CHEST_CAN_REWARD});
                        _ ->
                            Acc
                    end;
                _ ->
                    Acc
            end
        end, Reward, List),
    Reward2.

do_recharge(State, PayFee) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_TREASURE_CHEST, State)  of
        true ->
            #r_role{role_act_treasure_chest = TreasureChest} = State,
            #r_role_act_treasure_chest{accrecharge = AccRecharge,reward = Reward} = TreasureChest,
            AccRecharge2 = AccRecharge + lib_tool:to_integer(PayFee / 100),
            Reward2 = get_change_status(AccRecharge2, Reward),
            TreasureChest2 = TreasureChest#r_role_act_treasure_chest{accrecharge = AccRecharge2, reward = Reward2},
            State2 = State#r_role{role_act_treasure_chest = TreasureChest2},
            online(State2);
        _ ->
            State
    end.

handle({#m_treasure_chest_reward_tos{id = ID}, RoleID, _PID}, State) ->
    do_reward(RoleID, ID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

do_reward(RoleID, ID, State) ->
    case catch check_do_reward(ID, State) of
        {ok, BagDoings, Reward2, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_treasure_chest_reward_toc{reward = Reward2}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_treasure_chest_reward_toc{err_code = ErrCode}),
            State
    end.

check_do_reward(ID, State) ->
    #r_role{role_act_treasure_chest = TreasureChest} = State,
    #r_role_act_treasure_chest{accrecharge = AccRecharge, reward = Reward} = TreasureChest,
    ConfigList = lib_config:list(cfg_act_treasure_chest),
    Config = get_config_by_id_and_config_num(ConfigList, ID, #c_act_treasure_chest.id, #c_act_treasure_chest.config_num),
    #c_act_treasure_chest{need_recharge = NeedRecharge, reward_list = RewardList} = Config,
    case lists:keytake(ID, #p_kv.id, Reward) of
        {value, Pkv, Other} ->
            case AccRecharge >= NeedRecharge of
                true ->
                    ?IF(Pkv#p_kv.val =:= ?TREASURE_CHEST_CAN_REWARD, ok, ?THROW_ERR(?ERROR_TREASURE_CHEST_REWARD_002)),
                    RewardList2 = lib_tool:string_to_intlist(RewardList),
                    RewardList3 = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- RewardList2],
                    mod_role_bag:check_bag_empty_grid(RewardList3, State),
                    BagDoings = [{create, ?ITEM_GAIN_ACT_TREASURE_CHEST, RewardList3}],
                    Reward2 = [#p_kv{id = ID, val = ?TREASURE_CHEST_HAS_REWARD}|Other],
                    TreasureChest2 = TreasureChest#r_role_act_treasure_chest{reward = Reward2},
                    State2 = State#r_role{role_act_treasure_chest = TreasureChest2},
                    {ok, BagDoings, Reward2, State2};
                _ ->
                    ?THROW_ERR(?ERROR_TREASURE_CHEST_REWARD_001)
            end;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end.

do_chest_end(State) ->
    #r_role{role_act_treasure_chest = TreasureChest} = State,
    #r_role_act_treasure_chest{reward = Reward} = TreasureChest,
    RewardStatus = get_reward_status(State),
    case RewardStatus =:= [] of
        false ->
            do_chest_end2(RewardStatus, State);
        _ ->
            ok
    end,
    Reward2 = set_reward_status(Reward, []),
    TreasureChest2 = TreasureChest#r_role_act_treasure_chest{reward = Reward2},
    State#r_role{role_act_treasure_chest = TreasureChest2}.

set_reward_status([], Acc) ->
    Acc;
set_reward_status([#p_kv{id = ID, val = Val} | R], Acc) ->
    Val2 =
        case Val =/= ?TREASURE_CHEST_HAS_REWARD of
            true ->
                ?TREASURE_CHEST_HAS_REWARD;
            _ ->
                Val
        end,
    set_reward_status(R, [#p_kv{id = ID, val = Val2} | Acc]).

do_chest_end2([], _State) ->
    ok;
do_chest_end2([{ID, Val} | R], State) ->
    #r_role{role_id = RoleID, role_act_treasure_chest = TreasureChest} = State,
    ConfigList = lib_config:list(cfg_act_treasure_chest),
    #r_role_act_treasure_chest{accrecharge = AccRecharge} = TreasureChest,
    case Val =:= ?TREASURE_CHEST_HAS_REWARD of
        false ->
            Config = get_config_by_id_and_config_num2(ConfigList, ID, #c_act_treasure_chest.id, #c_act_treasure_chest.config_num, State),
            #c_act_treasure_chest{need_recharge = NeedRecharge, reward_list = RewardList,name = Name} = Config,
            case AccRecharge >= NeedRecharge of
                true ->
                    RewardList2 = lib_tool:string_to_intlist(RewardList),
                    GoodsList3 = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(ItemBind)} || {TypeID, Num, ItemBind} <- RewardList2],
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_ACT_TREASURE_CHEST,
                        action = ?ITEM_GAIN_ACT_TREASURE_CHEST,
                        goods_list = GoodsList3,
                        text_string = [Name]
                    },
                    common_letter:send_letter(RoleID, LetterInfo),
                    do_chest_end2(R, State);
                _ ->
                    do_chest_end2(R, State)
            end;
        _ ->
            do_chest_end2(R, State)
    end.

get_reward_status(State) ->
    #r_role{role_act_treasure_chest = TreasureChest} = State,
    #r_role_act_treasure_chest{reward = Reward} = TreasureChest,
    List = lists:foldl(
        fun(#p_kv{id = ID, val = Val}, Acc) ->
            case Val =:= ?TREASURE_CHEST_HAS_REWARD of
                false ->
                    [{ID, Val} | Acc];
                _ ->
                    Acc
            end
        end,[], Reward),
    List.

get_rewards_by_config_num(ConfigNum) ->
    List = cfg_act_treasure_chest:list(),
    List2 = [#p_kv{id = Config#c_act_treasure_chest.id, val = ?TREASURE_CHEST_CANNOT_REWARD} || {_, #c_act_treasure_chest{config_num = NeedConfigNum} = Config} <- List,NeedConfigNum =:= ConfigNum],
    #p_kv{id = ID, val = ?TREASURE_CHEST_CANNOT_REWARD} = lists:nth(1, List2),
    List3 = lists:keystore(ID, #p_kv.id, List2, #p_kv{id = ID, val = ?TREASURE_CHEST_CAN_REWARD}),
    List3.

get_config_num() ->
    world_cycle_act_server:get_act_config_num(?CYCLE_ACT_TREASURE_CHEST).

get_config_by_id_and_config_num(ConfigList, ID, Index, ConfigNumIndex) ->
    ConfigNum = get_config_num(),
    get_config_by_id_and_config_num(ConfigList, ID, Index, ConfigNum, ConfigNumIndex).

get_config_by_id_and_config_num([], ID, _Index, ConfigNum, _ConfigNumIndex) ->
    ?ERROR_MSG("unknow ID:~p and ConfigIndex:~p", [ID, ConfigNum]),
    error;
get_config_by_id_and_config_num([{_, Config}|R], ID, Index, ConfigNum, ConfigNumIndex) ->
    case Config#c_act_treasure_chest.config_num =:= ConfigNum andalso Config#c_act_treasure_chest.id =:= ID of
        true ->
            Config;
        _ ->
            get_config_by_id_and_config_num(R, ID, Index, ConfigNum, ConfigNumIndex)
    end.

get_config_by_id_and_config_num2(ConfigList, ID, Index, ConfigNumIndex, State) ->
    #r_role{role_act_treasure_chest = TreasureChest} = State,
    #r_role_act_treasure_chest{config_num = ConfigNum} = TreasureChest,
    get_config_by_id_and_config_num2(ConfigList, ID, Index, ConfigNum, ConfigNumIndex, State).

get_config_by_id_and_config_num2([], ID, _Index, ConfigNum, _ConfigNumIndex, _State) ->
    ?ERROR_MSG("unknow ID:~p and ConfigIndex:~p", [ID, ConfigNum]),
    error;
get_config_by_id_and_config_num2([{_, Config}|R], ID, Index, ConfigNum, ConfigNumIndex, _State) ->
    case Config#c_act_treasure_chest.config_num =:= ConfigNum andalso Config#c_act_treasure_chest.id =:= ID of
        true ->
            Config;
        _ ->
            get_config_by_id_and_config_num2(R, ID, Index, ConfigNum, ConfigNumIndex, _State)
    end.
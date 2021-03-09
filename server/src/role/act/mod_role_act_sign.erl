%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     每日签到活动
%%% @end
%%% Created : 28. 四月 2018 15:18
%%%-------------------------------------------------------------------
-module(mod_role_act_sign).
-author("laijichang").
-include("role.hrl").
-include("act.hrl").
-include("proto/mod_role_act_sign.hrl").

%% API
-export([
    init/1,
    day_reset/1,
    zero/1,
    online/1,
    handle/2
]).

init(#r_role{role_id = RoleID, role_act_sign = undefined} = State) ->
    RoleActSign = #r_role_act_sign{role_id = RoleID},
    State#r_role{role_act_sign = RoleActSign};
init(State) ->
    State.

day_reset(State) ->
    #r_role{role_act_sign = RoleActSign} = State,
    #r_role_act_sign{sign_times = SignTimes, times_reward_list = TimeRewardList} = RoleActSign,
    SignTimes2 =
    if
        SignTimes < 0 ->
            ?IF(mod_role_act_seven:is_all_reward(State), 0, SignTimes);
        true ->
            case lib_config:find(cfg_act_sign_daily, SignTimes + 1) of
                [_Config] ->
                    SignTimes;
                _ -> %% 下一天的签到奖励没有了
                    0
            end
    end,
    %% 第30天，次数奖励会重置
    TimeRewardList2 = ?IF(SignTimes2 rem 30 =:= 0, [], TimeRewardList),
    RoleActSign2 = RoleActSign#r_role_act_sign{
        is_sign = false,
        sign_times = SignTimes2,
        times_reward_list = TimeRewardList2},
    State#r_role{role_act_sign = RoleActSign2}.

zero(State) ->
    online(State).

online(State) ->
    #r_role{role_id = RoleID, role_act_sign = RoleActSign} = State,
    #r_role_act_sign{
        is_sign = IsSign,
        sign_times = SignTimes,
        times_reward_list = TimesList} = RoleActSign,
    case SignTimes >= 0 of
        true ->
            DataRecord = #m_act_sign_info_toc{
                is_sign = IsSign,
                sign_times = SignTimes,
                times_reward_list = TimesList
            },
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end,
    State.

handle({#m_act_sign_tos{}, RoleID, _PID}, State) ->
    do_sign(RoleID, State);
handle({#m_act_sign_reward_tos{times = Times}, RoleID, _PID}, State) ->
    do_reward(RoleID, Times, State).

do_sign(RoleID, State) ->
    case catch check_can_sign(State) of
        {ok, SignTimes, BagDoings, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_act_sign_toc{is_sign = true, sign_times = SignTimes}),
            State4 = mod_role_achievement:sign(State3),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_sign_toc{err_code = ErrCode}),
            State
    end.

check_can_sign(State) ->
    #r_role{role_act_sign = RoleActSign} = State,
    #r_role_act_sign{is_sign = IsSign, sign_times = SignTimes} = RoleActSign,
    ?IF(IsSign, ?THROW_ERR(?ERROR_ACT_SIGN_001), ok),
    SignTimes2 = SignTimes + 1,
    BagDoings = get_sign_reward(SignTimes2, ?ITEM_GAIN_ACT_SIGN, State),
    RoleActSign2 = RoleActSign#r_role_act_sign{is_sign = true, sign_times = SignTimes2},
    State2 = State#r_role{role_act_sign = RoleActSign2},
    {ok, SignTimes2, BagDoings, State2}.

do_reward(RoleID, Times, State) ->
    case catch check_can_reward(Times, State) of
        {ok, BagDoings, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_act_sign_reward_toc{times = Times}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_sign_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_reward(Times, State) ->
    #r_role{role_act_sign = RoleActSign} = State,
    #r_role_act_sign{is_sign = IsSign, times_reward_list = TimesList, sign_times = SignTimes} = RoleActSign,
    ?IF(lists:member(Times, TimesList), ?THROW_ERR(?ERROR_ACT_SIGN_REWARD_001), ok),
    Rem = SignTimes rem 30,
    if
        Rem =:= 0 -> %% 刚刚好最后一天，只要没领的都可以！！
            ?IF(IsSign andalso SignTimes > 0, ok, ?THROW_ERR(?ERROR_ACT_SIGN_REWARD_002));
        true ->
            ?IF(Rem >= Times, ok, ?THROW_ERR(?ERROR_ACT_SIGN_REWARD_002))
    end,
    case lib_config:find(cfg_act_sign_reward, Times) of
        [Config] ->
            #c_act_sign_reward{item_rewards = ItemRewards} = Config;
        _ ->
            ItemRewards =  ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    GoodsList = [ #p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(ItemRewards)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_TIMES_REWARD, GoodsList}],
    TimesList2 = [Times|TimesList],
    RoleActSign2 = RoleActSign#r_role_act_sign{times_reward_list = TimesList2},
    State2 = State#r_role{role_act_sign = RoleActSign2},
    {ok, BagDoings, State2}.

get_sign_reward(Day, Action, State) ->
    [#c_act_sign_daily{
        item_reward = ItemRewards,
        vip_level = VipLevel,
        multi = Multi
    }] = lib_config:find(cfg_act_sign_daily, Day),
    ItemRewards2 = common_misc:get_item_reward(ItemRewards),
    Multi2 = ?IF(mod_role_vip:get_vip_level(State) >= VipLevel, erlang:max(Multi, 1), 1),
    GoodsList = [ #p_goods{type_id = TypeID, num = Num * Multi2} || {TypeID, Num} <- ItemRewards2],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    [{create, Action, GoodsList}].





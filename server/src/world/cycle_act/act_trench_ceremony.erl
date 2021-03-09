%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 九月 2019 15:53
%%%-------------------------------------------------------------------
-module(act_trench_ceremony).
-author("chenqinyong").
-include("global.hrl").
-include("cycle_act.hrl").
-include("proto/mod_role_act_trench_ceremony.hrl").
%% API
-export([
    handle/1,
    recharge/2,
    do_recharge/2,
    reward/1,
    gm_set_first_trench_ceremony/0
]).

-export([
    zero/0,
    trench_ceremony_end/0
]).

recharge(RoleID, AccRecharge) ->
    world_cycle_act_server:call_mod(?MODULE, {recharge, RoleID, AccRecharge}).

reward(RoleID) ->
    world_cycle_act_server:call_mod(?MODULE, {reward, RoleID}).

gm_set_first_trench_ceremony() ->
    world_cycle_act_server:info({mod, ?MODULE, {gm}}).

handle({recharge, RoleID, AccRecharge}) ->
    do_recharge(RoleID, AccRecharge);
handle({reward, RoleID}) ->
    do_reward(RoleID);
handle({gm}) ->
    gm_set_first_trench_ceremony_i();
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).

%% 玩家达到条件
do_recharge(RoleID, AccRecharge) ->
    case world_data:get_first_trench_ceremony() of
        #r_world_trench_ceremony{reward_role_id = RewardRoleID} when RewardRoleID > 0 ->
            ok;
        _ ->
            TrenchCeremony = #r_world_trench_ceremony{reward_role_id = RoleID, status = ?TRENCH_CEREMONY_CAN_REWARD, accrecharge = AccRecharge},
            world_data:set_first_trench_ceremony(TrenchCeremony),
            [#c_cycle_act{level = Level}] = lib_config:find(cfg_cycle_act, ?CYCLE_ACT_TRENCH_CEREMONY),
            Condition = #r_broadcast_condition{min_level = Level, ignore_ids = [RoleID]},
            DataRecord = #m_trench_ceremony_toc{role_id = RoleID, name = common_role_data:get_role_name(RoleID), accrecharge = AccRecharge, status = ?TRENCH_CEREMONY_CAN_REWARD},
            common_broadcast:bc_record_to_world_by_condition(DataRecord, Condition)
    end.

%% 获取奖励 call
do_reward(RoleID) ->
    case world_data:get_first_trench_ceremony() of
        #r_world_trench_ceremony{reward_role_id = RoleID, status = Status} = TrenchCeremony ->
            case Status =:= ?TRENCH_CEREMONY_CAN_REWARD of
                true ->
                    world_data:set_first_trench_ceremony(TrenchCeremony#r_world_trench_ceremony{status = ?TRENCH_CEREMONY_HAS_REWARD}),
                    ok;
                _ ->
                    {error, ?ERROR_TRENCH_CEREMONY_REWARD_002}
            end;
        _ ->
            {error, ?ERROR_TRENCH_CEREMONY_REWARD_001}
    end.

%% 怕出现
zero() ->
    case world_cycle_act_server:is_act_open(?CYCLE_ACT_TRENCH_CEREMONY) of
        true ->
            ok;
        _ ->
            world_data:set_first_trench_ceremony(undefined)
    end.

%% 活动结束，状态设置，同时看看要不要补发奖励
trench_ceremony_end() ->
    TrenchCeremony = world_data:get_first_trench_ceremony(),
    world_data:set_first_trench_ceremony(undefined),
    case TrenchCeremony of
        #r_world_trench_ceremony{reward_role_id = RewardRoleID, status = Status} when RewardRoleID > 0 andalso Status =:= ?TRENCH_CEREMONY_CAN_REWARD ->
            GoodsList2 = common_misc:get_global_string_list(?GLOBAL_ACT_TRENCH_CEREMONY),
            GoodsList3 = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- GoodsList2],
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_ACT_TRENCH_CEREMONY,
                action = ?ITEM_GAIN_ACT_TRENCH_CEREMONY,
                goods_list = GoodsList3
            },
            common_letter:send_letter(RewardRoleID, LetterInfo);
        _ ->
            ok
    end.

gm_set_first_trench_ceremony_i() ->
    world_data:set_first_trench_ceremony(undefined),
    ok.
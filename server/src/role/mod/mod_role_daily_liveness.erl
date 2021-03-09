%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% 活跃度
%%% @end
%%% Created : 03. 四月 2018 20:05
%%%-------------------------------------------------------------------
-module(mod_role_daily_liveness).
-author("WZP").

-include("role.hrl").
-include("copy.hrl").
-include("daily_liveness.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_daily_liveness.hrl").

%% API
-export([
    zero/1,
    online/1,
    day_reset/1,
    handle/2
]).

-export([
    get_daily_liveness/1,
    get_offline_solo_times/1
]).

-export([
    kill_boss/2,
    function_open/1,
    role_pre_enter/1,
    trigger_copy/2,
    gm_add_liveness/2,
    trigger_daily_liveness/2,
    auction_sell/2
]).




zero(State) ->
    online(State).

online(#r_role{role_daily_liveness = undefined} = State) ->
    State;
online(#r_role{role_id = RoleID, role_daily_liveness = RoleDailyLiveness} = State) ->
    #r_role_daily_liveness{liveness = Liveness, liveness_list = LivenessList, got_reward = GotReward} = RoleDailyLiveness,
    common_misc:unicast(RoleID, #m_daily_liveness_reward_toc{list = GotReward}),
    common_misc:unicast(RoleID, #m_daily_liveness_toc{list = LivenessList, liveness = Liveness}),
    State.


day_reset(#r_role{role_daily_liveness = undefined} = State) ->
    State;
day_reset(#r_role{role_id = RoleID, role_daily_liveness = RoleDailyLiveness} = State) ->
    IsWeek = role_misc:is_reset_week(State),
    NewLivenessList = reset_list(IsWeek, RoleDailyLiveness#r_role_daily_liveness.liveness_list, []),
    RoleDailyLiveness2 = RoleDailyLiveness#r_role_daily_liveness{role_id = RoleID, liveness = 0, liveness_list = NewLivenessList, got_reward = []},
    common_misc:unicast(RoleID, #m_daily_liveness_toc{list = NewLivenessList, liveness = 0}),
    State#r_role{role_daily_liveness = RoleDailyLiveness2}.

reset_list(_IsWeek, [], List) ->
    List;
reset_list(IsWeek, [#p_kv{id = ID, val = Val}|T], List) ->
    case ID =:= ?LIVENESS_FAMILY_MISSION of
        false ->
            reset_list(IsWeek, T, [#p_kv{id = ID, val = 0}|List]);
        _ ->
            case IsWeek of
                true ->
                    reset_list(IsWeek, T, [#p_kv{id = ID, val = 0}|List]);
                _ ->
                    reset_list(IsWeek, T, [#p_kv{id = ID, val = Val}|List])
            end
    end.


handle({#m_daily_liveness_reward_tos{type = Type}, _RoleID, _Pid}, State) ->
    do_get_reward(Type, State);
handle({trigger_daily_liveness, Type}, State) ->
    do_daily_liveness(State, Type);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info:~w", [Info]),
    State.

get_daily_liveness(State) ->
    #r_role{role_daily_liveness = RoleDailyLiveness} = State,
    case RoleDailyLiveness of
        #r_role_daily_liveness{liveness = Liveness} ->
            Liveness;
        _ ->
            0
    end.

get_offline_solo_times(State) ->
    #r_role{role_daily_liveness = RoleDailyLiveness} = State,
    #r_role_daily_liveness{liveness_list = LivenessList} = RoleDailyLiveness,
    case lists:keyfind(?LIVENESS_OFF_SOLO, #p_kv.id, LivenessList) of
        #p_kv{val = Times} ->
            Times;
        _ ->
            0
    end.

%%触发日常活跃度
role_pre_enter(State) ->
    #r_role{role_map = #r_role_map{map_id = MapID}} = State,
    case lib_config:find(cfg_copy, MapID) of
        [] ->
            State;
        [#c_copy{copy_type = CopyType}] ->
            trigger_copy(CopyType, State)
    end.




kill_boss(TypeID, State) ->
    case lib_config:find(cfg_world_boss, TypeID) of
        [#c_world_boss{type = Type}] ->
            if
                Type =:= ?BOSS_TYPE_FAMILY -> mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_FUDI);
                Type =:= ?BOSS_TYPE_WORLD_BOSS ->
                    mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_WORLD_BOSS);
                Type =:= ?BOSS_TYPE_TIME -> mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_YOUMING);
                Type =:= ?BOSS_TYPE_MYTHICAL ->
                    mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_SHENGSHOU);
                Type =:= ?BOSS_TYPE_CROSS_MYTHICAL ->
                    mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_SHENGSHOU);
                Type =:= ?BOSS_TYPE_ANCIENTS -> mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_YUANGU);
                true ->
                    State
            end;
        _ ->
            State
    end.

trigger_copy(CopyType, State) ->
    case CopyType of
        ?COPY_EXP ->
            mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_EXP_COPY);
        ?COPY_SILVER ->
            mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_SILVER_COPY);
        ?COPY_EQUIP ->
            mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_EQUIP_COPY);
        ?COPY_SINGLE_TD ->
            mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_PET_COPY);
        ?COPY_IMMORTAL ->
            mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_YOUHUNLIN);
        ?COPY_FIVE_ELEMENTS ->
            mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_WUXING);
        _ ->
            State
    end.

do_get_reward(_Liveness, #r_role{role_daily_liveness = undefined} = State) ->
    State;
do_get_reward(Liveness, #r_role{role_id = RoleID, role_daily_liveness = RoleDailyLiveness} = State) ->
    #r_role_daily_liveness{got_reward = GotReward} = RoleDailyLiveness,
    case catch check_can_get(State, GotReward, Liveness, RoleDailyLiveness) of
        {ok, NewState} ->
            common_misc:unicast(RoleID, #m_daily_liveness_reward_toc{list = [Liveness]}),
            NewState;
        {error, Ecode} ->
            common_misc:unicast(RoleID, #m_daily_liveness_reward_toc{err_code = Ecode}),
            State
    end.

check_can_get(State, GotReward, Liveness, RoleDailyLiveness) ->
    case lists:member(Liveness, GotReward) of
        false ->
            [RewardConfig] = lib_config:find(cfg_daily_liveness_reward, Liveness),
            Goods = get_goods(lib_tool:string_to_intlist(RewardConfig#c_daily_liveness_reward.reward), []),
            mod_role_bag:check_bag_empty_grid(Goods, State),
            BagDoing = [{create, ?ITEM_GAIN_DAILY_LIVENESS, Goods}],
            State2 = mod_role_bag:do(BagDoing, State),
            NewGotReward = [Liveness|GotReward],
            NewRoleDailyLiveness = RoleDailyLiveness#r_role_daily_liveness{got_reward = NewGotReward},
            {ok, State2#r_role{role_daily_liveness = NewRoleDailyLiveness}};
        _ ->
            ?THROW_ERR(?ERROR_DAILY_LIVENESS_REWARD_002)
    end.

get_goods([], List) ->
    List;
get_goods([{TypeID, Num}|T], List) ->
    Goods = #p_goods{type_id = TypeID, num = Num, bind = false},
    get_goods(T, [Goods|List]).

trigger_daily_liveness(RoleInfo, Type) ->
    if
        erlang:is_record(RoleInfo, r_role) ->
            do_daily_liveness(RoleInfo, Type);
        erlang:is_list(RoleInfo) ->
            lists:foreach(
                fun(RoleID) ->
                    role_misc:info_role(RoleID, {mod, ?MODULE, {trigger_daily_liveness, Type}})
                end, RoleInfo);
        erlang:is_integer(RoleInfo) ->
            role_misc:info_role(RoleInfo, {mod, ?MODULE, {trigger_daily_liveness, Type}});
        true ->
            RoleInfo
    end.


do_daily_liveness(#r_role{role_id = _RoleID, role_daily_liveness = undefined} = State, _Type) ->
    State;
do_daily_liveness(#r_role{role_id = RoleID, role_daily_liveness = RoleDailyLiveness} = State, Type) ->
    case lib_config:find(cfg_daily_liveness, Type) of
        [] ->
            State;
        [Config] ->
            #r_role_daily_liveness{liveness_list = LivenessList, liveness = Liveness} = RoleDailyLiveness,
            State2 =
            case lists:keytake(Type, #p_kv.id, LivenessList) of
                {value, #p_kv{val = Value}, LivenessList2} ->
                    case Config#c_daily_liveness.times > Value of
                        false ->
                            State;
                        _ ->
                            NewLiveness = Liveness + Config#c_daily_liveness.once_liveness,
                            NewPkv = #p_kv{val = Value + 1, id = Type},
                            NewRoleDailyLiveness = RoleDailyLiveness#r_role_daily_liveness{liveness_list = [NewPkv|LivenessList2], liveness = NewLiveness},
                            common_misc:unicast(RoleID, #m_daily_liveness_toc{list = [NewPkv], liveness = NewRoleDailyLiveness#r_role_daily_liveness.liveness}),
                            State#r_role{role_daily_liveness = NewRoleDailyLiveness}
                    end;
                _ ->
                    NewLiveness = Liveness + Config#c_daily_liveness.once_liveness,
                    NewPkv = #p_kv{val = 1, id = Type},
                    NewRoleDailyLiveness = RoleDailyLiveness#r_role_daily_liveness{liveness_list = [NewPkv|LivenessList], liveness = NewLiveness},
                    common_misc:unicast(RoleID, #m_daily_liveness_toc{list = [NewPkv], liveness = NewRoleDailyLiveness#r_role_daily_liveness.liveness}),
                    State#r_role{role_daily_liveness = NewRoleDailyLiveness}
            end,
            AddLiveness = get_daily_liveness(State2) - get_daily_liveness(State),
            case AddLiveness > 0 of
                false ->
                    State2;
                _ ->
                    hook_role:add_daily_liveness(State2, AddLiveness)
            end
    end.


function_open(#r_role{role_id = RoleID, role_daily_liveness = undefined} = State) ->
    RoleDailyLiveness = #r_role_daily_liveness{role_id = RoleID},
    State#r_role{role_daily_liveness = RoleDailyLiveness};
function_open(State) ->
    State.

gm_add_liveness(#r_role{role_daily_liveness = undefined} = State, _Val) ->
    State;
gm_add_liveness(#r_role{role_daily_liveness = RoleDailyLiveness, role_id = RoleID} = State, Val) ->
    NewRoleDailyLiveness = RoleDailyLiveness#r_role_daily_liveness{liveness = Val},
    common_misc:unicast(RoleID, #m_daily_liveness_toc{liveness = Val}),
    State2 = State#r_role{role_daily_liveness = NewRoleDailyLiveness},
    hook_role:add_daily_liveness(State2, Val).



auction_sell(State, Num) when Num > 0 ->
    State2 = do_daily_liveness(State, ?LIVENESS_AUCTION_SELL),
    auction_sell(State2, Num - 1);
auction_sell(State, _Num) ->
    State.
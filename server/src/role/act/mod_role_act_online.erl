%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 五月 2018 11:39
%%%-------------------------------------------------------------------
-module(mod_role_act_online).
-author("WZP").
-include("role.hrl").
-include("act.hrl").
-include("activity.hrl").
-include("proto/mod_role_act_online.hrl").


%% API
-export([
    online/1,
    offline/1,
    handle/2
]).


-export([
    function_open/1,
    gm_add_online_time/2
]).



online(#r_role{role_act_online = undefined} = State) ->
    State;
online(#r_role{role_id = RoleID, role_act_online = ActOnline} = State) ->
    case ActOnline#r_role_act_online.reward =:= [] of
        true ->
            ok;
        _ ->
            common_misc:unicast(RoleID, #m_act_online_toc{online_time = ActOnline#r_role_act_online.online_time, list = ActOnline#r_role_act_online.reward})
    end,
    State.

offline(#r_role{role_act_online = undefined} = State) ->
    State;
offline(#r_role{role_private_attr = PrivateAttr, role_act_online = ActOnline} = State) ->
    CountTime = erlang:max(PrivateAttr#r_role_private_attr.last_login_time, ActOnline#r_role_act_online.open_time),
    NewTime = time_tool:now() - CountTime + ActOnline#r_role_act_online.online_time,
    State#r_role{role_act_online = ActOnline#r_role_act_online{online_time = NewTime}}.

handle({#m_act_online_get_reward_tos{minute = Minute}, _RoleID, _Pid}, State) ->
    do_get_reward(Minute, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info:~w", [Info]),
    State.

function_open(#r_role{role_act_online = undefined, role_id = RoleID} = State) ->
    List = cfg_act_online:list(),
    Rewards2 = lists:foldl(
        fun({_, {_, Reward, _}}, Rewards) ->
            [Reward|Rewards]
        end, [], List),
    ActOnline = #r_role_act_online{role_id = RoleID, reward = Rewards2, online_time = 0, open_time = 0},
    NewActOnline = ActOnline#r_role_act_online{open_time = time_tool:now()},
    common_misc:unicast(RoleID, #m_act_online_toc{online_time = 0, list = NewActOnline#r_role_act_online.reward}),
    State#r_role{role_act_online = NewActOnline};
function_open(State) ->
    State.


do_get_reward(_Minute, #r_role{role_act_online = undefined} = State) ->
    State;
do_get_reward(Minute, #r_role{role_id = RoleID} = State) ->
    case catch check_can_get(Minute, State) of
        {ok, State2, BagDoing, IsAll} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_act_online_get_reward_toc{minute = Minute, online_time = 0, is_all = IsAll}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_online_get_reward_toc{err_code = ErrCode}),
            State
    end.



check_can_get(Minute, #r_role{role_private_attr = PrivateAttr, role_act_online = ActOnline} = State) ->
    ?IF(lists:member(Minute, ActOnline#r_role_act_online.reward), ok, ?THROW_ERR(?ERROR_ACT_ONLINE_GET_REWARD_001)),
    CountTime = erlang:max(PrivateAttr#r_role_private_attr.last_login_time, ActOnline#r_role_act_online.open_time),
    Now = time_tool:now(),
    OnlineTime = Now - CountTime + ActOnline#r_role_act_online.online_time,
    ?IF(OnlineTime >= Minute * 60, ok, ?THROW_ERR(?ERROR_ACT_ONLINE_GET_REWARD_003)),
    [Config] = lib_config:find(cfg_act_online, Minute),
    [TypeID, Num, Bind] = Config#c_act_online.reward,
    CreateList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)}],
    mod_role_bag:check_bag_empty_grid(CreateList, State),
    BagDoing = [{create, ?ITEM_GAIN_ACT_ONLINE, CreateList}],
    NewReward = lists:delete(Minute, ActOnline#r_role_act_online.reward),
    IsAll = ?IF(NewReward =:= [], 1, 0),
    NewActOnline = ActOnline#r_role_act_online{reward = NewReward, open_time = Now, online_time = 0},
    State2 = State#r_role{role_act_online = NewActOnline},
    {ok, State2, BagDoing, IsAll}.

gm_add_online_time(#r_role{role_act_online = undefined} = State, _Value) ->
    State;
gm_add_online_time(#r_role{role_private_attr = PrivateAttr, role_act_online = ActOnline, role_id = RoleID} = State, Value) ->
    NewActOnline = ActOnline#r_role_act_online{online_time = Value * 60 + ActOnline#r_role_act_online.online_time},
    CountTime = erlang:max(PrivateAttr#r_role_private_attr.last_login_time, ActOnline#r_role_act_online.open_time),
    SendTime = time_tool:now() - CountTime + NewActOnline#r_role_act_online.online_time,
    common_misc:unicast(RoleID, #m_act_online_toc{online_time = SendTime, list = NewActOnline#r_role_act_online.reward}),
    State#r_role{role_act_online = NewActOnline}.
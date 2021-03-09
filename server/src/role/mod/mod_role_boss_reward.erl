%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 四月 2019 12:15
%%%-------------------------------------------------------------------
-module(mod_role_boss_reward).
-author("WZP").
-include("role.hrl").
-include("world_boss.hrl").
-include("monster.hrl").
-include("proto/mod_role_boss_reward.hrl").
%% API

-define(BOSS_XUANSHANG_LEVEL, 90).

-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    kill_boss/2,
    level_up/3
]).


init(#r_role{role_boss_reward = undefined, role_id = RoleID} = State) ->
    RoleBossReward = #r_role_boss_reward{role_id = RoleID},
    State#r_role{role_boss_reward = RoleBossReward};
init(State) ->
    State.


online(#r_role{role_boss_reward = RoleBossReward, role_attr = RoleAttr, role_id = RoleID} = State) ->
    case not had_complete(RoleBossReward) andalso RoleAttr#r_role_attr.level >= ?BOSS_XUANSHANG_LEVEL of
        true ->
            common_misc:unicast(RoleID, #m_boss_reward_toc{grade = RoleBossReward#r_role_boss_reward.grade, kill_num = RoleBossReward#r_role_boss_reward.kill_num,
                                                           got_reward = ?IF(RoleBossReward#r_role_boss_reward.got_reward, 1, 0)});
        _ ->
            ok
    end,
    State.

had_complete(#r_role_boss_reward{got_reward = GotReward}) ->
    case GotReward of
        false ->
            false;
        _ ->
            true
    end.


level_up(OldLevel, NewLevel, State) ->
    case OldLevel < ?BOSS_XUANSHANG_LEVEL andalso NewLevel >= ?BOSS_XUANSHANG_LEVEL of
        true ->
            #r_role{role_id = RoleID, role_boss_reward = RoleBossReward} = State,
            common_misc:unicast(RoleID, #m_boss_reward_toc{grade = RoleBossReward#r_role_boss_reward.grade, kill_num = RoleBossReward#r_role_boss_reward.kill_num,
                                                           got_reward = ?IF(RoleBossReward#r_role_boss_reward.got_reward, 1, 0)}),
            State;
        _ ->
            State
    end.

handle({#m_boss_reward_get_tos{}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, State).

do_get_reward(RoleID, State) ->
    case catch check_can_get(State, RoleID) of
        {ok, State2, BagDoing} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            #r_role{role_id = RoleID, role_boss_reward = RoleBossReward} = State3,
            common_misc:unicast(RoleID, #m_boss_reward_toc{grade = RoleBossReward#r_role_boss_reward.grade, kill_num = RoleBossReward#r_role_boss_reward.kill_num,
                                                           got_reward = ?IF(RoleBossReward#r_role_boss_reward.got_reward, 1, 0)}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_boss_reward_get_toc{err_code = ErrCode}),
            State
    end.

check_can_get(#r_role{role_boss_reward = RoleBossReward} = State, RoleID) ->
    ?IF(RoleBossReward#r_role_boss_reward.got_reward, ?THROW_ERR(?ERROR_BOSS_REWARD_GET_002), ok),
    [Config] = lib_config:find(cfg_boss_reward, RoleBossReward#r_role_boss_reward.grade),
    ?IF(Config#c_boss_reward.times =< RoleBossReward#r_role_boss_reward.kill_num, ok, ?THROW_ERR(?ERROR_BOSS_REWARD_GET_001)),
    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = true} || {TypeID, Num} <- lib_tool:string_to_intlist(Config#c_boss_reward.reward)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_BOSS_REWARD, GoodsList}],
    NewGrade = RoleBossReward#r_role_boss_reward.grade + 1,
    case lib_config:find(cfg_boss_reward, NewGrade) of
        [_Config2] ->
            RoleBossReward2 = #r_role_boss_reward{role_id = RoleID, grade = NewGrade},
            {ok, State#r_role{role_boss_reward = RoleBossReward2}, BagDoings};
        _ ->
            {ok, State#r_role{role_boss_reward = RoleBossReward#r_role_boss_reward{got_reward = true}}, BagDoings}
    end.


kill_boss(TypeID, #r_role{role_boss_reward = RoleBossReward} = State) ->
    case had_complete(RoleBossReward) of
        true ->
            State;
        _ ->
            case lib_config:find(cfg_world_boss, TypeID) of
                [#c_world_boss{type = Type}] ->
                    if
                        Type =:= ?BOSS_TYPE_WORLD_BOSS -> kill_boss_i(State, Type,TypeID);
                        Type =:= ?BOSS_TYPE_TIME -> kill_boss_i(State, Type,TypeID);
                        true ->
                            State
                    end;
                _ ->
                    State
            end
    end.


kill_boss_i(#r_role{role_boss_reward = RoleBossReward, role_id = RoleID, role_attr = RoleAttr} = State, Type, TypeID) ->
    case RoleAttr#r_role_attr.level >= ?BOSS_XUANSHANG_LEVEL of
        true ->
            [Config] = lib_config:find(cfg_boss_reward, RoleBossReward#r_role_boss_reward.grade),
            case Config#c_boss_reward.type =:= Type andalso Config#c_boss_reward.times > RoleBossReward#r_role_boss_reward.kill_num of
                false ->
                    State;
                _ ->
                    [Monster] = lib_config:find(cfg_monster, TypeID),
                    case Monster#c_monster.level >= Config#c_boss_reward.level of
                        true ->
                            RoleBossReward2 = RoleBossReward#r_role_boss_reward{kill_num = RoleBossReward#r_role_boss_reward.kill_num + 1},
                            common_misc:unicast(RoleID, #m_boss_reward_toc{grade = RoleBossReward2#r_role_boss_reward.grade, kill_num = RoleBossReward2#r_role_boss_reward.kill_num,
                                                                           got_reward = ?IF(RoleBossReward2#r_role_boss_reward.got_reward, 1, 0)}),
                            State#r_role{role_boss_reward = RoleBossReward2};
                        _ ->
                            State
                    end
            end;
        _ ->
            State
    end.
%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 四月 2018 14:55
%%%-------------------------------------------------------------------
-module(mod_role_act_level).
-author("laijichang").
-include("role.hrl").
-include("act.hrl").
-include("proto/mod_role_act_level.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    act_update/1
]).

init(#r_role{role_id = RoleID, role_act_level = undefined} = State) ->
    RoleActLevel = #r_role_act_level{role_id = RoleID},
    State#r_role{role_act_level = RoleActLevel};
init(State) ->
    State.

online(State) ->
    case mod_role_act:is_act_open(?ACT_LEVEL_ID, State) of
        true ->
            #r_role{role_id = RoleID, role_act_level = RoleActLevel} = State,
            #r_role_act_level{reward_level_list = LevelList} = RoleActLevel,
            ActLevelList = world_data:get_act_level_list(),
            common_misc:unicast(RoleID, #m_act_level_info_toc{world_level_list = ActLevelList, my_level_list = LevelList});
        _ ->
            ok
    end,
    State.



act_update(State) ->
    online(State).

handle({#m_act_level_reward_tos{level = Level}, RoleID, _PID}, State) ->
    do_level_reward(RoleID, Level, State).

do_level_reward(RoleID, Level, State) ->
    case catch check_level_reward(Level, State) of
        {ok, LimitNum, BagDoings, State2} ->
            case LimitNum > 0 of
                true ->
                    case catch world_act_server:level_reward(Level, LimitNum) of
                        ok ->
                            State3 = mod_role_bag:do(BagDoings, State2),
                            common_misc:unicast(RoleID, #m_act_level_reward_toc{level = Level}),
                            State3;
                        {error, ErrCode} ->
                            common_misc:unicast(RoleID, #m_act_level_reward_toc{err_code = ErrCode}),
                            State
                    end;
                _ ->
                    State3 = mod_role_bag:do(BagDoings, State2),
                    common_misc:unicast(RoleID, #m_act_level_reward_toc{level = Level}),
                    State3
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_act_level_reward_toc{err_code = ErrCode}),
            State
    end.

check_level_reward(Level, State) ->
    ?IF(mod_role_act:is_act_open(?ACT_LEVEL_ID, State), ok, ?THROW_ERR(?ERROR_ACT_LEVEL_REWARD_003)),
    #r_role{role_act_level = RoleActLevel} = State,
    #r_role_act_level{reward_level_list = LevelList} = RoleActLevel,
    ?IF(lists:member(Level, LevelList), ?THROW_ERR(?ERROR_ACT_LEVEL_REWARD_001), ok),
    RoleLevel = mod_role_data:get_role_level(State),
    ?IF(RoleLevel >= Level, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    case lib_config:find(cfg_act_level, Level) of
        [Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    #c_act_level{item_rewards = ItemRewards, limit_num = LimitNum} = Config,
    GoodsList = [ #p_goods{type_id = TypeID, num = Num} || {TypeID, Num , _} <- common_misc:get_item_reward(ItemRewards)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_LEVEL_REWARD, GoodsList}],
    LevelList2 = [Level|LevelList],
    RoleActLevel2 = RoleActLevel#r_role_act_level{reward_level_list = LevelList2},
    State2 = State#r_role{role_act_level = RoleActLevel2},
    {ok, LimitNum, BagDoings, State2}.
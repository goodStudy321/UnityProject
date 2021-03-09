%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 八月 2019 10:15
%%%-------------------------------------------------------------------
-module(mod_role_day_box).
-author("WZP").

-include("role.hrl").
-include("cycle_act.hrl").
-include("proto/mod_role_day_box.hrl").

%% API
-export([
    init/1,
    online/1,
    recharge/1,
    handle/2
]).

-export([
%%    act_close/2,
    init_data/2,
    get_day/0
]).




init(#r_role{role_id = RoleID, role_day_box = undefined} = State) ->
    RoleDayBox = #r_role_day_box{role_id = RoleID, list = [#p_kv{id = 1, val = ?ACT_REWARD_CANNOT_GET}, #p_kv{id = 2, val = ?ACT_REWARD_CANNOT_GET}, #p_kv{id = 3, val = ?ACT_REWARD_CANNOT_GET}]},
    State#r_role{role_day_box = RoleDayBox};
init(State) ->
    State.


init_data(#r_role{role_id = RoleID} = State, StartTime) ->
    RoleDayBox = #r_role_day_box{role_id = RoleID, list = [#p_kv{id = 1, val = ?ACT_REWARD_CANNOT_GET}, #p_kv{id = 2, val = ?ACT_REWARD_CANNOT_GET}, #p_kv{id = 3, val = ?ACT_REWARD_CANNOT_GET}],
                                 start_time = StartTime},
    online(State#r_role{role_day_box = RoleDayBox}).


online(#r_role{role_id = RoleID, role_day_box = RoleDayBox} = State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_DAY_CYCLE, State) of
        true ->
            Day = get_day(),
            common_misc:unicast(RoleID, #m_day_box_toc{day = Day, list = RoleDayBox#r_role_day_box.list});
        _ ->
            ok
    end,
    State.


%%act_close(State, SerialNumber) ->
%%    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_DAY_CYCLE, State) of
%%        true ->
%%            #r_role{role_id = RoleID, role_day_box = RoleDayBox} = State,
%%            Yesterday = get_yesterday_day(),
%%            case get_goods(State#r_role.role_day_box#r_role_day_box.list, Yesterday, SerialNumber, []) of
%%                [] ->
%%                    ok;
%%                GoodsList ->
%%                    LetterInfo = #r_letter_info{
%%                        template_id = ?LETTER_DAY_BOX,
%%                        action = ?ITEM_GAIN_DAY_BOX,
%%                        goods_list = GoodsList},
%%                    common_letter:send_letter(RoleID, LetterInfo)
%%            end,
%%            RoleDayBox2 = RoleDayBox#r_role_day_box{list = [#p_kv{id = 1, val = ?ACT_REWARD_CANNOT_GET}, #p_kv{id = 2, val = ?ACT_REWARD_CANNOT_GET}, #p_kv{id = 3, val = ?ACT_REWARD_CANNOT_GET}]},
%%            Day = get_day(),
%%            common_misc:unicast(RoleID, #m_day_box_toc{day = Day, list = RoleDayBox2#r_role_day_box.list}),
%%            State#r_role{role_day_box = RoleDayBox2};
%%        _ ->
%%            State
%%    end.


%%get_goods([], _Day, _SerialNumber, List) ->
%%    List;
%%get_goods([#p_kv{id = ID, val = Val}|T], Day, SerialNumber, List) ->
%%    case Val =:= ?ACT_REWARD_CAN_GET of
%%        false ->
%%            get_goods(T, Day, SerialNumber, List);
%%        _ ->
%%            [Config] = lib_config:find(cfg_day_box, {Day, ID, SerialNumber}),
%%            GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind, _} <- lib_tool:string_to_intlist(Config#c_day_box.reward)],
%%            get_goods(T, Day, SerialNumber, GoodsList ++ List)
%%    end.

%%
%%get_yesterday_day() ->
%%    OpenDays = common_config:get_open_days() - 1,
%%    [Min, Max|_] = common_misc:get_global_list(?GLOBAL_DAY_BOX),
%%    Day = (OpenDays - Min) rem (Max - Min + 1) + Min,
%%    Day rem 7 + 1.

get_day() ->
    OpenDays = common_config:get_open_days(),
    [Min, Max|_] = common_misc:get_global_list(?GLOBAL_DAY_BOX),
    Day = (OpenDays - Min) rem (Max - Min + 1) + Min,
    Day rem 7 + 1.


recharge(#r_role{role_id = RoleID, role_day_box = RoleDayBox} = State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_DAY_CYCLE, State) of
        true ->
            case change_times(RoleDayBox#r_role_day_box.list, 100) of
                {ok, Times} ->
                    NewList = lists:keyreplace(Times, #p_kv.id, RoleDayBox#r_role_day_box.list, #p_kv{id = Times, val = ?ACT_REWARD_CAN_GET}),
                    RoleDayBox2 = RoleDayBox#r_role_day_box{list = NewList},
                    common_misc:unicast(RoleID, #m_day_box_update_toc{id = Times}),
                    State#r_role{role_day_box = RoleDayBox2};
                _ ->
                    State
            end;
        _ ->
            State
    end.

change_times([], Times) ->
    case Times =:= 100 of
        true ->
            false;
        _ ->
            {ok, Times}
    end;
change_times([#p_kv{id = ID, val = Val}|T], Times) ->
    case Val =:= ?ACT_REWARD_CANNOT_GET andalso ID < Times of
        true ->
            change_times(T, ID);
        _ ->
            change_times(T, Times)
    end.



handle({#m_day_box_reward_tos{id = Times}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, Times, State).



do_get_reward(RoleID, Times, State) ->
    case catch check_can_get(State, Times) of
        {ok, State2, BagDoing} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_day_box_reward_toc{id = Times}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_day_box_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get(#r_role{role_day_box = RoleDayBox} = State, Times) ->
    Act = world_cycle_act_server:get_act(?CYCLE_ACT_DAY_CYCLE),
    case Act#r_cycle_act.status =:= ?CYCLE_ACT_STATUS_OPEN andalso mod_role_data:get_role_level(State) >= Act#r_cycle_act.level of
        true ->
            case lists:keytake(Times, #p_kv.id, RoleDayBox#r_role_day_box.list) of
                {value, #p_kv{val = ?ACT_REWARD_CAN_GET}, Other} ->
                    [Config] = lib_config:find(cfg_day_box, {get_day(), Times, Act#r_cycle_act.config_num}),
                    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)} || {TypeID, Num, Bind, _} <- lib_tool:string_to_intlist(Config#c_day_box.reward)],
                    BagDoing = [{create, ?ITEM_GAIN_DAY_BOX, GoodsList}],
                    mod_role_bag:check_bag_empty_grid(GoodsList, State),   %%检查包包空间够不够
                    RoleDayBox2 = RoleDayBox#r_role_day_box{list = [#p_kv{id = Times, val = ?ACT_REWARD_GOT}|Other]},
                    State2 = State#r_role{role_day_box = RoleDayBox2},
                    {ok, State2, BagDoing};
                _ ->
                    ?THROW_ERR(?ERROR_DAY_BOX_REWARD_001)
            end;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)
    end.




%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 四月 2018 15:46
%%%-------------------------------------------------------------------
-module(mod_role_act_seven).
-author("WZP").
-include("role.hrl").
-include("act.hrl").
-include("activity.hrl").
-include("proto/mod_role_act_seven.hrl").


%% API
-export([
    init/1,
    online/1,
    zero/1,
    day_reset/1,
    handle/2
]).

-export([
    gm_act_sign_active/1
]).

-export([
    is_all_reward/1
]).


init(#r_role{role_id = RoleID, role_seven_day = undefined} = State) ->
    Days = lists:seq(2, 7),
    Info = [#p_kv{id = Day, val = ?ACT_REWARD_CANNOT_GET} || Day <- Days],
    SevenDayInfo = #r_role_seven_day{role_id = RoleID, info = [#p_kv{id = 1, val = ?ACT_REWARD_CAN_GET}|Info], is_bc = true},
    State#r_role{role_seven_day = SevenDayInfo};
init(State) ->
    State.

zero(#r_role{role_seven_day = undefined} = State) ->
    State;
zero(State) ->
    case mod_role_act:is_act_open(?ACT_SEVEN_ID, State) of
        true ->
            #r_role{role_id = RoleID, role_seven_day = SevenDayInfo} = State,
            ?IF(SevenDayInfo#r_role_seven_day.is_bc, common_misc:unicast(RoleID, #m_role_seven_toc{list = SevenDayInfo#r_role_seven_day.info}), ok);
        _ ->
            ok
    end,
    State.


online(#r_role{role_seven_day = undefined} = State) ->
    State;
online(State) ->
    #r_role{role_id = RoleID, role_seven_day = SevenDayInfo} = State,
    case mod_role_act:is_act_open(?ACT_SEVEN_ID, State) of
        true ->
            ?IF(SevenDayInfo#r_role_seven_day.is_bc, common_misc:unicast(RoleID, #m_role_seven_toc{list = SevenDayInfo#r_role_seven_day.info}), ok);
        _ ->
            ok
    end,
    State.

day_reset(#r_role{role_seven_day = undefined} = State) ->
    State;
day_reset(State) ->
    case mod_role_act:is_act_open(?ACT_SEVEN_ID, State) of
        true ->
            #r_role{role_seven_day = SevenDayInfo} = State,
            SevenDayInfo2 = do_day_reset(SevenDayInfo),
            State#r_role{role_seven_day = SevenDayInfo2};
        _ ->
            State
    end.

gm_act_sign_active(State) ->
    #r_role{role_seven_day = SevenDayInfo} = State,
    #r_role_seven_day{info = DayList} = SevenDayInfo,
    DayList2 = [KV#p_kv{val = ?ACT_REWARD_GOT} || KV <- DayList],
    SevenDayInfo2 = SevenDayInfo#r_role_seven_day{info = DayList2},
    State2 = State#r_role{role_seven_day = SevenDayInfo2},
    online(State2).

is_all_reward(State) ->
    #r_role{role_seven_day = SevenDayInfo} = State,
    #r_role_seven_day{info = DayList} = SevenDayInfo,
    is_all_reward2(DayList).

is_all_reward2([]) ->
    true;
is_all_reward2([#p_kv{val = Status}|R]) ->
    ?IF(Status =:= ?ACT_REWARD_GOT, is_all_reward2(R), false).


handle({#m_role_seven_tos{day = Day}, _RoleID, _Pid}, State) ->
    do_get_reward(Day, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info:~w", [Info]),
    State.


do_get_reward(Day, #r_role{role_seven_day = SevenDayInfo, role_id = RoleID} = State) ->
    case catch check_can_get(SevenDayInfo, Day, State) of
        {ok, SevenDayInfo2, BagDoing, Pkv} ->
            State2 = mod_role_bag:do(BagDoing, State),
            common_misc:unicast(RoleID, #m_role_seven_toc{list = [Pkv]}),
            State2#r_role{role_seven_day = SevenDayInfo2};
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_seven_toc{err_code = ErrCode}),
            State
    end.

check_can_get(SevenDayInfo, Day, State) ->
    case world_act_server:is_act_open(?ACT_SEVEN_ID) of
        true ->
            case lists:keytake(Day, #p_kv.id, SevenDayInfo#r_role_seven_day.info) of
                {value, #p_kv{id = Day2, val = Status}, T} ->
                    case Status of
                        ?ACT_REWARD_CAN_GET ->
                            Pkv = #p_kv{id = Day2, val = ?ACT_REWARD_GOT},
                            SevenDayInfo2 = SevenDayInfo#r_role_seven_day{info = [Pkv|T]},
                            [Config] = lib_config:find(cfg_seven_day, Day),
                            ItemRewards2 = lib_tool:string_to_intlist(Config#c_seven_day.reward),
                            Goods = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- ItemRewards2],
                            mod_role_bag:check_bag_empty_grid(Goods, State),
                            BagDoing = [{create, ?ITEM_GAIN_ACT_SEVEN_LOGIN, Goods}],
                            {ok, SevenDayInfo2, BagDoing, Pkv};
                        ?ACT_REWARD_CANNOT_GET ->
                            {error, ?ERROR_ROLE_SEVEN_003};
                        _ ->
                            {error, ?ERROR_ROLE_SEVEN_001}
                    end;
                _ ->
                    {error, ?ERROR_ROLE_SEVEN_002}
            end;
        _ ->
            {error, ?ERROR_ROLE_SEVEN_004}
    end.


do_day_reset(#r_role_seven_day{info = List} = SevenDayInfo) ->
    Day = get_change_day(List, 100),
    case Day =/= 100 of
        true ->
            List2 = lists:keyreplace(Day, #p_kv.id, List, #p_kv{id = Day, val = ?ACT_REWARD_CAN_GET}),
            IsBc = true;
        _ ->
            List2 = List,
            IsBc = not lists:all(fun(Pkv) -> Pkv#p_kv.val =:= ?ACT_REWARD_GOT end, List2)
    end,
    SevenDayInfo#r_role_seven_day{info = List2, is_bc = IsBc}.

get_change_day([], Day) ->
    Day;
get_change_day([Pkv|T], Day) ->
    case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET andalso Pkv#p_kv.id < Day of
        true ->
            get_change_day(T, Pkv#p_kv.id);
        _ ->
            get_change_day(T, Day)
    end.


%%do_day_reset2([], _Day, List) ->
%%    List;
%%do_day_reset2([#p_kv{id = Day2, val = Status}|T], Day, List) ->
%%    case Status =:= ?ACT_REWARD_CANNOT_GET andalso Day2 =< Day of
%%        true ->
%%            do_day_reset2(T, Day, [#p_kv{id = Day2, val = ?ACT_REWARD_CAN_GET}|List]);
%%        _ ->
%%            do_day_reset2(T, Day, [#p_kv{id = Day2, val = Status}|List])
%%    end.

%%check_need_send([]) ->
%%    donnot_send;
%%check_need_send([#p_kv{val = Status}|T]) ->
%%    case Status =/= ?ACT_REWARD_GOT of
%%        true ->
%%            send;
%%        _ ->
%%            check_need_send(T)
%%    end.












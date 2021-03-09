%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 四月 2018 15:11
%%%-------------------------------------------------------------------
-module(mod_role_answer).
-author("WZP").
-include("role.hrl").
-include("answer.hrl").
-include("daily_liveness.hrl").
-include("activity.hrl").
-include("proto/mod_role_fight.hrl").
-include("proto/mod_role_answer.hrl").
%% API
-export([
    online/1,
    handle/2
]).


-export([
    check_role_pre_enter/2,
    role_enter_map/1,
    is_able/1,
    get_other_side/1
]).

online(State) ->
    Now = time_tool:now(),
    set_last_attack_time(?INTERFERE, Now - ?INTERFERE_CD),
    set_last_attack_time(?KICKED_UP, Now - ?KICKED_UP_CD),
    State.


handle({#m_answer_attack_tos{skill = Skill, target = Target, pos = Pos}, RoleID, _PID}, State) ->
    do_answer_attack(Skill, Target, Pos, State, RoleID);
handle({be_hit, Skill, Pos}, State) ->
    do_be_hit(Skill, State, Pos);
handle(answer_start, State) ->
    do_answer_start(),
    State;
handle({answer_right_add_exp, ExpRate}, State) -> %% 正确答题
    State2 = do_add_exp(ExpRate, State, true),
    mod_role_achievement:answer_times(State2);
handle({answer_wrong_add_exp, ExpRate}, State) -> %% 错误答题
    do_add_exp(ExpRate, State, true);
handle({answer_add_exp, ExpRate}, State) ->
    set_answer_add_exp(0),
    set_add_exp(0),
    do_add_exp(ExpRate, State, false);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info: ~w", [Info]),
    State.


%%进入地图之前
check_role_pre_enter(#r_role{role_attr = RoleAttr}, MapID) ->
    #r_role_attr{level = Level} = RoleAttr,
    case catch mod_answer:role_pre_enter(Level) of
        {ok, ExtraID, RecordPos, ServerID} ->
            {MapID, ExtraID, ServerID, ?DEFAULT_CAMP_ROLE, RecordPos};
        {error, ErrCode} ->
            ?THROW_ERR(ErrCode);
        Err ->
            ?WARNING_MSG("----------~w", [Err])
    end.

%%进入地图
role_enter_map(#r_role{role_attr = Attr, role_id = RoleID} = State) ->
    case ?IS_MAP_ANSWER(State#r_role.role_map#r_role_map.map_id) of
        true ->
            mod_answer:role_enter_map(State#r_role.role_id, Attr#r_role_attr.role_name),
            common_misc:unicast(RoleID, #m_answer_exp_toc{exp = get_answer_add_exp(), all_exp = get_add_exp()}),
            ?IF(get_add_exp() =:= 0, mod_role_daily_liveness:trigger_daily_liveness(State, ?LIVENESS_ANSWER), ok),
            State;
        _ ->
            State
    end.


%%登录地图校验
is_able(State) ->
    #r_role{role_attr = #r_role_attr{last_offline_time = LastOfflineTime}} = State,
    case mod_answer:is_activity_open() of
        true ->
            case time_tool:is_same_date(LastOfflineTime, time_tool:now()) of
                true ->
                    true;
                _ ->
                    false
            end;
        _ ->
            false
    end.


%%被技能砸中
do_be_hit(Skill, #r_role{role_id = RoleID, role_map = RoleMap} = State, Circle) ->
    common_misc:unicast(RoleID, #m_answer_attack_toc{skill = Skill}),
    #r_role_map{map_pname = MapPname} = RoleMap,
    case Skill of
        ?KICKED_UP ->
            RecordPos = get_other_side(Circle),
            Pos = map_misc:pos_encode(RecordPos),
            {ok, MapPid} = map_misc:get_map_pid(MapPname),
            mod_map_role:role_change_pos(MapPid, RoleID, RecordPos, Pos, ?ACTOR_MOVE_NORMAL, 0);
        _ ->
            ok
    end,
    State.

%%获取另一边答案区出生点
get_other_side(Circle) ->
    case Circle of
        ?ANSWER_RIGHT_CIRCLE ->
            ?ANSWER_WRONG_POS;
        _ ->
            ?ANSWER_RIGHT_POS
    end.

%%扔技能
do_answer_attack(Skill, Target, Pos, State, RoleID) ->
    case catch check_can_use_skill(Skill) of
        {ok, Now} ->
            set_last_attack_time(Skill, Now),
            notice_be_hit_role(Target, Skill, Pos, activity_misc:get_activity_mod(?ACTIVITY_ANSWER)),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_fight_attack_toc{err_code = ErrCode}),
            State
    end.

%%通知被击玩家
notice_be_hit_role([], _Skill, _Pos,_) ->
    ok;
notice_be_hit_role([RoleID|H], Skill, Pos, Mod) ->
    case world_activity_server =:= Mod of
        true ->
            role_misc:info_role(RoleID, {mod, mod_role_answer, {be_hit, Skill, Pos}});
        _ ->
            mod_answer:attack(Skill, Pos, RoleID)
    end,
    notice_be_hit_role(H, Skill, Pos,Mod).

%%检查技能冷却
check_can_use_skill(Skill) ->
    Now = time_tool:now(),
    Cd = case Skill of
             ?KICKED_UP ->
                 ?KICKED_UP_CD;
             _ ->
                 ?INTERFERE_CD
         end,
    ?IF(Now - get_last_attack_time(Skill) >= Cd, {ok, Now}, {error, ?ERROR_FIGHT_ATTACK_005}).

%%设置技能冷却
set_last_attack_time(Type, Time) ->
    erlang:put({?MODULE, last_attack_time, Type}, Time).
get_last_attack_time(Type) ->
    case erlang:get({?MODULE, last_attack_time, Type}) of
        Time when erlang:is_integer(Time) -> Time;
        _ -> 0
    end.


set_add_exp(Exp) ->
    erlang:put({?MODULE, add_exp}, Exp).
get_add_exp() ->
    case erlang:get({?MODULE, add_exp}) of
        Exp when erlang:is_integer(Exp) -> Exp;
        _ -> 0
    end.

set_answer_add_exp(Exp) ->
    erlang:put({?MODULE, answer_add_exp}, Exp).
get_answer_add_exp() ->
    case erlang:get({?MODULE, answer_add_exp}) of
        Exp when erlang:is_integer(Exp) -> Exp;
        _ -> 0
    end.


do_answer_start() ->
    set_add_exp(0).



do_add_exp(ExpRate, #r_role{role_attr = Attr, role_id = RoleID} = State, IsAnswer) ->
    #r_role_attr{level = Level} = Attr,
    Exp = mod_role_level:get_activity_level_exp(Level, ExpRate),
    AddExp = get_add_exp() + Exp,
    set_add_exp(AddExp),
    if
        IsAnswer ->
            AnswerAddExp = get_answer_add_exp() + Exp,
            set_answer_add_exp(AnswerAddExp),
            common_misc:unicast(RoleID, #m_answer_exp_toc{exp = AnswerAddExp, all_exp = AddExp});
        true ->
            AnswerAddExp = get_answer_add_exp(),
            common_misc:unicast(RoleID, #m_answer_exp_toc{exp = AnswerAddExp, all_exp = AddExp})
    end,
    mod_role_level:do_add_exp(State, Exp, ?EXP_ADD_FROM_ANSWER).


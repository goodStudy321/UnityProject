%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 四月 2018 10:15
%%%-------------------------------------------------------------------
-module(mod_map_answer).
-author("WZP").
-include("common.hrl").
-include("answer.hrl").
-include("role.hrl").
-include("map.hrl").
-include("all_pb.hrl").
-include("proto/mod_map_answer.hrl").

%% API
-export([
    init/0,
    handle/1
]).

-export([
    role_enter_map/1,
    role_leave_map/1,
    into_circle/1,
    send_question_to_one/4
]).


init() ->
    set_circle([]),
    ok.




handle({send_question, Question, Time, Num}) ->
    do_send_question(Question, Time, Num);
handle(question_round_end) ->
    do_question_round_end();
handle({send_now_question, Question}) ->
    set_question(Question);
handle(do_map_end) ->
    erlang:send_after(60000, erlang:self(), {mod, mod_map_answer, do_map_end_i});
handle(do_map_end_i) ->
    map_server:kick_all_roles(),
    map_server:delay_shutdown();
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).


role_enter_map(RoleID) ->
    CircleInfo = #r_answer_circle{role_id = RoleID, time = time_tool:now(), type = ?ANSWER_RIGHT_CIRCLE},
    List = get_circle(),
    case lists:keytake(RoleID, #r_answer_circle.role_id, List) of
        {value, _Info, List2} ->
            set_circle([CircleInfo|List2]);
        _ ->
            set_circle([CircleInfo|List])
    end.


role_leave_map(RoleID) ->
    case common_config:is_cross_node() of
        true ->
            mod_role_buff:remove_buff_cross_server([?ANSWERING_BUFF], RoleID);
        _ ->
            mod_role_buff:remove_buff([?ANSWERING_BUFF], RoleID)
    end,
    mod_answer:role_leave_map(RoleID),
    List = get_circle(),
    case lists:keytake(RoleID, #r_answer_circle.role_id, List) of
        {value, Info, List2} ->
            Info2 = Info#r_answer_circle{type = ?ANSWER_LEAVE_MAP},
            set_circle([Info2|List2]);
        _ ->
            Info = #r_answer_circle{role_id = RoleID, type = ?ANSWER_LEAVE_MAP},
            set_circle([Info|List])
    end.


into_circle(RoleID) ->
    List = get_circle(),
    case lists:keytake(RoleID, #r_answer_circle.role_id, List) of
        {value, Info, List2} ->
            CircleInfo = change_type(Info),
            set_circle([CircleInfo|List2]);
        _ ->
            Info = #r_answer_circle{role_id = RoleID, type = ?ANSWER_LEAVE_MAP},
            set_circle([Info|List])
    end.

change_type(Info) ->
    #r_pos{mx = Mx} = mod_map_ets:get_actor_pos(Info#r_answer_circle.role_id),
    case Mx < ?ANSWER_MX of
        true ->
            Info#r_answer_circle{type = ?ANSWER_RIGHT_CIRCLE, time = time_tool:now()};
        _ ->
            Info#r_answer_circle{type = ?ANSWER_WRONG_CIRCLE, time = time_tool:now()}
    end.



do_send_question(Question, Time, Num) ->
    map_server:send_all_gateway(#m_answer_question_toc{question = Question#c_activity_question.id, time = Time, num = Num}),
    set_time(Time),
    set_question(Question).

do_question_round_end() ->
    case get_question() of
        LastQuestion when erlang:is_record(LastQuestion, c_activity_question) ->
            List = get_circle(),
            {AddRoles, WrongRoles, RightIDS, WrongIDS} = division_role(List, LastQuestion#c_activity_question.answer),
            common_broadcast:bc_record_to_roles(RightIDS, #m_answer_res_toc{res = 1, answer_res = LastQuestion#c_activity_question.answer}),
            common_broadcast:bc_record_to_roles(WrongIDS, #m_answer_res_toc{res = 2, answer_res = LastQuestion#c_activity_question.answer}),
            Time = get_time(),
            AddScores = get_add_scores_exp(AddRoles, Time, []),
            AddScores2 = [#p_kv{id = WrongID, val = 0} || WrongID <- WrongIDS],
            ExtraID = map_common_dict:get_map_extra_id(),
            Mod = activity_misc:get_map_activity_mod(),
            Mod:info_mod(mod_answer, {map_complete_updaterank, ExtraID, AddScores2 ++ AddScores}),
            add_wrong_exp(WrongRoles, Time);
        _ ->
            ok
    end.


division_role(List, Answer) ->
    division_role(List, [], [], [], [], Answer).

division_role([], AddRoles, WrongRoles, RightIDS, WrongIDS, _Answer) ->
    {AddRoles, WrongRoles, RightIDS, WrongIDS};
division_role([RoleInfo|T], AddRoles, WrongRoles, RightIDS, WrongIDS, Answer) ->
    case RoleInfo#r_answer_circle.type of
        ?ANSWER_LEAVE_MAP ->
            division_role(T, AddRoles, WrongRoles, RightIDS, WrongIDS, Answer);
        Answer ->
            division_role(T, [RoleInfo|AddRoles], WrongRoles, [RoleInfo#r_answer_circle.role_id|RightIDS], WrongIDS, Answer);
        _ ->
            division_role(T, AddRoles, [RoleInfo|WrongRoles], RightIDS, [RoleInfo#r_answer_circle.role_id|WrongIDS], Answer)
    end.




get_add_scores_exp([], _Time, List) ->
    List;
get_add_scores_exp([AddRole|T], Time, List) ->
    #r_answer_circle{role_id = RoleID, time = IntoTime} = AddRole,
    {AddScore, ExpRate} = mod_answer:get_add_score(Time, IntoTime, right),
    case common_config:is_cross_node() of
        true ->
            mod_role_buff:remove_buff_cross_server([?ANSWERING_BUFF], RoleID);
        _ ->
            mod_role_buff:remove_buff([?ANSWERING_BUFF], RoleID)
    end,
    role_misc:info_role(RoleID, mod_role_answer, {answer_right_add_exp, ExpRate}),
    Pkv = #p_kv{id = RoleID, val = AddScore},
    get_add_scores_exp(T, Time, [Pkv|List]).

add_wrong_exp([], _Time) ->
    ok;
add_wrong_exp([WrongRole|T], Time) ->
    #r_answer_circle{role_id = RoleID, time = IntoTime} = WrongRole,
    {_AddScore, ExpRate} = mod_answer:get_add_score(Time, IntoTime, wrong),
    role_misc:info_role(RoleID, mod_role_answer, {answer_wrong_add_exp, ExpRate}),
    case common_config:is_cross_node() of
        true ->
            mod_role_buff:add_buff_cross_server([#buff_args{buff_id = ?ANSWERING_BUFF, from_actor_id = 0}], RoleID);
        _ ->
            mod_role_buff:add_buff([#buff_args{buff_id = ?ANSWERING_BUFF, from_actor_id = 0}], RoleID)
    end,
    add_wrong_exp(T, Time).

%%登录时发送
send_question_to_one(Question, Time, RoleID, QuestionNum) ->
    common_misc:unicast(RoleID, #m_answer_question_toc{question = Question#c_activity_question.id, time = Time, num = QuestionNum}).


%%圈内人
set_circle(Roles) ->
    erlang:put({?MODULE, answer_right_circle}, Roles).

get_circle() ->
    erlang:get({?MODULE, answer_right_circle}).


%%题目
set_question(QuestionInfo) ->
    erlang:put({?MODULE, answer_question}, QuestionInfo).

get_question() ->
    erlang:get({?MODULE, answer_question}).

set_time(Time) ->
    erlang:put({?MODULE, round_end_time}, Time).

get_time() ->
    erlang:get({?MODULE, round_end_time}).




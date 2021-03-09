%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 七月 2017 9:51
%%%-------------------------------------------------------------------
-module(mod_role_letter).
-author("laijichang").
-include("role.hrl").
-include("letter.hrl").
-include("proto/mod_role_letter.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    level_up/1
]).

init(#r_role{role_id = RoleID, role_letter = undefined} = State) ->
    RoleLetter = #r_role_letter{role_id = RoleID},
    State#r_role{role_letter = RoleLetter};
init(State) ->
    State.

online(State) ->
    #r_role{role_id = RoleID, role_letter = RoleLetter} = State,
    #r_role_letter{counter = Counter, receive_box = ReceiveBox, gm_id_list = GMIDList} = RoleLetter,
    WorldReceive = get_world_letter(RoleID),
    {GMIDList2, GMReceive, _IsGetLetter} = get_gm_letter(GMIDList, State),
    {Counter2, NewLetters} = receive_add_counter(del_out_time_letter(WorldReceive ++ GMReceive), Counter, []),
    ReceiveBox2 = NewLetters ++ del_out_time_letter(ReceiveBox),
    case has_new_letter(ReceiveBox2, false) of
        true ->
            common_misc:unicast(RoleID, #m_letter_light_toc{});
        _ ->
            ignore
    end,
    ?TRY_CATCH(log_role_letter(NewLetters, State)),
    RoleLetter2 = RoleLetter#r_role_letter{counter = Counter2, receive_box = ReceiveBox2, gm_id_list = GMIDList2},
    State#r_role{role_letter = RoleLetter2}.

has_new_letter(_ReceiveBox, true) ->
    true;
has_new_letter([], false) ->
    false;
has_new_letter([Letter|ReceiveBox], false) ->
    if Letter#r_letter.letter_state =:= ?LETTER_NOT_OPEN ->
        Flag = true;
        true ->
            Flag = false
    end,
    has_new_letter(ReceiveBox, Flag).

get_world_letter(RoleID) ->
    case catch world_letter_server:role_get_letter(RoleID) of
        {ok, WorldReceive} ->
            del_out_time_letter(WorldReceive);
        Error ->
            ?ERROR_MSG("获取server新信件失败, Error :~w", [Error]),
            []
    end.

get_gm_letter(GMIDList, State) ->
    #r_role{role_attr = RoleAttr, role_private_attr = PrivateAttr} = State,
    #r_role_attr{
        level = Level,
        game_channel_id = GameChannelID,
        last_offline_time = LastOfflineTime} = RoleAttr,
    #r_role_private_attr{
        create_time = CreateTime,
        last_login_time = LastLoginTime
    } = PrivateAttr,
    #r_world_letter{receive_box = ReceiveBox} = world_letter_server:get_world_letter(?GM_MAIL_ID),
    get_gm_letter2(ReceiveBox, GMIDList, Level, GameChannelID, CreateTime, LastLoginTime, LastOfflineTime, [], false).

get_gm_letter2([], GMIDList, _Level, _GameChannelID, _CreateTime, _LastLoginTime, _LastOfflineTime, GMReceive, IsGetLetter) ->
    {GMIDList, GMReceive, IsGetLetter};
get_gm_letter2([Letter|R], GMIDList, Level, GameChannelID, CreateTime, LastLoginTime, LastOfflineTime, GMReceive, IsGetLetter) ->
    #r_letter{id = ID, condition = Condition} = Letter,
    case lists:member(ID, GMIDList) of
        true ->
            IsGetLetter2 = IsGetLetter,
            GMIDList2 = GMIDList,
            GMReceive2 = GMReceive;
        _ ->
            #r_gm_condition{
                min_level = MinLevel,
                max_level = MaxLevel,
                min_create_time = MinCreateTime,
                max_create_time = MaxCreateTime,
                last_offline_time = NeedOfflineTime,
                game_channel_id_list = GameChannelIDList} = Condition,
            case (MinLevel =< Level andalso Level =< MaxLevel) andalso
                (NeedOfflineTime =:= 0 orelse LastOfflineTime >= NeedOfflineTime orelse LastLoginTime - time_tool:now() >= ?ONE_MINUTE) andalso
                ((MinCreateTime =< CreateTime orelse MinCreateTime =:= 0) andalso (CreateTime =< MaxCreateTime orelse MinCreateTime =:= 0)) andalso
                (lists:member(GameChannelID, GameChannelIDList) orelse GameChannelIDList =:= []) of
                true ->
                    GMIDList2 = [ID|GMIDList],
                    IsGetLetter2 = true,
                    GMReceive2 = [Letter|GMReceive];
                _ ->
                    GMIDList2 = GMIDList,
                    IsGetLetter2 = IsGetLetter,
                    GMReceive2 = GMReceive
            end
    end,
    get_gm_letter2(R, GMIDList2, Level, GameChannelID, CreateTime, LastLoginTime, LastOfflineTime, GMReceive2, IsGetLetter2).

%% 删除角色内过期的信件
del_out_time_letter(ReceiveBox) ->
    Now = time_tool:now(),
    [Letter || Letter <- ReceiveBox, Letter#r_letter.end_time >= Now].

level_up(State) ->
    do_get_gm_letter(State).

%% ====================================================================
%%% Internal functions
%% ====================================================================
handle(gm_letter, State) ->
    do_get_gm_letter(State);
handle({#m_letter_get_tos{}, _RoleID, _PID}, State) ->
    do_get_letter(State);
handle({#m_letter_open_tos{letter_id = LetterID}, RoleID, _PID}, State) ->
    do_open_letter(RoleID, LetterID, State);
handle({#m_letter_delete_tos{op_type = ?DELETE_ALL_LETTER}, RoleID, _PID}, State) ->
    do_delete_all_letter(RoleID, State);
handle({#m_letter_delete_tos{op_type = ?DELETE_LETTER, id_list = IDList}, RoleID, _PID}, State) ->
    do_delete_letter(RoleID, IDList, State);
handle({#m_letter_accept_goods_tos{op_type = ?RECEIVE_ALL_LETTER}, RoleID, _PID}, State) ->
    do_accept_all_goods(RoleID, State);
handle({#m_letter_accept_goods_tos{op_type = ?RECEIVE_LETTER, id_list = IDList}, RoleID, _PID}, State) ->
    do_accept_goods(RoleID, IDList, State);
handle(Info, State) ->
    ?ERROR_MSG("mod_role_letter模块收到未知的消息~w", [Info]),
    State.

%% 在线获取GM邮件
do_get_gm_letter(State) ->
    #r_role{role_id = RoleID, role_letter = RoleLetter} = State,
    #r_role_letter{counter = Counter, receive_box = ReceiveBox, gm_id_list = GMIDList} = RoleLetter,
    {GMIDList2, GMReceive, IsGetLetter} = get_gm_letter(GMIDList, State),
    {Counter2, GMReceive2} = receive_add_counter(GMReceive, Counter, []),
    ReceiveBox2 = GMReceive2 ++ ReceiveBox,
    mod_role_dict:set_gm_letters(GMReceive2 ++ mod_role_dict:get_gm_letters()),
    ?IF(IsGetLetter, common_misc:unicast(RoleID, #m_letter_light_toc{}), ok),
    ?TRY_CATCH(log_role_letter(GMReceive2, State)),
    RoleLetter2 = RoleLetter#r_role_letter{counter = Counter2, receive_box = ReceiveBox2, gm_id_list = GMIDList2},
    State#r_role{role_letter = RoleLetter2}.

%% 获取已接收的邮件,前端上线时请求一次
do_get_letter(State) ->
    #r_role{role_id = RoleID, role_letter = RoleLetter} = State,
    #r_role_letter{counter = Counter, receive_box = ReceiveBox} = RoleLetter,
    %% 前端发起请求时可能已经有新信件了
    WorldReceive = get_world_letter(RoleID),
    {Counter2, NewLetters} = receive_add_counter(WorldReceive, Counter, []),
    ReceiveBox2 = NewLetters ++ ReceiveBox,
    case mod_role_dict:get_all_letter() of
        true ->
            OpType = ?GET_LETTER_NEW,
            GMLetters = mod_role_dict:get_gm_letters(),
            PLetters = trans_to_p_letter(NewLetters ++ GMLetters);
        _ ->
            mod_role_dict:set_all_letter(true),
            OpType = ?GET_LETTER_ALL,
            PLetters = trans_to_p_letter(ReceiveBox2)
    end,
    mod_role_dict:set_gm_letters([]),
    R = #m_letter_get_toc{op_type = OpType, letters = PLetters},
    common_misc:unicast(RoleID, R),
    ?TRY_CATCH(log_role_letter(NewLetters, State)),
    RoleLetter2 = RoleLetter#r_role_letter{counter = Counter2, receive_box = ReceiveBox2},
    State#r_role{role_letter = RoleLetter2}.

%% 打开信件/后端纯粹记录
do_open_letter(RoleID, LetterID, State) ->
    #r_role{role_letter = RoleLetter} = State,
    #r_role_letter{receive_box = ReceiveBox} = RoleLetter,
    case lists:keyfind(LetterID, #r_letter.id, ReceiveBox) of
        #r_letter{letter_state = LetterState} = Letter ->
            case LetterState =:= ?LETTER_NOT_OPEN of
                true ->
                    ReceiveBox2 = lists:keystore(LetterID, #r_letter.id, ReceiveBox, Letter#r_letter{letter_state = ?LETTER_HAS_OPEN}),
                    RoleLetter2 = RoleLetter#r_role_letter{receive_box = ReceiveBox2},
                    Stat2 = State#r_role{role_letter = RoleLetter2};
                _ ->
                    Stat2 = State
            end,
            DataRecord = #m_letter_open_toc{letter_id = LetterID};
        _ ->
            Stat2 = State,
            DataRecord = #m_letter_open_toc{err_code = ?ERROR_LETTER_OPEN_001}
    end,
    common_misc:unicast(RoleID, DataRecord),
    Stat2.

%% 删除所有信件
do_delete_all_letter(RoleID, State) ->
    #r_role{role_letter = RoleLetter} = State,
    #r_role_letter{receive_box = ReceiveBox} = RoleLetter,
    {ReceiveBox2, IDList} =
        lists:foldl(
            fun(#r_letter{id = ID, letter_state = LetterState, goods_list = GoodsList} = Letter, {LetterAcc, DelIDs}) ->
                case (LetterState =:= ?LETTER_HAS_OPEN andalso GoodsList =:= []) of
                    true ->
                        {LetterAcc, [ID|DelIDs]};
                    _ ->
                        {[Letter|LetterAcc], DelIDs}
                end
            end, {[], []}, ReceiveBox),
    R = #m_letter_delete_toc{op_type = ?DELETE_ALL_LETTER, id_list = IDList},
    common_misc:unicast(RoleID, R),
    RoleLetter2 = RoleLetter#r_role_letter{receive_box = ReceiveBox2},
    State#r_role{role_letter = RoleLetter2}.

%% 删除选定的信件
do_delete_letter(RoleID, IDList, State) ->
    #r_role{role_letter = RoleLetter} = State,
    #r_role_letter{receive_box = ReceiveBox} = RoleLetter,
    case catch check_letter_delete(IDList, ReceiveBox, []) of
        {ok, ReceiveBox2} ->
            R = #m_letter_delete_toc{op_type = ?DELETE_LETTER, id_list = IDList},
            common_misc:unicast(RoleID, R),
            RoleLetter2 = RoleLetter#r_role_letter{receive_box = ReceiveBox2},
            State#r_role{role_letter = RoleLetter2};
        {error, ErrorCode} ->
            common_misc:unicast(RoleID, #m_letter_delete_toc{err_code = ErrorCode}),
            State
    end.

check_letter_delete([], ReceiveBox, ReceiveBoxAcc) ->
    {ok, ReceiveBox ++ ReceiveBoxAcc};
check_letter_delete(_IDList, [], _ReceiveBoxAcc) ->
    ?THROW_ERR(?ERROR_LETTER_OPEN_001);
check_letter_delete(IDList, [Letter|R], ReceiveBoxAcc) ->
    case lists:member(Letter#r_letter.id, IDList) of
        true ->
            IDList2 = lists:delete(Letter#r_letter.id, IDList),
            ReceiveBoxAcc2 = ReceiveBoxAcc;
        false ->
            IDList2 = IDList,
            ReceiveBoxAcc2 = [Letter|ReceiveBoxAcc]
    end,
    check_letter_delete(IDList2, R, ReceiveBoxAcc2).


do_accept_all_goods(RoleID, State) ->
    case catch check_accept_all(State) of
        {ok, State2, BagDoings} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_letter_accept_goods_toc{op_type = ?RECEIVE_ALL_LETTER}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_letter_accept_goods_toc{err_code = ErrCode}),
            State
    end.

check_accept_all(State) ->
    #r_role{role_letter = RoleLetter} = State,
    #r_role_letter{receive_box = ReceiveBox} = RoleLetter,
    {ReceiveBox2, GoodsList, BagDoings} = check_accept_all2(ReceiveBox, [], [], []),
    ?IF(mod_role_bag:check_bag_empty_grid(GoodsList, State), ok, ?THROW_ERR(?ERROR_COMMON_BAG_FULL)),
    RoleLetter2 = RoleLetter#r_role_letter{receive_box = ReceiveBox2},
    State2 = State#r_role{role_letter = RoleLetter2},
    {ok, State2, BagDoings}.

check_accept_all2([], ReceiveBoxAcc, GoodsAcc, BagDoingsAcc) ->
    {ReceiveBoxAcc, GoodsAcc, BagDoingsAcc};
check_accept_all2([Letter|R], ReceiveBoxAcc, GoodsAcc, BagDoingsAcc) ->
    #r_letter{action = Action, goods_list = LetterGoods} = Letter,
    GoodsAcc2 = LetterGoods ++ GoodsAcc,
    Letter2 = Letter#r_letter{goods_list = [], letter_state = ?LETTER_HAS_OPEN},
    ReceiveBoxAcc2 = [Letter2|ReceiveBoxAcc],
    BagDoings = ?IF(LetterGoods =/= [], [{create, Action, LetterGoods}], []),
    BagDoingsAcc2 = BagDoings ++ BagDoingsAcc,
    check_accept_all2(R, ReceiveBoxAcc2, GoodsAcc2, BagDoingsAcc2).

%% 获取信件中的道具
do_accept_goods(RoleID, IDList, State) ->
    #r_role{role_letter = RoleLetter} = State,
    #r_role_letter{receive_box = ReceiveBox} = RoleLetter,
    case catch check_can_accept(IDList, ReceiveBox, State) of
        {ok, ReceiveBox2, BagDoings} ->
            State2 = mod_role_bag:do(BagDoings, State),
            RoleLetter2 = RoleLetter#r_role_letter{receive_box = ReceiveBox2},
            common_misc:unicast(RoleID, #m_letter_accept_goods_toc{op_type = ?RECEIVE_LETTER, id_list = IDList}),
            State2#r_role{role_letter = RoleLetter2};
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_letter_accept_goods_toc{err_code = ErrCode}),
            State
    end.

check_can_accept(IDList, ReceiveBox, State) ->
    {ok, ReceiveBox2, GoodsList, BagDoings} = check_can_accept2(IDList, ReceiveBox, [], [], []),
    ?IF(mod_role_bag:check_bag_empty_grid(GoodsList, State), ok, ?THROW_ERR(?ERROR_COMMON_BAG_FULL)),
    {ok, ReceiveBox2, BagDoings}.


check_can_accept2([], ReceiveBox, ReceiveBoxAcc, GoodsAcc, BagDoingsAcc) ->
    {ok, ReceiveBox ++ ReceiveBoxAcc, GoodsAcc, BagDoingsAcc};
check_can_accept2(_IDList, [], _ReceiveBoxAcc, _GoodsAcc, _BagDoingsAcc) ->
    ?THROW_ERR(?ERROR_LETTER_OPEN_001);
check_can_accept2(IDList, [Letter|R], ReceiveBoxAcc, GoodsAcc, BagDoingsAcc) ->
    #r_letter{id = ID, action = Action, goods_list = LetterGoods} = Letter,
    case lists:member(ID, IDList) of
        true ->
            IDList2 = lists:delete(ID, IDList),
            Letter2 = Letter#r_letter{goods_list = [], letter_state = ?LETTER_HAS_OPEN},
            ReceiveBoxAcc2 = [Letter2|ReceiveBoxAcc],
            GoodsAcc2 = LetterGoods ++ GoodsAcc,
            BagDoings = ?IF(LetterGoods =/= [], [{create, Action, LetterGoods}], []),
            BagDoingsAcc2 = BagDoings ++ BagDoingsAcc;
        false ->
            IDList2 = IDList,
            ReceiveBoxAcc2 = [Letter|ReceiveBoxAcc],
            GoodsAcc2 = GoodsAcc,
            BagDoingsAcc2 = BagDoingsAcc
    end,
    check_can_accept2(IDList2, R, ReceiveBoxAcc2, GoodsAcc2, BagDoingsAcc2).


trans_to_p_letter(List) when erlang:is_list(List) ->
    [trans_to_p_letter(Letter) || Letter <- List];
trans_to_p_letter(Letter) ->
    #r_letter{
        id = LetterID,
        letter_state = LetterState,
        send_time = SendTime,
        template_id = TemplateID,
        goods_list = GoodsList,
        title_string = TitleString,
        text_string = TextString} = Letter,
    #p_letter{
        id = LetterID,
        letter_state = LetterState,
        send_time = SendTime,
        template_id = TemplateID,
        goods_list = GoodsList,
        title_string = TitleString,
        text_string = TextString}.


log_role_letter([], _State) ->
    ok;
log_role_letter(Letters, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    LogList =
        [ #log_role_mail{
            role_id = RoleID,
            template_id = TemplateID,
            title_strings = TitleStrings,
            text_strings = TextStrings,
            gold = Gold,
            goods_list = GoodsString,
            channel_id = ChannelID,
            game_channel_id = GameChannelID
        }|| {TemplateID, TitleStrings, TextStrings, Gold, GoodsString} <- get_log_letters(Letters, [])],
    mod_role_dict:add_background_logs(LogList).

get_log_letters([], Acc) ->
    Acc;
get_log_letters([Letter|R], Acc) ->
    #r_letter{
        template_id = TemplateID,
        title_string = TitleString,
        text_string = TextString,
        goods_list = GoodsList
    } = Letter,
    TitleString2 = common_misc:get_log_string(TitleString),
    TextString2 = common_misc:get_log_string(TextString),
    {Gold, GoodsString} = get_log_goods(GoodsList, 0, ""),
    Acc2 = [{TemplateID, TitleString2, TextString2, Gold, GoodsString}|Acc],
    get_log_letters(R, Acc2).


get_log_goods([], Gold, GoodsList) ->
    {Gold, common_misc:to_goods_string(GoodsList)};
get_log_goods([Goods|R], GoldAcc, GoodsAcc) ->
    #p_goods{type_id = TypeID, num = Num} = Goods,
    case TypeID =:= ?BAG_ASSET_GOLD orelse TypeID =:= ?BAG_ASSET_BIND_GOLD of
        true ->
            get_log_goods(R, GoldAcc + Num, GoodsAcc);
        _ ->
            get_log_goods(R, GoldAcc, [Goods|GoodsAcc])
    end.

receive_add_counter([], CounterAcc, LetterAcc) ->
    {CounterAcc, LetterAcc};
receive_add_counter([Letter|R], Counter, Acc) ->
    Acc2 = [Letter#r_letter{id = Counter}|Acc],
    receive_add_counter(R, Counter + 1, Acc2).

%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 七月 2018 20:33
%%%-------------------------------------------------------------------
-module(mod_role_title).
-author("laijichang").
-include("role.hrl").
-include("family.hrl").
-include("proto/mod_role_title.hrl").

%% API
-export([
    init/1,
    calc/1,
    online/1,
    loop_min/2,
    handle/2
]).

-export([
    family_title_change/2,

    add_title/3
]).

-export([
    add_vip_title/1,
    del_vip_title/1,
    update_title/3,
    off_line_update_title/2
]).

-export([
    gm_add_title/2,
    gm_del_title/2
]).

%% 加称号的话，暂时是加永久称号
update_title(Title, Type, RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, {deal_title, Title, Type}});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, off_line_update_title, [Title, Type]})
    end.

off_line_update_title(Title, Type) ->
    erlang:send(erlang:self(), {mod, ?MODULE, {deal_title, Title, Type}}).

init(#r_role{role_id = RoleID, role_title = undefined} = State) ->
    RoleTitle = #r_role_title{role_id = RoleID},
    State#r_role{role_title = RoleTitle};
init(State) ->
    State.

calc(State) ->
    #r_role{role_title = RoleTitle} = State,
    #r_role_title{titles = Titles} = RoleTitle,
    CalcAttr = calc_title(Titles, #actor_cal_attr{}),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_TITLE, CalcAttr).

calc_title([], Attr) ->
    Attr;
calc_title([#p_kv{id = TitleID}|R], Attr) ->
    [#c_title{
        add_attack = AddAttack,
        add_hp = AddHp,
        add_arp = AddArp,
        add_defence = AddDefence,
        special_props = SpecialProps
    }] = lib_config:find(cfg_title, TitleID),
    Attr2 =
        #actor_cal_attr{  %% T  0 是比例
            attack = {AddAttack, 0},
            max_hp = {AddHp, 0},
            arp = {AddArp, 0},
            defence = {AddDefence, 0}
        },
    Attr3 = common_misc:get_attr_by_kv(common_misc:get_string_props(SpecialProps)),
    CalcAttr = common_misc:sum_calc_attr([Attr, Attr2, Attr3]),
    calc_title(R, CalcAttr).

online(State) ->
    #r_role{role_id = RoleID, role_title = RoleTitle} = State,
    #r_role_title{cur_title = CurTitle, titles = Titles} = RoleTitle,
    common_misc:unicast(RoleID, #m_title_info_toc{cur_title = CurTitle, titles = Titles}),
    loop_min(time_tool:now(), State).

family_title_change(FamilyTitleID, State) ->
    [_, TitleID|_] = common_misc:get_global_list(?GLOBAL_FAMILY_POPULAR),
    case FamilyTitleID of
        ?TITLE_POPULAR -> %% 获得人气甜心的称号 ++++
            State2 = add_title(0, TitleID, State),
            do_title_change(State#r_role.role_id, TitleID, State2);
        _ ->
            del_titles([TitleID], State)
    end.

add_title(EndTime, TitleID, State) ->
    #r_role{role_id = RoleID, role_title = RoleTitle} = State,
    #r_role_title{titles = Titles} = RoleTitle,
    case lists:keyfind(TitleID, #p_kv.id, Titles) of
        #p_kv{val = 0} -> %% 永久称号
            State;
        _ ->
            [#c_title{is_forever = IsForever}] = lib_config:find(cfg_title, TitleID),
            KV = ?IF(?IS_FOREVER_TITLE(IsForever), #p_kv{id = TitleID, val = 0}, #p_kv{id = TitleID, val = EndTime}),
            Titles2 = lists:keystore(TitleID, #p_kv.id, Titles, KV),
            common_misc:unicast(RoleID, #m_title_update_toc{update_titles = [KV]}),
            case Titles =:= [] of %% 原本没有称号
                true ->
                    RoleTitle2 = RoleTitle#r_role_title{cur_title = TitleID, titles = Titles2},
                    common_misc:unicast(RoleID, #m_title_change_toc{cur_title = TitleID}),
                    mod_map_role:update_role_title(mod_role_dict:get_map_pid(), RoleID, TitleID);
                _ ->
                    RoleTitle2 = RoleTitle#r_role_title{titles = Titles2}
            end,
            State2 = State#r_role{role_title = RoleTitle2},
            mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_TITLE_ADD, TitleID)
    end.

del_titles(DelList, State) ->
    #r_role{role_id = RoleID, role_title = RoleTitle} = State,
    #r_role_title{cur_title = CurTitle, titles = Titles} = RoleTitle,
    {Titles2, DelList2} =
        lists:foldl(
            fun(#p_kv{id = DelTitleID} = Title, {Acc1, Acc2}) ->
                case lists:member(DelTitleID, DelList) of
                    true ->
                        {Acc1, [DelTitleID|Acc2]};
                    _ ->
                        {[Title|Acc1], Acc2}
                end
            end, {[], []}, Titles),
    case lists:member(CurTitle, DelList) of
        true ->
            CurTitleID = 0,
            RoleTitle2 = RoleTitle#r_role_title{cur_title = CurTitleID, titles = Titles2},
            common_misc:unicast(RoleID, #m_title_change_toc{cur_title = 0}),
            mod_map_role:update_role_title(mod_role_dict:get_map_pid(), RoleID, CurTitleID);
        _ ->
            RoleTitle2 = RoleTitle#r_role_title{titles = Titles2}
    end,
    State2 = State#r_role{role_title = RoleTitle2},
    case DelList2 =/= [] of
        true ->
            common_misc:unicast(RoleID, #m_title_update_toc{del_titles = DelList2}),
            mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_TITLE_DEL, 0);
        _ ->
            State2
    end.

add_vip_title(State) ->
    Titles = mod_role_vip:get_vip_titles(State),
    Titles2 = lists:reverse(lists:sort(Titles)),
    State2 = add_vip_title2(Titles2, State),
    #r_role{role_id = RoleID, role_title = RoleTitle} = State2,
    #r_role_title{cur_title = CurTitle} = RoleTitle,
    case lists:member(CurTitle, Titles2) andalso CurTitle =/= lists:nth(1, Titles2) of
        true ->
            TitleID = lists:nth(1, Titles2),
            RoleTitle2 = RoleTitle#r_role_title{cur_title = TitleID},
            common_misc:unicast(RoleID, #m_title_change_toc{cur_title = TitleID}),
            mod_map_role:update_role_title(mod_role_dict:get_map_pid(), RoleID, TitleID),
            State2#r_role{role_title = RoleTitle2};
        _ ->
            State2
    end.

add_vip_title2([], State) ->
    State;
add_vip_title2([TitleID|R], State) ->
    State2 = add_title(0, TitleID, State),
    add_vip_title2(R, State2).

del_vip_title(State) ->
    Titles = mod_role_vip:get_vip_titles(State),
    del_titles(Titles, State).

gm_add_title(TitleID, State) ->
    [#c_title{is_forever = IsForever}] = lib_config:find(cfg_title, TitleID),
    EndTime = ?IF(?IS_FOREVER_TITLE(IsForever), 0, time_tool:now() + ?ONE_DAY),
    add_title(EndTime, TitleID, State).

gm_del_title(TitleID, State) ->
    del_titles([TitleID], State).

loop_min(Now, State) ->
    #r_role{role_title = RoleTitle} = State,
    #r_role_title{titles = Titles} = RoleTitle,
    DelList =
    lists:foldl(
        fun(#p_kv{id = ID, val = Time}, DelAcc) ->
            case (not ?IS_FOREVER_TIME(Time)) andalso Now >= Time of
                true ->
                    [ID|DelAcc];
                _ ->
                    DelAcc
            end
        end, [], Titles),
    del_titles(DelList, State).

handle({#m_title_change_tos{title_id = TitleID}, RoleID, _PID}, State) ->
    do_title_change(RoleID, TitleID, State);
handle({deal_title, Title, Type}, State) ->
    do_deal_title(State, Title, Type).

do_title_change(RoleID, TitleID, State) ->
    case catch check_title_change(TitleID, State) of
        {ok, State2} ->
            mod_map_role:update_role_title(mod_role_dict:get_map_pid(), RoleID, TitleID),
            common_misc:unicast(RoleID, #m_title_change_toc{cur_title = TitleID}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_title_change_toc{err_code = ErrCode}),
            State
    end.

check_title_change(TitleID, State) ->
    #r_role{role_title = RoleTitle} = State,
    #r_role_title{cur_title = CurTitle, titles = Titles} = RoleTitle,
    ?IF(TitleID =:= CurTitle, ?THROW_ERR(?ERROR_TITLE_CHANGE_001), ok),
    ?IF(TitleID =:= 0 orelse lists:keymember(TitleID, #p_kv.id, Titles), ok, ?THROW_ERR(?ERROR_TITLE_CHANGE_002)),
    RoleTitle2 = RoleTitle#r_role_title{cur_title = TitleID},
    State2 = State#r_role{role_title = RoleTitle2},
    {ok, State2}.


do_deal_title(State, Title, Type) ->
    case Type of
        ?REMOVE_TITLE ->
            del_titles([Title], State);
        ?ADD_TITLE ->
            add_title(0, Title, State);
        _ ->
            State
    end.
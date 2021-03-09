%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十一月 2017 19:49
%%%-------------------------------------------------------------------
-module(mod_role_rank).
-include("global.hrl").
-include("rank.hrl").
-include("proto/mod_role_rank.hrl").
-include("role.hrl").
-include("role_extra.hrl").
-include("copy.hrl").


%% API
-export([
    online/1,
    handle/2,
    loop/2,
    offline/1
]).

-export([
    update_rank/2,
    rank_now/0
]).

-define(MAX_RANK_FREQUENT, 10).     %% 玩家请求更新频率
-define(RANK_FRESH_INTERVAL, 300).  %% 定时刷新的频率

handle(rank_now, State) ->
    rank_now(),
    State;
handle({#m_rank_info_tos{rank_id = RankID}, RoleID, _PID}, State) ->
    do_rank_info(RoleID, RankID, State);
handle(Info, State) ->
    ?ERROR_MSG("unkow info :~w",[Info]),
    State.

loop(Now, State)->
    case  Now - mod_role_dict:get_rank_time() >= ?RANK_FRESH_INTERVAL of
        true->
            rank_now(),
            State;
        _ ->
            State
    end.

online(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_copy = RoleCopy, calc_list = CalcList} = State,
    #r_role_attr{level = RoleLevel, max_power = MaxPower} = RoleAttr,
    MergeServerID = mod_role_extra:get_data(?EXTRA_KEY_MERGE_SERVER, 0, State),
    NowServerID = common_config:get_server_id(),
    case MergeServerID =/= NowServerID of
        true -> %% 合服后上线重新推一下排行榜数据
            Now = time_tool:now(),
            #r_role_copy{cur_five_elements = CurFiveElements, tower_id = CurTowerID} = RoleCopy,
            update_rank(?RANK_ROLE_POWER, {RoleID, MaxPower, Now}),
            ?IF(RoleLevel > 100, update_rank(?RANK_ROLE_LEVEL, {RoleID, RoleLevel, Now}), ok),
            ?IF(CurFiveElements > 0, update_rank(?RANK_COPY_FIVE_ELEMENTS, {RoleID, CurFiveElements, Now}), ok),
            ?IF(CurTowerID > 0, update_rank(?RANK_COPY_TOWER, {RoleID, ?GET_TOWER_FLOOR(CurTowerID), Now}), ok),
            ?TRY_CATCH(update_rank_power([?CALC_KEY_MOUNT, ?CALC_KEY_PET, ?CALC_KEY_MAGIC_WEAPON, ?CALC_KEY_GOD_WEAPON, ?CALC_KEY_WING], CalcList, State)),
            mod_role_extra:set_data(?EXTRA_KEY_MERGE_SERVER, NowServerID, State);
        _ ->
            State
    end.

update_rank_power([], _CalcList, _State) ->
    ok;
update_rank_power([Key|R], CalcList, State) ->
    case lists:keyfind(Key, #r_calc.key, CalcList) of
        #r_calc{power = NewPower} when NewPower > 0->
            if
                Key =:= ?CALC_KEY_MOUNT ->
                    MountID = State#r_role.role_mount#r_role_mount.mount_id,
                    mod_role_rank:update_rank(?RANK_MOUNT_POWER, {State#r_role.role_id, NewPower, MountID, time_tool:now()});
                Key =:= ?CALC_KEY_PET ->
                    #r_role_pet{pet_id = PetID} = State#r_role.role_pet,
                    mod_role_rank:update_rank(?RANK_PET_POWER, {State#r_role.role_id, NewPower, PetID, time_tool:now()});
                Key =:= ?CALC_KEY_MAGIC_WEAPON ->
                    MagicWeaponLevel = State#r_role.role_magic_weapon#r_role_magic_weapon.level,
                    mod_role_rank:update_rank(?RANK_MAGIC_WEAPON_POWER, {State#r_role.role_id, NewPower, MagicWeaponLevel, time_tool:now()});
                Key =:= ?CALC_KEY_GOD_WEAPON ->
                    #r_role_god_weapon{level = GodWeaponLevel} = State#r_role.role_god_weapon,
                    mod_role_rank:update_rank(?RANK_GOD_WEAPON_POWER, {State#r_role.role_id, NewPower, GodWeaponLevel, time_tool:now()});
                Key =:= ?CALC_KEY_WING ->
                    #r_role_wing{level = Level} = State#r_role.role_wing,
                    mod_role_rank:update_rank(?RANK_WING_POWER, {State#r_role.role_id, NewPower, Level, time_tool:now()})
            end;
        _ ->
            ok
    end,
    update_rank_power(R, CalcList, State).


offline(State)->
    rank_now(),
    State.

%% RankItem -> 第一位必须是key
update_rank(RankID, RankItem)->
    add_rank_item(RankID, RankItem).

add_rank_item(RankID, RankItem)->
    Key = erlang:element(1, RankItem),
    NewRanks = lists:keystore({RankID, Key}, 1, mod_role_dict:get_ranks(), {{RankID, Key}, RankItem}),
    mod_role_dict:set_ranks(NewRanks),
    NewTimes = mod_role_dict:get_rank_update() + 1,
    case NewTimes >= ?MAX_RANK_FREQUENT of
        true->
            rank_now();
        _->
            ignore
    end.

%% @doc 开始排行
rank_now()->
    Ranks = mod_role_dict:get_ranks(),
    Ranks2 = modify_ranks(Ranks, []),
    [begin
         rank_misc:rank_insert_elements(RankID, RankItems)
     end || {RankID, RankItems} <- Ranks2],
    mod_role_dict:set_ranks([]),
    mod_role_dict:set_rank_update(0),
    mod_role_dict:set_rank_time(time_tool:now()).

modify_ranks([], Acc) ->
    Acc;
modify_ranks([{{RankID, _Key}, RankItem}|R], Acc) ->
    case lists:keyfind(RankID, 1, Acc) of
        {RankID, RankItems} ->
            Acc2 = lists:keyreplace(RankID, 1, Acc, {RankID, [RankItem|RankItems]});
        _ ->
            Acc2 = [{RankID, [RankItem]}|Acc]
    end,
    modify_ranks(R, Acc2).

do_rank_info(RoleID, RankID, State) ->
    case lists:keyfind(RankID, #c_rank_config.rank_id, ?RANK_LIST) of
        #c_rank_config{mod = Mod, show_num = ShowNum} ->
            case erlang:function_exported(Mod, trans_to_p_rank, 1) of
                true ->
                    Ranks = rank_misc:get_rank(RankID),
                    Ranks2 = Mod:trans_to_p_rank(Ranks),
                    Ranks3 = lists:sublist(lists:keysort(#p_rank.rank, Ranks2), ShowNum),
                    common_misc:unicast(RoleID, #m_rank_info_toc{rank_id = RankID, ranks = Ranks3});
                _ ->
                    ?ERROR_MSG("Error : function not exported RankID : ~w", [RankID]),
                    common_misc:unicast(RoleID, #m_rank_info_toc{rank_id = RankID})
            end;
        _ ->
            common_misc:unicast(RoleID, #m_rank_info_toc{rank_id = RankID})
    end,
    State.

%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. 三月 2018 15:55
%%%-------------------------------------------------------------------
-module(mod_role_family_td).
-author("laijichang").
-include("role.hrl").
-include("global.hrl").
-include("activity.hrl").
-include("family_td.hrl").
-include("family.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_map_family_td.hrl").

%% API
-export([
    handle/2
]).

-export([
    is_able/1,
    check_role_pre_enter/1,
    check_is_open/1
]).

handle({buff_multi, BuffMulti}, State) ->
    do_buff_multi(BuffMulti, State);
handle({family_td_end, TDEnd}, State) ->
    do_family_td_end(TDEnd, State).

do_buff_multi(BuffMulti, State) ->
    RoleID = State#r_role.role_id,
    BuffID = ?FAMILY_TD_EXP_BUFF,
    State2 = mod_role_buff:do_remove_buff([BuffID], State),
    case BuffMulti > 0 of
        true ->
            BuffList = [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || _Times <- lists:seq(1, BuffMulti)],
            mod_role_buff:do_add_buff(BuffList, State2);
        _ ->
            State
    end.

do_family_td_end(TDEnd, State) ->
    #r_family_td_end{
        is_succ = IsSucc,
        kill_num = KillNum,
        kill_exp = KillExp,
        star = Star,
        star_exp = StarExp,
        rank_list = RankList
    } = TDEnd,
    #r_role{role_id = RoleID, role_map_panel = RoleMapPanel, role_attr = #r_role_attr{family_id = FamilyID}} = State,
    #r_role_map_panel{panel_list = PanelList} = RoleMapPanel,
    PanelExp =
    case lists:keyfind(?MAP_FAMILY_TD, #r_map_panel.map_id, PanelList) of
        #r_map_panel{exp = Exp} ->
            Exp;
        _ ->
            0
    end,
    ets:insert(?ETS_FAMILY_TD_REWARD, #p_kv{id = State#r_role.role_id, val = 1}),
    case IsSucc of
        true ->
            case lists:keyfind(RoleID, #p_family_td_rank.role_id, RankList) of
                #p_family_td_rank{rank = Rank} ->
                    RankRate = get_rank_rate(Rank),
                    RankExp = lib_tool:ceil(KillExp * RankRate / ?RATE_10000);
                _ ->
                    RankExp = 0
            end,
            DataRecord = #m_family_td_end_toc{
                is_succ = IsSucc,
                star = Star,
                kill_num = KillNum,
                kill_monster_exp = PanelExp,
                star_exp = StarExp,
                rank_exp = RankExp
            },
            common_misc:unicast(RoleID, DataRecord),
            [Score, AddMoney] = common_misc:get_global_list(?GLOBAL_FAMILY_TD_STAR_EXP),
            mod_family_operation:add_family_money(FamilyID, AddMoney),
            AssetDoing = [{add_score, ?ASSET_FAMILY_SCORE_FROM_FAMILY_TD, ?ASSET_FAMILY_CON, Score}],
            State2 = mod_role_level:do_add_exp(State, StarExp + RankExp, ?EXP_ADD_FROM_FAMILY_TD),
            mod_role_asset:do(AssetDoing, State2);
        _ ->
            DataRecord = #m_family_td_end_toc{
                is_succ = IsSucc,
                star = Star,
                kill_num = KillNum,
                kill_monster_exp = PanelExp
            },
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

is_able(_State) ->
    case mod_family_td:is_activity_open() of
        true ->
            true;
        _ ->
            false
    end.

check_role_pre_enter(State) ->
    case mod_family_td:is_activity_open() of
        true ->
            #r_role{role_id = RoleID} = State,
            #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
            [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ?ACTIVITY_FAMILY_TD),
            ?IF(mod_role_data:get_role_level(State) >= MinLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
            case ets:lookup(?ETS_FAMILY_TD_REWARD, RoleID) of
                [#p_kv{val = 1}] ->
                    ?THROW_ERR(?ERROR_PRE_ENTER_016);
                _ ->
                    ok
            end,
            case ?HAS_FAMILY(FamilyID) of
                true ->
                    #r_family_td{is_map_open = IsOpen, is_end = IsEnd} = mod_family_td:get_family_td(FamilyID),
                    ?IF(IsEnd, ?THROW_ERR(?ERROR_PRE_ENTER_015), ok),
                    ?IF(IsOpen, ok, mod_family_td:start_family_td(FamilyID)),
                    {ok, BornPos} = map_misc:get_born_pos(?MAP_FAMILY_TD),
                    {FamilyID, ?DEFAULT_CAMP_ROLE, BornPos};
                _ ->
                    ?THROW_ERR(?ERROR_PRE_ENTER_014)
            end;
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_011)
    end.

check_is_open(State) ->
    case mod_family_td:is_activity_open() of
        true ->
            #r_role{role_id = RoleID} = State,
            #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
            case ?HAS_FAMILY(FamilyID) of
                true ->
                    [#c_activity{min_level = MinLevel}] = lib_config:find(cfg_activity, ?ACTIVITY_FAMILY_TD),
                    #r_family_td{is_end = IsEnd} = mod_family_td:get_family_td(FamilyID),
                    not IsEnd andalso mod_role_data:get_role_level(State) >= MinLevel;
                _ ->
                    false
            end;
        _ ->
            false
    end.

get_rank_rate(Rank) ->
    List = cfg_family_td_rank_exp:list(),
    get_rank_rate2(Rank, List).

get_rank_rate2(Rank, [{{MinRank, MaxRank}, Config}|R]) ->
    case MinRank =< MinRank andalso Rank =< MaxRank of
        true ->
            Config#c_family_td_rank_exp.rate;
        _ ->
            get_rank_rate2(Rank, R)
    end.
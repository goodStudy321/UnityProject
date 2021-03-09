%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 九月 2019 10:16
%%%-------------------------------------------------------------------
-module(mod_role_universe).
-author("laijichang").
-include("role.hrl").
-include("copy.hrl").
-include("role_extra.hrl").
-include("universe.hrl").
-include("proto/mod_role_universe.hrl").
-include("proto/mod_role_copy.hrl").

%% API
-export([
    online/1,
    zero/1,
    handle/2,
    loop_10min/2
]).

-export([
    function_open/1,
    role_finish_copy/4
]).

online(State) ->
    case mod_role_function:get_is_function_open(?FUNCTION_UNIVERSE, State) of
        true ->
            do_send_info(State);
        _ ->
            ok
    end,
    loop_10min(time_tool:now(), State),
    do_check_universe(State).

zero(State) ->
    do_send_info(State),
    State.

function_open(State) ->
    do_send_info(State),
    State.

loop_10min(_Now, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        category = Category,
        sex = Sex,
        level = Level,
        skin_list = SkinList
    } = RoleAttr,
    ConfineID = mod_role_confine:get_confine_id(State),
    Ranks = game_universe_server:get_ranks(),
    case lists:keyfind(RoleID, #r_universe_rank.role_id, Ranks) of
        #r_universe_rank{} = Rank ->
            #r_universe_rank{
                role_name = RankRoleName,
                confine_id = RankConfineID,
                category = RankCategory,
                sex = RankSex,
                level = RankLevel,
                skin_list = RankSkinList
            } = Rank,
            case RoleName =/= RankRoleName orelse RankConfineID =/= ConfineID orelse RankCategory =/= Category orelse RankSex =/= Sex orelse
                RankLevel =/= Level orelse (SkinList -- RankSkinList =/= []) of
                true -> %% 有变化，更新
                    Info = #universe_role_info{
                        role_id = RoleID,
                        role_name = RoleName,
                        confine_id = mod_role_confine:get_confine_id(State),
                        category = Category,
                        sex = Sex,
                        level = Level,
                        skin_list = SkinList
                    },
                    center_universe_server:role_update_info(Info);
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    State.

handle({#m_universe_floor_info_tos{copy_id = CopyID}, RoleID, _PID}, State) ->
    do_universe_floor_info(RoleID, CopyID),
    State;
handle({#m_universe_rank_tos{}, RoleID, _PID}, State) ->
    do_universe_rank(RoleID),
    State;
handle({#m_universe_admire_tos{}, RoleID, _PID}, State) ->
    do_universe_admire(RoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info: ~w", [Info]),
    State.

role_finish_copy(CopyID, UseTime, Power, State) ->
    UniverseInfo = get_universe_info(CopyID, UseTime, Power, State),
    UpdateList1 =
        case game_universe_server:get_floor(CopyID) of
            #r_universe_floor{power = RankPower, use_time = RankUseTime} ->
                ?IF(Power < RankPower orelse UseTime < RankUseTime, [?UNIVERSE_UPDATE_KEY_FLOOR], []);
            _ ->
                [?UNIVERSE_UPDATE_KEY_FLOOR]
        end,
    UpdateList2 = ?IF(center_universe_server:is_rank_update(UniverseInfo, game_universe_server:get_ranks()),
        [?UNIVERSE_UPDATE_FLOOR_RANK|UpdateList1], UpdateList1),
    case UpdateList2 =/= [] of
        true ->
            case catch center_universe_server:role_finish_copy(UniverseInfo#universe_info{update_list = UpdateList2}) of
                [_|_] = ResultList ->
                    case lists:keyfind(?UNIVERSE_UPDATE_KEY_FLOOR, 1, ResultList) of
                        {_Key, Status} ->
                            Status;
                        _ ->
                            0
                    end;
                _ ->
                    0
            end;
        _ ->
            0
    end.

do_check_universe(State) ->
    case mod_role_extra:get_data(?EXTRA_KEY_UNIVERSE_POWER_SET, false, State) of
        true ->
            State;
        _ ->
            State2 = mod_role_extra:set_data(?EXTRA_KEY_UNIVERSE_POWER_SET, true, State),
            RoleLevel = mod_role_data:get_role_level(State2),
            #r_role{role_id = RoleID, role_copy = RoleCopy} = State2,
            #r_role_copy{max_universe = MaxUniverse} = RoleCopy,
            case MaxUniverse =/= 0 orelse RoleLevel < mod_role_function:get_function_level(?FUNCTION_UNIVERSE, 275) of
                true -> %% 已经通关过或者等级不够
                    State2;
                _ ->
                    Power = mod_role_data:get_role_power(State2),
                    {MaxUniverse2, GoodsList} = do_check_universe2(Power, RoleLevel, 0),
                    case MaxUniverse2 > 0 of
                        true ->
                            UniverseInfo = get_universe_info(MaxUniverse2, 90 * ?SECOND_MS, Power, State2),
                            case catch center_universe_server:role_finish_copy(UniverseInfo#universe_info{update_list = [?UNIVERSE_UPDATE_FLOOR_RANK]}) of
                                [_|_] ->
                                    ok;
                                _ ->
                                    ?WARNING_MSG("center not receive:~w", [{RoleID, MaxUniverse2}])
                            end,
                            LetterInfo = #r_letter_info{
                                template_id = ?LETTER_UNIVERSE_POWER_SET,
                                goods_list = GoodsList,
                                action = ?ITEM_GAIN_UNIVERSE_POWER_SET
                            },
                            common_letter:send_letter(RoleID, LetterInfo),
                            RoleCopy2 = RoleCopy#r_role_copy{max_universe = MaxUniverse2},
                            common_misc:unicast(RoleID, #m_copy_max_universe_update_toc{max_universe = MaxUniverse2}),
                            State2#r_role{role_copy = RoleCopy2};
                        _ ->
                            State2
                    end
            end
    end.

do_check_universe2(Power, RoleLevel, CopyID) ->
    CopyID2 = ?IF(CopyID =:= 0, ?MAP_FIRST_UNIVERSE, CopyID + 1),
    case lib_config:find(cfg_copy_universe, CopyID2) of
        [#c_copy_universe{power = NeedPower}] when Power >= NeedPower ->
            do_check_universe2(Power, RoleLevel, CopyID2);
        _ ->
            %% 当战力达到X层通天塔的对应战力，则玩家可挑战X-14层，X-14层之前的层数均默认已通关，再挑战不会获得奖励
            MaxUniverse = CopyID - 15,
            case MaxUniverse >= ?MAP_FIRST_UNIVERSE of
                true ->
                    GoodsList = do_check_universe3(MaxUniverse, RoleLevel, []),
                    {MaxUniverse, GoodsList};
                _ ->
                    {0, []}
            end
    end.

do_check_universe3(MaxUniverse, RoleLevel, GoodsAcc) ->
    case lib_config:find(cfg_copy, MaxUniverse) of
        [Config] ->
            GoodsList = mod_role_copy:get_star_finish_goods(3, RoleLevel, Config),
            do_check_universe3(MaxUniverse - 1, RoleLevel, GoodsList ++ GoodsAcc);
        _ ->
            GoodsAcc
    end.

%% 获取本层信息
do_universe_floor_info(SendRoleID, CopyID) ->
    DataRecord =
        case game_universe_server:get_floor(CopyID) of
            #r_universe_floor{} = Floor ->
                #r_universe_floor{
                    fast_role_id = FastRoleID,
                    fast_role_name = FastRoleName,
                    fast_server_name = FastServerName,
                    use_time = UseTime,
                    power = Power,
                    power_role_id = PowerRoleID,
                    power_role_name = PowerRoleName,
                    power_server_name = PowerServerName
                } = Floor,
                #m_universe_floor_info_toc{
                    fast_role_id = FastRoleID,
                    fast_role_name = FastRoleName,
                    fast_server_name = FastServerName,
                    use_time = UseTime,
                    power = Power,
                    power_role_id = PowerRoleID,
                    power_role_name = PowerRoleName,
                    power_server_name = PowerServerName
                };
            _ ->
                #m_universe_floor_info_toc{}
        end,
    common_misc:unicast(SendRoleID, DataRecord).

%% 获取排行信息
do_universe_rank(RoleID) ->
    Ranks = game_universe_server:get_ranks(),
    {PRanks, PBestThree} =
        lists:foldl(
            fun(Rank, {PRanksAcc, PBestThreeAcc}) ->
                PRanksAcc2 = [trans_to_p_universe_rank(Rank)|PRanksAcc],
                PBestThreeAcc2 =
                    case Rank#r_universe_rank.rank =< ?BEST_RANK_NUM of
                        true ->
                            [trans_to_p_best_three(Rank)|PBestThreeAcc];
                        _ ->
                            PBestThreeAcc
                    end,
                {PRanksAcc2, PBestThreeAcc2}
            end, {[], []}, Ranks),
    common_misc:unicast(RoleID, #m_universe_rank_toc{universe_ranks = PRanks, best_three = PBestThree}).

%% 膜拜
do_universe_admire(RoleID, State) ->
    case catch check_universe_admire(State) of
        {ok, AdmireTimes, GoodsList, State2} ->
            common_misc:unicast(RoleID, #m_universe_admire_toc{admire_times = AdmireTimes}),
            role_misc:create_goods(State2, ?ITEM_GAIN_UNIVERSE_ADMIRE, GoodsList);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_universe_admire_toc{err_code = ErrCode}),
            State
    end.

check_universe_admire(State) ->
    AdmireTimes = mod_role_extra:get_data(?EXTRA_KEY_UNIVERSE_ADMIRE, 0, State),
    MaxTimes = common_misc:get_global_int(?GLOBAL_UNIVERSE_ADMIRE),
    ?IF(AdmireTimes >= MaxTimes, ?THROW_ERR(?ERROR_UNIVERSE_ADMIRE_001), ok),
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_global_string_list(?GLOBAL_UNIVERSE_ADMIRE)),
    AdmireTimes2 = AdmireTimes + 1,
    State2 = mod_role_extra:set_data(?EXTRA_KEY_UNIVERSE_ADMIRE, AdmireTimes2, State),
    {ok, AdmireTimes2, GoodsList, State2}.

do_send_info(State) ->
    AdmireTimes = mod_role_extra:get_data(?EXTRA_KEY_UNIVERSE_ADMIRE, 0, State),
    common_misc:unicast(State#r_role.role_id, #m_universe_admire_times_toc{admire_times = AdmireTimes}),
    do_universe_rank(State#r_role.role_id).

get_universe_info(CopyID, UseTime, Power, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        category = Category,
        sex = Sex,
        level = Level,
        skin_list = SkinList
    } = RoleAttr,
    #universe_info{
        role_id = RoleID,
        role_name = RoleName,
        server_name = common_config:get_server_name(),
        copy_id = CopyID,
        confine_id = mod_role_confine:get_confine_id(State),
        category = Category,
        sex = Sex,
        level = Level,
        skin_list = SkinList,
        use_time = UseTime,
        power = Power
    }.

trans_to_p_universe_rank(RankInfo) ->
    #r_universe_rank{
        rank = Rank,
        role_id = RoleID,
        role_name = RoleName,
        server_name = ServerName,
        copy_id = CopyID,
        confine_id = ConfineID,
        use_time = UseTime
    } = RankInfo,
    #p_universe_rank{
        rank = Rank,
        role_id = RoleID,
        role_name = RoleName,
        server_name = ServerName,
        copy_id = CopyID,
        confine_id = ConfineID,
        use_time = UseTime
    }.

trans_to_p_best_three(RankInfo) ->
    #r_universe_rank{
        rank = Rank,
        role_id = RoleID,
        role_name = RoleName,
        server_name = ServerName,
        copy_id = CopyID,
        category = Category,
        sex = Sex,
        level = Level,
        skin_list = SkinList
    } = RankInfo,
    #p_universe_best_three{
        rank = Rank,
        role_id = RoleID,
        role_name = RoleName,
        server_name = ServerName,
        copy_id = CopyID,
        category = Category,
        sex = Sex,
        level = Level,
        skin_list = SkinList
    }.
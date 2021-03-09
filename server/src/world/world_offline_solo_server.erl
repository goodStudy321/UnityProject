%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 四月 2018 9:34
%%%-------------------------------------------------------------------
-module(world_offline_solo_server).
-author("laijichang").
-include("global.hrl").
-include("offline_solo.hrl").
-include("proto/mod_role_offline_solo.hrl").

%% API
-export([
    start/0,
    start_link/0
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    solo_challenge/2,
    solo_result/3,
    solo_result2/3,
    buy_challenge/2,
    solo_reward/1,
    solo_bestir/1,
    gm_set_challenge/2
]).

-export([
    get_challenge/2,
    get_fight_info/1,
    get_offline_solo/1,
    get_offline_solo_size/0,
    get_offline_solo_by_rank/1,
    get_robot_solo/1,
    get_robot_config/2,
    set_offline_solo/1
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

solo_challenge(RoleID, Rank) ->
    pname_server:call(?MODULE, {solo_challenge, RoleID, Rank}).

solo_result(RoleID, DestRoleID, IsWin) ->
    pname_server:send(?MODULE, {solo_result, RoleID, DestRoleID, IsWin}).

solo_result2(RoleID, DestRoleID, IsWin) ->
    pname_server:send(?MODULE, {solo_result2, RoleID, DestRoleID, IsWin}).

buy_challenge(RoleID, BuyTimes) ->
    pname_server:call(?MODULE, {buy_challenge, RoleID, BuyTimes}).

gm_set_challenge(RoleID,Times) ->
    pname_server:call(?MODULE, {gm_set_challenge, RoleID,Times}).

solo_reward(RoleID) ->
    pname_server:call(?MODULE, {solo_reward, RoleID}).

solo_bestir(RoleID) ->
    pname_server:call(?MODULE, {solo_bestir, RoleID}).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    ets:new(?ETS_RANK_OFFLINE_SOLO, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #r_rank_offline_solo.rank}]),
    do_init_robots(),
    do_modify_ranks(),
    time_tool:reg(world, [0]),
    erlang:send_after(time_tool:diff_next_hoursec(?REWARD_RESET_HOUR, 0) * 1000, erlang:self(), reward_rank),
    {ok, []}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    time_tool:dereg(world, [0]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({solo_challenge, RoleID, Rank}) ->
    do_solo_challenge(RoleID, Rank);
do_handle({solo_result, RoleID, DestRoleID, IsWin}) ->
    do_solo_result(RoleID, DestRoleID, IsWin);
do_handle({solo_result2, RoleID, DestRoleID, IsWin}) ->
    do_solo_result2(RoleID, DestRoleID, IsWin);
do_handle({buy_challenge, RoleID, BuyTimes}) ->
    do_buy_challenge(RoleID, BuyTimes);
do_handle({gm_set_challenge, RoleID,Times}) ->
    do_gm_set_challenge(RoleID,Times);
do_handle({solo_bestir, RoleID}) ->
    do_solo_bestir(RoleID);
do_handle(zeroclock) ->
    do_zeroclock();
do_handle(reward_rank) ->
    do_reward_rank();
do_handle({solo_reward, RoleID}) ->
    do_solo_reward(RoleID);
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_init_robots() ->
    AllRobotSolos = get_all_robot_solo(),
    [FirstNames] = lib_config:find(cfg_names, first_names),
    [SecondNames] = lib_config:find(cfg_names, second_names),
    case AllRobotSolos =:= [] of
        true -> %% 初始化
            ConfigList = cfg_robot_offline_solo:list(),
            {AllRobotSolos2, RobotNames} =
                lists:foldl(
                    fun(RobotID, {RobotSolosAcc, UseNamesAcc}) ->
                        #c_robot_offline_solo{
                            level = Level,
                            hp = Hp,
                            min_power = MinPower,
                            max_power = MaxPower} = get_robot_config(RobotID, ConfigList),
                        Name = get_robot_name(FirstNames, SecondNames, UseNamesAcc),
                        {Sex, Category} = lib_tool:random_element_from_list([{?SEX_GIRL, ?CATEGORY_1}, {?SEX_BOY, ?CATEGORY_2}]),
                        RobotSolo = #r_robot_offline_solo{
                            robot_id = RobotID,
                            name = Name,
                            category = Category,
                            sex = Sex,
                            level = Level,
                            hp = Hp,
                            power = lib_tool:random(MinPower, MaxPower)
                        },
                        {[RobotSolo|RobotSolosAcc], [Name|UseNamesAcc]}
                    end, {[], []}, lists:seq(1, ?OFFLINE_SOLO_MAX_ROBOT_NUM)),
            set_robot_solo(AllRobotSolos2),
            {OfflineSolos, _Rank} =
                lists:foldl(
                    fun(#r_robot_offline_solo{robot_id = RobotID}, {ListAcc, RankAcc}) ->
                        ListAcc2 = [#r_role_offline_solo{rank = RankAcc, role_id = RobotID}|ListAcc],
                        RankAcc2 = RankAcc + 1,
                        {ListAcc2, RankAcc2}
                    end, {[], 1}, lists:reverse(lists:keysort(#r_robot_offline_solo.power, AllRobotSolos2))),
            set_offline_solo(OfflineSolos);
        _ ->
            RobotNames = [ Name || #r_robot_offline_solo{name = Name}<- AllRobotSolos]
    end,
    world_data:set_offline_solo_robot_names(RobotNames).

%% 修正排行数据
do_modify_ranks() ->
    AllSolos = get_all_offline_solo(),
    {AllSolos2, DeleteIDs} =
        lists:foldl(
            fun(#r_role_offline_solo{role_id = RoleID} = Solo, {Acc1, Acc2}) ->
                case RoleID > ?OFFLINE_SOLO_MAX_ROBOT_NUM of
                    true ->
                        case db:lookup(?DB_ROLE_ATTR_P, RoleID) of
                            [#r_role_attr{}] ->
                                {[Solo|Acc1], Acc2};
                            _ ->
                                {Acc1, [RoleID|Acc2]}
                        end;
                    _ ->
                        {[Solo|Acc1], Acc2}
                end
            end, {[], []}, AllSolos),
    AllSolos3 = lists:keysort(#r_role_offline_solo.rank, AllSolos2),
    {AllSolo4, _Num} =
        lists:foldl(
            fun(Solo, {SoloAcc, RankNumAcc}) ->
                SoloAcc2 = [Solo#r_role_offline_solo{rank = RankNumAcc}|SoloAcc],
                {SoloAcc2, RankNumAcc + 1}
            end, {[], 1}, AllSolos3),
    db:delete_many(?DB_ROLE_OFFLINE_SOLO_P, DeleteIDs),
    set_offline_solo(AllSolo4),
    RankSolos = [ #r_rank_offline_solo{rank = Rank, role_id = RoleID} || #r_role_offline_solo{rank = Rank, role_id = RoleID} <- AllSolo4],
    set_rank_offline_solo(RankSolos).

do_solo_challenge(RoleID, Rank) ->
    case catch check_solo_challenge(RoleID, Rank) of
        {ok, IsNew, DestRoleID, DestBestirTimes, MyOfflineSolo} ->
            #r_role_offline_solo{rank = MyRank, bestir_times = BestirTimes} = MyOfflineSolo,
            set_offline_solo(MyOfflineSolo),
            ?IF(IsNew, set_rank_offline_solo(#r_rank_offline_solo{rank = MyRank, role_id = RoleID}), ok),
            {ok, BestirTimes, DestRoleID, DestBestirTimes};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_solo_challenge(RoleID, Rank) ->
    case get_offline_solo(RoleID) of
        [#r_role_offline_solo{} = MyOfflineSolo] ->
            IsNew = false;
        _ ->
            IsNew = true,
            Size = get_offline_solo_size(),
            MyOfflineSolo = #r_role_offline_solo{role_id = RoleID, rank = Size + 1, challenge_times = ?DEFAULT_CHALLENGE_TIMES}
    end,
    #r_role_offline_solo{challenge_times = ChallengeTimes} = MyOfflineSolo,
    ?IF(ChallengeTimes > 0, ok, ?THROW_ERR(?ERROR_OFFLINE_SOLO_CHALLENGE_002)),
    [#r_role_offline_solo{role_id = DestRoleID, bestir_times = DestBestirTimes}] = get_offline_solo_by_rank(Rank),
    MyOfflineSolo2 = MyOfflineSolo#r_role_offline_solo{challenge_times = ChallengeTimes - 1},
    {ok, IsNew, DestRoleID, DestBestirTimes, MyOfflineSolo2}.

do_solo_result(RoleID, DestRoleID, IsWin) ->
    case IsWin of
        true ->
            [RoleOfflineSolo] = get_offline_solo(RoleID),
            [DestOfflineSolo] = get_offline_solo(DestRoleID),
            #r_role_offline_solo{rank = Rank} = RoleOfflineSolo,
            #r_role_offline_solo{rank = DestRank} = DestOfflineSolo,
            case Rank > DestRank of
                true ->
                    RoleOfflineSolo2 = RoleOfflineSolo#r_role_offline_solo{rank = DestRank},
                    DestOfflineSolo2 = DestOfflineSolo#r_role_offline_solo{rank = Rank},
                    set_offline_solo(RoleOfflineSolo2),
                    set_offline_solo(DestOfflineSolo2),
                    set_rank_offline_solo(#r_rank_offline_solo{rank = DestRank, role_id = RoleID}),
                    set_rank_offline_solo(#r_rank_offline_solo{rank = Rank, role_id = DestRoleID}),
                    RoleName = common_role_data:get_role_name(RoleID),
                    ?IF(DestRank =:= 1, common_broadcast:send_world_common_notice(?NOTICE_OFFLINE_SOLO, [RoleName]), ok),
                    ?IF(DestRoleID > ?OFFLINE_SOLO_MAX_ROBOT_NUM, mod_role_offline_solo:solo_info(DestRoleID), ok);
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    #p_challenge{role_name = DestName} = get_challenge(DestRoleID, 0),
    mod_role_offline_solo:solo_result(RoleID, IsWin, DestName).

do_solo_result2(RoleID, DestRoleID, IsWin) ->
    case IsWin of
        true ->
            [RoleOfflineSolo] = get_offline_solo(RoleID),
            [DestOfflineSolo] = get_offline_solo(DestRoleID),
            #r_role_offline_solo{rank = Rank} = RoleOfflineSolo,
            #r_role_offline_solo{rank = DestRank} = DestOfflineSolo,
            case Rank > DestRank of
                true ->
                    RoleOfflineSolo2 = RoleOfflineSolo#r_role_offline_solo{rank = DestRank},
                    DestOfflineSolo2 = DestOfflineSolo#r_role_offline_solo{rank = Rank},
                    set_offline_solo(RoleOfflineSolo2),
                    set_offline_solo(DestOfflineSolo2),
                    set_rank_offline_solo(#r_rank_offline_solo{rank = DestRank, role_id = RoleID}),
                    set_rank_offline_solo(#r_rank_offline_solo{rank = Rank, role_id = DestRoleID}),
                    RoleName = common_role_data:get_role_name(RoleID),
                    ?IF(DestRank =:= 1, common_broadcast:send_world_common_notice(?NOTICE_OFFLINE_SOLO, [RoleName]), ok),
                    ?IF(DestRoleID > ?OFFLINE_SOLO_MAX_ROBOT_NUM, mod_role_offline_solo:solo_info(DestRoleID), ok);
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    #p_challenge{role_name = DestName} = get_challenge(DestRoleID, 0),
    mod_role_offline_solo:solo_result2(RoleID, IsWin, DestName).

do_buy_challenge(RoleID, BuyTimes) ->
    [#r_role_offline_solo{challenge_times = ChallengeTimes, buy_times = RoleBuyTimes} = OfflineSolo] = get_offline_solo(RoleID),
    RoleBuyTimes2 = RoleBuyTimes + BuyTimes,
    case RoleBuyTimes2 >= 0 of
        true ->
            ChallengeTimes2 = ChallengeTimes + BuyTimes,
            set_offline_solo(OfflineSolo#r_role_offline_solo{challenge_times = ChallengeTimes2, buy_times = RoleBuyTimes2}),
            {ok, ChallengeTimes2, RoleBuyTimes2};
        _ ->
            {error, ?ERROR_OFFLINE_SOLO_BUY_CHALLENGE_002}
    end.

do_gm_set_challenge(RoleID,Times)->
    [#r_role_offline_solo{buy_times = BuyTimes} = OfflineSolo] = get_offline_solo(RoleID),
    set_offline_solo(OfflineSolo#r_role_offline_solo{challenge_times = Times}),
    {ok,BuyTimes}.


do_solo_bestir(RoleID) ->
    [#r_role_offline_solo{bestir_times = BestirTimes} = OfflineSolo] = get_offline_solo(RoleID),
    MaxTimes = common_misc:get_global_int(?GLOBAL_SOLO_BESTIR_TIMES),
    case BestirTimes < MaxTimes of
        true ->
            BestirTimes2 = BestirTimes + 1,
            set_offline_solo(OfflineSolo#r_role_offline_solo{bestir_times = BestirTimes2}),
            {ok, BestirTimes2};
        _ ->
            {error, ?ERROR_OFFLINE_SOLO_BESTIR_002}
    end.

%% 0点重置次数
do_zeroclock() ->
    RoleList =
        [begin
             set_offline_solo(OfflineSolo#r_role_offline_solo{challenge_times = ?DEFAULT_CHALLENGE_TIMES, buy_times = 0, bestir_times = 0}),
             RoleID
         end|| #r_role_offline_solo{role_id = RoleID} = OfflineSolo <- get_all_offline_solo(), RoleID > ?OFFLINE_SOLO_MAX_ROBOT_NUM],
    common_broadcast:bc_role_info_to_roles(RoleList, {mod_role_offline_solo, online, []}).

%% 22点快照排行奖励
do_reward_rank() ->
    erlang:send_after(time_tool:diff_next_hoursec(?REWARD_RESET_HOUR, 0) * 1000, erlang:self(), reward_rank),
    RoleList =
        [ begin
              set_offline_solo(OfflineSolo#r_role_offline_solo{reward_rank = Rank, is_reward = false}),
              RoleID
          end || #r_role_offline_solo{role_id = RoleID, rank = Rank} = OfflineSolo <- get_all_offline_solo(), RoleID > ?OFFLINE_SOLO_MAX_ROBOT_NUM],
    common_broadcast:bc_role_info_to_roles(RoleList, {mod_role_offline_solo, online, []}).

%% 领取排行奖励
do_solo_reward(RoleID) ->
    case catch check_solo_reward(RoleID) of
        {ok, OfflineSolo, RewardRank} ->
            set_offline_solo(OfflineSolo),
            {ok, RewardRank};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_solo_reward(RoleID) ->
    [#r_role_offline_solo{is_reward = IsReward, reward_rank = RewardRank} = OfflineSolo] = get_offline_solo(RoleID),
    ?IF(IsReward, ?THROW_ERR(?ERROR_OFFLINE_SOLO_REWARD_002), ok),
    {ok, OfflineSolo#r_role_offline_solo{is_reward = true}, RewardRank}.


get_robot_name(FirstNames, SecondNames, UseNamesAcc) ->
    Name = lib_tool:random_element_from_list(FirstNames) ++ lib_tool:random_element_from_list(SecondNames),
    case lists:member(Name, UseNamesAcc) of
        true ->
            get_robot_name(FirstNames, SecondNames, UseNamesAcc);
        _ ->
            Name
    end.

get_challenge(RoleID, Rank) ->
    case RoleID > ?OFFLINE_SOLO_MAX_ROBOT_NUM of
        true ->
            #r_role_attr{
                role_name = Name,
                power = Power,
                sex = Sex,
                category = Category,
                level = Level,
                skin_list = SkinList,
                ornament_list = OrnamentList} = common_role_data:get_role_attr(RoleID);
        _ ->
            SkinList = [3040205, 3050000, 30200000, 3030101],
            OrnamentList = [],
            [#r_robot_offline_solo{
                name = Name,
                sex = Sex,
                power = Power,
                category = Category,
                level = Level
            }] = get_robot_solo(RoleID)
    end,
    #p_challenge{
        rank = Rank,
        role_id = RoleID,
        role_name = Name,
        sex = Sex,
        category = Category,
        level = Level,
        power = Power,
        skin_list = SkinList,
        ornament_list = OrnamentList}.

get_fight_info(RoleID) ->
    case RoleID > ?OFFLINE_SOLO_MAX_ROBOT_NUM of
        true ->
            #r_role_fight{fight_attr = #actor_fight_attr{max_hp = Hp}} = common_role_data:get_role_fight(RoleID),
            #r_role_attr{
                role_name = RoleName,
                sex = Sex,
                category = Category,
                level = Level,
                power = Power,
                skin_list = SkinList} = common_role_data:get_role_attr(RoleID);
        _ ->
            SkinList = [3040205, 3050000, 30200000, 3030101],
            [#r_robot_offline_solo{
                name = RoleName,
                sex = Sex,
                category = Category,
                level = Level,
                power = Power
            }] = get_robot_solo(RoleID),
            Hp = Power
    end,
    #r_offline_solo_fight{
        role_id = RoleID,
        role_name = RoleName,
        level = Level,
        sex = Sex,
        category = Category,
        hp = Hp,
        power = Power,
        skin_list = SkinList
    }.

%% 找不到的话，用第一个
get_robot_config(_RobotID, []) ->
    {_Rank, Config} = lists:nth(1, lib_config:list(cfg_robot_offline_solo)),
    Config;
get_robot_config(RobotID, [{{MinRank, MaxRank}, Config}|R]) ->
    case MinRank =< RobotID andalso RobotID =< MaxRank of
        true ->
            Config;
        _ ->
            get_robot_config(RobotID, R)
    end.

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_offline_solo(OfflineSolo) ->
    db:insert(?DB_ROLE_OFFLINE_SOLO_P, OfflineSolo).
get_offline_solo(RoleID) ->
    ets:lookup(?DB_ROLE_OFFLINE_SOLO_P, RoleID).
get_all_offline_solo() ->
    ets:tab2list(?DB_ROLE_OFFLINE_SOLO_P).
get_offline_solo_size() ->
    ets:info(?DB_ROLE_OFFLINE_SOLO_P, size).
get_offline_solo_by_rank(Rank) ->
    [#r_rank_offline_solo{role_id = RoleID}] = get_rank_offline_solo(Rank),
    get_offline_solo(RoleID).

get_rank_offline_solo(Rank) ->
    ets:lookup(?ETS_RANK_OFFLINE_SOLO, Rank).
set_rank_offline_solo(RankSolo) ->
    ets:insert(?ETS_RANK_OFFLINE_SOLO, RankSolo).

set_robot_solo(RobotSolo) ->
    db:insert(?DB_ROBOT_OFFLINE_SOLO_P, RobotSolo).
get_robot_solo(RobotID) ->
    db:lookup(?DB_ROBOT_OFFLINE_SOLO_P, RobotID).
get_all_robot_solo() ->
    ets:tab2list(?DB_ROBOT_OFFLINE_SOLO_P).


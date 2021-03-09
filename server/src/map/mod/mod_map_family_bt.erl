%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 八月 2018 19:09
%%%-------------------------------------------------------------------
-module(mod_map_family_bt).
-author("WZP").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                                     占领点份数放大至   100倍                                                                                         %%%
%%%                                                     占领速度放大至     100倍                                                                                         %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-include("common_records.hrl").
-include("common.hrl").
-include("role.hrl").
-include("family_battle.hrl").
-include("daily_liveness.hrl").
-include("proto/mod_map_family_bt.hrl").
-include("proto/mod_role_map.hrl").

%% API
-export([
    init/0,
    handle/1,
    loop/1,
    role_leave_map/1,
    role_dead/2,
    get_region_by_pos/1,
    role_relive_type_fee/2,
    terminate/0
]).

-export([
    role_enter_map/1,
    check_pre_enter/5,
    get_new_change/2,
    get_camp_id_pos/1
]).


init() ->
    set_state(?FAMILY_BATTLE_ROUND_ING),
    set_open_time(time_tool:now()),
    set_can_into(?FAMILY_BATTLE_CAN_IN),
    set_region_one(#r_family_battle_region{}),
    set_region_two(#r_family_battle_region{}),
    set_region_three(#r_family_battle_region{}),
    set_region_four(#r_family_battle_region{}),
    set_region_five(#r_family_battle_region{}).


role_leave_map(RoleID) ->
    case ets:lookup(?ETS_FAMILY_BATTLE_RANK, RoleID) of
        [] ->
            ok;
        [Info] ->
            case Info#r_family_battle_rank.region =:= 0 of
                false ->
                    Region = get_region_by_id(Info#r_family_battle_rank.region),
                    case Info#r_family_battle_rank.camp_id of
                        ?FAMILY_BATTLE_RED ->
                            NewRedRoles = lists:delete(RoleID, Region#r_family_battle_region.red_roles),
                            NewRegion = Region#r_family_battle_region{red_roles = NewRedRoles};
                        _ ->
                            NewBlueRoles = lists:delete(RoleID, Region#r_family_battle_region.blue_roles),
                            NewRegion = Region#r_family_battle_region{blue_roles = NewBlueRoles}
                    end,
                    set_region_by_id(NewRegion, Info#r_family_battle_rank.region);
                _ ->
                    ok
            end,
            ets:insert(?ETS_FAMILY_BATTLE_RANK, Info#r_family_battle_rank{region = 0})
    end.

role_dead(RoleID, Killer) ->
    role_be_kill(RoleID),
    role_kill_man(Killer).

%%被击杀
role_be_kill(RoleID) ->
    case ets:lookup(?ETS_FAMILY_BATTLE_RANK, RoleID) of
        [] ->
            ok;
        [Info] ->
            case Info#r_family_battle_rank.region =:= 0 of
                false ->
                    Region = get_region_by_id(Info#r_family_battle_rank.region),
                    case Info#r_family_battle_rank.camp_id of
                        ?FAMILY_BATTLE_RED ->
                            NewRedRoles = lists:delete(RoleID, Region#r_family_battle_region.red_roles),
                            NewRegion = Region#r_family_battle_region{red_roles = NewRedRoles};
                        _ ->
                            NewBlueRoles = lists:delete(RoleID, Region#r_family_battle_region.blue_roles),
                            NewRegion = Region#r_family_battle_region{blue_roles = NewBlueRoles}
                    end,
                    set_region_by_id(NewRegion, Info#r_family_battle_rank.region);
                _ ->
                    ok
            end,
            ets:insert(?ETS_FAMILY_BATTLE_RANK, Info#r_family_battle_rank{region = 0})
    end.

%%击杀
role_kill_man(RoleID) ->
    case ets:lookup(?ETS_FAMILY_BATTLE_RANK, RoleID) of
        [] ->
            ok;
        [Info] ->
            [Config] = lib_config:find(cfg_global, ?FAMILY_BATTLE_GLOBAL_TWO),
            [CampScore] = Config#c_global.list,
            ets:insert(?ETS_FAMILY_BATTLE_RANK, Info#r_family_battle_rank{score = Info#r_family_battle_rank.score + Config#c_global.int}),
            BattleInfo = get_battle_info(),
            BattleInfo2 = case Info#r_family_battle_rank.camp_id of
                              ?FAMILY_BATTLE_RED ->
                                  BattleInfo#r_family_battle_info{red_score = BattleInfo#r_family_battle_info.red_score + CampScore};
                              _ ->
                                  BattleInfo#r_family_battle_info{blue_score = BattleInfo#r_family_battle_info.blue_score + CampScore}
                          end,
            set_battle_info(BattleInfo2)
    end.

role_relive_type_fee(RoleID, BornPos) ->
    Region = get_region_by_pos(BornPos),
    case Region of
        false ->
            ok;
        _ ->
            [Info] = ets:lookup(?ETS_FAMILY_BATTLE_RANK, RoleID),
            RegionInfo = get_region_by_id(Region),
            send_pass_info(RoleID, RegionInfo, Region),
            ets:insert(?ETS_FAMILY_BATTLE_RANK, Info#r_family_battle_rank{region = Region}),
            RegionInfo2 = case Info#r_family_battle_rank.camp_id of
                              ?FAMILY_BATTLE_RED ->
                                  NewRedRoles = case lists:member(RoleID, RegionInfo#r_family_battle_region.red_roles) of
                                                    false ->
                                                        [RoleID|RegionInfo#r_family_battle_region.red_roles];
                                                    _ ->
                                                        RegionInfo#r_family_battle_region.red_roles
                                                end,
                                  RegionInfo#r_family_battle_region{red_roles = NewRedRoles};
                              _ ->
                                  NewBlueRoles = case lists:member(RoleID, RegionInfo#r_family_battle_region.blue_roles) of
                                                     false ->
                                                         [RoleID|RegionInfo#r_family_battle_region.blue_roles];
                                                     _ ->
                                                         RegionInfo#r_family_battle_region.blue_roles
                                                 end,
                                  RegionInfo#r_family_battle_region{blue_roles = NewBlueRoles}
                          end,
            send_pass_info(RoleID, RegionInfo2, Region),
            set_region_by_id(RegionInfo2, Region)
    end.


get_region_by_pos(#r_pos{mx = Mx, my = My}) ->
    List = cfg_fbt_region:list(),
    get_region_by_pos(Mx, My, List).

get_region_by_pos(_Mx, _My, []) ->
    false;
get_region_by_pos(Mx, My, [{_, Config}|T]) ->
    [X, _Z, Y] = Config#c_fbt_region.pos,
    X1 = erlang:abs(X - Mx),
    Y1 = erlang:abs(Y - My),
    case X1 * X1 + Y1 * Y1 =< Config#c_fbt_region.radius * Config#c_fbt_region.radius of
        true ->
            Config#c_fbt_region.id;
        _ ->
            get_region_by_pos(Mx, My, T)
    end.


check_pre_enter(ExtraID, FamilyID, RoleID, RoleName, FamilyName) ->
    PName = map_misc:get_map_pname(?MAP_FAMILY_BT, ExtraID),
    pname_server:call(PName, {mod, ?MODULE, {check_pre_enter, FamilyID, RoleID, RoleName, FamilyName}}).

handle({#m_family_battle_pass_tos{region = Region, state = Type}, RoleID, _PID}) ->
    do_pass_region(RoleID, Region, Type);
handle({open_info, InfoList}) ->
    do_init_family_info(InfoList);
handle({check_pre_enter, FamilyID, RoleID, RoleName, FamilyName}) ->
    do_check_pre_enter(FamilyID, RoleID, RoleName, FamilyName);
handle(round_one_end) ->
    battle_end(round_one_end);
handle(round_two_end) ->
    battle_end(round_two_end);
handle(do_map_end_i) ->
    do_map_end();
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).


loop(Now) ->
    case get_state() of
        ?FAMILY_BATTLE_ROUND_FINISH ->
            ok;
        _ ->
            #r_family_battle_info{red_score = OldRedScore, blue_score = OldBlueScore} = get_battle_info(),
            RegionOneInfo = get_region_one(),
            RegionOneInfo2 = deal_with_region(RegionOneInfo, 1),
            set_region_one(RegionOneInfo2),
            RegionTwoInfo = get_region_two(),
            RegionTwoInfo2 = deal_with_region(RegionTwoInfo, 2),
            set_region_two(RegionTwoInfo2),
            RegionThreeInfo = get_region_three(),
            RegionThreeInfo2 = deal_with_region(RegionThreeInfo, 3),
            set_region_three(RegionThreeInfo2),
            RegionFourInfo = get_region_four(),
            RegionFourInfo2 = deal_with_region(RegionFourInfo, 4),
            set_region_four(RegionFourInfo2),
            RegionFiveInfo = get_region_five(),
            RegionFiveInfo2 = deal_with_region(RegionFiveInfo, 5),
            set_region_five(RegionFiveInfo2),
            BattleInfo2 = get_battle_info(),
            NewRedTime = ?IF(OldRedScore =:= BattleInfo2#r_family_battle_info.red_score, BattleInfo2#r_family_battle_info.red_time, Now),
            NewBlueTime = ?IF(OldBlueScore =:= BattleInfo2#r_family_battle_info.blue_score, BattleInfo2#r_family_battle_info.blue_time, Now),
            List = [#p_kvt{id = ?FAMILY_BATTLE_RED, val = BattleInfo2#r_family_battle_info.red_score, type = erlang:length(BattleInfo2#r_family_battle_info.red_region_list)},
                    #p_kvt{id = ?FAMILY_BATTLE_BLUE, val = BattleInfo2#r_family_battle_info.blue_score, type = erlang:length(BattleInfo2#r_family_battle_info.blue_region_list)}],
            map_server:send_all_gateway(#m_family_battle_score_toc{list = List}),
            if
                BattleInfo2#r_family_battle_info.red_score =:= BattleInfo2#r_family_battle_info.max_score ->
                    battle_end(loop);
                BattleInfo2#r_family_battle_info.blue_score =:= BattleInfo2#r_family_battle_info.max_score ->
                    battle_end(loop);
                true -> ok
            end,
            set_battle_info(BattleInfo2#r_family_battle_info{red_time = NewRedTime, blue_time = NewBlueTime})
    end.


deal_with_region(#r_family_battle_region{owner = Owner, red_roles = RedRoles, blue_roles = BlueRoles} = RegionOneInfo, Region) ->
    BattleInfo = get_battle_info(),
    {NewRedPercent, NewBluePercent, NewOwner, RedRate2, BlueRate2, RedTrend, BlueTrend} = get_new_change(RegionOneInfo),
    [RegionConfig] = lib_config:find(cfg_fbt_region, Region),
    {NewRedScore, NewBlueScore} = case Owner of
                                      ?FAMILY_BATTLE_RED ->
                                          {BattleInfo#r_family_battle_info.red_score + RegionConfig#c_fbt_region.add_score, BattleInfo#r_family_battle_info.blue_score};
                                      ?FAMILY_BATTLE_BLUE ->
                                          {BattleInfo#r_family_battle_info.red_score, BattleInfo#r_family_battle_info.blue_score + RegionConfig#c_fbt_region.add_score};
                                      ?FAMILY_BATTLE_BLANK ->
                                          {BattleInfo#r_family_battle_info.red_score, BattleInfo#r_family_battle_info.blue_score}
                                  end,
    NewRedScore2 = erlang:min(NewRedScore, BattleInfo#r_family_battle_info.max_score),
    NewBlueScore2 = erlang:min(NewBlueScore, BattleInfo#r_family_battle_info.max_score),
    {RedRegionList, BlueRegionList, RegionRecord} = if
                                                        NewOwner =:= Owner ->
                                                            {BattleInfo#r_family_battle_info.red_region_list, BattleInfo#r_family_battle_info.blue_region_list, false};
                                                        NewOwner =:= ?FAMILY_BATTLE_RED ->
                                                            {[Region|BattleInfo#r_family_battle_info.red_region_list], lists:delete(Region, BattleInfo#r_family_battle_info.blue_region_list),
                                                             #m_family_battle_region_toc{info = #p_kv{id = ?FAMILY_BATTLE_RED, val = Region}}};
                                                        NewOwner =:= ?FAMILY_BATTLE_BLUE ->
                                                            {lists:delete(Region, BattleInfo#r_family_battle_info.red_region_list), [Region|BattleInfo#r_family_battle_info.blue_region_list],
                                                             #m_family_battle_region_toc{info = #p_kv{id = ?FAMILY_BATTLE_BLUE, val = Region}}};
                                                        true ->
                                                            {lists:delete(Region, BattleInfo#r_family_battle_info.red_region_list), lists:delete(Region, BattleInfo#r_family_battle_info.blue_region_list),
                                                             #m_family_battle_region_toc{info = #p_kv{id = ?FAMILY_BATTLE_BLANK, val = Region}}}
                                                    end,
    set_battle_info(BattleInfo#r_family_battle_info{red_score = NewRedScore2, blue_score = NewBlueScore2, red_region_list = RedRegionList, blue_region_list = BlueRegionList}),
    AddScoreList = get_add_owner(Owner, NewOwner, RedRoles, BlueRoles),
    lists:foreach(
        fun(RoleID) ->
            RankInfo = mod_family_bt:get_role_rank_by_id(RoleID),
            mod_family_bt:set_role_rank(RankInfo#r_family_battle_rank{score = RankInfo#r_family_battle_rank.score + RegionConfig#c_fbt_region.role_add_score})
        end, AddScoreList),
    TrendList = [#p_family_battle_trend{camp = ?FAMILY_BATTLE_RED, score = NewRedPercent, change = RedRate2, trend = RedTrend},
                 #p_family_battle_trend{camp = ?FAMILY_BATTLE_BLUE, score = NewBluePercent, change = BlueRate2, trend = BlueTrend}],
    Record = #m_family_battle_trend_toc{owner = NewOwner, info = TrendList},
    [common_misc:unicast(RoleID2, Record) || RoleID2 <- RedRoles],
    [common_misc:unicast(RoleID1, Record) || RoleID1 <- BlueRoles],
    ?IF(RegionRecord =:= false, ok, map_server:send_all_gateway(RegionRecord)),
    RegionOneInfo#r_family_battle_region{owner = NewOwner, red_percent = NewRedPercent, blue_percent = NewBluePercent, red_rate = RedRate2, blue_rate = BlueRate2, blue_trend = BlueTrend, red_trend = RedTrend}.



get_new_change(#r_family_battle_region{red_rate = RedRate, blue_rate = BlueRate} = Info, SecondPercent) ->
    get_new_change(Info#r_family_battle_region{red_rate = lib_tool:ceil(RedRate * SecondPercent), blue_rate = lib_tool:ceil(BlueRate * SecondPercent)}).

get_new_change(#r_family_battle_region{owner = Owner, red_percent = RedPercent, blue_percent = BluePercent, red_roles = RedRoles,
                                       blue_roles = BlueRoles, red_rate = RedRate, blue_rate = BlueRate, red_trend = RedTrend, blue_trend = BlueTrend}) ->
    RedPercent2 = ?IF(RedTrend =:= ?FAMILY_BATTLE_ADD, RedPercent + RedRate, RedPercent - RedRate),
    BluePercent2 = ?IF(BlueTrend =:= ?FAMILY_BATTLE_ADD, BluePercent + BlueRate, BluePercent - BlueRate),
    OldRedNum = erlang:length(RedRoles),
    OldBlueNum = erlang:length(BlueRoles),
    {NextRedRate, NextBlueRate, NextRedTrend, NewBlueTrend} = case RedPercent2 + BluePercent2 < 10000 of
                                                                  true ->
                                                                      NewRedRate = get_occupy_rate(OldRedNum),
                                                                      NewBlueRate = get_occupy_rate(OldBlueNum),
                                                                      Sum = RedPercent2 + NewRedRate + BluePercent2 + NewBlueRate,
                                                                      case Sum > 10000 of
                                                                          false ->
                                                                              {NewRedRate, NewBlueRate, ?FAMILY_BATTLE_ADD, ?FAMILY_BATTLE_ADD};
                                                                          _ ->
                                                                              Rem = Sum rem 2,
                                                                              Add = (Sum - 10000) div 2,
                                                                              case OldRedNum > OldBlueNum of
                                                                                  true ->
                                                                                      {Add + Rem, Add, ?FAMILY_BATTLE_ADD, ?FAMILY_BATTLE_ADD};
                                                                                  _ ->
                                                                                      {Add, Add + Rem, ?FAMILY_BATTLE_ADD, ?FAMILY_BATTLE_ADD}
                                                                              end
                                                                      end;
                                                                  _ ->
                                                                      TotalRate = get_occupy_rate(erlang:abs(OldRedNum - OldBlueNum)),
                                                                      if
                                                                          OldRedNum > OldBlueNum ->
                                                                              RedPercent3 = erlang:min(RedPercent2 + TotalRate, 10000),
                                                                              BluePercent3 = erlang:max(BluePercent2 - TotalRate, 0),
                                                                              {RedPercent3 - RedPercent2, BluePercent2 - BluePercent3, ?FAMILY_BATTLE_ADD, ?FAMILY_BATTLE_REDUCE};
                                                                          OldRedNum < OldBlueNum ->
                                                                              RedPercent3 = erlang:max(RedPercent2 - TotalRate, 0),
                                                                              BluePercent3 = erlang:min(BluePercent2 + TotalRate, 10000),
                                                                              {RedPercent2 - RedPercent3, BluePercent3 - BluePercent2, ?FAMILY_BATTLE_REDUCE, ?FAMILY_BATTLE_ADD};
                                                                          true ->
                                                                              {0, 0, ?FAMILY_BATTLE_ADD, ?FAMILY_BATTLE_ADD}
                                                                      end
                                                              end,
    Owner2 = get_new_owner(Owner, RedPercent2, BluePercent2),
    {RedPercent2, BluePercent2, Owner2, NextRedRate, NextBlueRate, NextRedTrend, NewBlueTrend}.

%%新拥有者
get_new_owner(Owner, RedPercent2, BluePercent2) ->
    case Owner of
        ?FAMILY_BATTLE_RED ->
            if
                RedPercent2 < 5000 ->
                    ?IF(BluePercent2 >= 10000, ?FAMILY_BATTLE_BLUE, ?FAMILY_BATTLE_BLANK);
                true ->
                    ?FAMILY_BATTLE_RED
            end;
        ?FAMILY_BATTLE_BLUE ->
            if
                BluePercent2 < 5000 ->
                    ?IF(RedPercent2 >= 10000, ?FAMILY_BATTLE_RED, ?FAMILY_BATTLE_BLANK);
                true ->
                    ?FAMILY_BATTLE_BLUE
            end;
        ?FAMILY_BATTLE_BLANK ->
            if
                RedPercent2 >= 10000 ->
                    ?FAMILY_BATTLE_RED;
                BluePercent2 >= 10000 ->
                    ?FAMILY_BATTLE_BLUE;
                true ->
                    ?FAMILY_BATTLE_BLANK
            end
    end.

get_add_owner(Owner, NewOwner, RedRoles, BlueRoles) ->
    if
        Owner =:= NewOwner ->
            [];
        NewOwner =:= ?FAMILY_BATTLE_RED -> RedRoles;
        NewOwner =:= ?FAMILY_BATTLE_BLUE -> BlueRoles;
        true ->
            []
    end.

get_occupy_rate(Num) ->
    case lib_config:find(cfg_fbt_occupy, Num) of
        [] ->
            0;
        [RateConfig] ->
            RateConfig#c_fbt_occupy.rate * 100
    end.

role_enter_map(RoleID) ->
    BattleInfo = get_battle_info(),
    List = [#p_family_bt_open_info{family_id = BattleInfo#r_family_battle_info.blue_family_id, id = ?FAMILY_BATTLE_BLUE, region = BattleInfo#r_family_battle_info.blue_region_list,
                                   score = BattleInfo#r_family_battle_info.blue_score, family_name = BattleInfo#r_family_battle_info.blue_family_name},
            #p_family_bt_open_info{family_id = BattleInfo#r_family_battle_info.red_family_id, id = ?FAMILY_BATTLE_RED, region = BattleInfo#r_family_battle_info.red_region_list,
                                   score = BattleInfo#r_family_battle_info.blue_score, family_name = BattleInfo#r_family_battle_info.red_family_name}],
    common_misc:unicast(RoleID, #m_family_battle_open_toc{open_time = get_open_time(), list = List}).


battle_end(EndType) ->
    case catch battle_end_i(EndType) of
        ok ->
            ok;
        Error ->
            ?ERROR_MSG("-----------FAMILIT-BT--------~w", [Error])
    end.

battle_end_i(EndType) ->
    ?WARNING_MSG("-----------EndType-BT--------~w", [EndType]),
    set_state(?FAMILY_BATTLE_ROUND_FINISH),
    BattleInfo = get_battle_info(),
    List3 = get_settlement_list(),
    {Winner, Loser} = get_winner(BattleInfo),
    {WinnerCamp, WinFamilyID, LoseFamilyID} =
    case BattleInfo#r_family_battle_info.red_rank =:= Winner of
        true ->
            {?FAMILY_BATTLE_RED, BattleInfo#r_family_battle_info.red_family_id, BattleInfo#r_family_battle_info.blue_family_id};
        _ ->
            {?FAMILY_BATTLE_BLUE, BattleInfo#r_family_battle_info.blue_family_id, BattleInfo#r_family_battle_info.red_family_id}
    end,
    ExtraID = map_common_dict:get_map_extra_id(),
    pname_server:send(world_activity_server, {mod, mod_family_bt, {round_end, Winner, Loser, WinFamilyID, LoseFamilyID, ExtraID}}),
    map_server:send_all_gateway(#m_family_battle_rank_toc{list = lists:reverse(List3), winner = WinnerCamp}),
    set_can_into(?FAMILY_BATTLE_CANNOT_IN),
    [Config] = lib_config:find(cfg_global, ?FAMILY_BATTLE_GLOBAL),
    [_BattleTime, _StandTime, _SleepTime, EndTime] = Config#c_global.list,
    erlang:send_after(EndTime * 1000, erlang:self(), {mod, ?MODULE, do_map_end_i}),
    set_return_info(true),
    ok.


%%结算列表
get_settlement_list() ->
    Extra = map_common_dict:get_map_extra_id(),
    Ms = [{#r_family_battle_rank{role_id = '_', map_extra = '_',
                                 rank = '_', family_name = '_', camp_id = '_', role_name = '_',
                                 score = '_', region = '_'},
           [{'and', {'orelse', true, fail}, {'=:=', {element, 3, '$_'}, Extra}}],
           ['$_']}],
    List = ets:select(?ETS_FAMILY_BATTLE_RANK, Ms),
    List2 = lists:sort(
        fun(A, B) ->
            A#r_family_battle_rank.score > B#r_family_battle_rank.score
        end, List),
    {_, Res} = lists:foldl(
        fun(#r_family_battle_rank{family_name = FamilyName, role_name = RoleName, score = Score, role_id = RoleID}, {Rank, SendList}) ->
            mod_role_daily_liveness:trigger_daily_liveness(RoleID, ?LIVENESS_FAMILY_BT),
            send_reward(RoleID, Score, Rank),
            SendInfo = #p_family_battle_rank{rank = Rank, family_name = FamilyName, role_name = RoleName, score = Score},
            {Rank + 1, [SendInfo|SendList]}
        end, {1, []}, List2),
    Res.


send_reward(RoleID, _Score, Rank) ->
    GoodsList = get_reward(Rank),
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_FAMILY_BT_RANK,
        text_string = [lib_tool:to_list(Rank)],
        action = ?ITEM_GAIN_FAMILY_BATTLE_RANK,
        goods_list = GoodsList
    },
    common_letter:send_letter(RoleID, LetterInfo).


get_reward(Rank) ->
    [Config] = lib_config:find(cfg_fbt_rank_reward, Rank),
    List = lib_tool:string_to_intlist(Config#c_fbt_rank_reward.reward),
    [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- List].

get_winner(BattleInfo) ->
    if
        BattleInfo#r_family_battle_info.red_score > BattleInfo#r_family_battle_info.blue_score ->
            {BattleInfo#r_family_battle_info.red_rank, BattleInfo#r_family_battle_info.blue_rank};
        BattleInfo#r_family_battle_info.red_score < BattleInfo#r_family_battle_info.blue_score ->
            {BattleInfo#r_family_battle_info.blue_rank, BattleInfo#r_family_battle_info.red_rank};
        true ->
            if
                BattleInfo#r_family_battle_info.red_family_id =:= 0 ->
                    {BattleInfo#r_family_battle_info.blue_rank, BattleInfo#r_family_battle_info.red_rank};
                BattleInfo#r_family_battle_info.blue_family_id =:= 0 ->
                    {BattleInfo#r_family_battle_info.red_rank, BattleInfo#r_family_battle_info.blue_rank};
                BattleInfo#r_family_battle_info.red_time < BattleInfo#r_family_battle_info.blue_time ->
                    {BattleInfo#r_family_battle_info.red_rank, BattleInfo#r_family_battle_info.blue_rank};
                BattleInfo#r_family_battle_info.red_time > BattleInfo#r_family_battle_info.blue_time ->
                    {BattleInfo#r_family_battle_info.blue_rank, BattleInfo#r_family_battle_info.red_rank};
                true ->
                    ?IF(BattleInfo#r_family_battle_info.red_power > BattleInfo#r_family_battle_info.blue_power, {BattleInfo#r_family_battle_info.red_rank, BattleInfo#r_family_battle_info.blue_rank},
                        {BattleInfo#r_family_battle_info.blue_rank, BattleInfo#r_family_battle_info.red_rank})
            end
    end.


do_init_family_info(InfoList) ->
    Red = lists:keyfind(?FAMILY_BATTLE_RED, 1, InfoList),
    {_, RedFamilyID, RedFamilyName, RedPower, RedRank} = Red,
    Blue = lists:keyfind(?FAMILY_BATTLE_BLUE, 1, InfoList),
    {_, BlueFamilyID, BlueFamilyName, BluePower, BlueRank} = Blue,
    [Config] = lib_config:find(cfg_global, ?FAMILY_BATTLE_GLOBAL),
    set_battle_info(#r_family_battle_info{max_score = Config#c_global.int, red_power = RedPower, blue_power = BluePower, red_rank = RedRank, blue_rank = BlueRank,
                                          red_family_id = RedFamilyID, red_family_name = RedFamilyName, blue_family_id = BlueFamilyID, blue_family_name = BlueFamilyName}).

do_pass_region(RoleID, Region, Type) ->
    case ets:lookup(?ETS_FAMILY_BATTLE_RANK, RoleID) of
        [#r_family_battle_rank{} = Info] ->
            case Type of
                ?FAMILY_BATTLE_IN ->
                    case check_is_in_region(Region, RoleID) of
                        {true, Region2} ->
                            RegionInfo = get_region_by_id(Region2),
                            send_pass_info(RoleID, RegionInfo, Region),
                            ets:insert(?ETS_FAMILY_BATTLE_RANK, Info#r_family_battle_rank{region = Region}),
                            RegionInfo2 = case Info#r_family_battle_rank.camp_id of
                                              ?FAMILY_BATTLE_RED ->
                                                  NewRedRoles = case lists:member(RoleID, RegionInfo#r_family_battle_region.red_roles) of
                                                                    false ->
                                                                        [RoleID|RegionInfo#r_family_battle_region.red_roles];
                                                                    _ ->
                                                                        RegionInfo#r_family_battle_region.red_roles
                                                                end,
                                                  RegionInfo#r_family_battle_region{red_roles = NewRedRoles};
                                              _ ->
                                                  NewBlueRoles = case lists:member(RoleID, RegionInfo#r_family_battle_region.blue_roles) of
                                                                     false ->
                                                                         [RoleID|RegionInfo#r_family_battle_region.blue_roles];
                                                                     _ ->
                                                                         RegionInfo#r_family_battle_region.blue_roles
                                                                 end,
                                                  RegionInfo#r_family_battle_region{blue_roles = NewBlueRoles}
                                          end,
                            set_region_by_id(RegionInfo2, Region2);
                        _ ->
                            ok
                    end;
                _ ->
                    RegionInfo = get_region_by_id(Region),
                    ets:insert(?ETS_FAMILY_BATTLE_RANK, Info#r_family_battle_rank{region = 0}),
                    case Info#r_family_battle_rank.camp_id of
                        ?FAMILY_BATTLE_RED ->
                            NewRedRoles = lists:delete(RoleID, RegionInfo#r_family_battle_region.red_roles),
                            RegionInfo2 = RegionInfo#r_family_battle_region{red_roles = NewRedRoles};
                        _ ->
                            NewBlueRoles = lists:delete(RoleID, RegionInfo#r_family_battle_region.blue_roles),
                            RegionInfo2 = RegionInfo#r_family_battle_region{blue_roles = NewBlueRoles}
                    end,
                    set_region_by_id(RegionInfo2, Region)
            end;
        _ ->
            ok
    end.


%%检查是否在同一圈    0时需自己检查圈
check_is_in_region(Region, RoleID) ->
    case mod_map_ets:get_actor_pos(RoleID) of
        undefined ->
            ok;
        #r_pos{mx = Mx, my = My} ->
            case Region =:= 0 of
                false ->
                    check_is_in_region(Region, Mx, My);
                _ ->
                    case get_region_by_pos(#r_pos{mx = Mx, my = My}) of
                        false ->
                            false;
                        NewRegion ->
                            check_is_in_region(NewRegion, Mx, My)
                    end
            end
    end.

check_is_in_region(Region, Mx, My) ->
    [Config] = lib_config:find(cfg_fbt_region, Region),
    [X, _Z, Y] = Config#c_fbt_region.pos,
    X1 = erlang:abs(X - Mx),
    Y1 = erlang:abs(Y - My),
    case X1 * X1 + Y1 * Y1 < 4 * Config#c_fbt_region.radius * Config#c_fbt_region.radius + 160000 + 1600 * Config#c_fbt_region.radius of
        true ->
            {true, Region};
        _ ->
            false
    end.

%%进入时发送数据
send_pass_info(RoleID, #r_family_battle_region{owner = Owner} = RegionInfo, Region) ->
    {NewRedPercent, NewBluePercent, NewOwner, RedRate2, BlueRate2, RedTrend, BlueTrend} = get_new_change(RegionInfo, (time_tool:now_ms() - time_tool:now() * 1000) / 1000),
    common_misc:unicast(RoleID, #m_family_battle_pass_toc{list = [#p_kv{id = ?FAMILY_BATTLE_RED, val = NewRedPercent},
                                                                  #p_kv{id = ?FAMILY_BATTLE_BLUE, val = NewBluePercent}]}),
    TrendList = [#p_family_battle_trend{camp = ?FAMILY_BATTLE_RED, score = NewRedPercent, change = RedRate2, trend = RedTrend},
                 #p_family_battle_trend{camp = ?FAMILY_BATTLE_BLUE, score = NewBluePercent, change = BlueRate2, trend = BlueTrend}],
    common_misc:unicast(RoleID, #m_family_battle_trend_toc{owner = NewOwner, info = TrendList}),
    RegionRecord = if
                       NewOwner =:= Owner ->
                           false;
                       NewOwner =:= ?FAMILY_BATTLE_RED ->
                           #m_family_battle_region_toc{info = #p_kv{id = ?FAMILY_BATTLE_RED, val = Region}};
                       NewOwner =:= ?FAMILY_BATTLE_BLUE ->
                           #m_family_battle_region_toc{info = #p_kv{id = ?FAMILY_BATTLE_BLUE, val = Region}};
                       true ->
                           #m_family_battle_region_toc{info = #p_kv{id = ?FAMILY_BATTLE_BLANK, val = Region}}
                   end,
    ?IF(RegionRecord =:= false, ok, common_misc:unicast(RoleID, RegionRecord)).

set_battle_info(Info) ->
    erlang:put({?MODULE, battle_info}, Info).

get_battle_info() ->
    erlang:get({?MODULE, battle_info}).


set_region_one(Info) ->
    erlang:put({?MODULE, region_one}, Info).

get_region_one() ->
    erlang:get({?MODULE, region_one}).

set_region_two(Info) ->
    erlang:put({?MODULE, region_two}, Info).

get_region_two() ->
    erlang:get({?MODULE, region_two}).

set_region_three(Info) ->
    erlang:put({?MODULE, region_three}, Info).

get_region_three() ->
    erlang:get({?MODULE, region_three}).


set_region_four(Info) ->
    erlang:put({?MODULE, region_four}, Info).

get_region_four() ->
    erlang:get({?MODULE, region_four}).


set_region_five(Info) ->
    erlang:put({?MODULE, region_fight}, Info).

get_region_five() ->
    erlang:get({?MODULE, region_fight}).


set_region_by_id(Info, ID) ->
    case ID of
        1 ->
            set_region_one(Info);
        2 ->
            set_region_two(Info);
        3 ->
            set_region_three(Info);
        4 ->
            set_region_four(Info);
        5 ->
            set_region_five(Info)
    end.

get_region_by_id(ID) ->
    case ID of
        1 ->
            get_region_one();
        2 ->
            get_region_two();
        3 ->
            get_region_three();
        4 ->
            get_region_four();
        5 ->
            get_region_five()
    end.

%%是否已经返回战斗结果
get_return_info() ->
    erlang:get({?MODULE, return_info}).
%%是否已经返回战斗结果
set_return_info(Status) ->
    erlang:put({?MODULE, return_info}, Status).

set_open_time(Time) ->
    erlang:put({?MODULE, set_opentime}, Time).

get_open_time() ->
    erlang:get({?MODULE, set_opentime}).


set_state(State) ->
    erlang:put({?MODULE, state}, State).

get_state() ->
    erlang:get({?MODULE, state}).

set_can_into(State) ->
    erlang:put({?MODULE, into_state}, State).

get_can_into() ->
    erlang:get({?MODULE, into_state}).

do_map_end() ->
    map_server:kick_all_roles(),
    map_server:delay_shutdown().


do_check_pre_enter(FamilyID, RoleID, RoleName, FamilyName) ->
    case catch check_pre_enter(FamilyID, RoleID, RoleName, FamilyName) of
        {ok, Camp} ->
            {ok, Camp};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_pre_enter(FamilyID, RoleID, RoleName, FamilyName) ->
    ?IF(get_can_into() =:= ?FAMILY_BATTLE_CANNOT_IN, ?THROW_ERR(?ERROR_PRE_ENTER_021), ok),
    Info = get_battle_info(),
    Camp = if
               FamilyID =:= Info#r_family_battle_info.blue_family_id -> ?FAMILY_BATTLE_BLUE;
               FamilyID =:= Info#r_family_battle_info.red_family_id -> ?FAMILY_BATTLE_RED;
               true -> ?FAMILY_BATTLE_BLANK
           end,
    case Camp =:= ?FAMILY_BATTLE_BLANK of
        true ->
            {error, ?ERROR_PRE_ENTER_020};
        _ ->
            case ets:lookup(?ETS_FAMILY_BATTLE_RANK, RoleID) of
                [#r_family_battle_rank{}] ->
                    ok;
                _ ->
                    Extra = map_common_dict:get_map_extra_id(),
                    mod_family_bt:set_role_rank(#r_family_battle_rank{role_id = RoleID, map_extra = Extra, role_name = RoleName, family_name = FamilyName, camp_id = Camp})
            end,
            {ok, Camp}
    end.



get_camp_id_pos(CampID) ->
    [List] = map_base_data:get_born_points(?MAP_FAMILY_BT),
    #c_born_point{mx = Mx, my = My, mdir = MDir} = lists:keyfind(CampID, #c_born_point.camp_id, List),
    map_misc:get_pos_by_meter(Mx, My, MDir).



terminate() ->
    case get_return_info() of
        true ->
            ok;
        _ ->
            battle_end(terminate)
    end.

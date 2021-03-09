%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 八月 2018 14:15
%%%-------------------------------------------------------------------
-module(mod_family_battle).
-author("WZP").
-include("family.hrl").
-include("activity.hrl").
-include("all_pb.hrl").
-include("common.hrl").
-include("global.hrl").
-include("family_battle.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    refresh_salary/0,
    refresh_list/0,
    get_qua_info/1
]).

-export([
    gm_refresh_list/0
]).

-export([
    family_get_salary/2,
    family_add_continuity_victory/4,
    family_end_continuity_victory/2,
    family_distribute_cv_reward/4,
    family_distribute_end_reward/3
]).


-export([
    handle/1
]).


family_get_salary(RoleID, FamilyID) ->
    family_misc:call_family({mod, ?MODULE, {check_can_salary, RoleID, FamilyID}}).
family_add_continuity_victory(Rank, VctTime, FamilyID, OldFamilyID) ->
    family_misc:info_family({mod, ?MODULE, {add_continuity_victory, Rank, VctTime, FamilyID, OldFamilyID}}).
family_end_continuity_victory(FamilyID, VctTime) ->
    family_misc:info_family({mod, ?MODULE, {end_continuity_victory, FamilyID, VctTime}}).
family_distribute_cv_reward(Reward, RoleID, FamilyID, RcRoleID) ->
    family_misc:call_family({mod, ?MODULE, {distribute_cv_reward, Reward, RoleID, FamilyID, RcRoleID}}).
family_distribute_end_reward(RcRoleID, RoleID, FamilyID) ->
    family_misc:call_family({mod, ?MODULE, {distribute_end_reward, RcRoleID, RoleID, FamilyID}}).


handle({check_can_salary, RoleID, FamilyID}) ->
    do_check_can_salary(RoleID, FamilyID);
handle({add_continuity_victory, Rank, VctTime, FamilyID, OldFamilyID}) ->
    do_add_continuity_victory(Rank, VctTime, FamilyID, OldFamilyID);
handle({end_continuity_victory, FamilyID, VctTime}) ->
    do_end_continuity_victory(FamilyID, VctTime);
handle({distribute_cv_reward, Reward, RoleID, FamilyID, RcRoleID}) ->
    do_distribute_cv_reward(Reward, RoleID, FamilyID, RcRoleID);
handle({distribute_end_reward, RcRoleID, RoleID, FamilyID}) ->
    do_distribute_end_reward(RoleID, FamilyID, RcRoleID);
handle(Info) ->
    ?ERROR_MSG("unkonw info :~w", [Info]).

do_distribute_end_reward(RoleID, FamilyID, RcRoleID) ->
    case catch check_can_distribute_end(RoleID, FamilyID, RcRoleID) of
        ok ->
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.


check_can_distribute_end(RoleID, FamilyID, RcRoleID) ->
    Family = mod_family_data:get_family(FamilyID),
    #p_family{members = Members, end_cv = EndReward, cv_reward = CvReward, max_cv = MaxCv} = Family,
    case lists:keyfind(RoleID, #p_family_member.role_id, Members) of
        false ->
            ?THROW_ERR(?ERROR_FAMILY_BATTLE_ECV_REWARD_002);
        OWNER ->
            ?IF(OWNER#p_family_member.title =:= ?TITLE_OWNER, ok, ?THROW_ERR(?ERROR_FAMILY_KICK_002)),
            case lists:keyfind(RcRoleID, #p_family_member.role_id, Members) of
                #p_family_member{} ->
                    ?IF(EndReward =:= 0, ?THROW_ERR(?ERROR_FAMILY_BATTLE_CV_REWARD_001), ok),
                    NewFamily = Family#p_family{end_cv = 0},
                    mod_family_data:set_family(NewFamily),
                    [Config] = lib_config:find(cfg_fbt_end, EndReward),
                    ReWards = lib_tool:string_to_intlist(Config#c_fbt_end.reward),
                    Goods = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- ReWards],
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_FAMILY_BT_END_CV,
                        action = ?ITEM_GAIN_LETTER_FAMILY_BT_END_CV,
                        goods_list = Goods
                    },
                    common_broadcast:bc_record_to_family(FamilyID, #m_family_refresh_bt_info_toc{cv_reward = CvReward, max_cv = MaxCv, end_cv = 0}),
                    common_letter:send_letter(RcRoleID, LetterInfo),
                    ok;
                false ->
                    ?THROW_ERR(?ERROR_FAMILY_BATTLE_ECV_REWARD_002)
            end
    end.



do_distribute_cv_reward(Reward, RoleID, FamilyID, RcRoleID) ->
    case catch check_can_distribute_cv(Reward, RoleID, FamilyID, RcRoleID) of
        ok ->
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_distribute_cv(Reward, RoleID, FamilyID, RcRoleID) ->
    Family = mod_family_data:get_family(FamilyID),
    #p_family{members = Members, max_cv = MaxCv, end_cv = EndCv} = Family,
    ?IF(Family#p_family.cv_reward =:= [], ?THROW_ERR(?ERROR_FAMILY_BATTLE_ECV_REWARD_001), ok),
    [CvReward] = Family#p_family.cv_reward,
    case lists:keyfind(RoleID, #p_family_member.role_id, Members) of
        false ->
            ?THROW_ERR(?ERROR_FAMILY_BATTLE_ECV_REWARD_002);
        OWNER ->
            ?IF(OWNER#p_family_member.title =:= ?TITLE_OWNER, ok, ?THROW_ERR(?ERROR_FAMILY_KICK_002)),
            case lists:keyfind(RcRoleID, #p_family_member.role_id, Members) of
                #p_family_member{} ->
                    case Reward =:= CvReward of
                        false ->
                            ?THROW_ERR(?ERROR_FAMILY_BATTLE_CV_REWARD_001);
                        _ ->
                            NewFamily = Family#p_family{cv_reward = []},
                            mod_family_data:set_family(NewFamily),
                            WorldLevel = world_data:get_world_level(),
                            case mod_family_bt:get_vc_config(Reward#p_kv.id, Reward#p_kv.val, WorldLevel) of
                                false ->
                                    ?THROW_ERR(?ERROR_FAMILY_BATTLE_CV_REWARD_004);
                                Config ->
                                    ReWards = lib_tool:string_to_intlist(Config#c_fbt_cv_reward.vc_reward),
                                    Goods = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- ReWards],
                                    LetterInfo = #r_letter_info{
                                        template_id = ?LETTER_FAMILY_BT_CV,
                                        action = ?ITEM_GAIN_LETTER_FAMILY_BT_CV,
                                        goods_list = Goods
                                    },
                                    common_broadcast:bc_record_to_family(FamilyID, #m_family_refresh_bt_info_toc{cv_reward = [], max_cv = MaxCv, end_cv = EndCv}),
                                    common_letter:send_letter(RcRoleID, LetterInfo),
                                    ok
                            end
                    end;
                false ->
                    ?THROW_ERR(?ERROR_FAMILY_BATTLE_ECV_REWARD_002)
            end
    end.


%%胜利组
do_add_continuity_victory(Rank, VctTime, FamilyID, OldFamilyID) ->
    ?IF(?HAS_FAMILY(OldFamilyID), force_distribute_cv(OldFamilyID), ok),
    Family = mod_family_data:get_family(FamilyID),
    NewFamily = case lists:keytake(Rank, #p_kv.id, Family#p_family.max_cv) of
                    {value, #p_kv{val = Val}, Other} ->
                        case VctTime > Val andalso VctTime =/= 1 of
                            true ->
                                MaxCv = [#p_kv{id = Rank, val = VctTime}|Other],
                                ?IF(Family#p_family.cv_reward =:= [], ok, distribute_cv_to_owner(Family)),
                                common_broadcast:bc_record_to_family(FamilyID, #m_family_refresh_bt_info_toc{cv_reward = [#p_kv{id = Rank, val = VctTime}], max_cv = MaxCv, end_cv = Family#p_family.end_cv}),
                                Family#p_family{cv_reward = [#p_kv{id = Rank, val = VctTime}], max_cv = MaxCv};
                            _ ->
                                Family
                        end;
                    _ ->
                        Family
                end,
    NewMembers = [OldMember#p_family_member{salary = false} || OldMember <- NewFamily#p_family.members],
    mod_family_data:set_family(NewFamily#p_family{members = NewMembers}),
    common_broadcast:bc_record_to_family(FamilyID, #m_family_battle_salary_update_toc{}).


%%强制分配旧帮派连胜奖励
force_distribute_cv(OldFamilyID) ->
    OldFamily = mod_family_data:get_family(OldFamilyID),
    case OldFamily#p_family.cv_reward of
        [] ->
            ok;
        [Pkv] ->
            #p_family_member{role_id = RoleID} = lists:keyfind(?TITLE_OWNER, #p_family_member.title, OldFamily#p_family.members),
            WorldLevel = world_data:get_world_level(),
            case mod_family_bt:get_vc_config(Pkv#p_kv.id, Pkv#p_kv.val, WorldLevel) of
                false ->
                    ok;
                Config ->
                    ReWards = lib_tool:string_to_intlist(Config#c_fbt_cv_reward.vc_reward),
                    Goods = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- ReWards],
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_FAMILY_BT_CV,
                        action = ?ITEM_GAIN_LETTER_FAMILY_BT_CV,
                        goods_list = Goods
                    },
                    common_broadcast:bc_record_to_family(OldFamilyID, #m_family_refresh_bt_info_toc{cv_reward = [], max_cv = OldFamily#p_family.max_cv, end_cv = OldFamily#p_family.end_cv}),
                    common_letter:send_letter(RoleID, LetterInfo),
                    mod_family_data:set_family(OldFamily#p_family{cv_reward = []}),
                    ok
            end
    end.



do_end_continuity_victory(FamilyID, VctTime) ->
    #p_family{members = Members} = Family = mod_family_data:get_family(FamilyID),
    common_broadcast:bc_record_to_family(FamilyID, #m_family_refresh_bt_info_toc{cv_reward = Family#p_family.cv_reward, max_cv = Family#p_family.max_cv, end_cv = Family#p_family.end_cv}),
    mod_family_data:set_family(Family#p_family{end_cv = VctTime}),
    [mod_role_achievement:family_end_continuity_victory(RoleID) || #p_family_member{role_id = RoleID} <- Members].

do_check_can_salary(RoleID, FamilyID) ->
    Family = mod_family_data:get_family(FamilyID),
    #p_family{members = Members} = Family,
    case lists:keytake(RoleID, #p_family_member.role_id, Members) of
        {value, Member, Other} ->
            case Member#p_family_member.salary =:= false of
                true ->
                    NewMembers = [Member#p_family_member{salary = true}|Other],
                    mod_family_data:set_family(Family#p_family{members = NewMembers}),
                    ok;
                _ ->
                    {error, ?ERROR_FAMILY_BATTLE_SALARY_001}
            end;
        _ ->
            {error, ?ERROR_FAMILY_BATTLE_ECV_REWARD_002}
    end.

%%强制分配奖励给帮会拥有者
distribute_cv_to_owner(Family) ->
    case lists:keyfind(?TITLE_OWNER, #p_family_member.title, Family#p_family.members) of
        #p_family_member{role_id = RoleID} ->
            WorldLevel = world_data:get_world_level(),
            [Reward] = Family#p_family.cv_reward,
            case mod_family_bt:get_vc_config(Reward#p_kv.id, Reward#p_kv.val, WorldLevel) of
                false ->
                    undefined;
                Config ->
                    ReWards = lib_tool:string_to_intlist(Config#c_fbt_cv_reward.vc_reward),
                    Goods = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- ReWards],
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_FAMILY_BT_CV,
                        action = ?ITEM_GAIN_LETTER_FAMILY_BT_CV,
%%                        text_string = [lib_tool:to_list(Reward#p_kv.id), lib_tool:to_list(Reward#p_kv.val)],
                        goods_list = Goods
                    },
                    common_letter:send_letter(RoleID, LetterInfo),
                    ok
            end;
        _ ->
            undefined
    end.


%%刷新列表
refresh_list() ->
    #r_activity{start_time = StartTime} = world_activity_server:get_activity(?ACTIVITY_FAMILY_BATTLE),
    Now = time_tool:now(),
    case time_tool:is_same_date(StartTime, Now) andalso time_tool:midnight(Now) + 86400 - Now =< 43200 of
        true ->
            List = lists:foldl(
                fun(BriefData, AccList) ->
                    #p_family{members = Members} = mod_family_data:get_family(BriefData#p_family_brief.family_id),
                    case erlang:length(Members) > 0 of
                        true ->
                            [BriefData|AccList];
                        _ ->
                            AccList
                    end
                end, [], ets:tab2list(?ETS_FAMILY_BRIEFS)),
            List2 = lists:sort(
                fun(FamilyB1, FamilyB2) ->
                    #p_family_brief{rank = Rank1} = FamilyB1,
                    #p_family_brief{rank = Rank2} = FamilyB2,
                    if
                        Rank1 > Rank2 ->
                            false;
                        true ->
                            true
                    end
                end, List),
            [Config] = lib_config:find(cfg_activity, ?ACTIVITY_FAMILY_BATTLE),
            List3 = get_battle_rank(List2, Config#c_activity.min_level, [], 0, 8),
            List4 = lists:sort(
                fun(FamilyB1, FamilyB2) ->
                    #p_family_brief{rank = Rank1} = FamilyB1,
                    #p_family_brief{rank = Rank2} = FamilyB2,
                    if
                        Rank1 > Rank2 ->
                            false;
                        true ->
                            true
                    end
                end, List3),
            {_, List6} = lists:foldl(
                fun(FamilyBrief3, {NewRank, List5}) ->
                    {NewRank + 1, [#c_family_battle_rank{rank = NewRank, family_name = FamilyBrief3#p_family_brief.family_name,
                                                         family_id = FamilyBrief3#p_family_brief.family_id, power = FamilyBrief3#p_family_brief.power}|List5]}
                end, {1, []}, List4),
            world_data:set_family_battle_rank(List6);
        _ ->
            ok
    end.

get_battle_rank([], _Level, List, _Num, _MaxNum) ->
    List;
get_battle_rank(_, _Level, List, Num, MaxNum) when Num =:= MaxNum ->
    List;
get_battle_rank([#p_family_brief{family_id = FamilyID} = Info|T], Level, List, Num, MaxNum) ->
    #p_family{members = Members} = mod_family_data:get_family(FamilyID),
    case check_can_join(Members, Level) of
        true ->
            get_battle_rank(T, Level, [Info|List], Num + 1, MaxNum);
        _ ->
            get_battle_rank(T, Level, List, Num, MaxNum)
    end.

check_can_join([], _Level) ->
    false;
check_can_join([Member|T], Level) ->
    case Member#p_family_member.role_level >= Level of
        true ->
            true;
        _ ->
            check_can_join(T, Level)
    end.


%% 拿资格赛信息
get_qua_info(FamilyID) ->
    QuaList = world_data:get_family_battle_rank(),
    SendList = format_list([], QuaList),
    {Opponent, Round, OpenTime} = get_opponent_and_round(QuaList, FamilyID),
    {ok, SendList, Opponent, Round, OpenTime}.

format_list(List, []) ->
    List;
format_list(List, [Info|T]) ->
    format_list([#p_ks{id = Info#c_family_battle_rank.rank, str = Info#c_family_battle_rank.family_name}|List], T).


get_opponent_and_round(RankList, FamilyID) ->
    #r_activity{start_time = StartTime, end_time = EndTime} = world_activity_server:get_activity(?ACTIVITY_FAMILY_BATTLE),
    [Config] = lib_config:find(cfg_global, ?FAMILY_BATTLE_GLOBAL),
    [BattleTime, StandTime, _SleepTime, _] = Config#c_global.list,
    Now = time_tool:now(),
    Round = if
                StartTime + BattleTime + StandTime =< Now -> 2;
                true -> 1
            end,
    Opponent = case lists:keyfind(FamilyID, #c_family_battle_rank.family_id, RankList) of
                   false ->
                       "";
                   #c_family_battle_rank{rank = Rank} ->
                       case StartTime - 3600 =< Now andalso EndTime >= Now of
                           true ->
                               get_opponent_i(RankList, Rank, Round);
                           _ ->
                               ""
                       end
               end,
    {Opponent, Round, StartTime}.


get_opponent_i(RankList, Rank, Round) ->
    TargetRank = case Round of
                     1 ->
                         case Rank of
                             1 ->
                                 3;
                             2 ->
                                 4;
                             3 ->
                                 1;
                             4 ->
                                 2;
                             5 ->
                                 7;
                             6 ->
                                 8;
                             7 ->
                                 5;
                             8 ->
                                 6
                         end;
                     _ ->
                         case Rank of
                             1 ->
                                 2;
                             2 ->
                                 1;
                             3 ->
                                 4;
                             4 ->
                                 3;
                             5 ->
                                 6;
                             6 ->
                                 5;
                             7 ->
                                 8;
                             8 ->
                                 7
                         end
                 end,
    case lists:keyfind(TargetRank, #c_family_battle_rank.rank, RankList) of
        false ->
            "";
        #c_family_battle_rank{family_name = Name} ->
            Name
    end.


%%每日刷新俸禄
refresh_salary() ->
    TempList = world_data:get_family_temple(),
    refresh_salary(TempList).

refresh_salary([]) ->
    ok;
refresh_salary([#r_family_battle_temple{family_id = FamilyID}|T]) ->
    Family = mod_family_data:get_family(FamilyID),
    #p_family{members = Members} = Family,
    NewMembers = refresh_members_salary(Members, []),
    mod_family_data:set_family(Family#p_family{members = NewMembers}),
    common_broadcast:bc_record_to_family(FamilyID, #m_family_battle_salary_toc{salary = true}),
    refresh_salary(T).

refresh_members_salary([], List) ->
    List;
refresh_members_salary([Member|T], List) ->
    refresh_members_salary(T, [Member#p_family_member{salary = false}|List]).


gm_refresh_list() ->
    List = lists:foldl(
        fun(BriefData, AccList) ->
            #p_family{members = Members} = mod_family_data:get_family(BriefData#p_family_brief.family_id),
            case erlang:length(Members) > 0 of
                true ->
                    [BriefData|AccList];
                _ ->
                    AccList
            end
        end, [], ets:tab2list(?ETS_FAMILY_BRIEFS)),
    List2 = lists:sort(
        fun(FamilyB1, FamilyB2) ->
            #p_family_brief{rank = Rank1} = FamilyB1,
            #p_family_brief{rank = Rank2} = FamilyB2,
            if
                Rank1 > Rank2 ->
                    false;
                true ->
                    true
            end
        end, List),
    [Config] = lib_config:find(cfg_activity, ?ACTIVITY_FAMILY_BATTLE),
    List3 = get_battle_rank(List2, Config#c_activity.min_level, [], 0, 8),
    List4 = lists:sort(
        fun(FamilyB1, FamilyB2) ->
            #p_family_brief{rank = Rank1} = FamilyB1,
            #p_family_brief{rank = Rank2} = FamilyB2,
            if
                Rank1 > Rank2 ->
                    false;
                true ->
                    true
            end
        end, List3),
    {_, List6} = lists:foldl(
        fun(FamilyBrief3, {NewRank, List5}) ->
            {NewRank + 1, [#c_family_battle_rank{rank = NewRank, family_name = FamilyBrief3#p_family_brief.family_name,
                                                 family_id = FamilyBrief3#p_family_brief.family_id, power = FamilyBrief3#p_family_brief.power}|List5]}
        end, {1, []}, List4),
    world_data:set_family_battle_rank(List6).







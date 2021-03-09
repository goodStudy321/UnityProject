%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     转生相关
%%% @end
%%% Created : 04. 一月 2018 14:50
%%%-------------------------------------------------------------------
-module(mod_role_relive).
-author("laijichang").
-include("role.hrl").
-include("proto/mod_role_relive.hrl").

%% API
-export([
    init/1,
    online/1,
    calc/1,
    handle/2
]).

-export([
    mission_complete/2,
    gm_set_relive_level/3,
    trigger_relive/3,
    relive_level_up/2,
    relive_progress_up/2,
    add_talent_points/2
]).

init(#r_role{role_id = RoleID, role_relive = undefined} = State) ->
    RoleRelive = #r_role_relive{role_id = RoleID},
    State#r_role{role_relive = RoleRelive};
init(State) ->
    State.

online(State) ->
    notice_relive_info(State),
    notice_destiny(State),
    notice_talent(State),
    State.

calc(State) ->
    #r_role{role_relive = RoleRelive} = State,
    #r_role_relive{
        relive_level = ReliveLevel,
        progress = Progress,
        destiny_id = DestinyID,
        talent_skills = TalentSkills} = RoleRelive,
    LevelAttr = calc_level_attr(ReliveLevel),
    ProgressAttr = calc_progress_attr(ReliveLevel, Progress),
    DestinyAttr = calc_destiny_attr(DestinyID),
    TalentAttr = calc_talent_attr(TalentSkills),
    CalAttr = common_misc:sum_calc_attr([LevelAttr, ProgressAttr, DestinyAttr, TalentAttr]),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_RELIVE, CalAttr).

calc_level_attr(0) ->
    #actor_cal_attr{};
calc_level_attr(Level) ->
    [#c_relive{level_props = LevelProps}] = lib_config:find(cfg_role_relive, Level),
    common_misc:get_attr_by_kv([#p_kv{id = ID, val = Val} || {ID, Val} <- lib_tool:string_to_intlist(LevelProps)]).

calc_progress_attr(ReliveLevel, Progress) ->
    case Progress > 0 andalso lib_config:find(cfg_role_relive, ReliveLevel + 1) of
        [#c_relive{stage_props = StageProps}] ->
            ProgressList = string:tokens(StageProps, "|"),
            case erlang:length(ProgressList) >= Progress of
                true ->
                    StringProps = lists:nth(Progress, ProgressList),
                    common_misc:get_attr_by_kv(common_misc:get_string_props(StringProps));
                _ ->
                    #actor_cal_attr{}
            end;
        _ ->
            #actor_cal_attr{}
    end.

calc_destiny_attr(0) ->
    #actor_cal_attr{};
calc_destiny_attr(DestinyID) ->
    [#c_destiny{props = Props}] = lib_config:find(cfg_role_destiny, DestinyID),
    common_misc:get_attr_by_kv(common_misc:get_string_props(Props)).

calc_talent_attr(TalentSkills) ->
    calc_talent_attr(TalentSkills, #actor_cal_attr{}).

calc_talent_attr([], Acc) ->
    Acc;
calc_talent_attr([#p_tab_skill{skills = SkillIDs}|R], Acc) ->
    KVList =
        lists:foldl(
            fun(SkillID, KVAcc) ->
                [#c_talent_skill{props = Props}] = lib_config:find(cfg_talent_skill, SkillID),
                common_misc:get_string_props(Props) ++ KVAcc
            end, [], SkillIDs),
    Acc2 = common_misc:sum_calc_attr([common_misc:get_attr_by_kv(KVList), Acc]),
    calc_talent_attr(R, Acc2).

handle({#m_relive_up_tos{}, RoleID, _PID}, State) ->
    do_relive_up(RoleID, State);
handle({#m_destiny_up_tos{}, RoleID, _PID}, State) ->
    do_destiny_up(RoleID, State);
handle({#m_talent_reset_tos{tab_id = TabID}, RoleID, _PID}, State) ->
    do_talent_reset(RoleID, TabID, State);
handle({#m_talent_skill_tos{tab_id = TabID, talent_skill_id = NextSkillID}, RoleID, _PID}, State) ->
    do_talent_skill(RoleID, TabID, NextSkillID, State).

add_talent_points(AddPoints, State) when AddPoints > 0 ->
    #r_role{role_id = RoleID, role_relive = RoleRelive} = State,
    #r_role_relive{talent_points = TalentPoints} = RoleRelive,
    TalentPoints2 = TalentPoints + AddPoints,
    common_misc:unicast(RoleID, #m_talent_point_toc{talent_points = TalentPoints2}),
    RoleRelive2 = RoleRelive#r_role_relive{talent_points = TalentPoints2},
    State#r_role{role_relive = RoleRelive2};
add_talent_points(_AddPoints, State) ->
    State.

mission_complete(MissionID, State) ->
    trigger_relive(?RELIVE_TRIGGER_MISSION, MissionID, State).

trigger_relive(Type, Args, State) ->
    #r_role{role_relive = RoleRelive} = State,
    #r_role_relive{relive_level = ReliveLevel, progress = Progress} = RoleRelive,
    ReliveLevel2 = ReliveLevel + 1,
    case lib_config:find(cfg_role_relive, ReliveLevel2) of
        [#c_relive{target = Target}] ->
            TargetList = lib_tool:string_to_intlist(Target),
            case Progress < erlang:length(TargetList) of
                true ->
                    Progress2 = Progress + 1,
                    {NeedType, NeedID} = lists:nth(Progress2, TargetList),
                    case NeedType =:= Type andalso NeedID =:= Args of
                        true ->
                            relive_progress_up(Progress2, State);
                        _ ->
                            State
                    end;
                _ ->
                    State
            end;
        _ ->
            State
    end.

gm_set_relive_level(ReliveLevel, Progress, State) ->
    #r_role{role_relive = #r_role_relive{relive_level = OldReliveLevel} = RoleRelive} = State,
    if
        ReliveLevel =:= 0 ->
            RoleRelive2 = RoleRelive#r_role_relive{relive_level = 0},
            relive_progress_up(Progress, State#r_role{role_relive = RoleRelive2});
        ReliveLevel > OldReliveLevel ->
            State2  =
                lists:foldl(
                    fun(NewLevel, StateAcc) ->
                        relive_level_up(NewLevel, StateAcc)
                    end, State, lists:seq(OldReliveLevel + 1, ReliveLevel)),
            relive_progress_up(Progress, State2);
        true ->
            State2 = relive_level_up(ReliveLevel, State),
            relive_progress_up(Progress, State2)
    end.

do_relive_up(RoleID, State) ->
    case catch check_relive_up(State) of
        {ok, ReliveLevel} ->
            relive_level_up(ReliveLevel, State);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_relive_info_toc{err_code = ErrCode}),
            State
    end.

check_relive_up(State) ->
    #r_role{role_relive = RoleRelive} = State,
    #r_role_relive{relive_level = ReliveLevel, progress = Progress, destiny_id = DestinyID} = RoleRelive,
    ReliveLevel2 = ReliveLevel + 1,
    case lib_config:find(cfg_role_relive, ReliveLevel2) of
        [#c_relive{role_level = NeedRoleLevel, target = Target}] ->
            ?IF(mod_role_data:get_role_level(State) >= NeedRoleLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
            TargetList = lib_tool:string_to_intlist(Target),
            if
                ReliveLevel2 =:= ?RELIVE_LEVEL_DESTINY -> %% 进行4转是判断命格
                    ?IF(is_max_destiny(DestinyID), ok, ?THROW_ERR(?ERROR_RELIVE_INFO_001));
                true ->
                    ?IF(Progress =:= erlang:length(TargetList), ok, ?THROW_ERR(?ERROR_RELIVE_INFO_001))
            end,
            {ok, ReliveLevel2};
        _ ->
            ?THROW_ERR(?ERROR_RELIVE_INFO_002)
    end.

relive_level_up(ReliveLevel, State) ->
    #r_role{role_id = RoleID, role_relive = RoleRelive, role_attr = #r_role_attr{category = Category}} = State,
    [#c_relive{
        category_1_skills = Skills1,
        category_2_skills = Skills2}] = lib_config:find(cfg_role_relive, ReliveLevel),
    RoleRelive2 = RoleRelive#r_role_relive{relive_level = ReliveLevel, progress = 0},
    State2 = State#r_role{role_relive = RoleRelive2},
    Skills =
        if
            Category =:= ?CATEGORY_1 ->
                Skills1;
            true ->
                Skills2
        end,
    State3 =
        lists:foldl(
            fun(SkillID, StateAcc) ->
                mod_role_skill:skill_open(SkillID, StateAcc)
            end, State2, Skills),
    notice_relive_info(State3),
    State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_RELIVE_STEP, ReliveLevel),
    State5 = mod_role_mission:condition_update(State4),
    mod_map_role:update_relive_level(mod_role_dict:get_map_pid(), RoleID, ReliveLevel),
    State6 = mod_role_achievement:relive_level_up(ReliveLevel, State5),
    case ReliveLevel =:= ?RELIVE_LEVEL_DESTINY of
        true ->
            State7 = mod_role_level:do_add_exp(State6, 1, ?EXP_ADD_FROM_RELIVE_UP),
            State8 = add_talent_points(common_misc:get_global_int(?GLOBAL_RELIVE_TALENT_PINTS), State7),
            notice_talent(State8),
            State8;
        _ ->
            State6
    end.

relive_progress_up(Progress, State) ->
    #r_role{role_relive = RoleRelive} = State,
    RoleRelive2 = RoleRelive#r_role_relive{progress = Progress},
    State2 = State#r_role{role_relive = RoleRelive2},
    notice_relive_info(State2),
    State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_RELIVE_PROGRESS, Progress),
    mod_role_mission:condition_update(State3).

do_destiny_up(RoleID, State) ->
    case catch check_destiny_up(State) of
        {ok, BagDoings, ReduceExp, DestinyID, State2} ->
            State3 = mod_role_level:reduce_exp(ReduceExp, State2),
            State4 = mod_role_bag:do(BagDoings, State3),
            common_misc:unicast(RoleID, #m_destiny_up_toc{destiny_id = DestinyID}),
            mod_role_fight:calc_attr_and_update(calc(State4), ?POWER_RELIVE_DESTINY_UP, DestinyID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_destiny_up_toc{err_code = ErrCode}),
            State
    end.

check_destiny_up(State) ->
    #r_role{role_attr = RoleAttr, role_relive = RoleRelive} = State,
    #r_role_attr{level = Level, exp = Exp} = RoleAttr,
    #r_role_relive{relive_level = ReliveLevel, destiny_id = DestinyID} = RoleRelive,
    ?IF(ReliveLevel >= ?RELIVE_LEVEL_DESTINY - 1, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_RELIVE_LEVEL)),
    [#c_relive{role_level = NeedRoleLevel}] = lib_config:find(cfg_role_relive, ?RELIVE_LEVEL_DESTINY),
    ?IF(Level >= NeedRoleLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    DestinyID2 = DestinyID + 1,
    Config =
        case lib_config:find(cfg_role_destiny, DestinyID + 1) of
            [ConfigT] ->
                ConfigT;
            _ ->
                ?THROW_ERR(?ERROR_DESTINY_UP_001)
        end,
    #c_destiny{need_items = NeedItems, need_exp = NeedExp} = Config,
    {BagDoings, ReduceExp} =
    case catch mod_role_bag:check_num_by_item_list(common_misc:get_item_reward(NeedItems), ?ITEM_REDUCE_DESTINY_UP, State) of
        BagDoingsT when erlang:is_list(BagDoingsT) ->
            {BagDoingsT, 0};
        _ ->
            ?IF(Exp >= NeedExp, ok, ?THROW_ERR(?ERROR_DESTINY_UP_002)),
            {[], NeedExp}
    end,
    RoleRelive2 = RoleRelive#r_role_relive{destiny_id = DestinyID2},
    State2 = State#r_role{role_relive = RoleRelive2},
    {ok, BagDoings, ReduceExp, DestinyID2, State2}.

do_talent_reset(RoleID, TabID, State) ->
    case catch check_talent_reset(TabID, State) of
        {ok, BagDoings, TalentPoints, TabSkills, AllSkillIDs, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_talent_reset_toc{talent_points = TalentPoints, tab_skills = TabSkills}),
            mod_role_skill:skill_fun_change(?SKILL_FUN_TALENT, AllSkillIDs, calc(State3));
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_talent_reset_toc{err_code = ErrCode}),
            State
    end.

check_talent_reset(TabID, State) ->
    #r_role{role_relive = RoleRelive} = State,
    #r_role_relive{
        talent_points = TalentPoints,
        talent_skills = TalentSkills} = RoleRelive,
    #p_tab_skill{skills = SkillIDs} = get_tab_skill(TabID, TalentSkills),
    ?IF(SkillIDs =/= [], ok, ?THROW_ERR(?ERROR_TALENT_RESET_001)),
    [TypeID, Num, ActTypeID, ActNum|_] = common_misc:get_global_list(?GLOBAL_RESET_TALENT_ITEM),
    BagDoings =
        case catch mod_role_bag:check_num_by_type_id(ActTypeID, ActNum, ?ITEM_REDUCE_TALENT_SKILL_RESET, State) of
            BagDoingsT when erlang:is_list(BagDoingsT) ->
                BagDoingsT;
            _ ->
                mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_TALENT_SKILL_RESET, State)
        end,
    AddPoints = get_all_points(SkillIDs),
    TalentPoints2 = TalentPoints + AddPoints,
    TabSkills2 = #p_tab_skill{tab_id = TabID},
    TalentSkills2 = set_tab_skill(TabSkills2, TalentSkills),
    AllSkillIDs = get_all_talent_skills(TalentSkills2),
    RoleRelive2 = RoleRelive#r_role_relive{talent_points = TalentPoints2, talent_skills = TalentSkills2},
    State2 = State#r_role{role_relive = RoleRelive2},
    {ok, BagDoings, TalentPoints2, TabSkills2, AllSkillIDs, State2}.

do_talent_skill(RoleID, TabID, NextSkillID, State) ->
    case catch check_talent_skill(NextSkillID, TabID, State) of
        {ok, TalentPoints, AllSkillIDs, State2} ->
            common_misc:unicast(RoleID, #m_talent_skill_toc{talent_points = TalentPoints, learn_skill = NextSkillID}),
            mod_role_skill:skill_fun_change(?SKILL_FUN_TALENT, AllSkillIDs, calc(State2));
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_talent_skill_toc{err_code = ErrCode}),
            State
    end.

check_talent_skill(NextSkillID, TabID, State) ->
    #r_role{role_relive = RoleRelive} = State,
    #r_role_relive{
        talent_points = TalentPoints,
        talent_skills = TalentSkills} = RoleRelive,
    [#c_talent_skill{
        need_point = NeedPoint,
        pre_skill = PreSkillID,
        tree_id = TreeID,
        need_role_level = NeedRoleLevel,
        need_all_points = NeedAllPoints}] = lib_config:find(cfg_talent_skill, NextSkillID),
    ?IF(TalentPoints >= NeedPoint, ok, ?THROW_ERR(?ERROR_TALENT_SKILL_001)),
    #p_tab_skill{skills = SkillIDs} = TabSkills = get_tab_skill(TabID, TalentSkills),
    NowTabPoints = get_all_points(SkillIDs),
    AllPoints = get_all_points(get_all_talent_skills(TalentSkills)),
    ?IF(mod_role_data:get_role_level(State) >= NeedRoleLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(NowTabPoints >= NeedAllPoints, ok, ?THROW_ERR(?ERROR_TALENT_SKILL_007)),
    check_tab_skill(TabID, TreeID, SkillIDs, AllPoints, TalentPoints),
    check_pre_skill(PreSkillID, SkillIDs),
    TalentPoints2 = TalentPoints - NeedPoint,
    SkillIDs2 = replace_talent_skill(?GET_BASE_ID(NextSkillID), NextSkillID, SkillIDs, []),
    TabSkills2 = TabSkills#p_tab_skill{skills = SkillIDs2},
    TalentSkills2 = set_tab_skill(TabSkills2, TalentSkills),
    AllSkillIDs = get_all_talent_skills(TalentSkills2),

    RoleRelive2 = RoleRelive#r_role_relive{talent_points = TalentPoints2, talent_skills = TalentSkills2},
    State2 = State#r_role{role_relive = RoleRelive2},
    {ok, TalentPoints2, AllSkillIDs, State2}.

%% 查看当前页签能不能学习
check_tab_skill(TabID, TreeID, SkillIDs, AllPoints, TalentPoints) ->
    case SkillIDs of
        [OldSkillID|_] ->
            [#c_talent_skill{tree_id = OldTreeID}] = lib_config:find(cfg_talent_skill, OldSkillID),
            ?IF(TreeID =:= OldTreeID, ok, ?THROW_ERR(?ERROR_TALENT_SKILL_004));
        _ -> %% 新开启的页签，检查条件
            [#c_talent_tab{tree_list = TreeList, pre_points = PrePoints}] = lib_config:find(cfg_talent_tab, TabID),
            ?IF(lists:member(TreeID, TreeList), ok, ?THROW_ERR(?ERROR_TALENT_SKILL_005)),
            ?IF(AllPoints + TalentPoints >= PrePoints, ok, ?THROW_ERR(?ERROR_TALENT_SKILL_006))
    end.

check_pre_skill(0, _TalentSkills) ->
    ok;
check_pre_skill(PreSkillID, TalentSkills) ->
    check_pre_skill2(?GET_BASE_ID(PreSkillID), PreSkillID, TalentSkills).

check_pre_skill2(_PreSkillGroup, _PreSkillID, []) ->
    ?THROW_ERR(?ERROR_TALENT_SKILL_002);
check_pre_skill2(PreBaseID, PreSkillID, [SkillID|R]) ->
    case PreBaseID =:= ?GET_BASE_ID(PreSkillID) andalso SkillID >= PreSkillID of
        true ->
            ok;
        _ ->
            check_pre_skill2(PreBaseID, PreSkillID, R)
    end.

replace_talent_skill(_BaseID, NextSkillID, [], Acc) ->
    [NextSkillID|Acc];
replace_talent_skill(BaseID, NextSkillID, [SkillID|R], Acc) ->
    case BaseID =:= ?GET_BASE_ID(SkillID) of
        true ->
            ?IF(NextSkillID > SkillID, ok, ?THROW_ERR(?ERROR_TALENT_SKILL_003)),
            [NextSkillID|R] ++ Acc;
        _ ->
            replace_talent_skill(BaseID, NextSkillID, R, [SkillID|Acc])
    end.

get_tab_skill(TabID, TabSkills) ->
    case lists:keyfind(TabID, #p_tab_skill.tab_id, TabSkills) of
        #p_tab_skill{} = TabSkill ->
            TabSkill;
        _ ->
            #p_tab_skill{tab_id = TabID}
    end.

set_tab_skill(TabSkill, TabSkills) ->
    lists:keystore(TabSkill#p_tab_skill.tab_id, #p_tab_skill.tab_id, TabSkills, TabSkill).

get_all_talent_skills(TalentSkills) ->
    get_all_talent_skills2(TalentSkills, []).

get_all_talent_skills2([], SkillIDs) ->
    SkillIDs;
get_all_talent_skills2([#p_tab_skill{skills = SkillIDs}|R], AccSkillIDs) ->
    get_all_talent_skills2(R, SkillIDs ++ AccSkillIDs).

get_all_points(SkillIDs) ->
    lists:sum(
        [ begin
              [#c_talent_skill{reset_point = ResetPoint}] = lib_config:find(cfg_talent_skill, SkillID),
              ResetPoint
          end || SkillID <- SkillIDs]).

notice_relive_info(State) ->
    #r_role{role_id = RoleID, role_relive = RoleRelive} = State,
    #r_role_relive{relive_level = ReliveLevel, progress = Progress} = RoleRelive,
    common_misc:unicast(RoleID, #m_relive_info_toc{relive_level = ReliveLevel, progress = Progress}).

notice_destiny(State) ->
    #r_role{role_id = RoleID, role_relive = RoleRelive} = State,
    #r_role_relive{destiny_id = DestinyID} = RoleRelive,
    ?IF(DestinyID > 0, common_misc:unicast(RoleID, #m_destiny_info_toc{destiny_id = DestinyID}), ok).

notice_talent(State) ->
    #r_role{role_id = RoleID, role_relive = RoleRelive} = State,
    #r_role_relive{talent_points = TalentPoints, talent_skills = TalentSkills} = RoleRelive,
    ?IF(TalentPoints > 0 orelse TalentSkills =/= [], common_misc:unicast(RoleID, #m_talent_info_toc{talent_points = TalentPoints, talent_skills = TalentSkills}), ok).

is_max_destiny(DestinyID) ->
    case lib_config:find(cfg_role_destiny, DestinyID + 1) of
        [_Config] ->
            false;
        _ ->
            true
    end.

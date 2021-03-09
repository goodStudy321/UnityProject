%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 九月 2018 9:49
%%%-------------------------------------------------------------------
-module(mod_role_family_bt).
-author("WZP").
-include("map.hrl").
-include("role.hrl").
-include("family.hrl").
-include("family_battle.hrl").
-include("activity.hrl").
-include("team.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_team.hrl").
-include("proto/mod_map_family_battle.hrl").


%% API
-export([
    check_role_pre_enter/1,
    system_open_info/1,
    role_enter_map/1,
    is_able/1,
    online/1
]).

-export([
    tran_to_list/2
]).

-export([
    gm_reset_family_bt/2
]).

role_enter_map(#r_role{role_map = RoleMap} = State) ->
    case ?IS_MAP_FAMILY_BT(RoleMap#r_role_map.map_id) of
        true ->
            mod_role_buff:do_add_buff([#buff_args{buff_id = ?FAMILY_BATTLE_MAP_BUFF, from_actor_id = 0}], State);
        _ ->
            State
    end.

is_able(_State) ->
    case mod_family_bt:is_activity_open() of
        true ->
            true;
        _ ->
            false
    end.

system_open_info(State) ->
    online(State).

online(#r_role{role_id = RoleID} = State) ->
    case world_data:get_family_temple() of
        [] ->
            ok;
        TempleList ->
            List = tran_to_list(TempleList, []),
            common_misc:unicast(RoleID, #m_family_battle_temple_toc{list = List})
    end,
    State.

tran_to_list([], List) ->
    List;
tran_to_list([Temple|T], List) ->
    #r_family_battle_temple{role_name = Name, skin = Skin, rank = Rank, family_name = FamilyName, sex = Sex, level = Level, category = Category, cv_time = CvTimes} = Temple,
    Info = #p_temple_statue{skin = Skin, cv_times = CvTimes, rank = Rank, family_name = FamilyName, name = Name, sex = Sex, level = Level, category = Category},
    tran_to_list(T, [Info|List]).


check_role_pre_enter(State) ->
    case catch check_pre_enter(State) of
        {ok, ExtraID, CampID} -> %% 之前进入过地图
            {ok, BornPos} = map_misc:get_born_pos(#r_born_args{map_id = ?MAP_FAMILY_BT, camp_id = CampID}),
            {ExtraID, CampID, BornPos};
        {error, ErrCode} ->
            ?THROW_ERR(ErrCode)
    end.

check_pre_enter(#r_role{role_attr = RoleAttr, role_id = RoleID} = State) ->
%%    ?IF(?HAS_TEAM(RoleAttr#r_role_attr.team_id), ?THROW_ERR(?ERROR_TEAM_CREATE_002), ok),
    #r_activity{status = Status, start_time = StartTime} = world_activity_server:get_activity(?ACTIVITY_FAMILY_BATTLE),
    ?IF(Status =:= ?STATUS_OPEN, ok, ?THROW_ERR(?ERROR_PRE_ENTER_010)),
    ?IF(?HAS_FAMILY(RoleAttr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_LEAVE_001)),
    [Config] = lib_config:find(cfg_activity, ?ACTIVITY_FAMILY_BATTLE),
    ?IF(RoleAttr#r_role_attr.level >= Config#c_activity.min_level, ok, ?THROW_ERR(?ERROR_PRE_ENTER_001)),
    RankList = world_data:get_family_battle_rank(),
    case lists:keyfind(RoleAttr#r_role_attr.family_id, #c_family_battle_rank.family_id, RankList) of
        false ->
            ?THROW_ERR(?ERROR_PRE_ENTER_019);
        #c_family_battle_rank{rank = Rank} ->
            Round = get_round(StartTime),
            ExtraID = mod_family_bt:get_extra_by_rank(Rank, Round),
            case mod_map_family_bt:check_pre_enter(ExtraID, RoleAttr#r_role_attr.family_id, RoleID, RoleAttr#r_role_attr.role_name, RoleAttr#r_role_attr.family_name) of
                {ok, Camp} ->
                    check_end_buff(State, Rank, Round),
                    {ok, ExtraID, Camp};
                {error, ErrCode} ->
                    {error, ErrCode};
                Err ->
                    ?ERROR_MSG("---check_pre_enter---Err----------~w", [Err]),
                    ?ERROR_MSG("---ExtraID---------~w", [ExtraID]),
                    {error, ?ERROR_FAMILY_BATTLE_CV_REWARD_005}
            end
    end.

check_end_buff(State, Rank, Round) ->
    case catch check_end_buff_i(State, Rank, Round) of
        ok ->
            State;
        {error, ErrCode} ->
            ?ERROR_MSG("---FBT---ErrCode----------~w", [ErrCode]),
            State;
        _ ->
            State
    end.

check_end_buff_i(State, Rank, Round) ->
    case Rank =:= 2 andalso Round =:= 2 of
        false ->
            nobuff;
        _ ->
            TempList = world_data:get_family_temple(),
            Temp = lists:keyfind(1, #r_family_battle_temple.rank, TempList),
            case lib_config:find(cfg_fbt_end, Temp#r_family_battle_temple.cv_time) of
                [Config] ->
                    mod_role_buff:add_buff([#buff_args{buff_id = Config#c_fbt_end.buff, from_actor_id = 0}], State#r_role.role_id);
                _ ->
                    ok
            end,
            ok
    end.


get_round(StartTime) ->
    [Config] = lib_config:find(cfg_global, ?FAMILY_BATTLE_GLOBAL),
    [BattleTime, StandTime, SleepTime, _] = Config#c_global.list,
    Now = time_tool:now(),
    if
        StartTime + BattleTime + StandTime >= Now -> 1;
        StartTime + BattleTime + StandTime + SleepTime >= Now -> ?THROW_ERR(?ERROR_PRE_ENTER_010);
        true -> 2
    end.


gm_reset_family_bt(State, Num) ->
    case Num of
        1 ->
            reset_salary(State);
        2 ->
            reset_end_reward(State);
        _ ->
            reset_cv_reward(State)
    end,
    State.

reset_salary(#r_role{role_attr = Attr, role_private_attr = PrivateAttr, role_id = RoleID}) ->
    FamilyID = Attr#r_role_attr.family_id,
    FamilyData = mod_family_data:get_family(FamilyID),
    #p_family{members = Members} = FamilyData,
    {value, Member, Other} = lists:keytake(RoleID, #p_family_member.role_id, Members),
    NewMember = Member#p_family_member{salary = false},
    NewFamily = FamilyData#p_family{members = [NewMember|Other]},
    mod_family_data:set_family(NewFamily),
    Integral = case lists:keyfind(RoleID, #p_family_member.role_id, NewFamily#p_family.members) of
                   false ->
                       0;
                   PFMember ->
                       PFMember#p_family_member.integral
               end,
    BoxList = mod_role_family:get_role_family_box(FamilyID, RoleID),
    common_misc:unicast(RoleID, #m_family_info_toc{family_info = NewFamily, integral = Integral, skill_list = PrivateAttr#r_role_private_attr.family_skills, box_list = BoxList}).


reset_end_reward(#r_role{role_attr = Attr, role_private_attr = PrivateAttr, role_id = RoleID}) ->
    FamilyID = Attr#r_role_attr.family_id,
    FamilyData = mod_family_data:get_family(FamilyID),
    NewFamily = FamilyData#p_family{end_cv = 2},
    mod_family_data:set_family(NewFamily),
    Integral = case lists:keyfind(RoleID, #p_family_member.role_id, NewFamily#p_family.members) of
                   false ->
                       0;
                   PFMember ->
                       PFMember#p_family_member.integral
               end,
    BoxList = mod_role_family:get_role_family_box(FamilyID, RoleID),
    common_misc:unicast(RoleID, #m_family_info_toc{family_info = NewFamily, integral = Integral, skill_list = PrivateAttr#r_role_private_attr.family_skills, box_list = BoxList}).


reset_cv_reward(#r_role{role_attr = Attr, role_private_attr = PrivateAttr, role_id = RoleID}) ->
    FamilyID = Attr#r_role_attr.family_id,
    FamilyData = mod_family_data:get_family(FamilyID),
    NewFamily = FamilyData#p_family{cv_reward = [#p_kv{id = 1, val = 2}]},
    mod_family_data:set_family(NewFamily),
    Integral = case lists:keyfind(RoleID, #p_family_member.role_id, NewFamily#p_family.members) of
                   false ->
                       0;
                   PFMember ->
                       PFMember#p_family_member.integral
               end,
    BoxList = mod_role_family:get_role_family_box(FamilyData#p_family.family_id, RoleID),
    common_misc:unicast(RoleID, #m_family_info_toc{family_info = NewFamily, integral = Integral, skill_list = PrivateAttr#r_role_private_attr.family_skills, box_list = BoxList}).







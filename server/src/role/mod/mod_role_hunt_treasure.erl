%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     藏宝图
%%% @end
%%% Created : 21. 三月 2019 15:09
%%%-------------------------------------------------------------------
-module(mod_role_hunt_treasure).
-author("laijichang").
-include("role.hrl").
-include("hunt_treasure.hrl").
-include("proto/mod_role_hunt_treasure.hrl").
-include("proto/mod_role_item.hrl").
-include("team.hrl").

%% API
-export([
    init/1,
    online/1
]).

-export([
    role_pre_enter/1,
    use_item/2
]).

-export([
    do_event_item_reward/3
]).

init(#r_role{role_id = RoleID, role_hunt_treasure = undefined} = State) ->
    RoleHuntTreasure = #r_role_hunt_treasure{role_id = RoleID},
    State#r_role{role_hunt_treasure = RoleHuntTreasure};
init(State) ->
    State.

online(State) ->
    #r_role{role_id = RoleID, role_hunt_treasure = RoleHuntTreasure} = State,
    #r_role_hunt_treasure{
        end_time = EndTime,
        event_id = EventID,
        type_id = TypeID,
        map_id = MapID,
        int_pos = IntPos
        } = RoleHuntTreasure,
    case time_tool:now() < EndTime of
        true ->
            DataRecord = #m_hunt_treasure_status_toc{
                end_time = EndTime,
                event_id = EventID,
                type_id = TypeID,
                map_id = MapID,
                pos = IntPos
            },
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end,
    State.

role_pre_enter(State) ->
    #r_role{
        role_id = RoleID,
        role_hunt_treasure = RoleHuntTreasure,
        role_map = #r_role_map{map_id = MapID}
    } = State,
    #r_role_hunt_treasure{
        end_time = EndTime,
        event_id = EventID
    } = RoleHuntTreasure,
    case time_tool:now() < EndTime of
        true ->
            [#c_hunt_treasure_event{map_id = EventMapID}] = lib_config:find(cfg_hunt_treasure_event, EventID),
            case EventMapID =:= MapID of
                true ->
                    common_misc:unicast(RoleID, #m_hunt_treasure_status_toc{end_time = 0}),
                    RoleHuntTreasure2 = RoleHuntTreasure#r_role_hunt_treasure{end_time = 0, event_id = 0},
                    State#r_role{role_hunt_treasure = RoleHuntTreasure2};
                _ ->
                    State
            end;
        _ ->
            State
    end.

use_item(TypeID, State) ->
    #r_role{role_id = RoleID,
        role_hunt_treasure = RoleHuntTreasure,
        role_map = #r_role_map{map_id = MapID},
        role_attr = #r_role_attr{level = RoleLevel, team_id = TeamID}
    } = State,
    #r_role_hunt_treasure{end_time = EndTime} = RoleHuntTreasure,
    Now = time_tool:now(),
    ?IF(time_tool:now() > EndTime, ok, ?THROW_ERR(?ERROR_ITEM_USE_015)),
    [#c_hunt_treasure_item{
        event_string = EventString,
        pos_string = PosString,
        hunt_treasure_score = AddScore
    }] = lib_config:find(cfg_hunt_treasure_item, TypeID),
    RoleList =
        case ?HAS_TEAM(TeamID) andalso mod_team_data:get_team_data(TeamID) of
            #r_team{captain_role_id = RoleID, role_list = RoleListT} ->
                RoleListT;
            _ ->
                ?THROW_ERR(?ERROR_ITEM_USE_016)
        end,
    {ok, RecordPos} = mod_map_role:role_get_pos(mod_role_dict:get_map_pid(), RoleID),
    PosList = lib_tool:string_to_intlist(PosString, "|", ","),
    check_pos(PosList, RoleLevel, MapID, RecordPos),
    EventList = [ {Weight, EventID} || {EventID, Weight} <- lib_tool:string_to_intlist(EventString)],
    EventID = lib_tool:get_weight_output(EventList),
    State2 =
        case EventID =:= ?ITEM_EVENT_ID of
            true -> %% 马上获取奖励
                do_event_item_reward(EventID, RoleID, RoleList),
                State;
            _ ->
                [#c_hunt_treasure_event{time = Time}] = lib_config:find(cfg_hunt_treasure_event, EventID),
                RoleHuntTreasure2 = RoleHuntTreasure#r_role_hunt_treasure{
                    end_time = Now + Time,
                    event_id = EventID,
                    type_id = TypeID,
                    map_id = MapID,
                    int_pos = map_misc:pos_encode(RecordPos)
                },
                online(State#r_role{role_hunt_treasure = RoleHuntTreasure2})
        end,
    common_misc:unicast(RoleID, #m_hunt_treasure_action_toc{event_id = EventID}),
    BagDoings = [{create, ?ITEM_GAIN_HUNT_TREASURE_ITEM, [#p_goods{type_id = ?BAG_ITEM_HUNT_TREASURE_SCORE, num = AddScore}]}],
    mod_role_bag:do(BagDoings, State2).

check_pos([], _RoleLevel, _MapID, _RecordPos) ->
    ?THROW_ERR(?ERROR_ITEM_USE_017);
check_pos([{ConfigMx, _, ConfigMy, ConfigMapID, MinLevel, MaxLevel, _}|R], RoleLevel, MapID, RecordPos) ->
    case ConfigMapID =:= MapID andalso MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel of
        true ->
            ConfigPos = map_misc:get_pos_by_map_offset_pos(ConfigMapID, ConfigMx, ConfigMy),
            ?IF(map_misc:get_dis(ConfigPos, RecordPos) =< 1500, ok, check_pos(R, RoleLevel, MapID, RecordPos));
        _ ->
            check_pos(R, RoleLevel, MapID, RecordPos)
    end.

%% 地图进程也会掉这个方法
do_event_item_reward(EventID, CaptainRoleID, RoleList) ->
    [#c_hunt_treasure_event{
        captain_reward = CaptainRewardString,
        member_reward = MemberRewardString
    }] = lib_config:find(cfg_hunt_treasure_event, EventID),
    CaptainRewards = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- lib_tool:string_to_intlist(CaptainRewardString)],
    MemberRewards = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- lib_tool:string_to_intlist(MemberRewardString)],
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_TEMPLATE_HUNT_TREASURE,
        action = ?ITEM_GAIN_HUNT_TREASURE_SUCC},
    common_letter:send_letter(CaptainRoleID, LetterInfo#r_letter_info{goods_list = CaptainRewards}),
    ?IF(MemberRewards =/= [],
        [common_letter:send_letter(MemberRoleID, LetterInfo#r_letter_info{goods_list = CaptainRewards})|| MemberRoleID <- lists:delete(CaptainRoleID, RoleList)],
    ok).
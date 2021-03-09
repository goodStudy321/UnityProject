%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 三月 2019 14:59
%%%-------------------------------------------------------------------
-module(act_oss).
-author("WZP").

-include("act.hrl").
-include("rank.hrl").
-include("global.hrl").
-include("proto/mod_role_act_rank.hrl").
-include("proto/act_oss.hrl").

%%第二阶段开服活动


%% API
-export([
    init/1,
    refresh_rank/2,
    trans_to_p_act_rank/1
]).

-export([
    gm_refresh_rank/0
]).

init(ID) ->
    refresh_rank(ID, time_tool:now()).

refresh_rank(ID, Now) ->
    #r_act{end_date = EndDate} = world_act_server:get_act(ID),
    case time_tool:midnight(EndDate) - ?AN_HOUR >= Now of
        true ->
            refresh_rank_i(ID);
        _ ->
            ok
    end.

trans_to_p_act_rank(List) ->
    [trans_to_p_act_rank2(Rank) || Rank <- List].

trans_to_p_act_rank2(RoleRank) ->
    case RoleRank of
        #r_rank_handbook_power{rank = Rank, role_id = RoleID, power = Power} ->
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            #p_open_act_rank{type = ?RANK_HANDBOOK_POWER_I, rank = Rank, role_id = RoleID, role_name = RoleName, rank_value = Power};
        #r_rank_wing_power_i{rank = Rank, role_id = RoleID, power = Power} ->
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            #p_open_act_rank{type = ?RANK_WING_POWER_I, rank = Rank, role_id = RoleID, role_name = RoleName, rank_value = Power};
        #r_rank_magic_weapon_power_i{rank = Rank, role_id = RoleID, magic_weapon_power = Power} ->
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            #p_open_act_rank{type = ?RANK_MAGIC_WEAPON_POWER_I, rank = Rank, role_id = RoleID, role_name = RoleName, rank_value = Power}
    end.


refresh_rank_i(ID) ->
    RankID = case ID of
                 ?ACT_OSS_WING ->
                     ?RANK_WING_POWER_I;
                 ?ACT_OSS_MAGIC_WEAPON ->
                     ?RANK_MAGIC_WEAPON_POWER_I;
                 ?ACT_OSS_HANDBOOK ->
                     ?RANK_HANDBOOK_POWER_I
             end,
    RankList4 =
    lists:foldl(fun(RankID2, Acc) ->
        case RankID =/= RankID2 of
            true ->
                RankList2 = world_data:get_oss_rank(),
                RankList3 = [#p_open_act_rank{type = Type, rank = Rank, role_id = RoleID, role_name = RoleName, rank_value = Power} || #p_open_act_rank{type = Type, rank = Rank, role_id = RoleID, role_name = RoleName, rank_value = Power} <- RankList2, Type =:= RankID2],
                Acc ++ RankList3;
            _ ->
                RankList = rank_misc:get_rank(RankID2),
                RankList2 = trans_to_p_act_rank(RankList),
                common_broadcast:bc_record_to_world(#m_oss_rank_list_change_toc{type = RankID2, rank_list = RankList2}),
                Acc ++ RankList2
        end
    end, [], [?RANK_WING_POWER_I, ?RANK_MAGIC_WEAPON_POWER_I, ?RANK_HANDBOOK_POWER_I]),
    RankList5 = lists:flatten(RankList4),
    world_data:set_oss_rank(RankList5).



gm_refresh_rank() ->
    #r_act{status = Status1} = world_act_server:get_act(?ACT_OSS_WING),
    #r_act{status = Status2} = world_act_server:get_act(?ACT_OSS_MAGIC_WEAPON),
    #r_act{status = Status3} = world_act_server:get_act(?ACT_OSS_HANDBOOK),
    IDList =
    [begin
         ID
     end || {ID, Status} <- [{?ACT_OSS_WING, Status1}, {?ACT_OSS_MAGIC_WEAPON, Status2}, {?ACT_OSS_HANDBOOK, Status3}], Status =:= ?ACT_STATUS_OPEN],
    lists:foreach(fun(ID) ->
        refresh_rank(ID, time_tool:now())
    end, IDList).

%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     人物战力排行
%%% @end
%%% Created : 10. 十一月 2017 14:55
%%%-------------------------------------------------------------------
-module(rank_role_level).
-author("laijichang").
-include("global.hrl").
-include("rank.hrl").
-include("role.hrl").
-include("proto/mod_role_rank.hrl").

%% API
-export([
    init_rank/2,
    cmp_rank/2,
    rank/1,
    zero/1,
    trans_to_r_rank/1,
    trans_to_p_rank/1,
    trans_to_log/2
]).

init_rank(RankID, MaxNum) ->
    case ets:lookup(?DB_RANK_P, RankID) of
        [#r_rank{ranks = Ranks}] ->
            ok;
        _ ->
            Ranks = []
    end,
    Ranks2 = [{RoleID, RankInfo} || #r_rank_role_level{role_id = RoleID} = RankInfo <- Ranks],
    lib_minheap:new_heap(RankID, MaxNum, {?MODULE, cmp_rank}, Ranks2).

cmp_rank(RankInfo1, RankInfo2) ->
    #r_rank_role_level{level = Level1, update_time = UpdateTime1} = RankInfo1,
    #r_rank_role_level{level = Level2, update_time = UpdateTime2} = RankInfo2,
    rank_misc:cmp([{Level1, Level2}, {UpdateTime2, UpdateTime1}]).

rank(RankID) ->
    AllEs = lib_minheap:get_all_elements(RankID),
    SortAllEs = lists:sort(fun cmp_rank/2, AllEs),
    SortAllEs2 = lists:reverse(SortAllEs),
    {SortAllEs3, _} = lists:foldl(
        fun(E, {Acc, Rank}) ->
            E1 = E#r_rank_role_level{rank = Rank},
            {[E1|Acc], Rank + 1}
        end, {[], 1}, SortAllEs2),
    db:insert(?DB_RANK_P, #r_rank{rank_id = RankID, ranks = SortAllEs3}),
    recalc_world_level(RankID).

zero(RankID) ->
    recalc_world_level(RankID).

%% 重算世界等级
recalc_world_level(RankID) ->
    %% 取前5名
    RankData = rank_misc:get_rank(RankID),
    RankData2 = lists:keysort(#r_rank_role_level.rank, RankData),
    WorldLevels = [ RoleLevel || #r_rank_role_level{level = RoleLevel} <- lists:sublist(RankData2, 5)],
    case WorldLevels =/= [] of
        true ->
            Average = lists:sum(WorldLevels) div erlang:length(WorldLevels),
            WorldLv = world_data:get_world_level(),
            case Average =/= WorldLv andalso (not common_config:is_debug()) of
                true ->
                    world_data:set_world_level(Average),
                    ?IF(Average >= ?WORLD_LEVEL_OPEN_LV, common_broadcast:bc_role_info_to_world({mod, mod_role_world_level, update_world_level}), ok),
                    ?IF(Average >= common_misc:get_global_int(?GLOBAL_CROSS_ACTIVITY_LEVEL), cross_activity_server:send_game_world_level(Average), ok);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

trans_to_r_rank(List) ->
    [{RoleID, #r_rank_role_level{role_id = RoleID, level = Level, update_time = Time}} || {RoleID, Level, Time} <- List].

trans_to_p_rank(List) ->
    [trans_to_p_rank2(Rank) || Rank <- List].

trans_to_p_rank2(RoleRank) ->
    #r_rank_role_level{rank = Rank, role_id = RoleID, level = Level} = RoleRank,
    #r_role_attr{role_name = RoleName, category = Category} = common_role_data:get_role_attr(RoleID),
    #p_rank{
        rank = Rank,
        role_id = RoleID,
        role_name = RoleName,
        role_level = Level,
        vip_level = common_role_data:get_role_vip_level(RoleID),
        confine = common_role_data:get_role_confine(RoleID),
        category = Category,
        relive_level = common_role_data:get_role_relive_level(RoleID),
        kv_list = [#p_dkv{id = ?KEY_ROLE_LEVEL, val = Level}]
    }.


trans_to_log([], Logs) ->
    Logs;
trans_to_log([E|SortAllEs], Logs) ->
    #r_rank_role_level{rank = Rank, role_id = RoleID, level = RoleLevel} = E,
    #r_role_attr{role_name = RoleName, category = Category, family_id = FamilyID, family_name = FamilyName} = common_role_data:get_role_attr(RoleID),
    Log = #log_rank{role_id = RoleID, role_name = unicode:characters_to_binary(RoleName), category = Category, role_vip_level = common_role_data:get_role_vip_level(RoleID), rank_type = ?RANK_ROLE_LEVEL, rank_value = RoleLevel,
                    role_rank = Rank, family_id = FamilyID, family_name = unicode:characters_to_binary(FamilyName)},
    trans_to_log(SortAllEs, [Log|Logs]).
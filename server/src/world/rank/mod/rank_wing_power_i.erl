%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%         开服二阶活动所用排行
%%% @end
%%% Created : 27. 三月 2019 11:28
%%%-------------------------------------------------------------------
-module(rank_wing_power_i).
-include("global.hrl").
-include("rank.hrl").
-include("act.hrl").
-include("proto/mod_role_rank.hrl").

%% API
-export([
    init_rank/2,
    cmp_rank/2,
    rank/1,
    trans_to_r_rank/1
]).

init_rank(RankID, MaxNum) ->
    case ets:lookup(?DB_RANK_P, RankID) of
        [#r_rank{ranks = Ranks}] ->
            ok;
        _ ->
            Ranks = []
    end,
    Ranks2 = [{RoleID, RankInfo} || #r_rank_wing_power_i{role_id = RoleID} = RankInfo <- Ranks],
    lib_minheap:new_heap(RankID, MaxNum, {?MODULE, cmp_rank}, Ranks2).

cmp_rank(RankInfo1, RankInfo2) ->
    #r_rank_wing_power_i{power = Level1, update_time = UpdateTime1} = RankInfo1,
    #r_rank_wing_power_i{power = Level2, update_time = UpdateTime2} = RankInfo2,
    rank_misc:cmp([{Level1, Level2}, {UpdateTime2, UpdateTime1}]).

rank(RankID) ->
    case world_act_server:is_act_open(?ACT_OSS_WING) of
        true ->
            AllEs = lib_minheap:get_all_elements(RankID),
            SortAllEs = lists:sort(fun cmp_rank/2, AllEs),
            {SortAllEs1, _} = lists:foldl(
                fun(E, {Acc, Rank}) ->
                    E1 = E#r_rank_wing_power_i{rank = Rank},
                    {[E1|Acc], Rank + 1}
                end, {[], 1}, lists:reverse(SortAllEs)),
            db:insert(?DB_RANK_P, #r_rank{rank_id = RankID, ranks = SortAllEs1});
        _ ->
            ok
    end.

trans_to_r_rank(List) ->
    [
        {RoleID, #r_rank_wing_power_i{
            role_id = RoleID,
            power = Power,
            update_time = Time}} || {RoleID, Power, Time} <- List].
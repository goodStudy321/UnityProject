%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     法宝等级排行
%%% @end
%%% Created : 10. 十一月 2017 14:55
%%%-------------------------------------------------------------------
-module(rank_magic_weapon_power).
-author("laijichang").
-include("global.hrl").
-include("rank.hrl").
-include("proto/mod_role_rank.hrl").

%% API
-export([
    init_rank/2,
    cmp_rank/2,
    rank/1,
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
    Ranks2 = [ {RoleID, RankInfo}|| #r_rank_magic_weapon_power{role_id = RoleID} = RankInfo <- Ranks],
    lib_minheap:new_heap(RankID, MaxNum, {?MODULE, cmp_rank}, Ranks2).

cmp_rank(RankInfo1, RankInfo2) ->
    #r_rank_magic_weapon_power{magic_weapon_power = Power1, update_time = UpdateTime1} = RankInfo1,
    #r_rank_magic_weapon_power{magic_weapon_power = Power2, update_time = UpdateTime2} = RankInfo2,
    rank_misc:cmp([{Power1, Power2}, {UpdateTime2, UpdateTime1}]).

rank(RankID) ->
    AllEs = lib_minheap:get_all_elements(RankID),
    SortAllEs = lists:sort(fun cmp_rank/2, AllEs),
    {SortAllEs1, _} = lists:foldl(
        fun(E, {Acc, Rank}) ->
            E1 = E#r_rank_magic_weapon_power{rank = Rank},
            {[E1|Acc], Rank + 1}
        end, {[], 1}, lists:reverse(SortAllEs)),
    db:insert(?DB_RANK_P, #r_rank{rank_id = RankID, ranks = SortAllEs1}).

trans_to_r_rank(List) ->
    [ {RoleID, #r_rank_magic_weapon_power{
        role_id = RoleID,
        magic_weapon_level = Level,
        magic_weapon_power = Power,
        update_time = Time}}|| {RoleID, Power, Level, Time} <- List].

trans_to_p_rank(List) ->
    [ trans_to_p_rank2(Rank) || Rank <- List].

trans_to_p_rank2(RoleRank) ->
    #r_rank_magic_weapon_power{rank = Rank, role_id = RoleID, magic_weapon_level = MagicWeaponLevel, magic_weapon_power = Power} = RoleRank,
    #r_role_attr{role_name = RoleName, category = Category, level = RoleLevel} = common_role_data:get_role_attr(RoleID),
    #p_rank{
        rank = Rank,
        role_id = RoleID,
        role_name = RoleName,
        role_level = RoleLevel,
        vip_level = common_role_data:get_role_vip_level(RoleID),
        category = Category,
        confine = common_role_data:get_role_confine(RoleID),
        relive_level = common_role_data:get_role_relive_level(RoleID),
        kv_list = [
            #p_dkv{id = ?KEY_MAGIC_WEAPON_LEVEL, val = MagicWeaponLevel},
            #p_dkv{id = ?KEY_POWER, val = Power}
        ]}.

trans_to_log([], Logs) ->
    Logs;
trans_to_log([E | SortAllEs], Logs) ->
    #r_rank_magic_weapon_power{rank = Rank, role_id = RoleID, magic_weapon_level = MagicWeaponLevel, magic_weapon_power = MagicWeaponPower} = E,
    #r_role_attr{role_name = RoleName, category = Category, family_id = FamilyID, family_name = FamilyName} = common_role_data:get_role_attr(RoleID),
    Log = #log_rank{role_id = RoleID, role_name = unicode:characters_to_binary(RoleName), category = Category, role_vip_level = common_role_data:get_role_vip_level(RoleID), rank_type = ?RANK_MAGIC_WEAPON_POWER,
        rank_value = MagicWeaponPower, rank_value2 = MagicWeaponLevel,
        role_rank = Rank, family_id = FamilyID, family_name =  unicode:characters_to_binary(FamilyName) },
    trans_to_log(SortAllEs, [Log | Logs]).
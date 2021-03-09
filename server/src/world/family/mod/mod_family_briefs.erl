%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 十月 2017 9:50
%%%-------------------------------------------------------------------
-module(mod_family_briefs).
-author("laijichang").
-include("global.hrl").
-include("family.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    loop_10min/0
]).

-export([
    regen_family_briefs/0,
    family_briefs_sort/1,
    update_family_briefs/2,
    transform_family_fields/1]).

loop_10min() ->
    regen_family_briefs().

update_family_briefs(FamilyID, Values) ->
    case mod_family_data:get_family_brief(FamilyID) of
        #p_family_brief{} = FamilyBrief ->
            NewFamilyBrief = set_elements(FamilyBrief, Values),
            mod_family_data:set_family_brief(NewFamilyBrief);
        _ ->
            ignore
    end.

set_elements(Tuple, []) ->
    Tuple;
set_elements(Tuple, [{N, Value} | N_Values]) ->
    set_elements(erlang:setelement(N, Tuple, Value), N_Values).

%% 生成推荐仙盟列表
regen_family_briefs() ->
    FamilyBriefs = [ transform_family_fields(FamilyData) || FamilyData <- mod_family_data:get_all_family()],
    FamilyBriefs2 = family_briefs_sort(FamilyBriefs),
    {FamilyBriefs3, _} = lists:foldl(
        fun(FamilyBrief, {Acc1, Acc2}) ->
            #p_family_brief{family_id = FamilyID, rank = OldRank} = FamilyBrief,
            NewRank = Acc2 + 1,
            case OldRank =/= NewRank of
                true ->
                    #p_family{rank = OldRank} = FamilyData = mod_family_data:get_family(FamilyID),
                    mod_family_data:set_family(FamilyData#p_family{rank = NewRank}),
                    ChangeList = [#p_kv{id = ?FAMILY_UPDATE_RANK, val = NewRank}],
                    common_broadcast:bc_record_to_family(FamilyID, #m_family_info_update_toc{kv_list = ChangeList});
                _ ->
                    ok
            end,
            {[FamilyBrief#p_family_brief{rank = NewRank}|Acc1], NewRank}
        end, {[], 0}, FamilyBriefs2),
    mod_family_data:del_family_brief(),
    mod_family_data:set_family_brief(lists:reverse(FamilyBriefs3)).

%% 先比战力，再比大小
family_briefs_sort(FamilyBriefs) ->
    lists:sort(
        fun(FamilyB1, FamilyB2) ->
            #p_family_brief{level = Level1, power = Power1} = FamilyB1,
            #p_family_brief{level = Level2, power = Power2} = FamilyB2,
            if
                Power1 > Power2 ->
                    true;
                Power1 < Power2 ->
                    false;
                true ->
                    Level1 >= Level2
            end
        end, FamilyBriefs).

transform_family_fields(FamilyInfo) ->
    #p_family{
        family_id = FamilyID,
        family_name = FamilyName,
        level = Level,
        members = Members,
        rank = Rank} = FamilyInfo,
    {OwnerRoleID, OwnerName, Num, AllPower} =
    lists:foldl(
        fun(Member, {Acc1, Acc2, Acc3, Acc4}) ->
            #p_family_member{role_id = RoleID, role_name = RoleName, title = Title, power = Power} = Member,
            {NewAcc1, NewAcc2} = ?IF(Title =:= ?TITLE_OWNER, {RoleID, RoleName}, {Acc1, Acc2}),
            {NewAcc1, NewAcc2, Acc3 + 1, Acc4 + Power}
        end, {0, "", 0, 0}, Members),
    #p_family_brief{
        family_id = FamilyID,
        family_name = FamilyName,
        level = Level,
        num = Num,
        owner_id = OwnerRoleID,
        owner_name = OwnerName,
        power = AllPower,
        rank = Rank}.
%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 十月 2017 9:50
%%%-------------------------------------------------------------------
-module(mod_family_role).
-author("laijichang").
-include("global.hrl").
-include("family.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    update_role_info/3
]).

-export([
    handle/1
]).

update_role_info(RoleID, FamilyID, Info) ->
    family_misc:info_family({mod, ?MODULE, {update_role_info, RoleID, FamilyID, Info}}).


handle({update_role_info, RoleID, FamilyID, Info}) ->
    do_update_role_info(RoleID, FamilyID, Info).

do_update_role_info(RoleID, FamilyID, Info) ->
    %% 更新自己仙盟的数据
    #r_role_family{family_id = FamilyID, apply_list = ApplyList} = mod_family_data:get_role_family(RoleID),
    {RoleName, Level, Category, Power, IsOnline, LastOfflineTime} = Info,
    case ?HAS_FAMILY(FamilyID) of
        true ->
            #p_family{members = Members} = FamilyData = mod_family_data:get_family(FamilyID),
            #p_family_member{title = Title} = Member = lists:keyfind(RoleID, #p_family_member.role_id, Members),
            Member2 = Member#p_family_member{
                role_name = RoleName,
                role_level = Level,
                category = Category,
                power = Power,
                is_online = IsOnline,
                last_offline_time = LastOfflineTime},
            Members2 = lists:keystore(RoleID, #p_family_member.role_id, Members, Member2),
            FamilyData2 = FamilyData#p_family{members = Members2},
            mod_family_data:set_family(FamilyData2),
            ?IF(Title =:= ?TITLE_OWNER, mod_family_briefs:update_family_briefs(FamilyID, [{#p_family_brief.owner_name, RoleName}]), ok),
            DataRecord = #m_family_member_update_toc{member = Member2},
            common_broadcast:bc_record_to_family(FamilyID, DataRecord);
        _ ->
            ok
    end,
    %% 更新申请列表里的仙盟
    [begin
         case mod_family_data:get_family(ApplyFamilyID) of
             #p_family{apply_list = FApplyList} = ApplyFamilyData ->
                 Apply = lists:keyfind(RoleID, #p_family_apply.role_id, FApplyList),
                 Apply2 = Apply#p_family_apply{
                     role_name = RoleName,
                     role_level = Level,
                     category = Category,
                     power = Power},
                 FApplyList2 = lists:keystore(RoleID, #p_family_apply.role_id, FApplyList, Apply2),
                 ApplyFamilyData2 = ApplyFamilyData#p_family{apply_list = FApplyList2},
                 mod_family_data:set_family(ApplyFamilyData2),
                 ApplyDataRecord = #m_family_apply_update_toc{apply = Apply2},
                 common_broadcast:bc_record_to_family(FamilyID, ApplyDataRecord);
             _ ->
                 ok
         end
     end || ApplyFamilyID <- ApplyList].



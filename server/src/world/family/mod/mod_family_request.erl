%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十月 2017 21:16
%%%-------------------------------------------------------------------
-module(mod_family_request).
-author("laijichang").
-include("global.hrl").
-include("family.hrl").
-include("activity.hrl").
-include("proto/mod_role_family.hrl").

%% API
%% 角色进程调用
-export([
    create_family/2,
    invite_join_family/3,
    apply_family/2,
    apply_reply/4,
    family_admin/4,
    family_kick/3,
    leave_family/2
]).

-export([
    del_family/1,
    log_family_member/4
]).

-export([
    handle/1
]).

create_family(RoleID, FamilyName) ->
    family_misc:call_family({mod, ?MODULE, {create_family, RoleID, FamilyName}}).
invite_join_family(RoleID, FromRoleID, FamilyID) ->
    family_misc:info_family({mod, ?MODULE, {invite_join_family, RoleID, FromRoleID, FamilyID}}).
apply_family(RoleID, FamilyID) ->
    family_misc:info_family({mod, ?MODULE, {apply_family, RoleID, FamilyID}}).
apply_reply(RoleID, FamilyID, OpType, RoleIDs) ->
    family_misc:info_family({mod, ?MODULE, {apply_reply, RoleID, FamilyID, OpType, RoleIDs}}).

family_admin(RoleID, FamilyID, DestRoleID, NewTitle) ->
    family_misc:info_family({mod, ?MODULE, {family_admin, RoleID, FamilyID, DestRoleID, NewTitle}}).
family_kick(RoleID, FamilyID, DestRoleID) ->
    family_misc:info_family({mod, ?MODULE, {family_kick, RoleID, FamilyID, DestRoleID}}).
leave_family(RoleID, MapID) ->
    family_misc:info_family({mod, ?MODULE, {leave_family, RoleID, MapID}}).

handle({create_family, RoleID, FamilyName}) ->
    do_create_family(RoleID, FamilyName);
handle({invite_join_family, RoleID, FromRoleID, FamilyID}) ->
    do_invite_join_family(RoleID, FromRoleID, FamilyID);
handle({apply_family, RoleID, FamilyID}) ->
    do_apply_family(RoleID, FamilyID);
handle({apply_reply, RoleID, FamilyID, OpType, RoleIDs}) ->
    do_apply_reply(RoleID, FamilyID, OpType, RoleIDs);
handle({family_admin, RoleID, FamilyID, DestRoleID, NewTitle}) ->
    do_family_admin(RoleID, FamilyID, DestRoleID, NewTitle);
handle({family_kick, RoleID, FamilyID, DestRoleID}) ->
    do_family_kick(RoleID, FamilyID, DestRoleID);
handle({leave_family, RoleID, MapID}) ->
    do_family_leave(RoleID, MapID);
handle(Info) ->
    ?ERROR_MSG("unkonw info :~w", [Info]).

%% 创建帮派
do_create_family(RoleID, FamilyName) ->
    case catch check_can_create(RoleID, FamilyName) of
        ok ->
            FamilyID = world_data:update_family_id(),
            FamilyData = #p_family{
                family_id = FamilyID,
                family_name = FamilyName,
                level = 1,
                max_cv = [#p_kv{id = 1, val = 0}, #p_kv{id = 2, val = 0}, #p_kv{id = 3, val = 0}],
                packet_id = 1,
                red_packet = [],
                depot = [#p_goods{id = 1, type_id = ?DEPOT_FIRST_GRID}]
            },
            mod_family_data:set_family_box(#r_family_box{family_id = FamilyID}),
            do_role_join_family(RoleID, ?TITLE_OWNER, FamilyData),
            mod_family_data:set_family_name(#r_family_name{family_name = FamilyName, family_id = FamilyID}),
            common_misc:unicast(RoleID, #m_family_create_toc{family_info = FamilyData}),
            mod_family_briefs:regen_family_briefs(),
            family_misc:log_family_status(FamilyData),
            log_family_member(FamilyID, RoleID, 0, ?LOG_FAMILY_MEMBER_CREATE),
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_create(RoleID, FamilyName) ->
    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
    ?IF(?HAS_FAMILY(FamilyID), ?THROW_ERR(?ERROR_FAMILY_APPLY_001), ok),
    case mod_family_data:get_family_name(FamilyName) of
        [#r_family_name{}] ->
            ?THROW_ERR(?ERROR_FAMILY_CREATE_002);
        _ -> ok
    end,
    ok.

%% 玩家同意邀请进入帮派
do_invite_join_family(RoleID, FromRoleID, FamilyID) ->
    case catch check_can_invite_join(RoleID, FamilyID) of
        {ok, FamilyData} ->
            DataRecord = #m_family_invite_reply_toc{
                op_type = ?INVITE_REPLY_ACCEPT,
                reply_role_id = RoleID,
                reply_role_name = common_role_data:get_role_name(RoleID)
            },
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(FromRoleID, DataRecord),
            do_role_join_family(RoleID, ?TITLE_MEMBER, FamilyData),
            log_family_member(FamilyID, RoleID, FromRoleID, ?LOG_FAMILY_MEMBER_JOIN);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_invite_reply_toc{err_code = ErrCode})
    end.

check_can_invite_join(RoleID, FamilyID) ->
    family_misc:check_join(),
    #r_role_family{family_id = MyFamilyID} = mod_family_data:get_role_family(RoleID),
    ?IF(?HAS_FAMILY(MyFamilyID), ?THROW_ERR(?ERROR_FAMILY_INVITE_REPLY_001), ok),
    #p_family{level = Level, members = Members} = FamilyData = mod_family_data:get_family(FamilyID),
    MaxNum = family_misc:get_family_max_num(Level),
    ?IF(erlang:length(Members) < MaxNum, ok, ?THROW_ERR(?ERROR_FAMILY_INVITE_REPLY_002)),
    {ok, FamilyData}.

%% 申请加入帮派
do_apply_family(RoleID, FamilyID) ->
    case catch check_can_apply(RoleID, FamilyID) of
        {direct_join, FamilyData} ->
            Title = ?IF(FamilyData#p_family.members =:= [], ?TITLE_OWNER, ?TITLE_MEMBER),
            do_role_join_family(RoleID, Title, FamilyData),
            log_family_member(FamilyID, RoleID, 0, ?LOG_FAMILY_MEMBER_JOIN),
            common_misc:unicast(RoleID, #m_family_apply_toc{});
        {ok, FamilyData, RoleFamily, FamilyApply} ->
            mod_family_data:set_family(FamilyData),
            mod_family_data:set_role_family(RoleFamily),
            common_broadcast:bc_record_to_family(FamilyID, #m_family_apply_update_toc{apply = FamilyApply}),
            common_misc:unicast(RoleID, #m_family_apply_toc{});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_apply_toc{err_code = ErrCode})
    end.

check_can_apply(RoleID, FamilyID) ->
    family_misc:check_join(),
    #r_role_family{family_id = MyFamilyID, apply_list = RoleApplyList} = RoleFamily = mod_family_data:get_role_family(RoleID),
    ?IF(?HAS_FAMILY(MyFamilyID), ?THROW_ERR(?ERROR_FAMILY_APPLY_001), ok),
    ?IF(lists:member(FamilyID, RoleApplyList), ?THROW_ERR(?ERROR_FAMILY_APPLY_002), ok),
    #p_family{
        level = FamilyLevel,
        members = Members,
        apply_list = FamilyApplyList,
        is_direct_join = IsDirect} = FamilyData = mod_family_data:get_family(FamilyID),
    MaxNum = family_misc:get_family_max_num(FamilyLevel),
    ?IF(erlang:length(Members) < MaxNum, ok, ?THROW_ERR(?ERROR_FAMILY_INVITE_REPLY_002)),
    case IsDirect of
        true ->
            {direct_join, FamilyData};
        _ ->
            ?IF(erlang:length(RoleApplyList) < ?ROLE_MAX_APPLY_NUM, ok, ?THROW_ERR(?ERROR_FAMILY_APPLY_004)),
            ?IF(erlang:length(FamilyApplyList) < ?FAMILY_MAX_APPLY_NUM, ok, ?THROW_ERR(?ERROR_FAMILY_APPLY_005)),
            #r_role_attr{role_name = RoleName, level = RoleLevel, category = Category, power = Power, sex = Sex} = common_role_data:get_role_attr(RoleID),
            FamilyApply = #p_family_apply{role_id = RoleID, role_name = RoleName, role_level = RoleLevel, category = Category, power = Power, sex = Sex},
            FamilyApplyList2 = [FamilyApply|FamilyApplyList],
            FamilyData2 = FamilyData#p_family{apply_list = FamilyApplyList2},
            RoleFamily2 = RoleFamily#r_role_family{apply_list = [FamilyID|RoleApplyList]},
            {ok, FamilyData2, RoleFamily2, FamilyApply}
    end.

%% 申请的回复，同意or拒绝
do_apply_reply(RoleID, FamilyID, OpType, RoleIDs) ->
    case catch check_apply_reply(FamilyID, OpType, RoleIDs) of
        {ok, ?APPLY_REPLY_ACCEPT, RoleIDs2, FamilyData} ->
            mod_family_data:set_family(FamilyData),
            [begin
                 do_role_join_family(DestRoleID, ?TITLE_MEMBER, FamilyID),
                 log_family_member(FamilyID, RoleID, DestRoleID, ?LOG_FAMILY_MEMBER_JOIN)
             end || DestRoleID <- RoleIDs2],
            common_broadcast:bc_record_to_family(FamilyID, #m_family_apply_update_toc{del_apply_ids = RoleIDs}),
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            DataRecord = #m_family_apply_reply_toc{op_type = OpType, reply_role_id = RoleID, reply_role_name = RoleName},
            common_broadcast:bc_record_to_roles([RoleID|RoleIDs], DataRecord);
        {ok, ?APPLY_REPLY_REFUSE, RefuseRoleIDs, FamilyData} ->
            mod_family_data:set_family(FamilyData),
            [begin
                 #r_role_family{apply_list = OldApplyList} = RefuseFamily = mod_family_data:get_role_family(RefuseRoleID),
                 mod_family_data:set_role_family(RefuseFamily#r_role_family{apply_list = lists:delete(FamilyID, OldApplyList)})
             end || RefuseRoleID <- RefuseRoleIDs],
            common_broadcast:bc_record_to_family(FamilyID, #m_family_apply_update_toc{del_apply_ids = RoleIDs}),
            #r_role_attr{role_name = RoleName} = common_role_data:get_role_attr(RoleID),
            DataRecord = #m_family_apply_reply_toc{op_type = OpType, reply_role_id = RoleID, reply_role_name = RoleName},
            common_broadcast:bc_record_to_roles([RoleID|RoleIDs], DataRecord);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_apply_reply_toc{err_code = ErrCode})
    end.

check_apply_reply(FamilyID, OpType, RoleIDs) ->
    #p_family{members = Members, level = Level, apply_list = ApplyList} = FamilyData = mod_family_data:get_family(FamilyID),
    {ok, ApplyList2, RoleIDs2} = check_apply_reply2(RoleIDs, ApplyList, []),
    case OpType of
        ?APPLY_REPLY_ACCEPT ->
            family_misc:check_join(),
            MaxNum = family_misc:get_family_max_num(Level),
            ?IF(erlang:length(Members) + erlang:length(RoleIDs2) =< MaxNum, ok, ?THROW_ERR(?ERROR_FAMILY_APPLY_REPLY_005)),
            {ok, ?APPLY_REPLY_ACCEPT, RoleIDs2, FamilyData};
        ?APPLY_REPLY_REFUSE ->
            FamilyData2 = FamilyData#p_family{apply_list = ApplyList2},
            {ok, ?APPLY_REPLY_REFUSE, RoleIDs, FamilyData2}
    end.

check_apply_reply2([], ApplyList, RoleIDAcc) ->
    {ok, ApplyList, RoleIDAcc};
check_apply_reply2([RoleID|R], ApplyList, RoleIDAcc) ->
    case lists:keytake(RoleID, #p_family_apply.role_id, ApplyList) of
        {value, #p_family_apply{}, ApplyList2} ->
            ok;
        _ ->
            ApplyList2 = ?THROW_ERR(?ERROR_FAMILY_APPLY_REPLY_003)
    end,
    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
    RoleIDAcc2 = ?IF(?HAS_FAMILY(FamilyID), RoleIDAcc, [RoleID|RoleIDAcc]),
    check_apply_reply2(R, ApplyList2, RoleIDAcc2).

%% 调整职位
do_family_admin(RoleID, FamilyID, DestRoleID, NewTitle) ->
    case catch check_can_admin(RoleID, FamilyID, DestRoleID, NewTitle) of
        {ok, ChangeList, FamilyData, OldViceNum, NewViceNum, LetterList, Logs} ->
            mod_family_data:set_family(FamilyData),
            [begin
                 DataRecord = #m_family_admin_toc{role_id = ChangeRoleID, new_title = ChangeTitle},
                 common_broadcast:bc_record_to_family(FamilyID, DataRecord),
                 role_misc:info_role(ChangeRoleID, {mod, mod_role_family, {title_change, ChangeTitle}})
             end || {ChangeRoleID, ChangeTitle} <- ChangeList],
            [common_letter:send_letter(DestRoleID, LetterInfo) || LetterInfo <- LetterList],
            background_misc:log(Logs),
            ?IF(NewViceNum > OldViceNum, act_family:family_vice_change(FamilyID, family_misc:get_family_owner_id(FamilyData), NewViceNum), ok);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_admin_toc{err_code = ErrCode})
    end.

check_can_admin(RoleID, FamilyID, DestRoleID, NewTitle) ->
    #p_family{members = Members} = FamilyData = mod_family_data:get_family(FamilyID),
    case lists:keyfind(DestRoleID, #p_family_member.role_id, Members) of
        #p_family_member{title = Title} = Member ->
            ?IF(Title =/= NewTitle andalso NewTitle >= ?TITLE_MEMBER andalso NewTitle =< ?TITLE_POPULAR, ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_003)),
            Member2 = Member#p_family_member{title = NewTitle},
            Members2 = lists:keystore(DestRoleID, #p_family_member.role_id, Members, Member2),
            case NewTitle =:= ?TITLE_OWNER of
                true -> %% 移交帮主时，自己的职位会变成普通成员
                    Owner = lists:keyfind(RoleID, #p_family_member.role_id, Members),
                    Members3 = lists:keystore(RoleID, #p_family_member.role_id, Members2, Owner#p_family_member{title = ?TITLE_MEMBER}),
                    Logs = [#log_family_member{family_id = FamilyID, role_id1 = RoleID, role_id2 = DestRoleID, action_type = ?LOG_FAMILY_ADMIN},
                            #log_family_member{family_id = FamilyID, role_id1 = RoleID, role_id2 = RoleID, action_type = ?LOG_FAMILY_ADMIN}],
                    ChangeList = [{RoleID, ?TITLE_MEMBER}, {DestRoleID, NewTitle}];
                _ ->
                    check_can_admin2(NewTitle, Members),
                    Members3 = Members2,
                    Logs = [#log_family_member{family_id = FamilyID, role_id1 = RoleID, role_id2 = DestRoleID, action_type = ?LOG_FAMILY_ADMIN}],
                    ChangeList = [{DestRoleID, NewTitle}]
            end,
            FamilyData2 = FamilyData#p_family{members = Members3},
            OldViceNum = family_misc:get_family_vice_num(FamilyData),
            NewViceNum = family_misc:get_family_vice_num(FamilyData2),
            LetterList1 = ?IF(                                      Title > ?TITLE_MEMBER, [#r_letter_info{
                text_string = [FamilyData#p_family.family_name, family_misc:get_title_name(Title)],
                template_id = ?LETTER_TEMPLATE_FAMILY_TITLE_DOWN}], []),
            LetterList2 =
            if
                NewTitle =:= ?TITLE_POPULAR ->
                    LetterList1 ++ [#r_letter_info{template_id = ?LETTER_TEMPLATE_FAMILY_POPULAR}];
                NewTitle > ?TITLE_MEMBER ->
                    LetterList1 ++ [#r_letter_info{
                        text_string = [FamilyData#p_family.family_name, family_misc:get_title_name(NewTitle)],
                        template_id = ?LETTER_TEMPLATE_FAMILY_TITLE_UP}];
                true ->
                    LetterList1
            end,
            {ok, ChangeList, FamilyData2, OldViceNum, NewViceNum, LetterList2, Logs};
        _ ->
            ?THROW_ERR(?ERROR_FAMILY_ADMIN_004)
    end.

check_can_admin2(NewTitle, Members) ->
    if
        NewTitle =:= ?TITLE_VICE_OWNER ->
            Num = erlang:length([Member || #p_family_member{title = ?TITLE_VICE_OWNER} = Member <- Members]),
            ?IF(Num < ?MAX_VICE_OWNER_NUM, ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_005));
        NewTitle =:= ?TITLE_ELDER ->
            Num = erlang:length([Member || #p_family_member{title = ?TITLE_ELDER} = Member <- Members]),
            ?IF(Num < ?MAX_ELDER_NUM, ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_005));
        NewTitle =:= ?TITLE_POPULAR ->
            Num = erlang:length([Member || #p_family_member{title = ?TITLE_POPULAR} = Member <- Members]),
            ?IF(Num < ?MAX_POPULAR_NUM, ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_005));
        true ->
            ok
    end.

%% 开除职员
do_family_kick(RoleID, FamilyID, DestRoleID) ->
    case catch check_can_kick(FamilyID, DestRoleID) of
        {ok, FamilyData} ->
            do_role_leave_family(DestRoleID, FamilyData, ?FAMILY_LEAVE_STATUS_4),
            case lists:keyfind(?TITLE_OWNER, #p_family_member.title, FamilyData#p_family.members) of
                #p_family_member{role_name = Owner} ->
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_TEMPLATE_FAMILY_KICK,
                        text_string = [FamilyData#p_family.family_name, Owner]},
                    common_letter:send_letter(DestRoleID, LetterInfo);
                _ ->
                    undefined
            end,
            log_family_member(FamilyID, RoleID, DestRoleID, ?LOG_FAMILY_MEMBER_KICK);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_kick_toc{err_code = ErrCode})
    end.

check_can_kick(FamilyID, DestRoleID) ->
    family_misc:check_kick(),
    #p_family{members = Members} = FamilyData = mod_family_data:get_family(FamilyID),
    ?IF(lists:keymember(DestRoleID, #p_family_member.role_id, Members), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_003)),
    {ok, FamilyData}.


do_family_leave(RoleID, MapID) ->
    case catch check_family_leave(RoleID, MapID) of
        {owner_leave, FamilyID, FamilyData} -> %% 帮主离开帮会转让,转让无果解散
            case lists:keydelete(RoleID, #p_family_member.role_id, FamilyData#p_family.members) of
                [] ->
                    RoleFamily = mod_family_data:get_role_family(RoleID),
                    RoleFamily2 = RoleFamily#r_role_family{family_id = 0, family_name = ""},
                    mod_family_data:set_role_family(RoleFamily2),
                    hook_family:role_leave_family(RoleID, FamilyID, ?FAMILY_LEAVE_STATUS_2),
                    log_family_member(FamilyID, RoleID, RoleID, ?LOG_FAMILY_OWNER_DISMISS),
                    del_family(FamilyID),
                    common_misc:unicast(RoleID, #m_family_leave_toc{}),
                    common_broadcast:bc_record_to_roles([RoleID], #m_family_info_toc{}),
                    family_misc:log_family_dismiss(FamilyData#p_family{members = []}, RoleID);
                OtherMembers ->
                    RoleFamily = mod_family_data:get_role_family(RoleID),
                    RoleFamily2 = RoleFamily#r_role_family{family_id = 0, family_name = ""},
                    mod_family_data:set_role_family(RoleFamily2),
                    hook_family:role_leave_family(RoleID, FamilyID, ?FAMILY_LEAVE_STATUS_2),
                    log_family_member(FamilyID, RoleID, RoleID, ?LOG_FAMILY_OWNER_QUIT),
                    {ok, NewOwner, OtherMembers2} = family_misc:get_next_owner(OtherMembers),
                    NewOwner2 = NewOwner#p_family_member{title = ?TITLE_OWNER},
                    FamilyData2 = FamilyData#p_family{members = [NewOwner2|OtherMembers2]},
                    common_broadcast:send_family_common_notice(FamilyID, ?NOTICE_FAMILY_TRANSFERS,
                                                               [lib_tool:to_list(RoleID), common_role_data:get_role_name(RoleID),
                                                                lib_tool:to_list(NewOwner#p_family_member.role_id), common_role_data:get_role_name(NewOwner#p_family_member.role_id)]),

                    family_misc:log_family_status(FamilyData2),
                    mod_family_data:set_family(FamilyData2),
                    do_role_leave_family_box(FamilyID, RoleID),
                    common_broadcast:bc_record_to_family(FamilyID, #m_family_member_update_toc{member = NewOwner2, del_member_id = RoleID}),
                    common_broadcast:bc_record_to_family(FamilyID, #m_family_admin_toc{role_id = NewOwner#p_family_member.role_id, new_title = ?TITLE_OWNER})
            end,
            del_activity(FamilyID, RoleID);
        {member_leave, RoleID, FamilyData} ->
            do_role_leave_family(RoleID, FamilyData, ?FAMILY_LEAVE_STATUS_3),
            log_family_member(FamilyData#p_family.family_id, RoleID, 0, ?LOG_FAMILY_MEMBER_QUIT),
            del_activity(FamilyData#p_family.family_id, RoleID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_leave_toc{err_code = ErrCode})
    end.

%% 仙盟移除时涉及的相关操作
del_family(FamilyID) ->
    #p_family{family_name = FamilyName} = mod_family_data:get_family(FamilyID),
    mod_family_data:del_family(FamilyID),
    mod_family_data:del_family_name(FamilyName),
    mod_family_data:del_family_box(FamilyID),
    world_chat_history_server:del_history(FamilyID, ?CHAT_CHANNEL_FAMILY),
    act_family:family_del(FamilyID),
    family_misc:check_need_create_family(),
    mod_family_briefs:regen_family_briefs().

%%通知处理活动期间数据
del_activity(FamilyID, RoleID) ->
    #r_activity{status = Status} = world_activity_server:get_activity(?ACTIVITY_FAMILY_GOD_BEAST),
    case Status =:= ?STATUS_OPEN of
        true ->
            Mod = activity_misc:get_activity_mod(?ACTIVITY_FAMILY_GOD_BEAST),
            Mod:info({mod, mod_family_god_beast, {family_member_leave, FamilyID, RoleID}});
        _ ->
            ok
    end,
    #r_activity{status = Status2} = world_activity_server:get_activity(?ACTIVITY_FAMILY_BATTLE),
    case Status2 =:= ?STATUS_OPEN of
        true ->
            Mod2 = activity_misc:get_activity_mod(?ACTIVITY_FAMILY_BATTLE),
            Mod2:info({mod, mod_family_bt, {family_member_leave, FamilyID, RoleID}});
        _ ->
            ok
    end,
    #r_activity{status = Status3} = world_activity_server:get_activity(?ACTIVITY_FAMILY_TD),
    case Status3 =:= ?STATUS_OPEN of
        true ->
            Mod3 = activity_misc:get_activity_mod(?ACTIVITY_FAMILY_TD),
            Mod3:info({mod, mod_family_td, {family_member_leave, FamilyID, RoleID}});
        _ ->
            ok
    end.


check_family_leave(RoleID, MapID) ->
    family_misc:check_leave(MapID),
    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_LEAVE_001)),
    FamilyData = mod_family_data:get_family(FamilyID),
    case family_misc:is_owner(RoleID, FamilyData) of
        true ->
            {owner_leave, FamilyID, FamilyData};
        _ ->
            {member_leave, RoleID, FamilyData}
    end.

%% 玩家进入帮派操作
do_role_join_family(RoleID, Title, FamilyID) when erlang:is_integer(FamilyID) ->
    do_role_join_family(RoleID, Title, mod_family_data:get_family(FamilyID));
do_role_join_family(RoleID, Title, FamilyData) ->
    #p_family{family_id = FamilyID, family_name = FamilyName, members = Members} = FamilyData,
    #r_role_family{apply_list = ApplyList} = RoleFamily = mod_family_data:get_role_family(RoleID),
    #r_role_attr{
        role_name = RoleName,
        level = RoleLevel,
        category = Category,
        power = Power,
        last_offline_time = LastOffline,
        sex = Sex} = common_role_data:get_role_attr(RoleID),
    FamilyMember = #p_family_member{
        role_id = RoleID,
        role_name = RoleName,
        role_level = RoleLevel,
        title = Title,
        salary = true,
        sex = Sex,
        category = Category,
        power = Power,
        is_online = role_misc:is_online(RoleID),
        last_offline_time = LastOffline},
    MemberRoleIDs = [MemberRoleID || #p_family_member{role_id = MemberRoleID} <- Members],
    Members2 = [FamilyMember|Members],
    RoleFamily2 = RoleFamily#r_role_family{role_id = RoleID, family_id = FamilyID, family_name = FamilyName, apply_list = []},
    FamilyData2 = FamilyData#p_family{members = Members2},
    mod_family_data:set_role_family(RoleFamily2),
    mod_family_data:set_family(FamilyData2),
    case FamilyData2#p_family.is_direct_join =:= true andalso family_misc:get_family_max_num(FamilyData2#p_family.level) =< erlang:length(Members2) of
        true ->
            family_misc:check_need_create_family();
        _ ->
            ok
    end,
    FamilyBox = mod_family_data:get_family_box(FamilyID),
    BoxList = [#r_box_list{role_id = RoleID, max_num = mod_role_vip:get_box_max_num(RoleID)}|FamilyBox#r_family_box.role_box_list],
    FamilyBox2 = FamilyBox#r_family_box{role_box_list = BoxList},
    mod_family_data:set_family_box(FamilyBox2),
    family_misc:log_family_status(FamilyData2),
    %% 删除该玩家在其他帮派的申请记录
    [begin
         case mod_family_data:get_family(DestFamilyID) of
             #p_family{apply_list = FamilyApplyList} = DestFamilyData ->
                 FamilyApplyList2 = lists:keydelete(RoleID, #p_family_apply.role_id, FamilyApplyList),
                 DestFamilyData2 = DestFamilyData#p_family{apply_list = FamilyApplyList2},
                 mod_family_data:set_family(DestFamilyData2),
                 common_broadcast:bc_record_to_family(DestFamilyID, #m_family_apply_update_toc{del_apply_ids = [RoleID]});
             _ ->
                 ok
         end
     end || DestFamilyID <- ApplyList],
    DataRecord = #m_family_member_update_toc{member = FamilyMember},
    common_broadcast:bc_record_to_roles(MemberRoleIDs, DataRecord),
    act_family:family_member_change(FamilyID, family_misc:get_family_owner_id(FamilyData2), erlang:length(Members2)),
    hook_family:role_join_family(RoleID, FamilyID, FamilyName, Title).

%% 玩家退出帮派操作
do_role_leave_family(RoleID, FamilyData, LeaveStatus) ->
    #p_family{family_id = FamilyID, members = Members} = FamilyData,
    Members2 = lists:keydelete(RoleID, #p_family_member.role_id, Members),
    MemberRoleIDs = [MemberRoleID || #p_family_member{role_id = MemberRoleID} <- Members2],
    FamilyData2 = FamilyData#p_family{members = Members2},
    RoleFamily = mod_family_data:get_role_family(RoleID),
    RoleFamily2 = RoleFamily#r_role_family{family_id = 0, family_name = ""},
    mod_family_data:set_role_family(RoleFamily2),
    mod_family_data:set_family(FamilyData2),
    %%
    do_role_leave_family_box(FamilyID, RoleID),
    family_misc:log_family_status(FamilyData2),
    DataRecord = #m_family_member_update_toc{del_member_id = RoleID},
    common_broadcast:bc_record_to_roles(MemberRoleIDs, DataRecord),
    hook_family:role_leave_family(RoleID, FamilyID, LeaveStatus).

do_role_leave_family_box(FamilyID, RoleID) ->
    FamilyBox = mod_family_data:get_family_box(FamilyID),
    RoleBoxList = lists:keydelete(RoleID, #r_box_list.role_id, FamilyBox#r_family_box.role_box_list),
    FamilyBox2 = FamilyBox#r_family_box{role_box_list = RoleBoxList},
    mod_family_data:set_family_box(FamilyBox2).


log_family_member(FamilyID, RoleID1, RoleID2, ActionType) ->
    Log = #log_family_member{
        family_id = FamilyID,
        role_id1 = RoleID1,
        role_id2 = RoleID2,
        action_type = ActionType
    },
    background_misc:log(Log).



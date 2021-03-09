%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十月 2017 20:54
%%%-------------------------------------------------------------------
-module(family_misc).
-author("laijichang").
-include("family.hrl").
-include("activity.hrl").
-include("global.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    info_family/1,
    call_family/1
]).

-export([
    check_join/0,
    check_leave/1,
    check_kick/0
]).

-export([
    is_owner/2,
    is_owner_or_vice_owner/2,
    is_owner_or_vice_owner_title/1,
    is_accept_member/1,
    is_kick_member/1,
    is_activity_time/0,
    get_family_owner_id/1,
    get_family_vice_num/1,
    get_title_name/1,
    owner_transfers/2,
    get_next_owner/1,
    is_activity_map/1,
    get_family_max_num/1,
    check_automatic_key/1,
    check_need_create_family/0
]).



-export([
    log_family_status/1,
    log_family_dismiss/2
]).

info_family(Info) ->
    case family_server:is_family_server() of
        true ->
            family_server:handle(Info);
        _ ->
            pname_server:send(family_server, Info)
    end.

call_family(Info) ->
    case family_server:is_family_server() of
        true ->
            family_server:handle(Info);
        _ ->
            pname_server:call(family_server, Info)
    end.

check_join() ->
    ok.

check_leave(MapID) ->
    ?IF(is_activity_map(MapID), ?THROW_ERR(?ERROR_FAMILY_LEAVE_003), ok).

check_kick() ->
    ?IF(is_activity_time(), ?THROW_ERR(?ERROR_FAMILY_KICK_004), ok).

is_owner(RoleID, FamilyData) ->
    #p_family{members = Members} = FamilyData,
    case lists:keyfind(RoleID, #p_family_member.role_id, Members) of
        #p_family_member{title = ?TITLE_OWNER} ->
            true;
        _ ->
            false
    end.

is_owner_or_vice_owner(RoleID, FamilyData) ->
    #p_family{members = Members} = FamilyData,
    case lists:keyfind(RoleID, #p_family_member.role_id, Members) of
        #p_family_member{title = Title} ->
            is_owner_or_vice_owner_title(Title);
        _ ->
            false
    end.

is_owner_or_vice_owner_title(TitleID) ->
    TitleID =:= ?TITLE_OWNER orelse TitleID =:= ?TITLE_VICE_OWNER.

is_accept_member(Title) ->
    lists:member(Title, [?TITLE_OWNER, ?TITLE_VICE_OWNER, ?TITLE_ELDER]).

is_kick_member(Title) ->
    lists:member(Title, [?TITLE_OWNER, ?TITLE_VICE_OWNER]).

is_activity_time() ->
    mod_family_bt:is_activity_open() orelse mod_family_td:is_activity_open() orelse is_activity_open(?ACTIVITY_FAMILY_GOD_BEAST) orelse is_activity_open(?ACTIVITY_FAMILY_AS).


is_activity_map(MapID) ->
    ?MAP_FAMILY_BOSS =:= MapID orelse ?MAP_FAMILY_BT =:= MapID orelse ?MAP_FAMILY_TD =:= MapID orelse ?MAP_FAMILY_AS =:= MapID.


is_activity_open(Type) ->
    #r_activity{status = Status} = world_activity_server:get_activity(Type),
    Status =:= ?STATUS_OPEN.



get_family_owner_id(FamilyData) ->
    #p_family{members = Members} = FamilyData,
    #p_family_member{role_id = RoleID} = lists:keyfind(?TITLE_OWNER, #p_family_member.title, Members),
    RoleID.

get_family_vice_num(FamilyData) ->
    #p_family{members = Members} = FamilyData,
    get_family_vice_num2(Members, 0).

get_family_vice_num2([], Acc) ->
    Acc;
get_family_vice_num2([#p_family_member{title = Title}|R], Acc) ->
    Acc2 = ?IF(Title =:= ?TITLE_VICE_OWNER, Acc + 1, Acc),
    get_family_vice_num2(R, Acc2).

get_title_name(TitleID) ->
    if
        TitleID =:= ?TITLE_OWNER ->
            ?FAMILY_TITLE_OWNER_LANG;
        TitleID =:= ?TITLE_VICE_OWNER ->
            ?FAMILY_TITLE_VICE_OWNER_LANG;
        TitleID =:= ?TITLE_ELDER ->
            ?FAMILY_TITLE_ELDER_LANG;
        TitleID =:= ?TITLE_POPULAR ->
            ?FAMILY_TITLE_POPULAR;
        true ->
            ?FAMILY_TITLE_MEMBER_LANG
    end.


log_family_status(FamilyData) ->
    #p_family{notice = Notice} = FamilyData,
    #p_family_brief{
        family_id = FamilyID,
        family_name = FamilyName,
        level = Level,
        num = Num,
        owner_id = OwnerRoleID,
        power = Power
    } = mod_family_briefs:transform_family_fields(FamilyData),
    Log = #log_family_status{
        family_id = FamilyID,
        family_name = unicode:characters_to_binary(FamilyName),
        family_level = Level,
        owner_role_id = OwnerRoleID,
        member_num = Num,
        family_power = Power,
        family_notice = unicode:characters_to_binary(Notice)},
    background_misc:log(Log).
log_family_dismiss(FamilyData, OwnerRoleID) ->
    #p_family{
        family_id = FamilyID,
        family_name = FamilyName,
        level = Level,
        notice = Notice
    } = FamilyData,
    Log = #log_family_status{
        family_id = FamilyID,
        family_name = unicode:characters_to_binary(FamilyName),
        family_level = Level,
        owner_role_id = OwnerRoleID,
        member_num = 0,
        family_power = 0,
        family_notice = unicode:characters_to_binary(Notice)},
    background_misc:log(Log).

owner_transfers(#p_family{members = Members, family_id = FamilyID} = FamilyData, Now) ->
    case lists:keytake(?TITLE_OWNER, #p_family_member.title, Members) of
        {value, #p_family_member{last_offline_time = LastOfflineTime, is_online = IsOnline} = OldOwner, OtherMembers} ->
            case not IsOnline andalso Now >= LastOfflineTime + 2 * ?ONE_DAY of
                false ->
                    ok;
                _ ->
                    case catch get_next_owner(OtherMembers, Now) of
                        {ok, NewOwner, OtherMembers2} ->
                            [begin
                                 LetterInfo = #r_letter_info{
                                     text_string = [OldOwner#p_family_member.role_name, NewOwner#p_family_member.role_name],
                                     template_id = ?LETTER_TEMPLATE_FAMILY_TEMPLATE
                                 },
                                 common_letter:send_letter(RoleID, LetterInfo)
                             end || #p_family_member{role_id = RoleID} <- Members],
                            NewMembers = [OldOwner#p_family_member{title = ?TITLE_MEMBER}|[NewOwner#p_family_member{title = ?TITLE_OWNER}|OtherMembers2]],
                            NewFamilyData = FamilyData#p_family{members = NewMembers},
                            mod_family_data:set_family(NewFamilyData),
                            DataRecord = #m_family_admin_toc{role_id = OldOwner#p_family_member.role_id, new_title = ?TITLE_MEMBER},
                            DataRecord2 = #m_family_admin_toc{role_id = NewOwner#p_family_member.role_id, new_title = ?TITLE_OWNER},
                            common_broadcast:send_family_common_notice(FamilyID, ?NOTICE_FAMILY_TRANSFERS,
                                                                       [lib_tool:to_list(OldOwner#p_family_member.role_id), common_role_data:get_role_name(OldOwner#p_family_member.role_id),
                                                                        lib_tool:to_list(NewOwner#p_family_member.role_id), common_role_data:get_role_name(NewOwner#p_family_member.role_id)]),
                            Logs = [#log_family_member{family_id = FamilyID, role_id1 = OldOwner#p_family_member.role_id, role_id2 = OldOwner#p_family_member.role_id, action_type = ?LOG_FAMILY_TRANSFORM},
                                    #log_family_member{family_id = FamilyID, role_id1 = NewOwner#p_family_member.role_id, role_id2 = NewOwner#p_family_member.role_id, action_type = ?LOG_FAMILY_TRANSFORM}],
                            background_misc:log(Logs),
                            common_broadcast:bc_record_to_family(FamilyID, DataRecord),
                            common_broadcast:bc_record_to_family(FamilyID, DataRecord2),
                            role_misc:info_role(NewOwner#p_family_member.role_id, {mod, mod_role_family, {title_change, ?TITLE_OWNER}}),
                            ok;
                        _ ->
                            ok
                    end
            end;
        false ->
            ?ERROR_MSG("--------------owner_transfers--------------------~w", [FamilyID]),
            ok
    end.


get_next_owner(Members, Now) ->
    {OtherMembers, CandidateMembers} =
    lists:foldl(
        fun(Member, {AccMembers1, AccMembers2}) ->
            case Member#p_family_member.is_online orelse Now < Member#p_family_member.last_offline_time + 2 * ?ONE_DAY of
                false ->
                    {[Member|AccMembers1], AccMembers2};
                _ ->
                    {AccMembers1, [Member|AccMembers2]}
            end
        end, {[], []}, Members),
    CandidateMembers2 = lists:sort(
        fun(AMember, BMember) ->
            if
                AMember#p_family_member.title > BMember#p_family_member.title -> true;
                AMember#p_family_member.title < BMember#p_family_member.title -> false;
                true ->
                    true
            end
        end, CandidateMembers),
    [NewOwner|T] = CandidateMembers2,
    {ok, NewOwner, T ++ OtherMembers}.


get_next_owner(Members) ->
    CandidateMembers2 = lists:sort(
        fun(AMember, BMember) ->
            if
                AMember#p_family_member.title > BMember#p_family_member.title -> true;
                AMember#p_family_member.title < BMember#p_family_member.title -> false;
                true ->
                    true
            end
        end, Members),
    [NewOwner|T] = CandidateMembers2,
    {ok, NewOwner, T}.


get_family_max_num(Level) ->
    [#c_family_level{
        max_num = MaxNum,
        guild_max_num = GuildMaxNum
    }] = lib_config:find(cfg_family_level, Level),
    ?IF(common_pf:is_agent_guild(), GuildMaxNum, MaxNum).


check_automatic_key(RoleID) ->
    [Config] = lib_config:find(cfg_global, 178),
    case (RoleID - common_id:get_start_role_id()) > Config#c_global.int of
        true ->
            world_data:set_automatic_family_key(true),
            pname_server:send(family_server, check_need_create_family);
        _ ->
            ok
    end.

check_need_create_family() ->
    case world_data:get_automatic_family_key() of
        true ->
            List = mod_family_data:get_all_family(),
            case erlang:length(List) >= 50 of
                true ->
                    ok;
                _ ->
                    Need = check_need_create_family(List, true),
                    ?IF(Need, create_new_empty_family(), ok)
            end;
        _ ->
            ok
    end.



check_need_create_family([], Need) ->
    Need;
check_need_create_family([PFamily|T], Need) ->
    case PFamily#p_family.is_direct_join of
        true ->
            FamilyNum = family_misc:get_family_max_num(PFamily#p_family.level),
            case FamilyNum > erlang:length(PFamily#p_family.members) of
                true ->
                    false;
                _ ->
                    check_need_create_family(T, Need)
            end;
        _ ->
            check_need_create_family(T, Need)
    end.



create_new_empty_family() ->
    FamilyName = random_family_name(),
    FamilyID = world_data:update_family_id(),
    FamilyData = #p_family{
        family_id = FamilyID,
        family_name = FamilyName,
        level = 1,
        max_cv = [#p_kv{id = 1, val = 0}, #p_kv{id = 2, val = 0}, #p_kv{id = 3, val = 0}],
        packet_id = 1,
        red_packet = []
    },
    mod_family_data:set_family_box(#r_family_box{family_id = FamilyID}),
    mod_family_data:set_family_name(#r_family_name{family_name = FamilyName, family_id = FamilyID}),
    mod_family_data:set_family(FamilyData),
    mod_family_briefs:regen_family_briefs(),
    family_misc:log_family_status(FamilyData).


random_family_name() ->
    FamilyName = random_family_name_i(),
    %% 检查敏感词、等
    case catch re:run(FamilyName, " ", [unicode]) of
        {match, _} ->
            random_family_name();
        _ ->
            case catch common_misc:word_check(FamilyName) of
                {error, _ErrCode} ->
                    random_family_name();
                _ ->
                    case mod_family_data:get_family_name(FamilyName) of
                        [#r_family_name{}] ->
                            random_family_name();
                        _ ->
                            FamilyName
                    end
            end
    end.


random_family_name_i() ->
    List = cfg_family_name:list(),
    random_family_name_i(erlang:length(List)).

random_family_name_i(Num) ->
    Num1 = lib_tool:random(Num),
    Num2 = lib_tool:random(Num),
    [Config1] = lib_config:find(cfg_family_name, Num1),
    [Config2] = lib_config:find(cfg_family_name, Num2),
    Config1#c_family_name.name ++ Config2#c_family_name.last_name.
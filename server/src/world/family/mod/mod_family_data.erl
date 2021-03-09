%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十月 2017 17:35
%%%-------------------------------------------------------------------
-module(mod_family_data).
-author("laijichang").
-include("global.hrl").
-include("family.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    init/0
]).

%% 数据相关
-export([
    set_family/1,
    del_family/1,
    get_family/1,
    get_all_family/0,
    set_role_family/1,
    get_role_family/1,
    get_family_brief/1,
    get_family_brief_by_rank/2,
    del_family_brief/0,
    set_family_brief/1,
    set_family_name/1,
    get_family_name/1,
    del_family_name/1,
    get_family_member/2,
    get_family_owner/1,
    set_role_family_asm_info/1,
    del_role_family_asm_info/1,
    get_role_family_asm_info/1,
    set_family_box/1,
    get_family_box/1,
    del_family_box/1,
    get_family_member_by_ids/2
]).


init() ->
    init_ets(),
    init_data().

init_ets() ->
    lib_tool:init_ets(?ETS_FAMILY_BRIEFS, #p_family_brief.family_id),
    ok.

init_data() ->
    world_data:init_family_id(),
    mod_family_briefs:regen_family_briefs().

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_family(#p_family{} = FamilyData) ->
    db:insert(?DB_FAMILY_P, FamilyData).
del_family(FamilyID) ->
    db:delete(?DB_FAMILY_P, FamilyID).

set_family_box(#r_family_box{} = FamilyBoxData) ->
    db:insert(?DB_FAMILY_BOX_P, FamilyBoxData).
get_family_box(FamilyID) ->
    case db:lookup(?DB_FAMILY_BOX_P, FamilyID) of
        [#r_family_box{} = FamilyBox] -> FamilyBox;
        _ -> undefined
    end.
del_family_box(FamilyID) ->
    db:delete(?DB_FAMILY_BOX_P, FamilyID).

set_family_name(#r_family_name{} = FamilyNameData) ->
    db:insert(?DB_FAMILY_NAME_P, FamilyNameData).
get_family_name(FamilyName) ->
    db:lookup(?DB_FAMILY_NAME_P, FamilyName).
del_family_name(FamilyName) ->
    db:delete(?DB_FAMILY_NAME_P, FamilyName).

get_family(FamilyID) ->
    case db:lookup(?DB_FAMILY_P, FamilyID) of
        [#p_family{} = FamilyData] -> FamilyData;
        _ -> undefined
    end.
get_all_family() ->
    ets:tab2list(?DB_FAMILY_P).


get_family_owner(FamilyID) ->
    case db:lookup(?DB_FAMILY_P, FamilyID) of
        [#p_family{members = Members}] ->
            case lists:keyfind(?TITLE_OWNER, #p_family_member.title, Members) of
                #p_family_member{} = Member ->
                    Member;
                _ ->
                    undefined
            end;
        _ -> undefined
    end.

set_role_family(#r_role_family{} = RoleFamily) ->
    db:insert(?DB_ROLE_FAMILY_P, RoleFamily).

get_role_family(RoleID) ->
    case db:lookup(?DB_ROLE_FAMILY_P, RoleID) of
        [#r_role_family{} = RoleFamily] ->
            RoleFamily;
        _ ->
            #r_role_family{role_id = RoleID}
    end.

%%仙盟简略信息
get_family_brief(FamilyID) ->
    case ets:lookup(?ETS_FAMILY_BRIEFS, FamilyID) of
        [FamilyBrief] ->
            FamilyBrief;
        _ ->
            undefiend
    end.

get_family_brief_by_rank(From, To) ->
    %% shell 里执行
    %% MS = ets:fun2ms(fun(#p_family_brief{rank = Rank} = Brief) when Rank >= From andalso Rank =< To -> Brief end),
    MS = [{#p_family_brief{_ = '_', rank = '$1'},
           [{'andalso', {'>=', '$1', From}, {'=<', '$1', To}}],
           ['$_']}],
    {ets:select(?ETS_FAMILY_BRIEFS, MS), ets:info(?ETS_FAMILY_BRIEFS, size)}.

del_family_brief() ->
    ets:delete_all_objects(?ETS_FAMILY_BRIEFS).
set_family_brief(FamilyBriefs) ->
    ets:insert(?ETS_FAMILY_BRIEFS, FamilyBriefs).


%%返回   Member or  false
get_family_member(#p_family{members = Members}, MemberID) ->
    case lists:keyfind(MemberID, #p_family_member.role_id, Members) of
        #p_family_member{} = Member ->
            Member;
        _ ->
            ?THROW_ERR(?ERROR_FAMILY_CREATE_001)
    end.

set_role_family_asm_info(FamilyMi) ->
    db:insert(?DB_FAMILY_ASM_P, FamilyMi).
del_role_family_asm_info(RoleID) ->
    db:delete(?DB_FAMILY_ASM_P, RoleID).
get_role_family_asm_info(RoleID) ->
    case db:lookup(?DB_FAMILY_ASM_P, RoleID) of
        [#r_role_family_mi{} = FamilyMi] ->
            FamilyMi;
        _ ->
            #r_role_family_mi{role_id = RoleID}
    end.

get_family_member_by_ids(FamilyID, MemberID) ->
    case db:lookup(?DB_FAMILY_P, FamilyID) of
        [#p_family{members = Members}] ->
            case lists:keyfind(MemberID, #p_family_member.role_id, Members) of
                #p_family_member{} = Member ->
                    Member;
                _ ->
                    undefined
            end;
        _ -> undefined
    end.
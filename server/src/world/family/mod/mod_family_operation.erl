%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     各种杂项操作
%%% @end
%%% Created : 18. 十月 2017 11:23
%%%-------------------------------------------------------------------
-module(mod_family_operation).
-author("laijichang").
-include("global.hrl").
-include("family.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    family_config/3,
    family_rename/2,
    family_merge_rename/2,
    add_family_money/2
]).

-export([
    web_dismiss_family/1,
    web_change_family_notice/2,
    web_rename_family/2
]).

-export([
    handle/1
]).

family_config(FamilyID, KVList, KSList) ->
    family_misc:info_family({mod, ?MODULE, {family_config, FamilyID, KVList, KSList}}).
family_rename(FamilyID, FamilyName) ->
    family_misc:call_family({mod, ?MODULE, {family_rename, FamilyID, FamilyName}}).
family_merge_rename(FamilyID, NewFamilyName) ->
    family_misc:call_family({mod, ?MODULE, {family_merge_rename, FamilyID, NewFamilyName}}).
add_family_money(FamilyID, AddMoney) ->
    ?IF(?HAS_FAMILY(FamilyID), family_misc:info_family({mod, ?MODULE, {add_family_money, FamilyID, AddMoney}}), ok).

web_dismiss_family(FamilyID) ->
    family_misc:info_family({mod, ?MODULE, {web_dismiss_family, FamilyID}}).
web_change_family_notice(FamilyID, Notice) ->
    family_misc:info_family({mod, ?MODULE, {web_change_family_notice, FamilyID, Notice}}).
web_rename_family(FamilyID, NewFamilyName) ->
    family_misc:call_family({mod, ?MODULE, {web_rename_family, FamilyID, NewFamilyName}}).

handle({family_config, FamilyID, KVList, KSList}) ->
    do_family_config(FamilyID, KVList, KSList);
handle({family_rename, FamilyID, FamilyName}) ->
    do_family_rename(FamilyID, FamilyName);
handle({family_merge_rename, FamilyID, NewFamilyName}) ->
    do_family_merge_rename(FamilyID, NewFamilyName);
handle({add_family_money, FamilyID, AddMoney}) ->
    do_add_family_money(FamilyID, AddMoney);
handle({web_dismiss_family, FamilyID}) ->
    do_web_dismiss_family(FamilyID);
handle({web_change_family_notice, FamilyID, Notice}) ->
    do_web_change_family_notice(FamilyID, Notice);
handle({web_rename_family, FamilyID, NewName}) ->
    do_web_rename_family(FamilyID, NewName).


do_family_config(FamilyID, KVList, KSList) ->
    FamilyData = mod_family_data:get_family(FamilyID),
    FamilyData2 = do_kv_config(FamilyData, KVList),
    FamilyData3 = do_ks_config(FamilyData2, KSList),
    mod_family_data:set_family(FamilyData3),
    ?IF(FamilyData3#p_family.is_direct_join =:= true, ok, family_misc:check_need_create_family()),
    DataRecord = #m_family_config_toc{kv_list = KVList, ks_list = KSList},
    common_broadcast:bc_record_to_family(FamilyID, DataRecord).

do_kv_config(FamilyData, []) ->
    FamilyData;
do_kv_config(FamilyData, [KV|R]) ->
    #p_kv{id = Key, val = Value} = KV,
    FamilyData2 =
    if
        Key =:= ?CONFIG_IS_DIRECT ->
            Bool = ?IF(Value > 0, true, false),
            FamilyData#p_family{is_direct_join = Bool};
        Key =:= ?CONFIG_LIMIT_LEVEL ->
            FamilyData#p_family{limit_level = Value};
        Key =:= ?CONFIG_LIMIT_POWER ->
            FamilyData#p_family{limit_power = Value}
    end,
    do_kv_config(FamilyData2, R).

do_ks_config(FamilyData, []) ->
    FamilyData;
do_ks_config(FamilyData, [KS|R]) ->
    #p_ks{id = Key, str = String} = KS,
    FamilyData2 =
    if
        Key =:= ?CONFIG_NOTICE ->
            FamilyData#p_family{notice = String}
    end,
    do_ks_config(FamilyData2, R).

do_family_rename(FamilyID, FamilyName) ->
    case catch check_family_rename(FamilyID, FamilyName) of
        {ok, FamilyData} ->
            do_family_rename2(FamilyName, FamilyData),
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

do_family_rename2(FamilyName, FamilyData) ->
    #p_family{family_name = OldFamilyName, family_id = FamilyID} = FamilyData,
    mod_family_data:del_family_name(OldFamilyName),
    mod_family_data:set_family_name(#r_family_name{family_name = FamilyName, family_id = FamilyID}),
    mod_family_data:set_family(FamilyData#p_family{family_name = FamilyName}),
    [begin
         RoleFamily = mod_family_data:get_role_family(RoleID),
         mod_family_data:set_role_family(RoleFamily#r_role_family{family_name = FamilyName})
     end || #p_family_member{role_id = RoleID} <- FamilyData#p_family.members],
    mod_family_briefs:update_family_briefs(FamilyID, [{#p_family_brief.family_name, FamilyName}]),
    DataRecord = #m_family_config_toc{ks_list = [#p_ks{id = ?CONFIG_FAMILY_NAME, str = FamilyName}]},
    common_broadcast:bc_record_to_family(FamilyID, DataRecord),
    common_broadcast:bc_role_info_to_family(FamilyID, {mod, mod_role_family, {family_name_change, FamilyName}}).


check_family_rename(FamilyID, FamilyName) ->
    case mod_family_data:get_family_name(FamilyName) of
        [#r_family_name{}] ->
            ?THROW_ERR(?ERROR_FAMILY_RENAME_001);
        _ ->
            ok
    end,
    #p_family{} = FamilyData = mod_family_data:get_family(FamilyID),
    {ok, FamilyData}.

do_family_merge_rename(FamilyID, NewFamilyName) ->
    #p_family{members = Members} = FamilyData = mod_family_data:get_family(FamilyID),
    do_family_rename2(NewFamilyName, FamilyData),
    case lists:keyfind(?TITLE_OWNER, #p_family_member.title, Members) of
        #p_family_member{role_id = RoleID} ->
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_MERGE_FAMILY_RENAME,
                action = ?ITEM_GAIN_SERVER_MERGE,
                goods_list = [#p_goods{type_id = 31031, num = 1}]
            },
            common_letter:send_letter(RoleID, LetterInfo);
        _ ->
            ok
    end,
    ok.

do_add_family_money(FamilyID, AddMoney) ->
    #p_family{level = Level, money = Money} = FamilyData = mod_family_data:get_family(FamilyID),
    {Level2, Money2} = do_add_family_money2(Level, Money + AddMoney),
    FamilyData2 = FamilyData#p_family{level = Level2, money = Money2},
    mod_family_data:set_family(FamilyData2),
    ChangeList =
    case Level =/= Level2 of
        true ->
            OwnerID = family_misc:get_family_owner_id(FamilyData),
            [mod_role_act_family:family_level_trigger(OwnerID, TempLevel) || TempLevel <- lists:seq(Level + 1, Level2)],
            [#p_kv{id = ?FAMILY_UPDATE_LEVEL, val = Level2}, #p_kv{id = ?FAMILY_UPDATE_MONEY, val = Money2}];
        _ ->
            [#p_kv{id = ?FAMILY_UPDATE_MONEY, val = Money2}]
    end,
    common_broadcast:bc_record_to_family(FamilyID, #m_family_info_update_toc{kv_list = ChangeList}).

do_add_family_money2(Level, Money) ->
    case lib_config:find(cfg_family_level, Level + 1) of
        [_NextConfig] -> %% 可以升到下一级
            [#c_family_level{use_money = UseMoney}] = lib_config:find(cfg_family_level, Level),
            case Money >= UseMoney of
                true ->
                    do_add_family_money2(Level + 1, Money - UseMoney);
                _ ->
                    {Level, Money}
            end;
        _ ->
            {Level, Money}
    end.

%% 后台解散仙盟
do_web_dismiss_family(FamilyID) ->
    case mod_family_data:get_family(FamilyID) of
        #p_family{members = Members} = FamilyData ->
            [begin
                 RoleFamily = mod_family_data:get_role_family(RoleID),
                 RoleFamily2 = RoleFamily#r_role_family{family_id = 0, family_name = ""},
                 mod_family_data:set_role_family(RoleFamily2),
                 hook_family:role_leave_family(RoleID, FamilyID, ?FAMILY_LEAVE_STATUS_1),
                 mod_family_request:log_family_member(FamilyID, 0, RoleID, ?LOG_FAMILY_WEB_DISMISS)
             end || #p_family_member{role_id = RoleID} <- Members],
            common_broadcast:bc_record_to_family(FamilyID, #m_family_info_toc{}),
            mod_family_request:del_family(FamilyID),
            #p_family_member{role_id = OwnerRoleID} = lists:keyfind(?TITLE_OWNER, #p_family_member.title, Members),
            family_misc:log_family_dismiss(FamilyData#p_family{members = []}, OwnerRoleID);
        _ ->
            ok
    end.

do_web_change_family_notice(FamilyID, Notice) ->
    case mod_family_data:get_family(FamilyID) of
        #p_family{} = FamilyData ->
            FamilyData2 = FamilyData#p_family{notice = Notice},
            mod_family_data:set_family(FamilyData2),
            DataRecord = #m_family_config_toc{ks_list = [#p_ks{id = ?CONFIG_NOTICE, str = Notice}]},
            common_broadcast:bc_record_to_family(FamilyID, DataRecord),
            family_misc:log_family_status(FamilyData2);
        _ ->
            ok
    end.

do_web_rename_family(FamilyID, NewName) ->
    case catch check_web_rename_family(FamilyID, NewName) of
        {ok, FamilyData} ->
            do_family_rename2(NewName, FamilyData),
            ok;
        {error, Msg} ->
            {error, Msg}
    end.

check_web_rename_family(FamilyID, NewName) ->
    FamilyData =
    case mod_family_data:get_family(FamilyID) of
        #p_family{} = FamilyDataT ->
            FamilyDataT;
        _ ->
            erlang:throw({error, "family not found"})
    end,
    case db:lookup(?DB_FAMILY_NAME_P, NewName) of
        #r_family_name{} ->
            erlang:throw({error, "name exist"});
        _ ->
            ok
    end,
    {ok, FamilyData}.
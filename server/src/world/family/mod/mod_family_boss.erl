%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 五月 2018 11:33
%%%-------------------------------------------------------------------
-module(mod_family_boss).
-author("WZP").
-include("family.hrl").
-include("family_boss.hrl").
-include("common.hrl").
-include("common_records.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_family_bs.hrl").

%% API
-export([
    family_open_boss/2,
%%    refresh_boss_times/0,
    family_turn_over_boss_grain/2
]).
-export([
    handle/1
]).


family_open_boss(RoleID, FamilyID) ->
    family_misc:call_family({mod, ?MODULE, {family_open_boss, RoleID, FamilyID}}).
family_turn_over_boss_grain(FamilyID, Num) ->
    family_misc:info_family({mod, ?MODULE, {family_turn_over_boss_grain, FamilyID, Num}}).


%%handle({family_open_boss, RoleID, FamilyID}) ->
%%    do_family_open_boss(RoleID, FamilyID);
handle({family_turn_over_boss_grain, FamilyID, Num}) ->
    {FamilyID, Num}.
%%    do_turn_over_boss_grain(FamilyID, Num).


%%do_family_open_boss(RoleID, FamilyID) ->
%%    case catch check_can_open_boss(RoleID, FamilyID) of
%%        {ok, NewFamily, RecordList} ->
%%            mod_family_data:set_family(NewFamily),
%%            [common_broadcast:bc_record_to_family(FamilyID, DataRecord) || DataRecord <- RecordList],
%%            ok;
%%        {error, ErrCode} ->
%%            {error, ErrCode}
%%    end.
%%
%%do_turn_over_boss_grain(FamilyID, Num) ->
%%    #p_family{boss_grain = BossGrain} = FamilyData = mod_family_data:get_family(FamilyID),
%%    NewFamilyData = FamilyData#p_family{boss_grain = BossGrain + Num},
%%    DataRecord = #m_family_boss_grain_update_toc{boss_grain = NewFamilyData#p_family.boss_grain},
%%    common_broadcast:bc_record_to_family(FamilyID, DataRecord),
%%    mod_family_data:set_family(NewFamilyData).
%%
%%
%%check_can_open_boss(RoleID, FamilyID) ->
%%    #p_family{boss_grain = BossGrain, boss_times = BossTimes} = FamilyData = mod_family_data:get_family(FamilyID),
%%    [Config] = lib_config:find(cfg_global, ?FAMILY_BOSS_GLOBAL),
%%    [NeedBossGrain, MaxTimes] = Config#c_global.list,
%%    NewBossGrain = BossGrain - NeedBossGrain,
%%    ?IF(NewBossGrain >= 0, ok, ?THROW_ERR(?ERROR_FAMILY_BOSS_002)),
%%    ?IF(MaxTimes =< BossTimes, ?THROW_ERR(?ERROR_FAMILY_BOSS_003), ok),
%%    ?IF(family_misc:is_owner_or_vice_owner(RoleID, FamilyData), ok, ?THROW_ERR(?ERROR_FAMILY_BOSS_001)),
%%    NewBossTimes = BossTimes + 1,
%%    case mod_family_bs:open_family_boss(FamilyID) of
%%        {ok, _} ->
%%            DataRecord = #m_family_boss_notice_toc{type = ?FAMILY_BOSS_ONLINE_BC},
%%            DataRecord2 = #m_family_boss_grain_update_toc{boss_grain = NewBossGrain},
%%            DataRecord3 = #m_family_boss_times_update_toc{times = NewBossTimes},
%%            RecordList = [DataRecord, DataRecord2, DataRecord3],
%%            {ok, FamilyData#p_family{boss_grain = NewBossGrain, boss_times = NewBossTimes}, RecordList};
%%        {error, ErrCode} ->
%%            {error, ErrCode}
%%    end.
%%
%%refresh_boss_times() ->
%%    AllFamily = mod_family_data:get_all_family(),
%%    DataRecord = #m_family_boss_times_update_toc{times = 0},
%%    refresh_boss_times2(AllFamily, DataRecord).
%%
%%refresh_boss_times2([], _) ->
%%    ok;
%%refresh_boss_times2([Family|T], DataRecord) ->
%%    NewFamily = Family#p_family{boss_times = 0},
%%    mod_family_data:set_family(NewFamily),
%%    common_broadcast:bc_record_to_family(NewFamily#p_family.family_id, DataRecord),
%%    refresh_boss_times2(T, DataRecord).
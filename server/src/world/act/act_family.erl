%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     仙盟活动相关数据处理
%%% @end
%%% Created : 28. 十一月 2018 15:30
%%%-------------------------------------------------------------------
-module(act_family).
-author("laijichang").
-include("act.hrl").
-include("proto/mod_role_act_family.hrl").
-include("global.hrl").

%% API
-export([
    handle/1
]).

%% 角色进程调用
-export([
    create_reward/1
]).

%% 其他进程调用
-export([
    family_create/1,
    family_del/1,
    family_vice_change/3,
    family_member_change/3,

    family_battle_end/1,
    family_hunt_boss_score_change/2,
    family_hunt_boss_reward_list_status_change/1
]).

create_reward(Config) ->
    world_act_server:call_mod(?MODULE, {create_reward, Config}).

family_create(FamilyID) ->
    world_act_server:info_mod(?MODULE, {family_create, FamilyID}).

family_del(FamilyID) ->
    world_act_server:info_mod(?MODULE, {family_del, FamilyID}).

family_vice_change(FamilyID, OwnerID, ViceNum) ->
    ?IF(world_act_server:is_act_open(?ACT_FAMILY_CREATE),
        world_act_server:info_mod(?MODULE, {family_data_change, ?ACT_FAMILY_MAX_VICE, FamilyID, OwnerID, ViceNum}),
        ok).

family_member_change(FamilyID, OwnerID, MemberNum) ->
    ?IF(world_act_server:is_act_open(?ACT_FAMILY_CREATE),
        world_act_server:info_mod(?MODULE, {family_data_change, ?ACT_FAMILY_MAX_MEMBER, FamilyID, OwnerID, MemberNum}),
        ok).

family_battle_end(ActList) ->
    ?IF(world_act_server:is_act_open(?ACT_FAMILY_BATTLE),
        world_act_server:info_mod(?MODULE, {family_battle_end, ActList}),
        ok).

family_hunt_boss_score_change(FamilyID, Type) ->
    ?IF(world_act_server:is_act_open(?ACT_HUNT_BOSS_ID),
        world_act_server:info_mod(?MODULE,{family_score_change, FamilyID ,Type}),
        ok).

family_hunt_boss_reward_list_status_change(FamilyID) ->
    ?IF(world_act_server:is_act_open(?ACT_HUNT_BOSS_ID),
        world_act_server:info_mod(?MODULE,{family_reward_status_change, FamilyID}),
        ok).

handle({create_reward, Config}) ->
    do_create_reward(Config);
handle({family_create, FamilyID}) ->
    do_family_create(FamilyID);
handle({family_del, FamilyID}) ->
    do_family_del(FamilyID);
handle({family_data_change, ID, FamilyID, OwnerID, Num}) ->
    do_family_data_change(ID, FamilyID, OwnerID, Num);
handle({family_battle_end, ActList}) ->
    do_family_battle_end(ActList);
handle({family_score_change, FamilyID, Type}) ->
    do_family_score_change(FamilyID, Type);
handle({family_reward_status_change, FamilyID}) ->
    family_reward_status_change(FamilyID);
handle(Info) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]).

do_create_reward(Config) ->
    #c_act_family_create{id = ID, num = AllNum} = Config,
    RewardList = world_data:get_act_family_create_reward(),
    {KV, RewardList2} =
        case lists:keytake(ID, #p_kv.id, RewardList) of
            {value, KVT, RewardListT} ->
                {KVT, RewardListT};
            _ ->
                {#p_kv{id = ID, val = 0}, RewardList}
        end,
    #p_kv{val = HasReward} = KV,
    case HasReward < AllNum of
        true ->
            KV2 = KV#p_kv{val = HasReward + 1},
            RewardList3 = [KV2|RewardList2],
            world_data:set_act_family_create_reward(RewardList3),
            DataRecord = #m_act_family_create_reward_update_toc{reward = KV2},
            [#c_act{min_level = MinLevel}] = lib_config:find(cfg_act, ?ACT_FAMILY_CREATE),
            Condition = #r_broadcast_condition{min_level = MinLevel},
            common_broadcast:bc_record_to_world_by_condition(DataRecord, Condition),
            true;
        _ ->
            {error, ?ERROR_ACT_FAMILY_CREATE_REWARD_003}
    end.

do_family_create(FamilyID) ->
    List = world_data:get_act_family(),
    ActFamily = get_act_family(FamilyID, List),
    set_act_family(ActFamily, List).

do_family_del(FamilyID) ->
    List = world_data:get_act_family(),
    FamilyHuntBossScoreList = world_data:get_act_family_hunt_boss_score(),
    ?IF(lists:keymember(FamilyID, 1, FamilyHuntBossScoreList), world_data:set_act_family_hunt_boss_score(lists:keydelete(FamilyID, 1, FamilyHuntBossScoreList)), ok),
    del_act_family(FamilyID, List).

do_family_data_change(ID, FamilyID, OwnerID, Val) ->
    List = world_data:get_act_family(),
    #r_act_family{max_list = MaxList} = ActFamily = get_act_family(FamilyID, List),
    case lists:keytake(ID, #p_kv.id, MaxList) of
        {value, #p_kv{val = OldVal} = KV, MaxList2} ->
            case Val > OldVal of
                true -> %% 最大值更新
                    MaxList3 = [KV#p_kv{val = Val}|MaxList2],
                    ActFamily2 = ActFamily#r_act_family{max_list = MaxList3},
                    set_act_family(ActFamily2, List),
                    do_family_data_change2(ID, OwnerID, OldVal, Val);
                _ ->
                    ok
            end;
        _ ->
            MaxList2 = [#p_kv{id = ID, val = Val}|MaxList],
            ActFamily2 = ActFamily#r_act_family{max_list = MaxList2},
            set_act_family(ActFamily2, List),
            do_family_data_change2(ID, OwnerID, 0, Val)
    end.

do_family_data_change2(ID, OwnerID, OldVal, Val) ->
    if
        ID =:= ?ACT_FAMILY_MAX_VICE ->
            [ mod_role_act_family:family_vice(OwnerID, TempNum) || TempNum<- lists:seq(OldVal, Val)];
        ID =:= ?ACT_FAMILY_MAX_MEMBER ->
            [ mod_role_act_family:family_member_trigger(OwnerID, TempNum) || TempNum <- lists:seq(OldVal, Val)]
    end.

do_family_battle_end(ActList) ->
    ConditionList = do_family_battle_end2(ActList, []),
    ActBattle = #r_act_family_battle{is_end = true, condition_list = ConditionList},
    world_data:set_act_family_battle(ActBattle),
    common_broadcast:bc_role_info_to_world({mod, mod_role_act_family, family_battle_condition}).

do_family_battle_end2([], Acc) ->
    Acc;
do_family_battle_end2([{Rank, OwnerID, Members}|R], Acc) ->
    {OwnerCondition, MemberCondition} =
        if
            Rank =:= 1 ->
                {?ACT_FAMILY_BATTLE_FIRST_OWNER, ?ACT_FAMILY_BATTLE_FIRST_MEMBER};
            Rank =:= 2 ->
                {?ACT_FAMILY_BATTLE_SECOND_OWNER, ?ACT_FAMILY_BATTLE_SECOND_MEMBER};
            Rank =:= 3 ->
                {?ACT_FAMILY_BATTLE_THIRD_OWNER, ?ACT_FAMILY_BATTLE_THIRD_OWNER}
        end,
    RoleList = [ #p_dkv{id = MemberRoleID, val = MemberCondition}|| MemberRoleID <- Members],
    Acc2 = [#p_dkv{id = OwnerID, val = OwnerCondition}|RoleList] ++ Acc,
    do_family_battle_end2(R, Acc2).

do_family_score_change(FamilyID, Type) ->
    FamilyScoreList = world_data:get_act_family_hunt_boss_score(), %得到完整列表.
    Now = time_tool:now(),
    case lists:keyfind(FamilyID,1,FamilyScoreList) of  %找自己的仙盟
        {_, FScore, _} ->
            NewFscore = mod_role_act_hunt_boss:add_score(Type, FScore), %加仙盟的积分
            world_data:set_act_family_hunt_boss_score(lists:keyreplace(FamilyID,1,FamilyScoreList,{FamilyID, NewFscore, Now}));%更新列表
        false ->
            NewFscore1 = mod_role_act_hunt_boss:add_score(Type, 0),% 默认是0分
            world_data:set_act_family_hunt_boss_score([{FamilyID, NewFscore1, Now}|FamilyScoreList])
    end.

family_reward_status_change(FamilyID) ->  %[id1,id2,id3]
    RewardStatus = world_data:get_act_family_hunt_boss_reward_status(),
    AlreadyInTheRewardList = lists:member(FamilyID, RewardStatus),
    NewRewardStatus = ?IF(AlreadyInTheRewardList, RewardStatus, lists:append(RewardStatus, [FamilyID])),
    world_data:set_act_family_hunt_boss_reward_status(NewRewardStatus).
%%%===================================================================
%%% 数据操作
%%%===================================================================
get_act_family(FamilyID, List) ->
    case lists:keyfind(FamilyID, #r_act_family.family_id, List) of
        #r_act_family{} = ActFamily ->
            ActFamily;
        _ ->
            #r_act_family{family_id = FamilyID}
    end.

set_act_family(ActFamily, List) ->
    List2 = lists:keystore(ActFamily#r_act_family.family_id, #r_act_family.family_id, List, ActFamily),
    world_data:set_act_family(List2).

del_act_family(FamilyID, List) ->
    List2 = lists:keydelete(FamilyID, #r_act_family.family_id, List),
    world_data:set_act_family(List2).


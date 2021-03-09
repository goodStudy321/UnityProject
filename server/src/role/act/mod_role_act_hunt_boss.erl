%%%-------------------------------------------------------------------
%%% @author TcwXinYe
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十一月 2018 16:56
%%%-------------------------------------------------------------------
-module(mod_role_act_hunt_boss).
-author("TcwXinYe").
-include("role.hrl").
-include("act.hrl").
-include("monster.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_act_hunt_boss.hrl").
-include("proto/mod_role_family.hrl").
%% API
-export([
    init/1,
    online/1,
    handle/2,
    handle/1,
    zero/1
]).

-export([
    init_data/2,
    kill_world_boss/2,
    kill_boss/3,
    act_update/1,
    add_score/2,
    get_final_family_reward_list/0,
    family_title_change/1
]).

-export([
    gm/1
]).

init(#r_role{role_id = RoleID, role_act_hunt_boss = undefined} = State) ->
    RoleActHunt = #r_role_act_hunt_boss{role_id = RoleID},
    State#r_role{role_act_hunt_boss = RoleActHunt};
init(State) ->
    State.

init_data(#r_role{role_id = RoleID} = State, OpenTime) ->
    RoleActHunt = #r_role_act_hunt_boss{role_id = RoleID, start_date = OpenTime},
    State#r_role{role_act_hunt_boss = RoleActHunt}.

act_update(State) ->
    online(State).

zero(State) ->
    online(State).

family_title_change(State) ->
    online(State).

online(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_act_hunt_boss = RoleActHuntBoss} = State,
    #r_role_act_hunt_boss{reward_list = RewardList} = RoleActHuntBoss,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    FinalReward1 = case mod_role_act:is_act_open(?ACT_HUNT_BOSS_ID, State) of
                       true -> % 在8天的活动时间内 就会有对奖励列表可能有所改变
                           Day = common_config:get_open_days(),
                           FinalReward = case Day of
                                             8 -> %开服第8天就开始结算个人与仙盟的奖励。
                                                 RewardWho = get_final_personal_reward_list(),
                                                 CanIGetReward = lists:member(RoleID, RewardWho), % 我（个人）是否可以获奖的
                                                 NewRewardList3 = case CanIGetReward of   % 更新个人奖励
                                                                      true ->
                                                                          RewardRank = what_kind_of_reward_I_can_get(RoleID, RewardWho),
                                                                          RewardId = personal_reward_id(RewardRank),
                                                                          NewRewardList2 = case have_I_got_the_reward(RewardId, RewardList) of
                                                                                               true ->
                                                                                                   RewardList;
                                                                                               _ ->
                                                                                                   NewRewardList1 = lists:append(RewardList, [#p_kv{id = RewardId, val = ?ACT_REWARD_CAN_GET}]),
                                                                                                   NewRewardList1 end,
                                                                          NewRewardList2;
                                                                      _ ->   %个人没有获奖
                                                                          RewardList end,
                                                 % 以下是关于玩家所在的仙盟是否能获奖。
                                                 RewardFamilies = get_final_family_reward_list(),  %得到一份前（？）的仙盟的名单  策划的表如果改变需要通知。
                                                 CanWeGetReward = lists:member(FamilyID, RewardFamilies), %是否是在可以获奖的仙盟里
                                                 NewRewardList4 = case CanWeGetReward of
                                                                      true ->   %我在可以获奖的仙盟
                                                                          AmITheBoss = am_I_the_boss(FamilyID, RoleID), %我是不是盟主
                                                                          AddFamilyRewardList4 = case AmITheBoss of %我是盟主
                                                                                                     true ->
                                                                                                         FamilyRewardRank = what_kind_of_reward_I_can_get(FamilyID, RewardFamilies),
                                                                                                         FamilyRewardId = family_reward_id(FamilyRewardRank),%这个仙盟（盟主）是得哪个奖励
                                                                                                         HaveWeNotGotReward = have_we_not_got_the_reward(FamilyID), %有没有消费（使用）过奖
                                                                                                         AddFamilyRewardList2 = case HaveWeNotGotReward of
                                                                                                                                    true ->
                                                                                                                                        %% 需要判断是不是个人是不是已经领取了这个奖励
                                                                                                                                        AddFamilyRewardList = ?IF(lists:keymember(FamilyRewardId, #p_kv.id, NewRewardList3), NewRewardList3, lists:append(NewRewardList3, [#p_kv{id = FamilyRewardId, val = ?ACT_REWARD_CAN_GET}])),
                                                                                                                                        AddFamilyRewardList;
                                                                                                                                    _ ->
                                                                                                                                        NewRewardList3 end,
                                                                                                         AddFamilyRewardList2;
                                                                                                     _ ->   %我不是盟主 就把盟主可以获取的仙盟奖励给删掉
                                                                                                         FamilyRewardRank = what_kind_of_reward_I_can_get(FamilyID, RewardFamilies),
                                                                                                         FamilyRewardId = family_reward_id(FamilyRewardRank),
                                                                                                         AddFamilyRewardList = case lists:keyfind(FamilyRewardId, #p_kv.id, NewRewardList3) of
                                                                                                                                   true ->   %曾经是盟主，现在不是了，要把他可以领的奖励取消
                                                                                                                                       NewListTitleChange = lists:keydelete(FamilyRewardId, #p_kv.id, NewRewardList3),
                                                                                                                                       NewListTitleChange;
                                                                                                                                   _ ->
                                                                                                                                       NewRewardList3 end,
                                                                                                         AddFamilyRewardList end,
                                                                          AddFamilyRewardList4;
                                                                      _ ->  % 我不在可以获奖的仙盟
                                                                          DelFamilyRewardList4 = del_family_reward(NewRewardList3),
                                                                          DelFamilyRewardList4
                                                                  end,
                                                 NewRewardList4;
                                             _ ->   %在1-7天就不用结算
                                                 RewardList
                                         end,
                           %8天以内都会推送一次消息
                           ?IF(FinalReward =/= [], common_misc:unicast(RoleID, #m_role_act_hunt_boss_info_toc{hunt_boss_reward_list = FinalReward}), ok),
                           FinalReward;
                       _ ->   %不在8天活动时间内 消息都不推送。
                           RewardList
                   end,
    NewRoleActHuntBoss = RoleActHuntBoss#r_role_act_hunt_boss{reward_list = FinalReward1},
    State2 = State#r_role{role_act_hunt_boss = NewRoleActHuntBoss},
    State2.

handle({#m_act_boss_hunt_family_rank_info_tos{}, RoleID, _PID}, State) -> % 处理猎杀boss仙盟排行
    do_handle_boss_hunt_family_rank_info_tos(RoleID, State);

handle({#m_act_boss_hunt_personal_rank_info_tos{}, RoleID, _PID}, State) ->  % 处理猎杀boss个人排行
    do_handle_boss_hunt_personal_rank_info_tos(RoleID, State);

handle({#m_role_act_hunt_boss_reward_tos{id = ID}, RoleID, _PID}, State) ->  % 处理请求获得猎杀boss奖励
    do_hunt_boss_reward(RoleID, ID, State).

do_hunt_boss_reward(RoleID, ID, State) ->
    case catch check_hunt_boss_reward(ID, State) of
        {ok, BagDoings, RewardType, FamilyID, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_role_act_hunt_boss_reward_toc{hunt_boss_reward_list = #p_kv{id = ID, val = ?ACT_REWARD_GOT}}),
            case RewardType =:= 1 of    %如果奖励类型是道庭奖励就生成仙盟红包。
                true ->
                    %把仙盟已经领奖的状态给加上。
                    family_reward_status_change(FamilyID); %领取过了就加上这个仙盟的ID
                _ ->
                    ok
            end,
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_act_hunt_boss_reward_toc{err_code = ErrCode}),
            State
    end.

check_hunt_boss_reward(ID, State) ->
    ?IF(mod_role_act:is_act_open(?ACT_HUNT_BOSS_ID, State), ok, ?THROW_ERR(?ERROR_ROLE_ACT_HUNT_BOSS_REWARD_002)),
    #r_role{role_attr = RoleAttr, role_act_hunt_boss = RoleActHuntBoss} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    #r_role_act_hunt_boss{reward_list = RewardList} = RoleActHuntBoss,
    case lists:keyfind(ID, #p_kv.id, RewardList) of
        #p_kv{val = ?ACT_REWARD_CAN_GET} ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    case lib_config:find(cfg_act_hunt_boss, ID) of
        [Config] ->
            ok;
        _ ->
            Config = ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    #c_act_hunt_boss{id = ID, type = RewardType, reward = RewardItems} = Config,
    GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(RewardItems)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_HUNT_BOSS, GoodsList}],
    NewRewardList = lists:keyreplace(ID, #p_kv.id, RewardList, #p_kv{id = ID, val = ?ACT_REWARD_GOT}),
    NewRoleActHuntBoss = RoleActHuntBoss#r_role_act_hunt_boss{reward_list = NewRewardList},
    State2 = State#r_role{role_act_hunt_boss = NewRoleActHuntBoss},
    {ok, BagDoings, RewardType, FamilyID, State2}.

kill_world_boss(TypeID, State) ->
    [#c_world_boss{type = Type, boss_type = BossType}] = lib_config:find(cfg_world_boss, TypeID), %根据TypeID得到世界boss配置表中boss类型。
    ?IF(?IS_WORLD_BOSS_TYPE(BossType), kill_boss(Type, TypeID, State), State).

kill_boss(Type, TypeID, State) ->
    #c_monster{level = Level} = monster_misc:get_monster_config(TypeID),%得到怪物的等级
    #r_role{role_id = RoleID, role_attr = #r_role_attr{family_id = FamilyID}, role_act_hunt_boss = RoleActHuntBoss} = State,
    #r_role_act_hunt_boss{hunt_boss_score = Score, reward_list = RewardList} = RoleActHuntBoss,
    case common_config:is_open_7days() of
        true -> %在7天以内猎杀Boss就要加分
            NewScore = case Level >= 1 of  %1的意思：怪物在1级以上才有加分！
                           true ->
                               NewScore1 = add_score(Type, Score), %得到新的个人分数
                               personal_hunt_boss_score_change(NewScore1, RoleID), %个人积分变更
                               family_hunt_boss_score_change(FamilyID, Type),  %仙盟积分变更
                               NewScore1;
                           _ ->
                               Score end,
            Config7 = lib_config:find(cfg_act_hunt_boss, ?ACT_HUNT_BOSS_40_REWARD),
            [#c_act_hunt_boss{args2 = Args7}] = Config7,  %% 40 积分的奖励 id 为7
            FinalRewardList = case NewScore >= Args7 of %得出最终的奖励列表
                                  true ->
                                      NewRewardList = check_reward(?ACT_HUNT_BOSS_40_REWARD, RewardList), %看看能不能获得40积分的奖励
                                      ?IF(NewRewardList =/= RewardList, common_misc:unicast(RoleID, #m_role_act_hunt_boss_info_toc{hunt_boss_reward_list = NewRewardList}), ok),
                                      [#c_act_hunt_boss{args2 = Args8}] = lib_config:find(cfg_act_hunt_boss, ?ACT_HUNT_BOSS_60_REWARD),  %% 60 积分的奖励 id 为7
                                      NewRewardList2 = case NewScore >= Args8 of
                                                           true ->
                                                               NewRewardList3 = check_reward(?ACT_HUNT_BOSS_60_REWARD, NewRewardList),  %加60积分奖励
                                                               ?IF(NewRewardList3 =/= RewardList, common_misc:unicast(RoleID, #m_role_act_hunt_boss_info_toc{hunt_boss_reward_list = NewRewardList3}), ok),
                                                               NewRewardList3;
                                                           _ -> %没到60积分
                                                               NewRewardList end,
                                      NewRewardList2;
                                  _ -> %没到40积分
                                      RewardList end,
            NewRoleActHuntBoss = RoleActHuntBoss#r_role_act_hunt_boss{hunt_boss_score = NewScore, reward_list = FinalRewardList},
            State2 = State#r_role{role_act_hunt_boss = NewRoleActHuntBoss},
            State2;
        _ -> %不在7天以内不加分 直接返回状态。
            State
    end.

%%根据类型(Type)加上猎杀boss个人分
add_score(1, Score) ->   % 1 世界boss
    NewScore = Score + 3,
    NewScore;
add_score(2, Score) ->  % 2 洞天福地
    NewScore = Score + 1,
    NewScore;
add_score(3, Score) ->  % 3 个人Boss
    NewScore = Score + 3,
    NewScore;
add_score(4, Score) ->  % 4 幽冥地界
    NewScore = Score + 2,
    NewScore;
add_score(_, Score) ->
    Score.

%%=================================================
%% internal function
%%=================================================
check_reward(RewardId, RewardList) ->
    case RewardList =/= [] of
        true ->
            RewardList2 = ?IF(lists:keymember(RewardId, #p_kv.id, RewardList), RewardList, lists:append(RewardList, [#p_kv{id = RewardId, val = ?ACT_REWARD_CAN_GET}])),
            RewardList2;
        _ ->
            RewardList2 = [#p_kv{id = RewardId, val = 2}],
            RewardList2
    end,
    RewardList2.

sort_score(ListA) ->
    SortFun = fun(A, B) ->
        {_, Score1, Time1} = A,
        {_, Score2, Time2} = B,
        if Score1 =:= Score2 ->
            Time1 =< Time2;
            true ->
                Score1 > Score2
        end end,
    lists:sort(SortFun, ListA).

get_rank([], _Rank, _RoleID) ->  %找到自己在顺序表中的排行，这里空表与没找到均返回0
    NewRank = 0,
    NewRank;
get_rank(ListA, Rank, RoleID) ->
    [A|Tail] = ListA,
    {RoleID1, _, _} = A,
    NewRank = case RoleID1 =:= RoleID of
                  true ->
                      NewRank1 = Rank,
                      NewRank1;
                  _ ->
                      Rank1 = Rank + 1,
                      NewRank1 = get_rank(Tail, Rank1, RoleID),
                      NewRank1
              end,
    NewRank.

get_ranks(_ScoreList, [], _Number) ->
    [];
get_ranks([], _TailList, _Number) ->
    [];
get_ranks(_ScoreList, _TailList, 0) ->
    [];
get_ranks(ScoreList, TailList, Number) ->
    [X|Tail] = TailList,
    {RoleID, Score, _} = X,
    Rank = get_rank(ScoreList, 1, RoleID),
    #r_role_attr{role_name = RoleName, family_name = FamilyName} = common_role_data:get_role_attr(RoleID),
    Info = #p_hb_personal_rank{rank = Rank, name = RoleName, family_name = FamilyName, personal_score = Score},
    NewNumber = Number - 1,
    NewInfo = [Info] ++ get_ranks(ScoreList, Tail, NewNumber),
    NewInfo.

get_family_score([], _FamilyID) ->
    Score = 0,
    Score;
get_family_score(NewFamilyScoreList, FamilyID) ->
    [A|Tail] = NewFamilyScoreList,
    {FamilyID1, Score, _} = A,
    NewScore = case FamilyID =:= FamilyID1 of
                   true ->
                       Score;
                   _ ->
                       NewScore1 = get_family_score(Tail, FamilyID),
                       NewScore1
               end,
    NewScore.

get_family_ranks(_ScoreList, [], _Number) ->
    [];
get_family_ranks([], _TailList, _Number) ->
    [];
get_family_ranks(_ScoreList, _TailList, 0) ->
    [];
get_family_ranks(ScoreList, TailList, Number) ->
    [X|Tail] = TailList,
    {FamilyID, Score, _} = X,
    Rank = get_rank(ScoreList, 1, FamilyID),
%%    Score = get_family_score(ScoreList, FamilyID),
    {FamilyOwnerID, FamilyName} = get_family_owner_info(FamilyID),
    #r_role_attr{role_name = FamilyOwnerName} = common_role_data:get_role_attr(FamilyOwnerID),
    Info = #p_hb_family_rank{rank = Rank, name = FamilyName, family_owner_name = FamilyOwnerName, family_score = Score},
    NewNumber = Number - 1,
    NewInfo = [Info] ++ get_family_ranks(ScoreList, Tail, NewNumber),
    NewInfo.

get_final_personal_reward_list() ->
    ScoreList = world_data:get_act_personal_hunt_boss_score(),
    NewScoreList = sort_score(ScoreList),
    [#c_act_hunt_boss{args2 = Args2}] = lib_config:find(cfg_act_hunt_boss, 4), %% 根据id取个人猎杀BOSS个人奖励获奖人数
    RewardWho = get_top(NewScoreList, Args2),
    RewardWho.

get_top(_NewScoreList, 0) ->
    [];
get_top([], _Number) ->
    [];
get_top(NewScoreList, Number) ->
    [X|Tail] = NewScoreList,
    {ID, _, _} = X,
    NewNumber = Number - 1,
    Info = lists:append([ID], get_top(Tail, NewNumber)),
    Info.

what_kind_of_reward_I_can_get(RoleID, RewardWho) ->
    [X|Tail] = RewardWho,
    RewardID = case X =:= RoleID of
                   true ->
                       NewReward = 1,
                       NewReward;
                   _ ->
                       NewReward = 1 + what_kind_of_reward_I_can_get(RoleID, Tail),
                       NewReward
               end,
    RewardID.

personal_reward_id(1) ->
    Reward_ID = 4,
    Reward_ID;
personal_reward_id(2) ->
    Reward_ID = 5,
    Reward_ID;
personal_reward_id(3) ->
    Reward_ID = 5,
    Reward_ID;
personal_reward_id(4) ->
    Reward_ID = 6,
    Reward_ID;
personal_reward_id(5) ->
    Reward_ID = 6,
    Reward_ID;
personal_reward_id(6) ->
    Reward_ID = 6,
    Reward_ID;
personal_reward_id(7) ->
    Reward_ID = 6,
    Reward_ID;
personal_reward_id(8) ->
    Reward_ID = 6,
    Reward_ID;
personal_reward_id(9) ->
    Reward_ID = 6,
    Reward_ID;
personal_reward_id(10) ->
    Reward_ID = 6,
    Reward_ID;
personal_reward_id(_) ->
    ?ERROR_MSG("猎杀boss奖励id错误").

have_I_got_the_reward(RewardId, RewardList) ->
    TrueOrFalse = lists:keymember(RewardId, #p_kv.id, RewardList),
    TrueOrFalse.

get_final_family_reward_list() ->
    ScoreList = world_data:get_act_family_hunt_boss_score(),
    NewScoreList = sort_score(ScoreList),
    [#c_act_hunt_boss{args2 = Args2}] = lib_config:find(cfg_act_hunt_boss, 1), %% 根据id取个人猎杀BOSS仙盟奖励获奖人数
    RewardWho = get_top(NewScoreList, Args2),
    RewardWho.


family_reward_id(1) ->
    Reward_ID = 1,
    Reward_ID;
family_reward_id(2) ->
    Reward_ID = 2,
    Reward_ID;
family_reward_id(3) ->
    Reward_ID = 2,
    Reward_ID;
family_reward_id(4) ->
    Reward_ID = 3,
    Reward_ID;
family_reward_id(5) ->
    Reward_ID = 3,
    Reward_ID;
family_reward_id(_) ->
    ?ERROR_MSG("仙盟的猎杀boss奖励id错误").

am_I_the_boss(0, _RoleID) ->
    AmITheBoss = false,
    AmITheBoss;
am_I_the_boss(FamilyID, RoleID) ->
    FamilyData = mod_family_data:get_family(FamilyID),
    FamilyOwnerID = family_misc:get_family_owner_id(FamilyData),
    AmITheBoss = (RoleID =:= FamilyOwnerID),
    AmITheBoss.

have_we_not_got_the_reward(FamilyID) -> %这个list 当中有没有可以领奖的ID
    RewardStatus = world_data:get_act_family_hunt_boss_reward_status(),
    TrueOrFalse = not lists:member(FamilyID, RewardStatus),
    TrueOrFalse.

family_reward_status_change(FamilyID) ->
    act_family:family_hunt_boss_reward_list_status_change(FamilyID).

do_handle_boss_hunt_personal_rank_info_tos(RoleID, State) ->    %个人排名榜
    #r_role{role_attr = RoleAttr, role_act_hunt_boss = RoleActHuntBoss} = State,
    #r_role_act_hunt_boss{hunt_boss_score = Score} = RoleActHuntBoss,
    ScoreList = world_data:get_act_personal_hunt_boss_score(), %取得保存的分数表
    NewScoreList = sort_score(ScoreList),
    Rank = get_rank(NewScoreList, 1, RoleID),   %从第一个开始计算自己的排名
    Ranks = get_ranks(NewScoreList, NewScoreList, 20),%取最大20个的排行榜列表
    #r_role_attr{role_name = RoleName, family_name = FamilyName} = RoleAttr,
    common_misc:unicast(RoleID, #m_act_boss_hunt_personal_rank_info_toc{ranks = Ranks, personal_rank = #p_hb_personal_rank{rank = Rank, name = RoleName, family_name = FamilyName, personal_score = Score}}),
    State.

do_handle_boss_hunt_family_rank_info_tos(RoleID, State) ->     %仙盟排名榜
    FamilyScoreList = world_data:get_act_family_hunt_boss_score(), %得到所有仙盟积分的列表
    NewFamilyScoreList = sort_score(FamilyScoreList),   %把这个列表排序
    #r_role{role_attr = RoleAttr} = State,   %得到自己的属性
    #r_role_attr{role_name = RoleName, family_id = FamilyID, family_name = FamilyName} = RoleAttr, % 从属性中取出仙盟id，仙盟名字
    Rank = get_rank(NewFamilyScoreList, 1, FamilyID),   %根据自己仙盟ID得到自己仙盟的排名
    Score = get_family_score(NewFamilyScoreList, FamilyID),    %取自己仙盟的分数
    %如果自己的仙盟id为0,就说明自己没有加入任何的仙盟。
    %取自己仙盟的 盟主的ID
    {FamilyOwnerID, _} = get_family_owner_info(FamilyID),
    ?IF(FamilyOwnerID =/= RoleID, #r_role_attr{role_name = FamilyOwnerName} = common_role_data:get_role_attr(FamilyOwnerID), FamilyOwnerName = RoleName),  %根据自己仙盟盟主的ID取他的名字
    Ranks = get_family_ranks(NewFamilyScoreList, NewFamilyScoreList, 20),  %得到新的排行榜返回信息，最多20个
    common_misc:unicast(RoleID, #m_act_boss_hunt_family_rank_info_toc{ranks = Ranks, family_rank = #p_hb_family_rank{rank = Rank, name = FamilyName, family_owner_name = FamilyOwnerName, family_score = Score}}),
    State.

get_family_owner_info(0) -> %如果自己的familyID为0，说明没有加入任何帮派，那么我们输出的就是familyID 为0，帮会名为空，帮主名为空
    FamilyOwnerID = 0,
    FamilyName = "",
    {FamilyOwnerID, FamilyName};
get_family_owner_info(FamilyID) ->
    FamilyData = #p_family{family_name = FamilyName} = mod_family_data:get_family(FamilyID),
    FamilyOwnerID = family_misc:get_family_owner_id(FamilyData),
    {FamilyOwnerID, FamilyName}.

personal_hunt_boss_score_change(NewScore, RoleID) ->
    ?IF(world_act_server:is_act_open(?ACT_HUNT_BOSS_ID),
        world_act_server:info_mod(?MODULE, {personal_score_change, NewScore, RoleID}),
        ok).


handle({personal_score_change, NewScore, RoleID}) ->
    do_personal_score_change(NewScore, RoleID).

do_personal_score_change(NewScore1, RoleID) ->
    ScoreList = world_data:get_act_personal_hunt_boss_score(),
    Now = time_tool:now(),
    case lists:keyfind(RoleID, 1, ScoreList) of
        {_, _, _} -> %用新分数替换原来的老的个人分
            world_data:set_act_personal_hunt_boss_score(lists:keyreplace(RoleID, 1, ScoreList, {RoleID, NewScore1, Now}));
        _ -> %第一次加分
            world_data:set_act_personal_hunt_boss_score([{RoleID, NewScore1, Now}|ScoreList])
    end.

family_hunt_boss_score_change(FamilyID, Type) ->
    case FamilyID =/= 0 of %如果有仙盟就加仙盟积分
        true ->
            act_family:family_hunt_boss_score_change(FamilyID, Type); %加上仙盟的分数
        _ ->
            ok
    end.

del_family_reward(NewRewardList3) -> % 离开仙盟了，或者不当盟主了就删除个人奖励列表中的道庭奖励
    DelFamilyReward1 = lists:keydelete(1, 1, NewRewardList3),  %去除仙盟第一奖励
    DelFamilyReward2 = lists:keydelete(2, 1, DelFamilyReward1), %去除仙盟第二奖励
    DelFamilyReward3 = lists:keydelete(3, 1, DelFamilyReward2), %去除仙盟第三奖励
    DelFamilyReward3.


gm(State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{family_id = FamilyID}, role_act_hunt_boss = RoleActHuntBoss} = State,
    #r_role_act_hunt_boss{hunt_boss_score = Score, reward_list = RewardList} = RoleActHuntBoss,
    NewScore1 = add_score(1, Score), %得到新的个人分数
    personal_hunt_boss_score_change(NewScore1, RoleID), %个人积分变更
    family_hunt_boss_score_change(FamilyID, 1),  %仙盟积分变更
    Config7 = lib_config:find(cfg_act_hunt_boss, ?ACT_HUNT_BOSS_40_REWARD),
    [#c_act_hunt_boss{args2 = Args7}] = Config7,  %% 40 积分的奖励 id 为7
    FinalRewardList = case NewScore1 >= Args7 of %得出最终的奖励列表
                          true ->
                              NewRewardList = check_reward(?ACT_HUNT_BOSS_40_REWARD, RewardList), %看看能不能获得40积分的奖励
                              ?IF(NewRewardList =/= RewardList, common_misc:unicast(RoleID, #m_role_act_hunt_boss_info_toc{hunt_boss_reward_list = NewRewardList}), ok),
                              [#c_act_hunt_boss{args2 = Args8}] = lib_config:find(cfg_act_hunt_boss, ?ACT_HUNT_BOSS_40_REWARD),  %% 60 积分的奖励 id 为7
                              NewRewardList2 = case NewScore1 >= Args8 of
                                                   true ->
                                                       NewRewardList3 = check_reward(?ACT_HUNT_BOSS_60_REWARD, NewRewardList),  %加60积分奖励
                                                       ?IF(NewRewardList3 =/= RewardList, common_misc:unicast(RoleID, #m_role_act_hunt_boss_info_toc{hunt_boss_reward_list = NewRewardList3}), ok),
                                                       NewRewardList3;
                                                   _ -> %没到60积分
                                                       NewRewardList end,
                              NewRewardList2;
                          _ -> %没到40积分
                              RewardList end,
    NewRoleActHuntBoss = RoleActHuntBoss#r_role_act_hunt_boss{hunt_boss_score = NewScore1, reward_list = FinalRewardList},
    State2 = State#r_role{role_act_hunt_boss = NewRoleActHuntBoss},
    State2.

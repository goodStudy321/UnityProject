%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 十二月 2018 11:40
%%%-------------------------------------------------------------------
-module(mod_marry_tree).
-author("laijichang").
-include("marry.hrl").
-include("global.hrl").
-include("proto/mod_role_marry.hrl").

%% API
-export([
    tree_buy/1,
    tree_reward/2
]).

-export([
    handle/1
]).

-export([
    is_marry_tree_end/1
]).

tree_buy(RoleID) ->
    marry_server:call_mod(?MODULE, {tree_buy, RoleID}).

tree_reward(RoleID, Type) ->
    marry_server:call_mod(?MODULE, {tree_reward, RoleID, Type}).

handle({tree_buy, RoleID}) ->
    do_tree_buy(RoleID);
handle({tree_reward, RoleID, Type}) ->
    do_tree_reward(RoleID, Type);
handle(Info) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]).

%% 购买姻缘树
do_tree_buy(RoleID) ->
    case catch check_tree_buy(RoleID) of
        {ok, CoupleID, DataRecord, MarryData, TreeEndTime2} ->
            mod_marry_data:set_marry_data(MarryData),
            common_letter:send_letter(CoupleID, #r_letter_info{template_id = ?LETTER_TEMPLATE_MARRY_TREE}),
            common_misc:unicast(CoupleID, DataRecord),
            {ok, TreeEndTime2};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_tree_buy(RoleID) ->
    #r_marry_data{couple_id = CoupleID} = mod_marry_data:get_marry_data(RoleID),
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_TREE_BUY_001)),
    #r_marry_data{tree_end_time = TreeEndTime, tree_daily_time = TreeDailyTime} = MarryData = mod_marry_data:get_marry_data(CoupleID),
    ?IF(is_marry_tree_end(TreeEndTime), ok, ?THROW_ERR(?ERROR_MARRY_TREE_BUY_002)),
    [Day] = common_misc:get_global_list(?GLOBAL_MARRY_TREE),
    TreeEndTime2 = time_tool:timestamp(time_tool:timestamp_to_date(time_tool:now())) +  Day * ?ONE_DAY - 1,
    Active = true,
    MarryData2 = MarryData#r_marry_data{
        tree_end_time = TreeEndTime2,
        tree_active_reward = Active
    },
    DataRecord = #m_marry_tree_update_toc{
        tree_end_time = TreeEndTime2,
        tree_active_reward = Active,
        tree_daily_time = TreeDailyTime
    },
    {ok, CoupleID, DataRecord, MarryData2, TreeEndTime2}.

%% 姻缘树奖励
do_tree_reward(RoleID, Type) ->
    case catch check_tree_reward(RoleID, Type) of
        {ok, MarryData, GoodsList, IsActive, TreeDailyTime2} ->
            mod_marry_data:set_marry_data(MarryData),
            {ok, GoodsList, IsActive, TreeDailyTime2};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_tree_reward(RoleID, Type) ->
    #r_marry_data{
        tree_end_time = TreeEndTime,
        tree_active_reward = TreeActiveReward,
        tree_daily_time = TreeDailyTime} = MarryData = mod_marry_data:get_marry_data(RoleID),
    ?IF(is_marry_tree_end(TreeEndTime), ?THROW_ERR(?ERROR_MARRY_TREE_REWARD_001), ok),
    if
        Type =:= ?MARRY_TREE_REWARD -> %% 种树立即获得
            ?IF(TreeActiveReward, ok, ?THROW_ERR(?ERROR_MARRY_TREE_REWARD_002)),
            GoodsList = [#p_goods{type_id = ?ITEM_BIND_GOLD, num = common_misc:get_global_int(?GLOBAL_MARRY_TREE)}],
            IsActive = false,
            TreeDailyTime2 = TreeDailyTime;
        Type =:= ?MARRY_TREE_DAILY ->
            ?IF(time_tool:date() =< time_tool:timestamp_to_date(TreeDailyTime), ?THROW_ERR(?ERROR_MARRY_TREE_REWARD_002), ok),
            GoodsList = [ #p_goods{type_id = TypeID, num = Num}|| {TypeID, Num} <- common_misc:get_global_string_list(?GLOBAL_MARRY_TREE)],
            IsActive = TreeActiveReward,
            TreeDailyTime2 = time_tool:now()
    end,
    MarryData2 = MarryData#r_marry_data{tree_active_reward = IsActive, tree_daily_time = TreeDailyTime2},
    {ok, MarryData2, GoodsList, IsActive, TreeDailyTime2}.

is_marry_tree_end(TreeEndTime) ->
    time_tool:date() > time_tool:timestamp_to_date(TreeEndTime).
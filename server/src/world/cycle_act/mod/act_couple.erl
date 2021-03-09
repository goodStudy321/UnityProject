%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 十月 2019 11:14
%%%-------------------------------------------------------------------
-module(act_couple).
-author("laijichang").
-include("global.hrl").
-include("cycle_act.hrl").
-include("cycle_act_couple.hrl").
-include("proto/mod_role_cycle_act_couple.hrl").

%% API
-export([
    node_up/1,
    role_add_charm/1,

    add_pray_logs/1
]).

-export([
    center_send_data/1,
    center_update_data/1,
    send_rank_reward/1
]).

-export([
    cycle_act_end/0,
    handle/1
]).

node_up(Node) ->
    world_cycle_act_server:info_mod(?MODULE, {node_up, Node}).

role_add_charm(AddList) ->
    world_cycle_act_server:info_mod(?MODULE, {role_add_charm, AddList}).

add_pray_logs(Logs) ->
    world_cycle_act_server:info_mod(?MODULE, {add_pray_logs, Logs}).

center_send_data(List) ->
    world_cycle_act_server:info_mod(?MODULE, {center_send_data, List}).

center_update_data(List) ->
    world_cycle_act_server:info_mod(?MODULE, {center_update_data, List}).

send_rank_reward(RankList) ->
    world_cycle_act_server:info_mod(?MODULE, {send_rank_reward, RankList}).


cycle_act_end() ->
    world_data:set_cycle_act_couple_charm([]),
    world_data:set_cycle_act_couple_pray_logs([]).

handle({node_up, Node}) ->
    do_node_up(Node);
handle(get_center_data) ->
    do_get_center_data();
handle({role_add_charm, AddList}) ->
    do_role_add_charm(AddList);
handle({add_pray_logs, Logs}) ->
    do_add_pray_logs(Logs);
handle({center_send_data, List}) ->
    set_get_center_data(true),
    do_update_data(List);
handle({center_update_data, List}) ->
    do_update_data(List);
handle({send_rank_reward, RankList}) ->
    do_send_rank_reward(RankList);
handle(Info) ->
    ?ERROR_MSG("Unknow Info:~w", [Info]).

%% 中央服连接后，要去请求数据
do_node_up(NodeName) ->
    case common_config:get_center_node() =:= NodeName of
        true ->
            set_get_center_data(false),
            world_act_server:info_mod(?MODULE, get_center_data);
        _ ->
            ok
    end.


%% 游戏服去中央服请求数据
do_get_center_data() ->
    case is_get_center_data() of
        true ->
            ok;
        _ ->
            erlang:send_after(30 * 1000, erlang:self(), {mod, ?MODULE, get_center_data}),
            center_cycle_act_server:game_get_center_data(erlang:date(), node_misc:get_node_id())
    end.

%% 角色送花，加魅力值
do_role_add_charm(AddList) ->
    {Hour, _Min, _Sec} = erlang:time(),
    case world_cycle_act_server:is_act_open(?CYCLE_ACT_COUPLE) andalso Hour =/= 23 of
        true -> %% 23点前送的，才会加上魅力值
            RoleList = world_data:get_cycle_act_couple_charm(),
            Date = erlang:date(),
            {RoleList2, UpLoadList} = do_role_add_charm2(AddList, Date, RoleList, []),
            world_data:set_cycle_act_couple_charm(RoleList2),
            ?INFO_MSG("test:~w", [UpLoadList]),
            ?IF(UpLoadList =/= [], center_cycle_act_server:upload(Date, UpLoadList), ok);
        _ ->
            ok
    end.

do_role_add_charm2([], _Date, RoleList, UploadAcc) ->
    {RoleList, UploadAcc};
do_role_add_charm2([{RoleID, AddCharm}|R], Date, RoleList, UploadAcc) ->
    {CoupleCharm2, RoleList2} =
        case lists:keytake(RoleID, #r_cycle_act_couple_charm.role_id, RoleList) of
            {value, #r_cycle_act_couple_charm{} = CoupleCharm, RoleListT} ->
                #r_cycle_act_couple_charm{
                    charm = OldCharm,
                    date = OldDate
                } = CoupleCharm,
                CoupleCharmT = ?IF(Date =:= OldDate,
                    CoupleCharm#r_cycle_act_couple_charm{charm = OldCharm + AddCharm},
                    CoupleCharm#r_cycle_act_couple_charm{date = Date, charm = AddCharm}),
                {CoupleCharmT, RoleListT};
            _ ->
                CoupleCharmT = #r_cycle_act_couple_charm{role_id = RoleID, date = Date, charm = AddCharm},
                {CoupleCharmT, RoleList}
        end,
    UploadAcc2 = get_upload(Date, CoupleCharm2) ++ UploadAcc,
    RoleList3 = [CoupleCharm2|RoleList2],
    do_role_add_charm2(R, Date, RoleList3, UploadAcc2).

do_add_pray_logs(AddLogs) ->
    Logs = world_data:get_cycle_act_couple_pray_logs(),
    Len = common_misc:get_global_int(?GLOBAL_CYCLE_ACT_COUPLE_PRAY),
    Logs2 = lists:sublist(AddLogs ++ Logs, Len),
    world_data:set_cycle_act_couple_pray_logs(Logs2),
    DataRecord = #m_cycle_act_couple_pray_log_toc{add_logs = AddLogs},
    [#c_cycle_act{level = NeedLevel}] = lib_config:find(cfg_cycle_act, ?CYCLE_ACT_COUPLE),
    common_broadcast:bc_record_to_world_by_condition(DataRecord, #r_broadcast_condition{min_level = NeedLevel}).

%% 更新排行数据
do_update_data(List) ->
    [global_data:set_cycle_act_couple_rank(Key, Value) || {Key, Value} <- List].

%% 发送排行奖励
do_send_rank_reward(RankList) ->
    #r_cycle_act{config_num = ConfigNum} = world_cycle_act_server:get_act(?CYCLE_ACT_COUPLE),
    ConfigList = [ Config || {_, #c_cycle_act_couple_charm{config_num = ConfigNumT} = Config} <- lib_config:list(cfg_cycle_act_couple_charm), ConfigNumT =:= ConfigNum],
    [begin
         case db:lookup(?DB_ROLE_ATTR_P, RoleID) of
             [_RoleAttr] ->
                 ?WARNING_MSG("couple rank reward : ~w", [{RoleID, Rank}]),
                 ?TRY_CATCH(do_send_rank_reward2(RoleID, Rank, ConfigList));
             _ ->
                 ok
         end
     end || #r_charm_rank{role_id = RoleID, rank = Rank} <- RankList].

do_send_rank_reward2(RoleID, Rank, ConfigList) ->
    GoodsList = get_rank_goods(Rank, ConfigList),
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_CYCLE_ACT_COUPLE_CHARM,
        text_string = [lib_tool:to_list(Rank)],
        action = ?ITEM_GAIN_CYCLE_ACT_COUPLE_CHARM,
        goods_list = GoodsList
    },
    common_letter:send_letter(RoleID, LetterInfo).

get_rank_goods(_Rank, []) ->
    [];
get_rank_goods(Rank, [#c_cycle_act_couple_charm{rank = [MinRank, MaxRank], reward = Reward}|R]) ->
    case MinRank =< Rank andalso Rank =< MaxRank of
        true ->
            common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward));
        _ ->
            get_rank_goods(Rank, R)
    end.

get_upload(Date, CoupleCharm) ->
    #r_cycle_act_couple_charm{role_id = RoleID, charm = NowCharm} = CoupleCharm,
    case NowCharm >= common_misc:get_global_int(?GLOBAL_CYCLE_ACT_COUPLE_CHARM) of
        true ->
            case common_role_data:get_role_attr(RoleID) of
                #r_role_attr{role_name = RoleName} = RoleAttr when RoleName =/= "" ->
                    #r_role_attr{
                        category = Category,
                        sex = Sex
                        } = RoleAttr,
                    case center_cycle_act_server:is_rank_update(RoleID, NowCharm, global_data:get_cycle_act_couple_rank({Date, Sex})) of
                        true -> %% 需要更新数据
                            [#r_charm_rank{
                                role_id = RoleID,
                                role_name = RoleName,
                                category = Category,
                                sex = Sex,
                                charm = NowCharm,
                                server_name = common_config:get_server_name(),
                                update_time = time_tool:now()
                            }];
                        _ ->
                            []
                    end;
                _ ->
                    []
            end;
        _ ->
            []
    end.

is_get_center_data() ->
    erlang:get({?MODULE, get_center_data}) =:= true.
set_get_center_data(Flag) ->
    erlang:put({?MODULE, get_center_data}, Flag).
%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     充值服务
%%% @end
%%% Created : 11. 六月 2018 10:15
%%%-------------------------------------------------------------------
-module(world_pay_server).
-author("laijichang").
-include("global.hrl").
-include("pay.hrl").
-include("platform.hrl").

%% API
-export([
    start/0,
    start_link/0
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    info/1,
    call/1
]).

-export([
    pay/1,
    role_online/1,
    role_pay/2,
    get_order_id/0
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).

pay(PayArgs) ->
    call({pay, PayArgs}).

role_online(RoleID) ->
    info({role_online, RoleID}).

role_pay(RoleID, OrderID) ->
    call({role_pay, RoleID, OrderID}).

get_order_id() ->
    call(get_order_id).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    world_data:init_pay_order_id(),
    do_init(),
    {ok, []}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({role_online, RoleID}) ->
    do_online(RoleID);
do_handle({pay, PayArgs}) ->
    do_pay(PayArgs);
do_handle({role_pay, RoleID, OrderID}) ->
    do_role_pay(RoleID, OrderID);
do_handle(get_order_id) ->
    do_get_order_id();
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_init() ->
    [begin
         #r_pay_log{order_id = OrderID, is_finish = IsFinish, role_id = RoleID} = PayLog,
         case IsFinish of
             false ->
                 add_role_order(RoleID, OrderID);
             _ ->
                 ignore
         end
     end || PayLog <- db_lib:all(?DB_PAY_LOG_P)],
    ok.

%% @doc 玩家上线则处理充值
do_online(RoleID) ->
    case get_role_order(RoleID) of
        [_|_] = Orders ->
            [mod_role_pay:role_pay(RoleID, OrderID) || OrderID <- Orders],
            ok;
        _ ->
            ignore
    end.

%% @doc 玩家充值
do_pay(PayArgs) ->
    #r_pay_args{
        order_id = OrderID,
        pf_order_id = PFOrderID,
        role_id = RoleID,
        product_id = ProductID,
        total_fee = PayFee} = PayArgs,
    ?WARNING_MSG("收到充值请求: OrderID:~w, RoleID:~w, ProductID:~w, PayFee:~w", [OrderID, RoleID, ProductID, PayFee]),
    case catch do_pay_check(OrderID, RoleID, ProductID, PayFee) of
        {ok, RoleAttr, RolePrivateAttr} ->
            Now = time_tool:now(),
            PayLog = #r_pay_log{
                order_id = OrderID,
                pf_order_id = PFOrderID,
                is_finish = false,
                role_id = RoleID,
                time = Now,
                product_id = ProductID,
                total_fee = PayFee},
            db:insert(?DB_PAY_LOG_P, PayLog),
            add_role_order(RoleID, OrderID),
            mod_role_pay:role_pay(RoleID, OrderID),
            ?TRY_CATCH(log_role_pay(OrderID, PFOrderID, ProductID, PayFee, RoleAttr, RolePrivateAttr)),
            ?TRY_CATCH(mod_role_pf:pay_log(OrderID, PFOrderID, PayFee, RoleAttr, RolePrivateAttr), Err2),
            ok;
        oredr_is_exist ->
            ok;
        Error ->
            ?ERROR_MSG("充值出错 Reason: ~w", [Error]),
            {error, Error}
    end.
%% @doc 检查订单号
do_pay_check(OrderID, RoleID, ProductID, PayFee) ->
    case db:lookup(?DB_PAY_LOG_P, OrderID) of
        [] ->
            ok;
        _ ->
            erlang:throw(oredr_is_exist)
    end,
    [#c_pay{pay_money = PayMoney}] = lib_config:find(cfg_pay, ProductID),
    ?IF(PayMoney * 100 =:= PayFee, ok, erlang:throw(pay_fee_not_valid)),
    RoleAttr =
        case common_role_data:get_role_attr(RoleID) of
            #r_role_attr{} = RoleAttrT ->
                RoleAttrT;
            _ ->
                erlang:throw(role_not_exist)
        end,
    [RolePrivateAttr] = db:lookup(?DB_ROLE_PRIVATE_ATTR_P, RoleID),
    {ok, RoleAttr, RolePrivateAttr}.

do_role_pay(RoleID, OrderID) ->
    case db:lookup(?DB_PAY_LOG_P, OrderID) of
        [#r_pay_log{is_finish = false, role_id = RoleID, product_id = ProductID, pf_order_id = PFOrderID, total_fee = TotalFee} = PayLog] ->
            db:insert(?DB_PAY_LOG_P, PayLog#r_pay_log{is_finish = true}),
            del_role_order(RoleID, OrderID),
            {ok, PFOrderID, ProductID, TotalFee};
        PayLog ->
            ?ERROR_MSG("充值订单非法 RoleID:~p,PayLog:~p", [RoleID, PayLog]),
            del_role_order(RoleID, OrderID),
            error
    end.

do_get_order_id() ->
    OrderID = world_data:update_pay_order_id(),
    {ok, OrderID}.

%%%===================================================================
%%% 数据操作
%%%===================================================================
add_role_order(RoleID,OrderID) ->
    Orders = get_role_order(RoleID),
    case lists:member(OrderID, Orders) of
        true ->
            ignore;
        _ ->
            erlang:put({?MODULE,RoleID},lists:reverse([OrderID|Orders]))
    end.
del_role_order(RoleID,OrderID) ->
    Orders = get_role_order(RoleID),
    erlang:put({?MODULE,RoleID},lists:delete(OrderID,Orders)).
get_role_order(RoleID) ->
    case erlang:get({?MODULE, RoleID}) of
        [_|_] = Orders ->
            Orders;
        _ ->
            []
    end.

log_role_pay(OrderID, PFOrderID, ProductID, PayFee, RoleAttr, RolePrivateAttr) ->
    #r_role_attr{
        role_id = RoleID,
        account_name = AccountName,
        level = RoleLevel,
        uid = UID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    PayTimes = get_role_pay_times(RoleID),
    #r_role_private_attr{
        imei = IMEI
    } = RolePrivateAttr,
    [#c_pay{add_gold = AddGold}] = lib_config:find(cfg_pay, ProductID),
    Log =
        #log_role_pay{
            role_id = RoleID,
            account_name = AccountName,
            imei = IMEI,
            order_id = OrderID,
            pf_order_id = PFOrderID,
            product_id = ProductID,
            pay_fee = PayFee,
            pay_gold = AddGold,
            role_level = RoleLevel,
            uid = UID,
            pay_times = PayTimes,
            channel_id = ChannelID,
            game_channel_id = GameChannelID
        },
    background_misc:log(Log).

get_role_pay_times(RoleID) ->
    AllPayLog = db:table_all(?DB_PAY_LOG_P),
    get_role_pay_times2(AllPayLog, RoleID, 0).

get_role_pay_times2([], _RoleID, TimesAcc) ->
    TimesAcc;
get_role_pay_times2([#r_pay_log{role_id = PayRoleID}|R], RoleID, TimesAcc) ->
    TimesAcc2 = ?IF(PayRoleID =:= RoleID, TimesAcc + 1, TimesAcc),
    get_role_pay_times2(R, RoleID, TimesAcc2).

% get_modify_pay_fee(RoleAttr, ProductID, TotalFee) ->
%     #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
%     case lists:member(GameChannelID, [?PENGCHAO_IOS_GAME_CHANNEL_ID, ?PENGCHAO_AND_GAME_CHANNEL_ID])
%         orelse lists:member(ChannelID, [?IOS_GAT_CHANNEL_ID, ?AND_GAT_CHANNEL_ID]) of
%         true -> %% 部分包渠道或渠道，传的金额是打折金额，用ProductID对应的金额
%             [#c_pay{pay_money = PayMoney}] = lib_config:find(cfg_pay, ProductID),
%             lib_tool:ceil(PayMoney * 100);
%         _ ->
%             TotalFee
%     end.
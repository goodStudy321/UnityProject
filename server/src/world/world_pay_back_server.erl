%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     内测充值返利
%%% @end
%%% Created : 26. 二月 2019 16:38
%%%-------------------------------------------------------------------
-module(world_pay_back_server).
-author("laijichang").
-include("global.hrl").
-include("pay.hrl").

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
    data_init/1,
    role_create/3,
    info/1
]).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% [{{GameChannelID, UID}, Gold}|....]
%% 注意UID是字符串！！
data_init(List) ->
    info({data_init, List}).

role_create(RoleID, GameChannelID, UID) ->
    info({role_create, RoleID, GameChannelID, UID}).

info(Info) ->
    pname_server:send(?MODULE, Info).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    time_tool:reg(world, [0]),
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
do_handle(?TIME_ZERO) ->
    do_zero();
do_handle({data_init, List}) ->
    do_data_init(List);
do_handle({role_create, RoleID, GameChannelID, UID}) ->
    do_role_create(RoleID, GameChannelID, UID);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_zero() ->
    OpenDays = common_config:get_open_days(),
    List = world_data:get_pay_back_list(),
    List2 =
        lists:foldl(
            fun(PayBack, Acc) ->
                #r_pay_back{
                    role_id = RoleID,
                    gold = Gold,
                    send_open_days = SendOpenDays
                } = PayBack,
                case RoleID > 0 andalso OpenDays >= SendOpenDays of
                    true -> %% 有奖励并且可以发放
                        BackGold = lib_tool:ceil(Gold * 1.5),
                        GoodsList = [#p_goods{type_id = ?ITEM_GOLD, num = BackGold}],
                        LetterInfo = #r_letter_info{
                            template_id = ?LETTER_TEMPLATE_PAY_BACK,
                            action = ?ITEM_GAIN_PAY_BACK,
                            goods_list = GoodsList
                        },
                        common_letter:send_letter(RoleID, LetterInfo),
                        Acc;
                    _ ->
                        [PayBack|Acc]
                end
            end, [], List),
    world_data:set_pay_back_list(List2).

%% [{{GameChannelID, UID}, Gold}|....]
%%
do_data_init(List) ->
    List2 = [ #r_pay_back{key = Key, gold = Gold}|| {Key, Gold} <- List],
    world_data:set_pay_back_list(List2).

do_role_create(RoleID, GameChannelID, UID) ->
    List = world_data:get_pay_back_list(),
    Key = {GameChannelID, UID},
    case lists:keytake(Key, #r_pay_back.key, List) of
        {value, #r_pay_back{role_id = HasRoleID} = PayBack, List2} when HasRoleID =:= 0 -> %% 第一个帐号触发
            OpenDays = common_config:get_open_days(),
            SendOpenDays = ?IF(OpenDays > 7, OpenDays + 2, 8),
            PayBack2 = PayBack#r_pay_back{role_id = RoleID, send_open_days = SendOpenDays},
            world_data:set_pay_back_list([PayBack2|List2]),
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_TIP_PAY_BACK
            },
            common_letter:send_letter(RoleID, LetterInfo);
        _ ->
            ok
    end.

%%%===================================================================
%%% data
%%%===================================================================

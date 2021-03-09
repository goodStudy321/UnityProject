%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 聊天历史记录
%%% @end
%%% Created : 03. 六月 2019 15:43
%%%-------------------------------------------------------------------
-module(world_chat_history_server).
-author("huangxiangrui").
-include("db.hrl").
-include("common.hrl").
-include("broadcast.hrl").
-include("mod_role_chat.hrl").
-include("world_chat_history_server.hrl").

%% API
-export([
    i/1,
    init/1,
    start/0,
    start_link/0
]).

-export([
    handle/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([get_role_info/1]).

-export([
    to_p_chat_history/1,
    add_chat_history/3,
    del_history/2,
    online_send_chat_history/2
]).

-record(state, {}).

-define(HISTORY_RECORD_COUNT, 30).  % 聊天历史记录总数

-define(HISTORY_POSITION, [?CHAT_CHANNEL_WORLD]).  % 要记录的频道

%% @doc 调试打印
i(ID) ->
    [chat_history, get_role_info(ID)].

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc 初始化
init([]) ->
    erlang:process_flag(trap_exit, true),
%%    time_tool:reg(world, [1000, 0]), % 秒循环和零点
    {ok, #state{}}.


handle(Info) ->
    do_handle(Info).

%% @doc handle_call回调函数
handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

%% @doc handle_cast回调函数
handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%% @doc handle_info回调函数
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%% @doc terminate回调函数
terminate(_Reason, _State) ->
    ok.

%% @doc code_change回调函数
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% @doc mod调用
do_handle({mod, Module, Info}) ->
    Module:handle(Info);
%% @doc 用参数调用模块的函数
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
%% @doc 调用函数
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
%% @doc 秒循环
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now);
%% @doc 零点
do_handle(zeroclock) ->
    ok;
do_handle({increase_chat_history, MyRoleID, ChannelType, ChatHistory}) ->
    do_increase_chat_history(MyRoleID, ChannelType, ChatHistory);
do_handle({del_history, ID, ChannelType}) ->
    do_del_history(ID, ChannelType);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

del_history(ID, ChannelType) ->
    pname_server:send(?MODULE, {del_history, ID, ChannelType}).
add_chat_history(MyRoleID, ChannelType, ChatHistory) ->
    pname_server:send(?MODULE, {increase_chat_history, MyRoleID, ChannelType, to_p_chat_history(ChatHistory)}).

%% @doc 记录聊天历史
%% 个人好友聊天记录
%% chat_history = [{channel_type,[#p_chat_history{}]}|...]
do_increase_chat_history(MyRoleID, ?CHAT_CHANNEL_PRIVATE, ChatHistory) ->
    case ChatHistory of
        #p_chat_history{channel_id = ChannelID} ->
            ignore;
        #p_pos_history{channel_id = ChannelID} ->
            ignore
    end,
    #r_chat_history{chat_history = ChatHistoryLists} = RChatHistory = get_role_info(MyRoleID),
    case lists:keytake(?CHAT_CHANNEL_PRIVATE, 1, ChatHistoryLists) of
        {value, {_, HistoryList}, TupleList2} ->
            ok;
        _ ->
            HistoryList = [],
            TupleList2 = ChatHistoryLists
    end,
    case lists:filter(fun(
        #p_chat_history{channel_id = InnerChannelID}) ->
        InnerChannelID =:= ChannelID;
        (#p_pos_history{channel_id = InnerChannelID}) ->
            InnerChannelID =:= ChannelID end, HistoryList) of
        [_ | _] = L ->
            RetLists = HistoryList -- L,
            InnerHistoryList = lists:sublist([ChatHistory | L], ?HISTORY_RECORD_COUNT);
        _ ->
            RetLists = HistoryList,
            InnerHistoryList = [ChatHistory]
    end,
    set_role_info(RChatHistory#r_chat_history{chat_history = [{?CHAT_CHANNEL_PRIVATE, InnerHistoryList ++ RetLists} | TupleList2]});

%% @doc 道庭聊天历史
do_increase_chat_history(FamilyID, ?CHAT_CHANNEL_FAMILY, ChatHistory) ->
    #r_chat_history{chat_history = ChatHistoryLists} = RChatHistory = get_role_info(FamilyID),
    InnerHistoryList = lists:sublist([ChatHistory | ChatHistoryLists], ?HISTORY_RECORD_COUNT),
    set_role_info(RChatHistory#r_chat_history{chat_history = InnerHistoryList});

%% 公共聊天记录
%% chat_history = [[#p_chat_history{}]|...]
do_increase_chat_history(ChannelType, ChannelType, ChatHistory) ->
    #r_chat_history{chat_history = ChatHistoryLists} = RChatHistory = get_role_info(ChannelType),
    InnerHistoryList = lists:sublist([ChatHistory | ChatHistoryLists], ?HISTORY_RECORD_COUNT),
    set_role_info(RChatHistory#r_chat_history{chat_history = InnerHistoryList}).

%% @doc 发送聊天历史
%%online_send_chat_history(RoleID, FamilyID) ->
%%    #r_chat_history{chat_history = _ChatHistoryLists} = get_role_info(RoleID),
%%    case lists:keyfind(?CHAT_CHANNEL_PRIVATE, 1, ChatHistoryLists) of
%%        {_, HistoryList} ->
%%            ok;
%%        _ ->
%%            HistoryList = []
%%    end,
%%    {History, History1} =
%%        lists:foldl(fun(Position, {Acc, Acc1}) ->
%%            #r_chat_history{chat_history = L} = get_role_info(Position),
%%            Lists = [H || H <- L, erlang:is_record(H, p_chat_history)],
%%            Lists1 = [H || H <- L, erlang:is_record(H, p_pos_history)],
%%            {Lists ++ Acc, Lists1 ++ Acc1} end, {[], []}, [FamilyID] ++ ?HISTORY_POSITION),
%%    {FriendHistory, FriendHistory1} =
%%        lists:foldl(fun(ChatHistory, {Acc, Acc1}) ->
%%            case ChatHistory of
%%                #p_chat_history{channel_id = ChannelID} ->
%%                    case world_friend_server:is_friend(RoleID, ChannelID)
%%                        orelse world_friend_server:is_black(RoleID, ChannelID)
%%                        orelse world_friend_server:is_chat(RoleID, ChannelID) of
%%                        true ->
%%                            {[ChatHistory | Acc], Acc1};
%%                        _ ->
%%                            {Acc, Acc1}
%%                    end;
%%                #p_pos_history{channel_id = ChannelID} ->
%%                    case world_friend_server:is_friend(RoleID, ChannelID)
%%                        orelse world_friend_server:is_black(RoleID, ChannelID)
%%                        orelse world_friend_server:is_chat(RoleID, ChannelID) of
%%                        true ->
%%                            {Acc, [ChatHistory | Acc1]};
%%                        _ ->
%%                            {Acc, Acc1}
%%                    end
%%            end end, {[], []}, HistoryList),
%%    common_misc:unicast(RoleID, #m_world_chat_history_toc{chat_list = History ++ FriendHistory, pos_list = History1 ++ FriendHistory1}).

online_send_chat_history(RoleID, _FamilyID) ->
    common_misc:unicast(RoleID, #m_world_chat_history_toc{chat_list = [], pos_list = []}).


%% @doc 道庭解散
do_del_history(FamilyID, ?CHAT_CHANNEL_FAMILY) ->
    del_role_info(FamilyID);
do_del_history(_, _) ->
    ok.

to_p_chat_history(#m_chat_text_toc{
    channel_type = ChannelType,
    channel_id = ChannelID,
    role_info = ChatRole,
    voice_sec = VoiceSec,
    msg = ReplaceMsg,
    goods_list = GoodsList,
    time = Time,
    voice_url = VoiceURL}) ->
    #p_chat_history{
        channel_type = ChannelType,
        channel_id = ChannelID,
        role_info = ChatRole,
        voice_sec = VoiceSec,
        msg = ReplaceMsg,
        goods_list = GoodsList,
        time = Time,
        voice_url = VoiceURL};
to_p_chat_history(#m_chat_pos_toc{
    channel_type = ChannelType,
    channel_id = ChannelID,
    role_info = ChatRole,
    pos = Pos,
    map_id = MapID,
    time = Now}) ->
    #p_pos_history{
        channel_type = ChannelType,
        channel_id = ChannelID,
        role_info = ChatRole,
        map_id = MapID,
        pos = Pos,
        time = Now}.

%%%===================================================================
%%% 数据操作
%%%===================================================================
set_role_info(ChatHistory) ->
    db:insert(?DB_CHAT_HISTORY_P, ChatHistory).
del_role_info(TypeID) ->
    db:delete(?DB_CHAT_HISTORY_P, TypeID).
get_role_info(RoleOrTypeID) ->
    case db:lookup(?DB_CHAT_HISTORY_P, RoleOrTypeID) of
        [#r_chat_history{} = ChatHistory] ->
            ChatHistory;
        _ ->
            #r_chat_history{role_or_type_id = RoleOrTypeID}
    end.

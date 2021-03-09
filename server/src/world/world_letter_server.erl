%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 七月 2017 15:05
%%%-------------------------------------------------------------------
-module(world_letter_server).
-author("laijichang").
-include("letter.hrl").
-include("proto/mod_role_letter.hrl").

-behaviour(gen_server).

%% External exports
-export([
    role_get_letter/1,
    send_letter/8,
    del_gm_letter/1
]).

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
    get_world_letter/1,
    set_world_letter/1
]).

%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

role_get_letter(RoleID) ->
    call({role_get_letter, RoleID}).

send_letter(RoleID, TemplateID, Action, GoodsList, Days, Condition, TitleString, TextString) ->
    info({send_letter, RoleID, TemplateID, Action, GoodsList, Days, Condition, TitleString, TextString}).

del_gm_letter(WebID) ->
    info({del_gm_letter, WebID}).

info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).

%% ====================================================================
%% Server functions
%% ====================================================================

init([]) ->
    erlang:process_flag(trap_exit, true),
    del_world_end_time_letter(),
    case db:lookup(?DB_WORLD_LETTER_P, ?GM_MAIL_ID) of
        [_GMLetter] ->
            ok;
        _ ->
            set_world_letter(#r_world_letter{role_id = ?GM_MAIL_ID})
    end,
    del_role_end_time_letter(),
    {ok, []}.

handle_call(Request, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Request, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(Reason, State) ->
    {stop, Reason, State}.

code_change(_Request, State, _Code) ->
    {ok, State}.

%% ====================================================================
%%% Internal functions
%% ====================================================================
do_handle(del_world_end_time_letter) ->
    del_world_end_time_letter();
do_handle({role_get_letter, RoleID}) ->
    do_role_get_letter(RoleID);
do_handle({send_letter, RoleID, TemplateID, Action, GoodsList, Days, Condition, TitleString, TextString}) ->
    do_send_letter(RoleID, TemplateID, Action, GoodsList, Days, Condition, TitleString, TextString);
do_handle({del_gm_letter, WebID}) ->
    do_del_gm_letter(WebID);
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?INFO_MSG("world_letter_server收到未知的info消息:~w", [Info]).

%% 服务器重启时遍历角色信件数据库,删除过期信件,删除不存在的gm_mail_list
del_role_end_time_letter() ->
    #r_world_letter{receive_box = GMReceiveBox} = get_world_letter(?GM_MAIL_ID),
    MailIDList = [ LetterID || #r_letter{id = LetterID} <- GMReceiveBox],
    Now = time_tool:now(),
    Table = ?DB_ROLE_LETTER_P,
    List =
        [begin
             ReceiveBox = [Letter || Letter <- RoleLetter#r_role_letter.receive_box, Letter#r_letter.end_time >= Now],
             RoleLetter#r_role_letter{receive_box = ReceiveBox, gm_id_list = GMIDList -- (GMIDList -- MailIDList)}
         end || #r_role_letter{gm_id_list = GMIDList} = RoleLetter <- db:table_all(Table)],
    db:insert(Table, List).

%% 遍历世界信件数据库,删除过期信件
del_world_end_time_letter() ->
    erlang:send_after(?WORLD_LETTER_CHECK_CD * 1000, erlang:self(), del_world_end_time_letter),
    Now = time_tool:now(),
    Table = ?DB_WORLD_LETTER_P,
    List =
        [ begin
              ReceiveBox = [Letter || Letter <- WorldLetter#r_world_letter.receive_box, Letter#r_letter.end_time >= Now],
              WorldLetter#r_world_letter{receive_box = ReceiveBox}
          end || WorldLetter <- db:table_all(?DB_WORLD_LETTER_P)],
    db:insert(Table, List).

%%角色上线检查信箱里的过期信件,返回server存储的信件 || 角色call处理
do_role_get_letter(RoleID) ->
    WorldLetter = get_world_letter(RoleID),
    ReceiveBox = WorldLetter#r_world_letter.receive_box,
    set_world_letter(WorldLetter#r_world_letter{receive_box = []}),
    {ok, ReceiveBox}.

do_send_letter(RoleID, TemplateID, Action, GoodsList, Days, Condition, TitleString, TextString) ->
    WorldLetter = get_world_letter(RoleID),
    do_send_letter2(RoleID, WorldLetter, TemplateID, Action, GoodsList, Days, Condition, TitleString, TextString).

do_send_letter2(RoleID, WorldLetter, TemplateID, Action, GoodsList, Days, Condition, TitleString, TextString) ->
    #r_world_letter{counter = Counter, receive_box = ReceiveBox} = WorldLetter,
    {GoodsList2, RemainList} = lib_tool:split(?ONE_LETTER_ITEM_NUM, GoodsList),
    SendTime = time_tool:now(),
    EndTime = SendTime + Days * 24 * 60 * 60,
    Counter2 = Counter + 1,
    Letter = #r_letter{
        id = Counter2,
        letter_state = ?LETTER_NOT_OPEN,
        send_time = SendTime,
        end_time = EndTime,
        template_id = TemplateID,
        condition = Condition,
        title_string = TitleString,
        text_string = TextString,
        action = Action,
        goods_list = GoodsList2},
    WorldLetter2 = WorldLetter#r_world_letter{receive_box = ReceiveBox ++ [Letter], counter = Counter2},
    case RemainList =/= [] of
        true ->
            do_send_letter2(RoleID, WorldLetter2, TemplateID, Action, RemainList, Days, Condition, TitleString, TextString);
        _ ->
            set_world_letter(WorldLetter2),
            case RoleID of
                ?GM_MAIL_ID ->
                    common_broadcast:bc_role_info_to_world({mod, mod_role_letter, gm_letter});
                _ ->
                    common_misc:unicast(RoleID, #m_letter_light_toc{})
            end
    end.

do_del_gm_letter(WebID) ->
    #r_world_letter{receive_box = ReceiveList} = GMLetter = get_world_letter(?GM_MAIL_ID),
    ReceiveList2 =
        lists:foldl(
            fun(Letter, Acc) ->
                #r_letter{condition = #r_gm_condition{id = LetterWebID}} = Letter,
                ?IF(LetterWebID =:= WebID, Acc, [Letter|Acc])
            end, [], ReceiveList),
    set_world_letter(GMLetter#r_world_letter{receive_box = ReceiveList2}).

%% 获取玩家在server的mailbox
get_world_letter(RoleID) ->
    case db:lookup(?DB_WORLD_LETTER_P, RoleID) of
        [WorldLetter] -> WorldLetter;
        _ -> #r_world_letter{role_id = RoleID}
    end.

set_world_letter(#r_world_letter{} = WorldLetter) ->
    db:insert(?DB_WORLD_LETTER_P, WorldLetter).


%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 十二月 2019 14:08
%%%-------------------------------------------------------------------
-module(update_12).
-author("WZP").
-include("db.hrl").
-include("role.hrl").
-include("family.hrl").
-include("bg_act.hrl").
-include("platform.hrl").

%% API
-export([
    update_game/0,
    update_cross/0,
    update_center/0
]).

-export([
    update_bg_act/1
]).

%% 游戏节点数据更新
update_game() ->
    List = [
        {?DB_R_BG_ACT_P, update_bg_act}
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 跨服节点数据更新
update_cross() ->
    List = [
    ],
    update_common:data_update(?MODULE, List),
    ok.

%% 中央服数据更新
update_center() ->
    List = [
    ],
    update_common:data_update(?MODULE, List),
    ok.



update_bg_act(BgActList) ->
    case BgActList of
        [BgAct|_] ->
            ?ERROR_MSG("------------------~w~n", [BgActList]),
            case BgAct of
                {r_bg_act, _ID, _WorldLevel, _Is_gm_set, _Template, _Edit_time, _Start_time, _End_time, _Start_date, _End_date, _Start_day_time, _End_day_time, _Status,
                 _Is_visible, _Icon, _Icon_name, _Channel_id, _Game_channel_id, _Title, _Min_level, _Explain, _Explain_i, _Background_img, _Bc_pid, _Sort, _Config_list, _Config} ->
                    ibrowse_sup:start_link(),
                    Now = time_tool:now(),
                    ServerID = common_config:get_server_id(),
                    AgentID = common_config:get_agent_id(),
                    Url = web_misc:get_web_url(?BG_ACT_URL),
                    Ticket = web_misc:get_key(Now),
                    Body = [
                        {agent_id, AgentID},
                        {server_id, ServerID},
                        {time, Now},
                        {ticket, Ticket}
                    ],
                    KvList = case ibrowse:send_req(Url, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 2000) of
                                 {ok, "200", _Headers2, Body2} ->
                                     {_, Data} = mochijson2:decode(Body2),
                                     DataList = proplists:get_value(lib_tool:to_binary("data"), Data),
                                     ?ERROR_MSG("------------------~w~n", [DataList]),
                                     [
                                         begin
                                             Type = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("type"), DataList2)),
                                             BgID = lib_tool:to_integer(proplists:get_value(lib_tool:to_binary("id"), DataList2)),
                                             {Type, BgID}
                                         end
                                         || {struct, DataList2} <- DataList];
                                 _Reason ->
                                     []
                             end,
                    ?ERROR_MSG("------------KvList------~w~n", [KvList]),
                    lists:foldl(fun(BgAct1, UpdateList) ->
                        case BgAct1 of
                            {r_bg_act, ID, WorldLevel, Is_gm_set, Template, Edit_time, Start_time, End_time, Start_date, End_date, Start_day_time, End_day_time, Status,
                             Is_visible, Icon, Icon_name, Channel_id, Game_channel_id, Title, Min_level, Explain, Explain_i, Background_img, Bc_pid, Sort, Config_list, Config} ->
                                case lists:keyfind(ID, 1, KvList) of
                                    false ->
                                        db:delete(?DB_R_BG_ACT_P, ID),
                                        UpdateList;
                                    {_, BgId} ->
                                        NewBgAct = {r_bg_act, ID, BgId, WorldLevel, Is_gm_set, Template, Edit_time, Start_time, End_time, Start_date, End_date, Start_day_time, End_day_time, Status,
                                                    Is_visible, Icon, Icon_name, Channel_id, Game_channel_id, Title, Min_level, Explain, Explain_i, Background_img, Bc_pid, Sort, Config_list, Config},
                                        [NewBgAct|UpdateList]
                                end;
                            _ ->
                                UpdateList
                        end
                                end, [], BgActList);
                _ ->
                    BgActList
            end;
        _ ->
            []
    end.





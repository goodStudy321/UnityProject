%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     平台通用接口
%%% @end
%%% Created : 09. 三月 2018 12:02
%%%-------------------------------------------------------------------
-module(common_pf).
-author("laijichang").
-include("global.hrl").
-include("platform.hrl").

%% Agent相关参数
%% API
-export([
    pf_log/1,
    online_log/1,
    get_common_mod/0
]).

%% 包渠道相关参数
-export([
    get_role_mod/2,
    get_pf_agent_id/0,

    is_junhai_ios_game_channel_id/1,

    is_log_ios/2
]).

-export([
    is_agent_guild/0
]).

pf_log(Logs) ->
    execute_common_mod(pf_log, [Logs]).

online_log(GameChannelList) ->
    execute_common_mod(online_log, [GameChannelList]).

execute_common_mod(Fun, Args) ->
    Mod = common_pf:get_common_mod(),
    case erlang:function_exported(Mod, Fun, erlang:length(Args)) of
        true ->
            erlang:apply(Mod, Fun, Args);
        _ ->
            not_exist
    end.

get_common_mod() ->
    AgentID = get_pf_agent_id(),
    case lists:keyfind(AgentID, #c_agent_mod.agent_id, ?PLATFORM_AGENT_MOD_LIST) of
        #c_agent_mod{common_mod = CommonMod} ->
            CommonMod;
        _ ->
            undefined
    end.

get_pf_agent_id() ->
    AgentID = common_config:get_agent_id(),
    modify_agent_id(AgentID).

modify_agent_id(AgentID) ->
    case AgentID of
        ?AGENT_LOCAL ->
            ServerID = common_config:get_server_id(),
            if
                100 =< ServerID andalso ServerID =< 159 -> %% 外网本地安卓
                    ?AGENT_JUNHAI_AND;
                160 =< ServerID andalso ServerID =< 179 -> %% 外网本地IOS
                    ?AGENT_JUNHAI_IOS;
                180 =< ServerID andalso ServerID =< 189 -> %% 外网爱奇艺
                    ?AGENT_IQIYI;
                true ->
                    AgentID
            end;
        _ ->
            AgentID
    end.

%% 通过GameChannelID获取平台参数
get_role_mod(ChannelID, GameChannelID) ->
    PlatForm = get_platform(ChannelID, GameChannelID),
    case lists:keyfind(PlatForm, #c_pf_mod.platform, ?PLATFORM_ROLE_MOD_LIST) of
        #c_pf_mod{role_mod = RoleMod} ->
            RoleMod;
        _ ->
            undefined
    end.

%% 通过包渠道ID获取平台
get_platform(ChannelID, GameChannelID) ->
    case ChannelID =:= 0 andalso GameChannelID =:= 0 of
        true -> %% pc
            ServerID = common_config:get_server_id(),
            if
                160 =< ServerID andalso ServerID =< 179 -> %% 外网本地IOS
                    ?PLATFORM_JUNHAI_IOS;
                true ->
                    ?PLATFORM_JUNHAI_AND
            end;
        _ ->
            case ChannelID of
                ?IQIYI_IOS_CHANNEL_ID -> %% 爱奇艺IOS
                    ?PLATFORM_IQIYI_IOS;
                ?SQ_IOS_CHANNEL_ID -> %% 神起IOS
                    ?PLATFORM_SQ_IOS;
                ?MUSHAO_IOS_CHANNEL_ID -> %% 木勺IOS渠道
                    ?PLATFORM_MUSHAO_IOS;
                ?YOUJING_IOS_CHANNEL_ID -> %% 游境IOS渠道
                    ?PLATFORM_YOUJING_IOS;
                ?ZHANGYOU_IOS_CHANNEL_ID -> %% 掌游IOS渠道
                    ?PLATFORM_ZHANGYOU_IOS;
                ?XIAOQI_IOS_CHANNEL_ID -> %% 小七IOS
                    ?PLATFORM_XIAOQI_IOS;
                ?AND_DT_CHANNEL_ID -> %% 顶拓
                    ?PLATFORM_AND_DT;
                _ ->
                    case is_junhai_ios_game_channel_id(GameChannelID) of
                        true ->
                            ?PLATFORM_JUNHAI_IOS;
                        _ ->
                            ?PLATFORM_JUNHAI_AND
                    end
            end
    end.

is_junhai_ios_game_channel_id(GameChannelID) ->
    lists:member(GameChannelID, [1000, ?IOS_JUNHAI_GAME_CHANNEL_ID, ?IOS_YOUJIA_GAME_CHANNEL_ID, ?KUISHE_IOS_GAME_CHANNEL_ID,
        ?PENGCHAO_IOS_GAME_CHANNEL_ID, ?IOS_JIANGUO_GAME_CHANNEL_ID, ?IOS_RAIN_GAME_CHANNEL_ID, ?IOS_LINGXIANG_GAME_CHANNEL_ID,
        ?IOS_JIANGUO2_GAME_CHANNEL_ID, ?IOS_JIANGUO3_GAME_CHANNEL_ID]).

is_log_ios(ChannelID, GameChannelID) ->
    lists:member(ChannelID, [?MUSHAO_IOS_CHANNEL_ID, ?YOUJING_IOS_CHANNEL_ID, ?ZHANGYOU_IOS_CHANNEL_ID, ?XIAOQI_IOS_CHANNEL_ID]) orelse
        is_junhai_ios_game_channel_id(GameChannelID).

is_agent_guild() ->
    common_config:get_agent_id() =:= ?AGENT_GUILD.
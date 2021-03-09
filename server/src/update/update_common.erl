%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     数据更新通用模块处理
%%% @end
%%% Created : 09. 一月 2019 0:21
%%%-------------------------------------------------------------------
-module(update_common).
-author("laijichang").
-include("common.hrl").

%% API
-export([
    update/2,
    data_update/2
]).

update(Mod, ServerType) ->
    if
        ServerType =:= ?NODE_TYPE_GAME -> %% 游戏服数据更新脚本
            execute_function(Mod, update_game);
        ServerType =:= ?NODE_TYPE_CROSS -> %% 跨服数据更新脚本
            execute_function(Mod, update_cross);
        ServerType =:= ?NODE_TYPE_CENTER -> %% 中央服数据更新脚本
            execute_function(Mod, update_center)
    end.

%% update_xxx回调
%% FuncList ---- {DBName, Function}
data_update(Module, FuncList) ->
    [ begin
          case catch db_lib:all(DB) of
              List when erlang:is_list(List) ->
                  List2 = Module:Fun(List),
                  ets:insert(DB, List2),
                  db:sync_all(DB),
                  db:flush(DB);
              _ ->
                  ?SYSTEM_LOG("db update tab not exist, ~w ...~n", [DB])
          end
      end || {DB, Fun} <- FuncList].

execute_function(Mod, Function) ->
    case erlang:function_exported(Mod, Function, 0) of
        true ->
            ?SYSTEM_LOG("db update, ~w:~w() ...~n", [Mod, Function]),
            erlang:apply(Mod, Function, []);
        _ ->
            ok
    end.
%%%-------------------------------------------------------------------
%%% @doc  The Module is for the interface to provide "startup", register
%%% log handle callback
%%%
%%% @end
%%% Created : 13. Mar 2015 22:02
%%%-------------------------------------------------------------------
-module(log).


%% API
-export([
    i/0,
    start/0,
    set_loglevel/1,
    set_callback/2,
    set_callbacks/1
]).

-define(INFO_LEVEL, 4).

-spec i() -> ok.
%% @doc 输出log_level和各logLevel的callback
i() ->
    io:format("log level:~p ~n",[log_loglevel:get()]),
    io:format("log callback:~p ~n",[log_server:get_callback()]),
    ok.

start() ->
    gen_event:add_handler(error_logger, log_syserror, []),
    log_server:start().

-spec set_loglevel(LogLevel) -> {module, log_entry} | ok when
      LogLevel :: 1..5.
%% @doc 设置日志等级
%% @param ErrorLogLevel 日志级别 1-5
%%     {1, "Critical"}
%%     {2, "Error"}
%%     {3, "Warning"}
%%     {4, "Info"}
%%     {5, "Debug"}
%% @end
set_loglevel(Loglevel) ->
    log_loglevel:set(Loglevel).

-spec set_callback(LogLevel, MFAs) -> {set_callback, {LogLevel, MFAs}} | ignore when
      LogLevel :: integer(),
      MFAs :: [{atom(), atom(), [term()]}].
%% @doc 设置1-3级别的回调执行，会在每次写日志时执行回调函数
set_callback(LogLevel,MFAs) when LogLevel >=1 andalso LogLevel =<3->
    log_server:set_callback(LogLevel,MFAs);
set_callback(_LogLevel,_MFAs) ->
    ignore.

-spec set_callbacks(LogLevelMFAsList) -> ok when
      LogLevelMFAsList :: [{LogLevel, MFAs}],
      LogLevel :: 1..5,
      MFAs :: [{atom(), atom(), [term()]}].
%% @doc 设置1-3级别的回调执行，会在每次写日志时执行回调函数
set_callbacks([]) ->
    ok;
set_callbacks([{LogLevel,MFAs}|TCallBacks]) ->
    [begin code:ensure_loaded(M) end || {M,_F,_A} <- MFAs],
    set_callback(LogLevel,MFAs),
    set_callbacks(TCallBacks).




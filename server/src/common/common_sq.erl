%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     神起渠道
%%% @end
%%% Created : 30. 七月 2019 19:46
%%%-------------------------------------------------------------------
-module(common_sq).
-author("laijichang").

%% API
-export([
    pf_log/1
]).

pf_log(Logs) ->
    junhai_misc:log(Logs).
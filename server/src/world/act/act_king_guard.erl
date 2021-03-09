%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 六月 2019 16:29
%%%-------------------------------------------------------------------
-module(act_king_guard).
-author("WZP").
-include("act.hrl").
-include("letter.hrl").


%% API
-export([
    hour/2
]).



hour(Now, #r_act{end_time = EndTime}) ->
    case EndTime - Now =:= 43200 of
        false ->
            ok;
        _ ->
            LetterInfo = #r_letter_info{
                condition = #r_gm_condition{min_level = 150},
                template_id = ?LETTER_TEMPLATE_KING_GUARD},
            common_letter:send_letter(?GM_MAIL_ID, LetterInfo)
    end.
%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 六月 2019 14:46
%%%-------------------------------------------------------------------
-module(act_rank).
-author("WZP").
-include("act.hrl").
-include("letter.hrl").

%% API
-export([
    zero/0,
    hour/1
]).



zero() ->
    OpenDay = common_config:get_open_days(),
    do_send_letter(cfg_act_rank:list(), OpenDay),
    ok.

do_send_letter([], _OpenDay) ->
    ok;
do_send_letter([{_ID, Config}|T], OpenDay) ->
    case Config#c_act_rank.open_days =:= OpenDay of
        false ->
            do_send_letter(T, OpenDay);
        _ ->
            LetterInfo = #r_letter_info{
                condition = #r_gm_condition{},
                days = 1,
                template_id = ?LETTER_TEMPLATE_ACT_RANK_OPEN,
                text_string = [Config#c_act_rank.name]},
            common_letter:send_letter(?GM_MAIL_ID, LetterInfo)
    end.

hour(Hour) ->
    OpenDay = common_config:get_open_days(),
    do_send_letter_i(cfg_act_rank:list(), OpenDay, Hour),
    ok.

do_send_letter_i([], _OpenDay, _NowHour) ->
    ok;
do_send_letter_i([{ID, Config}|T], OpenDay, NowHour) ->
    [Day, Hour] = Config#c_act_rank.rank_time,
    case Day =:= OpenDay andalso Hour =:= NowHour of
        false ->
            do_send_letter_i(T, OpenDay, NowHour);
        _ ->
            Ranks = world_data:get_act_ranks(ID),
            [begin
                 LetterInfo = #r_letter_info{
                     condition = #r_gm_condition{},
                     template_id = ?LETTER_TEMPLATE_ACT_RANK_END,
                     text_string = [lib_tool:to_list(Rank)]},
                 common_letter:send_letter(RoleID, LetterInfo)
             end || #r_act_rank{rank = Rank, role_id = RoleID} <- Ranks]
    end.
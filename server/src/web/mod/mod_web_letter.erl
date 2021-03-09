%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 四月 2018 14:32
%%%-------------------------------------------------------------------
-module(mod_web_letter).
-author("laijichang").
-include("web.hrl").
-include("global.hrl").
-include("letter.hrl").

%% API
-export([
    send_role_letter/1,
    send_all_letter/1,
    del_letter/1
]).

send_role_letter(Req) ->
    Post = Req:parse_post(),
    RoleIDList = web_tool:get_integer_list("role_ids", Post),
    Goods = web_tool:get_string_param("goods", Post),
    Goods2 = ?IF(Goods =:= undefined, "", Goods),
    Title = web_tool:to_utf8(web_tool:get_string_param("title", Post)),
    Text = get_text(Post),
%%    IsInsider = web_tool:get_int_param("is_insider", Post),
    EffectDays = erlang:max(1, web_tool:get_int_param("effective_time", Post)),
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_TEMPLATE_COMMON,
        action = ?ITEM_GAIN_LETTER_WEB_SINGLE,
        goods_list = web_tool:get_goods(Goods2),
        days = EffectDays,
        title_string = [Title],
        text_string = [Text]},
    [ begin
          common_letter:send_letter(RoleID, LetterInfo)
%%          ?IF(IsInsider > 0, mod_role_insider:mark_insider(RoleID, true, time_tool:now()), ok)
      end|| RoleID <- RoleIDList],
    ok.

send_all_letter(Req) ->
    Post = Req:parse_post(),
    Goods = web_tool:get_string_param("goods", Post),
    Title = web_tool:to_utf8(web_tool:get_string_param("title", Post)),
    Text = get_text(Post),
    ChannelIDList = web_tool:get_integer_list("game_channel_id", Post),
    ID = web_tool:get_int_param("id", Post),
    MinLevel = web_tool:get_int_param("lv1", Post),
    MaxLevel = web_tool:get_int_param("lv2", Post),
    MinCreateTime = web_tool:get_int_param("create_time1", Post),
    MaxCreateTime = web_tool:get_int_param("create_time2", Post),
    OfflineDays = web_tool:get_int_param("login_time", Post),
    OfflineTime = ?IF(OfflineDays > 0, time_tool:now() - OfflineDays * ?ONE_DAY, 0),
    EffectDays = erlang:max(1, web_tool:get_int_param("effective_time", Post)),
    Condition = #r_gm_condition{
        id = ID,
        min_level = MinLevel,
        max_level = MaxLevel,
        min_create_time = MinCreateTime,
        max_create_time = MaxCreateTime,
        last_offline_time = OfflineTime,
        game_channel_id_list = ChannelIDList},
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_TEMPLATE_COMMON,
        days = EffectDays,
        goods_list = web_tool:get_goods(Goods),
        action = ?ITEM_GAIN_LETTER_WEB_ALL,
        condition = Condition,
        title_string = [Title],
        text_string = [Text]},
    common_letter:send_letter(?GM_MAIL_ID, LetterInfo),
    ok.

del_letter(Req) ->
    Post = Req:parse_post(),
    ID = web_tool:get_int_param("id", Post),
    world_letter_server:del_gm_letter(ID),
    ok.

get_text(Post) ->
    Text = web_tool:get_string_param("text", Post),
    web_tool:to_utf8(Text).
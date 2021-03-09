%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 五月 2019 10:33
%%%-------------------------------------------------------------------
-module(bg_act_update).
-author("WZP").
-include("bg_act.hrl").
-include("role.hrl").
-include("global.hrl").
-include("platform.hrl").
-include("copy.hrl").
-include("proto/mod_role_bg_act.hrl").

%% API
-export([
    bg_update_bg_act/1
]).


%%后台增加新活动
%%bg_update_bg_act(Info) ->
%%    Type = lib_tool:to_integer(proplists:get_value("type", Info)),
%%    ActivityName = web_tool:to_utf8(proplists:get_value("activity_set_name", Info)),
%%    Icon = lib_tool:to_integer(proplists:get_value("icon", Info)),
%%    Title = web_tool:to_utf8((proplists:get_value("title", Info))),
%%    MinLevel = lib_tool:to_integer(proplists:get_value("min_level", Info)),
%%    TimeSlot = lib_tool:to_list(proplists:get_value("time_slot", Info)),
%%    Time = lib_tool:to_list(proplists:get_value("date", Info)),
%%    Explain1 = web_tool:to_utf8((proplists:get_value("explain1", Info))),
%%    Explain2 = web_tool:to_utf8((proplists:get_value("explain2", Info))),
%%    Sort = lib_tool:to_integer(proplists:get_value("sort", Info)),
%%    IsVisible = proplists:get_value("is_visible", Info),
%%    BackgroundImg = web_tool:to_utf8((proplists:get_value("background_img", Info))),
%%    EditTime = proplists:get_value("edit_time", Info),
%%    ConfigList = proplists:get_value("config", Info),
%%    Config2 = proplists:get_value("config2", Info),
%%    ChannelId = lib_tool:to_list(proplists:get_value("channel_id", Info)),
%%    GameChannelId = lib_tool:to_list(proplists:get_value("game_channel_id", Info)),
%%    Config3 = add_tran_config_i(Type, Config2),
%%    ConfigList2 = add_tran_config_list(Type, ConfigList, []),
%%    {StartTime, EndTime, StartDayTime, EndDayTime, StartDate, EndDate} = init_time(TimeSlot, Time),
%%    BGActInfo = #r_bg_act{id = Type, start_time = StartTime, end_time = EndTime, start_day_time = StartDayTime, end_day_time = EndDayTime, start_date = StartDate, end_date = EndDate,
%%                          status = ?BG_ACT_STATUS_FOUR, channel_id = ChannelId, game_channel_id = GameChannelId, title = Title, min_level = MinLevel, icon_name = ActivityName, icon = Icon,
%%                          explain = Explain1, explain_i = Explain2, background_img = BackgroundImg, is_visible = ?INT2BOOL(IsVisible), sort = Sort, config_list = ConfigList2, config = Config3, edit_time = EditTime},
%%    db:insert(?DB_R_BG_ACT_P, BGActInfo),

bg_update_bg_act(Info) ->
    bg_act_misc:bg_add_bg_act(Info),
    ok.
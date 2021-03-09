%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 六月 2019 19:43
%%%-------------------------------------------------------------------
-module(mod_web_family).
-author("laijichang").
-include("web.hrl").
-include("global.hrl").

%% API
-export([
    dismiss_family/1,
    change_family_notice/1,
    rename_family/1
]).

dismiss_family(Req) ->
    Post = Req:parse_post(),
    FamilyID = web_tool:get_int_param("family_id", Post),
    mod_family_operation:web_dismiss_family(FamilyID),
    ok.

change_family_notice(Req) ->
    Post = Req:parse_post(),
    FamilyID = web_tool:get_int_param("family_id", Post),
    Notice = web_tool:to_utf8(web_tool:get_string_param("new_notice", Post)),
    mod_family_operation:web_change_family_notice(FamilyID, Notice),
    ok.

rename_family(Req) ->
    Post = Req:parse_post(),
    FamilyID = web_tool:get_int_param("family_id", Post),
    NewName = web_tool:to_utf8(web_tool:get_string_param("new_family_name", Post)),
    case mod_family_operation:web_rename_family(FamilyID, NewName) of
        ok ->
            ok;
        {error, Msg} ->
            {error, Msg}
    end.

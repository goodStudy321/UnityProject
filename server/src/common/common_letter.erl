%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 七月 2017 12:06
%%%-------------------------------------------------------------------
-module(common_letter).
-author("laijichang").
-include("global.hrl").

%% API
-export([
    send_letter/2,
    send_cross_letter/2
]).

send_letter(RoleID, LetterInfo) ->
    #r_letter_info{
        template_id = TemplateID,
        goods_list = GoodsList,
        condition = Condition,
        days = Days,
        action = Action,
        title_string = TitleString,
        text_string = TextString
    } = LetterInfo,
    CreateList = mod_role_bag:get_create_list(GoodsList, common_role_data:get_role_category(RoleID)),
    ?IF(CreateList =/= [] andalso Action =:= 0, ?ERROR_MSG("当前信件未设置TemplateID:~w, Action: ~w", [TemplateID, Action]), ok),
    world_letter_server:send_letter(RoleID, TemplateID, Action, CreateList, Days, Condition, TitleString, TextString).

%% 该接口既可以本服调用，也可以在跨服节点调用
send_cross_letter(RoleID, LetterInfo) ->
    case common_config:is_game_node() of
        true ->
            send_letter(RoleID, LetterInfo);
        _ ->
            node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, send_letter, [RoleID, LetterInfo]})
    end.

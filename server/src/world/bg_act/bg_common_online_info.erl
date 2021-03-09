%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 二月 2019 17:38
%%%-------------------------------------------------------------------
-module(bg_common_online_info).
-author("WZP").
-include("bg_act.hrl").
-include("role.hrl").
-include("global.hrl").
-include("platform.hrl").
-include("copy.hrl").
-include("drop.hrl").
-include("proto/mod_role_bg_act.hrl").


%% API
-export([
    bg_act_drop/2,
    double_copy/1,
    double_exp/1
]).



double_copy(Info) ->
    PBgAct1 = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    Day = time_tool:diff_date(time_tool:now(), PBgAct1#p_bg_act.start_date) + 1,
    case lists:keyfind(Day, #bg_act_config_info.sort, PBgAct1#p_bg_act.entry_list) of
        false ->
            ok;
        #bg_act_config_info{condition = List} ->
            {_, List2} = lists:foldl(fun({CopyType, _NewList, TitleStr}, {SortID, AccList}) ->
                {SortID + 1, [#p_bg_act_entry{sort = SortID, num = CopyType, title = TitleStr}|AccList]}
                                     end, {1, []}, List),
            {ok, PBgAct1#p_bg_act{entry_list = List2}}
    end.


double_exp(Info) ->
    PBgAct1 = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    {ok, PBgAct1#p_bg_act{entry_list = []}}.


bg_act_drop(Info, RoleID) ->
    PBgAct1 = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    #r_bg_act{config = Config} = Info,
    [{boss_drop, BossDrop}, {boss_drop2, BossDrop2}|_] = Config,
    [DropConfig] = lib_config:find(cfg_drop, BossDrop),
    [DropConfig2] = lib_config:find(cfg_drop, BossDrop2),
    List1 = [ItemID || {_, {_, ItemID}} <- DropConfig#c_drop.drop_bag_list, ItemID =/= 0],
    List2 = [ItemID || {_, {_, ItemID}} <- DropConfig2#c_drop.drop_bag_list, ItemID =/= 0],
    common_misc:unicast(RoleID, #m_bg_drop_toc{info = PBgAct1, drop = lists:usort(List1 ++ List2)}),
    ok.


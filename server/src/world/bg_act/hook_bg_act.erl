%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 十二月 2018 19:38
%%%-------------------------------------------------------------------
-module(hook_bg_act).
-author("WZP").
-include("role.hrl").
-include("bg_act.hrl").
-include("letter.hrl").
-include("proto/mod_role_bg_act.hrl").
%% API
-export([
    do_bg_act_open_action/2,
    do_bg_act_close_action/1,
    update_consume_rank/3,
    config_list_change/5,
    bc_bg_init_act/1,
    time_store_buy/1,
    zero_clock_before_init/2,
    zero_clock_after_init/2,
    half_hour/3,
    bc_bg_act/2,
    hour/3
]).


zero_clock_before_init(#r_bg_act{id = BcActID} = BgAct, _Now) ->
    case BcActID of
        ?BG_ACT_DOUBLE_COPY ->
            ok;
        _ ->
            ok
    end,
    BgAct.


zero_clock_after_init(#r_bg_act{id = BcActID, status = Status, is_visible = IsVisible} = BgAct, _Now) ->
    case BcActID of
        ?BG_ACT_TIME_STORE ->
            case Status =:= ?BG_ACT_STATUS_TWO andalso IsVisible =:= true of
                true ->
                    PBgAct2 = bg_act_misc:trans_r_bg_act_to_p_bg_act(BgAct),
                    common_broadcast:bc_record_to_world(#m_bg_act_update_toc{act_list = [PBgAct2]});
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    BgAct.




bc_bg_act(ID, IsInit) ->
    common_broadcast:bc_role_info_to_world({mod, mod_role_bg_act, {bg_act_bc, ID, IsInit}}).

bc_bg_init_act(ID) ->
    common_broadcast:bc_role_info_to_world({mod, mod_role_bg_act, {bg_act_init, ID}}).

config_list_change(ID, AddConfigList, DelConfigList, UpdateConfigList, IsBc) ->
    common_broadcast:bc_role_info_to_world({mod, mod_role_bg_act, {config_list_change, ID, IsBc, AddConfigList, DelConfigList, UpdateConfigList}}).


do_bg_act_open_action(#r_bg_act{id = BcActID, start_date = StartDate, config_list = ConfigList, config = Config}, Now) ->
    case BcActID of
        ?BG_ACT_DOUBLE_COPY ->
            Day = time_tool:diff_date(Now, StartDate) + 1,
            case lists:keyfind(Day, #bg_act_config_info.sort, ConfigList) of
                false ->
                    ok;
                #bg_act_config_info{condition = CopyList} ->
                    CopyTypeList = [CopyType || {CopyType, _, _} <- CopyList],
                    ?IF(erlang:is_list(CopyTypeList), world_data:set_double_copy(CopyTypeList), ok)
            end;
        ?BG_ACT_STORE ->
            world_data:set_bg_drop(Config);
        ?BG_ACT_DOUBLE_EXP ->
            common_broadcast:bc_role_info_to_world({mod, mod_role_world_level, bg_act});
        _ ->
            BcActID
    end.


do_bg_act_close_action(BcActID) ->
    case BcActID of
        ?BG_ACT_DOUBLE_EXP ->
            common_broadcast:bc_role_info_to_world({mod, mod_role_world_level, bg_act});
        ?BG_ACT_DOUBLE_COPY ->
            world_data:set_double_copy([]);
        ?BG_ACT_STORE ->
            world_data:set_bg_drop([]);
        ?BG_ACT_CONSUME_RANK ->
            do_consume_rank_end();
        _ ->
            BcActID
    end.

hour(Now, _Hour, #r_bg_act{id = ID, end_date = EndDate}) ->
    case ID of
        ?BG_ACT_KING_GUARD ->
            king_guard_hour(Now, EndDate);
        _ ->
            ok
    end.

half_hour(_Now, _Hour, #r_bg_act{id = ID}) ->
    case ID of
        ?BG_ACT_CONSUME_RANK ->
            common_broadcast:bc_role_info_to_world({mod, mod_role_bg_act, consume_rank_update});
        _ ->
            ok
    end.


king_guard_hour(Now, EndDate) ->
    case EndDate - Now =:= 43200 of
        false ->
            ok;
        _ ->
            LetterInfo = #r_letter_info{
                condition = #r_gm_condition{min_level = 150},
                template_id = ?LETTER_TEMPLATE_KING_GUARD},
            common_letter:send_letter(?GM_MAIL_ID, LetterInfo)
    end.



update_consume_rank(RoleID, RoleName, Consume) ->
    BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_CONSUME_RANK),
    List = [#r_bg_rank{role_id = RoleID2, consume = RoleConsume2, role_name = RoleName2, rank = Sort}
        || #bg_act_config_info{status = RoleID2, condition = RoleConsume2, title = RoleName2, sort = Sort} <- BgInfo#r_bg_act.config_list],
    List2 = case lists:keytake(RoleID, #r_bg_rank.role_id, List) of
                false ->
                    [#r_bg_rank{role_id = RoleID, consume = Consume, role_name = RoleName, rank = 6}|List];
                {value, MyInfo, Other} ->
                    [MyInfo#r_bg_rank{role_id = RoleID, consume = Consume, role_name = RoleName}|Other]
            end,
    List3 = lists:sort(
        fun(RankInfo1, RankInfo2) ->
            #r_bg_rank{consume = Consume1, rank = Rank1} = RankInfo1,
            #r_bg_rank{consume = Consume2, rank = Rank2} = RankInfo2,
            if
                Consume1 > Consume2 ->
                    true;
                Consume1 < Consume2 ->
                    false;
                Rank1 > Rank2 ->
                    false;
                true ->
                    true
            end
        end, List2),
    List4 = update_consume_rank(BgInfo#r_bg_act.config_list, List3, 1, []),
    BgInfo2 = BgInfo#r_bg_act{config_list = List4},
    db:insert(?DB_R_BG_ACT_P, BgInfo2).

update_consume_rank(_ConfigList, _, Rank, List) when Rank > 5 ->
    List;
update_consume_rank(_ConfigList, [], _Rank, List) ->
    List;
update_consume_rank(ConfigList, [#r_bg_rank{role_id = RoleID2, consume = RoleConsume2, role_name = RoleName2}|T], Rank, List) ->
    case lists:keyfind(Rank, #bg_act_config_info.sort, ConfigList) of
        false ->
            update_consume_rank(ConfigList, T, Rank + 1, List);
        Info ->
            update_consume_rank(ConfigList, T, Rank + 1, [Info#bg_act_config_info{status = RoleID2, condition = RoleConsume2, title = RoleName2}|List])
    end.



do_consume_rank_end() ->
    BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_CONSUME_RANK),
    ?ERROR_MSG("----do_consume_rank_end----------~w", [BgInfo#r_bg_act.config_list]),
    [begin
         GoodsList = [#p_goods{type_id = TypeID, num = ItemNum, bind = ?IS_BIND(ISBind)} || #p_item_i{type_id = TypeID, num = ItemNum, is_bind = ISBind} <- Info#bg_act_config_info.items],
         LetterInfo = #r_letter_info{
             template_id = ?LETTER_CONSUME_RANK,
             text_string = [],
             action = ?ITEM_GAIN_CONSUME_RANK,
             goods_list = GoodsList},
         common_letter:send_letter(Info#bg_act_config_info.status, LetterInfo)
     end || Info <- BgInfo#r_bg_act.config_list].



time_store_buy(EntryID) ->
    BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_TIME_STORE),
    #r_bg_act{config_list = ConfigList} = BgInfo,
    ?ERROR_MSG("---------EntryID------------~w", [ConfigList]),
    case lists:keytake(EntryID, #bg_act_config_info.sort, ConfigList) of
        {value, #bg_act_config_info{items = Items} = Info, Other} ->
            [#p_item_i{num = Num} = PItems|T] = Items,
            ?ERROR_MSG("---------Num------------~w", [Num]),
            case Num > 0 of
                false ->
                    {error, ?ERROR_COMMON_SYSTEM_ERROR};
                _ ->
                    NewNum = Num - 1,
                    NewItems = [PItems#p_item_i{num = NewNum}|T],
                    NewConfigList = [Info#bg_act_config_info{items = NewItems}|Other],
                    db:insert(?DB_R_BG_ACT_P, BgInfo#r_bg_act{config_list = NewConfigList}),
                    common_broadcast:bc_record_to_world(#m_bg_act_reward_num_toc{id = ?BG_ACT_TIME_STORE, list = [#p_kv{id = EntryID, val = NewNum}]}),
                    {ok, NewNum}
            end;
        _ ->
            {error, ?ERROR_COMMON_SYSTEM_ERROR}
    end.
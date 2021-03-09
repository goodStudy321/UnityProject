%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     在线信息模块
%%% @end
%%% Created : 01. 八月 2017 10:21
%%%-------------------------------------------------------------------
-module(mod_role_online).
-author("laijichang").
-include("role.hrl").
-include("family.hrl").
-include("proto/mod_role_online.hrl").

%% API
-export([
    online/1,
    offline/1
]).

-export([
    notify_info/1
]).

online(#r_role{role_id = RoleID} = State) ->
    notify_info(State),
    case mod_role_bless:online_i(State) of
        {ok, State2, Exp, Time, OldLevel, NowLevel} ->
            {ok, State3, Illusion, NatIntensify} = mod_role_copy:online_i(State2),
            {ok, State4, AddBoxNum} = mod_role_family:online_i(State3),
            case mod_role_function:get_is_function_open(?FUNCTION_MINING, State4) of
                true ->
                    {MiningBindGold, MiningBindCopper} = case world_mining_server:get_mining_role_info(RoleID) of
                                                             #r_mining_role{goods_list = GoodsList} ->
                                                                 lists:foldl(fun(#p_kv{id = ID, val = Val}, {AccMiningBindGold, AccMiningBindCopper}) ->
                                                                     case ID of
                                                                         ?BAG_ASSET_SILVER ->
                                                                             {AccMiningBindGold, AccMiningBindCopper + Val};
                                                                         ?BAG_ASSET_BIND_GOLD ->
                                                                             {AccMiningBindGold + Val, AccMiningBindCopper};
                                                                         _ ->
                                                                             {AccMiningBindGold, AccMiningBindCopper}
                                                                     end

                                                                             end, {0, 0}, GoodsList);
                                                             _ ->
                                                                 {-1, -1}
                                                         end;
                _ ->
                    MiningBindGold = -1, MiningBindCopper = -1
            end,
            common_misc:unicast(RoleID, #m_bless_reward_online_toc{exp = Exp, time = Time, old_level = OldLevel, now_level = NowLevel, illusion = Illusion, nat_intensify = NatIntensify,
                                                                   family_box = AddBoxNum, mining_bind_gold = MiningBindGold, mining_bind_copper = MiningBindCopper}),
            State4;
        _ ->
            {ok, State3, _Illusion, _NatIntensify} = mod_role_copy:online_i(State),
            {ok, State4, _AddBoxNum} = mod_role_family:online_i(State3),
            State4
    end.

offline(State) ->
    #r_role{role_id = RoleID} = State,
    world_online_server:role_offline(RoleID),
    State.

notify_info(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{
        role_name = RoleName,
        account_name = AccountName,
        sex = Sex,
        category = Category,
        level = Level,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    RoleOnline = #r_role_online{
        role_id = RoleID,
        role_name = RoleName,
        account_name = AccountName,
        sex = Sex,
        category = Category,
        level = Level,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    world_online_server:notify_info(RoleOnline).

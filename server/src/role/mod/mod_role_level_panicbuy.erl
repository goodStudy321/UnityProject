%%%-------------------------------------------------------------------
%%% @author TcwXinYe
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 十月 2018 19:34
%%%-------------------------------------------------------------------
-module(mod_role_level_panicbuy).
-author("TcwXinYe").
-include("role.hrl").
-include("proto/mod_role_level_panicbuy.hrl").
%% API
-export([
    init/1,
    online/1,
    level_up/3,
    handle/2
]).

init(#r_role{role_id = RoleID, role_levelpanicbuy = undefined} = State) ->
    RoleLevelPanicBuy = #r_role_levelpanicbuy{role_id = RoleID, buy_list = []},
    State#r_role{role_levelpanicbuy = RoleLevelPanicBuy};
init(State) ->
    State.

online(#r_role{role_levelpanicbuy = #r_role_levelpanicbuy{buy_list = []}} = State) ->
    State;
online(#r_role{role_id = RoleID, role_levelpanicbuy = #r_role_levelpanicbuy{buy_list = SendList}} = State) ->
    Now = time_tool:now(),
    NewSendList = dump_expire_level_panic_buy_item(Now, SendList),%%上线的时候检查一遍r_role_levelpanicbuy中的buylist, 有时间过期的剔除，不过期且不为空就推送
    ?IF(NewSendList =/= [], common_misc:unicast(RoleID, #m_role_level_panicbuy_info_toc{list = NewSendList}), ok),
    NewRoleLevelPanicBuy = #r_role_levelpanicbuy{role_id = RoleID, buy_list = NewSendList}, %更新State
    State#r_role{role_levelpanicbuy = NewRoleLevelPanicBuy}.

level_up(OldLevel, NewLevel, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_levelpanicbuy = RoleLevelPanicBuy} = State,
    #r_role_attr{sex = Sex} = RoleAttr,
    SendList = RoleLevelPanicBuy#r_role_levelpanicbuy.buy_list,
    Now = time_tool:now(),
    NewSendList = dump_expire_level_panic_buy_item(Now, SendList),    %% 把已有的限时抢购列表检查一遍过期时间,过期就剔除得出新的列表
    ConfigList = cfg_role_level_panicbuy:list(), %% 遍历一遍取到整个配置表
    NewSendList2 = lists:foldl(
        fun(X, Acc1) ->  %% 在等级限时抢购列表中（新的列表)加入新的可以抢购的物品ID和过期时间（ExpireTime）
            {_, #c_role_level_panicbuy{id = ID, level = Level, time_expire = TimeToExpire, gender = Gender}} = X,
            BuyItem = #p_level_buy_item{level_buy_id = ID, expire_time = (Now + TimeToExpire * 3600)},
            ?IF((Gender =:= 3) or (Sex =:= Gender), ?IF(Level > OldLevel andalso Level =< NewLevel, [BuyItem|Acc1], Acc1), Acc1)
        end, NewSendList, ConfigList),
    ?IF(NewSendList2 =/= NewSendList, common_misc:unicast(RoleID, #m_role_level_panicbuy_info_toc{list = NewSendList2}), ok),
    NewRoleLevelPanicBuy = #r_role_levelpanicbuy{role_id = RoleID, buy_list = NewSendList2},
    State#r_role{role_levelpanicbuy = NewRoleLevelPanicBuy}.

handle({#m_role_level_panicbuy_tos{id = ID}, RoleID, _PID}, State) ->   %处理购买返回信息
    do_level_panic_buy(State, RoleID, ID).

%%% internal function
%%%
do_level_panic_buy(State, RoleID, ID) ->
    case catch check_can_buy(State, ID) of
        {ok, State2, AssetDoing, BagDoing, Log} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            common_misc:unicast(RoleID, #m_role_level_panicbuy_toc{id = ID}),
            mod_role_dict:add_background_logs(Log),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_level_panicbuy_toc{err_code = ErrCode}),
            State
    end.

check_can_buy(#r_role{role_levelpanicbuy = RoleLevelPanicBuy} = State, ID) ->
    case lists:keytake(ID, #p_kvt.id, RoleLevelPanicBuy#r_role_levelpanicbuy.buy_list) of
        {value, _Value, BuyList2} ->
            [Config] = lib_config:find(cfg_role_level_panicbuy, ID),
            #c_role_level_panicbuy{item_id = ItemId, quantity = Quantity, price = Price, currency_type = CurrencyType} = Config,
            %%下面是查有没有钱（元宝/绑元)去购买 但是这个currency_type策划不能配错了，配错了就无限购买BUG了。
            AssetDoing = mod_role_asset:check_asset_by_type(CurrencyType, Price, ?ASSET_GOLD_REDUCE_FROM_LEVEL_PANIC_BUY, State),%优先消耗绑定元宝
            GoodsList = [#p_goods{type_id = ItemId, num = Quantity, bind = true}],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),   %%检查包包空间够不够
            BagDoings = [{create, ?ITEM_GAIN_LEVEL_PANIC_BUY, GoodsList}],
            NewRoleLevelPanicBuy = RoleLevelPanicBuy#r_role_levelpanicbuy{buy_list = BuyList2},
            Log = get_log(State, ItemId),
            {ok, State#r_role{role_levelpanicbuy = NewRoleLevelPanicBuy}, AssetDoing, BagDoings, Log};
        _ ->
            ?THROW_ERR(?ERROR_ROLE_LEVEL_PANICBUY_001)
    end.

dump_expire_level_panic_buy_item(Time_Now, SendList) ->
    NewSendList = lists:foldl(                          fun(X, Acc1) ->    %%上线的时候检查一遍r_role_levelpanicbuy中的buylist, 有过期的剔除，不过期就推送
        #p_level_buy_item{expire_time = ExpireTime} = X,
        ?IF(ExpireTime > Time_Now, [X|Acc1], Acc1) end, [], SendList),
    NewSendList.


get_log(#r_role{role_id = RoleID, role_attr = RoleAttr}, ItemId) ->
    #log_role_gear{
        role_id = RoleID,
        channel_id = RoleAttr#r_role_attr.channel_id,
        game_channel_id = RoleAttr#r_role_attr.game_channel_id,
        type = ?LOG_GEAR_LEVEL_PANIC_BUY,
        gear = ItemId
    }.
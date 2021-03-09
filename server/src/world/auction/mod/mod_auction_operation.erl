%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 六月 2019 15:05
%%%-------------------------------------------------------------------
-module(mod_auction_operation).
-author("laijichang").
-include("auction.hrl").
-include("role.hrl").
-include("proto/mod_role_auction.hrl").

%% API
-export([
    buy_goods/4,
    sell_goods/2,
    obtain_goods/2,
    auction_care/3,
    family_auction_goods/3,

    open_panel/1,
    close_panel/1
]).

-export([
    handle/1
]).

-export([
    add_role_care/2
]).


buy_goods(RoleID, Type, ID, Gold) ->
    world_auction_server:call_mod(?MODULE, {buy_goods, RoleID, Type, ID, Gold}).
sell_goods(RoleID, GoodsList) ->
    world_auction_server:info_mod(?MODULE, {sell_goods, RoleID, GoodsList}).
obtain_goods(RoleID, ID) ->
    world_auction_server:call_mod(?MODULE, {obtain_goods, RoleID, ID}).
auction_care(RoleID, Type, TypeID) ->
    world_auction_server:info_mod(?MODULE, {auction_care, RoleID, Type, TypeID}).
family_auction_goods(FamilyID, Roles, GoodsList) ->
    world_auction_server:info_mod(?MODULE, {family_auction_goods, FamilyID, Roles, GoodsList}).

open_panel(RoleID) ->
    world_auction_server:info_mod(?MODULE, {open_panel, RoleID}).
close_panel(RoleID) ->
    world_auction_server:info_mod(?MODULE, {close_panel, RoleID}).

handle({buy_goods, RoleID, Type, ID, Gold}) ->
    do_role_buy_goods(RoleID, Type, ID, Gold);
handle({sell_goods, RoleID, GoodsList}) ->
    do_role_sell_goods(RoleID, GoodsList);
handle({obtain_goods, RoleID, ID}) ->
    do_role_obtain_goods(RoleID, ID);
handle({auction_care, RoleID, Type, TypeID}) ->
    do_auction_care(RoleID, Type, TypeID);
handle({family_auction_goods, FamilyID, Roles, GoodsList}) ->
    do_family_auction_goods(FamilyID, Roles, GoodsList);
handle({open_panel, RoleID}) ->
    do_open_panel(RoleID);
handle({close_panel, RoleID}) ->
    do_close_panel(RoleID);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]),
    error.

%% 玩家购买商品
do_role_buy_goods(RoleID, Type, ID, Gold) ->
    case catch check_buy_goods(RoleID, Type, ID, Gold) of
        {ok, AuctionGoods, OldRoleID, OldGold, Log} ->
            AuctionGoods2 =
                case Type of
                    ?AUCTION_BUY_BUYOUT ->
                        mod_auction_goods:goods_be_bought(AuctionGoods),
                        AuctionGoods;
                    ?AUCTION_BUY_AUCTION ->
                        OldEndTime = AuctionGoods#r_auction_goods.end_time,
                        NewEndTime = OldEndTime + ?ONE_MINUTE,
                        AuctionGoodsT = AuctionGoods#r_auction_goods{end_time = NewEndTime},
                        mod_auction_data:set_auction_goods(AuctionGoodsT),
                        mod_auction_goods:del_end_time_hash(OldEndTime, ID),
                        mod_auction_goods:add_end_time_hash(NewEndTime, ID),
                        auction_misc:auction_update(AuctionGoodsT),
                        auction_misc:broadcast_update(AuctionGoodsT),
                        AuctionGoodsT
                end,
            do_auction_change(OldRoleID, AuctionGoods2#r_auction_goods.type_id, OldGold, Log),
            ?TRY_CATCH(auction_misc:log_auction_buy(RoleID, Type, AuctionGoods2)),
            {ok, AuctionGoods2};
        {goods_update, AuctionGoods} ->
            {goods_update, AuctionGoods};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_buy_goods(RoleID, Type, ID, Gold) ->
    {AuctionGoods, NeedGold} = auction_misc:check_auction_buy(RoleID, Type, ID),
    #r_auction_goods{
        auction_role_id = OldAuctionRoleID,
        type_id = TypeID,
        num = Num,
        cur_gold = CurGold} = AuctionGoods,
    ?IF(Gold =:= NeedGold, ok, erlang:throw({goods_update, AuctionGoods})),
    Log = #r_auction_log{
        time = time_tool:now(),
        type_id = TypeID,
        num = Num,
        gold = 0},
    AuctionGoods2 = AuctionGoods#r_auction_goods{auction_role_id = RoleID, cur_gold = NeedGold},
    {ok, AuctionGoods2, OldAuctionRoleID, CurGold, Log}.

%% 拍卖者变化
do_auction_change(RoleID, TypeID, Gold, Log) when RoleID > 0->
    GoodsList = [#p_goods{type_id = ?ITEM_GOLD, num = Gold}],
    #c_item{name = ItemName} = mod_role_item:get_item_config(TypeID),
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_TEMPLATE_AUCTION_BUY_FAILED,
        text_string = [ItemName],
        goods_list = GoodsList,
        action = ?ITEM_GAIN_AUCTION_COMPETE_RETURN
    },
    common_letter:send_letter(RoleID, LetterInfo),
    mod_auction_goods:auction_role_buy_log(RoleID, Log);
do_auction_change(_RoleID, _TypeID, _Gold, _Log) ->
    ok.

%% 上架拍品
do_role_sell_goods(RoleID, GoodsList) ->
    [
        begin
            RoleAuction = mod_auction_data:get_role_auction(RoleID),
            #r_auction_goods{id = ID} = AuctionGoods = get_auction_goods(?AUCTION_FROM_ROLE, RoleID, 0, Goods),
            mod_auction_data:set_role_auction(RoleAuction#r_role_auction{auction_goods_ids = [ID|RoleAuction#r_role_auction.auction_goods_ids]}),
            mod_auction_data:set_auction_goods(AuctionGoods),
            mod_auction_goods:add_goods_hash(AuctionGoods),
            auction_misc:auction_update(AuctionGoods),
            auction_misc:broadcast_add(AuctionGoods),
            ?TRY_CATCH(auction_misc:log_auction_exchange(?AUCTION_FROM_ROLE, RoleID, ?ACTION_AUCTION_SELL, AuctionGoods))
        end || Goods <- GoodsList].

%% 下架拍品
do_role_obtain_goods(RoleID, ID) ->
    case catch check_role_obtain_goods(RoleID, ID) of
        {ok, FromID, AuctionGoods, RoleAuction, Log} ->
            mod_auction_data:set_role_auction(RoleAuction#r_role_auction{auction_goods_ids = lists:delete(ID, RoleAuction#r_role_auction.auction_goods_ids)}),
            mod_auction_data:del_auction_goods(ID),
            mod_auction_goods:del_goods_hash(AuctionGoods),
            auction_misc:auction_del(FromID, ID),
            auction_misc:broadcast_del(ID),
            mod_auction_goods:auction_role_sell_log(RoleID, Log),
            ?TRY_CATCH(auction_misc:log_auction_exchange(?AUCTION_FROM_ROLE, RoleID, ?ACTION_AUCTION_UNSOLD, AuctionGoods)),
            ok;
        {error, ErrCode}->
            {error, ErrCode}
    end.

check_role_obtain_goods(RoleID, ID) ->
    RoleAuction = mod_auction_data:get_role_auction(RoleID),
    AuctionGoods = auction_misc:get_auction_goods(ID),
    #r_auction_goods{type_id = TypeID, num = Num, from_id = FromID, from_type = FromType, auction_role_id = AuctionRoleID} = AuctionGoods,
    ?IF(AuctionRoleID =:= 0, ok, ?THROW_ERR(?ERROR_AUCTION_OBTAIN_001)),
    ?IF(FromType =/= ?AUCTION_FROM_FAMILY, ok, ?THROW_ERR(?ERROR_AUCTION_OBTAIN_002)),
    Log = #r_auction_log{time = time_tool:now(), type_id = TypeID, num = Num, gold = -1},
    {ok, FromID, AuctionGoods, RoleAuction, Log}.

%% 关注
do_auction_care(RoleID, Type, TypeID) ->
    #r_role_auction{care_type_ids = CareTypeIDs} = RoleAuction = mod_auction_data:get_role_auction(RoleID),
    CareTypeIDs2 =
        case Type of
            ?AUCTION_CARE ->
                case lists:member(TypeID, CareTypeIDs) of
                    true ->
                        CareTypeIDs;
                    _ ->
                        add_role_care(RoleID, TypeID),
                        [TypeID|CareTypeIDs]
                end;
            ?AUCTION_CANCEL_CARE ->
                case lists:member(TypeID, CareTypeIDs) of
                    true ->
                        del_role_care(RoleID, TypeID),
                        lists:delete(TypeID, CareTypeIDs);
                    _ ->
                        CareTypeIDs
                end
        end,
    mod_auction_data:set_role_auction(RoleAuction#r_role_auction{care_type_ids = CareTypeIDs2}),
    common_misc:unicast(RoleID, #m_auction_care_toc{type = Type, type_id = TypeID}).

do_family_auction_goods(FamilyID, Roles, GoodsList) ->
    [ begin
          case mod_role_item:get_item_config(TypeID) of
              #c_item{auction_sub_class = SubClass} when SubClass > 0 ->
                  AuctionGoods = get_auction_goods(?AUCTION_FROM_FAMILY, FamilyID, Roles, Goods),
                  mod_auction_data:set_auction_goods(AuctionGoods),
                  mod_auction_goods:add_goods_hash(AuctionGoods),
                  ?TRY_CATCH(auction_misc:log_auction_exchange(?AUCTION_FROM_FAMILY, FamilyID, ?ACTION_AUCTION_SELL, AuctionGoods));
              _ ->
                  ignore
          end,
          ok
      end|| #p_goods{type_id = TypeID} = Goods <- GoodsList].

get_auction_goods(FromType, FromID, FromArgs, Goods) ->
    #p_goods{
        type_id = TypeID,
        num = Num,
        excellent_list = ExcellentList} = Goods,
    #c_item{auction_gold = AuctionGold} = mod_role_item:get_item_config(TypeID),
    Now = time_tool:now(),
    [ShowTime, _AuctionTime, _LogLen, FamilyAuctionTimes|_] = common_misc:get_global_list(?GLOBAL_AUCTION_ARGS),
    #c_item{shelf_time = AuctionTime} = mod_role_item:get_item_config(TypeID),
    AddAuctionTime = ?IF(FromType =:= ?AUCTION_FROM_FAMILY, FamilyAuctionTimes, AuctionTime),
    #r_auction_goods{
        id = mod_auction_data:update_auction_goods_id(),
        type_id = TypeID,
        num = Num,
        excellent_list = ExcellentList,
        auction_time = Now + ShowTime,
        end_time = Now + ShowTime + AddAuctionTime,
        cur_gold = AuctionGold * Num,
        from_type = FromType,
        from_id = FromID,
        from_args = FromArgs
    }.

add_role_care(RoleID, TypeID) ->
    #r_auction_type_id_hash{care_role_ids = CareRoleIDs} = TypeIDHash = mod_auction_data:get_type_id_hash(TypeID),
    CareRoleIDs2 = [RoleID|lists:delete(RoleID, CareRoleIDs)],
    mod_auction_data:set_type_id_hash(TypeIDHash#r_auction_type_id_hash{care_role_ids = CareRoleIDs2}).

del_role_care(RoleID, TypeID) ->
    #r_auction_type_id_hash{care_role_ids = CareRoleIDs} = TypeIDHash = mod_auction_data:get_type_id_hash(TypeID),
    CareRoleIDs2 = lists:delete(RoleID, CareRoleIDs),
    mod_auction_data:set_type_id_hash(TypeIDHash#r_auction_type_id_hash{care_role_ids = CareRoleIDs2}).

do_open_panel(RoleID) ->
    Roles = mod_auction_data:get_panel_roles(),
    Roles2 = [RoleID|lists:delete(RoleID, Roles)],
    mod_auction_data:set_panel_roles(Roles2).

do_close_panel(RoleID) ->
    Roles = mod_auction_data:get_panel_roles(),
    Roles2 = lists:delete(RoleID, Roles),
    mod_auction_data:set_panel_roles(Roles2).
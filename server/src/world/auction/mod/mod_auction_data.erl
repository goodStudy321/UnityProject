%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     拍卖行数据模块
%%% @end
%%% Created : 17. 六月 2019 11:03
%%%-------------------------------------------------------------------
-module(mod_auction_data).
-author("laijichang").
-include("auction.hrl").
-include("family.hrl").
-include("global.hrl").

%% API
-export([
    i/0,
    init/0,
    init_sub_class_index/0,
    update_auction_goods_id/0
]).

%% dict
-export([
    set_last_loop_time/1,
    get_last_loop_time/0,

    set_sub_class_index_list/2,
    get_sub_class_index_list/1,

    set_panel_roles/1,
    get_panel_roles/0
]).

%% ets
-export([
    set_class_hash/1,
    get_class_hash/1,

    set_end_time_hash/1,
    del_end_time_hash/1,
    get_end_time_hash/1,

    set_type_id_hash/1,
    get_type_id_hash/1,

    set_auction_goods/1,
    del_auction_goods/1,
    get_auction_goods/1,

    set_role_auction/1,
    get_role_auction/1,

    set_family_auction/1,
    get_family_auction/1
]).

i() ->
    {ets:tab2list(?ETS_AUCTION_CLASS_HASH), ets:tab2list(?ETS_AUCTION_TIME_HASH), ets:tab2list(?ETS_AUCTION_TYPE_ID_HASH)}.

init() ->
    set_last_loop_time(time_tool:now()),
    lib_tool:init_ets(?ETS_AUCTION_CLASS_HASH, #r_auction_class_hash.key),
    lib_tool:init_ets(?ETS_AUCTION_TIME_HASH, #r_auction_time_hash.end_time),
    lib_tool:init_ets(?ETS_AUCTION_TYPE_ID_HASH, #r_auction_type_id_hash.type_id),
    init_sub_class_index(),
    modify_family_auction(),
    init_auction_goods(),
    init_type_id_hash().

%% 初始化二级分类的索引
init_sub_class_index() ->
    AllMajorClass = lib_config:list(cfg_auction_major_class),
    [ begin
          AllList = ?IF(lists:member(0, SubList), [MajorClass, ?AUCTION_ALL_CLASS], [?AUCTION_ALL_CLASS]),
          init_sub_class_index2(lists:delete(0, SubList), AllList)
      end || {MajorClass, #c_auction_major_class{sub_list = SubList}}<- AllMajorClass, MajorClass =/= ?AUCTION_ALL_CLASS].

init_sub_class_index2([], _AllList) ->
    ok;
init_sub_class_index2([SubClass|R], AllList) ->
    AddList = [SubClass|AllList],
    OldList = get_sub_class_index_list(SubClass),
    %% 去重
    set_sub_class_index_list(SubClass, (OldList -- AddList) ++ AddList),
    init_sub_class_index2(R, AllList).

%% 修正仙盟数据
modify_family_auction() ->
    [ begin
          case mod_family_data:get_family(FamilyID) =:= undefined of
              true ->
                  db:delete(?DB_FAMILY_AUCTION_P, FamilyID);
              _ ->
                  ok
          end
      end|| #r_family_auction{family_id = FamilyID} <- db:table_all(?DB_FAMILY_AUCTION_P)].

%% 检查拍卖品信息
init_auction_goods() ->
    Now = time_tool:now(),
    AllList = db:table_all(?DB_AUCTION_GOODS_P),
    [ begin
          case Now >= EndTime of
              true ->
                  mod_auction_goods:goods_end_time(AuctionGoods);
              _ ->
                  mod_auction_goods:add_goods_hash(AuctionGoods)
          end
      end || #r_auction_goods{end_time = EndTime} = AuctionGoods <- AllList].

init_type_id_hash() ->
    AllList = db:table_all(?DB_ROLE_AUCTION_P),
    [[ mod_auction_operation:add_role_care(RoleID, CareTypeID)|| CareTypeID <- CareTypeIDs] ||
        #r_role_auction{role_id = RoleID, care_type_ids = CareTypeIDs} <- AllList].

update_auction_goods_id() ->
    ID = world_data:get_auction_goods_id(),
    world_data:set_auction_goods_id(common_id:get_auction_next_id(ID)),
    ID.
%%%===================================================================
%%% 数据操作
%%%===================================================================
%% 时间戳会跳秒，缓存
set_last_loop_time(Time) ->
    erlang:put({?MODULE, last_loop_time}, Time).
get_last_loop_time() ->
    erlang:get({?MODULE, last_loop_time}).

%% 获取分类对应的ID
set_sub_class_index_list(SubClassID, List) ->
    erlang:put({?MODULE, class_index, SubClassID}, List).
get_sub_class_index_list(SubClassID) ->
    case erlang:get({?MODULE, class_index, SubClassID}) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.

set_panel_roles(RoleS) ->
    erlang:put({?MODULE, panel_roles}, RoleS).
get_panel_roles() ->
    case erlang:get({?MODULE, panel_roles}) of
        [_|_] = Roles ->
            Roles;
        _ ->
            []
    end.


set_class_hash(ClassHash) ->
    ets:insert(?ETS_AUCTION_CLASS_HASH, ClassHash).
get_class_hash(Key) ->
    case ets:lookup(?ETS_AUCTION_CLASS_HASH, Key) of
        [#r_auction_class_hash{} = ClassHash] ->
            ClassHash;
        _ ->
            #r_auction_class_hash{key = Key}
    end.

set_end_time_hash(TimeHash) ->
    ets:insert(?ETS_AUCTION_TIME_HASH, TimeHash).
del_end_time_hash(EndTime) ->
    ets:delete(?ETS_AUCTION_TIME_HASH, EndTime).
get_end_time_hash(EndTime) ->
    case ets:lookup(?ETS_AUCTION_TIME_HASH, EndTime) of
        [#r_auction_time_hash{} = TimeHash] ->
            TimeHash;
        _ ->
            #r_auction_time_hash{end_time = EndTime}
    end.

set_type_id_hash(TypeIDHash) ->
    ets:insert(?ETS_AUCTION_TYPE_ID_HASH, TypeIDHash).
get_type_id_hash(TypeID) ->
    case ets:lookup(?ETS_AUCTION_TYPE_ID_HASH, TypeID) of
        [#r_auction_type_id_hash{} = TypeIDHash] ->
            TypeIDHash;
        _ ->
            #r_auction_type_id_hash{type_id = TypeID}
    end.

set_auction_goods(AuctionGoods) ->
    db:insert(?DB_AUCTION_GOODS_P, AuctionGoods).
del_auction_goods(ID) ->
    db:delete(?DB_AUCTION_GOODS_P, ID).
get_auction_goods(ID) ->
    ets:lookup(?DB_AUCTION_GOODS_P, ID).

set_role_auction(RoleAuction) ->
    db:insert(?DB_ROLE_AUCTION_P, RoleAuction).
get_role_auction(RoleID) ->
    case ets:lookup(?DB_ROLE_AUCTION_P, RoleID) of
        [RoleAuction] ->
            RoleAuction;
        _ ->
            #r_role_auction{role_id = RoleID}
    end.

set_family_auction(FamilyAuction) ->
    db:insert(?DB_FAMILY_AUCTION_P, FamilyAuction).
get_family_auction(FamilyID) ->
    case ets:lookup(?DB_FAMILY_AUCTION_P, FamilyID) of
        [FamilyAuction] ->
            FamilyAuction;
        _ ->
            #r_family_auction{family_id = FamilyID}
    end.
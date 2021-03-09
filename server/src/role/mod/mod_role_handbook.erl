%%%-------------------------------------------------------------------
%%% @author yaolun
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 图鉴
%%% @end
%%% Created : 14. 二月 2019 16:40
%%%-------------------------------------------------------------------
-module(mod_role_handbook).
-author("yaolun").

-include("role.hrl").
-include("common.hrl").
-include("proto/mod_role_handbook.hrl").
-include("handbook.hrl").

%% API
-export([
    function_open/1,
    calc/1,
    online/1,
    handle/2
]).

-export([
    add_handbook_essence/2
]).


function_open(#r_role{role_id = RoleID, role_handbook = undefined} = State) ->
    RoleHandBook = #r_role_handbook{role_id = RoleID},
    State#r_role{role_handbook = RoleHandBook};
function_open(State) ->
    State.

calc(#r_role{role_handbook = undefined} = State) ->
    State;
calc(#r_role{role_handbook = RoleHandBook} = State) ->
    #r_role_handbook{handbook_maps = HandBookMaps, handbook_group_maps = HandGroupMaps} = RoleHandBook,
    PkvList = maps:fold(fun(_K, CardGroupMaps, PkList) ->
        maps:fold(fun(_k2, CardId, ReList2) ->
            case lib_config:find(cfg_handbook_cultivate, CardId) of
                [] -> ReList2;
                [#c_handbook_cultivate{property1 = Pro1, property2 = Pro2, property3 = Pro3, property4 = Pro4}] ->
                    lists:foldl(fun(ProData, ReList3) ->
                        case ProData of
                            [] -> ReList3;
                            [K, V] ->
                                [#p_kv{id = K, val = V}|ReList3]
                        end
                    end, ReList2, [Pro1, Pro2, Pro3, Pro4])
            end
        end, PkList, CardGroupMaps)
    end, [], HandBookMaps),

    PkvList2 = maps:fold(fun(_K, CardGroupId, PkvList2) ->
        lists:foldl(fun(ActCardGroupId, PkvList3) ->
            case lib_config:find(cfg_handbook_group, ActCardGroupId) of
                [] -> PkvList3;
                [#c_handbook_group{act_pro = ActProStr}] ->
                    ActPro = lib_tool:string_to_intlist(ActProStr),
                    ProList = [#p_kv{id = K, val = V} ||{K, V} <- ActPro],
                    lists:append(PkvList3, ProList)
            end
        end, PkvList2, CardGroupId)

    end, PkvList, HandGroupMaps),

    CalcAttr1 = common_misc:get_attr_by_kv(PkvList2),
    State2 = mod_role_fight:get_state_by_kv(State, ?CALC_KEY_HANDBOOK, CalcAttr1), %% 推送图鉴的战力
    State2.

online(#r_role{role_handbook = undefined} = State) ->
    State;
online(#r_role{role_id = RoleID, role_handbook = RoleHandBook} = State) ->
    #r_role_handbook{essence = Essence, handbook_maps = HandBookMaps, handbook_group_maps = HandbookGroupMaps} = RoleHandBook,

    HandBookDataList2 = maps:fold(fun(Group, CardGroupMaps, HandBookDataList) ->
        CardIds = maps:values(CardGroupMaps),
        CardGroupIdLis = case maps:find(Group, HandbookGroupMaps) of
            error -> [];
            {ok, ActList} -> ActList
        end,

        [#p_handbook_data{
            card_id = CardIds, card_group_id = CardGroupIdLis
        }|HandBookDataList]
    end, [], HandBookMaps),

    common_misc:unicast(RoleID, #m_role_handbook_list_toc{handbook_list = HandBookDataList2, total_essence = Essence}),
    State.



%% 图鉴卡片激活
handle({#m_role_handbook_activate_tos{card_id = CareId}, RoleID, _PID}, State) ->
    do_handbook_activate(RoleID, CareId, State);
%% 图鉴材料分解
handle({#m_role_handbook_resolve_tos{resolve_item_id = ItemIdList}, RoleID, _PID}, State) ->
    do_handbook_resolve(RoleID, ItemIdList, State);
%% 图鉴升级
handle({#m_role_handbook_upgrade_tos{card_id = CareId}, RoleID, _PID}, State) ->
    do_handbook_upgrade(RoleID, CareId, State);
%% 图鉴组属性激活
handle({#m_role_handbook_group_activate_tos{card_group_id = CareGroupId}, RoleID, _PID}, State) ->
    do_handbook_group_activate(RoleID, CareGroupId, State).


%% 图鉴卡片激活
%% @param CareId :: integer 图鉴养成表的Id
do_handbook_activate(_RoleID, _CardId, #r_role{role_handbook = undefined} = State) ->
    State;
do_handbook_activate(RoleID, CardId, State) ->
    CfgHandBookCultivate = lib_config:find(cfg_handbook_cultivate, CardId),
    case catch check_handbook_activate(CardId, CfgHandBookCultivate,  State) of
        {ok, BagDoing, State2, TotalEssence} ->
            %% 扣除物品
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_role_handbook_activate_toc{card_id = CardId + 1}),
            common_misc:unicast(RoleID, #m_role_handbook_essence_toc{total_essence = TotalEssence}),
            %% 调用战力计算后返回state
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_HANDBOOK_ACTIVATE, CardId);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_handbook_activate_toc{err_code = ErrCode}),
            State
    end.


check_handbook_activate(CardId, CfgHandBookCultivate, #r_role{role_handbook = RoleHandBook} = State) ->
    CardGid = ?GET_BASE_ID(CardId),
    [#c_handbook_cultivate{group = Group, upgrade_consume = UpgradeConsumeStr, essence_consume = EssenceConsume}] = CfgHandBookCultivate,
    ?IF(check_handbook_activate2(CardGid, CfgHandBookCultivate, State) == activate, ?THROW_ERR(?ERROR_ROLE_HANDBOOK_ACTIVATE_002), ok),
    %% 精华是否足够
    #r_role_handbook{essence = Essence} = RoleHandBook,
    ?IF(Essence >= EssenceConsume, ok, ?THROW_ERR(?ERROR_ROLE_HANDBOOK_ACTIVATE_001)),
    %% 扣除物品
    BagDoing = mod_role_bag:check_num_by_item_list(lib_tool:string_to_intlist(UpgradeConsumeStr), ?ITEM_REDUCE_HANDBOOK_CATIVATE, State),

    Essence2 = Essence - EssenceConsume,
    RoleHandBook2 = RoleHandBook#r_role_handbook{essence = Essence2},
    RoleHandBook3 = updata_HandBookMaps(CardId + 1, Group, RoleHandBook2),
    State2 = State#r_role{role_handbook = RoleHandBook3},

    {ok, BagDoing, State2, Essence2}.

check_handbook_activate2(CardGid, CfgHandBookCultivate, #r_role{role_handbook = RoleHandBook}) ->
    #r_role_handbook{handbook_maps = HandBookMaps} = RoleHandBook,
    [#c_handbook_cultivate{group = Group}] = CfgHandBookCultivate,
    case maps:find(Group, HandBookMaps) of
        {ok, CardGroupMaps} ->
            ?IF(maps:find(CardGid, CardGroupMaps) =:= error, ok, activate);
        error ->
            ok
    end.


%% 图鉴材料分解
do_handbook_resolve(_RoleID, _ItemIdList, #r_role{role_handbook = undefined} = State) ->
    State;
do_handbook_resolve(RoleID, ItemIdList,State) ->
    case catch check_handbook_resolve(ItemIdList, State) of
        {ok, BagDoing, GetEssence, State2, TotalEssence} ->
            %% 删除物品
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_role_handbook_resolve_toc{get_essence = GetEssence}),
            common_misc:unicast(RoleID, #m_role_handbook_essence_toc{total_essence = TotalEssence}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_handbook_resolve_toc{err_code = ErrCode}),
            State
    end.



check_handbook_resolve(ItemIdList, #r_role{role_handbook = RoleHandBook} = State) ->
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(ItemIdList, State),
    GetEssence = lists:foldl(fun(Goods, ToEssence) ->
        #p_goods{type_id = TypeId, num = Gnum} = Goods,
        case lib_config:find(cfg_handbook_prop, TypeId) of
            [] ->
                ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR);
            [#c_handbook_prop{essence = Essence}] ->
                TotalEssence = Essence * Gnum + ToEssence,
                TotalEssence
        end
    end, 0, GoodsList),

    BagDoing = [{delete, ?ITEM_REDUCE_HANDBOOK_RESOLVE, ItemIdList}],

    #r_role_handbook{essence = Essence} = RoleHandBook,
    Essence2 = GetEssence + Essence,
    State2 = State#r_role{role_handbook = RoleHandBook#r_role_handbook{essence = Essence2}},
    {ok, BagDoing, GetEssence, State2, Essence2}.



%% 图鉴升级
do_handbook_upgrade(_RoleID, _CareId, #r_role{role_handbook = undefined} = State) ->
    State;
do_handbook_upgrade(RoleID, CareId, State) ->
    case catch check_handbook_upgrade(CareId, State) of
        {ok, BagDoing, State2, UpCareId, TotalEssence} ->
            %% 扣除物品
            State3 = mod_role_bag:do(BagDoing, State2),

            common_misc:unicast(RoleID, #m_role_handbook_upgrade_toc{card_id = UpCareId}),
            common_misc:unicast(RoleID, #m_role_handbook_essence_toc{total_essence = TotalEssence}),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_HANDBOOK_UPGRADE, CareId);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_handbook_upgrade_toc{err_code = ErrCode}),
            State
    end.


check_handbook_upgrade(CareId, #r_role{role_handbook = RoleHandBook} = State) ->
    CfgHandBookCultivate = lib_config:find(cfg_handbook_cultivate, CareId),
    ?IF(CfgHandBookCultivate =:= [], ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR), ok),
    CardGid = ?GET_BASE_ID(CareId),
    ?IF(check_handbook_activate2(CardGid, CfgHandBookCultivate, State) == activate, ok, ?THROW_ERR(?ERROR_ROLE_HANDBOOK_UPGRADE_003)), %%此卡片未激活

    #r_role_handbook{essence = Essence} = RoleHandBook,
    [#c_handbook_cultivate{group = Group, upgrade_consume = UpgradeConsumeStr, essence_consume = EssenceConsume}] = CfgHandBookCultivate,
    ?IF(UpgradeConsumeStr =:= "" andalso EssenceConsume =:= 0, ?THROW_ERR(?ERROR_ROLE_HANDBOOK_UPGRADE_002), ok), %%此卡片等级已到达上限

    ?IF(Essence >= EssenceConsume, ok, ?THROW_ERR(?ERROR_ROLE_HANDBOOK_UPGRADE_001)), %%精华不足
    %% 消耗的物品是否足够
    BagDoing = mod_role_bag:check_num_by_item_list(lib_tool:string_to_intlist(UpgradeConsumeStr), ?ITEM_REDUCE_HANDBOOK_UPGRADE, State),

    Essence2 = Essence - EssenceConsume,
    %% 扣除精华
    RoleHandBook2 = RoleHandBook#r_role_handbook{essence = Essence2},
    %% 升级Id
    UpCareId = CareId + 1,
    RoleHandBook3 = updata_HandBookMaps(UpCareId, Group, RoleHandBook2),
    State2 = State#r_role{role_handbook = RoleHandBook3},

    {ok, BagDoing, State2, UpCareId, Essence2}.


%% 图鉴组属性激活
do_handbook_group_activate(_RoleID, _CareGroupId, #r_role{role_handbook = undefined} = State) ->
    State;
do_handbook_group_activate(RoleID, CareGroupId, State) ->
    case catch check_handbook_group_activate(CareGroupId, State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_role_handbook_group_activate_toc{card_group_id = CareGroupId}),
            mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_HANDBOOK_GROUP_ACT, CareGroupId);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_handbook_group_activate_toc{err_code = ErrCode}),
            State
    end.

check_handbook_group_activate(CareGroupId, #r_role{role_handbook = RoleHandBook} = State) ->
    #r_role_handbook{handbook_maps = HandBookMaps, handbook_group_maps = HandBookGroupMpas} = RoleHandBook,
    CfgHandBookCultivate = lib_config:find(cfg_handbook_group, CareGroupId),
    ?IF(CfgHandBookCultivate =:= [], ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),  %% 参数有误

    [#c_handbook_group{act_num = ActNum, star_num = StarNum}] = CfgHandBookCultivate,

    GroupId = ?GET_BASE_ID(CareGroupId),
    ActGroupIdData = maps:find(GroupId, HandBookGroupMpas),
    case ActGroupIdData of
        {ok, ActGroupIdList} ->
            ?IF(lists:member(CareGroupId, ActGroupIdList), ?THROW_ERR(?ERROR_ROLE_HANDBOOK_GROUP_ACTIVATE_001), ok);  %% 此阶已激活
        error ->
            case maps:find(GroupId, HandBookMaps) of
                {ok, CardGroupMaps} ->
                    TotalStarNum2 = maps:fold(fun(_K, CardId, TotalStarNum) ->
                        [#c_handbook_cultivate{star_lv = StarLv}] = lib_config:find(cfg_handbook_cultivate, CardId),
                        TotalStarNum + StarLv
                    end, 0, CardGroupMaps),
                    ?IF(maps:size(CardGroupMaps) >= ActNum orelse TotalStarNum2 >= StarNum, ok, ?THROW_ERR(?ERROR_ROLE_HANDBOOK_GROUP_ACTIVATE_002));
                error ->
                    ?THROW_ERR(?ERROR_ROLE_HANDBOOK_GROUP_ACTIVATE_002)
            end
    end,

    ActGroupIdList3 = case ActGroupIdData of
        {ok, ActGroupIdList2} ->
            [CareGroupId|ActGroupIdList2];
        error ->
            [CareGroupId]
    end,
    HandBookGroupMpas2 = maps:put(GroupId, ActGroupIdList3, HandBookGroupMpas),
    RoleHandBook2 = RoleHandBook#r_role_handbook{handbook_group_maps = HandBookGroupMpas2},
    State2 = State#r_role{role_handbook = RoleHandBook2},
    {ok, State2}.





updata_HandBookMaps(CareId, Group, #r_role_handbook{handbook_maps = HandBookMaps} = RoleHandBook) ->
    CardGid = ?GET_BASE_ID(CareId),
    CardGroupMaps2 = case maps:find(Group, HandBookMaps) of
        {ok, CardGroupMaps} ->
            maps:put(CardGid, CareId, CardGroupMaps);
        error ->
            maps:put(CardGid, CareId, maps:new())
    end,
    HandBookMaps2 = maps:put(Group, CardGroupMaps2, HandBookMaps),
    RoleHandBook#r_role_handbook{handbook_maps = HandBookMaps2}.


add_handbook_essence(AddEssence, #r_role{role_id = RoleID, role_handbook = RoleHandBook} = State) when AddEssence > 0 ->
    #r_role_handbook{essence = Essence} = RoleHandBook,
    TotalEssence = Essence + AddEssence,
    RoleHandBook2 = RoleHandBook#r_role_handbook{essence = TotalEssence},
    common_misc:unicast(RoleID, #m_role_handbook_essence_toc{total_essence = TotalEssence}),
    State#r_role{role_handbook = RoleHandBook2};
add_handbook_essence(_AddEssence, State) ->
    State.
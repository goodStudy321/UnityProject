%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     获取玩家数据
%%% @end
%%% Created : 29. 七月 2017 12:19
%%%-------------------------------------------------------------------
-module(common_role_data).
-author("laijichang").
-include("role.hrl").

%% API
%% 游戏服 && 跨服节点 API
-export([
    get_role_attr/1,
    get_role_name/1,
    get_role_level/1,
    get_role_power/1,
    get_role_category/1,
    get_role_vip_level/1,
    get_role_fight_attr/1
]).

-export([
    get_role_fight/1,
    get_role_skill/1,
    get_role_id_by_name/1,
    get_role_confine/1,
    get_role_relive_level/1,
    get_cur_id_list/1
]).

%%%===================================================================
%%% 游戏服 && 跨服节点调用 start
%%%===================================================================
%% 跨服调用时，有些信息可能未添加上
get_role_attr(RoleID) ->
    case common_config:is_cross_node() of
        true ->
            case cross_role_data_server:get_role_data(RoleID) of
                #r_role_cross_data{} = RoleCrossData ->
                    cross_data_to_attr(RoleCrossData);
                _ ->
                    #r_role_attr{role_id = RoleID, category = ?CATEGORY_1}
            end;
        _ ->
            case db:lookup(?DB_ROLE_ATTR_P, RoleID) of
                [#r_role_attr{} = RoleAttr] ->
                    RoleAttr;
                _ ->
                    #r_role_attr{role_id = RoleID, category = ?CATEGORY_1}
            end
    end.

get_role_name(RoleID) ->
    #r_role_attr{role_name = RoleName} = get_role_attr(RoleID),
    RoleName.

get_role_level(RoleID) ->
    #r_role_attr{level = RoleLevel} = get_role_attr(RoleID),
    RoleLevel.

get_role_category(RoleID) ->
    #r_role_attr{category = Category} = get_role_attr(RoleID),
    Category.

get_role_power(RoleID) ->
    #r_role_attr{power = Power} = get_role_attr(RoleID),
    Power.

get_role_vip_level(RoleID) ->
    case common_config:is_cross_node() of
        true ->
            case cross_role_data_server:get_role_data(RoleID) of
                #r_role_cross_data{vip_level = VipLevel} ->
                    VipLevel;
                _ ->
                    0
            end;
        _ ->
            case db:lookup(?DB_ROLE_VIP_P, RoleID) of
                [#r_role_vip{} = RoleVip] ->
                    mod_role_vip:get_vip_level_by_role_vip(RoleVip);
                _ ->
                    0
            end
    end.

get_role_fight_attr(RoleID) ->
    case common_config:is_cross_node() of
        true ->
            case cross_role_data_server:get_role_data(RoleID) of
                #r_role_cross_data{fight_attr = #actor_fight_attr{} = FightAttr} ->
                    FightAttr;
                _ ->
                    #actor_fight_attr{}
            end;
        _ ->
            case db:lookup(?DB_ROLE_FIGHT_P, RoleID) of
                [#r_role_fight{fight_attr = FightAttr}] ->
                    FightAttr;
                _ ->
                    #actor_fight_attr{}
            end
    end.

cross_data_to_attr(RoleCrossData) ->
    #r_role_cross_data{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category,
        skin_list = SkinList,
        power = Power,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
        } = RoleCrossData,
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        sex = Sex,
        level = Level,
        category = Category,
        skin_list = SkinList,
        power = Power,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.
%%%===================================================================
%%% 游戏服 && 跨服节点调用 end
%%%===================================================================


get_role_fight(RoleID) ->
    case db:lookup(?DB_ROLE_FIGHT_P, RoleID) of
        [#r_role_fight{} = RoleFight] ->
            RoleFight;
        _ ->
            #r_role_fight{role_id = RoleID, fight_attr = #actor_fight_attr{}}
    end.

get_role_skill(RoleID) ->
    case db:lookup(?DB_ROLE_SKILL_P, RoleID) of
        [#r_role_skill{} = RoleSkill] ->
            RoleSkill;
        _ ->
            #r_role_skill{role_id = RoleID}
    end.

%% 没有的时候返回 0
get_role_id_by_name(RoleName) ->
    case db:lookup(?DB_ROLE_NAME_P, RoleName) of
        [#r_role_name{role_id = RoleID}] ->
            RoleID;
        _ ->
            0
    end.

get_role_confine(RoleID) ->
    case db:lookup(?DB_ROLE_CONFINE_P, RoleID) of
        [#r_role_confine{confine = Confine}] ->
            Confine;
        _ ->
            0
    end.

get_role_relive_level(RoleID) ->
    case db:lookup(?DB_ROLE_RELIVE_P, RoleID) of
        [#r_role_relive{relive_level = ReliveLevel}] ->
            ReliveLevel;
        _ ->
            0
    end.


get_cur_id_list(RoleID) ->
    case db:lookup(?DB_ROLE_FASHION_P, RoleID) of
        [#r_role_fashion{cur_id_list = CurIDList}] ->
            CurIDList;
        _ ->
            []
    end.
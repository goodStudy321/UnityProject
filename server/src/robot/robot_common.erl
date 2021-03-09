%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 十月 2018 10:48
%%%-------------------------------------------------------------------
-module(robot_common).
-author("laijichang").
-include("role.hrl").
-include("global.hrl").
-include("proto/mod_role_bag.hrl").
-include("proto/mod_role_item.hrl").
-include("proto/mod_role_equip.hrl").
-include("proto/mod_role_skill.hrl").

%% API
-export([
    update_goods/1,
    init_equip/1,
    update_equip/1,
    init_skills/1,
    update_skills/2
]).

update_goods(UpdateList) ->
    EquipList = get_equip_list(),
    [
        ?IF(is_equip_use(TypeID, EquipList), robot_client:send_data(#m_item_use_tos{id = ID, num = 1}), ok)
        || #p_goods{id = ID, type_id = TypeID} <- UpdateList].

init_equip(EquipList) ->
    set_equip_list(EquipList).

update_equip(Equip) ->
    #p_equip{equip_id = EquipID} = Equip,
    [#c_equip{index = EquipIndex}] = lib_config:find(cfg_equip, EquipID),
    EquipList = get_equip_list(),
    EquipList2 = update_equip2(Equip, EquipIndex, EquipList, []),
    set_equip_list(EquipList2).

update_equip2(Equip, _EquipIndex, [], Acc) ->
    [Equip|Acc];
update_equip2(Equip, EquipIndex, [T|R], Acc) ->
    #p_equip{equip_id = EquipID} = T,
    [#c_equip{index = Index}] = lib_config:find(cfg_equip, EquipID),
    case EquipIndex =:= Index of
        true ->
            [Equip|R] ++ Acc;
        _ ->
            update_equip2(Equip, EquipIndex, R, [T|Acc])
    end.

is_equip_use(TypeID, EquipList) ->
    case lib_config:find(cfg_equip, TypeID) of
        [EquipConfig] ->
            is_equip_use2(EquipConfig, EquipList);
        _ ->
            false
    end.

is_equip_use2(_EquipConfig, []) ->
    true;
is_equip_use2(EquipConfig, [Equip|R]) ->
    #c_equip{id = NewID, index = Index} = EquipConfig,
    #p_equip{equip_id = EquipID} = Equip,
    [#c_equip{index = DestIndex}] = lib_config:find(cfg_equip, EquipID),
    case Index =:= DestIndex of
        true ->
            NewID > EquipID;
        _ ->
            is_equip_use2(EquipConfig, R)
    end.

init_skills(SkillList) ->
    SkillList2 = modify_skills(SkillList),
    robot_data:set_skills(SkillList2).

update_skills(UpdateList, DelList) ->
    SkillList = robot_data:get_skills(),
    SkillList2 = [ Skill || #p_skill{skill_id = SkillID} = Skill <- SkillList, not lists:member(SkillID, DelList)],
    SkillList3 = modify_skills(UpdateList ++ SkillList2),
    robot_data:set_skills(SkillList3).

modify_skills(SkillList) ->
    [
        Skill || #p_skill{skill_id = SkillID} = Skill <- SkillList,
        begin
            case lib_config:find(cfg_skill, SkillID) of
                [#c_skill{skill_type = SkillType}] ->
                    SkillType =:= ?SKILL_NORMAL orelse SkillType =:= ?SKILL_ATTACK;
                _ ->
                    false
            end
        end].


set_equip_list(EquipList) ->
    erlang:put({?MODULE, equip_list}, EquipList).
get_equip_list() ->
    erlang:get({?MODULE, equip_list}).
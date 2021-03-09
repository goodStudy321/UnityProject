%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 五月 2017 14:34
%%%-------------------------------------------------------------------
-module(mod_robot_buff).
-author("laijichang").
-include("world_robot.hrl").

%%%% API
-export([
    add_buff/2,
    loop/1
]).

add_buff(RobotID,  #buff_args{} = BuffArgs)->
    add_buff(RobotID, [BuffArgs]);
add_buff(RobotID, BuffList) ->
    case mod_robot_data:get_robot_data(RobotID) of
        #r_robot{} = RobotData ->
            add_buff2(RobotData, BuffList);
        _ ->
            ignore
    end.

add_buff2(_RobotData, []) ->
    ok;
add_buff2(RobotData, BuffList) ->
    #r_robot{robot_id = RobotID, buffs = Buffs, debuffs = Debuffs} = RobotData,
    RobotList = mod_robot_data:get_robot_buff_list(),
    {Buffs2, Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList} = common_buff:add_buff(BuffList, Buffs, Debuffs),
    RobotData2 = RobotData#r_robot{buffs = Buffs2, debuffs = Debuffs2},
    case lists:member(RobotID, RobotList) of
        true -> ok;
        _ -> mod_robot_data:set_robot_buff_list([RobotID|RobotList])
    end,
    do_update(RobotID, RobotData2, Buffs2 ++ Debuffs2, IsCalc, IsStatus, UpdateList, DelIDList).


loop(Now) ->
    RobotList = mod_robot_data:get_robot_buff_list(),
    RobotList2 =
        lists:foldl(
            fun(RobotID, Acc) ->
                case ?TRY_CATCH(loop2(Now, RobotID)) of
                    true ->
                        [RobotID|Acc];
                    _->
                        Acc
                end
        end, [], RobotList),
    mod_robot_data:set_robot_buff_list(RobotList2).

loop2(Now, RobotID) ->
    #r_robot{buffs = Buffs, debuffs = Debuffs} = RobotData = mod_robot_data:get_robot_data(RobotID),
    {Buffs2, Debuffs2, EffectList, IsCalc, IsStatus, DelIDList} = common_buff:loop(Now, Buffs, Debuffs),
    RobotData2 = RobotData#r_robot{buffs = Buffs2, debuffs = Debuffs2},
    AllBuffs = Buffs2 ++ Debuffs2,
    do_effect(RobotID, EffectList),
    do_update(RobotID, RobotData2, AllBuffs, IsCalc, IsStatus, [], DelIDList),
    AllBuffs =/= [].

do_effect(_RobotID, []) ->
    ok;
do_effect(RobotID, [Effect|R]) ->
    case Effect of
        {?BUFF_POISON, BuffID, FromActorID, Value} ->
            mod_map_robot:robot_buff_reduce_hp(RobotID, FromActorID, Value, ?BUFF_POISON, BuffID);
        {?BUFF_BURN, BuffID, FromActorID, Value} ->
            mod_map_robot:robot_buff_reduce_hp(RobotID, FromActorID, Value, ?BUFF_BURN, BuffID);
        {?BUFF_ADD_HP, BuffID, _FromActorID, Value} ->
            mod_map_robot:robot_buff_heal(RobotID, Value, ?BUFF_ADD_HP, BuffID);
        {?BUFF_ATTACK_HEAL, BuffID, _FromActorID, Value} ->
            mod_map_robot:robot_buff_heal(RobotID, Value, ?BUFF_ATTACK_HEAL, BuffID);
        {?BUFF_LEVEL_HP_BUFF, BuffID, _FromActorID, Value} ->
            mod_map_robot:robot_buff_heal(RobotID, Value, ?BUFF_LEVEL_HP_BUFF, BuffID);
        Error ->
            ?ERROR_MSG("unknow match Error :~w", [Error])
    end,
    do_effect(RobotID, R).

do_update(RobotID, RobotData, AllBuffs, IsCalc, IsStatus, UpdateList, DelIDList) ->
    case UpdateList =/= [] orelse DelIDList =/= [] of
        true ->
            AllBuffIDs = [ BuffID|| #r_buff{buff_id = BuffID} <- AllBuffs],
            UpdateIDList = [ BuffID || #r_buff{buff_id = BuffID} <- UpdateList],
            mod_map_robot:robot_update_buffs(RobotID, AllBuffIDs, UpdateIDList, DelIDList);
        _ ->
            ok
    end,
    case IsStatus of
        true ->
            BuffStatus = common_buff:recal_status(AllBuffs),
            RobotData2 = RobotData#r_robot{buff_status = BuffStatus},
            mod_map_robot:robot_update_buff_status(RobotID, BuffStatus);
        _ ->
            RobotData2 = RobotData
    end,
    case IsCalc of
        true ->
            mod_robot:recal_attr(RobotData2);
        _ ->
            mod_robot_data:set_robot_data(RobotID, RobotData2)
    end.


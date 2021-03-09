#!/usr/bin/env escript
%% -*- erlang -*-
-mode(compile).

-export([main/1]).
-include("../../include/drop.hrl").
-include("../../include/global.hrl").
-include("../../include/monster.hrl").


-define(DROP_FILE_NAME, "cfg_drop.erl").
-define(START_RANDOM_FILE_NAME, "cfg_equip_start_create.erl").
-define(MONSTER_FILE_NAME, "cfg_monster.erl").





main([]) ->
    Path = filename:dirname(escript:script_name()),
    EbinPath = Path ++ "/../../ebin/",
    code:add_path(EbinPath),
    OutPath = Path ++ "/../../config/dyn/",
    gen_drop(OutPath),
    gen_monster(OutPath),
    gen_equip_start_create(OutPath).




gen_monster(OutPath) ->
    List = get_monster_config(),
    ListOut = get_cfg_monster_output(List),
    Header = "-module(cfg_monster).
-include(\"config.hrl\").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H\n",
    Content = Header ++ ListOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?MONSTER_FILE_NAME, Content, [{encoding, utf8}]),
    ok.


gen_drop(OutPath) ->
    DropList = get_drop_config(),
    ListOut = get_cfg_drop_output(DropList),
    Header = "-module(cfg_drop).
-include(\"config.hrl\").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H\n",
    Content = Header ++ ListOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?DROP_FILE_NAME, Content, [{encoding, utf8}]),
    ok.


gen_equip_start_create(OutPath) ->
    CreateList = get_create_config(),
    ListOut = get_cfg_equip_start_create_output(CreateList),
    Header = "-module(cfg_equip_start_create).
-include(\"config.hrl\").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H\n",
    Content = Header ++ ListOut ++ "?CFG_E.",
    file:write_file(OutPath ++ ?START_RANDOM_FILE_NAME, Content, [{encoding, utf8}]),
    ok.


get_drop_config() ->
    ConfigList = cfg_drop_config:list(),
    get_drop_config2(ConfigList, []).

get_drop_config2([], List) ->
    List;
get_drop_config2([{_, Config}|T], List) ->
    NewConfig = get_new_config(Config),
    get_drop_config2(T, [NewConfig|List]).


get_new_config(#c_drop_config{drop_id = DropID, drop_times = Times} = Config) ->
    List = Config#c_drop_config.drop1 ++ "#" ++ Config#c_drop_config.drop2 ++ "#" ++ Config#c_drop_config.drop3 ++ "#" ++ Config#c_drop_config.drop4 ++ "#" ++
    Config#c_drop_config.drop5 ++ "#" ++ Config#c_drop_config.drop6,
        List2 = lib_tool:string_to_intlist(List, "#", ","),
        {SumWeight, List4} = lists:foldl(fun(Info, {Sum, List3}) ->
                case Info of
                        {Weight, Num, ItemID}->
                            RItemID = get_really_id(ItemID),
                            {Sum + Weight, [{Weight, {Num, RItemID}}|List3]};
                        {Weight, Num,ItemID,Bind}->
                            RItemID = get_really_id(ItemID),
                            {Sum + Weight, [{Weight, {Num, RItemID ,?IS_BIND(Bind)}}|List3]}
                end
            end, {0, []}, List2),
            case SumWeight < ?DROP_WEIGHT of
                true ->
                    Supplement = {?DROP_WEIGHT - SumWeight, {0, 0}},
                    List5 = [Supplement|List4];
                _->
                    List5 = List4
            end,
    #c_drop{drop_id = DropID, drop_times = Times, drop_bag_list = List5}.


get_really_id(ItemID) ->
    if
        ItemID div 1000000 =:= 10 ->
            case lib_config:find(cfg_drop_equip, ItemID) of
                [] ->
                    ItemID;
                [Config] ->
                    Color = ?GET_DROP_ID_COLOR(ItemID),
                    {Color, [{0, Config#c_drop_equip.start0}, {1, Config#c_drop_equip.start1}, {2, Config#c_drop_equip.start2}, {3, Config#c_drop_equip.start3}]}
            end;
        true ->
            ItemID
    end.


get_monster_config() ->
    MonsterList = cfg_monster_i:list(),
    ConfigList = lib_config:list(cfg_family_boss_drop),
    ConfigList2  = format_config_list(ConfigList),
    get_monster_config_i(ConfigList2,MonsterList, []).

get_monster_config_i(_FConfigList , [], List) ->
    List;
get_monster_config_i(FConfigList ,[{_, Monster}|T], List) ->
    DropList = case lib_config:find(cfg_drop_boss, Monster#c_monster.type_id) of
                    [] ->
                        [];
                    [Config] ->
                        IDList = [
                            Config#c_drop_boss.drop1, Config#c_drop_boss.drop2, Config#c_drop_boss.drop3,
                            Config#c_drop_boss.drop4, Config#c_drop_boss.drop5, Config#c_drop_boss.drop6,
                            Config#c_drop_boss.drop7, Config#c_drop_boss.drop8, Config#c_drop_boss.drop9,
                            Config#c_drop_boss.drop10, Config#c_drop_boss.drop11, Config#c_drop_boss.drop12,
                            Config#c_drop_boss.drop13, Config#c_drop_boss.drop14, Config#c_drop_boss.drop15,
                            Config#c_drop_boss.drop16, Config#c_drop_boss.drop17, Config#c_drop_boss.drop18,
                            Config#c_drop_boss.drop19, Config#c_drop_boss.drop20, Config#c_drop_boss.drop21,
                            Config#c_drop_boss.drop22, Config#c_drop_boss.drop23, Config#c_drop_boss.drop24,
                            Config#c_drop_boss.drop25,Config#c_drop_boss.drop26,Config#c_drop_boss.drop27,Config#c_drop_boss.drop28,Config#c_drop_boss.drop29,Config#c_drop_boss.drop30,
							Config#c_drop_boss.drop31, Config#c_drop_boss.drop32, Config#c_drop_boss.drop33,
                            Config#c_drop_boss.drop34, Config#c_drop_boss.drop35, Config#c_drop_boss.drop36,
                            Config#c_drop_boss.drop37, Config#c_drop_boss.drop38, Config#c_drop_boss.drop39,
							Config#c_drop_boss.drop40
                        ],
                        [DropID || DropID <- IDList, DropID =/= 0]
                end,
    SpecialDropID =
        case lib_config:find(cfg_drop_boss, Monster#c_monster.type_id) of
            [#c_drop_boss{special_drop_id = SpecialDropIDT}] ->
                SpecialDropIDT;
            _ ->
                0
        end,
    NewMonster = Monster#c_monster{special_drop_id = SpecialDropID, drop_id_list = DropList},
    get_monster_config_i(FConfigList ,T, [NewMonster|List]).
            



get_create_config() ->
    List = cfg_equip_start_create_i:list(),
    get_create_config_i(List, []).


get_create_config_i([], List) ->
    List;
get_create_config_i([{_, Create}|T], List) ->
    RandomList = [{Create#c_equip_start_create_i.start0, 0}, {Create#c_equip_start_create_i.start1, 1}, {Create#c_equip_start_create_i.start2, 2}, {Create#c_equip_start_create_i.start3, 3}],
    Config = #c_equip_start_create{color = Create#c_equip_start_create_i.color, list = RandomList},
    get_create_config_i(T, [Config|List]).


get_cfg_monster_output(Monsters) ->
    lists:foldl(
        fun(#c_monster{type_id = TypeID} = Monster, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(TypeID) ++ ", " ++ lib_tool:to_output(Monster) ++ ")\n",
            Output ++ Acc
        end, [], Monsters).

get_cfg_drop_output(DropList) ->
    lists:foldl(
        fun(#c_drop{drop_id = DropID} = Drop, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(DropID) ++ ", " ++ lib_tool:to_output(Drop) ++ ")\n",
            Output ++ Acc
        end, [], DropList).


get_cfg_equip_start_create_output(RandomList) ->
    lists:foldl(
        fun(#c_equip_start_create{color = Color} = Random, Acc) ->
            Output = "?C(" ++ lib_tool:to_output(Color) ++ ", " ++ lib_tool:to_output(Random) ++ ")\n",
            Output ++ Acc
        end, [], RandomList).


format_config_list(ConfigList)->
    format_config_list(ConfigList,[]).

format_config_list([],List)->
    List;

format_config_list(  [{_,Config} |  T] ,List)->
    format_config_list(  T ,[Config|List]).
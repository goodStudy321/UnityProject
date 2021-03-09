%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 六月 2019 11:58
%%%-------------------------------------------------------------------
-module(mod_family_box).
-author("WZP").
-include("family.hrl").
-include("global.hrl").
-include("background.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    add_box_by_role/3,
    update_box_num/3,
    open_box/3,
    add_box/4
]).


-export([
    handle/1
]).

update_box_num(RoleID, FamilyID, BoxNum) ->
    family_misc:call_family({mod, ?MODULE, {update_box_num, RoleID, FamilyID, BoxNum}}).


open_box(Box, FamilyID, RoleID) ->
    family_misc:call_family({mod, ?MODULE, {open_box, Box, FamilyID, RoleID}}).

handle({update_box_num, RoleID, FamilyID, BoxNum}) ->
    do_update_box(RoleID, FamilyID, BoxNum);
handle({open_box, Box, FamilyID, RoleID}) ->
    do_open_box(Box, FamilyID, RoleID).

add_box_by_role(Type, Value, RoleID) ->
    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
    add_box(Type, Value, FamilyID, RoleID).

add_box(Type, Value, FamilyID, RoleID) ->
    case mod_family_data:get_family_box(FamilyID) of
        #r_family_box{} = FamilyBox ->
            Level = world_data:get_world_level(),
            case get_box(Level, Type, Value) of
                {ok, BoxID} ->
                    PFamilyBox = #p_family_box{id = BoxID, end_time = time_tool:now() + ?ONE_DAY, type = Type, param = Value},
                    FamilyBox = mod_family_data:get_family_box(FamilyID),
                    {BoxList, LogList} =
                    lists:foldl(
                        fun(Info, {AccBoxList, AccLog}) ->
                            case Info#r_box_list.max_num > erlang:length(Info#r_box_list.box_list) of
                                true ->
                                    Info2 = Info#r_box_list{box_list = [PFamilyBox|Info#r_box_list.box_list]},
                                    Log = #log_role_family_box{role_id = Info#r_box_list.role_id, type = 2, box_type = BoxID, box_from = Type, box_from_value = Value},
                                    common_misc:unicast(Info#r_box_list.role_id, #m_family_box_update_toc{box_list = [PFamilyBox]}),
                                    {[Info2|AccBoxList], [Log|AccLog]};
                                _ ->
                                    Now = time_tool:now(),
                                    {IsChange, NewBoxList} = check_end_time_box(Info#r_box_list.box_list, false, Now, []),
                                    case IsChange of
                                        true ->
                                            Info2 = Info#r_box_list{box_list = [PFamilyBox|NewBoxList]},
                                            Log = #log_role_family_box{role_id = Info#r_box_list.role_id, type = 2, box_type = BoxID, box_from = Type, box_from_value = Value},
                                            common_misc:unicast(Info#r_box_list.role_id, #m_family_box_update_toc{box_list = [PFamilyBox]}),
                                            {[Info2|AccBoxList], [Log|AccLog]};
                                        _ ->
                                            {[Info|AccBoxList], AccLog}
                                    end
                            end
                        end, {[], []}, FamilyBox#r_family_box.role_box_list),
                    mod_family_data:set_family_box(FamilyBox#r_family_box{role_box_list = BoxList}),
                    Log2 = #log_family_box{family_id = FamilyID, box_type = BoxID, box_from = Type, box_from_value = Value, role_id = RoleID},
                    background_misc:log([Log2|LogList]);
                _ ->
                    ?ERROR_MSG("-------add_box-------~w", [{Level, Type, Value}])
            end;
        _ ->
            ?ERROR_MSG("-------add_box-------~w", [{FamilyID, Type, Value}])
    end.


check_end_time_box([], IsChange, _Now, List) ->
    {IsChange, List};
check_end_time_box([Info|T], IsChange, Now, List) ->
    case Info#p_family_box.end_time =< Now of
        true ->
            check_end_time_box(T, true, Now, List);
        _ ->
            check_end_time_box(T, IsChange, Now, [Info|List])
    end.



get_box(Level, Type, Value) ->
    List = cfg_box:list(),
    get_box(Level, Type, Value, List).


get_box(_Level, _Type, _Value, []) ->
    false;
get_box(Level, Type, Value, [{_, Config}|T]) ->
    case Config#c_box.type =:= Type andalso lists:member(Value, Config#c_box.value) of
        false ->
            get_box(Level, Type, Value, T);
        _ ->
            [MinLevel, MaxLevel] = Config#c_box.level_region,
            case Level >= MinLevel andalso MaxLevel >= Level of
                false ->
                    get_box(Level, Type, Value, T);
                _ ->
                    BoxList = lib_tool:string_to_intlist(Config#c_box.box_list),
                    BoxID = lib_tool:get_weight_output(BoxList),
                    {ok, BoxID}
            end
    end.

do_open_box(OpenBoxList, FamilyID, RoleID) ->
    case mod_family_data:get_family_box(FamilyID) of
        #r_family_box{role_box_list = List} = FamilyBox ->
            {value, #r_box_list{box_list = BoxList} = RoleBox, OtherRoleBox} = lists:keytake(RoleID, #r_box_list.role_id, List),
            case split_box(BoxList, OpenBoxList, []) of
                {ok, NewBoxList, OpenBoxList2} ->
                    NewRoleBox = RoleBox#r_box_list{box_list = NewBoxList},
                    FamilyBox2 = FamilyBox#r_family_box{role_box_list = [NewRoleBox|OtherRoleBox]},
                    mod_family_data:set_family_box(FamilyBox2),
                    {ok, OpenBoxList2};
                _ ->
                    {error, ?ERROR_FAMILY_BOX_OPEN_002}
            end;
        _ ->
            ?THROW_ERR(1)
    end.

split_box(BoxList, [], OpenBoxList) ->
    {ok, BoxList, OpenBoxList};
split_box(BoxList, [OpenBox|List], OpenBoxList) ->
    case split_box_i(BoxList, OpenBox, []) of
        false ->
            split_box(BoxList, List, OpenBoxList);
        {ok, BoxList2} ->
            split_box(BoxList2, List, [OpenBox|OpenBoxList])
    end.


split_box_i([], _Box, _List) ->
    false;
split_box_i([IBox|T], Box, List) ->
    case IBox =:= Box of
        false ->
            split_box_i(T, Box, [IBox|List]);
        _ ->
            {ok, T ++ List}
    end.



do_update_box(RoleID, FamilyID, BoxNum) ->
    case mod_family_data:get_family_box(FamilyID) of
        #r_family_box{role_box_list = List} = FamilyBox ->
            {value, RoleBox, OtherRoleBox} = lists:keytake(RoleID, #r_box_list.role_id, List),
            NewRoleBox = RoleBox#r_box_list{max_num = BoxNum},
            FamilyBox2 = FamilyBox#r_family_box{role_box_list = [NewRoleBox|OtherRoleBox]},
            mod_family_data:set_family_box(FamilyBox2);
        _ ->
            ?ERROR_MSG("--------do_update_box---------~w", [{RoleID, FamilyID, BoxNum}])
    end.









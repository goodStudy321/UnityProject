%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 四月 2018 10:23
%%%-------------------------------------------------------------------
-module(wzp_gm_test).
-author("WZP").
-include("role.hrl").
-include("copy.hrl").
-include("bg_act.hrl").
-include("global.hrl").
-include("family.hrl").
-include("proto/mod_role_family.hrl").
%%
%% API
-export([
    test/0,
    gm_set_family_title/3,
    gm_set_family_last_offline_time/2,
    test1/0,
    test_get_weight_output/2
]).


test() ->
    ok.


gm_set_family_title(RoleID, FamilyID, Title) ->
    Family = mod_family_data:get_family(FamilyID),
    case lists:keytake(RoleID, #p_family_member.role_id, Family#p_family.members) of
        {value, Member, Other} ->
            NewFamily = Family#p_family{members = [Member#p_family_member{title = Title}|Other]},
            mod_family_data:set_family(NewFamily);
        _ ->
            ok
    end.

gm_set_family_last_offline_time(FamilyID, Time) ->
    Family = mod_family_data:get_family(FamilyID),
    case lists:keytake(?TITLE_OWNER, #p_family_member.title, Family#p_family.members) of
        {value, Member, Other} ->
            NewFamily = Family#p_family{members = [Member#p_family_member{last_offline_time = Time}|Other]},
            mod_family_data:set_family(NewFamily);
        _ ->
            ok
    end.


test1() ->
    ?ERROR_MSG("-------111-------~w", [{?BACKGROUND_LIST}]).



test_get_weight_output(Times, #r_role{role_treasure = RoleTreasure} = State) ->
    #r_role{role_attr = #r_role_attr{level = RoleLevel, category = Category}, role_treasure = RoleTreasure} = State,
    ConfigList = cfg_equip_treasure:list(),
    {FirstList, SecondList, ControlList} = mod_role_treasure:get_equip_config(RoleLevel, Category, ConfigList, [], [], []),
    Res = get_pos_num(FirstList, [],0),
    Res2 = get_pos_num(SecondList, [],0),
    Res3 = get_pos_num(ControlList, [],0),
    ?ERROR_MSG("------------------Res---------------------------~w", [Res]),
    ?ERROR_MSG("------------------Res2---------------------------~w", [Res2]),
    ?ERROR_MSG("------------------Res3---------------------------~w", [Res3]),
    ?ERROR_MSG("------------------FirstList---------------------------~w", [FirstList]),
    ?ERROR_MSG("------------------Times---------------------------~w", [Times]),
    State.

get_pos_num([], List , AllWeight)->
    {List,AllWeight};
get_pos_num([{Weight2, Config}|T], List,AllWeight) ->
    case lists:keytake(Config#c_equip_treasure.type_id, 1, List) of
        {value, {_, Weight}, Other} ->
            get_pos_num(T, [{Config#c_equip_treasure.type_id, Weight + Weight2}|Other] , AllWeight + Weight2);
        _ ->
            get_pos_num(T, [{Config#c_equip_treasure.type_id, Weight2}|List], AllWeight + Weight2)
    end.




%%    Url = "http://192.168.2.250:82/index/index/activity?agent_id=" ++ lib_tool:to_list(1) ++ "&server_id=" ++ lib_tool:to_list(1),
%%    case httpc:request(get, {Url, []}, [{timeout, 5000}], [], default) of
%%        {ok, {{_, 200, _}, _Header, Body}} when Body =/= "[]" ->
%%            {ok, {obj, [{"status", _Res}, {"data", DataList}]}, []} = rfc4627:decode(Body),
%%            BGActInfoList = [
%%                #bg_act_info{id = ID, channel_id = lib_tool:to_list(ChannelId), game_channel_id = lib_tool:to_list(GameChannelId), type = Type, title = lib_tool:to_list(Title), min_level = MinLevel,
%%                             explain = lib_tool:to_list(Explain), time_slot = lib_tool:to_list(TimeSlot), condition_id = lib_tool:to_list(ConditionId), background_img = lib_tool:to_list(BackgroundImg),
%%                             is_visible = IsVisible, time = lib_tool:to_list(Time), config_list = ConfigList}
%%                || {obj, [{"id", ID}, {"channel_id", ChannelId}, {"game_channel_id", GameChannelId}, {"type", Type}, {"title", Title}, {"min_level", MinLevel},
%%                          {"explain", Explain}, {"time_slot", TimeSlot}, {"condition_id", ConditionId}, {"background_img", BackgroundImg}, {"is_visible", IsVisible},
%%                          {"time", Time}, {"config", ConfigList}]} <- DataList],
%%            BGActInfoList2 = [
%%                begin
%%                    ConfigList2 = tran_config_list(BGActInfo#bg_act_info.config_list),
%%                    BGActInfo#bg_act_info{config_list = ConfigList2}
%%                end
%%                || BGActInfo <- BGActInfoList],
%%            ?ERROR_MSG("--------------BGActInfoList----------------~w", [BGActInfoList2]),
%%            ok;
%%        Reason ->
%%            ?ERROR_MSG("--------------Reason----------------~w", [Reason])
%%    end.
%%
%%
%%tran_config_list(ConfigList) ->
%%    tran_config_list(ConfigList, []).
%%
%%tran_config_list([], List) ->
%%    List;
%%tran_config_list([Config|T], List) ->
%%    {obj, [{"id", ID}, {"title", Title}, {"condition", Condition}, {"items", Items}, {"sort", Sort}, {"status", Status}]} = Config,
%%    NewConfig = #bg_act_config_info{id = ID, title = lib_tool:to_list(Title), condition = lib_tool:to_list(Condition), items = lib_tool:to_list(Items), sort = Sort, status = Status},
%%    ?ERROR_MSG("--------------NewConfig----------------~w", [NewConfig]),
%%    tran_config_list(T, [NewConfig|List]).



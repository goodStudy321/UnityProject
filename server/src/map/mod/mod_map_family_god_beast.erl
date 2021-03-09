%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 六月 2019 20:34
%%%-------------------------------------------------------------------
-module(mod_map_family_god_beast).
-author("WZP").

%% API

-include("common.hrl").
-include("family_boss.hrl").
-include("monster.hrl").
-include("family_god_beast.hrl").
-include("daily_liveness.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_fgb.hrl").
-include("proto/mod_role_map.hrl").

%% API
-export([
    handle/1,
    loop/1,
    role_enter_map/1
]).

-export([
    role_inspire/2,
    do_hurt/2,
    boss_killed/0,
    get_activity_info/3,
    set_boss_id/1,
    get_all_inspire/1,
    get_activity_info/2
]).

role_enter_map(RoleID) ->
    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
    Data = mod_family_god_beast:get_family_data(FamilyID),
    InspireNumAll = get_all_inspire(Data#r_family_god_beast_rank.inspire_member),
    case InspireNumAll > 0 of
        true ->
            BuffID = calc_new_buff(InspireNumAll),
            mod_role_fgb:add_buff(BuffID, RoleID);
        _ ->
            ok
    end.

role_inspire(RoleID, FamilyID) ->
    pname_server:call(map_misc:get_map_pname(?MAP_FAMILY_BOSS, 1), {mod, mod_map_family_god_beast, {role_inspire, RoleID, FamilyID}}).

get_activity_info(FamilyID, RoleID, MapPID) ->
    pname_server:send(MapPID, {mod, mod_map_family_god_beast, {get_activity_info, FamilyID, RoleID}}).

handle({role_inspire, RoleID, FamilyID}) ->
    do_role_inspire(RoleID, FamilyID);
handle(map_end) ->
    do_map_end();
handle({boss_id, TableName}) ->
    init_boss(TableName);
handle({get_activity_info, FamilyID, RoleID}) ->
    get_activity_info(FamilyID, RoleID);
handle({family_member_leave, FamilyID, RoleID}) ->
    do_family_member_leave(FamilyID, RoleID);
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).


do_family_member_leave(FamilyID, RoleID) ->
    FamilyData = mod_family_god_beast:get_family_data(FamilyID),
    case lists:keytake(RoleID, #p_kv.id, FamilyData#r_family_god_beast_rank.member_hurt) of
        {value, #p_kv{}, OtherList} ->
            NewMemberHurt = OtherList,
            NewMemberNum = FamilyData#r_family_god_beast_rank.member_num - 1,
            mod_family_god_beast:set_family_data(FamilyData#r_family_god_beast_rank{member_hurt = NewMemberHurt, member_num = NewMemberNum});
        _ ->
            ok
    end.

init_boss(TableName) ->
    mod_family_god_beast:set_ets_name(TableName),
    Level = world_data:get_world_level(),
    {BossID, BossType} = mod_family_god_beast:get_boss_id_by_world_lv(Level),
    set_boss_type_id(BossID),
    [GlobalConfig] = lib_config:find(cfg_global, ?FAMILY_GOD_BEAST_GLOBAL),
    [X, Z, D] = GlobalConfig#c_global.list,
    RecordPos = map_misc:get_pos_by_offset_pos(X, Z, D),
    MonsterData = [#r_monster{type_id = BossType, born_pos = RecordPos}],
    mod_map_monster:born_monsters(MonsterData),
    [A, B|_] = string:tokens(GlobalConfig#c_global.string, lib_tool:to_list(",")),
    [BuffID|_] = string:tokens(A, lib_tool:to_list(":")),
    ?INFO_MSG("----BuffID--------~w", [BuffID]),
    [OneTimes, AllTimes|_] = string:tokens(B, lib_tool:to_list(":")),
    set_inspire_all_times(lib_tool:to_integer(AllTimes)),
    set_inspire_one_times(lib_tool:to_integer(OneTimes)),
    set_min_buff(lib_tool:to_integer(BuffID)),
    set_end_time(time_tool:now() + 480),
    set_boss_live(true),
    mod_family_god_beast:set_hurt_time().


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   map_server   open %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

do_hurt(ReduceHp, SrcID) ->
    ReduceHp2 = lib_tool:ceil(ReduceHp),
    #r_role_family{family_id = Family} = mod_family_data:get_role_family(SrcID),
    Info = mod_family_god_beast:get_family_data(Family),
    case lists:keytake(SrcID, #p_kv.id, Info#r_family_god_beast_rank.member_hurt) of
        {value, #p_kv{val = Val}, OtherList} ->
            Val2 = Val + ReduceHp2,
            MemberNum = Info#r_family_god_beast_rank.member_num,
            MemberHurt2 = [#p_kv{id = SrcID, val = Val2}|OtherList];
        _ ->
            MemberNum = Info#r_family_god_beast_rank.member_num + 1,
            Val2 = ReduceHp2,
            MemberHurt2 = [#p_kv{id = SrcID, val = Val2}|Info#r_family_god_beast_rank.member_hurt]
    end,
    Hurt = Info#r_family_god_beast_rank.hurt + ReduceHp2,
    mod_family_god_beast:set_family_data(Info#r_family_god_beast_rank{member_num = MemberNum, member_hurt = MemberHurt2, hurt = Hurt}),
    mod_family_god_beast:set_hurt_time().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   map_server  close %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

loop(Now) ->
    case Now - mod_family_god_beast:get_hurt_time() =< 1 of
        false ->
            ok;
        _ ->
            case mod_map_ets:get_actor_mapinfo(get_boss_id()) of
                #r_map_actor{hp = HP} ->
                    ReduceHp = get_reduce_hp(),
                    ReduceHp2 = case erlang:is_integer(ReduceHp) of
                                    false ->
                                        set_reduce_hp(HP div 480),
                                        HP div 480;
                                    _ ->
                                        ReduceHp
                                end,

%%                    测试
%%                    set_reduce_hp(1),
%%                    get_reduce_hp(),
%%                    ReduceHp2  = HP,
%%                    测试

                    mod_map_actor:reduce_hp(get_boss_id(), get_boss_id(), ReduceHp2),
                    RankList = mod_family_god_beast:get_family_data(),
                    RankList2 = lists:sort(
                        fun(A, B) ->
                            A#r_family_god_beast_rank.hurt > B#r_family_god_beast_rank.hurt
                        end, RankList

                    ),
                    deal_info(RankList2, 1, []);
                _ ->
                    ok
            end
    end.

deal_info([], _Rank, List) ->
    map_server:send_all_gateway(#m_role_fgb_rank_b_toc{type = get_rank_type_num(), list = List});

deal_info([RankInfo|T], Rank, List) ->
    mod_family_god_beast:set_family_data(RankInfo#r_family_god_beast_rank{rank = Rank}),
    PRankInfo = #p_fgb_rank{family_name = RankInfo#r_family_god_beast_rank.family_name, hurt_num = RankInfo#r_family_god_beast_rank.hurt, rank = Rank, num = RankInfo#r_family_god_beast_rank.member_num},
    deal_info(T, Rank + 1, [PRankInfo|List]).

get_rank_type_num() ->
    case mod_family_god_beast:get_ets_name() of
        ?ETS_FAMILY_GOD_BEAST_RANK_A ->
            1;
        _ ->
            2
    end.



get_activity_info(FamilyID, RoleID) ->
    case mod_family_god_beast:get_ets_name() of
        ?ETS_FAMILY_GOD_BEAST_RANK_A ->
            InsertNumB = 0, BHP = 100, Type = 1,
            InsertNumA2 = case mod_family_god_beast:get_family_data_by_name(?ETS_FAMILY_GOD_BEAST_RANK_A, FamilyID) of
                              #r_family_god_beast_rank{member_num = InsertNumA} ->
                                  InsertNumA;
                              _ ->
                                  0
                          end,
            AHP = case mod_map_ets:get_actor_mapinfo(get_boss_id()) of
                      #r_map_actor{hp = HP, max_hp = MaxHp} ->
                          lib_tool:ceil(HP / MaxHp * 100);
                      _ ->
                          ?IF(get_boss_live(), 100, 0)
                  end;
        _ ->
            Type = 2,
            InsertNumA2 = case mod_family_god_beast:get_family_data_by_name(?ETS_FAMILY_GOD_BEAST_RANK_A, FamilyID) of
                              #r_family_god_beast_rank{member_num = InsertNumA} ->
                                  InsertNumA;
                              _ ->
                                  0
                          end,
            AHP = 0,
            InsertNumB = case mod_family_god_beast:get_family_data_by_name(?ETS_FAMILY_GOD_BEAST_RANK_B, FamilyID) of
                             [] ->
                                 0;
                             DataB ->
                                 DataB#r_family_god_beast_rank.member_num
                         end,
            BHP = case mod_map_ets:get_actor_mapinfo(get_boss_id()) of
                      #r_map_actor{hp = HP, max_hp = MaxHp} ->
                          lib_tool:ceil(HP / MaxHp * 100);
                      _ ->
                          ?IF(get_boss_live(), 100, 0)
                  end
    end,
    common_misc:unicast(RoleID, #m_role_fgb_toc{type = Type, a_num = InsertNumA2, a_hp = AHP, b_num = InsertNumB, b_hp = BHP}).

get_all_inspire(List) ->
    get_all_inspire(List, 0).

get_all_inspire([], Num) ->
    Num;
get_all_inspire([#p_kv{val = Val}|T], Num) ->
    get_all_inspire(T, Num + Val).





do_role_inspire(RoleID, FamilyID) ->
    case catch check_role_inspire(RoleID, FamilyID) of
        {ok, InspireNumAll, InspireNum} ->
            {ok, InspireNumAll, InspireNum};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_role_inspire(RoleID, FamilyID) ->
    Data = mod_family_god_beast:get_family_data(FamilyID),
    InspireNumAll = get_all_inspire(Data#r_family_god_beast_rank.inspire_member),
%%    ?IF(get_inspire_all_times() > InspireNumAll, ok,ok),
    ?IF(get_inspire_all_times() > InspireNumAll, ok, ?THROW_ERR(?ERROR_ROLE_FGB_INSPIRE_002)),
    case lists:keytake(RoleID, #p_kv.id, Data#r_family_god_beast_rank.inspire_member) of
        {value, #p_kv{val = InspireNum}, OtherList} ->
            NewList = [#p_kv{id = RoleID, val = InspireNum + 1}|OtherList];
        _ ->
            NewList = [#p_kv{id = RoleID, val = 1}|Data#r_family_god_beast_rank.inspire_member],
            InspireNum = 0
    end,
%%    ?IF(get_inspire_one_times() > InspireNum, ok, ok),
    ?IF(get_inspire_one_times() > InspireNum, ok, ?THROW_ERR(?ERROR_ROLE_FGB_INSPIRE_001)),
    Data2 = Data#r_family_god_beast_rank{inspire_member = NewList},
    mod_family_god_beast:set_family_data(Data2),
    InspireNumAll2 = InspireNumAll + 1,
    BuffID = calc_new_buff(InspireNumAll2),
    [begin
         case mod_map_ets:get_actor_mapinfo(MemberID) of
             #r_map_actor{} ->
                 mod_role_fgb:add_buff(BuffID, MemberID);
             _ ->
                 ok
         end
     end || #p_kv{id = MemberID} <- Data2#r_family_god_beast_rank.member_hurt],
    common_broadcast:bc_record_to_family(FamilyID, #m_role_fgb_inspire_update_toc{all_inspire = InspireNumAll2}),
    {ok, InspireNumAll2, InspireNum + 1}.


calc_new_buff(InspireNumAll) ->
    get_min_buff() + InspireNumAll - 1.

boss_killed() ->
    set_boss_live(false),
    loop(time_tool:now()),
    world_activity_server:info({mod, mod_family_god_beast, {boss_killed, get_boss_type_id()}}),
    erlang:send_after(30000, erlang:self(), {mod, mod_map_family_bs, do_map_end_i}).


set_end_time(Time) ->
    erlang:put({?MODULE, end_time}, Time).
%%get_end_time() ->
%%    erlang:get({?MODULE, end_time}).


set_reduce_hp(Hp) ->
    erlang:put({?MODULE, reduce_hp}, Hp).

get_reduce_hp() ->
    erlang:get({?MODULE, reduce_hp}).

%%get_end_time() ->
%%    erlang:get({?MODULE, end_time}).



set_inspire_all_times(Times) ->
    erlang:put({?MODULE, inspire_all_times}, Times).
get_inspire_all_times() ->
    erlang:get({?MODULE, inspire_all_times}).
set_inspire_one_times(Times) ->
    erlang:put({?MODULE, inspire_one_times}, Times).

get_inspire_one_times() ->
    erlang:get({?MODULE, inspire_one_times}).

set_min_buff(BuffID) ->
    erlang:put({?MODULE, buff}, BuffID).
get_min_buff() ->
    erlang:get({?MODULE, buff}).

set_boss_id(BossID) ->
    erlang:put({?MODULE, boss_id}, BossID).
get_boss_id() ->
    erlang:get({?MODULE, boss_id}).


set_boss_live(Bool) ->
    erlang:put({?MODULE, boss_live}, Bool).
get_boss_live() ->
    erlang:get({?MODULE, boss_live}).

%%   掉落表ID
set_boss_type_id(BossID) ->
    erlang:put({?MODULE, boss_type}, BossID).
get_boss_type_id() ->
    erlang:get({?MODULE, boss_type}).

do_map_end() ->
    map_server:kick_all_roles(),
    map_server:delay_shutdown(1).



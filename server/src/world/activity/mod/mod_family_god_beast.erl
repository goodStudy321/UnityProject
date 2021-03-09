%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 六月 2019 19:40
%%%-------------------------------------------------------------------
-module(mod_family_god_beast).
-author("WZP").
-include("family_god_beast.hrl").
-include("activity.hrl").
-include("global.hrl").
-include("daily_liveness.hrl").
-include("monster.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_fgb.hrl").

%% API
-export([
    init/0,
    activity_prepare/0,
    activity_start/0,
    activity_end/0,
    zeroclock/0,
    handle/1,
    loop/1
]).


-export([
    boss_killed/1
]).

-export([
    get_boss_id_by_world_lv/1,
    get_family_data_by_name/2,
    get_all_drop_id_by_rank/2,
    get_family_data/1,
    set_family_data/1,
    get_family_data/0,
    get_hurt_time/0,
    set_hurt_time/0,
    set_ets_name/1,
    get_ets_name/0,
    get_map_pid/0
]).






init() ->
    lib_tool:init_ets(?ETS_FAMILY_GOD_BEAST_RANK_A, #r_family_god_beast_rank.family_id),
    lib_tool:init_ets(?ETS_FAMILY_GOD_BEAST_RANK_B, #r_family_god_beast_rank.family_id),
    ok.


activity_prepare() ->
    set_boss_live(true),
    TableName = case world_data:get_fgb() of
                    1 ->
                        set_ets_name(?ETS_FAMILY_GOD_BEAST_RANK_A),
                        ?ETS_FAMILY_GOD_BEAST_RANK_A;
                    _ ->
                        set_ets_name(?ETS_FAMILY_GOD_BEAST_RANK_B),
                        ?ETS_FAMILY_GOD_BEAST_RANK_B
                end,
    start_map(TableName).

activity_start() ->
    ok.

loop(Now) ->
    Now.

zeroclock() ->
    world_data:set_fgb(1),
    ets:delete_all_objects(?ETS_FAMILY_GOD_BEAST_RANK_A),
    ets:delete_all_objects(?ETS_FAMILY_GOD_BEAST_RANK_B).

activity_end() ->
    ?IF(get_boss_live(), pname_server:send(get_map_pid(), {mod, mod_map_family_god_beast, map_end}), ok),
    Type = world_data:get_fgb(),
    world_data:set_fgb(Type + 1),
    ok.


start_map(TableName) ->
    MapPName = map_misc:get_map_pname(?MAP_FAMILY_BOSS, 1),
    case erlang:whereis(MapPName) of
        PID when erlang:is_pid(PID) ->
            ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR);
        _ ->
            {ok, MapPID} = map_sup:start_map(?MAP_FAMILY_BOSS, 1),
            pname_server:send(MapPID, {mod, mod_map_family_god_beast, {boss_id, TableName}}),
            set_map_pid(MapPID)
    end.

handle({boss_killed, BossID}) ->
    do_boss_killed(BossID);
handle({role_info, FamilyID, RoleID}) ->
    role_info(FamilyID, RoleID);
handle({family_member_leave, FamilyID, RoleID}) ->
    pname_server:send(get_map_pid(), {mod, mod_map_family_god_beast, {family_member_leave, FamilyID, RoleID}});
handle(Info) ->
    ?ERROR_MSG("Unknow Info : ~w", [Info]).



get_boss_id_by_world_lv(Level) ->
    [Config] = lib_config:find(cfg_fgb, 1),
    [_MinLevel, MaxLevel] = string:tokens(Config#c_fgb.level, "|"),
    ?IF(lib_tool:to_integer(MaxLevel) >= Level, {Config#c_fgb.id, Config#c_fgb.boss_id}, get_boss_id_by_world_lv(Config, Level)).

get_boss_id_by_world_lv(Config, Level) ->
    case lib_config:find(cfg_fgb, Config#c_fgb.id + 1) of
        [] ->
            {Config#c_fgb.id, Config#c_fgb.boss_id};
        [NextConfig] ->
            [MinLevel, MaxLevel] = string:tokens(NextConfig#c_fgb.level, "|"),
            case lib_tool:to_integer(MaxLevel) >= Level andalso lib_tool:to_integer(MinLevel) =< Level of
                true ->
                    {NextConfig#c_fgb.id, NextConfig#c_fgb.boss_id};
                _ ->
                    get_boss_id_by_world_lv(NextConfig, Level)
            end
    end.

boss_killed(BossID) ->
    pname_server:send(map_common_dict:get_map_pid(), {mod, ?MODULE, boss_killed, BossID}).

role_info(FamilyID, RoleID) ->
    case mod_family_god_beast:get_ets_name() of
        ?ETS_FAMILY_GOD_BEAST_RANK_A ->
            InsertNumB = 0, BHP = 100, Type = 1,
            InsertNumA2 = case mod_family_god_beast:get_family_data_by_name(?ETS_FAMILY_GOD_BEAST_RANK_A, FamilyID) of
                              #r_family_god_beast_rank{member_num = InsertNumA} ->
                                  InsertNumA;
                              _ ->
                                  0
                          end,
            AHP = 0;
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
            BHP = 0
    end,
    common_misc:unicast(RoleID, #m_role_fgb_toc{type = Type, a_num = InsertNumA2, a_hp = AHP, b_num = InsertNumB, b_hp = BHP}).

do_boss_killed(BossID) ->
    set_boss_live(false),
    [Config] = lib_config:find(cfg_fgb, BossID),
    RankList = ets:tab2list(get_ets_name()),
    [
        begin
            #r_family_god_beast_rank{member_hurt = Members, rank = Rank, family_id = FamilyID} = RankInfo,
            family_server:add_box(?GLOBAL_FAMILY_BOX_FBG_BOSS, Config#c_fgb.boss_id, FamilyID, 0),
            MemberIDS = [begin
                             case Member#p_kv.val > 0 of
                                 true ->
                                     mod_role_daily_liveness:trigger_daily_liveness(Member#p_kv.id, ?LIVENESS_FAMILY_BS);
                                 _ ->
                                     ok
                             end,
                             Member#p_kv.id
                         end || Member <- Members],
            DropList = get_all_drop_id_by_rank(Config, Rank),
            DropList2 = [lib_tool:to_integer(DropID2) || DropID2 <- string:tokens(Config#c_fgb.family_drop, "|")],
            Items = lists:foldl(
                fun(DropID, AccList) ->
                    mod_map_drop:get_drop_by_item_control(DropID) ++ AccList
                end, [], DropList ++ DropList2),
            FamilyGoodList = [#p_goods{type_id = TypeID, num = Num, bind = Bind} || {TypeID, Num, Bind} <- Items],
            case FamilyGoodList =/= [] andalso mod_family_data:get_family(FamilyID) =/= undefined of
                true ->  %%防止帮派中途解散适应
                    mod_auction_operation:family_auction_goods(FamilyID, MemberIDS, FamilyGoodList);
                _ ->
                    ok
            end,
            lists:foreach(
                fun(RoleID) ->
                    mod_role_fgb:send_reward(Config#c_fgb.self_drop, FamilyGoodList, RoleID)
                end, MemberIDS)
        end || RankInfo <- RankList].

get_all_drop_id_by_rank(Config, Rank) ->
    Drop = if
               Rank =:= 1 -> Config#c_fgb.first_drop;
               Rank =:= 2 -> Config#c_fgb.second_drop;
               Rank =:= 3 -> Config#c_fgb.third_drop;
               Rank =:= 4 -> Config#c_fgb.fourth_drop;
               Rank =:= 5 -> Config#c_fgb.fifth_drop;
               true ->
                   Config#c_fgb.other_drop
           end,
    List = string:tokens(Drop, "|"),
    [lib_tool:to_integer(DropID) || DropID <- List].

get_family_data(Family) ->
    case ets:lookup(get_ets_name(), Family) of
        [] ->
            #p_family{family_name = FamilyName} = mod_family_data:get_family(Family),
            #r_family_god_beast_rank{family_id = Family, family_name = FamilyName};
        [Info] ->
            Info
    end.

get_family_data() ->
    ets:tab2list(get_ets_name()).


get_family_data_by_name(Name, FamilyID) ->
    case ets:lookup(Name, FamilyID) of
        [Data] ->
            Data;
        _ ->
            []
    end.

set_family_data(Info) ->
    ets:insert(get_ets_name(), Info).

set_ets_name(TableName) ->
    erlang:put({?MODULE, table_name}, TableName).

get_ets_name() ->
    erlang:get({?MODULE, table_name}).


set_hurt_time() ->
    erlang:put({?MODULE, hurt_time}, time_tool:now()).

get_hurt_time() ->
    erlang:get({?MODULE, hurt_time}).


set_map_pid(Pid) ->
    erlang:put({?MODULE, map_pid}, Pid).

get_map_pid() ->
    erlang:get({?MODULE, map_pid}).


set_boss_live(Bool) ->
    erlang:put({?MODULE, boss_live}, Bool).
get_boss_live() ->
    erlang:get({?MODULE, boss_live}).
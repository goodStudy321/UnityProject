%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 九月 2019 11:25
%%%-------------------------------------------------------------------
-module(copy_universe).
-author("laijichang").
-include("copy.hrl").
-include("monster.hrl").

%% API
%% API
-export([
    role_init/1,
    init/1,
    loop/1,
    role_dead/1,
    copy_end/1,
    get_finish_args/1
]).

role_init(CopyInfo) ->
    CopyInfo2 = CopyInfo#r_map_copy{mod_args = 0, all_wave = erlang:length(get_monster_datas(CopyInfo))},
    copy_data:set_copy_info(CopyInfo2),
    loop({time_tool:now(), CopyInfo2}).

init(CopyInfo) ->
    MonsterDatas = get_monster_datas(CopyInfo),
    mod_map_monster:born_monsters(MonsterDatas).

loop({_Now, CopyInfo}) ->
    #r_map_copy{
        mod_args = OldPower,
        enter_roles = EnterRoles
    } = CopyInfo,
    case EnterRoles of
        [RoleID|_] ->
            case mod_map_ets:get_actor_mapinfo(RoleID) of
                #r_map_actor{role_extra = #p_map_role{power = NowPower}} ->
                    copy_data:set_copy_info(CopyInfo#r_map_copy{mod_args = erlang:max(NowPower, OldPower)});
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

get_monster_datas(CopyInfo) ->
    #r_map_copy{map_id = MapID} = CopyInfo,
    [#c_copy_universe{
        monster_type_id = TypeID,
        monster_num = BornNum,
        monster_pos = StringPos,
        monster_dir = MonsterDir}
    ] = lib_config:find(cfg_copy_universe, MapID),
    BornPosList = copy_misc:get_pos_list(StringPos),
    [
        begin
            Pos = copy_misc:get_pos(BornPosList),
            #r_monster{
                type_id = TypeID,
                born_pos = Pos#r_pos{mdir = MonsterDir}}
        end|| _Num <- lists:seq(1, BornNum)].

role_dead({_RoleID, _SrcID, _SrcType}) ->
    copy_common:do_copy_end(?COPY_FAILED).

copy_end(_CopyInfo) ->
    [ begin
          mod_map_actor:add_hp(RoleID, 9999999999),
          {ok, BornPos} = map_misc:get_born_pos(map_common_dict:get_map_id()),
          mod_map_actor:map_change_pos(RoleID, BornPos, map_misc:pos_encode(BornPos), ?ACTOR_MOVE_NORMAL, 0)
      end|| RoleID <- mod_map_ets:get_in_map_roles()].

get_finish_args(CopyInfo) ->
    #r_map_copy{mod_args = ModArgs} = CopyInfo,
    ModArgs.

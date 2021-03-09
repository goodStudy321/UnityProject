%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 五月 2017 12:30
%%%-------------------------------------------------------------------
-module(mod_role_dict).
-include("role.hrl").
-include("global.hrl").
-include("offline_solo.hrl").

-export([
    set_role_id/1,
    get_role_id/0,
    set_gateway_pid/1,
    get_gateway_pid/0,
    set_ip/1,
    get_ip/0,
    set_device_args/1,
    get_device_args/0,
    set_server_id/1,
    get_server_id/0,
    set_imei/1,
    get_imei/0,
    set_uid/1,
    get_uid/0,
    set_account_name/1,
    get_account_name/0,
    set_game_chanel_id/1,
    get_game_chanel_id/0,
    set_login_state/1,
    get_login_state/0,
    set_login_roles/1,
    get_login_roles/0,
    set_min_ts/1,
    get_min_ts/0,
    set_ten_min_ts/1,
    get_ten_min_ts/0,
    set_create_info/1,
    get_create_info/0,
    set_map_pid/1,
    get_map_pid/0,
    set_skill_effect/2,
    get_skill_effect/1,
    set_skill_add_hurt/1,
    get_skill_add_hurt/0,
    set_skill_add_num/1,
    get_skill_add_num/0,
    set_skill_cd_reduce/1,
    get_skill_cd_reduce/0,
    set_skill_times/1,
    get_skill_times/0,
    set_attack_again/2,
    get_attack_again/1,
    set_pre_enter/1,
    get_pre_enter/0,
    erase_pre_enter/0,
    set_weapon_state/1,
    get_weapon_state/0,
    set_weapon_state_time/1,
    get_weapon_state_time/0,
    set_last_attack_time/2,
    get_last_attack_time/1,
    set_fight_time/1,
    get_fight_time/0,
    set_friend_recommend/1,
    get_friend_recommend/0,
    set_all_letter/1,
    get_all_letter/0,
    set_gm_letters/1,
    get_gm_letters/0,
    set_family_cache_info/1,
    get_family_cache_info/0,
    set_ranks/1,
    get_ranks/0,
    set_rank_time/1,
    get_rank_time/0,
    set_rank_update/1,
    get_rank_update/0,
    set_home_ref/1,
    get_home_ref/0,
    cancel_home_ref/0,
    set_attack_times/2,
    get_attack_times/1,
    erase_attack_times/1,
    set_offline_solo/1,
    get_offline_solo/0,
    set_recover_counter/1,
    get_recover_counter/0,
    set_recover_hp_abs/1,
    get_recover_hp_abs/0,
    set_recover_hp_rate/1,
    get_recover_hp_rate/0,
    set_war_spirit_time/1,
    get_war_spirit_time/0,
    set_war_spirit_buff_effects/1,
    erase_war_spirit_buff_effects/0,
    set_category/1,
    get_category/0,
    set_receive_flower/1,
    get_receive_flower/0,
    add_background_logs/1,
    set_background_logs/1,
    get_background_logs/0,
    add_pf_logs/1,
    set_pf_logs/1,
    get_pf_logs/0,
    set_must_double_effect/1,
    erase_must_double_effect/0,
    set_old_hp_rate/1,
    get_old_hp_rate/0,
    set_auction_show_ids/1,
    get_auction_show_ids/0,
    add_panel_attr/2,
    set_panel_attr_list/1,
    get_panel_attr_list/0
]).

-export([
    is_time_able/1,
    add_key_time/2
]).

set_role_id(RoleID) ->
    erlang:put({?MODULE, role_id}, RoleID).
get_role_id() ->
    erlang:get({?MODULE, role_id}).

set_gateway_pid(GatewayPID) ->
    erlang:put({?MODULE, gateway_pid}, GatewayPID).
get_gateway_pid() ->
    erlang:get({?MODULE, gateway_pid}).

set_ip(IP) ->
    erlang:put({?MODULE, ip}, IP).
get_ip() ->
    erlang:get({?MODULE, ip}).

set_device_args(DeviceArgs) ->
    erlang:put({?MODULE, device_args}, DeviceArgs).
get_device_args() ->
    erlang:get({?MODULE, device_args}).

set_server_id(ServerID) ->
    erlang:put({?MODULE, server_id}, ServerID).
get_server_id() ->
    erlang:get({?MODULE, server_id}).

set_imei(IMEI) ->
    erlang:put({?MODULE, imei}, IMEI).
get_imei() ->
    erlang:get({?MODULE, imei}).

set_uid(UID) ->
    erlang:put({?MODULE, uid}, UID).
get_uid() ->
    erlang:get({?MODULE, uid}).

set_account_name(AccountName) ->
    erlang:put({?MODULE, account_name}, AccountName).
get_account_name() ->
    erlang:get({?MODULE, account_name}).

set_game_chanel_id({ChannelID, GameChannelID}) ->
    erlang:put({?MODULE, game_chanel_id}, {ChannelID, GameChannelID}).
get_game_chanel_id() ->
    erlang:get({?MODULE, game_chanel_id}).

set_login_state(State) ->
    erlang:put({?MODULE, login_state}, State).
get_login_state() ->
    erlang:get({?MODULE, login_state}).

set_login_roles(RoleIDList) ->
    erlang:put({?MODULE, login_roles}, RoleIDList).
get_login_roles() ->
    erlang:get({?MODULE, login_roles}).

set_min_ts(Time) ->
    erlang:put({?MODULE, min_ts}, Time).
get_min_ts() ->
    erlang:get({?MODULE, min_ts}).

set_ten_min_ts(Time) ->
    erlang:put({?MODULE, ten_min_ts}, Time).
get_ten_min_ts() ->
    erlang:get({?MODULE, ten_min_ts}).

set_create_info(Info) ->
    erlang:put({?MODULE, create_info}, Info).
get_create_info() ->
    erlang:get({?MODULE, create_info}).

set_map_pid(MapPID) ->
    erlang:put({?MODULE, map_pid}, MapPID).
get_map_pid() ->
    erlang:get({?MODULE, map_pid}).

set_skill_effect(SkillFun, Effect) ->
    erlang:put({?MODULE, skill_effect, SkillFun}, Effect).
get_skill_effect(SkillFun) ->
    erlang:get({?MODULE, skill_effect, SkillFun}).

set_skill_add_hurt(List) ->
    erlang:put({?MODULE, skill_add_hurt}, List).
get_skill_add_hurt() ->
    case erlang:get({?MODULE, skill_add_hurt}) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.

set_skill_add_num(List) ->
    erlang:put({?MODULE, skill_add_num}, List).
get_skill_add_num() ->
    case erlang:get({?MODULE, skill_add_num}) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.

set_skill_cd_reduce(List) ->
    erlang:put({?MODULE, skill_cd_reduce}, List).
get_skill_cd_reduce() ->
    case erlang:get({?MODULE, skill_cd_reduce}) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.

set_skill_times(Times) ->
    erlang:put({?MODULE, skill_times}, Times).
get_skill_times() ->
    case erlang:get({?MODULE, skill_times}) of
        Times when erlang:is_integer(Times) ->
            Times;
        _ ->
            0
    end.

set_attack_again(SkillID, EndTimeMs) ->
    erlang:put({?MODULE, attack_again, SkillID}, EndTimeMs).
get_attack_again(SkillID) ->
    erlang:get({?MODULE, attack_again, SkillID}).

set_pre_enter(MapEnter) ->
    erlang:put({?MODULE, pre_enter}, MapEnter).
get_pre_enter() ->
    erlang:get({?MODULE, pre_enter}).
erase_pre_enter() ->
    erlang:erase({?MODULE, pre_enter}).

set_weapon_state(State) ->
    erlang:put({?MODULE, weapon_state}, State).
get_weapon_state() ->
    case erlang:get({?MODULE, weapon_state}) of
        State when erlang:is_integer(State) -> State;
        _ -> ?MAP_WEAPON_STATE_NORMAL
    end.

set_weapon_state_time(Time) ->
    erlang:put({?MODULE, weapon_state_time}, Time).
get_weapon_state_time() ->
    erlang:get({?MODULE, weapon_state_time}).

set_last_attack_time(Type, Time) ->
    erlang:put({?MODULE, last_attack_time, Type}, Time).
get_last_attack_time(Type) ->
    case erlang:get({?MODULE, last_attack_time, Type}) of
        Time when erlang:is_integer(Time) -> Time;
        _ -> 0
    end.

set_fight_time(Time) ->
    erlang:put({?MODULE, fight_time}, Time).
get_fight_time() ->
    erlang:get({?MODULE, fight_time}).

set_friend_recommend(Info) ->
    erlang:put({?MODULE, friend_recommend}, Info).
get_friend_recommend() ->
    erlang:get({?MODULE, friend_recommend}).

set_all_letter(Flag) ->
    erlang:put({?MODULE, all_letter}, Flag).
get_all_letter() ->
    erlang:get({?MODULE, all_letter}).

set_gm_letters(GMLetters) ->
    erlang:put({?MODULE, gm_letters}, GMLetters).
get_gm_letters() ->
    case erlang:get({?MODULE, gm_letters}) of
        List when erlang:is_list(List) ->
            List;
        _ ->
            []
    end.

set_family_cache_info(Info) ->
    erlang:put({?MODULE, family_cache_info}, Info).
get_family_cache_info() ->
    erlang:get({?MODULE, family_cache_info}).

set_ranks(Ranks) ->
    erlang:put({?MODULE, ranks}, Ranks).
get_ranks() ->
    case erlang:get({?MODULE, ranks}) of
        List when erlang:is_list(List) ->
            List;
        _ ->
            []
    end.

set_rank_time(Time)->
    erlang:put({?MODULE, rank_time}, Time).
get_rank_time()->
    case erlang:get({?MODULE, rank_time}) of
        Time when erlang:is_integer(Time) ->
            Time;
        _ ->
            0
    end.

set_rank_update(Times) ->
    erlang:put({?MODULE, rank_update}, Times).
get_rank_update() ->
    case erlang:get({?MODULE, rank_update}) of
        Times when erlang:is_integer(Times) ->
            Times;
        _ ->
            0
    end.

set_home_ref(Ref) ->
    erlang:put({?MODULE, home_ref}, Ref).
get_home_ref() ->
    erlang:get({?MODULE, home_ref}).
cancel_home_ref() ->
    case erlang:erase({?MODULE, home_ref}) of
        Ref when erlang:is_reference(Ref) ->
            erlang:cancel_timer(Ref);
        _ ->
            ok
    end.

set_attack_times(Type, AttackTimes) ->
    erlang:put({?MODULE, attack_times, Type}, AttackTimes).
get_attack_times(Type) ->
    case erlang:get({?MODULE, attack_times, Type}) of
        AttackTimes when erlang:is_integer(AttackTimes) ->
            AttackTimes;
        _ ->
            0
    end.
erase_attack_times(Type) ->
    erlang:erase({?MODULE, attack_times, Type}).

set_offline_solo(SoloDict) ->
    erlang:put({?MODULE, offline_solo}, SoloDict).
get_offline_solo() ->
    case erlang:get({?MODULE, offline_solo}) of
        #r_offline_solo_dict{} = SoloDict ->
            SoloDict;
        _ ->
            #r_offline_solo_dict{}
    end.

set_recover_counter(Counter) ->
    erlang:put({?MODULE, recover_counter}, Counter).
get_recover_counter() ->
    case erlang:get({?MODULE, recover_counter}) of
        Int when erlang:is_integer(Int) ->
            Int;
        _ ->
            1
    end.

set_recover_hp_abs(RecoverHp) ->
    erlang:put({?MODULE, recover_hp_abs}, RecoverHp).
get_recover_hp_abs() ->
    case erlang:get({?MODULE, recover_hp_abs}) of
        RecoverHp when erlang:is_integer(RecoverHp) ->
            RecoverHp;
        _ ->
            0
    end.

set_recover_hp_rate(List) ->
    erlang:put({?MODULE, recover_hp_rate}, List).
get_recover_hp_rate() ->
    case erlang:get({?MODULE, recover_hp_rate}) of
        RecoverHpList when erlang:is_list(RecoverHpList) ->
            RecoverHpList;
        _ ->
            []
    end.

set_war_spirit_time(SpiritTime) ->
    erlang:put({?MODULE, war_spirit_time}, SpiritTime).
get_war_spirit_time() ->
    case erlang:get({?MODULE, war_spirit_time}) of
        Ms when erlang:is_integer(Ms) ->
            Ms;
        _ ->
            0
    end.

set_war_spirit_buff_effects({SelfBuffEffects, EnemyBuffEffects}) ->
    erlang:put({?MODULE, war_spirit_buff_effects}, {SelfBuffEffects, EnemyBuffEffects}).
erase_war_spirit_buff_effects() ->
    case erlang:get({?MODULE, war_spirit_buff_effects}) of
        {SelfBuffEffects, EnemyBuffEffects} ->
            {SelfBuffEffects, EnemyBuffEffects};
        _ ->
            {[], []}
    end.


set_category(Category) ->
    erlang:put({?MODULE, category}, Category).
get_category() ->
    erlang:get({?MODULE, category}).

is_time_able(Key) ->
    List = get_key_time_list(),
    case lists:keyfind(Key, 1, List) of
        {_, Time} ->
            ?IF(time_tool:now_ms() >= Time, ok, ?THROW_ERR(?ERROR_COMMON_ACTION_TOO_FAST));
        _ ->
            true
    end.
add_key_time(Key, CD) ->
    List = get_key_time_list(),
    Time  = time_tool:now_ms() + CD,
    List2 = lists:keystore(Key, 1, List, {Key, Time}),
    set_key_time_list(List2).

get_key_time_list() ->
    case erlang:get({?MODULE, key_time}) of
        List when erlang:is_list(List) ->
            List;
        _ ->
            []
    end.
set_key_time_list(List) ->
    erlang:put({?MODULE, key_time}, List).

set_receive_flower(RoleList) ->
    erlang:put({?MODULE, receive_flower}, RoleList).
get_receive_flower() ->
    case erlang:get({?MODULE, receive_flower}) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.

add_background_logs(Logs) when erlang:is_list(Logs) ->
    Logs2 = Logs ++ get_background_logs(),
    set_background_logs(Logs2);
add_background_logs(Log) ->
    add_background_logs([Log]).
set_background_logs(Logs) ->
    erlang:put({?MODULE, background_logs}, Logs).
get_background_logs() ->
    case erlang:get({?MODULE, background_logs}) of
        [_|_] = Logs ->
            Logs;
        _ ->
            []
    end.

add_pf_logs(Logs) when erlang:is_list(Logs) ->
    Logs2 = Logs ++ get_pf_logs(),
    set_pf_logs(Logs2);
add_pf_logs(Log) ->
    add_pf_logs([Log]).
set_pf_logs(Logs) ->
    erlang:put({?MODULE, pf_logs}, Logs).
get_pf_logs() ->
    case erlang:get({?MODULE, pf_logs}) of
        [_|_] = Logs ->
            Logs;
        _ ->
            []
    end.

set_must_double_effect(PropEffects) ->
    erlang:put({?MODULE, must_double_effect}, PropEffects).
erase_must_double_effect() ->
    case erlang:erase({?MODULE, must_double_effect}) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.

%% 每5秒设置一次
set_old_hp_rate(HpRate) ->
    erlang:put({?MODULE, old_hp_rate}, HpRate).
get_old_hp_rate() ->
    case erlang:get({?MODULE, old_hp_rate}) of
        HpRate when erlang:is_integer(HpRate) ->
            HpRate;
        _ ->
            0
    end.

set_auction_show_ids(IDs) ->
    erlang:put({?MODULE, auction_show_ids}, IDs).
get_auction_show_ids() ->
    case erlang:get({?MODULE, auction_show_ids}) of
        List when erlang:is_list(List) ->
            List;
        _ ->
            []
    end.

add_panel_attr(Key, #actor_cal_attr{} = CalcAttr) ->
    List = get_panel_attr_list(),
    List2 = lists:keystore(Key, #r_panel_calc.key, List, #r_panel_calc{key = Key, attr = CalcAttr}),
    set_panel_attr_list(List2),
    ok;
add_panel_attr(Key, CalcAttr) ->
    ?ERROR_MSG("Unknow Key:~w _CalcAttr:~w", [{Key, CalcAttr}]).

set_panel_attr_list(List) ->
    erlang:put({?MODULE, panel_attr_list}, List).
get_panel_attr_list() ->
    case erlang:get({?MODULE, panel_attr_list}) of
        List when erlang:is_list(List) ->
            List;
        _ ->
            []
    end.


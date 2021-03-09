%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 六月 2017 17:56
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(TRAP_HRL).
-define(TRAP_HRL, trap_hrl).
-include("global.hrl").

-define(TRAP_STATE_BORN, 1).
-define(TRAP_STATE_WORK, 2).

-define(TRAP_WORK_TIME, 200).
-define(TRAP_BORN_COUNTER, 1).
-define(TRAP_WORK_COUNTER, ?GET_COUNTER_BY_MS(?TRAP_WORK_TIME)).

-define(GET_COUNTER_BY_MS(Ms), (Ms div 100)).

-record(trap_args, {
    type_id,
    owner_id,
    owner_type,
    owner_level = 0,
    fight_attr,
    pos,
    pk_mode,
    camp_id
}).

-record(c_trap, {
    type_id,
    trap_name,
    time,           %% 持续时间（ms）
    length,         %% 移动长度
    skill_id        %% 技能ID
}).

-record(r_trap, {
    trap_id,
    trap_name,
    type_id,
    skill_id,
    can_attack_time = 0,
    last_attack_time = 0,
    fight_args=[],
    owner_id,
    owner_type,
    owner_level=0,
    fight_attr,
    state,
    move_speed,
    pos,
    target_pos,
    end_counter,
    attack_type,
    attack_range,
    pk_mode,
    camp_id,
    path_list=[],   %% 每Xms走的路径
    tile_list=[]    %% 每Xms经过的格子
}).

-endif.

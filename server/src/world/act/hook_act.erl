%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 六月 2018 10:27
%%%-------------------------------------------------------------------
-module(hook_act).
-author("WZP").

-include_lib("act.hrl").
-include("global.hrl").

%% API
-export([
    init_act/2,
    init_end/1,
    act_status_change/2,
    hour/3,
    zero/1,
    terminate/1
]).




init_act(#r_act{id = ID, start_time = StartTime}, Now) ->
    case StartTime =/= get_init_time(ID) of
        true ->
            case ID of
                ?ACT_CLWORD_ID ->
                    act_clword:init();
                ?ACT_FAMILY_BATTLE ->
                    world_data:set_act_family_battle(#r_act_family_battle{});
                ?ACT_LIMITED_TIME_BUY ->
                    act_limited_time_buy:init(StartTime, Now);
                ?ACT_OSS_WING ->
                    act_oss:init(ID);
                ?ACT_OSS_MAGIC_WEAPON ->
                    act_oss:init(ID);
                ?ACT_OSS_HANDBOOK ->
                    act_oss:init(ID);
                ?ACT_HUNT_BOSS_ID ->
                    world_data:set_act_family_hunt_boss_reward_status([]),
                    world_data:set_act_family_hunt_boss_score([]),
                    world_data:set_act_personal_hunt_boss_score([]);
                _ ->
                    ok
            end,
            set_init_time(ID, StartTime);
        _ ->
            case ID of
                ?ACT_LIMITED_TIME_BUY ->
                    act_limited_time_buy:init(StartTime, Now);
                _ ->
                    ok
            end
    end.


init_end(ID) ->
    case ID of
        ?ACT_LIMITED_TIME_BUY ->
            act_limited_time_buy:end_time();
        _ ->
            ok
    end.

terminate(ID) ->
    case ID of
        ?ACT_LIMITED_TIME_BUY ->
            act_limited_time_buy:terminate();
        _ ->
            ok
    end.

act_status_change(ID, NowStatus) ->
    case ID of
        ?ACT_DOUBLE_COPY ->
            act_double_copy:reload();
        ?ACT_CAVE_BOSS_DOUBLE ->
            world_boss_server:cave_act_change(NowStatus);
        _ ->
            ok
    end.


zero(ID) ->
    case ID of
        ?ACT_DOUBLE_COPY ->
            act_double_copy:reload();
        ?ACT_CLWORD_ID ->
            act_clword:init();
        ?ACT_LIMITED_TIME_BUY ->
            act_limited_time_buy:zero();
        ?ACT_RANK ->
            act_rank:zero();
        _ ->
            ok
    end.


hour(Now, Hour, #r_act{id = ID} = RAct) ->
    case ID of
        ?ACT_RANK ->
            act_rank:hour(Hour);
        ?ACT_OTF_BIG_GUARD ->
            act_king_guard:hour(Now, RAct);
        _ ->
            0
    end.



get_init_time(ID) ->
    case db:lookup(?DB_ACT_INIT_TIME_P, ID) of
        [#r_act_init_time{time = Time}] ->
            Time;
        _ ->
            0
    end.

set_init_time(ID, Time) ->
    db:insert(?DB_ACT_INIT_TIME_P, #r_act_init_time{act_id = ID, time = Time}).
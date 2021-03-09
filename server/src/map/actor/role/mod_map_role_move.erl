%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 五月 2017 17:17
%%%-------------------------------------------------------------------
-module(mod_map_role_move).
-include("global.hrl").
-include("proto/mod_map_role_move.hrl").
-include("proto/gateway.hrl").
-author("laijichang").

%% API
-export([]).

-export([handle/1]).

-export([sync_actor_pos/3]).
%% ====================================================================
%% API functions
%% ====================================================================

%%无论玩家使用何种方式走路,每经过一格都必须要发一次消息给服务端
handle({#m_move_role_walk_tos{pos = Pos}, RoleID, _PID}) ->
    do_walk(RoleID, Pos);
handle({#m_move_point_tos{point = Point}, RoleID, _PID}) ->
    do_point(RoleID, Point);
handle({#m_move_stop_tos{pos = Pos}, RoleID, _PID}) ->
    do_move_stop(RoleID, Pos);
handle({#m_move_rush_tos{pos = Pos}, RoleID, _PID}) ->
    do_move_rush(RoleID, Pos);
handle({#m_stick_move_tos{pos = Pos}, RoleID, _PID}) ->
    do_stick_move(RoleID, Pos);
handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE, Info]).


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

do_walk(RoleID, Pos) ->
    ?CATCH(do_walk2(RoleID, Pos), ok).

do_walk2(RoleID, Pos) ->
    RecordPos = map_misc:pos_decode(Pos),
    #r_pos{mx = Mx, my = My, tx = Tx, ty = Ty} = RecordPos,
    case mod_map_ets:get_actor_mapinfo(RoleID) of
        #r_map_actor{pos = IntPos, move_speed = MovePeed} ->
            #r_pos{mx = OldMx, my = OldMy} = OldRecordPos = map_misc:pos_decode(IntPos),
            JudgeDis = erlang:max(500, MovePeed),
			XDis = erlang:abs(OldMx - Mx),
			YDis = erlang:abs(OldMy - My),
			Dis = XDis * XDis + YDis * YDis,
            case (Dis =< (JudgeDis * JudgeDis))  of %%
                true ->
                    case map_base_data:is_exist(Tx, Ty) orelse common_config:is_debug() of
                        true ->
                            clean_sync_count(RoleID),
                            mod_map_actor:move(RoleID, ?ACTOR_TYPE_ROLE, RecordPos, Pos);
                        false ->
                            add_sync_count(RoleID, OldRecordPos, RecordPos, false),
                            %% 用同步的方式而不是直接踢掉的方式
                            sync_actor_pos(RoleID, OldRecordPos, RecordPos)
                    end;
                _ ->
                    add_sync_count(RoleID, OldRecordPos, RecordPos, true),
                    sync_actor_pos(RoleID, OldRecordPos, RecordPos)
            end;
        _ ->
            ignore
    end,
    ok.



clean_sync_count(ActorID) ->
    erlang:erase({?MODULE, move_count, ActorID}).
-define(MAX_SYNC_TIMES, 30). %% 异常
add_sync_count(ActorID, OldPos, NewPos, Flag) ->
    Times = get_sync_count(ActorID),
    case Times > ?MAX_SYNC_TIMES of
        true ->
            clean_sync_count(ActorID),
            ?WARNING_MSG("!!!kick role:~w oldpos:~w newPos:~w", [ActorID, OldPos, NewPos]);
%%            role_misc:kick_role(ActorID, ?ERROR_SYSTEM_ERROR_023);
        _ ->
            set_sync_count(ActorID, Times + 1),
            ?IF(Flag andalso (Times + 1) rem 5 =:= 0, sync_actor_pos(ActorID, OldPos, NewPos), ok)
    end.

set_sync_count(ActorID, Times) ->
    erlang:put({?MODULE, move_count, ActorID}, Times).
get_sync_count(ActorID) ->
    case erlang:get({?MODULE, move_count, ActorID}) of
        Times when erlang:is_integer(Times) ->
            Times;
        _ -> 0
    end.

do_point(RoleID, Point) ->
    mod_map_actor:move_point(RoleID, Point).

%% 停止移动
do_move_stop(RoleID, Pos) ->
    do_walk(RoleID, Pos),
    mod_map_actor:move_stop(RoleID).

do_move_rush(RoleID, Pos) ->
    ?CATCH(do_move_rush2(RoleID, Pos), ok).

do_move_rush2(RoleID, Pos) ->
    RecordPos = map_misc:pos_decode(Pos),
    #r_pos{tx = Tx, ty = Ty} = RecordPos,
    case mod_map_ets:get_actor_pos(RoleID) of
        #r_pos{tx = OldTx, ty = OldTy} = OldRecordPos ->
            case (erlang:abs(OldTx - Tx) =< 10 andalso erlang:abs(OldTy - Ty) =< 10) of
                true ->
                    case map_base_data:is_exist(Tx, Ty) of
                        true ->
                            clean_sync_count(RoleID),
                            mod_map_actor:map_change_pos(RoleID, RecordPos, Pos, ?ACTOR_MOVE_RUSH, 0);
                        false ->
                            sync_actor_pos(RoleID, OldRecordPos, RecordPos)
                    end;
                false ->
                    sync_actor_pos(RoleID, OldRecordPos, RecordPos)
            end;
        _ -> ignore
    end,
    ok.

do_stick_move(RoleID, Pos) ->
    ?CATCH(do_stick_move2(RoleID, Pos), ok).

do_stick_move2(RoleID, Pos) ->
    RecordPos = map_misc:pos_decode(Pos),
    #r_pos{mx = Mx, my = My, tx = Tx, ty = Ty} = RecordPos,
    case mod_map_ets:get_actor_mapinfo(RoleID) of
        #r_map_actor{pos = IntPos, move_speed = MovePeed} ->
            #r_pos{mx = OldMx, my = OldMy} = OldRecordPos = map_misc:pos_decode(IntPos),
            JudgeDis = erlang:max(200, MovePeed div 3),
            XDis = erlang:abs(OldMx - Mx),
            YDis = erlang:abs(OldMy - My),
            Dis = XDis * XDis + YDis * YDis,
            case (Dis =< (JudgeDis * JudgeDis)) of %%
                true ->
                    case map_base_data:is_exist(Tx, Ty) of
                        true ->
                            clean_sync_count(RoleID),
                            mod_map_actor:stick_move(RoleID, ?ACTOR_TYPE_ROLE, RecordPos, Pos);
                        false ->
                            add_sync_count(RoleID, OldRecordPos, RecordPos, false),
                            %% 用同步的方式而不是直接踢掉的方式
                            sync_actor_pos(RoleID, OldRecordPos, RecordPos)
                    end;
                _ ->
                    add_sync_count(RoleID, OldRecordPos, RecordPos, true),
                    sync_actor_pos(RoleID, OldRecordPos, RecordPos)
            end;
        _ ->
            ignore
    end,
    ok.

%%同步玩家位置
sync_actor_pos(ActorID, OldRecordPos, RecordPos) ->
    ?WARNING_MSG("sync_actor_pos: ~w", [{ActorID, OldRecordPos, RecordPos}]),
    IntPos = map_misc:pos_encode(OldRecordPos),
    DataRecord = #m_move_sync_toc{actor_id = ActorID, pos = IntPos},
    common_misc:unicast(ActorID, DataRecord),
    RoleIDList = mod_map_slice:get_9slices_roleids_by_pos(OldRecordPos),
    map_server:send_msg_by_roleids(RoleIDList, DataRecord).
%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 四月 2019 11:21
%%%-------------------------------------------------------------------
-author("huangxiangrui").

-ifndef(GATEWAY_LIMITED_PRINTING_HRL).
-define(GATEWAY_LIMITED_PRINTING_HRL, gateway_limited_printing_hrl).

%% 不打印的协议
-define(LIMITED_LISTS, [
    m_move_role_walk_tos,
    m_move_point_tos,
    m_move_point_toc,
    m_move_stop_tos,
    m_move_stop_toc,
    m_move_sync_toc,
    m_stick_move_tos,
    m_stick_move_toc,
    m_system_hb_tos,
    m_system_hb_toc,
    m_move_rush_tos]).

-endif.
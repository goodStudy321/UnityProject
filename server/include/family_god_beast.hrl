%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 六月 2019 20:04
%%%-------------------------------------------------------------------
-author("WZP").

-ifndef(FAMILY_GOD_BEAST_HRL).
-define(FAMILY_GOD_BEAST_HRL, family_god_beast_hrl).


-define(ETS_FAMILY_GOD_BEAST_RANK_A, ets_family_god_beast_rank_a).
-define(ETS_FAMILY_GOD_BEAST_RANK_B, ets_family_god_beast_rank_b).

-define(FAMILY_GOD_BEAST_GLOBAL, 24).


-record(c_fgb, {id, boss_id, level, self_drop, family_drop, first_drop, second_drop, third_drop, fourth_drop, fifth_drop, other_drop}).
-record(r_family_god_beast_rank, {family_id, family_name = "", hurt = 0, rank = 0, member_hurt = [], member_num = 0, inspire_member = []}).

-endif.

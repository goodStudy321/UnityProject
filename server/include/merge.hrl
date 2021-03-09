%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 八月 2019 10:48
%%%-------------------------------------------------------------------
-author("laijichang").
-include("common.hrl").
-ifndef(MERGE_HRL).
-define(MERGE_HRL, merge_hrl).

-define(PRINT(Format), ?WARNING_MSG(Format), io:format(Format ++ "~n", [])).
-define(PRINT(Format, Args), ?WARNING_MSG(Format, Args), io:format(Format ++ "~n", Args)).

-define(MERGE_ROLE_ID_LIST, role_id_list).              %% [RoleID1, RoleID2]
-define(MERGE_ROLE_ID_TUPLE_LIST, role_id_tuple_list).  %% [#xxxx{role_id}....]

-endif.
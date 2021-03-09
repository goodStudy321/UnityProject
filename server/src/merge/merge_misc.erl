%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 八月 2019 11:00
%%%-------------------------------------------------------------------
-module(merge_misc).
-author("laijichang").
-include("merge.hrl").
-include("global.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    get_del_relative_list/0,
    get_del_list/0,
    del_all_data/0
]).

%% 只支持2层嵌套，多层嵌套的话，特殊处理数据
get_del_relative_list() ->
    [
        {?DB_ACCOUNT_ROLE_P, [
            {?MERGE_ROLE_ID_LIST, #r_account_role.role_id_list}
        ]},
        {?DB_WORLD_FRIEND_P, [
            {?MERGE_ROLE_ID_TUPLE_LIST, #r_world_friend.friend_list, #r_friend.role_id},
            {?MERGE_ROLE_ID_LIST, #r_world_friend.request_list},
            {?MERGE_ROLE_ID_LIST, #r_world_friend.black_list},
            {?MERGE_ROLE_ID_LIST, #r_world_friend.chat_list}
        ]},
        {?DB_FAMILY_P, [
            {?MERGE_ROLE_ID_TUPLE_LIST, #p_family.members, #p_family_member.role_id},
            {?MERGE_ROLE_ID_TUPLE_LIST, #p_family.apply_list, #p_family_apply.role_id}
        ]}
    ].

%% role_id匹配就删除
get_del_list() ->
    [{?DB_ROLE_NAME_P, #r_role_name.role_id}].

del_all_data() ->
    case common_config:is_gm_open() of
        true ->
            [ db:delete_all(TabName) || #c_tab{tab = TabName, node = NodeType} <- ?TABLE_INFO, db:is_node_match(NodeType, game)],
            ok;
        _ ->
            ok
    end.


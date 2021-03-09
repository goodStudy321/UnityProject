%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     合服入口
%%% @end
%%% Created : 17. 八月 2019 10:42
%%%-------------------------------------------------------------------
-module(merge_main).
-author("laijichang").
-include("global.hrl").
-include("merge.hrl").
-include("letter.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    start_merge/1
]).

-export([
    do_del_role/0,
    do_del_relative_data/1
]).

%%
start_merge(List) ->
    case catch do_start_merge(List) of
        ok ->
            ok;
        Error ->
            ?PRINT("Error: ~w", [Error]),
            error
    end.

do_start_merge(List) ->
    ?PRINT("List: ~w", [List]),
    PoolList = init_pool_list(List),
    ?PRINT("PoolList: ~w", [PoolList]),
    ?PRINT("----------- 开始合服 merge -----------"),
    %% 部分表数据不导入或者不直接导入
    IgnoreTab = [
        ?DB_ROLE_NAME_P, ?DB_FAMILY_NAME_P,
        ?DB_RANK_P, ?DB_WORLD_BOSS_P, ?DB_ROLE_SOLO_P, ?DB_ROLE_OFFLINE_SOLO_P, ?DB_ROBOT_OFFLINE_SOLO_P, ?DB_R_BG_ACT_P,
        ?DB_CHAT_HISTORY_P, ?DB_MINING_LATTICE_P, ?DB_MINING_ROLE_P, ?DB_WORLD_DATA_P, ?DB_NODE_MSG_P, ?DB_BACKGROUND_LOG_P
        ],
    [ begin
          ?PRINT("----------- ~w ----------- ", [TabName]),
          do_merge_data(PoolList, TabName),
          timer:sleep(1000)
      end || #c_tab{tab = TabName, node = NodeType} <- ?TABLE_INFO,
        not lists:member(TabName, IgnoreTab), db:is_node_match(NodeType, game)],
    %% GM信件删除
    do_del_gm_letter(),
    %% 玩家重命名
    do_role_rename(PoolList),
    %% 仙盟重命名
    do_family_rename(PoolList),
    %% 删除死号
    do_del_role(),
    %% 删除不常在线的仙盟
    do_del_family(),
    %%
    ?PRINT("----------- 合服数据处理完毕 -----------"),
    ok.

%% 初始化pool
init_pool_list(List) ->
    UserName = ?MYSQL_USER,
    Password = ?MYSQL_PASSWORD,
    Connections = ?DB_CONNECTIONS,
    [DBPort] = lib_config:find(common, db_port),
    [begin
         ServerID = lib_tool:to_integer(proplists:get_value(<<"server_id">>, ValueList)),
         AgentCode = lib_tool:to_list(proplists:get_value(<<"agent_code">>, ValueList)),
         DBHost = lib_tool:to_list(proplists:get_value(<<"db_host">>, ValueList)),
         DBHostPublic = lib_tool:to_list(proplists:get_value(<<"db_host_public">>, ValueList)),
         DataBaseName = lists:concat([?GAME_DB_NAME, "_", AgentCode, "_",  ServerID]),
         PoolID = lib_tool:to_atom(DataBaseName),
         %% 上次操作可能出错
         catch emysql:remove_pool(PoolID),
         ?PRINT("MySQL connecting to ~p:~p ~p:~p ~p ~w", [DBHost, DBPort, UserName, Password, DataBaseName, Connections]),
         case catch emysql:add_pool(PoolID, Connections, UserName, Password, DBHost, DBPort, DataBaseName, utf8mb4) of
             ok -> %% 先用内网连接
                 ok;
             {failed_to_connect_to_database,enetunreach} -> %% 再用公网
                 emysql:add_pool(test, Connections, UserName, Password, DBHostPublic, DBPort, DataBaseName, utf8mb4)
         end,
         PoolID
     end || {struct, ValueList} <- mochijson2:decode(List)].

%% key值不会有重复的
do_merge_data(PoolList, TabName) ->
    [ begin
          AllData = db_lib:all(PoolID, TabName),
          AllData2 =
              case TabName of
                  ?DB_ROLE_LETTER_P -> %% 信件里的 gm_id_list，需要清空
                      [ RoleLetter#r_role_letter{gm_id_list = []}|| RoleLetter <- AllData];
                  _ ->
                      AllData
              end,
          db:insert(TabName, AllData2)
      end|| PoolID <- PoolList].


do_del_gm_letter() ->
    db:delete(?DB_WORLD_LETTER_P, ?GM_MAIL_ID).

do_role_rename(PoolList) ->
    ?PRINT("----------- 玩家重命名处理 -----------"),
    Tab = ?DB_ROLE_NAME_P,
    AllRoleNames = get_all_data(PoolList, Tab),
    {NormalNames, SameList} =
        lists:foldl(
            fun(#r_role_name{role_name = RoleName} = NameIndex, {NormalNamesAcc, SameNamesAcc}) ->
                case lists:keytake(RoleName, 1, SameNamesAcc) of
                    {value, {RoleName, List}, SameNamesAcc2} ->
                        {NormalNamesAcc, [{RoleName, [NameIndex|List]}|SameNamesAcc2]};
                    _ ->
                        case lists:keytake(RoleName, #r_role_name.role_name, NormalNamesAcc) of
                            {value, #r_role_name{} = OldNormalName, NormalNamesAcc2} -> %% 出现重名
                                {NormalNamesAcc2, [{RoleName, [OldNormalName, NameIndex]}|SameNamesAcc]};
                            _ ->
                                {[NameIndex|NormalNamesAcc], SameNamesAcc}
                        end
                end
            end, {[], []}, AllRoleNames),
    %% 对重名的玩家进行处理
    do_role_rename2(SameList),
    db:insert(Tab, NormalNames),
    ?PRINT("----------- 玩家重命名处理完毕 -----------"),
    timer:sleep(1000),
    ok.

do_role_rename2([]) ->
    ok;
do_role_rename2([{Name, NameIndexList}|R]) ->
    %% 名字相同的，以VIP等级进行排序
    [FirstRoleName|NameIndexList2] =
        lists:sort(
            fun(#r_role_name{role_id = RoleID1}, #r_role_name{role_id = RoleID2}) ->
                common_role_data:get_role_vip_level(RoleID1) >= common_role_data:get_role_vip_level(RoleID2)
            end, NameIndexList),
    AllIDList = [ RoleID || #r_role_name{role_id = RoleID} <- NameIndexList2],
    ?PRINT("----------- 角色重复的名字: ~ts, FirstID:~w, RemainID:~w-----------", [Name, FirstRoleName#r_role_name.role_id, AllIDList]),
    db:insert(?DB_ROLE_NAME_P, FirstRoleName),
    do_role_rename3(NameIndexList2, 1),
    do_role_rename2(R).

do_role_rename3([], _Index) ->
    ok;
do_role_rename3([NameIndex|R], Index) ->
    #r_role_name{role_name = OldName, role_id = RoleID} = NameIndex,
    NewName = lib_tool:concat([OldName, [32], "#", Index]),
    [RoleAttr] = db:lookup(?DB_ROLE_ATTR_P, RoleID),
    db:insert(?DB_ROLE_ATTR_P, RoleAttr#r_role_attr{role_name = NewName}),
    db:insert(?DB_ROLE_NAME_P, NameIndex#r_role_name{role_name = NewName}),
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_MERGE_ROLE_RENAME,
        action = ?ITEM_GAIN_SERVER_MERGE,
        goods_list = [#p_goods{type_id = 31030, num = 1}]
    },
    FunList =
        [
            fun() -> common_letter:send_letter(RoleID, LetterInfo) end,
            fun() -> family_escort_server:role_name_update(RoleID, NewName) end
        ],
    [?TRY_CATCH(F()) || F <- FunList],
    do_role_rename3(R, Index + 1).

do_family_rename(PoolList) ->
    ?PRINT("----------- 道庭重命名开始 -----------"),
    Tab = ?DB_FAMILY_NAME_P,
    AllRoleNames = get_all_data(PoolList, Tab),
    {NormalNames, SameList} =
        lists:foldl(
            fun(#r_family_name{family_name = FamilyName} = NameIndex, {NormalNamesAcc, SameNamesAcc}) ->
                case lists:keytake(FamilyName, 1, SameNamesAcc) of
                    {value, {FamilyName, List}, SameNamesAcc2} ->
                        {NormalNamesAcc, [{FamilyName, [NameIndex|List]}|SameNamesAcc2]};
                    _ ->
                        case lists:keytake(FamilyName, #r_family_name.family_name, NormalNamesAcc) of
                            {value, #r_family_name{} = OldFamilyName, NormalNamesAcc2}-> %% 出现重名
                                {NormalNamesAcc2, [{FamilyName, [OldFamilyName, NameIndex]}|SameNamesAcc]};
                            _ ->
                                {[NameIndex|NormalNamesAcc], SameNamesAcc}
                        end
                end
            end, {[], []}, AllRoleNames),
    %% 对重名的玩家进行处理
    do_family_rename2(SameList),
    db:insert(Tab, NormalNames),
    ?PRINT("----------- 道庭重命名处理完毕 -----------"),
    timer:sleep(1000),
    ok.

do_family_rename2([]) ->
    ok;
do_family_rename2([{Name, NameIndexList}|R]) ->
    [FirstFamilyName|NameIndexList2] =
        lists:sort(
            fun(#r_family_name{family_id = FamilyID1}, #r_family_name{family_id = FamilyID2}) ->
                #p_family{level = Level1} = mod_family_data:get_family(FamilyID1),
                #p_family{level = Level2} = mod_family_data:get_family(FamilyID2),
                Level1 >= Level2
            end, NameIndexList),
    AllIDList = [ FamilyID || #r_family_name{family_id = FamilyID} <- NameIndexList2],
    ?PRINT("----------- 道庭重复的名字: ~ts, FirstID:~w, RemainID:~w-----------", [Name, FirstFamilyName#r_family_name.family_id, AllIDList]),
    db:insert(?DB_FAMILY_NAME_P, FirstFamilyName),
    do_family_rename3(NameIndexList2, 1),
    do_family_rename2(R).

do_family_rename3([], _Index) ->
    ok;
do_family_rename3([NameIndex|R], Index) ->
    #r_family_name{family_name = FamilyName, family_id = FamilyID} = NameIndex,
    NewName = lists:concat([FamilyName, [32], Index]),
    ok = mod_family_operation:family_merge_rename(FamilyID, NewName),
    do_family_rename3(R, Index + 1).

do_del_role() ->
    DelRoleIDList = get_del_roles(),
    TabList =
        lists:foldl(
            fun(Tab, Acc) ->
                #c_tab{tab = TabName, node = NodeType, sql_opts = SqlOpts} = Tab,
                case db:is_node_match(NodeType, game) andalso lists:keyfind(keyformat, 1, SqlOpts) of
                    {keyformat, int} ->
                        [TabName|Acc];
                    _ ->
                        Acc
                end
            end, [], ?TABLE_INFO),
    ?PRINT("----------- 删除死号 ID:~w-----------", [DelRoleIDList]),
    do_del_role_data(TabList, DelRoleIDList),
    ?PRINT("----------- 删除关联数据-----------"),
    do_del_relative_data(DelRoleIDList),
    ok.

%% 删除玩家相关数据
do_del_role_data([], _DelRoleIDList) ->
    ok;
do_del_role_data([Tab|R], DelRoleIDList) ->
    ?PRINT("----------- 删除死号数据，Tab:~w-----------", [Tab]),
    db:delete_many(Tab, DelRoleIDList),
    timer:sleep(1000),
    do_del_role_data(R, DelRoleIDList).

%% 删除与RoleID相关数据
do_del_relative_data([]) ->
    ok;
do_del_relative_data(DelRoleIDList) ->
    RelativeList = merge_misc:get_del_relative_list(),
    [begin
         ?PRINT("----------- 删除~w关联数据-----------", [Tab]),
         db:flush(Tab),
         AllList = db_lib:all(Tab),
         DataList = do_del_relative_data2(AllList, DelIndexList, DelRoleIDList, []),
         db:insert(Tab, DataList),
         timer:sleep(1000)
     end || {Tab, DelIndexList} <- RelativeList],
    DelTabList = merge_misc:get_del_list(),
    [begin
         ?PRINT("----------- 删除死号~w数据-----------", [Tab]),
         db:flush(Tab),
         AllList = db_lib:all(Tab),
         DelList = do_del_relative_data3(AllList, DleIndex, DelRoleIDList, []),
         db:delete_many(Tab, DelList),
         timer:sleep(1000)
     end || {Tab, DleIndex} <- DelTabList],
    ok.

%% 字段里数据删掉对应的RoleID
do_del_relative_data2([], _DelIndexList, _DelRoleIDList, DataList) ->
    DataList;
do_del_relative_data2([Data|R], DelIndexList, DelRoleIDList, DataList) ->
    Data2 =
        lists:foldl(
            fun(DelIndex, DataAcc) ->
                case DelIndex of
                    {?MERGE_ROLE_ID_TUPLE_LIST, Index, RoleIDIndex} ->
                        Elements = erlang:element(Index, DataAcc),
                        case erlang:is_list(Elements) of
                            true ->
                                Elements2 = lists:foldl(fun(DelRoleID, ElementsAcc) -> lists:keydelete(DelRoleID, RoleIDIndex, ElementsAcc) end, Elements, DelRoleIDList),
                                erlang:setelement(Index, DataAcc, Elements2);
                            _ ->
                                DataAcc
                        end;
                    {?MERGE_ROLE_ID_LIST, Index} ->
                        Elements = erlang:element(Index, DataAcc),
                        case erlang:is_list(Elements) of
                            true ->
                                Elements2 = Elements -- DelRoleIDList,
                                erlang:setelement(Index, DataAcc, Elements2);
                            _ ->
                                DataAcc
                        end
                end
            end, Data, DelIndexList),
    do_del_relative_data2(R, DelIndexList, DelRoleIDList, [Data2|DataList]).

%% 有相同的ID，就删掉
do_del_relative_data3([], _DleIndex, _DelRoleIDList, DelKeyList) ->
    DelKeyList;
do_del_relative_data3([Data|R], DleIndex, DelRoleIDList, DelKeyAcc) ->
    DelKeyAcc2 =
        case lists:member(erlang:element(DleIndex, Data), DelRoleIDList) of
            true ->
                [erlang:element(2, Data)|DelKeyAcc];
            _ ->
                DelKeyAcc
        end,
    do_del_relative_data3(R, DleIndex, DelRoleIDList, DelKeyAcc2).

do_del_family() ->
    Now = time_tool:now(),
    [ begin
          case get_is_family_del(FamilyData, Now) of
              true ->
                  ?PRINT("-----------道庭解散ID: ~w-----------", [FamilyData#p_family.family_id]),
                  mod_family_operation:web_dismiss_family(FamilyData#p_family.family_id);
              _ ->
                  ok
          end
      end || FamilyData <- mod_family_data:get_all_family()],
    ok.

get_all_data(PoolList, TabName) ->
    get_all_data2(PoolList, TabName, []).

get_all_data2([], _TabName, Datas) ->
    Datas;
get_all_data2([PoolID|R], TabName, Datas) ->
    AllData = db_lib:all(PoolID, TabName),
    get_all_data2(R, TabName, AllData ++ Datas).

%% 获取被删除的角色ID
get_del_roles() ->
    db:flush(?DB_ROLE_ATTR_P),
    Now = time_tool:now(),
    get_del_roles2(db_lib:all(?DB_ROLE_ATTR_P), Now, []).

get_del_roles2([], _Now, DelRoleAcc) ->
    DelRoleAcc;
get_del_roles2([RoleAttr|R], Now, DelRoleAcc) ->
    #r_role_attr{role_id = RoleID, level = RoleLevel, last_offline_time = LastOfflineTime} = RoleAttr,
    DelRoleAcc2 =
        case RoleLevel =< 100 andalso Now - LastOfflineTime >= ?ONE_DAY * 30 of
            true -> %% 角色：等级≤100级，30天内未登陆，未有充值记录的角色数据将被清除
                case db:lookup(?DB_ROLE_PAY_P, RoleID) of
                    [#r_role_pay{total_pay_fee = TotalPayFee}] when TotalPayFee > 0->
                        DelRoleAcc;
                    _ ->
                        [RoleID|DelRoleAcc]
                end;
            _ ->
                DelRoleAcc
        end,
    get_del_roles2(R, Now, DelRoleAcc2).

get_is_family_del(FamilyData, Now) ->
    case FamilyData of
        #p_family{level = FamilyLevel, members = Members} ->
            %% 道庭等级≤2级，15天内未有成员登录的道庭数据将被清除
            ?IF(FamilyLevel =< 2, get_is_family_del2(Members, Now), false);
        _ ->
            ?PRINT("----------- 获取family数据时不匹配-----------"),
            false
    end.

get_is_family_del2([], _Now) ->
    true;
get_is_family_del2([#p_family_member{role_id = RoleID}|R], Now) ->
    case db:lookup(?DB_ROLE_ATTR_P, RoleID) of
        [#r_role_attr{last_offline_time = LastOfflineTime}] ->
            case Now - LastOfflineTime =< 15 * ?ONE_DAY of
                true ->
                    false;
                _ ->
                    get_is_family_del2(R, Now)
            end;
        _ ->
            get_is_family_del2(R, Now)
    end.



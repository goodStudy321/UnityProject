%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 秘境探索（挖矿）
%%% @end
%%% Created : 26. 七月 2019 15:27
%%%-------------------------------------------------------------------
-module(mod_role_mining).
-author("huangxiangrui").
-include("db.hrl").
-include("common.hrl").
-include("role.hrl").
-include("global.hrl").
-include("mining.hrl").
-include("proto/world_mining_server.hrl").
-include("proto/mod_role_mining.hrl").

%% API
%% 只要在模块里定义了，gen_cfg_module.es就会在
%% cfg_module_etc里生成，role_server每次对应
%% 的操作都调用,还可以在gen_cfg_module.es设置优先级
-export([
    init/1,               %% role初始化
    online/1,             %% 上线
    loop_10min/1          %% 10分钟更新一次战力
]).

-export([
    handle/2,
    send/2
]).

-export([
    role_join_family/1,
    role_leave_family/1,
    role_rename/2,
    role_activity_trigger/2,
    send_mining_log/2
]).

send(RoleID, Msg) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {Msg, RoleID, 0}}).
init(State) ->
    State.

online(State) ->
    ?IF(mod_role_function:get_is_function_open(?FUNCTION_MINING, State),
        world_mining_server:online_info(State#r_role.role_id, mod_role_data:get_role_power(State)), ok),
    State.

loop_10min(State) ->
    ?IF(mod_role_function:get_is_function_open(?FUNCTION_MINING, State),
        world_mining_server:send_update_role_power(State#r_role.role_id, mod_role_data:get_role_power(State)),
        ok),
    State.

%% @doc 角色加入公会
%% 要在hook_role模块里添加才生效
role_join_family(State) ->
    #r_role_attr{role_id = RoleID, family_id = FamilyID} = State#r_role.role_attr,
    world_mining_server:send_role_join_family(RoleID, FamilyID),
    State.

%% @doc 角色脱离入公会
%% 要在hook_role模块里添加才生效
role_leave_family(State)->
    #r_role_attr{role_id = RoleID, family_id = FamilyID} = State#r_role.role_attr,
    world_mining_server:send_role_leave_family(RoleID, FamilyID),
    State.

%% @doc 角色修改名字
%% 要在hook_role模块里添加才生效
role_rename(RoleName, State) ->
    #r_role_attr{role_id = RoleID} = State#r_role.role_attr,
    world_mining_server:send_update_role_rename(RoleID, RoleName),
    State.

%% @doc 活动触发
%% 要在hook_role模块里添加才生效
role_activity_trigger(_MapID, State) ->
    State.

send_mining_log(RoleID, Log) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, Log}).

handle({#m_mining_role_info_tos{}, _RoleID, _PID}, State) ->
    ?IF(mod_role_function:get_is_function_open(?FUNCTION_MINING, State), world_mining_server:send_mining_role_info(get_first_mining_role(State)), ok),
    State;
handle({#m_role_mining_shift_tos{new_x = NewX, new_y = NewY}, RoleID, _PID}, State) ->
    do_mining_shift(NewX, NewY, RoleID, State);
handle({#m_role_mining_plunder_tos{object_id = ObjectID}, RoleID, _PID}, State) ->
    do_mining_plunder(RoleID, ObjectID, State);
handle({#m_role_mining_inspire_tos{}, RoleID, _PID}, State) ->
    do_mining_inspire(RoleID, State);
handle({#m_role_mining_take_out_goods_tos{}, RoleID, _PID}, State) ->
    do_mining_take_out_goods(RoleID, State);
handle(#log_mining_role{} = Log, State) ->
    do_mining_log(Log, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow info: ~w", [Info]),
    State.

%% @doc 移动
do_mining_shift(NewX, NewY, RoleID, State) ->
    case catch mod_role_function:is_function_open(?FUNCTION_MINING, State) of
        true ->
            case world_mining_server:call_mining_shift(NewX, NewY, RoleID) of
                ok ->
                    DataRecord = #m_role_mining_shift_toc{},
                    common_misc:unicast(RoleID, DataRecord),
                    ok;
                {error, ErrCode} ->
                    DataRecord = #m_role_mining_shift_toc{err_code = ErrCode},
                    common_misc:unicast(RoleID, DataRecord)
            end;
        {error, ErrCode} ->
            DataRecord = #m_role_mining_shift_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord)
    end,
    State.

%% @doc 掠夺
do_mining_plunder(RoleID, ObjectID, State) ->
    case catch mod_role_function:is_function_open(?FUNCTION_MINING, State) of
        true ->
            case world_mining_server:call_mining_plunder(RoleID, ObjectID) of
                {ok, ?MINING_PLUNDER_FAIL, ShiftNum} ->
                    DataRecord = #m_role_mining_plunder_toc{status = ?MINING_PLUNDER_FAIL, shift_num = ShiftNum},
                    common_misc:unicast(RoleID, DataRecord);
                {ok, ?MINING_PLUNDER_SUCCESS, ShiftNum} ->
                    DataRecord = #m_role_mining_plunder_toc{status = ?MINING_PLUNDER_SUCCESS, shift_num = ShiftNum},
                    common_misc:unicast(RoleID, DataRecord),
                    ok;
                ErrCode ->
                    DataRecord = #m_role_mining_plunder_toc{err_code = ErrCode},
                    common_misc:unicast(RoleID, DataRecord)
            end;
        {error, ErrCode} ->
            DataRecord = #m_role_mining_plunder_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord)
    end,
    State.

%% @doc 鼓舞
do_mining_inspire(RoleID, State) ->
    case catch check_mining_inspire(State) of
        {ok, AssetDoings, State2} ->
            case world_mining_server:call_mining_inspire(RoleID, mod_role_data:get_role_power(State)) of
                {ok, Inspire} ->
                    DataRecord = #m_role_mining_inspire_toc{inspire = Inspire},
                    common_misc:unicast(RoleID, DataRecord),
                    mod_role_asset:do(AssetDoings, State2);
                ErrCode ->
                    DataRecord = #m_role_mining_inspire_toc{err_code = ErrCode},
                    common_misc:unicast(RoleID, DataRecord),
                    State2
            end;
        {error, ErrCode} ->
            DataRecord = #m_role_mining_inspire_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

check_mining_inspire(State) ->
    mod_role_function:is_function_open(?FUNCTION_MINING, State),
    [AssetType, NeedGold] = common_misc:get_global_list(?GLOBAL_MINING_MINING_INSPIRE),
    AssetDoings = mod_role_asset:check_asset_by_type(AssetType, NeedGold, ?ASSET_GOLD_REDUCE_MINING_INSPIRE, State),
    {ok, AssetDoings, State}.

%% @doc 取出资源
do_mining_take_out_goods(RoleID, State) ->
    case catch mod_role_function:is_function_open(?FUNCTION_MINING, State) of
        true ->
            case world_mining_server:call_mining_take_out_goods(RoleID) of
                {ok, GoodsList} ->
                    DataRecord = #m_role_mining_take_out_goods_toc{},
                    common_misc:unicast(RoleID, DataRecord),
                    role_misc:create_goods(State, ?ITEM_GAIN_MINING_GOODS, GoodsList);
                ErrCode ->
                    DataRecord = #m_role_mining_take_out_goods_toc{err_code = ErrCode},
                    common_misc:unicast(RoleID, DataRecord),
                    State
            end;
        {error, ErrCode} ->
            DataRecord = #m_role_mining_take_out_goods_toc{err_code = ErrCode},
            common_misc:unicast(RoleID, DataRecord),
            State
    end.

do_mining_log(Log, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    mod_role_dict:add_background_logs(Log#log_mining_role{channel_id = ChannelID, game_channel_id = GameChannelID}).

get_first_mining_role(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        role_name = RoleName,
        category = Category,
        sex = Sex,
        family_id = FamilyID,
        max_power = RolePower} = RoleAttr,
    #r_mining_role{
        role_id = RoleID,
        role_name = RoleName,
        category = Category,
        sex = Sex,
        family_id = FamilyID,
        power = RolePower
    }.
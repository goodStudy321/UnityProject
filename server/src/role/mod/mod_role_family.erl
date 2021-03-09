%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十月 2017 17:23
%%%-------------------------------------------------------------------
-module(mod_role_family).
-author("laijichang").
-include("family.hrl").
-include("role.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_red_packet.hrl").
-include("family_battle.hrl").

%% API
-export([
    init/1,
    online_i/1,
    calc/1,
    loop_10min/2,
    offline/1,
    handle/2,
    day_reset/1,
    zero/1
]).

-export([
    get_observe_args/1,
    get_family_title_id/1,
    role_rename/1,
    get_role_family_box/2,
    gm_family_money_add/3
]).


gm_family_money_add(State, Num, Num2) ->
    PFamily = mod_family_data:get_family(State#r_role.role_attr#r_role_attr.family_id),
    mod_family_data:set_family(PFamily#p_family{money = Num, level = Num2}),
    {ok, State2, _} = online_i(State),
    State2.

init(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_family{family_id = FamilyID, family_name = FamilyName} = mod_family_data:get_role_family(RoleID),
    RoleAttr2 = RoleAttr#r_role_attr{family_id = FamilyID, family_name = FamilyName},
    State#r_role{role_attr = RoleAttr2}.

online_i(State) ->
    #r_role{role_id = RoleID, role_attr = Attr, role_private_attr = PrivateAttr, role_red_packet = RoleRedPacket} = State,
    #r_role_attr{family_id = FamilyID} = Attr,
    #r_role_private_attr{family_skills = FamilySkills} = PrivateAttr,
    {AddBoxNum2, Title2} = case ?HAS_FAMILY(FamilyID) of
                               true ->
                                   PFamily = mod_family_data:get_family(FamilyID),
                                   BoxList = get_role_family_box(FamilyID, RoleID),
                                   Now = time_tool:now(),
                                   BoxList2 = lists:filter(fun(Box) -> Box#p_family_box.end_time > Now end, BoxList),
                                   BoxList3 = lists:filter(                                                           fun(Box) ->
                                       Box#p_family_box.end_time - ?ONE_DAY > Attr#r_role_attr.last_offline_time end, BoxList2),
                                   Integral = case lists:keyfind(RoleID, #p_family_member.role_id, PFamily#p_family.members) of
                                                  false ->
                                                      0;
                                                  PFMember ->
                                                      PFMember#p_family_member.integral
                                              end,
                                   common_misc:unicast(RoleID, #m_family_info_toc{family_info = PFamily, integral = Integral,skill_list = FamilySkills, box_list = BoxList2}),
                                   common_misc:unicast(RoleID, #m_family_day_reward_info_toc{reward = PrivateAttr#r_role_private_attr.family_day_reward}),
                                   common_misc:unicast(RoleID, #m_family_red_packet_received_toc{amount = mod_role_red_packet:tran_to_list(RoleRedPacket#r_role_red_packet.red_packet), times = RoleRedPacket#r_role_red_packet.red_packet_num}),
                                   do_update_role_info(State, true, true),
                                   #p_family_member{title = Title} = lists:keyfind(RoleID, #p_family_member.role_id, PFamily#p_family.members),
                                   AddBoxNum = erlang:length(BoxList3),
                                   {AddBoxNum, Title};
                               _ ->
                                   {-1, 0}
                           end,
    FunList = [
        fun(StateAcc) -> mod_role_title:family_title_change(Title2, StateAcc) end,
        fun(StateAcc) -> mod_role_fashion:family_title_change(Title2, StateAcc) end
    ],
    State2 = role_server:execute_state_fun(FunList, State),
    {ok, State2, AddBoxNum2}.


zero(#r_role{role_private_attr = PrivateAttr, role_id = RoleID} = State) ->
    common_misc:unicast(RoleID, #m_family_day_reward_info_toc{reward = PrivateAttr#r_role_private_attr.family_day_reward}),
    State.

day_reset(#r_role{role_private_attr = PrivateAttr} = State) ->
    PrivateAttr2 = PrivateAttr#r_role_private_attr{family_day_reward = false},
    State#r_role{role_private_attr = PrivateAttr2}.


calc(State) ->
    #r_role{role_private_attr = PrivateAttr} = State,
    #r_role_private_attr{family_skills = FamilySkills} = PrivateAttr,
    Attr = common_misc:sum_calc_attr2(mod_role_level:get_level_attr(State), mod_role_equip:get_equip_base_attr(State)),
    #actor_cal_attr{
        attack = {Attack, _},
        max_hp = {MaxHp, _},
        arp = {Arp, _},
        defence = {Defence, _}
    } = Attr,
    {KVList, BuffAttr} =
    lists:foldl(
        fun(ID, {KVListAcc, AttrAcc}) ->
            [#c_family_skill{prop_id = PropID, prop_value = PropValue}] = lib_config:find(cfg_family_skill, ID),
            AddAttr =
            if
                PropID =:= ?ATTR_RATE_ADD_ATTACK ->
                    #actor_cal_attr{attack = {lib_tool:ceil(Attack * PropValue / ?RATE_10000), 0}};
                PropID =:= ?ATTR_RATE_ADD_HP ->
                    #actor_cal_attr{max_hp = {lib_tool:ceil(MaxHp * PropValue / ?RATE_10000), 0}};
                PropID =:= ?ATTR_RATE_ADD_DEFENCE ->
                    #actor_cal_attr{defence = {lib_tool:ceil(Defence * PropValue / ?RATE_10000), 0}};
                PropID =:= ?ATTR_RATE_ADD_ARP ->
                    #actor_cal_attr{arp = {lib_tool:ceil(Arp * PropValue / ?RATE_10000), 0}};
                true ->
                    #actor_cal_attr{}
            end,
            {[#p_kv{id = PropID, val = PropValue}|KVListAcc], common_misc:sum_calc_attr2(AttrAcc, AddAttr)}
        end, {[], #actor_cal_attr{}}, FamilySkills),
    BaseAttr = common_misc:get_attr_by_kv(KVList),
    CalcAttr = common_misc:sum_calc_attr2(BaseAttr, BuffAttr),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_FAMILY, CalcAttr).

loop_10min(_Now, State) ->
    do_update_role_info(State, true),
    State.

offline(State) ->
    do_update_role_info(State, false, true),
    State.

get_role_family_box(FamilyID, RoleID) ->
    case mod_family_data:get_family_box(FamilyID) of
        #r_family_box{role_box_list = List} ->
            case lists:keyfind(RoleID, #r_box_list.role_id, List) of
                false ->
                    [];
                #r_box_list{box_list = BoxList} ->
                    BoxList
            end;
        _ ->
            []
    end.


get_observe_args(RoleID) ->
    #r_role_family{family_id = FamilyID, family_name = FamilyName} = mod_family_data:get_role_family(RoleID),
    case ?HAS_FAMILY(FamilyID) of
        true ->
            #p_family{members = Members} = mod_family_data:get_family(FamilyID),
            #p_family_member{title = Title} = lists:keyfind(RoleID, #p_family_member.role_id, Members),
            {FamilyID, FamilyName, Title};
        _ ->
            {FamilyID, FamilyName, 0}
    end.

get_family_title_id(RoleID) ->
    #r_role_family{family_id = FamilyID} = mod_family_data:get_role_family(RoleID),
    case ?HAS_FAMILY(FamilyID) of
        true ->
            #p_family{members = Members} = mod_family_data:get_family(FamilyID),
            #p_family_member{title = Title} = lists:keyfind(RoleID, #p_family_member.role_id, Members),
            Title;
        _ ->
            0
    end.

role_rename(State) ->
    do_update_role_info(State, true, true).

%% to mod_family_request
handle({#m_family_create_tos{family_name = FamilyName}, RoleID, _PID}, State) ->
    do_family_create(RoleID, FamilyName, State);
handle({#m_family_invite_tos{role_id = DestRoleID}, RoleID, _PID}, State) ->
    do_family_invite(RoleID, DestRoleID, State);
handle({#m_family_invite_reply_tos{op_type = OpType, role_id = FromRoleID, family_id = FamilyID}, RoleID, _PID}, State) ->
    do_family_invite_reply(RoleID, OpType, FromRoleID, FamilyID, State);
handle({#m_family_apply_tos{family_id = FamilyID}, RoleID, _PID}, State) ->
    do_family_apply(RoleID, FamilyID, State);
handle({#m_family_apply_reply_tos{op_type = OpType, role_ids = RoleIDs}, RoleID, _PID}, State) ->
    do_family_apply_reply(RoleID, OpType, RoleIDs, State);
handle({#m_family_admin_tos{role_id = DestRoleID, new_title = NewTitle}, RoleID, _PID}, State) ->
    do_family_admin(RoleID, DestRoleID, NewTitle, State);
handle({#m_family_kick_tos{role_id = DestRoleID}, RoleID, _PID}, State) ->
    do_family_kick(RoleID, DestRoleID, State);
handle({#m_family_leave_tos{}, RoleID, _PID}, State) ->
    do_family_leave(RoleID, State);

%% to mod_family_operation
handle({#m_family_config_tos{kv_list = KVList, ks_list = KSList}, RoleID, _PID}, State) ->
    do_family_config(RoleID, KVList, KSList, State);
handle({#m_family_rename_tos{family_name = FamilyName}, RoleID, _PID}, State) ->
    do_family_rename(RoleID, FamilyName, State);

%% to mod_family_boss
handle({#m_family_boss_tos{}, RoleID, _PID}, State) ->
    do_family_boss_open(RoleID, State);
handle({#m_family_up_boss_grain_tos{num = Num}, RoleID, _PID}, State) ->
    do_boss_grain_turn_over(RoleID, State, Num);


%% to mod_family_depot
handle({#m_family_donate_tos{goods_list = GoodsIDList}, RoleID, _PID}, State) ->
    do_family_donate(RoleID, GoodsIDList, State);
handle({#m_family_del_depot_tos{goods_list = GoodsIDList}, RoleID, _PID}, State) ->
    do_family_del_depot(RoleID, GoodsIDList, State);
handle({#m_family_exchange_depot_tos{goods_id = GoodsID, num = Num}, RoleID, _PID}, State) ->
    do_family_exchange_depot(RoleID, GoodsID, State, Num);


%% to mod_family_red_packet
handle({#m_family_give_red_packet_tos{type = Type, amount = Amount, content = Content, piece = Piece}, RoleID, _PID}, State) ->
    do_family_give_red_packet(RoleID, Type, Amount, Content, Piece, State);
handle({#m_family_get_red_packet_tos{packet_id = PacketID}, RoleID, _PID}, State) ->
    do_family_get_red_packet(RoleID, PacketID, State);
handle({#m_family_see_red_packet_tos{packet_id = PacketID}, RoleID, _PID}, State) ->
    do_family_see_red_packet(RoleID, PacketID, State);


%%帮战
handle({#m_family_battle_qua_tos{}, RoleID, _PID}, State) ->
    do_get_qua_info(RoleID, State);
handle({#m_family_battle_salary_tos{}, RoleID, _PID}, State) ->
    do_get_salary(RoleID, State);
handle({#m_family_battle_cv_reward_tos{reward = Reward, role_id = RcRoleID}, RoleID, _PID}, State) ->
    do_distribute_cv_reward(RoleID, State, Reward, RcRoleID);
handle({#m_family_battle_ecv_reward_tos{role_id = RcRoleID}, RoleID, _PID}, State) ->
    do_distribute_end_reward(RoleID, State, RcRoleID);


%%开宝箱
handle({#m_family_box_open_tos{box = Box}, RoleID, _PID}, State) ->
    do_box_open(RoleID, Box, State);


%% self
handle({#m_family_brief_tos{from = From, to = To}, RoleID, _PID}, State) ->
    do_family_brief(RoleID, From, To, State);
handle({#m_family_skill_tos{skill_id = SkillID}, RoleID, _PID}, State) ->
    do_family_skill(RoleID, SkillID, State);
handle({#m_family_day_reward_tos{}, RoleID, _PID}, State) ->
    do_get_day_reward(RoleID, State);
handle({join_family, RoleID, FamilyID, FamilyName, Title}, State) ->
    do_join_family(RoleID, FamilyID, FamilyName, Title, State);
handle({leave_family, RoleID, FamilyID, LeaveStatus}, State) ->
    do_leave_family(RoleID, FamilyID, LeaveStatus, State);
handle({family_name_change, FamilyName}, State) ->
    do_family_name_change(FamilyName, State);
handle({title_change, ChangeTitle}, State) ->
    do_family_title_change(ChangeTitle, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]),
    State.

do_family_create(RoleID, FamilyName, State) ->
    case catch check_can_create(State, FamilyName) of
        {ok, BagDoings, AssetDoing} ->
            case mod_family_request:create_family(RoleID, FamilyName) of
                ok ->
                    State2 = mod_role_bag:do(BagDoings, State),
                    State3 = mod_role_asset:do(AssetDoing, State2),
                    mod_role_act_family:family_create(State3);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_family_create_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_create_toc{err_code = ErrCode}),
            State
    end.

check_can_create(State, FamilyName) ->
    ?IF(erlang:length(FamilyName) < 7, ok, ?THROW_ERR(?ERROR_FAMILY_CREATE_005)),
    mod_role_function:is_function_open(?FUNCTION_FAMILY_CREATE, State),
    %% 检查敏感词、道具等
    case catch re:run(FamilyName, " ", [unicode]) of
        {match, _} ->
            ?THROW_ERR(?ERROR_COMMON_WORD_CHECK);
        _ ->
            ok
    end,
    common_misc:word_check(FamilyName),
    [Config] = lib_config:find(cfg_global, ?CREATE_FAMILY_GLOBAL),
    [Type, Num, NeedSilver] = Config#c_global.list,
    BagDoing = mod_role_bag:check_num_by_type_id(Type, Num, ?ITEM_REDUCE_CREATE_FAMILY, State),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_SILVER, NeedSilver, ?ASSET_SILVER_REDUCE_FAMILY_CREATE, State),
    {ok, BagDoing, AssetDoing}.

%% 帮派邀请
do_family_invite(RoleID, DestRoleID, State) ->
    case catch check_can_invite(RoleID, DestRoleID, State) of
        {ok, FamilyID, FamilyName, RoleName} ->
            DataRecord = #m_family_invite_toc{
                invite_role_id = RoleID,
                invite_role_name = RoleName,
                invite_family_id = FamilyID,
                invite_family_name = FamilyName},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(DestRoleID, DataRecord),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_invite_toc{err_code = ErrCode}),
            State
    end.

check_can_invite(RoleID, DestRoleID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_name = RoleName, family_id = FamilyID, family_name = FamilyName} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_INVITE_001)),
    #r_role_family{family_id = DestFamilyID} = mod_family_data:get_role_family(DestRoleID),
    ?IF(?HAS_FAMILY(DestFamilyID), ?THROW_ERR(?ERROR_FAMILY_INVITE_002), ok),
    #p_family{members = Members, level = Level} = mod_family_data:get_family(FamilyID),
    #p_family_member{title = Title} = lists:keyfind(RoleID, #p_family_member.role_id, Members),
    ?IF(family_misc:is_accept_member(Title), ok, ?THROW_ERR(?ERROR_FAMILY_INVITE_003)),
    MaxNum = family_misc:get_family_max_num(Level),
    ?IF(erlang:length(Members) < MaxNum, ok, ?THROW_ERR(?ERROR_FAMILY_INVITE_004)),
    {ok, FamilyID, FamilyName, RoleName}.

%% 帮派邀请回复
do_family_invite_reply(RoleID, OpType, FromRoleID, FamilyID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_name = RoleName} = RoleAttr,
    case OpType of
        ?INVITE_REPLY_REFUSE ->
            DataRecord = #m_family_invite_reply_toc{op_type = ?INVITE_REPLY_REFUSE, reply_role_id = RoleID, reply_role_name = RoleName},
            common_misc:unicast(RoleID, DataRecord),
            common_misc:unicast(FromRoleID, DataRecord),
            State;
        ?INVITE_REPLY_ACCEPT ->
            mod_family_request:invite_join_family(RoleID, FromRoleID, FamilyID),
            State
    end.

%% 帮派申请
do_family_apply(RoleID, FamilyID, State) ->
    case catch check_can_apply(FamilyID, State) of
        ok ->
            mod_family_request:apply_family(RoleID, FamilyID),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_apply_toc{err_code = ErrCode}),
            State
    end.

check_can_apply(FamilyID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = MyFamilyID, level = RoleLevel, power = Power} = RoleAttr,
    ?IF(?HAS_FAMILY(MyFamilyID), ?THROW_ERR(?ERROR_FAMILY_APPLY_001), ok),
    family_misc:check_join(),
    case mod_family_data:get_family(FamilyID) of
        #p_family{is_direct_join = true} ->
            ok;
        #p_family{limit_level = LimitLevel, limit_power = LimitPower} ->
            ?IF(RoleLevel >= LimitLevel andalso Power >= LimitPower, ok, ?THROW_ERR((?ERROR_FAMILY_APPLY_006)));
        _ ->
            ?THROW_ERR(?ERROR_FAMILY_APPLY_007)
    end,
    ok.


%% 审批加入 or 拒绝
do_family_apply_reply(RoleID, OpType, RoleIDs, State) ->
    case catch check_apply_reply(RoleID, State) of
        {ok, FamilyID} ->
            mod_family_request:apply_reply(RoleID, FamilyID, OpType, RoleIDs),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_apply_reply_toc{err_code = ErrCode}),
            State
    end.

check_apply_reply(RoleID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_INVITE_REPLY_001)),
    #p_family{members = Members} = mod_family_data:get_family(FamilyID),
    #p_family_member{title = Title} = lists:keyfind(RoleID, #p_family_member.role_id, Members),
    ?IF(family_misc:is_accept_member(Title), ok, ?THROW_ERR(?ERROR_FAMILY_INVITE_REPLY_002)),
    {ok, FamilyID}.

%% 帮派职位调整
do_family_admin(RoleID, DestRoleID, NewTitle, State) ->
    case catch check_can_admin(RoleID, DestRoleID, State) of
        {ok, FamilyID} ->
            mod_family_request:family_admin(RoleID, FamilyID, DestRoleID, NewTitle),

            ?IF(NewTitle =:= ?TITLE_OWNER, common_broadcast:send_family_common_notice(FamilyID, ?NOTICE_FAMILY_TRANSFERS,
                                                                                      [lib_tool:to_list(RoleID), common_role_data:get_role_name(RoleID),
                                                                                       lib_tool:to_list(DestRoleID), common_role_data:get_role_name(DestRoleID)]), ok),

            ?IF(NewTitle =:= ?TITLE_VICE_OWNER, common_broadcast:send_family_common_notice(FamilyID, ?NOTICE_FAMILY_ADMIN,
                                                                                           [lib_tool:to_list(DestRoleID), common_role_data:get_role_name(DestRoleID)]), ok),

            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_admin_toc{err_code = ErrCode}),
            State
    end.

check_can_admin(RoleID, DestRoleID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),
    FamilyData = mod_family_data:get_family(FamilyID),
    ?IF(family_misc:is_owner(RoleID, FamilyData), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_002)),
    ?IF(RoleID =/= DestRoleID, ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_002)),
    {ok, FamilyID}.

%% 帮派踢人
do_family_kick(RoleID, DestRoleID, State) ->
    case catch check_can_kick(RoleID, DestRoleID, State) of
        {ok, FamilyID} ->
            mod_family_request:family_kick(RoleID, FamilyID, DestRoleID),
            common_broadcast:send_family_common_notice(
                FamilyID, ?NOTICE_FAMILY_KICK_ROLE, [lib_tool:to_list(DestRoleID), common_role_data:get_role_name(DestRoleID), lib_tool:to_list(RoleID), mod_role_data:get_role_name(State)]),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_kick_toc{err_code = ErrCode}),
            State
    end.

check_can_kick(RoleID, DestRoleID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_001)),
    FamilyData = mod_family_data:get_family(FamilyID),
    ?IF(family_misc:is_owner_or_vice_owner(RoleID, FamilyData), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_002)),
    ?IF(family_misc:is_owner(RoleID, FamilyData) orelse (not family_misc:is_owner_or_vice_owner(DestRoleID, FamilyData)),
        ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_002)),
    ?IF(RoleID =/= DestRoleID, ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_002)),
    {ok, FamilyID}.

%%帮派每日奖励
do_get_day_reward(RoleID, State) ->
    case catch check_can_get_day_reward(State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_family_day_reward_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_day_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get_day_reward(#r_role{role_attr = RoleAttr, role_private_attr = PrivateAttr} = State) ->
    ?IF(?HAS_FAMILY(RoleAttr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_CONFIG_001)),
    ?IF(PrivateAttr#r_role_private_attr.family_day_reward, ?THROW_ERR(?ERROR_FAMILY_DAY_REWARD_001), ok),
    [Config] = lib_config:find(cfg_global, ?FAMILY_DAY_REWARD_GLOBAL),
    [TypeID, Num] = Config#c_global.list,
    State2 = State#r_role{role_private_attr = PrivateAttr#r_role_private_attr{family_day_reward = true}},
    GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = true}],
    mod_role_bag:check_bag_empty_grid(GoodsList, State2),
    BagDoing = [{create, ?ITEM_GAIN_FAMILY_DAY_REWARD, GoodsList}],
    State3 = mod_role_bag:do(BagDoing, State2),
    {ok, State3}.

%% 离开帮派
do_family_leave(RoleID, State) ->
    case catch check_can_leave(State) of
        ok ->
            mod_family_request:leave_family(RoleID, State#r_role.role_map#r_role_map.map_id),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_leave_toc{err_code = ErrCode}),
            State
    end.

check_can_leave(State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_LEAVE_001)),
    ok.

%% 帮派信息设置
do_family_config(RoleID, KVList, KSList, State) ->
    case catch check_can_config(RoleID, KSList, State) of
        {ok, FamilyID} ->
            mod_family_operation:family_config(FamilyID, KVList, KSList),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_config_toc{err_code = ErrCode}),
            State
    end.

check_can_config(RoleID, KSList, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    case lists:keymember(?CONFIG_NOTICE, #p_ks.id, KSList) of
        true ->
            ?IF(common_misc:is_rename_ban(?WEB_BAN_NOTICE_RENAME), ?THROW_ERR(?ERROR_COMMON_FUNCTION_BAN), ok);
        _ ->
            ok
    end,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_CONFIG_001)),
    FamilyData = mod_family_data:get_family(FamilyID),
    ?IF(family_misc:is_owner_or_vice_owner(RoleID, FamilyData), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_002)),
    {ok, FamilyID}.

%% 仙盟改名
do_family_rename(RoleID, FamilyName, State) ->
    case catch check_family_rename(RoleID, FamilyName, State) of
        {ok, BagDoings, FamilyID, OldFamilyName} ->
            case mod_family_operation:family_rename(FamilyID, FamilyName) of
                ok ->
                    common_misc:unicast(RoleID, #m_family_rename_toc{family_name = FamilyName}),
                    log_family_rename(OldFamilyName, FamilyName, State),
                    common_broadcast:send_family_common_notice(
                        FamilyID, ?NOTICE_FAMILY_RENAME, [lib_tool:to_list(RoleID), mod_role_data:get_role_name(State), OldFamilyName, FamilyName]),
                    mod_role_bag:do(BagDoings, State);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_family_rename_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_rename_toc{err_code = ErrCode}),
            State
    end.

check_family_rename(RoleID, FamilyName, State) ->
    ?IF(common_misc:is_rename_ban(?WEB_BAN_FAMILY_RENAME), ?THROW_ERR(?ERROR_COMMON_FUNCTION_BAN), ok),
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    case catch re:run(FamilyName, " ", [unicode]) of
        {match, _} ->
            ?THROW_ERR(?ERROR_COMMON_WORD_CHECK);
        _ ->
            ok
    end,
    common_misc:word_check(FamilyName),
    ?IF(family_misc:is_activity_time(), ?THROW_ERR(?ERROR_FAMILY_RENAME_002), ok),
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_CONFIG_001)),
    #p_family{family_name = OldFamilyName} = FamilyData = mod_family_data:get_family(FamilyID),
    ?IF(OldFamilyName =:= FamilyName, ?THROW_ERR(?ERROR_FAMILY_RENAME_001), ok),
    ?IF(family_misc:is_owner_or_vice_owner(RoleID, FamilyData), ok, ?THROW_ERR(?ERROR_FAMILY_ADMIN_002)),
    [TypeID, Num] = common_misc:get_global_list(?GLOBAL_FAMILY_RENAME),
    BagDoings = mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_FAMILY_RENAME, State),
    {ok, BagDoings, FamilyID, OldFamilyName}.


%%仙盟BOSS系列
do_family_boss_open(RoleID, #r_role{role_attr = Attr} = State) ->
    #r_role_attr{family_id = FamilyID} = Attr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_LEAVE_001)),
    case catch mod_family_boss:family_open_boss(RoleID, FamilyID) of
        ok ->
            common_misc:unicast(RoleID, #m_family_boss_toc{});
        {error, timeout} ->
            ?ERROR_MSG("call timeout"),
            common_misc:unicast(RoleID, #m_family_boss_toc{});
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_boss_toc{err_code = ErrCode})
    end,
    State.

do_boss_grain_turn_over(RoleID, State, Num) ->
    case catch check_can_turn_over(State, Num) of
        {ok, AssetDoing, BagDoing} ->
            common_misc:unicast(RoleID, #m_family_up_boss_grain_toc{}),
            State2 = mod_role_bag:do(BagDoing, State),
            mod_role_asset:do(AssetDoing, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_up_boss_grain_toc{err_code = ErrCode}),
            State
    end.

check_can_turn_over(#r_role{role_attr = Attr} = State, Num) ->
    ?IF(?HAS_FAMILY(Attr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_UP_BOSS_GRAIN_002)),
    BagDoing = mod_role_bag:check_num_by_type_id(?FAMILY_BOSS_GRAIN_ID, Num, ?ITEM_REDUCE_FAMILY_BOSS_GRAIN, State),
    Config = mod_role_item:get_item_config(?FAMILY_BOSS_GRAIN_ID),
    AssetDoing = [{add_score, ?ASSET_FAMILY_BOSS_TURN_OVER, ?ASSET_FAMILY_CON, lib_tool:to_integer(Config#c_item.effect_args) * Num}],
    mod_family_boss:family_turn_over_boss_grain(Attr#r_role_attr.family_id, Num),
    {ok, AssetDoing, BagDoing}.


%% 帮派捐献
do_family_donate(RoleID, GoodsIDList, #r_role{role_attr = RoleAttr} = State) ->
    case catch check_can_donate(GoodsIDList, State) of
        {ok, BagDoings, GoodsList, DonateCon} ->
            case catch mod_family_depot:family_donate(RoleID, RoleAttr#r_role_attr.family_id, GoodsList, DonateCon, RoleAttr#r_role_attr.role_name) of
                {ok, NewCon, OldCon} ->
                    common_misc:unicast(RoleID, #m_family_donate_toc{integral = NewCon}),
                    State2 = mod_role_bag:do(BagDoings, State),
                    log_family_donate(?LOG_FAMILY_DEPOT_DONATE, GoodsList, NewCon, OldCon, State),
                    mod_role_achievement:family_donate(State2);
                {error, timeout} ->
                    ?ERROR_MSG("call timeout"),
                    common_misc:unicast(RoleID, #m_family_donate_toc{}),
                    State2 = mod_role_bag:do(BagDoings, State),
                    mod_role_achievement:family_donate(State2);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_family_donate_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_donate_toc{err_code = ErrCode}),
            State
    end.

check_can_donate(GoodsIDList, State) ->
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(GoodsIDList, State),
    DonateCon = check_can_donate2(GoodsList, 0),
    DecreaseList = [#r_goods_decrease_info{id = ID, num = Num} || #p_goods{id = ID, num = Num} <- GoodsList],
    BagDoings = [{decrease, ?ITEM_REDUCE_FAMILY_DONATE, DecreaseList}],
    {ok, BagDoings, GoodsList, DonateCon}.

check_can_donate2([], DonateCon) ->
    DonateCon;
check_can_donate2([Goods|R], DonateConAcc) ->
    #p_goods{type_id = TypeID, bind = IsBind} = Goods,
    ?IF(IsBind, ?THROW_ERR(?ERROR_FAMILY_DONATE_001), ok),
    case lib_config:find(cfg_item, TypeID) of
        [#c_item{donate_contribution = DonateCon}] when DonateCon > 0 ->
            check_can_donate2(R, DonateCon + DonateConAcc);
        _ ->
            ?THROW_ERR(?ERROR_FAMILY_DONATE_001)
    end.

%% 删除装备
do_family_del_depot(RoleID, GoodsIDList, State) ->
    mod_family_depot:family_del_depot(RoleID, GoodsIDList),
    State.

do_family_exchange_depot(RoleID, GoodsID, #r_role{role_attr = Attr} = State, Num) ->
    case catch mod_family_depot:family_exchange_depot(RoleID, Attr#r_role_attr.family_id, GoodsID, Num, Attr#r_role_attr.role_name) of
        {ok, Goods, NewInt, OldInt} ->
            common_misc:unicast(RoleID, #m_family_exchange_depot_toc{integral = NewInt}),
            log_family_donate(?LOG_FAMILY_DEPOT_EXCHANGE, [Goods], NewInt, OldInt, State),
            role_misc:create_goods(State, ?ITEM_GAIN_FAMILY_DEPOT, [Goods]);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_exchange_depot_toc{err_code = ErrCode}),
            State
    end.


%%红包
do_family_give_red_packet(RoleID, Type, Amount, Content, Piece, State) ->
    case catch check_can_give_red_packet(Type, Amount, Piece, Content, State) of
        {ok, AssetDoing, BagDoing, RedPacket, FamilyID, RoleRedPacket} ->
            case catch mod_family_red_packet:family_give_red_packet(RedPacket, FamilyID) of
                {ok, RedPacket2} ->
                    DataRecord = #m_family_new_red_packet_toc{red_packet = RedPacket2},
                    common_broadcast:bc_record_to_family(FamilyID, DataRecord),
                    common_misc:unicast(RoleID, #m_family_give_red_packet_toc{type = Type, amount = Amount}),
                    common_misc:unicast(RoleID, #m_family_red_packet_received_toc{amount = mod_role_red_packet:tran_to_list(RoleRedPacket#r_role_red_packet.red_packet), times = RoleRedPacket#r_role_red_packet.red_packet_num}),
                    State2 = mod_role_asset:do(AssetDoing, State),
                    State3 = mod_role_bag:do(BagDoing, State2),
                    mod_role_achievement:family_red_packet(State3#r_role{role_red_packet = RoleRedPacket});
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_family_give_red_packet_toc{err_code = ErrCode}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_give_red_packet_toc{err_code = ErrCode}),
            State
    end.

check_can_give_red_packet(Type, Amount, Piece, Content, #r_role{role_attr = Attr, role_red_packet = RoleRedPacket} = State) ->
    ?IF(Piece >= 1, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_005)),
    case Type of
        0 ->
            ?IF(Amount >= Piece, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_006)),
            ?IF(mod_role_vip:get_vip_level(State) >= 6, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_001)),
            ?IF(RoleRedPacket#r_role_red_packet.red_packet_num < 10, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_007)),
            NewAmount = ?IF(Amount >= 10000, 10000, Amount),
            RedPacket2 = #p_red_packet{sender_name = Attr#r_role_attr.role_name, content = Content, time = time_tool:now(), amount = NewAmount, icon = Attr#r_role_attr.category, piece = Piece,
                                       bind = ?BAG_ASSET_GOLD},
            AssetDoing2 = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NewAmount, ?ASSET_GOLD_REDUCE_FROM_GIVE_RED_PACKET, State),
            BagDoing = [],
            NewRoleRedPacket2 = RoleRedPacket#r_role_red_packet{red_packet_num = RoleRedPacket#r_role_red_packet.red_packet_num + 1};
        1 ->
            ?IF(Amount >= Piece, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_006)),
            ?IF(Piece >= 10, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_005)),
            {RedPacket2, AssetDoing2, NewRoleRedPacket2} = case lists:keytake(Amount, #p_kv.val, RoleRedPacket#r_role_red_packet.red_packet) of
                                                               {value, _, OtherRedPacket} ->
                                                                   RedPacket = #p_red_packet{sender_name = Attr#r_role_attr.role_name, content = Content, time = time_tool:now(), amount = Amount,
                                                                                             icon = Attr#r_role_attr.category, piece = Piece, bind = ?BAG_ASSET_BIND_GOLD},
                                                                   AssetDoing = [],
                                                                   NewRoleRedPacket = RoleRedPacket#r_role_red_packet{red_packet = OtherRedPacket},
                                                                   {RedPacket, AssetDoing, NewRoleRedPacket};
                                                               _ ->
                                                                   ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_003)
                                                           end,
            BagDoing = [];
        _ ->
            [ItemConfig] = lib_config:find(cfg_item, Amount),
            ?IF(ItemConfig#c_item.effect_type =:= ?ITEM_RED_PACKET, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_003)),
            NewAmount = lib_tool:to_integer(ItemConfig#c_item.effect_args),
            ?IF(NewAmount >= Piece, ok, ?THROW_ERR(?ERROR_FAMILY_GIVE_RED_PACKET_006)),
            BagDoing = mod_role_bag:check_num_by_type_id(Amount, 1, ?ITEM_REDUCE_SEND_RED_PACKET, State),
            AssetDoing2 = [],
            NewRoleRedPacket2 = RoleRedPacket,
            RedPacket2 = #p_red_packet{sender_name = Attr#r_role_attr.role_name, content = Content, time = time_tool:now(), amount = NewAmount, icon = Attr#r_role_attr.category, piece = Piece,
                                       bind = ?BAG_ASSET_BIND_GOLD}
    end,
    {ok, AssetDoing2, BagDoing, RedPacket2, Attr#r_role_attr.family_id, NewRoleRedPacket2}.



do_family_get_red_packet(RoleID, PacketID, State) ->
    case catch check_can_get_red_packet(PacketID, State) of
        {ok, AssetDoing, Gold} ->
            common_misc:unicast(RoleID, #m_family_get_red_packet_toc{gold = Gold, packet_id = PacketID}),
            mod_role_asset:do(AssetDoing, State);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_get_red_packet_toc{err_code = ErrCode}),
            State
    end.


check_can_get_red_packet(PacketID, #r_role{role_attr = Attr, role_id = RoleID}) ->
    ?IF(?HAS_FAMILY(Attr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_UP_BOSS_GRAIN_002)),
    case mod_family_red_packet:family_get_red_packet(PacketID, Attr#r_role_attr.family_id, RoleID, Attr#r_role_attr.role_name, Attr#r_role_attr.category) of
        {ok, Gold, Bind} ->
            AssetDoing = case Bind of
                             ?BAG_ASSET_BIND_GOLD ->
                                 [{add_gold, ?ASSET_GOLD_ADD_FROM_GIVE_RED_PACKET, 0, Gold}];
                             _ ->
                                 [{add_gold, ?ASSET_GOLD_ADD_FROM_GIVE_RED_PACKET, Gold, 0}]
                         end,
            {ok, AssetDoing, Gold};
        {error, ErrCode} ->
            {error, ErrCode}
    end.


do_family_see_red_packet(RoleID, PacketID, #r_role{role_attr = Attr} = State) ->
    case catch ?IF(?HAS_FAMILY(Attr#r_role_attr.family_id), {ok, Attr#r_role_attr.family_id}, ?THROW_ERR(?ERROR_FAMILY_UP_BOSS_GRAIN_002)) of
        {ok, FamilyID} ->
            mod_family_red_packet:family_see_red_packet(PacketID, FamilyID, RoleID),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_see_red_packet_toc{err_code = ErrCode}),
            State
    end.


%% 获取帮派简要信息
do_family_brief(RoleID, From, To, State) ->
    {Briefs, AllNum} = mod_family_data:get_family_brief_by_rank(From, To),
    common_misc:unicast(RoleID, #m_family_brief_toc{briefs = Briefs, all_num = AllNum}),
    State.

do_family_skill(RoleID, SkillID, State) ->
    case catch check_can_skill(SkillID, State) of
        {ok, AssetDoing, FamilySkills, Log, State2} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_FAMILY_SKILL, SkillID),
            common_misc:unicast(RoleID, #m_family_skill_toc{skill_list = FamilySkills}),
            mod_role_dict:add_background_logs(Log),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_skill_toc{err_code = ErrCode}),
            State
    end.

check_can_skill(SkillID, State) ->
    #r_role{role_attr = RoleAttr, role_private_attr = PrivateAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    #r_role_private_attr{family_skills = FamilySkills} = PrivateAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_SKILL_001)),
    case check_can_skill2(SkillID, FamilySkills) of
        {ok, NowID} -> %% 在列表中，升级技能
            OldSkillID = NowID,
            NewSkillID = NowID + 1,
            FamilySkills2 = [NewSkillID|lists:delete(NowID, FamilySkills)];
        _ ->
            ?IF(?GET_FAMILY_SKILL_LV(SkillID) =:= 1, ok, ?THROW_ERR(?ERROR_FAMILY_SKILL_002)),
            OldSkillID = 0,
            NewSkillID = SkillID,
            FamilySkills2 = [SkillID|FamilySkills]
    end,
    case lib_config:find(cfg_family_skill, NewSkillID) of
        [#c_family_skill{use_con = UseCon}] ->
            AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_FAMILY_CON, UseCon, ?ASSET_SCORE_REDUCE_FROM_FAMILY_SKILL, State);
        _ ->
            UseCon = AssetDoing = ?THROW_ERR(?ERROR_FAMILY_SKILL_004)
    end,
    PrivateAttr2 = PrivateAttr#r_role_private_attr{family_skills = FamilySkills2},
    State2 = State#r_role{role_private_attr = PrivateAttr2},
    Log = get_family_skill_log(OldSkillID, NewSkillID, UseCon, State2),
    {ok, AssetDoing, FamilySkills2, Log, State2}.

check_can_skill2(_SkillID, []) ->
    false;
check_can_skill2(SkillID, [NowID|R]) ->
    case ?GET_FAMILY_SKILL_ID(SkillID) =:= ?GET_FAMILY_SKILL_ID(NowID) of
        true ->
            {ok, NowID};
        _ ->
            check_can_skill2(SkillID, R)
    end.


%% 角色加入帮派hook
do_join_family(RoleID, FamilyID, FamilyName, Title, State) ->
    #r_role{role_attr = RoleAttr, role_private_attr = PrivateAttr, role_red_packet = RoleRedPacket} = State,
    RoleAttr2 = RoleAttr#r_role_attr{family_id = FamilyID, family_name = FamilyName},
    FamilyData = mod_family_data:get_family(FamilyID),
    common_misc:unicast(RoleID, #m_family_info_toc{family_info = FamilyData, skill_list = PrivateAttr#r_role_private_attr.family_skills, box_list = []}),
    common_misc:unicast(RoleID, #m_family_red_packet_received_toc{amount = mod_role_red_packet:tran_to_list(RoleRedPacket#r_role_red_packet.red_packet)
        ,                                                         times = RoleRedPacket#r_role_red_packet.red_packet_num}),
    common_misc:unicast(RoleID, #m_family_day_reward_info_toc{reward = PrivateAttr#r_role_private_attr.family_day_reward}),
    world_broadcast_server:role_add_channel(RoleID, [{?CHANNEL_FAMILY, FamilyID}]),
    State2 = State#r_role{role_attr = RoleAttr2},
    State3 = hook_role:role_join_family(State2),
    State4 = mod_role_friend:update(State3),
    do_update_role_info(State4, true, true),
    mod_map_role:update_role_family(mod_role_dict:get_map_pid(), RoleID, FamilyID, FamilyName),
    State5 = do_family_title_change(Title, State4),
    State6 = mod_role_mission:condition_update(State5),
    common_broadcast:send_family_common_notice(FamilyID, ?NOTICE_FAMILY_JOIN_FAMILY,
                                               [lib_tool:to_list(RoleID), mod_role_data:get_role_name(State)]),
    role_server:dump_table(?DB_ROLE_ATTR_P, State6).

%% 角色离开帮派hook
do_leave_family(RoleID, OldFamilyID, LeaveStatus, State) ->
    #r_role{role_attr = RoleAttr} = State,
    FamilyID = 0,
    FamilyName = "",
    RoleAttr2 = RoleAttr#r_role_attr{family_id = FamilyID, family_name = FamilyName},
    common_misc:unicast(RoleID, #m_family_info_toc{}),
    world_broadcast_server:role_leave_channel(RoleID, [{?CHANNEL_FAMILY, OldFamilyID}]),
    mod_map_role:update_role_family(mod_role_dict:get_map_pid(), RoleID, FamilyID, FamilyName),
    State2 = State#r_role{role_attr = RoleAttr2},
    State3 = hook_role:role_leave_family(State2),
    State4 = mod_role_friend:update(State3),
    State5 = do_family_title_change(0, State4),
    State6 = mod_role_mission:condition_update(State5),
    ?IF(LeaveStatus =/= ?FAMILY_LEAVE_STATUS_4, common_broadcast:send_family_common_notice(FamilyID, ?NOTICE_FAMILY_LEAVE_FAMILY,
                                                                                           [lib_tool:to_list(RoleID), mod_role_data:get_role_name(State)]), ok),
    role_server:dump_table(?DB_ROLE_ATTR_P, State6).

do_family_name_change(FamilyName, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{family_id = FamilyID} = RoleAttr,
    RoleAttr2 = RoleAttr#r_role_attr{family_name = FamilyName},
    mod_map_role:update_role_family(mod_role_dict:get_map_pid(), RoleID, FamilyID, FamilyName),
    State2 = State#r_role{role_attr = RoleAttr2},
    State3 = mod_role_friend:update(State2),
    State3.

do_family_title_change(ChangeTitle, State) ->
    #r_role{role_id = RoleID} = State,
    mod_map_role:update_role_family_title(mod_role_dict:get_map_pid(), RoleID, ChangeTitle),
    family_escort_server:family_title_update(RoleID, ChangeTitle),
    State2 = hook_role:role_family_title_change(ChangeTitle, State),
    State2.

%% 上线、下线、10min更新角色在帮派中的数据
do_update_role_info(State, IsOnline) ->
    do_update_role_info(State, IsOnline, false).
do_update_role_info(State, IsOnline, IsForce) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{
        family_id = FamilyID,
        role_name = RoleName,
        level = Level,
        category = Category,
        power = Power,
        last_offline_time = LastOfflineTime} = RoleAttr,
    Info = {RoleName, Level, Category, Power, IsOnline, LastOfflineTime},
    case ?HAS_FAMILY(FamilyID) andalso (mod_role_dict:get_family_cache_info() =/= Info orelse IsForce) of
        true ->
            mod_role_dict:set_family_cache_info(Info),
            mod_family_role:update_role_info(RoleID, FamilyID, Info);
        _ ->
            ok
    end.


%%  帮战

%%  返回对应资格赛信息
do_get_qua_info(RoleID, #r_role{role_attr = Attr} = State) ->
    case catch mod_family_battle:get_qua_info(Attr#r_role_attr.family_id) of
        {ok, SendList, Opponent, Round, OpenTime} ->
            common_misc:unicast(RoleID, #m_family_battle_qua_toc{list = SendList, opponent = Opponent, round = Round, open_time = OpenTime}),
            State;
        _ ->
            common_misc:unicast(RoleID, #m_family_battle_qua_toc{list = [], opponent = "", round = 1}),
            State
    end.


do_get_salary(RoleID, State) ->
    case catch check_can_salary(State, RoleID) of
        {ok, BagDoing} ->
            State2 = mod_role_bag:do(BagDoing, State),
            common_misc:unicast(RoleID, #m_family_battle_salary_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_battle_salary_toc{err_code = ErrCode}),
            State
    end.


check_can_salary(#r_role{role_attr = RoleAttr} = State, RoleID) ->
    ?IF(?HAS_FAMILY(RoleAttr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_LEAVE_001)),
    TempleList = world_data:get_family_temple(),
    case lists:keyfind(RoleAttr#r_role_attr.family_id, #r_family_battle_temple.family_id, TempleList) of
        false ->
            ?THROW_ERR(?ERROR_FAMILY_BATTLE_SALARY_001);
        #r_family_battle_temple{rank = Rank} ->
            [Config] = lib_config:find(cfg_fbt_temple, Rank),
            Reward = lib_tool:string_to_intlist(Config#c_fbt_temple.reward),
            GoodsList = [#p_goods{type_id = Type, num = Num, bind = ?IS_BIND(Bind)} || {Type, Num, Bind} <- Reward],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            case mod_family_battle:family_get_salary(RoleID, RoleAttr#r_role_attr.family_id) of
                {error, ErrCode} ->
                    {error, ErrCode};
                ok ->
                    BagDoings = [{create, ?ITEM_GAIN_FAMILY_TEMPLE, GoodsList}],
                    {ok, BagDoings}
            end
    end.


do_distribute_cv_reward(RoleID, State, Reward, RcRoleID) ->
    case catch check_distribute_cv_reward(State, RoleID, Reward, RcRoleID) of
        ok ->
            common_misc:unicast(RoleID, #m_family_battle_cv_reward_toc{}),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_battle_cv_reward_toc{err_code = ErrCode}),
            State
    end.

check_distribute_cv_reward(#r_role{role_attr = RoleAttr}, RoleID, Reward, RcRoleID) ->
    ?IF(?HAS_FAMILY(RoleAttr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_LEAVE_001)),
    mod_family_battle:family_distribute_cv_reward(Reward, RoleID, RoleAttr#r_role_attr.family_id, RcRoleID).



do_distribute_end_reward(RoleID, State, RcRoleID) ->
    case catch check_distribute_end_reward(State, RoleID, RcRoleID) of
        ok ->
            common_misc:unicast(RoleID, #m_family_battle_ecv_reward_toc{}),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_battle_ecv_reward_toc{err_code = ErrCode}),
            State
    end.

check_distribute_end_reward(#r_role{role_attr = RoleAttr}, RoleID, RcRoleID) ->
    ?IF(?HAS_FAMILY(RoleAttr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_LEAVE_001)),
    mod_family_battle:family_distribute_end_reward(RcRoleID, RoleID, RoleAttr#r_role_attr.family_id).

get_family_skill_log(OldSkillID, NewSkillID, UseCon, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #log_family_skill{
        role_id = RoleID,
        old_skill_id = OldSkillID,
        new_skill_id = NewSkillID,
        use_con = UseCon,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.



do_box_open(RoleID, BoxList, State) ->
    case catch check_box_open(State, RoleID, BoxList) of
        {ok, State2, GoodsList, BoxList2} ->
            common_misc:unicast(RoleID, #m_family_box_open_toc{goods = GoodsList, box = BoxList2}),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:family_box(erlang:length(BoxList2), StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_family_box_open_toc{err_code = ErrCode}),
            State
    end.


check_box_open(#r_role{role_attr = RoleAttr} = State, RoleID, BoxList) ->
    ?IF(?HAS_FAMILY(RoleAttr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_LEAVE_001)),
    Now = time_tool:now(),
    BoxList2 = lists:filtermap(
          fun(Box) ->
              Box#p_family_box.end_time >= Now
          end
        , BoxList),
    ?IF(erlang:length(BoxList) =/= erlang:length(BoxList2), ?INFO_MSG("-------BoxList2---------~w", [{BoxList, BoxList2}]), ok),
    case mod_family_box:open_box(BoxList2, RoleAttr#r_role_attr.family_id, RoleID) of
        {ok, OpenBoxList} ->
            ?IF(erlang:length(BoxList2) =/= erlang:length(OpenBoxList), ?INFO_MSG("-------1111---------~w", [{BoxList2, OpenBoxList}]), ok),
            mod_role_package:family_use_package(OpenBoxList, State);
        {error, Error} ->
            {error, Error}
    end.


log_family_donate(ActionType, GoodsList, NewCon, OldCon, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        family_id = FamilyID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    Log =
    #log_family_depot{
        family_id = FamilyID,
        role_id = RoleID,
        action_type = ActionType,
        goods_list = common_misc:to_goods_string(GoodsList),
        old_score = OldCon,
        new_score = NewCon,
        channel_id = ChannelID,
        game_channel_id = GameChannelID},
    mod_role_dict:add_background_logs(Log).

log_family_rename(OldFamilyName, FamilyName, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{role_id = RoleID, family_id = FamilyID} = RoleAttr,
    Log =
    #log_family_rename{
        family_id = FamilyID,
        role_id = RoleID,
        old_family_name = unicode:characters_to_binary(OldFamilyName),
        new_family_name = unicode:characters_to_binary(FamilyName)},
    mod_role_dict:add_background_logs(Log).
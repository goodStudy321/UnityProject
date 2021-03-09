-module(role_misc).
-include("role.hrl").
-include("proto/gateway.hrl").

%% API
-export([
    pid/1,
    register_name/1,
    get_role_pname/1,
    is_online/1,
    info_role/2,
    info_role/3,
    info_role_after/3
]).

-export([
    kick_role/1,
    kick_role/2
]).

%% 外部进程可调用
-export([
    add_buff/2,
    remove_buff/2,
    give_goods/3,
    online_give_goods/3
]).

-export([
    create_goods/3
]).

-export([

]).

-export([
    is_reset_week/1,
    get_skill_prop_rate/2,
    get_pellet_attr/2,
    get_attr_by_kv/2,
    pellet_max_num/3,
    pellet_broadcast/3,
    level_broadcast/4,
    skill_broadcast/3,
    get_new_level_exp/4,
    log_role_nurture/1,
    get_base_attr_by_kv/3,
    get_base_attr_by_kv/2
]).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc 获得玩家逻辑进程的PID
pid(RoleID) when erlang:is_integer(RoleID) ->
    erlang:whereis(get_role_pname(RoleID));
pid(Name) ->
    erlang:whereis(Name).

%% @doc 注册角色进程全局名字
register_name(RoleID) ->
    true = erlang:register(get_role_pname(RoleID), erlang:self()).

%% @doc 获取角色注册名字
get_role_pname(RoleID) ->
    lib_tool:list_to_atom(lists:concat(["role_", RoleID])).


%% @doc 判断玩家是否在线
is_online(RoleID) ->
    case role_misc:pid(get_role_pname(RoleID)) of
        undefined ->
            false;
        _PID ->
            true
    end.

%% @doc 获取角色进程id
get_role_pid(RoleID) when is_integer(RoleID) ->
    case role_misc:pid(RoleID) of
        RolePID when erlang:is_pid(RolePID) ->
            {ok, RolePID};
        _ ->
            case catch mod_map_ets:get_role_pid(RoleID) of %% map进程调用
                RolePID when erlang:is_pid(RolePID) ->
                    {ok, RolePID};
                _ ->
                    {error, not_exist}
            end
    end;
get_role_pid(RolePID) when is_pid(RolePID) ->
    {ok, RolePID}.

info_role(RoleArg, Info) ->
    case get_role_pid(RoleArg) of
        {ok, RolePID} ->
            pname_server:send(RolePID, Info);
        _ ->
            case common_config:is_cross_node() andalso erlang:is_integer(RoleArg) of
                true -> %% 跨服节点兼容处理
                    node_misc:cross_send_mfa_by_role_id(RoleArg, {?MODULE, info_role, [RoleArg, Info]});
                _ ->
                    {error, not_exist}
            end
    end.

%% RoleArg :RoleID|RolePID
info_role(RoleArg, Mod, Request) ->
    info_role(RoleArg, {mod, Mod, Request}).


info_role_after(AfterTime, RoleArg, Info) ->
    case get_role_pid(RoleArg) of
        {ok, RolePID} ->
            erlang:send_after(AfterTime, RolePID, Info);
        _ ->
            case common_config:is_cross_node() andalso erlang:is_integer(RoleArg) of
                true -> %% 跨服节点兼容处理
                    node_misc:cross_send_mfa_by_role_id(RoleArg, {?MODULE, info_role_after, [AfterTime, RoleArg, Info]});
                _ ->
                    {error, not_exist}
            end
    end.

%% @doc 踢玩家下线
kick_role(RoleID) ->
    kick_role(RoleID, ?ERROR_SYSTEM_ERROR_005).
kick_role(RoleID, Reason) ->
    ?ERROR_MSG("----Reason------~w",[Reason]),
    PName = gateway_misc:get_role_gpname(RoleID),
    case role_misc:pid(PName) of
        undefined ->
            case mod_role_dict:get_role_id() of
                RoleID ->
                    case mod_role_dict:get_gateway_pid() of
                        undefined ->
                            ignore;
                        PID ->
                            gateway_misc:exit(PID, Reason)
                    end;
                _ ->
                    ignore
            end;
        PID ->
            gateway_misc:exit(PID, Reason)
    end.

add_buff(_RoleID, []) ->
    ok;
add_buff(RoleID, #buff_args{} = BuffArgs) ->
    add_buff(RoleID, [BuffArgs]);
add_buff(RoleID, BuffList) ->
    role_misc:info_role(RoleID, mod_role_buff, {add_buff, BuffList}).

remove_buff(_RoleID, []) ->
    ok;
remove_buff(RoleID, BuffID) when erlang:is_integer(BuffID) ->
    remove_buff(RoleID, [BuffID]);
remove_buff(RoleID, BuffList) ->
    role_misc:info_role(RoleID, mod_role_buff, {remove_buff, BuffList}).

%% 外部进程调用
give_goods(RoleID, Action, GoodsList) ->
    Info = {mod, mod_role_bag, {create_goods, Action, GoodsList}},
    case common_config:is_cross_node() of
        true -> %% 跨服进程调用
            node_misc:cross_send_mfa_by_role_id(RoleID, {?MODULE, give_goods, [RoleID, Action, GoodsList]});
        _ ->
            case role_misc:is_online(RoleID) of
                true ->
                    role_misc:info_role(RoleID, Info);
                _ ->
                    world_offline_event_server:add_event(RoleID, {?MODULE, give_goods, [RoleID, Action, GoodsList]})
            end
    end.

%% 部分调用只能在线调用 || 跨服地图进程调用
online_give_goods(RoleID, Action, GoodsList) ->
    Info = {mod, mod_role_bag, {create_goods, Action, GoodsList}},
    role_misc:info_role(RoleID, Info).

%% 角色进程调用
%% 先检查是否有空格子，没有就发信件创建
create_goods(State, _Action, []) ->
    State;
create_goods(State, Action, GoodsList) ->
    #r_role{role_id = RoleID} = State,
    {BagList, LetterList} = mod_role_bag:spilt_bag_letter_goods(GoodsList, State),
    case LetterList =/= [] of
        true ->
            LetterInfo = #r_letter_info{template_id = ?LETTER_BAG_FULL, action = Action, goods_list = LetterList},
            common_letter:send_letter(RoleID, LetterInfo);
        _ ->
            ok
    end,
    case BagList =/= [] of
        true ->
            BagDoing = [{create, Action, BagList}],
            mod_role_bag:do(BagDoing, State);
        _ ->
            State
    end.

is_reset_week(State) ->
    #r_role{role_private_attr = #r_role_private_attr{reset_time = LastResetTime}} = State,
    LastDate = time_tool:timestamp_to_date(LastResetTime),
    ?IF(time_tool:week_of_year() =:= time_tool:week_of_year(LastDate), false, true).

%% 获取属性被动属性加成
get_skill_prop_rate(Key, State) ->
    #r_role{prop_rates = PropRates} = State,
    case lists:keyfind(Key, #p_kv.id, PropRates) of
        #p_kv{val = Val} ->
            Val;
        _ ->
            0
    end.

%% 养成功能丹药属性通用接口
get_pellet_attr(Config, List) ->
    {Props, AddRate} = get_pellet_attr2(Config, List, [], 0),
    {common_misc:get_attr_by_kv(Props), AddRate}.

get_pellet_attr2(_Config, [], PropsAcc, AddRateAcc) ->
    {PropsAcc, AddRateAcc};
get_pellet_attr2(Config, [KV|R], PropsAcc, AddRateAcc) ->
    #p_kv{id = TypeID, val = Num} = KV,
    [#c_pellet{props = Props}] = lib_config:find(Config, TypeID),
    {PropsAcc2, AddRateAcc2} =
    lists:foldl(
        fun(#p_kv{id = PropKey, val = Val} = PropKV, {Acc1, Acc2}) ->
            case lists:member(PropKey, [?ATTR_PET_ADD, ?ATTR_MOUNT_ADD, ?ATTR_WING_ADD, ?ATTR_MAGIC_WEAPON_ADD, ?ATTR_GOD_WEAPON_ADD]) of
                true ->
                    {Acc1, Acc2 + Val};
                _ ->
                    {[PropKV|Acc1], Acc2}
            end
        end,
        {PropsAcc, AddRateAcc}, common_misc:get_string_props(Props, Num)),
    get_pellet_attr2(Config, R, PropsAcc2, AddRateAcc2).

pellet_max_num(NewNum, MaxNum, State) ->
    ConfigList = lib_tool:string_to_intlist(MaxNum, "|", ","),
    Level = mod_role_data:get_role_level(State),
    pellet_max_num2(NewNum, Level, ConfigList, 0).

pellet_max_num2(NewNum, _Level, [], Acc) ->
    NewNum > Acc;
pellet_max_num2(NewNum, Level, [{NeedLevel, Num}|R], Acc) ->
    case Level >= NeedLevel of
        true ->
            pellet_max_num2(NewNum, Level, R, Num);
        _ ->
            NewNum > Acc
    end.

pellet_broadcast(ID, TypeID, State) ->
    #c_item{quality = Quality, name = Name} = mod_role_item:get_item_config(TypeID),
    ?IF(Quality >= ?QUALITY_RED, common_broadcast:send_world_common_notice(ID, [mod_role_data:get_role_name(State), Name]), ok).

level_broadcast(Level, NewLevel, ID, State) ->
    NoticeLevel = common_misc:get_global_int(?GLOBAL_NOTICE_LEVEL),
    [                                                 common_broadcast:send_world_common_notice(ID, [mod_role_data:get_role_name(State), lib_tool:to_list(LevelIndex)]) ||
        LevelIndex <- lists:seq(Level + 1, NewLevel), LevelIndex rem NoticeLevel =:= 0, LevelIndex >= 40]. % T 40 级以上 每10级广播一次

skill_broadcast(SkillList, ID, State) ->
    SkillNames = common_skill:get_skill_names(SkillList),
    common_broadcast:send_world_common_notice(ID, [mod_role_data:get_role_name(State), SkillNames]).

%% 养成功能经验通用接口
get_new_level_exp(ConfigFile, ExpIndex, Level, Exp) ->
    NewLevel = Level + 1,
    case lib_config:find(ConfigFile, NewLevel) of
        [_Config] ->
            [Config] = lib_config:find(ConfigFile, Level),
            NeedExp = erlang:element(ExpIndex, Config),
            case Exp >= NeedExp of
                true ->
                    get_new_level_exp(ConfigFile, ExpIndex, NewLevel, Exp - NeedExp);
                _ ->
                    {Level, Exp}
            end;
        _ ->
            {Level, 0}
    end.

%% 部分属性跟等级挂钩
get_attr_by_kv(List, State) ->
    Level = mod_role_data:get_role_level(State),
    {BigConfine, _SmallConfine} = mod_role_confine:get_confine(mod_role_confine:get_confine_id(State)),
    SealLevel = State#r_role.seal_all_level,
    {Attr1, KVList} =
    lists:foldl(
        fun(#p_kv{id = ID, val = Val} = KV, {AttrAcc, KVAcc}) ->
            #actor_cal_attr{
                max_hp = {MaxHp, MaxHpR},
                attack = {Attack, AttackR},
                defence = {Defence, DefenceR},
                arp = {Arp, ArpR},
                hit_rate = {HitRate, HitRateR},
                miss = {Miss, MissR},
                boss_hurt_add = {BossHurtAdd, BossHurtAddR},
                skill_hurt = {SkillHurt, SkillHurtR},
                skill_hurt_anti = {SkillHurtAnti, SkillHurtAntiR},
                hurt_rate = HurtRate,
                hurt_derate = HurtDeRate,
                double_rate = {DoubleRate, DoubleRateR},
                block_rate = BlockRate,
                block_reduce = BlockReduce
            } = AttrAcc,
            if
                ID =:= ?ATTR_EVERY_THREE_ATTACK ->
                    Value = erlang:round(Level * Val / 3),
                    AttrAcc2 = AttrAcc#actor_cal_attr{attack = {Attack + Value, AttackR}},
                    {AttrAcc2, KVAcc};
                ID =:= ?ATTR_EVERY_THREE_ARP ->
                    Value = erlang:round(Level * Val / 3),
                    AttrAcc2 = AttrAcc#actor_cal_attr{arp = {Arp + Value, ArpR}},
                    {AttrAcc2, KVAcc};
                ID =:= ?ATTR_EVERY_THREE_HP ->
                    Value = erlang:round(Level * Val / 3),
                    AttrAcc2 = AttrAcc#actor_cal_attr{max_hp = {MaxHp + Value, MaxHpR}},
                    {AttrAcc2, KVAcc};
                ID =:= ?ATTR_EVERY_THREE_DEFENCE ->
                    Value = erlang:round(Level * Val / 3),
                    AttrAcc2 = AttrAcc#actor_cal_attr{defence = {Defence + Value, DefenceR}},
                    {AttrAcc2, KVAcc};
                ID =:= ?ATTR_EVERY_TEN_ATTACK ->
                    Value = erlang:round(Level * Val),
                    {AttrAcc#actor_cal_attr{attack = {Attack + Value, AttackR}}, KVAcc};
                ID =:= ?ATTR_EVERY_FIFTY_BOSS_HURT ->
                    Value = erlang:round(Val * Level / 50),
                    AttrAcc2 = AttrAcc#actor_cal_attr{boss_hurt_add = {BossHurtAdd + Value, BossHurtAddR}},
                    {AttrAcc2, KVAcc};
                ID =:= ?ATTR_LEVEL_HP ->
                    Value = erlang:round(Val * Level),
                    {AttrAcc#actor_cal_attr{max_hp = {MaxHp + Value, MaxHpR}}, KVAcc};
                ID =:= ?ATTR_LEVEL_ATTACK ->
                    Value = erlang:round(Val * Level),
                    {AttrAcc#actor_cal_attr{attack = {Attack + Value, AttackR}}, KVAcc};
                ID =:= ?ATTR_LEVEL_DEFENCE ->
                    Value = erlang:round(Val * Level),
                    {AttrAcc#actor_cal_attr{defence = {Defence + Value, DefenceR}}, KVAcc};
                ID =:= ?ATTR_LEVEL_ARP ->
                    Value = erlang:round(Val * Level),
                    {AttrAcc#actor_cal_attr{arp = {Arp + Value, ArpR}}, KVAcc};
                ID =:= ?ATTR_LEVEL_HIT_RATE ->
                    Value = erlang:round(Val * Level),
                    {AttrAcc#actor_cal_attr{hit_rate = {HitRate + Value, HitRateR}}, KVAcc};
                ID =:= ?ATTR_LEVEL_MISS ->
                    Value = erlang:round(Val * Level),
                    {AttrAcc#actor_cal_attr{miss = {Miss + Value, MissR}}, KVAcc};
                ID =:= ?ATTR_LEVEL200_HURT_DERATE ->
                    Value = erlang:round(Val * (Level div 200)),
                    HurtDeRate2 = Value + HurtDeRate,
                    {AttrAcc#actor_cal_attr{hurt_derate = HurtDeRate2}, KVAcc};
                ID =:= ?ATTR_CONFINE_HP ->
                    Value = erlang:round(Val * BigConfine),
                    {AttrAcc#actor_cal_attr{max_hp = {MaxHp + Value, MaxHpR}}, KVAcc};
                ID =:= ?ATTR_CONFINE_ATTACK ->
                    Value = erlang:round(Val * BigConfine),
                    {AttrAcc#actor_cal_attr{attack = {Attack + Value, AttackR}}, KVAcc};
                ID =:= ?ATTR_CONFINE_HURT_DERATE ->
                    Value = erlang:round(Val * BigConfine),
                    {AttrAcc#actor_cal_attr{hurt_derate = HurtRate + Value}, KVAcc};
                ID =:= ?ATTR_CONFINE_HURT_RATE ->
                    Value = erlang:round(Val * BigConfine),
                    {AttrAcc#actor_cal_attr{hurt_rate = HurtDeRate + Value}, KVAcc};
                ID =:= ?ATTR_EQUIP_HURT_DERATE ->
                    %% mod_role_equip:is_prop_equip_fit(State) 没有放到外面，是因为这个ID只有1个地方用到，并且开放顺序比较靠后
                    HurtDeRateList2 = ?IF(mod_role_equip:is_prop_equip_fit(State), Val + HurtDeRate, HurtDeRate),
                    {AttrAcc#actor_cal_attr{hurt_derate = HurtDeRateList2}, KVAcc};
                ID =:= ?ATTR_CONFINE_SKILL_HURT_ANTI ->
                    Value = erlang:round(Val * BigConfine),
                    {AttrAcc#actor_cal_attr{skill_hurt_anti = {SkillHurtAnti + Value, SkillHurtAntiR}}, KVAcc};
                ID =:= ?ATTR_CONFINE_SKILL_HURT ->
                    Value = erlang:round(Val * BigConfine),
                    {AttrAcc#actor_cal_attr{skill_hurt = {SkillHurt + Value, SkillHurtR}}, KVAcc};
                ID =:= ?ATTR_CONFINE_BLOCK_REDUCE ->
                    Value = erlang:round(Val * BigConfine),
                    {AttrAcc#actor_cal_attr{block_reduce = BlockReduce + Value}, KVAcc};
                ID =:= ?ATTR_CONFINE_BLOCK_RATE ->
                    Value = erlang:round(Val * BigConfine),
                    {AttrAcc#actor_cal_attr{block_rate = BlockRate + Value}, KVAcc};
                ID =:= ?ATTR_SEAL_LEVEL_HP ->
                    Value = erlang:round(Val * SealLevel),
                    {AttrAcc#actor_cal_attr{max_hp = {MaxHp + Value, MaxHpR}}, KVAcc};
                ID =:= ?ATTR_SEAL_LEVEL_ATTACK ->
                    Value = erlang:round(Val * SealLevel),
                    {AttrAcc#actor_cal_attr{attack = {Attack + Value, AttackR}}, KVAcc};
                ID =:= ?ATTR_LEVEL10_DOUBLE_RATE ->
                    Value = erlang:round(Val * (Level div 10)),
                    {AttrAcc#actor_cal_attr{double_rate = {DoubleRate + Value, DoubleRateR}}, KVAcc};
                true ->
                    {AttrAcc, [KV|KVAcc]}
            end
        end, {#actor_cal_attr{}, []}, List),
    common_misc:sum_calc_attr2(Attr1, common_misc:get_attr_by_kv(KVList)).

%% 翅膀、神兵、法宝养成功能日志
log_role_nurture(State) ->
    #r_role{
        role_id = RoleID,
        role_attr = RoleAttr,
        role_god_weapon = RoleGodWeapon,
        role_wing = RoleWing,
        role_magic_weapon = RoleMagicWeapon} = State,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = RoleAttr,
    #r_role_god_weapon{level = GodWeaponLevel, skin_list = GodWeaponSkinList} = RoleGodWeapon,
    #r_role_wing{level = WingLevel, skin_list = WingSkinList} = RoleWing,
    #r_role_magic_weapon{level = MagicWeaponLevel, skin_list = MagicWeaponSkinList} = RoleMagicWeapon,
    Log =
    #log_role_nurture{
        role_id = RoleID,
        god_weapon_level = GodWeaponLevel,
        god_weapon_skins = to_nurture_skin_string(GodWeaponSkinList),
        wing_level = WingLevel,
        wing_skins = to_nurture_skin_string(WingSkinList),
        magic_weapon_level = MagicWeaponLevel,
        magic_weapon_skins = to_nurture_skin_string(MagicWeaponSkinList),
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    },
    mod_role_dict:add_background_logs(Log).

to_nurture_skin_string(SkinList) ->
    IDList = [ID || #p_kv{id = ID} <- SkinList],
    lib_tool:to_list_output(IDList).



get_base_attr_by_kv(Key, Value, LevelAttr) ->
    get_base_attr_by_kv([#p_kv{id = Key, val = Value}], LevelAttr).
get_base_attr_by_kv(List, LevelAttr) ->
    #actor_cal_attr{
        max_hp = {LevelHp, _},
        attack = {LevelAttack, _},
        defence = {LevelDefence, _},
        arp = {LevelArp, _}
    } = LevelAttr,
    #actor_cal_base_attr{
        base_hp = BaseHp,
        base_attack = BaseAttack,
        base_defence = BaseDefence,
        base_arp = BaseArp
    } = lists:foldl(
        fun(#p_kv{id = Key, val = Value}, BaseAttr) ->
            #actor_cal_base_attr{
                base_hp = BHp,                     %% 血量
                base_attack = BAttack,             %% 攻击
                base_defence = BDefence,           %% 防御
                base_arp = BArp                    %% 破甲
            } = BaseAttr,
            if
                Key =:= ?ATTR_BASE_ARP_RATE ->
                    BaseAttr#actor_cal_base_attr{base_arp = BArp + Value};
                Key =:= ?ATTR_BASE_HP_RATE ->
                    BaseAttr#actor_cal_base_attr{base_hp = BHp + Value};
                Key =:= ?ATTR_BASE_DEF_RATE ->
                    BaseAttr#actor_cal_base_attr{base_defence = BDefence + Value};
                Key =:= ?ATTR_BASE_ATTACK_RATE ->
                    BaseAttr#actor_cal_base_attr{base_attack = BAttack + Value};
                true ->
                    BaseAttr
            end
        end,#actor_cal_base_attr{} ,  List),
    #actor_cal_attr{
        max_hp = {LevelHp * BaseHp / ?RATE_10000, 0},
        attack = {LevelAttack * BaseAttack / ?RATE_10000, 0},
        defence = {LevelDefence * BaseDefence / ?RATE_10000, 0},
        arp = {LevelArp * BaseArp / ?RATE_10000, 0}
    }.



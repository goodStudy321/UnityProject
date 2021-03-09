%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 三月 2018 16:15
%%%-------------------------------------------------------------------
-module(mod_web_role).
-author("laijichang").
-include("web.hrl").
-include("global.hrl").
-include("role.hrl").
-include("proto/mod_role_equip.hrl").
-include("proto/mod_role_rune.hrl").
-include("proto/gateway.hrl").

%% API
-export([
    get_db_info/1,
    get_role_info/1,
    ban_role/1,
    ban_words/1,
    filter_words/1,
    ban_ip_imei/1,
    mark_insider/1,
    copy_role/1,
    ban_account/1,
    rename_role/1,
    kick_role/1,
    ban_chat/2
]).

get_db_info(Req) ->
    RoleID = get_req_role_id(Req),
    Post = Req:parse_post(),
    DBName = web_tool:get_atom_param("db_name", Post),
    case db:lookup(DBName, RoleID) of
        [Val] ->
            {ok, web_tool:transfer_to_json(Val)};
        _ ->
            {error, "not_found"}
    end.


get_role_info(Req) ->
    Post = Req:parse_post(),
    RoleIDs = web_tool:get_post_integer_list("role_id", Post),
    RoleInfos = [ {RoleID, get_role_info2(RoleID)} || RoleID <- RoleIDs],
    {list, RoleInfos}.

get_role_info2(RoleID) ->
    List = [
        {role_attr, ?DB_ROLE_ATTR_P, #r_role_attr{}},
        {role_private_attr, ?DB_ROLE_PRIVATE_ATTR_P, #r_role_private_attr{}},
        {role_map, ?DB_ROLE_MAP_P, #r_role_map{}},
        {role_fight, ?DB_ROLE_FIGHT_P, #r_role_fight{base_attr = #actor_fight_attr{}}},
        {role_asset, ?DB_ROLE_ASSET_P, #r_role_asset{}},
        {role_pay, ?DB_ROLE_PAY_P, #r_role_pay{}},
        {role_vip, ?DB_ROLE_VIP_P, #r_role_vip{}},
        {role_relive, ?DB_ROLE_RELIVE_P, #r_role_relive{}},

        {role_equip, ?DB_ROLE_EQUIP_P, #r_role_equip{}},
        {role_mount, ?DB_ROLE_MOUNT_P, #r_role_mount{}},
        {role_pet, ?DB_ROLE_PET_P, #r_role_pet{}},
        {role_god_weapon, ?DB_ROLE_GOD_WEAPON_P, #r_role_god_weapon{}},
        {role_magic_weapon, ?DB_ROLE_MAGIC_WEAPON_P, #r_role_magic_weapon{}},
        {role_wing, ?DB_ROLE_WING_P, #r_role_wing{}},
        {role_rune, ?DB_ROLE_RUNE_P, #r_role_rune{}}
    ],
    [RoleAttr, PrivateAttr, RoleMap, RoleFight, RoleAsset, RolePay, RoleVip, RoleRelive, RoleEquip, RoleMount, RolePet,
        RoleGodWeapon, RoleMagicWeapon, RoleWing, RoleRune] = get_role_detail(RoleID, List),
    web_tool:transfer_to_json(#web_role_info{
        role_basic = make_role_basic(RoleAttr, PrivateAttr, RoleMap, RoleFight, RoleAsset, RolePay, RoleVip, RoleRelive),
        role_equip_list = make_role_equip(RoleEquip),
        role_mount = make_role_mount(RoleMount),
        role_pet = make_role_pet(RolePet),
        role_god_weapon = make_role_god_weapon(RoleGodWeapon),
        role_magic_weapon = make_role_magic_weapon(RoleMagicWeapon),
        role_wing = make_role_wing(RoleWing),
        role_rune = make_role_rune(RoleRune)
    }).

ban_role(Req) ->
    Post = Req:parse_post(),
    RoleArgs = web_tool:get_string_param("role_args", Post),
    BanType = web_tool:get_int_param("ban_type", Post),
    BanAction = web_tool:get_int_param("ban_action", Post),
    EndTime = web_tool:get_int_param("end_time", Post),
    {RoleIDs, ErrorRoles} = get_ban_role_ids(RoleArgs),
    [ begin
          case BanAction of
              1 -> %% 封禁
                  mod_role_ban:add_ban(RoleID, BanType, EndTime);
              2 -> %% 解封
                  mod_role_ban:del_ban(RoleID, BanType)
          end
      end|| RoleID <- RoleIDs],
    {ok, to_ban_string(ErrorRoles, [])}.

to_ban_string([], Acc) ->
    Acc;
to_ban_string([T|R], []) ->
    Acc2 = lib_tool:to_list(T),
    to_ban_string(R, Acc2);
to_ban_string([T|R], Acc) ->
    Acc2 = Acc ++ "," ++ lib_tool:to_list(T),
    to_ban_string(R,  Acc2).

get_ban_role_ids(RoleArgs) ->
    RoleList = string:tokens(RoleArgs, ","),
    lists:foldr(
        fun(String, {Acc1, Acc2}) ->
            case catch lib_tool:to_integer(String) of
                RoleID when erlang:is_integer(RoleID) ->
                    case catch get_req_role_id2(RoleID, "") of
                        RoleID ->
                            {[RoleID|Acc1], Acc2};
                        _ ->
                            {Acc1, [RoleID|Acc2]}
                    end;
                _ ->
                    case catch get_req_role_id2(0, web_tool:to_utf8(String)) of
                        ID when erlang:is_integer(ID) ->
                            {[ID|Acc1], Acc2};
                        _ ->
                            {Acc1, [String|Acc2]}
                    end
            end
        end, {[], []}, RoleList).

ban_words(Req) ->
    Post = Req:parse_post(),
    OldWord = web_tool:to_utf8(web_tool:get_string_param("old_title", Post)),
    NewWord = web_tool:to_utf8(web_tool:get_string_param("new_title", Post)),
    BanTime = web_tool:get_int_param("ban_time", Post),
    BanWords = world_data:get_ban_words(),
    BanWords2 = lists:keydelete(OldWord, #r_ban_word.ban_word, BanWords),
    BanWords3 = lists:keystore(NewWord, #r_ban_word.ban_word, BanWords2, #r_ban_word{ban_word = NewWord, ban_time = BanTime}),
    world_data:set_ban_words(BanWords3),
    ok.

filter_words(Req) ->
    Post = Req:parse_post(),
    OldWord = web_tool:to_utf8(web_tool:get_string_param("old_title", Post)),
    NewWord = web_tool:to_utf8(web_tool:get_string_param("new_title", Post)),
    KeyWords = world_data:get_filter_words(),
    KeyWords2 = ?IF(NewWord =:= [], lists:delete(OldWord, lists:delete(NewWord, KeyWords)), [NewWord|lists:delete(OldWord, lists:delete(NewWord, KeyWords))]),
    world_data:set_filter_words(KeyWords2),
    ok.

ban_ip_imei(Req) ->
    Post = Req:parse_post(),
    Args = web_tool:get_string_param("role_args", Post),
    BanType = web_tool:get_int_param("ban_type", Post),
    BanAction = web_tool:get_int_param("ban_action", Post),
    EndTime = web_tool:get_int_param("end_time", Post),
    ArgsList = string:tokens(Args, ","),
    Fun1 = fun(Args1, AccT1) -> lists:keystore(Args1, 1, AccT1, {Args1, EndTime}) end,
    Fun2 = fun(Args2, AccT2) -> lists:keydelete(Args2, 1, AccT2) end,
    Fun = ?IF(BanAction =:= 1, Fun1, Fun2),
    if
        BanType =:= ?BAN_TYPE_IP -> %% IP封禁
            BanIPs = world_data:get_ban_ips(),
            BanIPs2 = lists:foldl(fun(IP, Acc) -> Fun(IP, Acc) end, BanIPs, ArgsList),
            world_data:set_ban_ips(BanIPs2);
        BanType =:= ?BAN_TYPE_IMEI -> %% 设备封禁
            BanIMEI = world_data:get_ban_imei(),
            BanIMEI2 = lists:foldl(fun(IMEI, Acc) -> Fun(IMEI, Acc) end, BanIMEI, ArgsList),
            world_data:set_ban_imei(BanIMEI2);
        BanType =:= ?BAN_TYPE_UID -> %% UID封禁
            BanUID = world_data:get_ban_uid(),
            BanUID2 = lists:foldl(fun(UID, Acc) -> Fun(UID, Acc) end, BanUID, ArgsList),
            world_data:set_ban_uid(BanUID2)
    end,
    ?IF(BanAction =:= 1, [ common_broadcast:bc_role_info_to_world({mod, mod_role_ban, {web_add_ban, BanType, BanArgs}}) || BanArgs <- ArgsList], ok),
    ok.

mark_insider(Req) ->
    Post = Req:parse_post(),
    RoleIDs = web_tool:get_integer_list("role_ids", Post),
    Status = web_tool:get_int_param("status", Post),
    Now = time_tool:now(),
    IsInsider =
        if
            Status =:= 1 -> %% 添加
                true;
            Status =:= 2 -> %% 删除
                false
        end,
    [ mod_role_insider:mark_insider(RoleID, IsInsider, Now)|| RoleID <- RoleIDs],
    ok.

copy_role(Req) ->
    Post = Req:parse_post(),
    FromRoleID = web_tool:get_int_param("from_role_id", Post),
    FromPublicIP = web_tool:get_string_param("from_database_ip", Post),
    FromPort = web_tool:get_int_param("from_database_port", Post),
    FromDataBase = web_tool:get_string_param("from_database_name", Post),
    ToRoleID = web_tool:get_int_param("to_role_id", Post),
    Options = web_tool:get_string_param("options", Post),
    OptionList = string:tokens(Options, ","),
    PoolID = ?MODULE,
    UserName = ?MYSQL_USER,
    Password = ?MYSQL_PASSWORD,
    Connections = ?DB_CONNECTIONS,
    %% 上次操作可能出错
    catch emysql:remove_pool(PoolID),
    ?WARNING_MSG("MySQL connecting to ~p:~p ~p:~p ~p ~w", [FromPublicIP, FromPort, UserName, Password, FromDataBase, Connections]),
    emysql:add_pool(PoolID, Connections, UserName, Password, FromPublicIP, FromPort, FromDataBase, utf8mb4),
    copy_role2(FromRoleID, ToRoleID, PoolID, OptionList),
    emysql:remove_pool(PoolID),
    ok.

copy_role2(FromRoleID, ToRoleID, PoolID, ["all"]) ->
    TabList = [ Tab || #c_tab{tab = Tab, class = {role, _}}<- ?TABLE_INFO],
    DataList3 = get_role_copy_data2(FromRoleID, PoolID, TabList, []),
    copy_role3(ToRoleID, DataList3);
copy_role2(FromRoleID, ToRoleID, PoolID, OptionList) ->
    DefaultTab = [?DB_ROLE_ATTR_P, ?DB_ROLE_FUNCTION_P],
    ConfigList = [
        {"skill", ?DB_ROLE_SKILL_P},
        {"relive", ?DB_ROLE_RELIVE_P},
        {"equip", ?DB_ROLE_EQUIP_P},
        {"handbook", ?DB_ROLE_HANDBOOK_P},
        {"mount", ?DB_ROLE_MOUNT_P},
        {"pet", ?DB_ROLE_PET_P},
        {"magic_weapon", ?DB_ROLE_MAGIC_WEAPON_P},
        {"god_weapon", ?DB_ROLE_GOD_WEAPON_P},
        {"wing", ?DB_ROLE_WING_P},
        {"rune", ?DB_ROLE_RUNE_P},
        {"immortal", ?DB_ROLE_IMMORTAL_SOUL_P},
        {"asset", ?DB_ROLE_ASSET_P},
        {"bag", ?DB_ROLE_BAG_P},
        {"confine", ?DB_ROLE_CONFINE_P},
        {"mission", ?DB_ROLE_MISSION_P}
    ],
    TabList =
    lists:foldl(
        fun(Option, Acc) ->
            case lists:keyfind(Option, 1, ConfigList) of
                {_, Tab} ->
                    [Tab|Acc];
                _ ->
                    ?ERROR_MSG("unknow : ~w", [Option]),
                    Acc
            end
        end, [], OptionList),
    DataList3 = get_role_copy_data2(FromRoleID, PoolID, DefaultTab ++ TabList, []),
    copy_role3(ToRoleID, DataList3).

get_role_copy_data2(_RoleID, _PoolID, [], DataAcc) ->
    DataAcc;
get_role_copy_data2(RoleID, PoolID, [Tab|R], DataAcc) ->
    case catch db_lib:kv_lookup_by_pool_id(PoolID, Tab, RoleID) of
        [Value] ->
            DataAcc2 = [{Tab, Value}|DataAcc],
            get_role_copy_data2(RoleID, PoolID, R, DataAcc2);
        _ ->
            get_role_copy_data2(RoleID, PoolID, R, DataAcc)
    end.

copy_role3(ToRoleID, DataList) ->
    erlang:spawn(
        fun() ->
            role_misc:kick_role(ToRoleID, ?ERROR_SYSTEM_ERROR_005),
            timer:sleep(1000),
            [begin
                 case Tab of
                     ?DB_ROLE_ATTR_P ->
                         [RoleAttr] = db:lookup(?DB_ROLE_ATTR_P, ToRoleID),
                         #r_role_attr{
                             level = Level,
                             skin_list = SkinList} = Value,
                         db:insert(?DB_ROLE_ATTR_P, RoleAttr#r_role_attr{level = Level, skin_list = SkinList});
                     ?DB_ROLE_MAP_P ->
                         ServerID = common_config:get_server_id(),
                         #r_role_map{map_id = MapID, old_map_id = OldMapID} = Value,
                         ExtraID = 1,
                         db:insert(db_role_map_p, Value#r_role_map{
                             server_id = ServerID,
                             extra_id = ExtraID,
                             map_pname = map_misc:get_map_pname(MapID, ExtraID, ServerID),
                             old_server_id = ServerID,
                             old_extra_id = ExtraID,
                             old_map_pname = map_misc:get_map_pname(OldMapID, ExtraID, ServerID)
                         });
                     _ ->
                         db:insert(Tab, erlang:setelement(2, Value, ToRoleID))
                 end
             end|| {Tab, Value} <- DataList]
        end).

ban_account(Req) ->
    Post = Req:parse_post(),
    FromAccount = web_tool:get_string_param("from_account", Post),
    ToAccount = web_tool:get_string_param("to_account", Post),
    login_server:ban_account(lib_tool:to_binary(FromAccount), lib_tool:to_binary(ToAccount)).

rename_role(Req) ->
    Post = Req:parse_post(),
    RoleID  = web_tool:get_int_param("role_id", Post),
    NewName = web_tool:to_utf8(web_tool:get_string_param("new_role_name", Post)),
    case role_misc:is_online(RoleID) of
        true ->
            pname_server:call(role_misc:pid(RoleID), {mod, mod_role_extra, {web_role_rename, NewName}});
        _ ->
            case db:lookup(?DB_ROLE_ATTR_P, RoleID) of
                [#r_role_attr{role_name = OldName} = RoleAttr] ->
                    case catch login_server:role_rename({RoleID, OldName, NewName}) of
                        ok ->
                            db:insert(?DB_ROLE_ATTR_P, RoleAttr#r_role_attr{role_name = NewName}),
                            ok;
                        _ ->
                            {error, "role name exist"}
                    end;
                _ ->
                    {error, "role_id not found"}
            end
    end.

kick_role(Req) ->
    RoleID = get_req_role_id(Req),
    role_misc:kick_role(RoleID, ?ERROR_SYSTEM_ERROR_042),
    ok.
ban_chat(RoleID, AddTime) ->
    EndTime = time_tool:now() + AddTime,
    URL = web_misc:get_web_url(banRole_url),
    Time = time_tool:now(),
    Ticket = web_misc:get_key(Time),
    Body =
        [
            {time, Time},
            {ticket, Ticket},
            {role_id, RoleID},
            {end_time, EndTime},
            {reason, ""}
        ],
    case ibrowse:send_req(URL, [{content_type, "application/json"}], post, lib_json:to_json(Body), [], 2000) of
        {ok, "200", _Headers2, Body2} ->
            {_, Obj2} = mochijson2:decode(Body2),
            {_, Status} = proplists:get_value(<<"status">>, Obj2),
            Code = lib_tool:to_integer(proplists:get_value(<<"code">>, Status)),
            case Code of
                10200 ->
                    ok;
                _ ->
                    ?ERROR_MSG("Code : ~w", [Code]),
                    ok
            end,
            ok;
        Error ->
            ?ERROR_MSG("Error:~w",[Error]),
            ok
    end.

get_req_role_id(Req) ->
    Post = Req:parse_post(),
    WebRoleID = web_tool:get_int_param("role_id", Post),
    WebRoleName = web_tool:to_utf8(web_tool:get_string_param("role_name", Post)),
    get_req_role_id2(WebRoleID, WebRoleName).

get_req_role_id2(WebRoleID, WebRoleName) ->
    RoleID = ?IF(WebRoleID > 0, WebRoleID, common_role_data:get_role_id_by_name(WebRoleName)),
    case RoleID > 0 andalso db:lookup(?DB_ROLE_ATTR_P, RoleID) of
        [_Attr] ->
            RoleID;
        _ ->
            erlang:throw({error, "role not found"})
    end.

get_role_detail(RoleID, List) ->
    case role_misc:is_online(RoleID) of
        true ->
            State = role_server:i(RoleID),
            Fields = record_info:fields(r_role),
            [ begin
                  case lib_tool:list_element_index(DictKey, Fields) of
                      Index when Index > 0 ->
                          Value = erlang:element(Index + 1, State),
                          ?IF(Value =:= undefined, Default, Value);
                      _ ->
                          Default
                  end
              end|| {DictKey, _DBKey, Default} <- List];
        _ ->
            [begin
                 case db:lookup(DBKey, RoleID) of
                     [Value] ->
                         Value;
                     _ ->
                         Default
                 end
             end || {_DictKey, DBKey, Default} <- List]
    end.

make_role_basic(RoleAttr, PrivateAttr, RoleMap, RoleFight, RoleAsset, RolePay, RoleVip, RoleRelive) ->
    #r_role_attr{
        role_id = RoleID,
        account_name = AccountName,
        uid = UID,
        role_name = RoleName,
        level = RoleLevel,
        sex = Sex,
        category = Category,
        power = Power,
        family_id = FamilyID,
        family_name = FamilyName
        } = RoleAttr,
    #r_role_private_attr{
        today_online_time = TodayOnlineTime,
        total_online_time = TotalOnlineTime
    } = PrivateAttr,
    #r_role_map{map_id = MapID} = RoleMap,
    #r_role_fight{base_attr = BaseAttr} = RoleFight,
    #r_role_asset{
        gold = Gold,
        bind_gold = BindGold,
        silver = Silver
    } = RoleAsset,
    #r_role_pay{
        total_pay_gold = TotalPayGold,
        total_pay_fee = TotalPayFee
    } = RolePay,
    #r_role_vip{
        level = VipLevel,
        expire_time = ExpireTime
    } = RoleVip,
    #r_role_relive{
        relive_level = ReliveLevel,
        progress = ReliveProgress
    } = RoleRelive,
    #actor_fight_attr{
        max_hp = Hp,
        attack = Attack,
        defence = Defence,
        arp = Arp,
        hit_rate = HitRate,
        miss = Miss,
        double = Double,
        double_anti = DoubleA,
        double_multi = DoubleM,
        hurt_rate = HurtR,
        hurt_derate = HurtD,
        double_rate = DoubleRate,
        miss_rate = MissRate,
        double_anti_rate = DoubleAntiRate,
        skill_hurt = SkillHurt,
        skill_hurt_anti = SkillHurtAnti,
        skill_dps = SkillDps,
        skill_ehp = SkillEhp,
        armor = Armor,
        role_hurt_reduce = RoleHurtReduce,
        boss_hurt_add = BossHurtAdd,
        rebound = Rebound} = BaseAttr,
    #web_role_basic{
        name = ?ROLE_INFO_BASIC,
        role_id = RoleID,
        account_name = AccountName,
        uid = UID,
        role_name = unicode:characters_to_binary(RoleName),
        role_level = RoleLevel,
        sex = Sex,
        category = Category,
        power = Power,
        today_online_time = TodayOnlineTime,
        total_online_time = TotalOnlineTime,
        family_id = FamilyID,
        family_name = unicode:characters_to_binary(FamilyName),

        vip_level = VipLevel,
        expire_time = ExpireTime,

        gold = Gold,
        bind_gold = BindGold,
        silver = Silver,
        total_pay_gold = TotalPayGold,
        total_pay_fee = TotalPayFee,

        map_id = MapID,

        relive_level = ReliveLevel,
        relive_progress = ReliveProgress,

        hp = Hp,
        attack = Attack,
        defence = Defence,
        arp = Arp,
        hit_rate = HitRate,
        miss = Miss,
        double = Double,
        double_anti = DoubleA,
        double_multi = DoubleM,
        hurt_rate = HurtR,
        hurt_derate = HurtD,
        double_rate = DoubleRate,
        miss_rate = MissRate,
        double_anti_rate = DoubleAntiRate,
        skill_hurt = SkillHurt,
        skill_hurt_anti = SkillHurtAnti,
        skill_dps = SkillDps,
        skill_ehp = SkillEhp,
        armor = Armor,
        role_hurt_reduce = RoleHurtReduce,
        boss_hurt_add = BossHurtAdd,
        rebound = Rebound
    }.

make_role_equip(RoleEquip) ->
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    EquipList2 =
    [ begin
          #p_equip{
              equip_id = EquipID,
              refine_level = RefineLevel,
              mastery = Mastery,
              suit_level = SuitLevel,
              stone_list = StoneList,
              excellent_list = ExcellentList
          } = Equip,
          #web_equip{
              equip_id = EquipID,
              refine_level = RefineLevel,
              mastery = Mastery,
              suit_level = SuitLevel,
              stone_list = StoneList,
              excellent_list = ExcellentList
          }
      end|| Equip <- EquipList],
    #web_role_equip{
        name = ?ROLE_INFO_EQUIP,
        equip_list = EquipList2
    }.

make_role_mount(RoleMount) ->
    #r_role_mount{
        mount_id = MountID,
        exp = Exp,
        cur_id = CurID,
        skin_list = SkinList,
        quality_list = QualityList
    } = RoleMount,
    #web_role_mount{
        name = ?ROLE_INFO_MOUNT,
        mount_id = MountID,
        exp = Exp,
        cur_id = CurID,
        skin_list = SkinList,
        pellet_list = QualityList
    }.

make_role_pet(RolePet) ->
    #r_role_pet{
        exp = Exp,
        step_exp = StepExp,
        cur_id = CurID,
        pet_id = PetID,
        pet_spirits = PelletList,
        surface_list = SkinList
    } = RolePet,
    #web_role_pet{
        name = ?ROLE_INFO_PET,
        level = 0,
        exp = Exp,
        step_exp = StepExp,
        cur_id = CurID,
        pet_id = PetID,
        pellet_list = PelletList,
        skin_list = SkinList
    }.

make_role_god_weapon(RoleGodWeapon) ->
    #r_role_god_weapon{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = PelletList
    } = RoleGodWeapon,
    #web_role_god_weapon{
        name = ?ROLE_INFO_GOD_WEAPON,
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        pellet_list = PelletList
    }.

make_role_magic_weapon(RoleMagicWeapon) ->
    #r_role_magic_weapon{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = PelletList
    } = RoleMagicWeapon,
    #web_role_magic_weapon{
        name = ?ROLE_INFO_MAGIC_WEAPON,
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        pellet_list = PelletList
    }.

make_role_wing(RoleWing) ->
    #r_role_wing{
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        soul_list = PelletList
    } = RoleWing,
    #web_role_wing{
        name = ?ROLE_INFO_WING,
        cur_id = CurID,
        level = Level,
        exp = Exp,
        skin_list = SkinList,
        pellet_list = PelletList
    }.

make_role_rune(RoleRune) ->
    #r_role_rune{
        exp = Exp,
        piece = Piece,
        essence = Essence,
        load_runes = LoadRunes} = RoleRune,
    LoadRunes2 = [ #p_kv{id = Index, val = LevelID}|| #p_rune{index = Index, level_id = LevelID} <- LoadRunes],
    #web_role_rune{
        name = ?ROLE_INFO_RUNE,
        exp = Exp,
        piece = Piece,
        essence = Essence,
        load_runes = LoadRunes2
    }.


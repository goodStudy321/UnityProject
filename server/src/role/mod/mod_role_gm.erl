%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     GM
%%% @end
%%% Created : 09. 六月 2017 17:47
%%%-------------------------------------------------------------------
-module(mod_role_gm).
-author("laijichang").
-include("role.hrl").
-include("role_extra.hrl").
-include("letter.hrl").
-include("family_escort.hrl").
-include("family_god_beast.hrl").
-include("summit_tower.hrl").
-include("proto/gateway.hrl").
-include("proto/mod_role_gm.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_chat.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_role_escort.hrl").
-include("proto/mod_role_addict.hrl").
-record(c_tester, {
    id = 0,   %% ID
    list  %% 物品列表
}).

%% API
-export([
    calc/1,
    handle/2
]).

-export([
    trim_space/1
]).

-export([
    send_gm/2,
    send_gm/3
]).

send_gm(RoleID, Type) ->
    send_gm(RoleID, Type, "").
send_gm(RoleID, Type, Args) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {send_gm, Type, Args}}).

calc(State) ->
    case common_config:is_gm_open() of
        true ->
            PropList = mod_role_extra:get_data(?EXTRA_KEY_GM_PROPS, [], State),
            CalcAttr = common_misc:get_attr_by_kv(PropList),
            mod_role_fight:get_state_by_kv(State, ?CALC_KEY_GM_PROP, CalcAttr);
        _ ->
            State
    end.

handle({send_gm, Type, Args}, State) ->
    do_gm2(State, lib_tool:to_list(Type), lib_tool:to_list(Args));
handle({#m_role_gm_tos{type = Type, args = Args}, RoleID, _PID}, State) ->
    State2 = do_gm(RoleID, State, Type, Args),
    State2.

do_gm(RoleID, State, Type, Args) ->
    case common_config:is_gm_open() of
        true ->
            {Result, State2} = do_gm2(State, trim_space(Type), trim_space(Args)),
            common_misc:unicast(RoleID, #m_role_gm_toc{result = lib_tool:to_unicode(Result)}),
            State2;
        _ ->
            State
    end.

do_gm2(State, Type, Args) ->
    ?WARNING_MSG("gm order RoleID:~w, Type:~ts, ~ts", [State#r_role.role_id, Type, Args]),
    Args2 = string:tokens(Args, ";"),
    Args3 =
    [begin
         IntArg = (catch erlang:list_to_integer(Arg)),
         ?IF(erlang:is_integer(IntArg), IntArg, Arg)
     end || Arg <- Args2],
    case lists:keyfind(Type, 1, get_all_fun()) of
        {_, Fun, _Desc} ->
            {"ok", Fun([State|Args3])};
        false ->
            ?ERROR_MSG("can not find:~s(~w) ", [Type, Args3]),
            {"cmd not found", State}
    end.

-define(GOD_BUFF, [999991]).
get_all_fun() ->
    [
        {"god",
            fun([State|_]) ->
                RoleID = State#r_role.role_id,
                AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_GM, 100000, 100000}, {add_silver, ?ASSET_SILVER_ADD_FROM_GM, 10000000}],
                State2 = role_misc:create_goods(mod_role_asset:do(AssetDoing, State), ?ITEM_GAIN_GM, [#p_goods{type_id = 20000, num = 1, bind = false}]),
                BuffList = [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || BuffID <- ?GOD_BUFF],
                role_misc:add_buff(RoleID, BuffList),
                RoleLevel = lib_tool:random(360, 400),
                State3 = mod_role_level:gm_set_level(RoleLevel, State2),
                State4 = mod_role_vip:gm_set_vip(5, State3),
                State5 = mod_role_function:gm_trigger_function(State4),
                GuideExpTimes = common_misc:get_global_int(?GLOBAL_COPY_EXP),
                State6 = mod_role_copy:gm_guide_exp(GuideExpTimes, GuideExpTimes, State5),
                State6
            end, "god"},
        {"clear_god",
            fun([State|_]) ->
                role_misc:remove_buff(State#r_role.role_id, ?GOD_BUFF),
                State
            end, "clear_god"},
        {"clear_mf",
            fun([State|_]) ->
                RoleID = State#r_role.role_id,
                State2 = State#r_role{role_mission = #r_role_mission{role_id = RoleID}, role_function = #r_role_function{role_id = RoleID}},
                State3 = mod_role_skill:gm_clear_skills(State2),
                mod_role_function:pre_enter(mod_role_mission:pre_enter(State3))
            end, "clear_god"},
        {"bag_create_goods",
            fun([State, TypeID, Num|_]) ->
                Num2 = erlang:min(Num, 10000),
                CreateList = [#p_goods{type_id = TypeID, num = Num2, bind = false}],
                role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList)
            end, "背包创建物品TypeID + Num"},
        {"bag_decrease_goods",
            fun([State, TypeID, Num|T]) ->
                DecreaseList = [#r_goods_decrease_info{type_id = TypeID, num = Num}],
                State2 = mod_role_bag:do([{decrease, ?ITEM_REDUCE_GM, DecreaseList}], State),
                bag_decrease_goods(State2, T)
            end, "背包创建物品TypeID + Num"},
        {"role_clear_bag",
            fun([State|_]) ->
                mod_role_bag:gm_clear_bag(State)
            end, "清理背包"},
        {"role_add_exp",
            fun([State, AddExp|_]) ->
                mod_role_level:do_add_exp(State, AddExp, ?EXP_ADD_FROM_GM)
            end, "增加角色经验"},
        {"role_set_level",
            fun([State, Level|_]) ->
                mod_role_level:gm_set_level(Level, State)
            end, "调整角色等级"},
        {"role_add_gold",
            fun([State, Gold, BindGold|_]) ->
                AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_GM, erlang:min(Gold, 1000000), erlang:min(BindGold, 1000000)}],
                mod_role_asset:do(AssetDoing, State)
            end, "增加元宝"},
        {"role_add_silver",
            fun([State, Silver|_]) ->
                Silver2 = erlang:min(lib_tool:to_integer(math:pow(2, 40)), Silver),
                AssetDoing = [{add_silver, ?ASSET_SILVER_ADD_FROM_GM, Silver2}],
                mod_role_asset:do(AssetDoing, State)
            end, "增加银两"},
        {"role_set_gold",
            fun([State, Gold, BindGold|_]) ->
                Gold2 = erlang:min(Gold, lib_tool:to_integer(math:pow(2, 16))),
                BindGold2 = erlang:min(BindGold, lib_tool:to_integer(math:pow(2, 16))),
                mod_role_asset:gm_set_gold(Gold2, BindGold2, State)
            end, "设置元宝"},
        {"role_set_silver",
            fun([State, Silver|_]) ->
                Silver2 = erlang:min(Silver, lib_tool:to_integer(math:pow(2, 40))),
                mod_role_asset:gm_set_silver(Silver2, State)
            end, "设置银两"},
        {"role_add_illusion",
            fun([State, AddIllusion|_]) ->
                mod_role_copy:gm_add_illusion(AddIllusion, State)
            end, "增加幻力"},
        {"role_add_nat_intensify",
            fun([State, AddNat|_]) ->
                mod_role_copy:gm_add_nat_intensify(AddNat, State)
            end, "增加可领取勾玉"},
        {"role_clear_universe_rank",
            fun([State|_]) ->
                center_universe_server:gm_clear_universe_rank(),
                State
            end, "设置五行秘境层数"},
        {"role_set_universe",
            fun([State, Universe|_]) ->
                mod_role_copy:gm_set_universe(Universe, State)
            end, "设置五行秘境层数"},
        {"role_set_five_elements",
            fun([State, CopyID|_]) ->
                mod_role_copy:gm_set_five_elements(CopyID, State)
            end, "设置五行秘境层数"},
        {"role_add_score",
            fun([State, Type, Value|_]) ->
                Value2 = erlang:min(Value, lib_tool:to_integer(math:pow(2, 30))),
                AssetDoing = [{add_score, ?ASSET_SCORE_ADD_FROM_GM, Type, Value2}],
                mod_role_asset:do(AssetDoing, State)
            end, "增加积分"},
        {"role_add_stone",
            fun([State, Num|_]) ->
                CreateList = [#p_goods{type_id = StoneID, num = Num, bind = false} || {StoneID, _Config} <- cfg_stone:list()],
                mod_role_bag:do([{create, ?ITEM_GAIN_GM, CreateList}], State)
            end, "增加宝石"},
        {"role_add_seal",
            fun([State, Num|_]) ->
                CreateList = [#p_goods{type_id = SealID, num = Num, bind = false} || {SealID, _Config} <- lib_config:list(cfg_seal)],
                role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList)
            end, "增加纹印"},
        {"role_mount_open",
            fun([State|_]) ->
                mod_role_function:gm_trigger_function2([?FUNCTION_MOUNT], State)
            end, "开启坐骑"},
        {"role_pet_open",
            fun([State|_]) ->
                mod_role_function:gm_trigger_function2([?FUNCTION_PET], State)
            end, "开启宠物"},
        {"role_pingce",
            fun([State|_]) ->
                common_shell:send_pingce_goods(State#r_role.role_id, 3),
                State
            end, "一键测评号接口"},
        {"role_pay",
            fun([State, AddGold|_]) ->
                mod_role_pay:gm_pay(erlang:min(AddGold, lib_tool:to_integer(math:pow(2, 16))), State)
            end, "充值元宝"},
        {"role_product_id",
            fun([State, ProductID|_]) ->
                mod_role_pay:gm_product_id(ProductID, State)
            end, "充值特定商品"},
        {"role_add_step_exp",
            fun([State, AddExp, TypeID, Num|_]) ->
                mod_role_pet:add_step_exp(AddExp, TypeID, Num, State)
            end, "开启宠物"},
        {"role_magic_weapon_open",
            fun([State|_]) ->
                mod_role_function:gm_trigger_function2([?FUNCTION_MAGIC_WEAPON], State)
            end, "开启法宝"},
        {"role_god_weapon_open",
            fun([State|_]) ->
                mod_role_function:gm_trigger_function2([?FUNCTION_GOD_WEAPON], State)
            end, "开启神兵"},
        {"role_wing_open",
            fun([State|_]) ->
                mod_role_function:gm_trigger_function2([?FUNCTION_WING], State)
            end, "开启翅膀"},
        {"role_magic_weapon_skin_id",
            fun([State, MagicWeaponID|_]) ->
                mod_role_magic_weapon:gm_magic_weapon_skin_id(MagicWeaponID, State)
            end, "增加法宝经验"},
        {"role_self_kill",
            fun([State|_]) ->
                #r_role{role_id = RoleID} = State,
                mod_map_role:role_buff_reduce_hp(mod_role_dict:get_map_pid(), RoleID, RoleID, 100000000, ?BUFF_POISON, 0),
                State
            end, "自杀"},
        {"role_send_letter",
            fun([State, Num, TemplateID|Goods]) ->
                #r_role{role_id = RoleID} = State,
                Num2 = erlang:min(erlang:max(Num, 1), 10000),
                GoodsList = [#p_goods{type_id = TypeID, num = 1, bind = true} || TypeID <- Goods],
                ?IF(Num2 > 100000, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
                [common_letter:send_letter(RoleID, #r_letter_info{template_id = TemplateID, action = ?ITEM_GAIN_GM, goods_list = GoodsList}) || _N <- lists:seq(1, Num2)],
                State
            end, "发送信件"},
        {"role_exit",
            fun([State|_]) ->
                role_login:notify_exit(?ERROR_SYSTEM_ERROR_005),
                State
            end, "断线"},
        {"role_main_mission",
            fun([State, MissionID|_]) ->
                mod_role_mission:gm_get_mission(MissionID, State)
            end, "设置主线任务"},
        {"role_get_mission",
            fun([State, MissionID|_]) ->
                mod_role_mission:gm_get_mission(MissionID, State)
            end, "设置任务"},
        {"role_add_chapter",
            fun([State, ChapterID, Num|_]) ->
                mod_role_chapter:gm_add_chapter(ChapterID, Num, State)
            end, "增加章节"},
        {"role_enter_map",
            fun([State, MapID|_]) ->
                mod_role_map:do_gm_pre_enter(MapID, State)
            end, "进入地图"},
        {"clear_enter_list",
            fun([State|_]) ->
                mod_role_map:gm_clear_enter_list(State)
            end, "清除进入次数"},
        {"role_clear_monster",
            fun([State|_]) ->
                #r_role{role_id = RoleID} = State,
                map_misc:info(mod_role_dict:get_map_pid(), {func, fun() ->
                    mod_map_monster:gm_delete_monsters(RoleID) end}),
                State
            end, "清理当前场景的怪物"},
        {"role_add_monster",
            fun([State, TypeID|_]) ->
                #r_role{role_id = RoleID} = State,
                map_misc:info(mod_role_dict:get_map_pid(), {func, fun() ->
                    mod_map_monster:gm_add_monster(RoleID, TypeID) end}),
                State
            end, "GM命令添加怪物"},
        {"role_dead_monster",
            fun([State, TypeID|_]) ->
                #r_role{role_id = RoleID} = State,
                map_misc:info(mod_role_dict:get_map_pid(), {func, fun() ->
                    mod_map_monster:gm_delete_monster(RoleID, TypeID) end}),
                State
            end, "GM清除某类型的怪"},
        {"role_add_drop",
            fun([State, TypeID|_]) ->
                #r_role{role_id = RoleID} = State,
                map_misc:info(mod_role_dict:get_map_pid(), {func, fun() ->
                    mod_map_drop:gm_add_drop(RoleID, TypeID) end}),
                State
            end, "GM命令添加掉落物"},
        {"role_drop_id",
            fun([State|DropIDList]) ->
                #r_role{role_id = RoleID} = State,
                map_misc:info(mod_role_dict:get_map_pid(), {func, fun() ->
                    mod_map_drop:gm_drop_id(RoleID, DropIDList) end}),
                State
            end, "GM掉落ID次数"},
        {"role_function_open",
            fun([State|_]) ->
                mod_role_function:gm_trigger_function(State)
            end, "GM开启所有功能"},
        {"role_skill_open",
            fun([State|_]) ->
                mod_role_function:gm_skill_open(State)
            end, "GM开启所有功能附带的技能"},
        {"role_finish_achievement",
            fun([State|_]) ->
                mod_role_achievement:gm_finish_achievement(State)
            end, "GM开启所有功能附带的技能"},
        {"role_solo_score",
            fun([State, AddScore|_]) ->
                mod_solo:gm_add_score(State#r_role.role_id, AddScore),
                State
            end, "GM命令增加solo积分"},
        {"role_clear_solo",
            fun([State|_]) ->
                mod_solo:gm_clear_solo(State#r_role.role_id),
                State
            end, "GM命令增加solo积分"},
        {"role_clear_discount_pay",
            fun([State|_]) ->
                mod_role_discount_pay:gm_clear(State)
            end, "GM命令清楚礼包信息"},
        {"role_add_discount_pay",
            fun([State, ID|_]) ->
                mod_role_discount_pay:gm_generate(ID, State)
            end, "GM命令生成礼包信息"},
        {"role_add_skill",
            fun([State, SkillID|_]) ->
                mod_role_skill:skill_open(SkillID, State)
            end, "GM增加某个技能"},
        {"role_open_function",
            fun([State|FunctionIDList]) ->
                mod_role_function:gm_trigger_function2(FunctionIDList, State)
            end, "GM开启某个功能"},
        {"role_fashion_timeout",
            fun([State|_]) ->
                mod_role_fashion:gm_fashion_timeout(State)
            end, "所有限时时装直接过期"},
        {"role_del_function",
            fun([State, FunctionID|_]) ->
                mod_role_function:gm_del_function(FunctionID, State)
            end, "GM关闭某个功能"},
        {"role_add_offline_time",
            fun([State, AddTime|_]) ->
                mod_role_world_robot:add_time(AddTime, State)
            end, "增加离线挂机时间"},
        {"role_offline_reward",
            fun([State, RewardMin|_]) ->
                mod_role_world_robot:gm_reward(RewardMin, State)
            end, "获得离线挂机奖励"},
        {"role_add_rune",
            fun([State, LevelID, Num|_]) ->
                ?IF(Num > 100000, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
                mod_role_rune:add_rune(lists:duplicate(Num, LevelID), State)
            end, "GM增加符文"},
        {"role_clear_rune",
            fun([State|_]) ->
                mod_role_rune:gm_clear_bag(State)
            end, "GM清空符文背包"},
        {"add_more_runes",
            fun([State|_]) ->
                GoodsList =
                [begin
                     #c_item{type_id = TypeID, effect_type = EffectType, effect_args = EffectArgs} = Config,
                     case EffectType =:= ?ITEM_ADD_RUNE andalso lib_config:find(cfg_rune, lib_tool:to_integer(EffectArgs)) of
                         [#c_rune{level_id = RuneLevelID}] when ?RUNE_LEVEL(RuneLevelID) =:= 1 ->
                             #p_goods{type_id = TypeID, num = 5};
                         _ ->
                             []
                     end
                 end || {_, Config} <- cfg_item:list()],
                GoodsList2 = lists:flatten(GoodsList),
                mod_role_bag:do([{create, ?ITEM_GAIN_GM, GoodsList2}], State)
            end, "GM增加一级符文"},
        {"role_day_target",
            fun([State]) ->
                mod_role_day_target:gm_set_all(State)
            end, "设置7日目标条件"},
        {"role_day_target_reset",
            fun([State]) ->
                mod_role_day_target:gm_reset_all(State)
            end, "设置7日目标条件"},
        {"role_add_rune_exp",
            fun([State, AddExp|_]) ->
                mod_role_rune:add_exp(AddExp, State)
            end, "GM增加符文经验"},
        {"role_add_piece",
            fun([State, Num|_]) ->
                mod_role_rune:add_piece(Num, State)
            end, "GM增加符文碎片"},
        {"role_add_essence",
            fun([State, Num|_]) ->
                mod_role_rune:add_essence(Num, State)
            end, "GM增加符文精粹"},
        {"role_copy_tower",
            fun([State, TowerID|_]) ->
                mod_role_copy:gm_set_copy_tower(TowerID, State)
            end, "设置爬塔层数"},
        {"role_copy_forge_soul",
            fun([State, CopyID|_]) ->
                ?IF(CopyID > 50150, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
                mod_role_copy:gm_set_forge_soul(CopyID, State)
            end, "设置镇魂塔层数"},
        {"role_clear_copy",
            fun([State|_]) ->
                mod_role_copy:gm_clear_copy_times(State)
            end, "清理副本次数"},
        {"add_copy_enter",
            fun([State, CopyType, AddTimes|_]) ->
                mod_role_copy:gm_add_copy_times(CopyType, AddTimes, State)
            end, "清理副本次数"},
        {"role_copy_time",
            fun([State, RemainTime|_]) ->
                mod_role_copy:gm_set_copy_time(RemainTime, State)
            end, "设置副本结束时间"},
        {"role_vip",
            fun([State, Level|_]) ->
                mod_role_vip:gm_set_vip(Level, State)
            end, "设置VIP等级"},
        {"role_vip_exp",
            fun([State, Exp|_]) ->
                mod_role_vip:gm_add_exp(State, Exp)
            end, "+VIP经验"},
        {"role_vip_expire",
            fun([State|_]) ->
                mod_role_vip:gm_vip_expire(State)
            end, "设置VIP等级"},
        {"robot_start",
            fun([State, Num, Type|_]) ->
                robot_misc:start_by_num(Num, Type),
                State
            end, "设置VIP等级"},
        {"set_online_time",
            fun([State, Min|_]) ->
                #r_role{role_private_attr = PrivateAttr} = State,
                PrivateAttr2 = PrivateAttr#r_role_private_attr{today_online_time = Min * ?ONE_MINUTE},
                State#r_role{role_private_attr = PrivateAttr2}
            end, "设置在线时间"},
        {"role_add_vip_exp",
            fun([State, AddExp|_]) ->
                mod_role_vip:use_gold(AddExp * 100, State)
            end, "设置VIP等级"},
        {"gm_add_times",
            fun([State, Times|_]) ->
                mod_role_offline_solo:gm_add_times(Times, State)
            end, "设置VIP等级"},
        {"role_add_buff",
            fun([State, BuffID|_]) ->
                RoleID = State#r_role.role_id,
                BuffList = [#buff_args{buff_id = BuffID, from_actor_id = RoleID}],
                role_misc:add_buff(RoleID, BuffList),
                State
            end, "增加buff"},
        {"role_remove_buff",
            fun([State, BuffID|_]) ->
                RoleID = State#r_role.role_id,
                role_misc:remove_buff(RoleID, BuffID),
                State
            end, "移除buff"},
        {"role_daily_mission",
            fun([State|_]) ->
                mod_role_mission:gm_refresh_daily_mission(State)
            end, "刷新跑环任务"},
        {"role_relive_level",
            fun([State, ReliveLevel|R]) ->
                ?IF(ReliveLevel > 10, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
                Progress =
                case R of
                    [Value|_] ->
                        Value;
                    _ ->
                        0
                end,
                mod_role_relive:gm_set_relive_level(ReliveLevel, Progress, State)
            end, "设置转生等级"},
        {"role_guide_id",
            fun([State, GuideID|_]) ->
                mod_role_extra:gm_set_guide(GuideID, State)
            end, "设置引导"},
        {"role_first_world_boss",
            fun([State|_]) ->
                mod_role_world_boss:gm_first_world_boss(State)
            end, "设置引导"},
        {"role_add_friendly",
            fun([State, AddFriendly|_]) ->
                mod_role_friend:gm_add_friendly(AddFriendly, State)
            end, "取消当前的预约"},
        {"role_friend_request",
            fun([State, Num|_]) ->
                world_friend_server:gm_friend_request(State#r_role.role_id, Num),
                State
            end, "增加XX名好友请求"},
        {"role_clear_appoint",
            fun([State|_]) ->
                marry_server:gm_clear_appoint(State#r_role.role_id),
                State
            end, "取消当前的预约"},
        {"role_start_feast",
            fun([State|Remain]) ->
                marry_server:gm_start_feast(State#r_role.role_id, Remain),
                State
            end, "开启婚礼"},
        {"role_stop_feast",
            fun([State|_]) ->
                marry_server:gm_stop_feast(State#r_role.role_id),
                State
            end, "关闭婚礼"},
        {"role_feast_heat",
            fun([State, AddHeat|_]) ->
                mod_role_marry:gm_feast_heat(AddHeat, State),
                State
            end, "增加婚礼热度"},
        {"role_bow_time",
            fun([State, RemainTime|_]) ->
                mod_role_marry:gm_bow_time(RemainTime, State),
                State
            end, "设置拜堂时间"},
        {"clear_boss_times",
            fun([State|_]) ->
                mod_role_world_boss:gm_clear_times(State)
            end, "清除世界boss疲劳值"},
        {"clear_boss_cd",
            fun([State|_]) ->
                world_boss_server:gm_clear_boss_cd(),
                State
            end, "清除世界bossCD"},
        {"clear_mythical_cd",
            fun([State|_]) ->
                world_boss_server:gm_clear_mythical_cd(),
                State
            end, "清除神兽岛bossCD"},
        {"clear_ancients_cd",
            fun([State|_]) ->
                world_boss_server:gm_clear_ancients_cd(),
                State
            end, "清除远古bossCD"},
        {"world_boss_time",
            fun([State, RemainTime|_]) ->
                mod_role_world_boss:gm_reduce_time(State, RemainTime)
            end, "清除世界boss地图内时间"},
        {"role_gm_chat",
            fun([State, Msg|_]) ->
                DataRecord = #m_chat_text_toc{msg = lib_tool:to_list(Msg)},
                common_misc:unicast(State#r_role.role_id, DataRecord),
                State
            end, "清除世界boss地图内时间"},
        {"activity_start",
            fun([State, ID|Remain]) ->
                world_activity_server:info({gm_start, ID, Remain}),
                catch cross_activity_server:info({gm_start, ID, Remain}),
                State
            end, "活动开始"},
        {"start_all_activity",
            fun([State|_]) ->
                [begin
                     world_activity_server:info({gm_start, ID, []}),
                     catch cross_activity_server:info({gm_start, ID, []})
                 end || ID <- lists:seq(10001, 10012, 1)],
                [world_act_server:info({gm_start, ID}) || ID <- lists:seq(1001, 1031, 1)],
                State
            end, "活动开始"},
        {"stop_all_activity",
            fun([State|_]) ->
                [begin
                     world_activity_server:info({gm_stop, ID, []}),
                     catch cross_activity_server:info({gm_stop, ID, []})
                 end || ID <- lists:seq(10001, 10012, 1)],
                [world_act_server:info({gm_stop, ID}) || ID <- lists:seq(1001, 1031, 1)],
                State
            end, "活动开始"},
        {"add_summit_score",
            fun([State, AddScore|_]) ->
                RoleID = State#r_role.role_id,
                case mod_summit_tower:get_role_summit(RoleID) of
                    [#r_role_summit{map_id = MapID}] ->
                        mod_summit_tower:add_score(MapID, RoleID, AddScore);
                    _ ->
                        ok
                end,
                State
            end, "活动开始"},
        {"add_family_bs",
            fun([State, Val1, Val2|_]) ->
                mod_family_bs:gm_update_family_grain(State, Val1, Val2)
            end, "增加兽粮"},
        {"add_liveness",
            fun([State, Val1|_Val2]) ->
                mod_role_daily_liveness:gm_add_liveness(State, Val1)
            end, "增加活跃度"},
        {"add_act_online_time",
            fun([State, Val1|_Val2]) ->
                mod_role_act_online:gm_add_online_time(State, Val1)
            end, "增加在线奖励时间"},
        {"add_talent_points",
            fun([State, AddPoints|_]) ->
                mod_role_relive:add_talent_points(AddPoints, State)
            end, "增加天赋点数"},
        {"role_do_10minloop",
            fun([State, Mod, Time|_]) ->
                case ?TRY_CATCH(erlang:apply(lib_tool:to_atom(Mod), loop_10min, [Time, State])) of
                    #r_role{} = State2 ->
                        ok;
                    Error ->
                        ?ERROR_MSG("execute loop error: ~w, ~w", [Mod, Error]),
                        State2 = State
                end,
                State2
            end, "GM触发10分钟循环"},
        {"role_set_camp",
            fun([State, CampID|_]) ->
                mod_role_battle:gm_camp_change(CampID, State)
            end, "阵营修改"},
        {"role_add_title",
            fun([State, TitleID|_]) ->
                mod_role_title:gm_add_title(TitleID, State)
            end, "称号添加"},
        {"role_add_resource",
            fun([State|List]) ->
                case List of
                    [ID, BaseTimes] ->
                        mod_role_resource:gm_add_times(ID, BaseTimes, 0, State);
                    [ID, BaseTimes, ExtraTimes] ->
                        mod_role_resource:gm_add_times(ID, BaseTimes, ExtraTimes, State);
                    _ ->
                        State
                end
            end, "称号添加"},
        {"role_del_title",
            fun([State, TitleID|_]) ->
                mod_role_title:gm_del_title(TitleID, State)
            end, "称号删除"},
        {"role_reset_survey",
            fun([State|_]) ->
                mod_role_survey:gm_reset_survey(State)
            end, "重设问卷"},
        {"role_god_book",
            fun([State, Type|_]) ->
                mod_role_god_book:gm_set_type(Type, State)
            end, "重设问卷"},
        {"role_comment",
            fun([State|_]) ->
                mod_role_extra:gm_set_comment(State)
            end, "重设问卷"},
        {"role_add_skin",
            fun([State, ID|_]) ->
                mod_role_skin:gm_add_skin_id(ID, State)
            end, "增加皮肤ID"},
        {"role_ornament",
            fun([State|IDList]) ->
                mod_role_skin:gm_set_ornament(IDList, State)
            end, "设置装饰"},
        {"mythical_equip",
            fun([State|_]) ->
                CreateList = [#p_goods{type_id = TypeID, num = Num} ||
                    {TypeID, Num} <- [{21060301, 1}, {22060301, 1}, {23060301, 1}, {24060301, 1}, {25060301, 1}]],
                role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList)
            end, "创建粉色兽魂道具"},
        {"mythical_all_equip",
            fun([State|_]) ->
                CreateList = [#p_goods{type_id = TypeID, num = 1} ||
                    {TypeID, _Config} <- cfg_mythical_equip_info:list()],
                role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList)
            end, "创建所有兽魂道具"},
        {"war_spirit_equip",
            fun([State|_]) ->
                CreateList = [#p_goods{type_id = TypeID, num = Num} ||
                    {TypeID, Num} <- [{50010105, 1}, {50010205, 1}, {50010305, 1}, {50010405, 1}]],
                role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList)
            end, "创建粉色灵饰道具"},
        {"war_spirit_all_equip",
            fun([State|_]) ->
                CreateList = [#p_goods{type_id = TypeID, num = 1} ||
                    {TypeID, _Config} <- cfg_war_spirit_equip_info:list()],
                role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList)
            end, "创建所有灵饰道具"},
        {"war_spirit_refine_exp",
            fun([State, AddNum|_]) ->
                mod_role_confine:gm_add_war_spirit_refine_exp(AddNum, State)
            end, "增加灵饰经验"},
        {"war_god_item",
            fun([State|_]) ->
                GoodsList = [#p_goods{type_id = TypeID, num = 20} || {TypeID, #c_item{effect_type = ?ITEM_WAR_GOD_PIECE}} <- lib_config:list(cfg_item)],
                role_misc:create_goods(State, ?ITEM_GAIN_GM, GoodsList)
            end, "增加战神碎片"},
        {"activity_stop",
            fun([State, ID|Remain]) ->
                world_activity_server:info({gm_stop, ID, Remain}),
                catch cross_activity_server:info({gm_stop, ID, Remain}),
                State
            end, "活动开始"},
        {"act_start",
            fun([State, ID|_Remain]) ->
                case ID >= 2000 of
                    false ->
                        world_act_server:info({gm_start, ID});
                    _ ->
                        world_cycle_act_server:info({gm_start, ID})
                end,
                State
            end, "运营活动开启"},
        {"act_stop",
            fun([State, ID|_Remain]) ->
                case ID >= 2000 of
                    false ->
                        world_act_server:info({gm_stop, ID});
                    _ ->
                        world_cycle_act_server:info({gm_stop, ID})
                end,
                State
            end, "运营活动结束"},
        {"act_end_time",
            fun([State, EndTime]) ->
                world_act_server:info({gm_end_time, EndTime}),
                State
            end, "运营活动结束"},
        {"zs1",
            fun([State|_Remain]) ->
                State2 = mod_role_relive:gm_set_relive_level(3, 0, State),
                State3 = mod_role_copy:gm_set_copy_tower(40006, State2),
                State3
            end, "组合命令"},
        {"fb1",
            fun([State|_Remain]) ->
                world_activity_server:info({gm_start, 10007, 5}),
                RoleID = State#r_role.role_id,
                State2 = mod_role_family:handle({#m_family_boss_tos{}, RoleID, erlang:self()}, State),
                State2
            end, "组合命令"},
        {"overdue_item",
            fun([State, Val1|_Val2]) ->
                mod_role_item:gm_overdue_item(Val1, State)
            end, "使物品过期"},
        {"overdue_guard",
            fun([State, Num1, Num2|_Val2]) ->
                mod_role_guard:gm_overdue_guard(State, Num1, Num2)
            end, "使物品过期"},
        {"reset_fairy",
            fun([State, Val|_Val2]) ->
                mod_role_escort:gm_reset(State, Val)
            end, "reset_fairy"},
        {"act_sign_active",
            fun([State|_]) ->
                mod_role_act_seven:gm_act_sign_active(State)
            end, "act_sign_reset"},
        {"act_sign_reset",
            fun([State|_]) ->
                State2 = mod_role_act_sign:day_reset(State),
                mod_role_act_sign:online(State2)
            end, "act_sign_reset"},
        {"invest_reset",
            fun([State|_]) ->
                State2 = mod_role_invest:day_reset(State),
                mod_role_invest:online(State2)
            end, "invest_reset"},
        {"gm_red_packget",
            fun([State, Num|_]) ->
                mod_family_red_packet:gm_add_red_packet(State, Num),
                State
            end, "get_monster_data"},
        {"set_gc_id",
            fun([State, Num|_]) ->
                mod_role_act:gm_set_game_channel_id(State, Num)
            end, "set_gc_id"},
        {"dl_reset",
            fun([State|_]) ->
                mod_role_daily_liveness:day_reset(State)
            end, "dl_reset"},
        {"clw_reset",
            fun([State|_]) ->
                world_act_server:info({func, act_clword, init, []}),
                mod_role_act_clword:day_reset(State)
            end, "dl_reset"},
        {"speed",
            fun([State, Num, Type|_]) ->
                mod_role_mount:gm_set_seed(State, Num, Type)
            end, "dl_reset"},
        {"guide_exp",
            fun([State, FinishTimes, EnterTimes|_]) ->
                mod_role_copy:gm_guide_exp(FinishTimes, EnterTimes, State)
            end, "dl_reset"},
        {"refresh_family_bt_rank",
            fun([State|_]) ->
                mod_family_battle:gm_refresh_list(),
                State
            end, "refresh_family_bt_rank"},
        {"up_market",
            fun([State, Num|_]) ->
                mod_role_market:gm_up_market(State, Num)
            end, "up_market"},
        {"reset_family_bt",
            fun([State, Num|_]) ->
                mod_role_family_bt:gm_reset_family_bt(State, Num)
            end, "reset_family_bt"},
        {"role_prop",
            fun([State, Key, Value|_]) ->
                PropList = mod_role_extra:get_data(?EXTRA_KEY_GM_PROPS, [], State),
                PropList2 = lists:keystore(Key, #p_kv.id, PropList, #p_kv{id = Key, val = Value}),
                State2 = mod_role_extra:set_data(?EXTRA_KEY_GM_PROPS, PropList2, State),
                mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_EQUIP_GM_PROP, Key)
            end, "设置属性"},
        {"family_td_succ",
            fun([State|_]) ->
                mod_map_family_td:gm_succ(State#r_role.role_attr#r_role_attr.family_id),
                State
            end, "reset_family_bt"},
        {"set_family_title",
            fun([State, Num|_]) ->
                wzp_gm_test:gm_set_family_title(State#r_role.role_id, State#r_role.role_attr#r_role_attr.family_id, Num),
                State
            end, "reset_family_bt"},
        {"set_fot",  %%自己仙盟盟主离线时间
            fun([State|_]) ->
                wzp_gm_test:gm_set_family_last_offline_time(State#r_role.role_attr#r_role_attr.family_id, 0),
                State
            end, "set_fot"},
        {"family_hour",  %%
            fun([State|_]) ->
                hook_family:loop_integer_hour(),
                State
            end, "family_hour"},
        {"reset_world_level",
            fun([State, Num|_]) ->
                ?IF(erlang:is_integer(Num), ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
                world_data:set_world_level(Num),
                ?IF(Num >= ?WORLD_LEVEL_OPEN_LV, common_broadcast:bc_role_info_to_world({mod, mod_role_world_level, update_world_level}), ok),
                State
            end, "reset_world_level"},
        {"reset_xianhun",
            fun([State|_]) ->
                mod_role_immortal_soul:gm_reset_immortal_soul(State)
            end, "reset_xianhun"},
        {"set_round",
            fun([State, Round|_]) ->
                act_limited_time_buy:gm_set_round(Round),
                State
            end, "set_round"},
        {"set_trench",
            fun([State|_]) ->
                act_trench_ceremony:gm_set_first_trench_ceremony(),
                State
            end, "set_trench"},
        {"xianhun",
            fun([State|_]) ->
                mod_role_immortal_soul:gm_print_all_color(State)
            end, "reset_xianhun"},
        {"god99",
            fun([State|_]) ->
                RoleID = State#r_role.role_id,
                AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_GM, 100000, 100000}, {add_silver, ?ASSET_SILVER_ADD_FROM_GM, 10000000}],
                BagDoing = [{create, ?ITEM_GAIN_GM, [#p_goods{type_id = 20000, num = 1, bind = false}]}],
                State2 = mod_role_bag:do(BagDoing, mod_role_asset:do(AssetDoing, State)),
                BuffList = [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || BuffID <- ?GOD_BUFF],
                role_misc:add_buff(RoleID, BuffList),
                RoleLevel = 99,
                State3 = mod_role_level:gm_set_level(RoleLevel, State2),
                State4 = mod_role_vip:gm_set_vip(5, State3),
                mod_role_function:gm_trigger_function(State4)
            end, "god99"
        },
        {"t",
         fun([State, ID|_]) ->
             [Config] = lib_config:find(cfg_tester, ID),
             Goods2 = lists:foldl(
                   fun(TypeID, Goods) ->
                       [#p_goods{type_id = TypeID, num = 1, bind = false}|Goods]
                   end
                 , [], Config#c_tester.list
             ),
             role_misc:create_goods(State, ?ITEM_GAIN_GM, Goods2)
         end,
         "测试专用"},
        {"confine",
            fun([State, Num, Num2|_]) ->
                mod_role_confine:gm_set_confine(State, Num, Num2)
            end, "confine"
        },
        {"zhanling",
            fun([State, Num|_]) ->
                mod_role_confine:gm_war_spirit(State, Num)
            end, "zhanling"},
        {"djrw",
            fun([State, Num|_]) ->
                mod_role_confine:gm_add_mission(State, Num)
            end, "djrw,801001"},
        {"qe_copy",
            fun([State|_]) ->
                mod_role_copy:gm_set_copy_time(4, State)
            end, "设置副本结束时间"},
        {"bless",
            fun([State, Times1, Times2|_]) ->
                mod_role_bless:gm_set(State, Times1, Times2)
            end, "设置祈福剩余次数"},
        {"wzpt1",
            fun([State|_]) ->
                mod_role_guard:activate_king_guard(State)
%%             wzp_gm_test:test_get_weight_output(Times1,State)
            end, "设置祈福剩余次数"},
        {"set_ei",
            fun([State, Times|_]) ->
                mod_role_bg_act_mission:gm_set_money(State, Times)
            end, "设置祈福剩余次数"},
        {"get_monster_data",
            fun([State|_]) ->
                map_misc:info(mod_role_dict:get_map_pid(), {func, fun() ->
                    mod_map_monster:gm_all_monster() end}),
                State
            end, "get_monster_data"},
        {"add_mana",
            fun([State, Num|_]) ->
%%                mod_role_act_os_second:gm_add_mana(State,Num)
                mod_role_act_otf:gm_add_score(State, Num)
            end, "增加开服二阶冲榜灵力"},
        {"act_oss_refresh",
            fun([State|_]) ->
                State
            end, "act_hour "},
        {"oss_rank",
            fun([State|_]) ->
                act_oss:gm_refresh_rank(),
                State
            end, "act_hour "},
        {"kill_boss",
            fun([State, TypeID|_]) ->
                hook_role:kill_world_boss(TypeID, State)
            end, "act_hour "},
        {"rank_all",
            fun([State|_]) ->
                rank_server:gm_all_rank(),
                State
            end, "rank_all "},
        {"world_level_exp",
            fun([State, Bool|_]) ->
                IsAdd = Bool =:= ?TRUE,
                State2 = mod_role_extra:set_data(?EXTRA_KEY_WORLD_LEVEL_ADD, IsAdd, State),
                mod_role_world_level:update_attr(State2)
            end, "world_level_exp "},
        {"act_red_packet",
            fun([State, Hour|_]) ->
                act_red_packet:gm_send_red_packet(Hour),
                State
            end, "act_red_packet "},
        {"team_guide_match",
            fun([State|_]) ->
                mod_team_request:leave_team(State#r_role.role_id),
                mod_team_match:role_robot_match(State#r_role.role_id),
                State
            end, "team_guide_match "},
        {"copy_exp_succ",
            fun([State|_]) ->
                mod_role_copy:gm_copy_exp(State)
            end, "一键完成经验副本 "},
        {"handbook_goods",
            fun([State|_]) ->
                CreateList = [#p_goods{type_id = TypeID, num = Num} ||
                    {TypeID, Num} <- [{1001, 10}, {1002, 10}, {1003, 10}, {1004, 10}, {1005, 10}, {1006, 10}, {1007, 10}, {1008, 10}, {1009, 10},
                                      {1010, 10}, {1011, 10}, {1012, 10}, {1013, 10}, {1014, 10}, {1015, 10}, {1016, 10}, {1017, 10}, {1018, 10}, {1019, 10},
                                      {1020, 10}, {1021, 10}, {1022, 10}, {1023, 10}, {1024, 10}, {1025, 10}, {1026, 10}, {1027, 10}, {1028, 10}, {1029, 10},
                                      {1030, 10}, {1031, 10}, {1101, 10}, {1102, 10}, {1103, 10}, {1104, 10}]],
                role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList)
            end, "创建图鉴需要道具"},
        {"set_template_role",
            fun([State|_]) ->
                erlang:spawn(fun() -> common_shell:set_template_role(State#r_role.role_id) end),
                State
            end, "设置模板角色"},
        {"huntboss",
            fun([State|_]) ->
                mod_role_act_hunt_boss:gm(State)
            end, "加猎杀BOSS积分"},
        {"wzp30",
            fun([State|_]) ->
                ets:delete_all_objects(?ETS_FAMILY_GOD_BEAST_RANK_A),
                ets:delete_all_objects(?ETS_FAMILY_GOD_BEAST_RANK_B),
                world_data:set_fgb(1),
                mod_role_fgb:do_get_info(State#r_role.role_id, State)
            end, "加猎杀BOSS积分"},
        {"wzp2",
            fun([State|_]) ->
                mod_role_confine:gm_set_mission(State)
            end, "加猎杀BOSS积分"},
        {"wzp4",
            fun([State|_]) ->
                mod_role_confine:gm_up_confine(State)
            end, "加猎杀BOSS积分"},
        {"wzp5",
            fun([State|_]) ->
                mod_role_confine:get_mission_by_confine(State)
            end, "再次获得本境界任务"},
%%        {"wzp3",
%%            fun([State|_]) ->
%%                State2 = mod_role_shop:day_reset(State),
%%                mod_role_shop:zero(State2)
%%            end, "加猎杀BOSS积分"},
        {"wzp3",
            fun([State|_]) ->
                MapID = 90021,
                {OffsetMx, OffsetMy} = map_misc:get_offset_meter_by_map_id(90021, 285, 106),
                StringPos = lib_tool:to_list(MapID) ++ "_" ++ lib_tool:to_list(OffsetMx) ++ "_" ++ lib_tool:to_list(OffsetMy),
                StringList = ["RoleName", " MapName", "BossName", "SrcName", StringPos],
                common_broadcast:send_family_common_notice(200100003, 1102, StringList),
                State
            end, "加猎杀BOSS积分"},
        {"turntable",
            fun([State, Num1, Num2|_]) ->
                mod_role_bg_turntable:gm_add_draw_times(State, Num1, Num2)
            end, "转盘"},
        {"open_family_auto",
            fun([State|_]) ->
                world_data:set_automatic_family_key(true),
                State
            end, "转盘"},
        {"family_change_type",
            fun([State, MissionID|_]) ->
                mod_role_family_asm:gm_change_task_type(MissionID, State)
            end, "任务的状态改成待领奖状态(减少时间)"},
        {"family_nonsuch_time",
            fun([State|_]) ->
                mod_role_family_asm:gm_nonsuch_time(State)
            end, "增加道庭任务的极品刷新"},
        {"cq",
            fun([State, Times|_]) ->
                ?IF(Times > 100000, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
                [
                    begin
                        family_server:add_box(?GLOBAL_FAMILY_BOX_PAY, 6, State#r_role.role_attr#r_role_attr.family_id, State#r_role.role_id),
                        Id
                    end
                    || Id <- lists:seq(1, Times)],
                State
            end, "da"},
        {"help",
            fun([State|_]) ->
                BcInfo = #m_common_notice_toc{id = ?NOTICE_ESCORT_ASK_FOR_HELP, text_string = ["1111", lib_tool:to_list(State#r_role.role_id)]},
                common_broadcast:bc_record_to_family(State#r_role.role_attr#r_role_attr.family_id, BcInfo),
                State
            end, "da"},
        {"log",
            fun([#r_role{role_id = RoleID, role_attr = RoleAttr} = State, Type|_]) ->
                case Type of
                    1 ->
                        PLog = #p_escort_log{type = ?ESCORT_LOG_START, text = [family_escort_server:log_time_text(), "挖人地"]};
                    6 ->
                        PLog = #p_escort_log{type = ?ESCORT_LOG_END, text = [family_escort_server:log_time_text()]};
                    7 ->
                        PLog = #p_escort_log{type = ?ESCORT_LOG_ROB_SUC, text = [family_escort_server:log_time_text(), "咸鱼王", lib_tool:to_list(RoleID), lib_tool:to_list(RoleID)]};
                    8 ->
                        PLog = #p_escort_log{type = ?ESCORT_LOG_ROB_FAIL, text = [family_escort_server:log_time_text(), "咸鱼王", lib_tool:to_list(RoleID)]};
                    9 ->
                        PLog = #p_escort_log{type = ?ESCORT_LOG_ROB_FAIL, text = [family_escort_server:log_time_text(), "咸鱼王", lib_tool:to_list(RoleID), "咸鱼王1"]};
                    10 ->
                        PLog = #p_escort_log{type = ?ESCORT_LOG_ROB_FAIL, text = [family_escort_server:log_time_text(), "咸鱼王"]};
                    11 ->
                        PLog = #p_escort_log{type = ?ESCORT_LOG_ROB_FAIL, text = [family_escort_server:log_time_text(), "咸鱼王"]},
                        BcInfo = #m_common_notice_toc{id = ?NOTICE_ESCORT_ASK_FOR_HELP, text_string = ["21221", lib_tool:to_list(RoleID), lib_tool:to_list(RoleID)]},
                        common_broadcast:bc_record_to_family(RoleAttr#r_role_attr.family_id, BcInfo)
                end,
                common_misc:unicast(State#r_role.role_id, #m_role_escort_log_toc{log_list = PLog}),
                State
            end, "da"},
        {"king_guard_letter",
            fun([State|_]) ->
                LetterInfo = #r_letter_info{
                    condition = #r_gm_condition{min_level = 150},
                    template_id = ?LETTER_TEMPLATE_KING_GUARD},
                common_letter:send_letter(?GM_MAIL_ID, LetterInfo),
                State
            end, "king_guard_letter)"},
        {"add_type_nature",
            fun([State, Type|_]) ->
                mod_role_nature:gm_nature_hole(Type, State)
            end, "开启孔)"},
        {"fulfil_esoterica_task",
            fun([State, MissionID, Times|_]) ->
                State2 = mod_role_act_esoterica:gm_add_gather_task(MissionID, Times, State),
                State2
            end, "任务次数"},
        {"del_nature",
            fun([State|_]) ->
                mod_role_nature:gm_del_nature(State)
            end, "清空)"},
        {"family_money_add",
            fun([State, Num, Num2|_]) ->
                mod_role_family:gm_family_money_add(State, Num, Num2)
            end, "清空)"},
        {"family_red_packet",
            fun([State, Type, Amount, Content, Piece|_]) ->
                mod_role_family:do_family_give_red_packet(State#r_role.role_id, Type, Amount, Content, Piece, State)
            end, "清空)"},
        {"djrp",
            fun([State|_]) ->
                mod_role_confine:update_confine_status(State#r_role.role_id)
            end, "清空)"},
        {"gm_escort",
            fun([State|_]) ->
                mod_role_escort:gm_escort(State)
            end, "清空)"},

        {"medicine_reduce_time",
            fun([State, GoodsID|_]) ->
                mod_role_pellet_medicine:gm_reduce_time(GoodsID, State)
            end, "减少时间"},
        {"family_del_task",
            fun([State|_]) ->
                mod_family_asm:call_del_role_info(State#r_role.role_attr#r_role_attr.role_id)
            end, "放弃所有任务,12点后的会重新获取一次极品刷新"},
        {"mining_reduce_time",
            fun([State|_]) ->
                world_mining_server:gm_reduce_time(State#r_role.role_id),
                State
            end, "减少时间"},
        {"mining_change_seat",
            fun([State|_]) ->
                world_mining_server:gm_change_seat(State#r_role.role_id),
                State
            end, "在九宫格增加玩家"},
        {"mining_add_plunder",
            fun([State|_]) ->
                world_mining_server:gm_add_plunder(State#r_role.role_id),
                State
            end, "增加被掠夺历史"},
        {"mining_add_shift",
            fun([State, Num|_]) ->
                world_mining_server:gm_add_shift(State#r_role.role_id, Num),
                State
            end, "增加被掠夺历史"},
        {"liandan",
            fun([State, Num1, Num2|_]) ->
                mod_role_bg_new_alchemy:gm_add_times(State, Num1, Num2)
            end, "炼丹"},
        {"bless_time_add",
            fun([State, Num1|_]) ->
                mod_role_bless:gm_time_add(State, Num1)
            end, "炼丹"},
        {"solo_season_start",
            fun([State|_]) ->
                mod_solo:send_server_solo_gm_season_start(),
                State
            end, "lvl赛季开启"},
        {"solo_season_stop",
            fun([State|_]) ->
                mod_solo:send_server_solo_gm_season_stop(),
                State
            end, "lvl赛季结束"},
        {"cycle_tower_set",
            fun([State, Layer, Pool|_]) ->
                mod_role_cycle_act_misc:gm_tower_set(State, Layer, Pool)
            end, ""},
        {"cycle_mission",
            fun([State, Money|_]) ->
                mod_role_cycle_mission:gm_set_money(State, Money)
            end, ""},
        {"qq",
            fun([State, Num|_]) ->
                case Num =:= 1 of
                    true ->
                        mod_role_addict:update_imei_time(State, time_tool:now());
                    _ ->
                        mod_role_addict:get_imei_time(State, time_tool:now())
                end,
                State
            end, ""},
        {"escort_cross",
            fun([State|_]) ->
                world_data:set_world_level(500),
                family_escort_server:info(zeroclock),
                State
            end, "炼丹"}
    ].

trim_space(String) ->
    [Value || Value <- String, Value > 32].


bag_decrease_goods(State, []) ->
    State;
bag_decrease_goods(State, [TypeID, Num|T]) ->
    DecreaseList = [#r_goods_decrease_info{type_id = TypeID, num = Num}],
    State2 = mod_role_bag:do([{decrease, ?ITEM_REDUCE_GM, DecreaseList}], State),
    bag_decrease_goods(State2, T);
bag_decrease_goods(State, [_TypeID|_T]) ->
    State.
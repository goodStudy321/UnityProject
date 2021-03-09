%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     婚礼 -- 定亲
%%% @end
%%% Created : 04. 十二月 2018 16:03
%%%-------------------------------------------------------------------
-module(mod_marry_propose).
-author("laijichang").
-include("marry.hrl").
-include("global.hrl").
-include("proto/mod_role_marry.hrl").
-include("proto/mod_marry_propose.hrl").

%% API
-export([
    propose/3,
    propose_reply/3
]).

-export([
    init/0,
    loop/1,
    handle/1
]).

propose(RoleID, ProposeID, Type) ->
    marry_server:call_mod(?MODULE, {propose, RoleID, ProposeID, Type}).

propose_reply(RoleID, SrcRoleID, AnswerType) ->
    marry_server:info_mod(?MODULE, {propose_reply, RoleID, SrcRoleID, AnswerType}).

init() ->
    AllMarryData = mod_marry_data:get_all_marry_data(),
    RoleIDs = get_loop_propose_ids(AllMarryData, []),
    mod_marry_data:set_loop_propose(RoleIDs).

get_loop_propose_ids([], RolesAcc) ->
    RolesAcc;
get_loop_propose_ids([#r_marry_data{role_id = RoleID, propose_id = ProposeID}|R], RolesAcc) ->
    RolesAcc2 = ?IF(?HAS_PROPOSE(ProposeID), [RoleID|RolesAcc], RolesAcc),
    get_loop_propose_ids(R, RolesAcc2).

loop(Now) ->
    LoopRoleIDs = mod_marry_data:get_loop_propose(),
    [begin
         #r_marry_data{propose_id = ProposeID, propose_end_time = EndTime} = MarryData = mod_marry_data:get_marry_data(RoleID),
         case Now >= EndTime of
             true ->
                 ProposeMarryData = mod_marry_data:get_marry_data(ProposeID),
                 do_propose_refuse(MarryData, ProposeMarryData, ?LETTER_TEMPLATE_PROPOSE_TIMEOUT),
                 ok;
             _ ->
                 ok
         end
     end|| RoleID <- LoopRoleIDs],
    ok.


handle({propose, RoleID, ProposeID, Type}) ->
    do_propose(RoleID, ProposeID, Type);
handle({propose_reply, RoleID, SrcRoleID, AnswerType}) ->
    do_propose_reply(RoleID, SrcRoleID, AnswerType);
handle({#m_marry_divorce_tos{}, RoleID, _PID}) ->
    do_divorce(RoleID);
handle(Info) ->
    ?ERROR_MSG("unknow Info : ~w", [Info]).

do_propose(RoleID, ProposeID, Type) ->
    case catch check_propose(RoleID, ProposeID, Type) of
        {ok, SrcMarryData, DestMarryData, ProposeEndTime} ->
            mod_marry_data:set_marry_data(SrcMarryData),
            mod_marry_data:set_marry_data(DestMarryData),
            mod_marry_data:add_loop_propose(RoleID),
            {ok, ProposeEndTime};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_propose(SrcRoleID, DestRoleID, Type) ->
    SrcMarryData = mod_marry_data:get_marry_data(SrcRoleID),
    DestMarryData = mod_marry_data:get_marry_data(DestRoleID),
    #r_marry_data{
        couple_id = CoupleID1,
        propose_id = ProPoseID1,
        be_propose_list = BeProposeList1
    } = SrcMarryData,
    #r_marry_data{
        couple_id = CoupleID2,
        propose_id = ProPoseID2,
        be_propose_list = BeProposeList2
    } = DestMarryData,
%%    [#c_marry_propose{
%%        need_friendly = NeedFriendlyT
%%        %% guild_need_friendly = GuildNeedFriendly
%%    }] = lib_config:find(cfg_marry_propose, Type),
    %% NeedFriendly = ?IF(common_pf:is_agent_guild(), GuildNeedFriendly, NeedFriendlyT),
%%    ?IF(world_friend_server:is_couple_friendly(SrcRoleID, DestRoleID, NeedFriendlyT), ok, ?THROW_ERR(?ERROR_MARRY_PROPOSE_008)),
    ?IF(ProPoseID1 > 0, ?THROW_ERR(?ERROR_MARRY_PROPOSE_003), ok),
    ?IF(BeProposeList1 =/= [], ?THROW_ERR(?ERROR_MARRY_PROPOSE_004), ok),
    ?IF(ProPoseID2 > 0, ?THROW_ERR(?ERROR_MARRY_PROPOSE_005), ok),
    if
        CoupleID1 =:= DestRoleID andalso CoupleID2 =:= SrcRoleID ->
            ok;
        CoupleID1 > 0 ->
            ?THROW_ERR(?ERROR_MARRY_PROPOSE_006);
        CoupleID2 > 0 ->
            ?THROW_ERR(?ERROR_MARRY_PROPOSE_007);
        true ->
            ok
    end,
    ProposeEndTime = time_tool:now() + ?MARRY_PROPOSE_END_TIME,
    SrcMarryData2 = SrcMarryData#r_marry_data{
        propose_id = DestRoleID,
        propose_type = Type,
        propose_end_time = ProposeEndTime
    },
    DestMarryData2 = DestMarryData#r_marry_data{be_propose_list = [SrcRoleID|BeProposeList2]},
    {ok, SrcMarryData2, DestMarryData2, ProposeEndTime}.

%% 提亲回复
do_propose_reply(RoleID, SrcRoleID, AnswerType) ->
    case catch check_propose_reply(RoleID, SrcRoleID, AnswerType) of
        {ok, ?MARRY_PROPOSE_ACCEPT, SrcMarryData, DestMarryData} ->
            do_propose_accept(SrcMarryData, DestMarryData);
        {ok, ?MARRY_PROPOSE_REFUSE, SrcMarryData, DestMarryData} ->
            do_propose_refuse(SrcMarryData, DestMarryData, ?LETTER_TEMPLATE_PROPOSE_FAILED);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_propose_reply_toc{err_code = ErrCode})
    end.

check_propose_reply(RoleID, SrcRoleID, AnswerType) ->
    #r_marry_data{couple_id = SrcCoupleID, propose_id = ProposeID, propose_end_time = EndTime} = SrcMarryData = mod_marry_data:get_marry_data(SrcRoleID),
    #r_marry_data{couple_id = DestCoupleID} = DestMarryData = mod_marry_data:get_marry_data(RoleID),
    ?IF(time_tool:now() >= EndTime, ?THROW_ERR(?ERROR_MARRY_PROPOSE_REPLY_001), ok),
    ?IF(ProposeID =:= RoleID, ok, ?THROW_ERR(?ERROR_MARRY_PROPOSE_REPLY_002)),
    if
        SrcCoupleID =:= RoleID andalso DestCoupleID =:= SrcRoleID ->
            ok;
        SrcCoupleID > 0 ->
            ?THROW_ERR(?ERROR_MARRY_PROPOSE_REPLY_003);
        DestCoupleID > 0 ->
            ?THROW_ERR(?ERROR_MARRY_PROPOSE_REPLY_004);
        true ->
            ok
    end,
    {ok, AnswerType, SrcMarryData, DestMarryData}.


do_propose_accept(SrcMarryData, DestMarryData) ->
    #r_marry_data{role_id = SrcRoleID, propose_type = ProposeType} = SrcMarryData,
    #r_marry_data{role_id = DestRoleID, be_propose_list = BeProposeList} = DestMarryData,
    SrcMarryData2 = SrcMarryData#r_marry_data{
        couple_id = DestRoleID,
        propose_id = 0,
        propose_type = 0,
        propose_end_time = 0},
    BeProposeList2 = lists:delete(SrcRoleID, BeProposeList),
    DestMarryData2 = DestMarryData#r_marry_data{couple_id = SrcRoleID, be_propose_list = BeProposeList2},
    mod_marry_data:set_marry_data(SrcMarryData2),
    mod_marry_data:set_marry_data(DestMarryData2),
    mod_marry_data:del_loop_propose(SrcRoleID),
    [#c_marry_propose{
        title_id = TitleID,
        reward = Reward,
        add_feast_times = AddFeastTimes
    }] = lib_config:find(cfg_marry_propose, ProposeType),
    ShareID = marry_misc:get_share_id(SrcRoleID, DestRoleID),
    #r_marry_share{feast_times = FeastTimes, marry_time = MarryTime} = ShareMarry = mod_marry_data:get_share_marry(ShareID),
    FeastTimes2 = FeastTimes + AddFeastTimes,
    MarryTime2 = ?IF(MarryTime > 0, MarryTime, time_tool:now()),
    ShareMarry2 = ShareMarry#r_marry_share{feast_times = FeastTimes2, marry_time = MarryTime2},
    mod_marry_data:set_share_marry(ShareMarry2),
    GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(Reward)],
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_TEMPLATE_PROPOSE_SUCC,
        action = ?ITEM_GAIN_MARRY_PROPOSE_SUCC,
        goods_list = GoodsList
    },
    #r_role_attr{role_name = SrcName} = common_role_data:get_role_attr(SrcRoleID),
    #r_role_attr{role_name = DestName} = common_role_data:get_role_attr(DestRoleID),
    do_propose_accept2(SrcRoleID, DestRoleID, DestName, TitleID, LetterInfo, ProposeType, FeastTimes2, MarryTime2),
    do_propose_accept2(DestRoleID, SrcRoleID, SrcName, TitleID, LetterInfo, ProposeType, FeastTimes2, MarryTime2),
    %% 拒绝其他人的提亲
    [ begin
          OtherMarryData = mod_marry_data:get_marry_data(OtherRoleID),
          %% 拒绝了之后数据会改变，所以这里重新get
          RefuseMarryData = mod_marry_data:get_marry_data(DestRoleID),
          do_propose_refuse(OtherMarryData, RefuseMarryData, ?LETTER_TEMPLATE_PROPOSE_FAILED)
      end || OtherRoleID <- BeProposeList2],
    ?TRY_CATCH(marry_misc:log_marry_status(ShareMarry2, ?LOG_MARRY_PROPOSE_SUCC, ProposeType)),
    common_broadcast:send_world_common_notice(?NOTICE_MARRY_SUCC, [SrcName, DestName]).

do_propose_accept2(RoleID, CoupleID, CoupleName, TitleID, LetterInfo, ProposeType, FeastTimes2, MarryTime2) ->
    common_letter:send_letter(RoleID, LetterInfo#r_letter_info{text_string = [CoupleName]}),
    mod_role_title:update_title(TitleID, ?ADD_TITLE, RoleID),
    DataRecord = #m_marry_propose_succ_toc{
        couple_id = CoupleID,
        couple_name = CoupleName,
        type = ProposeType,
        feast_times = FeastTimes2,
        marry_time = MarryTime2
    },
    common_misc:unicast(RoleID, DataRecord),
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, mod_role_marry, {get_marry, CoupleID, CoupleName, ProposeType}});
        _ ->
            world_offline_event_server:add_event(RoleID, {role_misc, info_role, [RoleID, {mod, mod_role_marry, {offline_propose_accept, ProposeType}}]})
    end.

do_propose_refuse(SrcMarryData, DestMarryData, TemplateID) ->
    #r_marry_data{role_id = SrcRoleID, propose_type = ProposeType} = SrcMarryData,
    #r_marry_data{role_id = DestRoleID, be_propose_list = BeProposeList} = DestMarryData,
    SrcMarryData2 = SrcMarryData#r_marry_data{propose_id = 0, propose_type = 0, propose_end_time = 0},
    DestMarryData2 = DestMarryData#r_marry_data{be_propose_list = lists:delete(SrcRoleID, BeProposeList)},
    mod_marry_data:set_marry_data(SrcMarryData2),
    mod_marry_data:set_marry_data(DestMarryData2),
    mod_marry_data:del_loop_propose(SrcRoleID),

    [#c_marry_propose{consume_type = ConsumeType, consume_fee = ConsumeFee}] = lib_config:find(cfg_marry_propose, ProposeType),
    TypeID = ?IF(ConsumeType =:= ?CONSUME_UNBIND_GOLD, ?ITEM_GOLD, ?ITEM_BIND_GOLD),
    LetterInfo = #r_letter_info{
        template_id = TemplateID,
        action = ?ITEM_GAIN_MARRY_PROPOSE_REFUSE,
        goods_list = [#p_goods{type_id = TypeID, num = ConsumeFee}],
        text_string = [common_role_data:get_role_name(DestRoleID)]
    },
    common_letter:send_letter(SrcRoleID, LetterInfo),
    DataRecord = #m_marry_propose_reply_toc{answer_type = ?MARRY_PROPOSE_REFUSE},
    common_misc:unicast(DestRoleID, DataRecord),
    DataRecord2 = #m_marry_propose_reply_toc{err_code = ?ERROR_MARRY_PROPOSE_REPLY_005},
    common_misc:unicast(SrcRoleID, DataRecord2).

%% 离婚
do_divorce(RoleID) ->
    case catch check_divorce(RoleID) of
        {ok, DestRoleID} ->
            mod_marry_data:del_share_marry(marry_misc:get_share_id(RoleID, DestRoleID)),
            do_divorce2(RoleID, DestRoleID),
            do_divorce2(DestRoleID, RoleID),
            ok;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_marry_divorce_toc{err_code = ErrCode})
    end.

do_divorce2(RoleID, DestRoleID) ->
    common_misc:unicast(RoleID, #m_marry_divorce_toc{}),
    mod_marry_data:del_marry_data(RoleID),
    LetterInfo = #r_letter_info{template_id = ?LETTER_TEMPLATE_MARRY_DIVORCE},
    common_letter:send_letter(RoleID, LetterInfo#r_letter_info{text_string = [common_role_data:get_role_name(DestRoleID)]}),
    role_misc:info_role(RoleID, {mod, mod_role_marry, divorce}).

check_divorce(RoleID) ->
    #r_marry_data{
        couple_id = CoupleID,
        propose_id = ProposeID,
        be_propose_list = BeProposeList} = mod_marry_data:get_marry_data(RoleID),
    ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_MARRY_DIVORCE_001)),
    ?IF(ProposeID > 0 orelse BeProposeList =/= [], ?THROW_ERR(?ERROR_MARRY_DIVORCE_002), ok),
    ShareID = marry_misc:get_share_id(RoleID, CoupleID),
    #r_marry_share{feast_start_time = FeastStartTime} = mod_marry_data:get_share_marry(ShareID),
    ?IF(marry_misc:is_feast_over(FeastStartTime), ok, ?THROW_ERR(?ERROR_MARRY_DIVORCE_003)),
    {ok, CoupleID}.

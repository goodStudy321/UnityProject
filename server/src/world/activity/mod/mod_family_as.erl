%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 四月 2018 11:21
%%%-------------------------------------------------------------------
-module(mod_family_as).
-author("WZP").

-include("global.hrl").
-include("map.hrl").
-include("activity.hrl").
-include("common.hrl").
-include("common_records.hrl").
-include("proto/mod_role_map.hrl").
-include("family_as.hrl").
-include("letter_template.hrl").
-include("all_pb.hrl").
-include("family.hrl").
-include("red_packet.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_family_as.hrl").

%% API
-export([
    activity_prepare/0,
    activity_start/0,
    activity_end/0,
    loop/1,
    handle/1
]).



activity_prepare() ->
    List = mod_family_data:get_all_family(),
    {MapPidS2, PNList2} = lists:foldl(
        fun(#p_family{family_id = FamilyID, family_name = FamilyName}, {MapPidS, PNList}) ->
            {ok, Pid} = start_map(FamilyID),
            {[Pid|MapPidS], [{Pid, FamilyName}|PNList]}
        end, {[], []}, List),
    set_family_as_maps(MapPidS2),
    Questions = init_question(),
    lib_tool:init_ets(?ETS_FAMILY_AS_RANK, #r_family_as_rank.family_id),
    lib_tool:init_ets(?ETS_FAMILY_AS_EXP, #r_family_as_exp.role_id),
    [pname_server:send(Pid, {mod, mod_map_family_as, {send_question, Questions, FName}}) || {Pid, FName} <- PNList2],
    ok.


activity_start() ->
    MapPidS = get_family_as_maps(),
    Now = time_tool:now(),
    [pname_server:send(Pid, {mod, mod_map_family_as, {start, Now}}) || Pid <- MapPidS],
    set_rank_time(Now + ?FAMILY_AS_RANK_INTERVAL + ?FAMILY_AS_RANK_START_DELAY).

activity_end() ->
    {RankList, _} = do_rank(),
    do_send_reward(RankList),
    ets:delete(?ETS_FAMILY_AS_RANK),
    ets:delete(?ETS_FAMILY_AS_EXP),
    MapPidS = get_family_as_maps(),
    [mod_map_family_as:activity_end(MapPid) || MapPid <- MapPidS],
    log_family_answer(RankList),
    do_family_answer_broadcast(RankList).



loop(Now) ->
    Time = get_rank_time(),
    if
        Now >= Time ->
            {RankList, RankInfoList} = do_rank(),
            MapPidS = get_family_as_maps(),
            lists:foreach(
                fun(Pid) ->
                    pname_server:send(Pid, {mod, mod_map_family_as, {rank_info, RankInfoList}})
                end, MapPidS),
            lists:foreach(
                fun(RankInfo) ->
                    set_family_as_rank(RankInfo)
                end, RankList),
            set_rank_time(Now + ?FAMILY_AS_RANK_INTERVAL);
        true ->
            ok
    end.

handle(Info) ->
    do_handle_info(Info).
do_handle_info({bingo, FamilyID, FamilyName}) ->
    change_family_score(FamilyID, FamilyName);
do_handle_info(activity_end) ->
    activity_end();
do_handle_info(Info) ->
    ?ERROR_MSG("unkonw info : ~w", [Info]).




start_map(FamilyID) ->
    map_sup:start_map(?MAP_FAMILY_AS, FamilyID).

init_question() ->
    AllQuestion = cfg_activity_family_as:list(),
    AllQuestion2 = lib_tool:random_reorder_list(AllQuestion),
    {ok, Question} = lib_tool:random_elements_from_list(?FAMILY_QUESTION_NUM, AllQuestion2),
    format_question(Question, []).

format_question([], Questions) ->
    Questions;
format_question([{_, Question}|T], Questions) ->
    format_question(T, [Question|Questions]).


set_family_as_maps(ExtraList) ->
    erlang:put({?MODULE, family_as_maps}, ExtraList).
get_family_as_maps() ->
    erlang:get({?MODULE, family_as_maps}).

set_rank_time(Time) ->
    erlang:put({?MODULE, rank_time}, Time).
get_rank_time() ->
    erlang:get({?MODULE, rank_time}).


%% 更变积分数据
set_family_as_rank(FamilyRank) ->
    ets:insert(?ETS_FAMILY_AS_RANK, FamilyRank).
get_family_as_rank(FamilyID, FamilyName) ->
    case ets:lookup(?ETS_FAMILY_AS_RANK, FamilyID) of
        [#r_family_as_rank{} = FamilyRank] ->
            FamilyRank;
        _ ->
            #r_family_as_rank{family_id = FamilyID, family_name = FamilyName}
    end.

change_family_score(FamilyID, FamilyName) ->
    FamilyRank = get_family_as_rank(FamilyID, FamilyName),
    NewFamilyRank = FamilyRank#r_family_as_rank{score = FamilyRank#r_family_as_rank.score + 1, time = time_tool:now()},
    set_family_as_rank(NewFamilyRank).

do_rank() ->
    List = ets:tab2list(?ETS_FAMILY_AS_RANK),
    NewList = lists:sort(
        fun(A, B) ->
            if
                A#r_family_as_rank.score > B#r_family_as_rank.score -> true;
                A#r_family_as_rank.score =:= B#r_family_as_rank.score ->
                    A#r_family_as_rank.time < B#r_family_as_rank.time;
                true ->
                    false
            end
        end, List),
    {_, FinalRankList, FinalFormatInfo} = lists:foldl(
        fun(RankInfo, {Rank, AllList, FormatInfoList}) ->
            NewRankInfo = RankInfo#r_family_as_rank{rank = Rank},
            FormatInfo = format_info(NewRankInfo),
            case NewRankInfo#r_family_as_rank.score =:= 0 of
                false ->
                    {Rank + 1, [NewRankInfo|AllList], [FormatInfo|FormatInfoList]};
                _ ->
                    {Rank + 1, AllList, [FormatInfo|FormatInfoList]}
            end
        end, {1, [], []}, NewList),
    {FinalRankList, FinalFormatInfo}.

do_send_reward([]) ->
    ok;
do_send_reward([#r_family_as_rank{rank = Rank, family_id = FamilyID}|T]) ->
    case lib_config:find(cfg_activity_family_as_reward, Rank) of
        [] ->
            ok;
        [Config] ->
            Goods = [#p_goods{type_id = Type, num = Num} || {Type, Num} <- lib_tool:string_to_intlist(Config#c_activity_family_as_reward.reward1)],
            Goods2 = [#p_goods{type_id = Type, num = Num} || {Type, Num} <- lib_tool:string_to_intlist(Config#c_activity_family_as_reward.reward2)],
            #p_family{members = Members} = mod_family_data:get_family(FamilyID),
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_FAMILY_ANSWER,
                text_string = [lib_tool:to_list(Rank)],
                action = ?ITEM_GAIN_LETTER_FAMILY_ANSWER,
                goods_list = Goods ++ Goods2
            },
            case catch get_red_packet_info(Rank) of
                {ok, From, Amount} ->
                    do_send_reward_i(Members, Amount, From, LetterInfo);
                _ ->
                    ok
            end
    end,
    do_send_reward(T).

do_send_reward_i([], _Amount, _, _LetterInfo) ->
    ok;
do_send_reward_i([Member|T], Amount, From, LetterInfo) ->
    case Member#p_family_member.title =:= ?TITLE_OWNER of
        true ->
            mod_family_red_packet:create_red_packet(Member#p_family_member.role_id, Member#p_family_member.role_name, From, Amount);
        _ ->
            ok
    end,
    common_letter:send_letter(Member#p_family_member.role_id, LetterInfo),
    do_send_reward_i(T, Amount, From, LetterInfo).



get_red_packet_info(Rank) ->
    Num = case Rank of
              1 ->
                  ?RED_PACKET_FAMILY_AS_FIRST;
              2 ->
                  ?RED_PACKET_FAMILY_AS_SECOND;
              3 ->
                  ?RED_PACKET_FAMILY_AS_THIRD;
              _ ->
                  ?THROW_ERR(1)
          end,
    [Config] = lib_config:find(cfg_red_packet, Num),
    {ok, Config#c_red_packet.id, Config#c_red_packet.amount}.



format_info(List) when erlang:is_list(List) ->
    format_info(List, []);
format_info(Info) ->
    #r_family_as_rank{family_name = FName, score = Score, rank = Rank} = Info,
    #p_family_as_rank{rank = Rank, name = FName, score = Score}.

format_info([], List) ->
    List;
format_info([Info|T], List) ->
    #r_family_as_rank{family_name = FName, score = Score, rank = Rank} = Info,
    NewInfo = #p_family_as_rank{rank = Rank, name = FName, score = Score},
    format_info(T, [NewInfo|List]).

log_family_answer(RankList) ->
    LogList = [
        #log_family_answer{family_id = FamilyID, answer_rank = Rank, score = Score} ||
        #r_family_as_rank{family_id = FamilyID, rank = Rank, score = Score} <- RankList],
    background_misc:log(LogList).

do_family_answer_broadcast(RankList) ->
    RankList2 = lists:sublist(lists:keysort(#r_family_as_rank.rank, RankList), 3),
    [common_broadcast:send_world_common_notice(?NOTICE_FAMILY_ANSWER_END, [FamilyName, lib_tool:to_list(Rank)]) ||
        #r_family_as_rank{family_name = FamilyName, rank = Rank} <- RankList2].

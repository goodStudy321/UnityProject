%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     章节
%%% @end
%%% Created : 21. 八月 2018 11:43
%%%-------------------------------------------------------------------
-module(mod_role_chapter).
-author("laijichang").
-include("role.hrl").
-include("mission.hrl").
-include("proto/mod_role_chapter.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2
]).

-export([
    add_chapter/2,
    gm_add_chapter/3
]).

init(#r_role{role_id = RoleID, role_chapter = undefined} = State) ->
    RoleChapter = #r_role_chapter{role_id = RoleID},
    State#r_role{role_chapter = RoleChapter};
init(State) ->
    State.

online(State) ->
    #r_role{role_id = RoleID, role_chapter = RoleChapter} = State,
    #r_role_chapter{chapter_list = ChapterList} = RoleChapter,
    DataRecord = #m_chapter_info_toc{chapter_list = ChapterList},
    common_misc:unicast(RoleID, DataRecord),
    State.

add_chapter(MissionID, State) ->
    case get_chapter(MissionID) of
        {ok, ChapterID} ->
            add_chapter2(ChapterID, 1, State);
        _ ->
            State
    end.

add_chapter2(ChapterID, AddNum, State) ->
    #r_role{role_id = RoleID, role_chapter = RoleChapter} = State,
    #r_role_chapter{chapter_list = ChapterList} = RoleChapter,
    case lists:keyfind(ChapterID, #p_chapter.id, ChapterList) of
        #p_chapter{num = Num} = Chapter ->
            [#c_chapter{need_num = NeedNum}] = lib_config:find(cfg_chapter, ChapterID),
            Num2 = erlang:min(NeedNum, Num + AddNum),
            Chapter2 = Chapter#p_chapter{num = Num2};
        _ ->
            Chapter2 = #p_chapter{id = ChapterID, num = AddNum, is_reward = false}
    end,
    ChapterList2 = lists:keystore(ChapterID, #p_chapter.id, ChapterList, Chapter2),
    RoleChapter2 = RoleChapter#r_role_chapter{chapter_list = ChapterList2},
    common_misc:unicast(RoleID, #m_chapter_update_toc{chapter = Chapter2}),
    State#r_role{role_chapter = RoleChapter2}.

gm_add_chapter(ChapterID, AddNum, State) ->
    case lib_config:find(cfg_chapter, ChapterID) of
        [_Config] ->
            add_chapter2(ChapterID, AddNum, State);
        _ ->
            State
    end.

handle({#m_chapter_reward_tos{chapter_id = ChapterID}, RoleID, _PID}, State) ->
    do_chapter_reward(RoleID, ChapterID, State).

do_chapter_reward(RoleID, ChapterID, State) ->
    case catch check_chapter_reward(ChapterID, State) of
        {ok, BagDoings, Chapter2, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_chapter_reward_toc{chapter = Chapter2}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_chapter_reward_toc{err_code = ErrCode}),
            State
    end.

check_chapter_reward(ChapterID, State) ->
    #r_role{role_chapter = RoleChapter} = State,
    #r_role_chapter{chapter_list = ChapterList} = RoleChapter,
    case lists:keyfind(ChapterID, #p_chapter.id, ChapterList) of
        #p_chapter{num = Num, is_reward = IsReward} = Chapter ->
            ?IF(IsReward, ?THROW_ERR(?ERROR_CHAPTER_REWARD_001), ok),
            [#c_chapter{need_num = NeedNum, rewards = Rewards}] = lib_config:find(cfg_chapter, ChapterID),
            ?IF(Num >= NeedNum, ok, ?THROW_ERR(?ERROR_CHAPTER_REWARD_002)),
            Chapter2 = Chapter#p_chapter{is_reward = true},
            GoodsList = [ #p_goods{type_id = TypeID, num  = ItemNum}|| {TypeID, ItemNum} <- common_misc:get_item_reward(Rewards)],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoings = [{create, ?ITEM_GAIN_CHAPTER_REWARD, GoodsList}],
            ChapterList2 = lists:keyreplace(ChapterID, #p_chapter.id, ChapterList, Chapter2),
            RoleChapter2 = RoleChapter#r_role_chapter{chapter_list = ChapterList2},
            State2 = State#r_role{role_chapter = RoleChapter2},
            {ok, BagDoings, Chapter2, State2};
        _ ->
            ?THROW_ERR(?ERROR_CHAPTER_REWARD_001)
    end.

get_chapter(MissionID) ->
    [#c_mission_excel{chapter = ChapterID}] = lib_config:find(cfg_mission_excel, MissionID),
    case lib_config:find(cfg_chapter, ChapterID) of
        [_Config] ->
            {ok, ChapterID};
        _ ->
            false
    end.
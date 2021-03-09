%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 十二月 2018 11:57
%%%-------------------------------------------------------------------
-module(marry_misc).
-author("laijichang").
-include("marry.hrl").
-include("global.hrl").

%% API
-export([
    is_feast_over/1,
    is_taste_collection/1,
    is_couple/2,
    is_propose/2,
    has_couple/1
]).

-export([
    get_couple_id/1,
    get_marry_data/1,
    get_share_marry/1,
    get_share_marry_by_id/1,
    get_share_id/2
]).

-export([
    trans_to_p_guest/1,
    trans_to_p_apply_guest/1
]).

-export([
    log_marry_status/3
]).

is_feast_over(FeastStartTime) ->
    time_tool:now() > FeastStartTime + ?FEAST_TIME.

is_taste_collection(TypeID) ->
    TasteList = common_misc:get_global_list(?GLOBAL_MARRY_TASTE),
    lists:member(TypeID, TasteList).

is_couple(RoleID1, RoleID2) ->
    #r_marry_data{couple_id = CoupleID} = get_marry_data(RoleID1),
    CoupleID =:= RoleID2.

is_propose(RoleID1, RoleID2) ->
    #r_marry_data{propose_id = ProposeID, be_propose_list = BeProposeList} = get_marry_data(RoleID1),
    RoleID2 =:= ProposeID orelse lists:member(RoleID2, BeProposeList).

get_couple_id(RoleID) ->
    #r_marry_data{couple_id = CoupleID} = get_marry_data(RoleID),
    CoupleID.

get_marry_data(RoleID) ->
    mod_marry_data:get_marry_data(RoleID).

get_share_marry(ShareID) ->
    mod_marry_data:get_share_marry(ShareID).

get_share_marry_by_id(RoleID) ->
    #r_marry_data{couple_id = CoupleID} = get_marry_data(RoleID),
    get_share_marry(get_share_id(RoleID, CoupleID)).

get_share_id(RoleID1, RoleID2) ->
    ?IF(RoleID1 > RoleID2, {RoleID1, RoleID2}, {RoleID2, RoleID1}).


trans_to_p_guest(GuestList) when erlang:is_list(GuestList) ->
    [ #p_dks{id = RoleID, val = common_role_data:get_role_name(RoleID) }|| RoleID <- GuestList];
trans_to_p_guest(RoleID) ->
    #p_dks{id = RoleID, val = common_role_data:get_role_name(RoleID)}.

trans_to_p_apply_guest(ApplyGuestList) ->
    [ #p_dks{id = RoleID, val = common_role_data:get_role_name(RoleID)}||
        #r_feast_apply{role_id = RoleID, is_refuse = IsRefuse} <- ApplyGuestList, not IsRefuse].

log_marry_status(ShareMarry, Type, ProposeType) ->
    #r_marry_share{
        share_id = ShareID,
        guest_list = GuestList
    } = ShareMarry,
    {RoleID1, RoleID2} = ShareID,
    LogMarry =
        #log_marry_status{
            role_id1 = RoleID1,
            role_id2 = RoleID2,
            action_type = Type,
            propose_type = ProposeType,
            guest_list = common_misc:get_list_string(GuestList)
        },
    background_misc:log(LogMarry).


has_couple(RoleID) ->
    #r_marry_data{couple_id = CoupleID} = get_marry_data(RoleID),
    ?HAS_COUPLE(CoupleID).
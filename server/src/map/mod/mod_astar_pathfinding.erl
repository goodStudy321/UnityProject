%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created : 15 Jul 2011 by  <>
%%%-------------------------------------------------------------------
-module(mod_astar_pathfinding).

-include("global.hrl").


-export([
         find_path/2,
         find_path/3,
         cmp/2
]).
-define(DEFAULT_HEAP_SIZE, 150).
-define(ASTAR_OPEN_HEAP, astar_open_heap).
-define(ASTAR_CLOSE_LIST, astar_close_list).
-define(ASTAR_CLOSE_LIST_ELEMENT, astar_close_list_element).

%% 
find_path(StartPos, EndPos) ->
    case  map_misc:check_same_tile(StartPos,EndPos) of
        true ->
            false;
        false ->
            find_path(StartPos, EndPos, ?DEFAULT_HEAP_SIZE)
    end.

find_path(StartPos, EndPos, HeapSize) ->
    lib_minheap:new_heap(?ASTAR_OPEN_HEAP, HeapSize, {?MODULE,cmp}),
    set_close_list([]),
    #r_pos{tx=StartTx, ty=StartTz, dir=StartDir} = StartPos,
    StartNode = #r_map_node{key={StartTx, StartTz}, tx=StartTx, tz=StartTz, dir=StartDir, g=0},
    close_list_insert(StartNode),
    #r_pos{tx=EndTX, ty=EndTZ}= EndPos,
    find_path2(StartNode, EndTX, EndTZ).

find_path2(CurNode, EndTx, EndTy) ->
    case catch insert_aound_map_nodes(CurNode, EndTx, EndTy) of
        ok ->
            case lib_minheap:del_min_element(?ASTAR_OPEN_HEAP) of
				undefined ->
					close_list_delete(),
                    lib_minheap:delete_heap(?ASTAR_OPEN_HEAP),
            		false;
				MinNode ->
            		close_list_insert(MinNode),
            		find_path2(MinNode, EndTx, EndTy)
			end;
        {ok, get_it} ->
            EndDir = get_dir(CurNode, EndTx, EndTy),
            EndRecordPos = map_misc:get_pos_by_tile(EndTx, EndTy, EndDir),
            Path = [#r_path{corner=map_misc:pos_encode(EndRecordPos), path=[EndRecordPos]}],
            lib_minheap:delete_heap(?ASTAR_OPEN_HEAP),
            find_path3(CurNode, Path, EndDir);
        {error, _} ->
            close_list_delete(),
            lib_minheap:delete_heap(?ASTAR_OPEN_HEAP),
            false;
        Error ->
            ?INFO_MSG("find_path error: ~w", [{Error}]),
            close_list_delete(),
            lib_minheap:delete_heap(?ASTAR_OPEN_HEAP),
            false
    end.
find_path3(#r_map_node{p_parent=undefined},  AllPath, _LastDir) -> %% 起始点不加进去
    close_list_delete(),
    AllPath;
%%    close_list_delete(),
%%    #r_map_node{tx=Tx, tz=Tz, dir=Dir} = MapNode,
%%    case Dir =:= LastDir of
%%        true -> %% ͬһ��·��
%%            NewPath = [ Path#r_path{path=[ map_misc:get_pos_by_tile(Tx, Tz, Dir) |Points]} | RemPath];
%%        false ->
%%            RecordPos = map_misc:get_pos_by_tile(Tx, Tz, Dir),
%%            NewPath = [ Path#r_path{corner=map_misc:pos_encode(RecordPos), path=[ RecordPos]} | AllPath]
%%    end,
%%    NewPath;
find_path3(CurNode, [ #r_path{path=Points}=Path | RemPath] = AllPath, LastDir) ->
    ParentNode = get_close_list(CurNode#r_map_node.p_parent),
    #r_map_node{tx=Tx, tz=Tz, dir=Dir} = CurNode,
    case Dir =:= LastDir of
        true ->
            NewPath = [ Path#r_path{path=[ map_misc:get_pos_by_tile(Tx, Tz, Dir) |Points]} | RemPath];
        false ->
            RecordPos = map_misc:get_pos_by_tile(Tx, Tz, Dir),
            NewPath = [ Path#r_path{corner=map_misc:pos_encode(RecordPos), path=[ RecordPos]} | AllPath]
    end,
    find_path3(ParentNode, NewPath, Dir).
    
%% find_path3(#r_map_node{p_parent=undefined}=MapNode, Path) ->
%%     close_list_delete(),
%%     [map_misc:get_pos_by_tile(MapNode#r_map_node.tx,0, MapNode#r_map_node.tz, MapNode#r_map_node.dir)|Path];
%% find_path3(CurNode, Path) ->
%%     ParentNode = get_close_list(CurNode#r_map_node.p_parent),
%%     find_path3(ParentNode, [map_misc:get_pos_by_tile(CurNode#r_map_node.tx,0, CurNode#r_map_node.tz, CurNode#r_map_node.dir)|Path]).

insert_aound_map_nodes(CurNode, EndTX, EndTY) ->
    #r_map_node{tx=CTX, tz=CTZ} = CurNode,
    [begin 
         lists:foreach(
           fun(TY) ->
                   WalkTable = is_tile_walkable(TX, TY),
                   if TX =:= EndTX andalso TY =:= EndTY ->
                           erlang:throw({ok, get_it});
                      TX =:= CTX andalso TY =:= CTZ ->
                           ignore;
                      not WalkTable ->
                           ignore;
                      true ->
                           insert_aound_map_nodes2(CurNode, EndTX, EndTY, TX, TY, close_list_member({TX, TY}))
                   end
           end, lists:seq(CTZ-1, CTZ+1))
     end || TX <- lists:seq(CTX-1, CTX+1)],
    ok.

insert_aound_map_nodes2(_CurNode, _EndTX, _EndTY, _TX, _TY, true) ->
    ignore;
insert_aound_map_nodes2(CurNode, EndTX, EndTY, TX, TY, false) ->
    MapNode = get_map_node(TX, TY, CurNode, EndTX, EndTY),
    case lib_minheap:get_element_by_key(?ASTAR_OPEN_HEAP, {TX, TY}) of
        undefined ->
            case lib_minheap:insert_element(?ASTAR_OPEN_HEAP,{TX, TY}, MapNode) of
                {error, _} ->
                    erlang:throw({error, heap_full});
                _ ->
                    ok
            end;
        OldMapNode ->
            if MapNode#r_map_node.f >= OldMapNode#r_map_node.f ->
                    ignore;
               true ->
                    lib_minheap:update_element(?ASTAR_OPEN_HEAP, {TX, TY}, MapNode)
            end
    end.

cmp(NodeA, NodeB) ->
    NodeA#r_map_node.f < NodeB#r_map_node.f.

get_map_node(TX, TY, CurNode, EndTX, EndTY) ->
    G = CurNode#r_map_node.g + 1,
    H = erlang:abs(TX-EndTX) + erlang:abs(TY-EndTY),
    #r_map_node{key={TX, TY}, tx=TX, tz=TY, g=G, f=G+H,
                p_parent={CurNode#r_map_node.tx, CurNode#r_map_node.tz},
                dir=get_dir(CurNode, TX, TY)}.

is_tile_walkable(TX, TY) ->
     map_base_data:is_exist(TX,TY).

get_dir(StartNode, TX, TY) ->
    #r_map_node{tx=STX, tz=STY} = StartNode,
    if TX > STX ->
            if TY > STY -> 1;
               TY =:= STY -> 2;
               true -> 3
            end;
       TX =:= STX ->
            if TY > STY -> 0;
               true -> 4
            end;
       true ->
            if TY > STY -> 7;
               TY =:= STY -> 6;
               true -> 5
            end
    end.

set_close_list(L) ->
    erlang:put(?ASTAR_CLOSE_LIST, L).

get_close_list(EKey) ->
    case erlang:get({?ASTAR_CLOSE_LIST_ELEMENT, EKey}) of
        undefined ->
            {error, not_found};
        Node ->
            Node
    end.

get_close_list() ->
    case erlang:get(?ASTAR_CLOSE_LIST) of
        undefined ->
            [];
        L ->
            L
    end.

close_list_insert(MapNode) when is_record(MapNode, r_map_node)->
    set_close_list([MapNode#r_map_node.key|get_close_list()]),
    erlang:put({?ASTAR_CLOSE_LIST_ELEMENT, MapNode#r_map_node.key}, MapNode);
close_list_insert(MapNode) ->
    ?INFO_MSG("MapNode=~w",[MapNode]).

close_list_delete() ->
    lists:foreach(
      fun(EKey) ->
              erlang:erase({?ASTAR_CLOSE_LIST_ELEMENT, EKey})
      end, get_close_list()),
    erlang:erase(?ASTAR_CLOSE_LIST).

close_list_member(EKey) ->
    case get_close_list(EKey) of
        {error, _} ->
            false;
        _ ->
            true
    end.

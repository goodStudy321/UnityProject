%%%-------------------------------------------------------------------
%%% @doc
%%%     最小堆通用模块（维护小顶堆数据，堆顶是堆中最小元素）
%%% @end
%%%-------------------------------------------------------------------
-module(lib_minheap).

-export([
         new_heap/3,
         new_heap/4,
         clear_heap/1,
         delete_heap/1,
         get_min_element/1,
         del_min_element/1,
         get_all_elements/1,
         get_element_by_key/2,
         insert_element/3,
         insert_element2/3,
         update_element/3,
         delete_element/2,
         is_full/1,
         is_empty/1,
         get_cmp_func/1,
         get_max_heap_size/1
        ]).

-define(HEAP_CMP_FUNC, heap_cmp_func).
-define(HEAP_INDEX2ELEMENT, heap_index2element).
-define(HEAP_KEY2INDEX, heap_key2index).
-define(HEAP_MAX_SIZE, heap_max_size).
-define(HEAP_SIZE, heap_size).

%% @doc 创建最小堆
%% @end
%% CmpFunc := {Mod,Func}, 比较函数, 定义为: fun(A, B) -> true|false, 当A=<B时返回true, 否则false
-spec new_heap(term(), integer(), {atom(), atom()}) -> {atom(), atom()} | undefined.
new_heap(HeapName, HeapSize, {_Mod,_Fun} = CmpFunc) ->
    set_max_heap_size(HeapName, HeapSize),
    set_heap_size(HeapName, 0),
    set_cmp_func(HeapName, CmpFunc).

%% @doc 创建最小堆, 并插入数据
%% @end
%% CmpFunc := {Mod,Func}, 比较函数, 定义为: fun(A, B) -> true|false, 当A=<B时返回true, 否则false
%%          ElementInfos := [{Key,Element}]
-spec new_heap(term(), integer(), {atom(), atom()}, [{term(), term()}]) -> ok.
new_heap(HeapName, HeapSize, {_Mod,_Fun} = CmpFunc, ElementInfos) ->
    set_max_heap_size(HeapName, HeapSize),
    set_heap_size(HeapName, 0),
    set_cmp_func(HeapName, CmpFunc),
    [begin insert_element(HeapName, Key, Element) end || {Key,Element} <-ElementInfos],
    ok.

%% @doc 删除所有堆元素, 但保留堆的其他属性
-spec clear_heap(term()) -> ok | ignore.
clear_heap(HeapName) ->
    case get_heap_size(HeapName) of
        HeapSize when erlang:is_integer(HeapSize)->
            clear_heap(HeapName, HeapSize, 0);
        _ ->
            ignore
    end.
clear_heap(HeapName, Size, Size) ->
    del_element_by_index(HeapName, Size),
    set_heap_size(HeapName, 0),
    ok;
clear_heap(HeapName, Size, Index) ->
    del_element_by_index(HeapName, Index),
    clear_heap(HeapName, Size, Index+1).

%% @doc 删除堆
-spec delete_heap(term()) -> ok.
delete_heap(HeapName) ->
    clear_heap(HeapName),
    del_heap_size(HeapName),
    del_max_heap_size(HeapName),
    del_cmp_func(HeapName),
    ok.

%% @doc 获取最小元素
-spec get_min_element(term()) -> term() | undefined.
get_min_element(HeapName) ->
    case is_empty(HeapName) of
        true->
            undefined;
        false ->
            case get_element_key_by_index(HeapName, 0) of
                {_Key,Element} ->
                    Element;
                _ ->
                    undefined
            end
    end.

%% @doc 删除最小元素
-spec del_min_element(term()) -> term() | undefined.
del_min_element(HeapName) ->
    case is_empty(HeapName) of
        true ->
            undefined;
        false ->
            case get_element_key_by_index(HeapName, 0) of
                {TopKey,TopElement} ->
                    del_element(HeapName, 0, TopKey),
                    LastIndex = get_heap_size(HeapName)-1,
                    set_heap_size(HeapName, LastIndex),
                    case get_element_key_by_index(HeapName, LastIndex) of
                        {LastKey,LastElement} ->
                            set_element(HeapName, 0, LastKey, LastElement),
                            filter_down(HeapName, 0),
                            TopElement;
                        _->
                            TopElement
                    end;
                _ ->undefined
            end
    end.

%% @doc 获取堆中所有元素, 升序
-spec get_all_elements(term()) -> [term()].
get_all_elements(HeapName) ->
    case get_heap_size(HeapName) of
        HeapSize when HeapSize>0 ->
            lists:foldl(fun(Index, Acc) ->
                                case get_element_key_by_index(HeapName, Index) of
                                    {_Key,Element} ->
                                        [Element|Acc];
                                    _ -> Acc
                                end
                        end, [], lists:seq(0, HeapSize-1));
        _ ->
            []
    end.

%% @doc 根据键值获取堆中元素
-spec get_element_by_key(term(), term()) -> term() | undefined.
get_element_by_key(HeapName, Key) ->
    case get_index_by_key(HeapName, Key) of
        Index when erlang:is_integer(Index)->
            case get_element_key_by_index(HeapName, Index) of
                {Key,Element} ->
                    Element;
                _ -> undefined
            end;
        _ -> undefined
    end.

%% @doc 插入/更新元素. 若在堆已满时插入新元素, 则与最小元素比较, 删除最小元素或取消插入
-spec insert_element(term(), term(), term()) -> ok | {error,heap_full}.
insert_element(HeapName, Key, Element) ->
    case get_index_by_key(HeapName, Key) of
        Index when erlang:is_integer(Index) -> %%已有元素
            update(HeapName, Key, Element, Index),
            ok;
        undefined -> %%插入新元素
            case is_full(HeapName) of
                true ->
                    MinElement = get_min_element(HeapName),
                    {Module,Func} = get_cmp_func(HeapName),
                    case erlang:apply(Module, Func, [MinElement,Element]) of
                        true ->
                            del_min_element(HeapName),
                            insert_element(HeapName, Key, Element);
                        _ ->
                            {error, heap_full}
                    end;
                false ->
                    HeapSize = get_heap_size(HeapName),
                    set_element(HeapName, HeapSize, Key, Element),
                    filter_up(HeapName, HeapSize),
                    set_heap_size(HeapName, HeapSize+1),
                    ok
            end
    end.
%% @doc 插入/更新元素. 若在堆已满时插入新元素, 则与最小元素比较, 删除最小元素或取消插入，【如果插入的key已有数值，则以高的为准】
-spec insert_element2(term(), term(), term()) -> ok | {error,heap_full}.
insert_element2(HeapName, Key, Element) ->
    case get_index_by_key(HeapName, Key) of
        Index when erlang:is_integer(Index) ->
            case get_element_key_by_index(HeapName, Index) of
                {Key, OldElement} ->
                    {Module,Func} = get_cmp_func(HeapName),
                    case erlang:apply(Module, Func, [OldElement,Element]) of
                        true ->
                            update(HeapName, Key, Element, Index);
                        _ ->
                            {error, heap_full}
                    end;
                _ ->
                    update(HeapName, Key, Element, Index),
                    ok
            end;
        undefined -> %%插入新元素
            case is_full(HeapName) of
                true ->
                    MinElement = get_min_element(HeapName),
                    {Module,Func} = get_cmp_func(HeapName),
                    case erlang:apply(Module, Func, [MinElement,Element]) of
                        true ->
                            del_min_element(HeapName),
                            insert_element(HeapName, Key, Element);
                        _ ->
                            {error, heap_full}
                    end;
                false ->
                    HeapSize = get_heap_size(HeapName),
                    set_element(HeapName, HeapSize, Key, Element),
                    filter_up(HeapName, HeapSize),
                    set_heap_size(HeapName, HeapSize+1),
                    ok
            end
    end.

%% @doc 更新现有元素
-spec update_element(term(), term(), term()) -> ok | {error,not_found}.
update_element(HeapName, Key, Element) ->
    case get_index_by_key(HeapName, Key) of
        Index when erlang:is_integer(Index) ->
            update(HeapName, Key, Element, Index),
            ok;
        undefined ->
            {error,not_found}
    end.

%% @doc 删除堆中的某一元素然后维护堆
-spec delete_element(term(), term()) -> ok | {error,not_found}.
delete_element(HeapName, Key) ->
    case get_index_by_key(HeapName, Key) of
        Index when erlang:is_integer(Index) -> %%已有元素
            del_element(HeapName, Index, Key),
            LastIndex = get_heap_size(HeapName)-1,
            set_heap_size(HeapName, LastIndex),
            case get_element_key_by_index(HeapName, LastIndex) of
                {LastKey, LastElement} ->
                    set_element(HeapName, Index, LastKey, LastElement),
                    filter(HeapName, Index, LastKey, LastElement);
                _ ->
                    ignore
            end,
            ok;
        _Error ->
            {error, not_found}
    end.

%% @doc 判断是否堆满
-spec is_full(term()) -> true | false.
is_full(HeapName) ->
    case get_max_heap_size(HeapName) of
        {ok,MaxHeapSize} ->
            HeapSize = get_heap_size(HeapName),
            HeapSize >= MaxHeapSize;
        _ ->true
    end.

%% @doc 判断堆是否为空
-spec is_empty(term()) -> true | false.
is_empty(HeapName) ->
    get_heap_size(HeapName) =:= 0.


%%
%%================LOCAL FUCTION=======================
%%
%% 更新堆中元素的值然后重新维护堆
update(HeapName, Key, Element, Index) ->
    set_element(HeapName, Index, Key, Element),
    filter(HeapName, Index, Key, Element).

filter(HeapName, Index, _Key, Element) ->
    ParentIndex = erlang:trunc((Index - 1) / 2),
    {_ParentKey,ParentElement} = get_element_key_by_index(HeapName, ParentIndex),
    {Module,Fun} = get_cmp_func(HeapName),
    case erlang:apply(Module, Fun, [ParentElement, Element]) of
        false ->
            %%新的值比父节点小的时候往上跟新
            filter_up(HeapName, Index);
        true ->
            %%新的值比父亲节点大的时候往下跟新
            filter_down(HeapName, Index)
    end.

filter_up(HeapName, Index) ->
    CurrentIndex = Index,
    ParentIndex = erlang:trunc((Index - 1) / 2),
    {TargetKey,TargetElement} = get_element_key_by_index(HeapName, CurrentIndex),
    NewCurrentIndex = filter_up2(CurrentIndex, ParentIndex, TargetElement, HeapName),
    set_element(HeapName, NewCurrentIndex, TargetKey, TargetElement).
filter_up2(0, _, _, _) ->
    0;
filter_up2(CurrentIndex, ParentIndex, TargetElement, HeapName) ->
    {ParentKey,ParentElement} = get_element_key_by_index(HeapName, ParentIndex),
    {Module,Fun} = get_cmp_func(HeapName),
    case erlang:apply(Module, Fun, [ParentElement, TargetElement]) of
        true ->
            CurrentIndex;
        false ->
            set_element(HeapName, CurrentIndex, ParentKey, ParentElement),
            filter_up2(ParentIndex, erlang:trunc((ParentIndex-1)/2), TargetElement, HeapName)
    end.

filter_down(HeapName, Index) ->
    CurrentIndex = Index,
    ChildIndex = 2 * Index + 1,
    {TargetKey,TargetElement} = get_element_key_by_index(HeapName, CurrentIndex),
    HeapSize = get_heap_size(HeapName),
    NewCurrentIndex = filter_down2(CurrentIndex, ChildIndex, TargetElement, HeapSize, HeapName),
    set_element(HeapName, NewCurrentIndex, TargetKey, TargetElement).
filter_down2(CurrentIndex, ChildIndex, TargetElement, HeapSize, HeapName) ->
    case ChildIndex < HeapSize of
        false ->
            CurrentIndex;
        true ->
            {Module,Fun} = get_cmp_func(HeapName),
            case ChildIndex + 1 < HeapSize of
                true ->
                    {_,Element1} = get_element_key_by_index(HeapName, ChildIndex+1),
                    {_,Element2} = get_element_key_by_index(HeapName, ChildIndex),
                    case erlang:apply(Module, Fun, [Element1, Element2]) of
                        true ->
                            NewChildIndex = ChildIndex + 1;
                        false ->
                            NewChildIndex = ChildIndex
                    end;
                false ->
                    NewChildIndex = ChildIndex
            end,
            {ChildKey,ChildElement} = get_element_key_by_index(HeapName, NewChildIndex),
            case erlang:apply(Module, Fun, [TargetElement, ChildElement]) of
                true ->
                    CurrentIndex;
                false ->
                    set_element(HeapName, CurrentIndex, ChildKey, ChildElement),
                    filter_down2(NewChildIndex, NewChildIndex*2+1, TargetElement, HeapSize, HeapName)
            end
    end.


set_cmp_func(HeapName, {_Mod,_Fun} = CmpFunc) ->
    erlang:put({?HEAP_CMP_FUNC, HeapName}, CmpFunc).
%% @doc 获取比较函数
-spec get_cmp_func(term()) -> {atom(), atom()} | undefined.
get_cmp_func(HeapName) ->
    erlang:get({?HEAP_CMP_FUNC, HeapName}).
del_cmp_func(HeapName) ->
    erlang:erase({?HEAP_CMP_FUNC, HeapName}).

del_element(HeapName, Index, Key) ->
    erlang:erase({?HEAP_INDEX2ELEMENT, HeapName, Index}),
    erlang:erase({?HEAP_KEY2INDEX, HeapName, Key}).
set_element(HeapName, Index, Key,Element) ->
    erlang:put({?HEAP_INDEX2ELEMENT, HeapName, Index}, {Key,Element}),
    erlang:put({?HEAP_KEY2INDEX, HeapName, Key}, Index).
del_element_by_index(HeapName, Index) ->
    case get_element_key_by_index(HeapName, Index) of
        {Key, _Element} ->
            del_element(HeapName, Index, Key);
        _ ->ignore
    end.
%% @returns undefined|{Key,Element}
get_element_key_by_index(HeapName, Index) ->
    erlang:get({?HEAP_INDEX2ELEMENT, HeapName, Index}).
%% @returns undefined|Index
get_index_by_key(HeapName, Key) ->
    erlang:get({?HEAP_KEY2INDEX, HeapName, Key}).

set_heap_size(HeapName, HeapSize) ->
    erlang:put({?HEAP_SIZE, HeapName}, HeapSize).
%% @returns Size|0
get_heap_size(HeapName) ->
    case erlang:get({?HEAP_SIZE, HeapName}) of
        undefined ->
            0;
        HeapSize ->
            HeapSize
    end.
del_heap_size(HeapName) ->
    erlang:erase({?HEAP_SIZE, HeapName}).

set_max_heap_size(HeapName, HeapSize) ->
    erlang:put({?HEAP_MAX_SIZE, HeapName}, HeapSize).
%% @doc 获取堆可存元素数量最大值
-spec get_max_heap_size(term()) -> {ok, integer()} | {error,not_found}.
get_max_heap_size(HeapName) ->
    case erlang:get({?HEAP_MAX_SIZE, HeapName}) of
        undefined -> {error,not_found};
        HeapSize -> {ok,HeapSize}
    end.
del_max_heap_size(HeapName) ->
    erlang:erase({?HEAP_MAX_SIZE, HeapName}).

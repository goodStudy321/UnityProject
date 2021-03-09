%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 三月 2018 16:03
%%%-------------------------------------------------------------------
-module(web_tool).
-author("laijichang").
-include("web.hrl").
-include("global.hrl").

-export([
    return_ok/1,
    return_ok/2,
    return_list/2,
    return_error/2,
    return_string/2,
    return_xml/2
]).

%% API
-export([
    get_int_param/2,
    get_atom_param/2,
    get_string_param/2,
    get_integer_list/2,
    get_post_integer_list/2,
    trunc_slash/1
]).


-export([
    transfer_to_json/1,
    to_utf8/1,
    get_goods/1
]).

-export([
    json_body_decode/1
]).


%%返回XML数据 【不】自动加上xml头
return_xml({no_auto_head, XmlResult}, Req) ->
    Req:ok({"text/xml; charset=utf-8", XmlResult});
%%返回XML数据 自动加上xml头
return_xml({auto_head, XmlResult}, Req) ->
    XmlResult2 = "<?xml version=\"1.0\" encoding=\"utf-8\"?>" ++ XmlResult,
    Req:ok({"text/xml; charset=utf-8", XmlResult2}).
return_string(StringResult, Req) ->
    Req:ok({"text/html; charset=utf-8", [{"Cache-Control", "no-cache"}, {"Cache-Control", "no-store"}], StringResult}).
return_json(Rtn, Req) ->
    Result = (catch (lib_json:to_json(Rtn))),
    Req:ok({"text/html; charset=utf-8", Result}).


%% @doc 新版本的后台json返回接口
%% {
%%     "ret": 1,
%%     "msg": "错误原因"
%%     "data": ""
%% }
%% {
%%     "ret": 0,
%%     "msg": "错误原因"
%%     "data": ""
%% }


return_ok(Req) ->
    return_ok(Req, "").
return_ok(Req, Data) ->
    Return = [{ret, ?RETURN_SUCCESS}, {msg, 0}, {data, Data}],
    return_json(Return,Req).
return_list(Req,DataList) ->
    return_json(DataList, Req).
return_error(Req, ErrInfo) ->
    Return = [{ret, ?RETURN_ERROR}, {msg, ErrInfo}],
    return_json(Return,Req).

%% @doc 获取QueryString中的Int参数值,如果没有传参数，返回默认值0
get_int_param(Key, QueryString) ->
    Val = proplists:get_value(Key, QueryString),
    case Val of
        undefined ->
            0;
        "" ->
            0;
        <<"">> ->
            0;
        _ ->
            lib_tool:to_integer(Val)
    end.

%%@doc 获取QueryString中的atom参数值
get_atom_param(Key, QueryString) ->
    Val = proplists:get_value(Key, QueryString),
    lib_tool:to_atom(Val).

%%@doc 获取QueryString中的string参数值
get_string_param(Key, QueryString) ->
    proplists:get_value(Key, QueryString).

%% @doc 获取QueryString中的integer list
%% 以","分隔
get_integer_list(Key, QueryString) ->
    case proplists:get_value(Key, QueryString) of
        undefined ->
            [];
        Int when erlang:is_integer(Int) ->
            [Int];
        String ->
            List = string:tokens(String, ","),
            [erlang:list_to_integer(I) || I <- List]
    end.

%% json数组分隔
get_post_integer_list(Key, PostList) ->
    case proplists:get_value(Key, PostList) of
        undefined ->
            [];
        IntList ->
            [ lib_tool:to_integer(I) || I <- IntList]
    end.

%% @doc 去掉末尾的'/'
trunc_slash(Path) ->
    PathReverse = lists:reverse(Path),
    case PathReverse of
        [$/ | Remain] ->
            lists:reverse(Remain);
        _ ->
            Path
    end.


%% @doc 将Record转换为json
transfer_to_json(Rec) ->
    RecName = erlang:element(1, Rec),
    transfer_to_json1(RecName, Rec).
transfer_to_json1(RecName, Rec) when is_atom(RecName)=:= false ->
    FieldVals = lib_tool:to_list(Rec),
    RecFileds = [undefined || _ <- FieldVals],
    transfer_to_json2(RecFileds, FieldVals, []);
transfer_to_json1(RecName, Rec)  ->
    RecFileds = web_misc:get_record_fields(RecName),
    case RecFileds of
        [] ->  {error, record_not_defined, RecName};
        _ ->
            FieldVals = get_record_values(Rec),
            transfer_to_json2(RecFileds, FieldVals, [])
    end.
transfer_to_json2([], [], Result) ->
    lists:reverse(Result);
transfer_to_json2([HName | NameList], [HVal | ValList], Result) ->
    Rec = case is_tuple(HVal) of
              true ->
                  case HVal of
                      {{Y, M, D}, {HH, _MM, _SS}} when is_integer(Y) andalso is_integer(M)
                          andalso is_integer(D) andalso is_integer(HH) ->
                          {HName, date_to_string(HVal)};
                      {HH, MM, SS} when is_integer(HH) andalso is_integer(MM) andalso is_integer(SS) ->
                          {HName, time_to_string(HVal)};
                      {Key, Value} when is_integer(Key) ->
                          {Key, Value};
                      _ ->
                          {HName, transfer_to_json(HVal)}
                  end;
              false ->
                  case is_list(HVal) andalso length(HVal) > 0 of
                      true ->
                          transfer_to_json3(HName, HVal);
                      false ->
                          case HVal of
                              undefined -> {HName, ""};
                              [] -> {HName, ""};
                              _ -> {HName, HVal}
                          end
                  end
          end,
    transfer_to_json2(NameList, ValList, [Rec | Result]).
transfer_to_json3(HName, HVal) ->
    case is_tuple(hd(HVal)) of
        true ->
            SubRecList = [transfer_to_json(SubRec) || SubRec <- HVal],
            {HName, SubRecList};
        false ->
            {HName, HVal}
    end.
%% @doc 获取Record的所有值的列表
get_record_values(Record) ->
    [_H | Values] = lib_tool:to_list(Record),
    Values.
date_to_string(DateTime) ->
    {{Y, M, D}, {HH, MM, SS}} = DateTime,
    lists:flatten(io_lib:format("~w-~w-~w ~w:~w:~w", [Y, M, D, HH, MM, SS])).
time_to_string(Time) ->
    {HH, MM, SS} = Time,
    lists:flatten(io_lib:format("~w:~w:~w", [HH, MM, SS])).

to_utf8(List) ->
    case catch lib_tool:to_binary(List) of
        Binary when erlang:is_binary(Binary) ->
            unicode:characters_to_list(Binary);
        _ ->
            List
    end.

get_goods(String) ->
    [ begin
          case string:tokens(ItemString, ",") of
              [TypeID, Num, Bind] ->
                  IsBind = ?IS_BIND(lib_tool:to_integer(Bind));
              [TypeID, Num] ->
                  IsBind = true
          end,
          #p_goods{type_id = lib_tool:to_integer(TypeID), num = lib_tool:to_integer(Num), bind = IsBind}
      end || ItemString <- string:tokens(String, "|")].

json_body_decode(Binary) ->
    List = lib_tool:to_list(Binary),
    {ok, {obj, KVList}, []} = rfc4627:decode(List),
    KVList2 =
        [ begin
              if
                  erlang:is_integer(Value) ->
                      {Key, Value};
                  erlang:is_boolean(Value) ->
                      {Key, Value};
                  true ->
                      case Value of
                          {obj, JsonData} ->
                              {Key, JsonData};
                          _ ->
                              {Key, lib_tool:to_list(Value)}
                      end
              end
          end|| {Key, Value} <- KVList],
    KVList2.

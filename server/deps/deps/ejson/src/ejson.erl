
-module(ejson).

-export([decode/1, encode/1]).

decode(Data) when is_list(Data) ->
    decode(list_to_binary(Data));
decode(Data) when is_binary(Data) ->
    case (catch ejson_decode:value(Data)) of
        {error, Reason} ->
            throw({invalid_json, Reason});
        {<<>>, EJson} ->
            EJson;
        {_Rest, _EJson} ->
            throw(has_rest)
    end.
    
encode(Term) ->
    case (catch ejson_encode:value(Term)) of
        {error, Reason} ->
            throw({invalid_erljson, Reason});
        Else ->
            Else
    end.

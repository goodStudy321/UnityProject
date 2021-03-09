%% coding: latin-1
-module(common_xml).
-include_lib("xmerl/include/xmerl.hrl").

-export([
        gen_record/2,
        gen_erl/1,
        gen_xml/3,
        gen_all_format/2,
        gen_format/2,
        gen_format/3
        ]).

gen_record(XMLPath, XmlFormat) ->
    {XmlElt, _} = xmerl_scan:file(XMLPath),
    get_tuple(XmlElt, XmlFormat, "").

get_tuple(undefined, _XmlFormat, _PEltPatn) ->
    undefined;
get_tuple(XmlElt, XmlFormat,PEltPatn) ->
    TupleList = tuple_to_list(XmlFormat),
    [EltPatn|TupleList2] = TupleList,
    LEltPatn = "/" ++ erlang:atom_to_list(EltPatn),
    NewEltPatn = PEltPatn ++ LEltPatn,
    case xmerl_xpath:string(NewEltPatn, XmlElt) of %% Tuple结构只有一个
        [TupleXmlElt|_] -> ok;
        _ -> TupleXmlElt = undefined
    end,
    {TupleRes, _} = 
        lists:foldl(fun(Att, {Res, Index})->
                AttValue = 
                    case Att of
                        [AttTuple] when is_tuple(AttTuple) ->
                            get_tuple_list(TupleXmlElt, AttTuple, LEltPatn);
                        [AttAtom] when is_atom(AttAtom) ->
                            get_values(TupleXmlElt, AttAtom, LEltPatn);
                        AttAtom when is_atom(AttAtom) ->
                            get_value(TupleXmlElt, AttAtom, LEltPatn);
                        AttTuple when is_tuple(AttTuple) ->
                            get_tuple(TupleXmlElt, AttTuple, LEltPatn)
                    end,
                NewRes = setelement(Index, Res, AttValue),
                {NewRes, Index+1}
            end, {XmlFormat, 2}, TupleList2),
    TupleRes.
    
get_tuple_list(undefined, _XmlFormat, _PEltPatn) ->
    [];
get_tuple_list(TupleXmlElt, XmlFormat, PEltPatn) ->
    TupleList = tuple_to_list(XmlFormat),
    [EltPatn|TupleList2] = TupleList,
    LEltPatn = "/" ++ erlang:atom_to_list(EltPatn),
    NewEltPatn = PEltPatn ++ LEltPatn,
    TupleXmlEltList = xmerl_xpath:string(NewEltPatn, TupleXmlElt),
    [begin 
        {TupleRes, _} =
            lists:foldl(fun(Att, {Res, Index})->
                    AttValue = 
                        case Att of
                        [AttTuple] when is_tuple(AttTuple) ->
                            get_tuple_list(Tuple, AttTuple, LEltPatn);
                        [AttAtom] when is_atom(AttAtom) ->
                            get_values(Tuple, AttAtom, LEltPatn);
                        AttAtom when is_atom(AttAtom) ->
                            get_value(Tuple, AttAtom, LEltPatn);
                        AttTuple when is_tuple(AttTuple) ->
                            get_tuple(Tuple, AttTuple, LEltPatn)
                        end,
                    NewRes = setelement(Index, Res, AttValue),
                    {NewRes, Index+1}
                end, {XmlFormat, 2}, TupleList2),
        TupleRes
     end || Tuple <-TupleXmlEltList].
get_value(undefined, _AttAtom, _LEltPatn) ->
    undefined;
get_value(TupleXmlElt, AttAtom, LEltPatn) ->
    AttStr = erlang:atom_to_list(AttAtom),
    NewEltPatn = LEltPatn ++ "/@" ++ AttStr,
    case xmerl_xpath:string(NewEltPatn, TupleXmlElt) of
        [#xmlAttribute{value = PriceString}] -> to_val(PriceString);
        [] ->
            NewEltPatn2 = LEltPatn ++ "/" ++ AttStr,
            case xmerl_xpath:string(NewEltPatn2, TupleXmlElt) of
                [#xmlElement{attributes = Attributes}] ->  to_val(Attributes);
                [] ->
                    case AttStr of
                        "_" ++ _ -> make_erl_value(TupleXmlElt);
                        _ -> undefined
                    end
            end
    end.
get_values(undefined, _AttAtom, _LEltPatn) ->
    [];
get_values(TupleXmlElt, AttAtom, LEltPatn) ->
    AttStr = erlang:atom_to_list(AttAtom),
    NewEltPatn = LEltPatn ++ "/@" ++ AttStr,
    case xmerl_xpath:string(NewEltPatn, TupleXmlElt) of
        [#xmlAttribute{}|_]=L -> [to_val(PriceString) || #xmlAttribute{value = PriceString}<-L];
        [] ->
            NewEltPatn2 = LEltPatn ++ "/" ++ AttStr,
            case xmerl_xpath:string(NewEltPatn2, TupleXmlElt) of
                [#xmlElement{}|_]=L -> [to_val(Attributes)|| #xmlElement{attributes = Attributes} <-L];
                [] -> 
                    case AttStr of
                        "_" ++ _ -> make_erl_value(TupleXmlElt);
                        _ -> []
                    end
                        
            end
    end.
    
make_erl_value(TupleXmlElt) ->
    case TupleXmlElt of
        #xmlAttribute{value = PriceString} -> to_val(PriceString);
        #xmlElement{content=[]} -> [];
        #xmlElement{content=[_|_]=ElexmlElements} -> gen_erl2(ElexmlElements)
    end.
    
%% 直接把xml格式转成对应的tuple
%% <tag attr1=1 attr2=2 attr3=3> <l  a=1 /> <l  a=2 /> </tag>
%% 转成
%% {tag 1, 2, 3, [{a, 1}, {a, 2}]}
gen_erl(XMLPath) ->
    {XmlElt, _} = xmerl_scan:file(XMLPath),
    gen_erl2(XmlElt).
    
gen_erl2(TupleXmlElt) ->
    case TupleXmlElt of
        #xmlAttribute{value = PriceString} -> 
            to_val(PriceString);
        #xmlElement{name = Name, attributes = Attributes, content=[]} -> 
            erlang:list_to_tuple([ Name | gen_erl2(Attributes) ]) ;
        #xmlElement{name = Name, attributes = Attributes, content=[_|_]=ElexmlElements} ->  
            erlang:list_to_tuple([ Name | gen_erl2(Attributes)] ++ [ gen_erl2(ElexmlElements) ] );
        [_|_]=L -> 
            [ gen_erl2(T) || T<-L, case T of #xmlAttribute{} -> true; #xmlElement{} ->  true; _ -> false end];
        [] -> []
            % erlang:list_to_tuple([Name, [to_val(Attributes)|| #xmlElement{attributes = Attributes} <-L]]);
    end.

to_val(Val) ->
    case catch erlang:list_to_integer(Val) of
        Int when is_integer(Int) -> Int;
        _ -> unicode:characters_to_binary(Val)
    end.
to_str(Val) ->
    if
        erlang:is_list(Val) -> Val;
        erlang:is_atom(Val) -> erlang:atom_to_list(Val);
        erlang:is_integer(Val) -> erlang:integer_to_list(Val);
        erlang:is_binary(Val) -> erlang:binary_to_list(Val);
        erlang:is_float(Val) -> erlang:float_to_list(Val);
        true ->
            io:format("common_xml unknow: ~w~n", [Val]),
            Val
    end.
    

gen_format(Base, List) ->
    gen_format(Base, List, 100). 
    
gen_format(Base, List, MaxTimes) ->
    {RecordName, Attrs} = Base,
    gen_format2(Attrs, RecordName, List, MaxTimes).
gen_format2(Attrs, RecordName, List, Times) ->
    [Res] = gen_replace(Attrs, RecordName, List, Times),
    Res.
    
gen_replace(Attrs,  RecordName, List,Times) ->
    [erlang:list_to_tuple([RecordName |[ gen_replace2(Attr, List, Times) || Attr<-Attrs]])]. 
    
gen_replace2(Attr,  List, Times) when Times>0 ->
    case lists:keyfind(Attr, 1, List) of
        false -> Attr;
        {RecordName, Attrs} ->
            gen_replace(Attrs, RecordName, List, Times-1)
    end;
gen_replace2(Attr, List, Times) ->
    erlang:throw({error, {Attr, List, Times}}).
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gen_all_format(Base, List) ->
    AllFormatRecord =
        lists:foldl(fun(F, Acc)->
                        case lists:keymember(erlang:element(1, F), 1, Acc) of
                            true -> Acc;
                            _ -> 
                                XmlFormatF = gen_format(F, List),
                                gen_all_records2(XmlFormatF, []) ++ Acc
                        end
                    end, gen_all_records2(gen_format(Base, List), []), [Base|List]),
    lists:usort(AllFormatRecord).

gen_all_records2([XmlFormat], AllFormatRecord) ->
    gen_all_records2(XmlFormat, AllFormatRecord);
gen_all_records2(XmlFormat, AllFormatRecord) when erlang:is_tuple(XmlFormat) ->
    lists:foldl(fun(Index, Acc)-> 
                    gen_all_records2(erlang:element(Index, XmlFormat), Acc)
                end, [XmlFormat|AllFormatRecord], lists:seq(2, erlang:size(XmlFormat)));
gen_all_records2(XmlFormat, AllFormatRecord) when is_atom(XmlFormat) ->
    AllFormatRecord.
    
    
    
-record(xml_node, {tab="label", type="0, <a /> or 1<a></a>", attr="orderly attr list:[{attr_name, attr_val}]", content="orderly xml node list:[#xml_node{}]"}).
gen_xml(RecordData, XmlFormat, AllXmlFormat) ->
    NodeList = gen_xml2(RecordData, XmlFormat, AllXmlFormat),
    %io:format("NodeList:~w~n~n", [NodeList]),
    gen_xml3(NodeList).
    
gen_xml2(RecordData, [XmlFormat], AllFormatRecord) when erlang:is_list(RecordData) ->
    {content, [ gen_xml2(Record, XmlFormat, AllFormatRecord) || Record <- RecordData]};
gen_xml2(RecordData, XmlFormat, AllFormatRecord) when erlang:is_tuple(RecordData) andalso erlang:is_tuple(XmlFormat) ->
    true = (erlang:element(1, RecordData) =:= erlang:element(1, XmlFormat) andalso erlang:size(RecordData) =:= erlang:size(XmlFormat) ),
    {AttrList, NodeList, Type} = 
        lists:foldl(fun(Index, {Acc1, Acc2, TypeAcc})->
                        case gen_xml2(erlang:element(Index, RecordData), erlang:element(Index, XmlFormat), AllFormatRecord) of
                            {attr, Attr} -> {[Attr|Acc1], Acc2, TypeAcc};
                            {content, Content} -> {Acc1, [Content|Acc2], true}
                        end
                    end, {[], [], false}, lists:seq(erlang:size(XmlFormat), 2, -1) ),
    #xml_node{tab=erlang:element(1, RecordData), type=case Type of true -> 1; _ -> 0 end, attr=AttrList, content=NodeList};
gen_xml2(RecordData, XmlFormat, AllFormatRecord) when erlang:is_atom(XmlFormat) ->
    case erlang:atom_to_list(XmlFormat) of
        "_" ++ _ ->
            {content,
                [begin  
                    FormatRecord = lists:keyfind( erlang:element(1, Record), 1, AllFormatRecord),
                    case FormatRecord of
                        false -> 
                            io:format("error can not found record ~w in AllFormatRecord:~w~n", [Record, AllFormatRecord]),
                            erlang:throw({error, Record});
                        _ -> ok
                    end,
                    gen_xml2(Record, FormatRecord, AllFormatRecord)
                 end|| Record <- RecordData]};
        _ -> 
            {attr, {XmlFormat, RecordData}}
    end;
gen_xml2(RecordData, XmlFormat, _AllFormatRecord) ->
    io:format("error:~w =/= ~w~n", [RecordData, XmlFormat]).

gen_xml3(NodeList) ->
    Head = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n",
    Body = gen_xml3_1(NodeList, 0),
    Head ++ Body.
    
%% type=0: <tab attr=1 attr2=2 />
%% type=1: <tab attr=1 attr2=2 > </tab>
gen_xml3_1([], _Level) ->
    "";
gen_xml3_1([#xml_node{}|_]=L, Level) ->
    lists:foldl(fun(T, Acc)->
                    gen_xml3_1(T, Level+1) ++ Acc
                end, "", lists:reverse(L));
gen_xml3_1(#xml_node{tab=Tab, type=Type, attr=Attr, content=Content}, Level) ->
    StrTab = to_str(Tab),
    TabChars = make_tab(Level), 
    case Type of
        0 ->
            Str = TabChars ++ "<" ++ StrTab ++ " " ++ gen_xml_attr(Attr) ++ "/>\n";
        1 ->
            StrContent =
                lists:foldl(fun(T, Acc)->
                                AddAcc = gen_xml3_1(T, Level+1),
                                AddAcc++ Acc
                            end, "", lists:reverse(Content)),
            case Attr of
                [] -> Str = TabChars ++  "<" ++ StrTab ++ ">\n" ++ StrContent ++ TabChars ++  "</" ++ StrTab ++ ">\n";
                _ -> Str = TabChars ++  "<" ++ StrTab ++ " " ++ gen_xml_attr(Attr) ++ ">\n" ++ StrContent ++ TabChars ++  "</" ++ StrTab ++ ">\n"
            end
    end,
    Str.
make_tab(Level) ->
    string:chars($ , Level*2).
    
gen_xml_attr(AttrList) ->
    lists:foldl(fun({Tab, Val}, Acc) ->
                    to_str(Tab) ++ "=\"" ++ to_str(Val) ++ "\" " ++ Acc
                end, "", lists:reverse(AttrList)).
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
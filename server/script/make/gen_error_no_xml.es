#!/usr/bin/env escript 
%% -*- erlang -*- 
-export([main/1]).

-define(EXIT, halt(1)).
-define(E(A, Y), io:format( "[~w]:" ++  A, [?LINE|Y])).
-define(CHECK_FILE(FILE), case filelib:is_file(FILE) of true -> ok; _ -> ?E("file:~s not exist ~n~n", [FILE]), ?EXIT end).
-define(RE_PATTERN, "^-define[^,]*,[\\s]*([0-9]+)[^%]*%%+\\s*(.+)\\s*$").
-define(PROTO_DIR, "./include/proto/").
-define(OUT_DIR, "./front/xml/ErrorCode.xml").
-define(OLD_FILE, "./include/error_no.hrl").

usage() ->
    ?E("help: \n", []),
    ?E("\t./gen_letter_no_xml.es InputPath OutputPath", []),
    ?E("\n\n\n", []),
    ?EXIT.

main([]) ->
    catch file:delete(?OLD_FILE),
    catch file:delete(?OUT_DIR),

    HeadStr = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" ++
        "<errors>\n",

    TailStr = "</errors>\n",

    {ok, FileList} = file:list_dir_all(?PROTO_DIR),
    BodyStr = lists:foldl(fun(File, Acc) -> gen_file_str(?PROTO_DIR ++ File) ++ Acc end, [], FileList),
    ErrCodeStr =  HeadStr ++ BodyStr ++ TailStr,
    file:write_file(?OUT_DIR, ErrCodeStr, [{encoding,latin1}]),
    ok;
main(_) ->
    usage().

gen_file_str(File) ->
    {ok, S} = file:open(File, [read, {encoding,latin1}]),
    {ok, RePattern} = re:compile(?RE_PATTERN),
    BodyStrList = read_to_eof(io:get_line(S,''), S, RePattern, []),
    file:close(S),
    lists:foldl(fun(TmpStr, AccStr)-> TmpStr ++ AccStr end, "", BodyStrList).

read_to_eof(eof, _S, _RePattern, Res) ->
    Res;
read_to_eof(LineStr, S, RePattern, Res) ->
    case re:run(LineStr, RePattern) of
        {match, [_, {CodeIndex, CodeLen}, {StrIndex, StrLen}]} -> %% 用replace也不错
            CodeStr = string:substr(LineStr, CodeIndex+1, CodeLen),
            StrStr = string:substr(LineStr, StrIndex+1, StrLen),
            case string:substr(StrStr, 1, 5) of
                "alert" ->
                    ShowType = "1",  %% 弹窗提示
                    NewStr = string:substr(StrStr, 6);
                _       ->
                    ShowType = "0",  %% 浮动提示
                    NewStr = StrStr

            end,
            NewLineStr = "    <e id = \"" ++ CodeStr ++ "\"  con=\"" ++ NewStr ++ "\"  show_type=\"" ++ ShowType ++ "\"/>\n",
            NewRes = [ NewLineStr| Res];
        {match, _} =_Err ->
            NewRes = Res,
            ?E("match err: ~p~n", [_Err]);
        _Err ->
            NewRes = Res
    end,
    read_to_eof(io:get_line(S,''), S, RePattern, NewRes).
    

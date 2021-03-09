#!/usr/bin/env escript
%% -*- erlang -*-
-mode(compile).
-include_lib("kernel/include/file.hrl").

-define(EXIT, halt(1)).
-define(GAME_PROTO, "./proto/game_proto.txt").
-define(GAME_LUA_PROTO, "./proto/game_lua_proto.txt").
-define(MSG_PROTO, "./front/proto/proto.proto").
-define(FRONT_MSG_PROTO, "../Protobuf/Proto/proto.proto").

-define(LUA_PROTO_DIR, "../Protobuf_lua/proto/").
-define(LUA_PROTO_ID, "../LuaCode/Conf/LuaProtoCfg.lua").

-define(GAME_PROTO_HRL, "./include/all_pb.hrl").
-define(GPB_MASTER_PATH, "./deps/deps/gpb/").
-define(GPB_ERL_DIR, "./bin/").
-define(GPB_HRL_DIR, "./include/").
-define(GPB_PROTO_NAME, "proto.erl").

-define(GAME_PROTO_ROUTER, "./src/gateway/gateway_proto_router.erl").
-define(GAME_ROBOT_PROTO_ROUTER, "./src/robot/robot_proto_router.erl").
-define(COMMON_ERROR_NO_HRL, "./include/proto/common_error_no.hrl").
-define(SWITCHING_MODULES, "./src/gateway/gateway_switching_modules.erl").
-define(PROTO_HRL_DIR, "./include/proto/").
-define(CSHARP_PROTOS_XML, "./front/xml/Protos.xml"). %% 用来展示
-define(ERROR_CODE_XML_DIR, "./front/xml/ErrorCode.xml"). %% 用来展示

-define(PROTOS_BIN, "./front/bin/Protos.bin").
-define(ERROR_CODE_BIN, "./front/bin/ErrorCode.bin").
-define(FRONT_PROTOS_BIN, "../Assets/Proto/Protos.bin").
-define(FRONT_ERROR_CODE_BIN, "../Assets/Proto/ErrorCode.bin").

%% role模块对应的目录
-define(ROLE_ROOT_DIR, "./src/role/").
-define(ROLE_MOD_DIR, "./src/role/mod/").
-define(ROLE_TEMPLATE_FILE, "./src/role/mod/mod_role_template.erl").
-define(ROLE_MOD_IGNORE_LIST, [mod_role_mact]). %% 部分文件不在src/role/下

-define(TOS_OR_TOC(ID), (ID > 0 andalso ID < 90000)). %% 90000以下为协议
-define(TOS, 1).
-define(TOC, 0).

-define(MAP_KEY_ID,      id).
-define(MAP_KEY_NAME,    name).
-define(MAP_KEY_NOTE,    note).
-define(MAP_KEY_FIELD,   fields).
-define(MAP_KEY_ROUTER,  router).
-define(MAP_KEY_ERRCODE, err_code).

-ifndef(IF).
-define(IF(C, T, F), (case (C) of true -> (T); false -> (F) end)).
-endif.

-record(p_ks,{id=0,str=""}).

main([]) ->
    case filelib:is_file(?GAME_PROTO) andalso filelib:is_file(?GAME_LUA_PROTO) of
        true ->
            gen_all();
        _ ->
            io:format("Error: game.proto file not found ~n"),
            ?EXIT
    end.

gen_all() ->
    io:format("Processing......[please do not close this window!]~n"),
    FunList = [  get_fun_list(N) || N <- lists:seq(1, 4)],
    gen_all2(FunList),
    ok.

gen_all2([]) ->
    ok;
gen_all2([FList|R]) ->
    process_flag(trap_exit,true),
    PidList = [ {erlang:spawn_link(F), Msg} || {F, Msg} <- FList ],
    [] = lists:foldl(fun(_T, Acc)->
        receive
            {'EXIT', Pid, normal} ->
                {_, Msg} = lists:keyfind(Pid, 1, Acc),
                io:format("~s success~n", [Msg]),
                lists:keydelete(Pid, 1, Acc);
            {'EXIT', Pid, Err} ->
                {_, Msg} = lists:keyfind(Pid, 1, Acc),
                io:format("~s error: ~w~n", [Msg, Err]),
                [ catch erlang:exit(P, kill) || {P, _} <- Acc],
                erlang:throw({error, Pid});
            _Err ->
                io:format("~w error~n", [_Err]),
                [ catch erlang:exit(P, kill) || {P, _} <- Acc],
                erlang:throw({error, _Err})
        end
                     end, PidList, PidList),
    process_flag(trap_exit, false),
    gen_all2(R).

get_fun_list(1) ->
    {ok, [{proto_list, ProtoList1}, {common_error_list, ErrorList}]} = file:consult(?GAME_PROTO),
    {ok, [{proto_list, ProtoList2}]} = file:consult(?GAME_LUA_PROTO),
    ProtoList = ProtoList1 ++ ProtoList2,
    {CommonProtoList, HrlList, _RoleModList} = gen_hrl_list(ProtoList),
    [
        {fun() -> check_proto_list(ProtoList) end, "proto checked"},
        {fun() -> gen_proto_game(ProtoList1, ProtoList2) end, "gen_proto_game"},
        {fun() -> gen_lua_proto(ProtoList1, ProtoList2) end, "gen_lua_proto"},
        {fun() -> gen_proto_router(ProtoList) end, "gen_proto_router"},
        {fun() -> gen_robot_proto_router(ProtoList) end, "gen_robot_proto_router"},
        {fun() -> gen_switching_modeules(ProtoList) end, "gen_switching_modeules"},

        {fun() -> gen_all_pb_hrl(CommonProtoList) end, "gen_all_pb_hrl"},
        {fun() -> gen_error_no(CommonProtoList, ErrorList) end,   "gen_error_no"},
        {fun() -> gen_proto_hrl(HrlList) end, "gen_proto_hrls"}
        %{fun() -> gen_mod(RoleModList) end, "gen_mod"}
    ];
get_fun_list(2) -> %%这个会依赖上面相关的生成
    Path = filename:dirname(filename:absname(escript:script_name())),
    TrunkPath = Path ++ "/../../",
    GpbPath = TrunkPath ++ ?GPB_MASTER_PATH,
    EbinPath = GpbPath++ "ebin/",
    code:add_path(EbinPath),
    code:add_path(TrunkPath ++ "ebin/"),
    Args = [
        "-I. ", TrunkPath ++ ?MSG_PROTO,
        "-o-erl", GpbPath ++ ?GPB_ERL_DIR,
        "-o-hrl", GpbPath ++ ?GPB_HRL_DIR,
        "-type-defaults-for-omitted-optionals"],
    [
        {fun() ->
            case gpb_compile:parse_opts_and_args(Args) of
                {ok, {Opts, Files}} ->
                    ok = gpb_compile:c(Opts, Files);
                {error, Reason} ->
                    io:format("Error: ~s.~n", [Reason])
            end
         end, "gen proto.erl  gen proto.hrl"
        }
    ];
get_fun_list(3) -> %%这个会依赖上面相关的生成
    Path = filename:dirname(filename:absname(escript:script_name())),
    TrunkPath = Path ++ "/../../",
    GpbPath = TrunkPath ++ ?GPB_MASTER_PATH,
    [
        {fun() ->
            Opts = [
                {outdir, TrunkPath ++ "ebin"},
                {i, GpbPath ++ "include"},
                {inline_size, 30},
                report,
                warnings_as_errors,
                verbose,
                {d, 'TEST'},
                debug_info],
            {ok, _Name} = compile:file(GpbPath ++ ?GPB_ERL_DIR ++ ?GPB_PROTO_NAME, Opts)
         end, "compile proto.erl"
        }
    ];
get_fun_list(4) -> %%这个会依赖上面相关的生成
    {ok, [{proto_list, ProtoList1}, {common_error_list, ErrorList}]} = file:consult(?GAME_PROTO),
    {ok, [{proto_list, ProtoList2}]} = file:consult(?GAME_LUA_PROTO),
    ProtoList = ProtoList1 ++ ProtoList2,
    [
        {fun() -> gen_protos_xml_and_bin(ProtoList1) end, "gen_protos_xml_and_bin"},
        {fun() -> gen_lua_protos_bin(ProtoList2) end, "gen_lua_protos_bin"},
        {fun() -> gen_error_no_xml_and_bin(ProtoList, ErrorList) end, "gen_error_no_xml"}
    ].

write_file(FileName, Bytes, Modes) ->
    write_file(FileName, Bytes, Modes, true).
write_file(FileName, Bytes, Modes, IsPrint) ->
    filelib:ensure_dir(FileName),
    Content = to_binary(Bytes),
    case file:read_file(FileName) of
        {ok, Content} ->
            ?IF(IsPrint, io:format("~s has not changed\t", [filename:basename(FileName)]), ok);
        _ ->
            file:write_file(FileName, Bytes, Modes)
    end.

%%======================== 生成proto.proto start ==============================
gen_proto_game(ProtoList1, ProtoList2) ->
    Code = [gen_proto_game2(Map) || Map <- ProtoList1],
    Code2 = [gen_proto_game2(Map) || Map <- ProtoList2],
    %% 后端用的proto文件
    write_file(?MSG_PROTO, lists:flatten(Code ++ Code2), [{encoding, latin1}]),

    %% 前端用的proto文件
    write_file(?FRONT_MSG_PROTO, lists:flatten(Code), [{encoding, latin1}]),
    ok.

%% message xxxx {
%% xxx xxxx = 1,
%% xxx xxxx = 2}
gen_proto_game2(Map) ->
    Head = "message ",
    case maps:find(?MAP_KEY_NOTE, Map) of
        {ok, Desc1} ->
            Desc = "// " ++ get_note(Desc1) ++ "\r\n";
        _ ->
            Desc = ""
    end,
    Name = get_map_name(Map),
    case maps:find(?MAP_KEY_FIELD, Map) of
        {ok, Fields} ->
            {Context, _Index} = gen_proto_game3(Fields);
        _ ->
            Context = ""
    end,
    lists:flatten([Desc, Head, to_list(Name), " {\r\n", Context, "}\r\n\r\n"]).

gen_proto_game3(Fields) ->
    lists:foldl(
        fun(Field, {Acc2, Index}) ->
            case Field of
                {Name, Type, Default, Note} ->
                    next;
                {Name, Type, Note} ->
                    Default = undefined
            end,
            case Note of
                [_|_] -> Note1 = lists:flatten(["//", get_note(Note)]);
                _ -> Note1 = ""
            end,
            Content = get_field_type(Type) ++ "  " ++ to_list(Name) ++ "=" ++ to_list(Index) ++ get_proto_field_default(Type, Default) ++ "; " ++ Note1 ++ "\r\n",
            {Content ++ Acc2, Index - 1}
        end, {"", erlang:length(Fields)}, lists:reverse(Fields)).
%%======================== 生成proto.proto  end ==============================

%%======================== 生成Protobuf_lua/proto/ start ==============================
gen_lua_proto(ProtoList1, ProtoList2) ->
    NeedPRecords =
        lists:foldl(
            fun(Map, Acc) ->
                {MapName, ImportNames, Code, IsPRecord} = gen_lua_proto2(Map),
                case IsPRecord of
                    true ->
                        lib_tool:list_filter_repeat([MapName|Acc] ++ ImportNames);
                    _ ->
                        write_file(?LUA_PROTO_DIR ++ to_list(MapName) ++ ".proto", Code, [{encoding, latin1}], false),
                        lib_tool:list_filter_repeat(Acc ++ ImportNames)
                end
            end, [], ProtoList2),
    AllPRecords = [ Map || Map <- ProtoList2 ++ ProtoList1, not ?TOS_OR_TOC(get_map_id(Map))],
    GenPRecords = get_gen_records(NeedPRecords, AllPRecords, []),
    [ begin
          {Name, _ImportName, Code, _IsPRecord} = gen_lua_proto2(Map),
          write_file(?LUA_PROTO_DIR ++ to_list(Name) ++ ".proto", Code, [{encoding, latin1}], false)
      end|| Map <- GenPRecords],
    ok.

%% message xxxx {
%% xxx xxxx = 1,
%% xxx xxxx = 2}
gen_lua_proto2(Map) ->
    Head = "message ",
    case maps:find(?MAP_KEY_NOTE, Map) of
        {ok, Desc1} ->
            Desc = "// " ++ get_note(Desc1) ++ "\r\n";
        _ ->
            Desc = ""
    end,
    ID = get_map_id(Map),
    Name = get_map_name(Map),
    case maps:find(?MAP_KEY_FIELD, Map) of
        {ok, Fields} ->
            {Imports, ImportNames, Content, _Index} = gen_lua_proto3(Fields);
        _ ->
            ImportNames = [],
            Imports = Content = ""
    end,
    {Name, ImportNames, lists:flatten([Imports, Desc, Head, to_list(Name), " {\r\n", Content, "}\r\n\r\n"]), not ?TOS_OR_TOC(ID)}.

gen_lua_proto3(Fields) ->
    lists:foldl(
        fun(Field, {ImportAcc, ImportNames, ContentAcc, Index}) ->
            case Field of
                {Name, Type, Default, Note} ->
                    next;
                {Name, Type, Note} ->
                    Default = undefined
            end,
            case Note of
                [_|_] -> Note1 = lists:flatten(["//", get_note(Note)]);
                _ -> Note1 = ""
            end,
            Content = get_field_type(Type) ++ "  " ++ to_list(Name) ++ "=" ++ to_list(Index) ++ get_proto_field_default(Type, Default) ++ "; " ++ Note1 ++ "\r\n",
            {ImportAcc2, ImportNames2} = get_lua_proto_import(Type, ImportNames),
            {ImportAcc2 ++ ImportAcc, ImportNames2, Content ++ ContentAcc, Index - 1}
        end, {"", [], "", erlang:length(Fields)}, lists:reverse(Fields)).

get_gen_records([], AllPRecords, NameList) ->
    [ get_map_by_name(MapName, AllPRecords) || MapName <- lib_tool:list_filter_repeat(NameList)];
get_gen_records([Name|R], AllPRecords, NameListAcc) ->
    Map = get_map_by_name(Name, AllPRecords),
    NameListAcc2 = [Name|NameListAcc],
    case maps:find(?MAP_KEY_FIELD, Map) of
        {ok, Fields} ->
            NameList = get_gen_records2(Fields, AllPRecords, []),
            get_gen_records(R, AllPRecords, lib_tool:list_filter_repeat(NameList ++ NameListAcc2));
        _ ->
            get_gen_records(R, AllPRecords, lib_tool:list_filter_repeat(NameListAcc2))
    end.

get_gen_records2([], _AllPRecords, NameList) ->
    lib_tool:list_filter_repeat(NameList);
get_gen_records2([Field|R], AllPRecords, NameListAcc) ->
    Type =
        case Field of
            {_Name, FieldType, _Default, _Note} ->
                FieldType;
            {_Name, FieldType, _Note} ->
                FieldType
        end,
    NameList = get_gen_records3(Type, AllPRecords),
    get_gen_records2(R, AllPRecords, NameList ++ NameListAcc).

get_gen_records3([Type], AllPRecords) ->
    get_gen_records3(Type, AllPRecords);
get_gen_records3(Type, AllPRecords) ->
    case Type of
        bool ->
            [];
        int64 ->
            [];
        int32 ->
            [];
        string ->
            [];
        _ ->
            Map = get_map_by_name(Type, AllPRecords),
            case maps:find(?MAP_KEY_FIELD, Map) of
                {ok, Fields} ->
                    get_gen_records2(Fields, AllPRecords, [Type]);
                _ ->
                    [Type]
            end
    end.

get_map_by_name(MapName, []) ->
    io:format("MapName not found: ~w", [MapName]),
    ?EXIT;
get_map_by_name(MapName, [Map|R]) ->
    case MapName =:= get_map_name(Map) of
        true ->
            Map;
        _ ->
            get_map_by_name(MapName, R)
    end.

%%======================== 生成Protobuf_lua/proto/ end ==============================

%%======================== 生成all_pb.hrl  start ==============================
gen_all_pb_hrl(ProtoList) ->
    Code = gen_record_fields(ProtoList),
    Content = erlang:list_to_binary(["-ifndef(ALL_PB_HRL).\n-define(ALL_PB_HRL, true).\n", Code, "\n-endif."]),
    write_file(?GAME_PROTO_HRL, Content, [{encoding, utf8}]),
    ok.

gen_record_fields(ProtoList) ->
    lists:foldr(
        fun(Map, Acc) ->
            {ok, Name} = maps:find(?MAP_KEY_NAME, Map),
            case maps:find(?MAP_KEY_FIELD, Map) of
                {ok, Fields} ->
                    ok;
                _ ->
                    Fields = []
            end,
            lists:concat(["-record(", Name, ",{", gen_record_fields2(Fields), "}).\n", Acc])
        end, [], ProtoList).

gen_record_fields2(Fields) ->
    lists:foldl(
        fun(Field, Acc) ->
            Header = ?IF(Acc =:= [], "", ","),
            case Field of
                {Name, Type, Default, _Note} ->
                    next;
                {Name, Type, _Note} ->
                    Default = get_field_default(Type)
            end,
            Default2 = to_string(Type, Default),
            Code = ?IF(Default =:= undefined, lists:concat([Header, Name]), lists:concat([Header, Name, "=", to_string(Default2)])),
            lists:concat([Acc, Code])
        end, [], Fields).

%%======================== 生成all_pb.hrl  end ==============================

%%======================== 生成gateway_proto_router.erl  start ==============================
gen_proto_router(ProtoList) ->
    Head = "%% ---------------------------------------------------------
%% This file is generated by script,please do not vim it
%% ---------------------------------------------------------
-module(gateway_proto_router).
-compile(export_all).

",
    {Map1, Map2} =
        lists:foldl(
            fun(Map, {Acc1, Acc2}) ->
                ID = get_map_id(Map),
                case ?TOS_OR_TOC(ID) of
                    true ->
                        case ID rem 2 of
                            ?TOS ->
                                Router = get_map_router(Map),
                                case  Router == {} of
                                    true ->
                                        {Acc1, Acc2};
                                    _ ->
                                        Router2 = get_router_value(Router),
                                        TosMap = io_lib:format("get_map(~s) -> {~s,~s};~n", [to_list(get_map_id(Map)), to_list(get_map_name(Map)), Router2]),
                                        {[TosMap|Acc1], Acc2}
                                end;
                            ?TOC ->
                                TocMap = io_lib:format("get_protoid(~s) -> ~s;~n", [to_list(get_map_name(Map)), to_list(get_map_id(Map))]),
                                {Acc1, [TocMap|Acc2]}
                        end;
                    false ->
                        {Acc1, Acc2}
                end
            end, {[], []}, ProtoList),
    T1 = "get_map(_) -> map.

",
    T2 = "get_protoid(Info) -> Info.

",
    Code = lists:flatten(lists:concat([Head, lists:reverse(Map1), T1, lists:reverse(Map2), T2])),
    write_file(?GAME_PROTO_ROUTER, Code, [{encoding, utf8}]),
    ok.
%%======================== 生成gateway_proto_router.erl  end ==============================

%%======================== 生成error_no.hrl  start ==============================
gen_error_no(ProtoList, ErrorList) ->
    Header = "%% coding: latin-1\n%% created by script, do not edit it\n\n-ifndef(COMMON_ERROR_NO_HRL).\n-define(COMMON_ERROR_NO_HRL, common_error_no_hrl).\n\n",
    CommonList =
        lists:foldr(
            fun(Error, Acc) ->
                {Code, Name, Note} =
                    case Error of
                        {CodeT, NameT, NoteT} -> {CodeT, NameT, NoteT};
                        {CodeT, NameT, NoteT, _ShowType} -> {CodeT, NameT, NoteT}
                    end,
                lists:concat(["-define(", Name, ", ", Code, "). %%", get_note(Note), "\n"]) ++ Acc
            end, [], ErrorList),
    NormalList = gen_error_define(ProtoList),
    End = "-endif.",
    Code = Header ++ CommonList ++ NormalList ++ End,
    Content = erlang:list_to_binary(Code),
    write_file(?COMMON_ERROR_NO_HRL, Content, [{encoding, latin1}]).

gen_error_define(ProtoList) ->
    lists:foldr(
        fun(Map, Acc2) ->
            ID = get_map_id(Map),
            case ?TOS_OR_TOC(ID) andalso ID rem 2 =:= ?TOC of
                true ->
                    case maps:find(?MAP_KEY_ERRCODE, Map) of
                        {ok, [_|_] = ErrorCodeList} -> %% 不为空列表时才继续
                            gen_error_define2(ErrorCodeList, to_list(get_map_name(Map)), ID) ++ "\n" ++ Acc2;
                        _ ->
                            Acc2
                    end;
                _ ->
                    Acc2
            end
        end, [], ProtoList).

gen_error_define2(ErrorList, Name, ID) ->
    ErrorName = to_error_no_header(Name),
    lists:foldr(
        fun(Error, Acc) ->
            {Num, Note} =
                case Error of
                    {NumT, NoteT} -> {NumT, NoteT};
                    {NumT, NoteT, _ShowType} -> {NumT, NoteT}
                end,
            DestName = to_error_no_header2(ErrorName, Num),
            lists:concat(["-define(", DestName, ", ", ID * 1000 + Num, "). %%", get_note(Note), "\n"]) ++ Acc
        end, [], ErrorList).

to_error_no_header(TocName) ->
    {ok, Pattern} = re:compile("m_(.*)_toc"),
    case re:run(TocName, Pattern, [global, {capture, all, list}]) of
        {_,[[_, Name]]} ->
            "ERROR_" ++ string:to_upper(Name) ++ "_";
        _ ->
            "ERROR_" ++ string:to_upper(to_list(TocName)) ++ "_"
    end.

to_error_no_header2(Header, Num) ->
    if Num >= 100 ->
        Add = 0;
        Num >= 10 ->
            Add = 1;
        true ->
            Add = 2
    end,
    Header ++ lists:concat(lists:duplicate(Add, "0")) ++ to_list(Num).

%%======================== 生成error_no.hrl  end ==============================
%%======================== 生成robot_proto_router.erl start ==============================
gen_robot_proto_router(ProtoList) ->
    Head = "-module(robot_proto_router).\n-export([find/1]).\n\n",
    MapStr =
        lists:foldl(fun(Map, Acc) ->
            ID = get_map_id(Map),
            case ?TOS_OR_TOC(ID) of
                true ->
                    case ID rem 2 of
                        ?TOS -> io_lib:format("find(~p) -> ~p;\n", [get_map_name(Map), ID]) ++ Acc;
                        ?TOC -> io_lib:format("find(~p) -> ~p;\n", [get_map_id(Map), get_map_name(Map)]) ++ Acc
                    end;
                _ -> %% p结构
                    Acc
            end
                    end, "", ProtoList),
    Tail = "find(P) -> P.\n",
    Code = lists:flatten([Head, MapStr, Tail]),
    write_file(?GAME_ROBOT_PROTO_ROUTER, Code, [{encoding, utf8}]),
    ok.
%%======================== 生成robot_proto_router.erl end ==============================

%%======================== 生成模块映射到tos（用于功能屏蔽快速拿到协议） start ==============================
gen_switching_modeules(ProtoList) ->
    Head = "%% ---------------------------------------------------------
%% This file is generated by script,please do not vim it
%% ---------------------------------------------------------
-module(gateway_switching_modules).
-export([find/1]).

",
    {AllModules, ModTos} =
        lists:foldl(
            fun(Map, {Acc1, Acc2}) ->
                ID = get_map_id(Map),
                case ?TOS_OR_TOC(ID) of
                    true ->
                        case ID rem 2 of
                            ?TOS ->
                                Router = get_map_router(Map),
                                case  Router == {} of
                                    true ->
                                        {Acc1, Acc2};
                                    _ ->
                                        NewAcc1 =
                                            case lists:member(Router, Acc1) of
                                                true -> Acc1;
                                                _ -> [ Router |Acc1]
                                            end,
                                        NewAcc2 =
                                            case lists:keyfind(Router, 1, Acc2) of
                                                {_, OldTosList} -> lists:keyreplace(Router, 1, Acc2, {Router, [ get_map_name(Map) | OldTosList ]});
                                                false -> [{Router, [get_map_name(Map)]}|Acc2]
                                            end,
                                        {NewAcc1, NewAcc2}
                                end;
                            ?TOC ->
                                {Acc1, Acc2}
                        end;
                    false ->
                        {Acc1, Acc2}
                end
            end, {[], []}, ProtoList),
    Body0 = "\nfind(_) -> undefined.\n",
    Body1 = io_lib:format("\n\nfind(~s) -> ~p;\n", [all_modules, AllModules]),
    Body =
        lists:foldl(fun({Mod, Tos}, AccStr)->
            io_lib:format("find(~p) -> ~p;\n", [Mod, Tos]) ++ AccStr
                    end, Body1 ++ Body0, ModTos),
    Code = lists:flatten(lists:concat([Head, Body])),
    write_file(?SWITCHING_MODULES, Code, [{encoding, utf8}]),
    ok.
%%======================== 生成模块映射到tos（用于功能屏蔽快速拿到协议） end ==============================

%%======================== 生成proto_xxx.hrl start ==============================
gen_proto_hrl(HrlList) ->
    filelib:ensure_dir(?PROTO_HRL_DIR),
    lists:foreach(
        fun({HrlName, ProtoList}) ->
            HrlNameUpcase = string:to_upper(to_list(HrlName)),
            IfDefine = io_lib:format("-ifndef(~s_HRL).\n-define(~s_HRL, true).\n", [HrlNameUpcase, HrlNameUpcase]),
            RecordList = gen_record_fields(ProtoList),
            ErrorList = gen_error_define(ProtoList),
            Content = "%% coding: latin-1\n%% created by script, do not edit it\n\n"++ IfDefine ++ ErrorList ++ RecordList ++ "-endif.",
            Content2 = erlang:list_to_binary(Content),
            FileName = lists:concat([?PROTO_HRL_DIR, to_list(HrlName), ".hrl"]),
            write_file(FileName, Content2, [{encoding, latin1}], false)
        end, HrlList),
    ok,
    %%删除当前proto下旧的hrl
    {ok, FileList} = file:list_dir_all(?PROTO_HRL_DIR),
    lists:foreach(
        fun(File) ->
            FileAtom = get_file_atom(File),
            case lists:keyfind(FileAtom, 1, HrlList) of
                {_, _} -> ignore;
                _ ->
                    DeleteFile = ?PROTO_HRL_DIR ++ File,
                    case DeleteFile =:= ?COMMON_ERROR_NO_HRL of %% common_error_no.hrl不能删除
                        true ->
                            ignore;
                        _ ->
                            file:delete(?PROTO_HRL_DIR ++ File)
                    end
            end
        end, FileList).

get_file_atom(File) ->
    [List|_] = string:tokens(File, "."),
    erlang:list_to_atom(List).

%%======================== 生成proto_xxx.hrl end ================================

%%======================== 生成gen_mod start =================================
%%gen_mod(RoleModList) ->
%%    Env = os:getenv("GEN_PROTO_TEMPLATE"),
%%    case Env =:= "false" orelse Env =:= "FALSE" of
%%        true ->
%%            io:format("skip gen mod\n");
%%        _ ->
%%            AllRoleFile = get_file_list([?ROLE_ROOT_DIR], [], []),
%%            lists:foreach(
%%                fun({Mod, TosList}) ->
%%                    FileName = to_list(Mod) ++ ".erl",
%%                    case lists:member(FileName, AllRoleFile) of
%%                        true -> ignore; %% 文件已经存在了，忽略之
%%                        _ ->
%%                            gen_mod2(Mod, FileName, TosList)
%%                    end
%%                end, RoleModList),
%%            ok
%%    end.
%%
%%gen_mod2(Mod, FileName, TosList) ->
%%    %% 根据src/role/mod/mod_role_template.erl的模版，替换关键字
%%    {ok, FileBinary} = file:read_file(?ROLE_TEMPLATE_FILE),
%%    FileModule = lists:concat(["-module(", to_list(Mod), ").\n"]),
%%    Include = lists:concat(["-include(\"proto/", to_list(Mod), ".hrl\")."]),
%%    Re = get_file_re("-module(mod_role_template).", []),
%%    Re2 = get_file_re("do_handle(Info)", []),
%%    {TosCode, FunCode} = get_tos_fun_code(TosList, [], []),
%%
%%    FileList = re:replace(FileBinary, Re, FileModule ++ Include, [{return, list}, global]),
%%    FileList2 = re:replace(FileList, "^" ++ Re2, TosCode ++ "do_handle(Info)", [{return, list}, global, multiline]),
%%    write_file(?ROLE_MOD_DIR ++ FileName, FileList2 ++ FunCode, [{encoding, latin1}]),
%%    ok.
%%
%%get_file_list([], _RootDir, FileList) ->
%%    FileList;
%%get_file_list([T|R], RootDir, FileAcc) ->
%%    Cur = RootDir ++ T,
%%    case filelib:is_dir(Cur) of
%%        true ->
%%            {ok, List} = file:list_dir_all(Cur),
%%            FileAcc2 = get_file_list(List, Cur ++ "/", []);
%%        _ ->
%%            FileAcc2 = [T]
%%    end,
%%    get_file_list(R, RootDir, FileAcc2 ++ FileAcc).
%%
%%get_file_re([], Acc) ->
%%    lists:reverse(lists:flatten(Acc));
%%get_file_re([$(|R], Acc) ->
%%    get_file_re(R, ["(\\"|Acc]);
%%get_file_re([$)|R], Acc) ->
%%    get_file_re(R, [")\\"|Acc]);
%%get_file_re([$_|R], Acc) ->
%%    get_file_re(R, ["_\\"|Acc]);
%%get_file_re([$.|R], Acc) ->
%%    get_file_re(R, ["\.\\"|Acc]);
%%get_file_re([T|R], Acc) ->
%%    get_file_re(R, [T|Acc]).
%%
%%get_tos_fun_code([], TosCode, FunCode) ->
%%    FunCode2 = "\n\n%%Internal Functions\n" ++ FunCode,
%%    {TosCode, FunCode2};
%%get_tos_fun_code([T|R], TosCode, FunCode) ->
%%    TosName = to_list(T),
%%    {ok, Pattern} = re:compile("m_(.*)_tos"),
%%    case re:run(TosName, Pattern, [global, {capture, all, list}]) of
%%        {_,[[_, FunName]]} ->
%%            Fun = lists:concat(["do_", FunName, "(RoleID, DataIn)"]),
%%            TosCode2 = [lists:concat(["do_handle({#", TosName, "{} = DataIn, RoleID, _PID}) ->\n    ", Fun, ";\n"])|TosCode],
%%            FunCode2 = [lists:concat([Fun, "->\n    ", "{RoleID, DataIn}.\n"])|FunCode],
%%            get_tos_fun_code(R, TosCode2, FunCode2);
%%        _ ->
%%            get_tos_fun_code(R, TosCode, FunCode)
%%    end.
%%======================== 生成gen_mod end =================================

%%======================== 生成Protos.xml start  ==============================
gen_protos_xml_and_bin(ProtoList) ->
    Head = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<Root>\n\t<Protos>\n",
    {MapStr, KSList} =
        lists:foldl(
            fun(Map, {Acc1, Acc2}) ->
                ID = get_map_id(Map),
                case ?TOS_OR_TOC(ID) of
                    true ->
                        {io_lib:format("         <Proto id=\"~w\" name=\"~s\"/>\n", [ID, to_list(get_map_name(Map))]) ++ Acc1,
                            [#p_ks{id = ID, str = to_list(get_map_name(Map))}|Acc2]};
                    _ -> %% p结构
                        {Acc1, Acc2}
                end
            end, {[], []}, ProtoList),
    Tail = "\t</Protos>\n</Root>",
    Code = lists:flatten([Head, MapStr, Tail]),
    write_file(?CSHARP_PROTOS_XML, Code, [{encoding, latin1}]),
    Bin = proto:encode_msg({c_proto_id, KSList}),
    write_file(?PROTOS_BIN, Bin, [{encoding, latin1}]),
    write_file(?FRONT_PROTOS_BIN, Bin, [{encoding, latin1}]),
    ok.
%%======================== 生成Protos.xml end  ==============================

%%======================== 生成Protos.xml start  ==============================
gen_lua_protos_bin(ProtoList) ->
    Head = "--Phantom\n--Not Edit\nLuaProtoCfg={}\nlocal We=LuaProtoCfg\n",
    IDList =
        lists:foldl(
            fun(Map, Acc1) ->
                ID = get_map_id(Map),
                case ?TOS_OR_TOC(ID) of
                    true ->
                        [{ID, Map}|Acc1];
                    _ -> %% p结构
                        Acc1
                end
            end, [], ProtoList),
    MapStr = lists:flatten([ io_lib:format("We[#We+1]={id=~w, ty=\"~s\"}\n", [ID, to_list(get_map_name(Map))])|| {ID, Map} <- lists:keysort(1, IDList)]),
    Code = lists:flatten([Head, MapStr]),
    write_file(?LUA_PROTO_ID, Code, [{encoding, latin1}]),
    ok.
%%======================== 生成Protos.xml end  ==============================

%%======================== 生成ErrorCode.xml start ==============================
gen_error_no_xml_and_bin(ProtoList, ErrorList) ->
    HeadStr = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<Root>\n\t<errors>\n",

    TailStr = "\t</errors>\n</Root>",
    CommonErrXml = [gen_error_no_xml2(E) || E <- ErrorList],
    CommonErrList = [#p_ks{id = ErrCode, str = lib_tool:to_unicode(get_note(Note))} || {ErrCode, _Name, Note} <- ErrorList],
    {ModErr, KSList} =
        lists:foldl(
            fun(Map, {Acc1, Acc2})->
                ID = get_map_id(Map),
                case maps:find(?MAP_KEY_ERRCODE, Map) of
                    {ok, [_|_] = ErrorCodeList} ->
                        {Error, List} =
                            lists:foldl(
                                fun(E1, {Acc3, Acc4}) ->
                                    {Num, Note} = E1,
                                    ErrCode = ID * 1000 + Num,
                                    {[gen_error_no_xml2({ErrCode, [], Note})|Acc3], [#p_ks{id = ErrCode, str = lib_tool:to_unicode(get_note(Note))}|Acc4]}
                                end, {[], []}, ErrorCodeList),
                        {Error ++ Acc1, List ++ Acc2};
                    _ ->
                        {Acc1, Acc2}
                end
            end, {[], []}, ProtoList),
    File = HeadStr ++ CommonErrXml ++ ModErr ++ TailStr,
    write_file(?ERROR_CODE_XML_DIR, File, [{encoding,latin1}]),
    Bin = proto:encode_msg({c_error_id, CommonErrList ++ KSList}),
    write_file(?ERROR_CODE_BIN, Bin, [{encoding, latin1}]),
    write_file(?FRONT_ERROR_CODE_BIN, Bin, [{encoding, latin1}]).

-define(DEFAULT_SHOW_TYPE, 0).
-define(ALERT_SHOW_TYPE, 1).
gen_error_no_xml2({Code, _Name, [_|_] = Note}) ->
    io_lib:format("\t\t<e id = \"~p\"  con=\"~s\"  show_type=\"~p\"/>\n", [Code, get_note(Note), ?DEFAULT_SHOW_TYPE]);
gen_error_no_xml2({Code, _Name, [_|_] = Note, ShowType}) ->
    io_lib:format("\t\t<e id = \"~p\"  con=\"~s\"  show_type=\"~p\"/>\n", [Code, get_note(Note), get_error_show_type(ShowType)]);
gen_error_no_xml2(_) ->
    [].

get_error_show_type(alert)->
    ?ALERT_SHOW_TYPE;
get_error_show_type(_)->
    ?DEFAULT_SHOW_TYPE.

%%======================== 生成ErrorCode.xml end ================================

to_list(List) when erlang:is_list(List) ->
    List;
to_list(Int) when erlang:is_integer(Int) ->
    erlang:integer_to_list(Int);
to_list(Binary) when erlang:is_binary(Binary) ->
    erlang:binary_to_list(Binary);
to_list(Atom) when erlang:is_atom(Atom) ->
    erlang:atom_to_list(Atom).

to_string([]) ->
    "[]";
to_string(Default) ->
    to_list(Default).

to_string(string, "") ->
    "\"\"";
to_string(_Type, Default) ->
    to_string(Default).

get_map_name(Map) ->
    {ok, Name} = maps:find(?MAP_KEY_NAME, Map),
    Name.
get_map_id(Map) ->
    {ok, ID} = maps:find(?MAP_KEY_ID, Map),
    ID.
get_map_router(Map) ->
    {ok, Router} = maps:find(?MAP_KEY_ROUTER, Map),
    Router.

get_router_value(Router) when erlang:is_atom(Router) ->
    to_string(Router);
get_router_value(Router) ->
    case Router of
        {Value} ->
            to_string(Value);
        {Value, Mod} ->
            "{" ++ to_string(Value) ++ "," ++ to_string(Mod) ++ "}";
        _ ->
            to_list(Router)
    end.

get_field_type([Type]) ->
    "repeated  " ++ to_list(Type);
get_field_type( Type ) ->
    "optional  " ++ to_list(Type).

get_field_default(Type) when erlang:is_list(Type) ->
    [];
get_field_default(Type) ->
    case Type of
        bool ->
            true;
        int64 ->
            0;
        int32 ->
            0;
        string ->
            "";
        _ ->
            undefined
    end.

get_proto_field_default(Type, _Default) when erlang:is_list(Type) ->
    "";
get_proto_field_default(Type, Default) ->
    case Type of
        bool ->
            ?IF(Default =:= undefined orelse Default =:= "", get_proto_field_default2(true), get_proto_field_default2(Default));
        int64 ->
            ?IF(Default =:= undefined orelse Default =:= "", get_proto_field_default2(0), get_proto_field_default2(Default));
        int32 ->
            ?IF(Default =:= undefined orelse Default =:= "", get_proto_field_default2(0), get_proto_field_default2(Default));
        string ->
            "";
        _ ->
            ""
    end.

get_proto_field_default2(Value) ->
    "[default=" ++ to_list(Value) ++ "]".

get_lua_proto_import([Type], ImportNames) ->
    get_lua_proto_import(Type, ImportNames);
get_lua_proto_import(Type, ImportNames) ->
    case Type of
        bool ->
            {"", ImportNames};
        int64 ->
            {"", ImportNames};
        int32 ->
            {"", ImportNames};
        string ->
            {"", ImportNames};
        _ ->
            case lists:member(Type, ImportNames) of
                true ->
                    {"", ImportNames};
                _ ->
                    {"import \"" ++ to_list(Type) ++ ".proto\";\n", [Type|ImportNames]}
            end
    end.

get_note(Note) ->
    NoteList = to_list(Note),
    NoteList1 = string:strip(NoteList, left, $/),
    case NoteList1 of
        [_|_] ->
            NoteList2 = re:replace(NoteList1, "\"", "", [{return, list}, global]),
            NoteList3 = re:replace(NoteList2, "\<", "", [{return, list}, global]),
            NoteList4 = re:replace(NoteList3, "\>", "", [{return, list}, global]),
            NoteList5 = re:replace(NoteList4, "\/", "", [{return, list}, global]),
            NoteList6 = re:replace(NoteList5, [13], "", [{return, list}, global]); %%反斜杠。。。
        _ -> NoteList6 = NoteList1
    end,
    NoteList6.
%%=============================
check_proto_list(ProtoList) ->
    lists:foreach(fun(Map) ->
        case erlang:is_map(Map) of
            true ->
                case maps:find(?MAP_KEY_NAME, Map) of
                    {ok, Name} -> ok;
                    _ ->
                        Name = "",
                        io:format("Name Empty   Map:~w~n", [Map]),
                        ?EXIT
                end,
                case maps:find(?MAP_KEY_ID, Map) of
                    {ok, ID} -> ok;
                    _ ->
                        ID = 0,
                        io:format("id Empty   Map:~w~n", [Map]),
                        ?EXIT
                end,
                case ?TOS_OR_TOC(ID) of
                    true ->
                        case ID rem 2 of
                            ?TOS ->
                                case maps:find(?MAP_KEY_ID, Map) of
                                    {ok, _} -> ok;
                                    _ ->
                                        io:format("id Empty  Name:~s~n", [to_list(Name)]),
                                        ?EXIT
                                end,
                                case maps:find(?MAP_KEY_ROUTER, Map) of
                                    {ok, _} -> ok;
                                    _ ->
                                        io:format("router Empty  Name:~s~n", [to_list(Name)]),
                                        ?EXIT
                                end;
                            ?TOC ->
                                case maps:find(?MAP_KEY_ID, Map) of
                                    {ok, _} -> ok;
                                    _ ->
                                        io:format("id Empty  Name:~s~n", [to_list(Name)]),
                                        ?EXIT
                                end
                        end;
                    false ->
                        case maps:find(?MAP_KEY_ID, Map) of
                            {ok, _} -> ok;
                            _ ->
                                io:format("id Empty  Name:~s~n", [to_list(Name)]),
                                ?EXIT
                        end,
                        case maps:find(?MAP_KEY_NOTE, Map) of
                            {ok, _} -> ok;
                            _ ->
                                io:format("note Empty  Name:~s~n", [to_list(Name)]),
                                ?EXIT
                        end,
                        case maps:find(?MAP_KEY_FIELD, Map) of
                            {ok, _} -> ok;
                            _ ->
                                io:format("fields Empty  Name:~s~n", [to_list(Name)]),
                                ?EXIT
                        end
                end;
            _ ->
                io:format("Not Map Type:  ~w~n", [Map]),
                ?EXIT
        end end, ProtoList).

gen_hrl_list(ProtoList) ->
    {OtherList, RoleModList} =
        lists:foldl(
            fun(Map, {OtherAcc, RoleModAcc}) ->
                case maps:find(?MAP_KEY_ROUTER, Map) of
                    {ok, Router} ->
                        HrlName = get_hrl_name(Router),
                        set_hrl_list(HrlName, [Map|get_hrl_list(HrlName)]),
                        RoleModAcc2 = get_role_mod(Map, Router, RoleModAcc),
                        {OtherAcc, RoleModAcc2};
                    _ ->
                        {[Map|OtherAcc], RoleModAcc}
                end
            end, {[], []}, ProtoList),
    HrlList = erlang:erase(),
    RoleModList2 = del_ignore_list(?ROLE_MOD_IGNORE_LIST, RoleModList),
    {OtherList, HrlList, RoleModList2}.

get_hrl_name(Router) ->
    case Router of
        {Value} ->
            Value;
        {_Value, Mod} ->
            Mod;
        _ ->
            Router
    end.

get_hrl_list(HrlName) ->
    case erlang:get(HrlName) of
        [_|_] = List -> List;
        _ -> []
    end.
set_hrl_list(HrlName, List) ->
    erlang:put(HrlName, List).

get_role_mod(Map, Router, RoleModAcc) ->
    case Router of
        {role, Mod} -> %% role模块才加
            ID = get_map_id(Map),
            ProtoName = get_map_name(Map),
            case ?TOS_OR_TOC(ID) andalso ((ID rem 2) =:= ?TOS) of %%tos才处理
                true ->
                    case lists:keyfind(Mod, 1, RoleModAcc) of
                        {_, NameList} ->
                            lists:keyreplace(Mod, 1, RoleModAcc, {Mod, [ProtoName|lists:delete(ProtoName, NameList)]});
                        _ ->
                            [{Mod, [ProtoName]}|RoleModAcc]
                    end;
                _ ->
                    RoleModAcc
            end;
        _ ->
            RoleModAcc
    end.

del_ignore_list([], RoleModList) ->
    RoleModList;
del_ignore_list([T|R], RoleModList) ->
    del_ignore_list(R, lists:keydelete(T, 1, RoleModList)).

to_binary(List) when erlang:is_list(List) ->
    erlang:list_to_binary(List);
to_binary(Binary) when erlang:is_binary(Binary) ->
    Binary.

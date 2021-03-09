%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 五月 2017 17:16
%%%-------------------------------------------------------------------
-module(test).
-author("laijichang").
-include("db.hrl").
-include("global.hrl").
-include("bg_act.hrl").
-include("proto/mod_role_fight.hrl").

%% API
-export([
    db_test/0,
    proto_test/0,
    out/0,
    word_test/0
]).

-export([
    beam_test/0,
    dictionary_test/0,
    init_tuple/0,
    tuple_test/0,
    modify_csv_data/0,
    get_port/1,
    test1/0,
    decompile/1
]).

db_test() ->
    List = lists:seq(1, 100),
    lib_profile:tc_begin(),
    [ db:lookup(?DB_ROLE_ACCOUNT_P, Value)|| Value <- List],
    lib_profile:tc_end().

proto_test() ->
    List = lists:seq(1, 10000),
    lib_profile:tc_begin(),
    [ enif_protobuf:encode(#m_fight_attack_toc{err_code = 0,skill_id = 1001,
        src_id = 10000100000042,
        effect_list = [#p_result{actor_id = 100010000011,
            result_type = 0,value = 72},
            #p_result{actor_id = 100010000006,result_type = 0,
                value = 117}],
        skill_pos = 345263166222214})|| _Value <- List],
    lib_profile:tc_end().

out() ->
    Header = "-module(cfg_test).\n-export([find/1]).\n",
    List = lists:flatten([
        lists:concat(["find\(", X, ") -> ", X, ";\n"])
    || X <- lists:seq(1, 100000)]),
    End = "find\(_) -> undefined.",
    file:write_file("/data/trunk/server/src/test/cfg_test.erl", Header ++ List ++ End, [{encoding, latin1}]).

beam_test() ->
    List = get_random_list(),
    lib_profile:tc_begin(),
    [ cfg_test:find(Key)|| Key<- List],
    lib_profile:tc_end().

dictionary_test() ->
    [ erlang:put(Key, Key)|| Key<- lists:seq(1, 100000)],
    List = get_random_list(),
    lib_profile:tc_begin(),
    [ _ = erlang:get(Key)|| Key <- List],
    lib_profile:tc_end().

tuple_test() ->
    List = get_random_list(),
    lib_profile:tc_begin(),
    [ begin
          DictTuple = erlang:get(tuple),
          Key = erlang:element(Key, DictTuple)
      end || Key <- List],
    lib_profile:tc_end().

get_random_list() ->
    [ lib_tool:random(100000)|| _ <- lists:seq(1, 1000000)].

init_tuple() ->
    List = lists:seq(1, 100000),
    Tuple = get_tuple(List, {}),
    erlang:put(tuple, Tuple).

get_tuple([], Tuple) ->
    Tuple;
get_tuple([Num|R], Tuple) ->
    Tuple2 = erlang:insert_element(Num, Tuple, Num),
    get_tuple(R, Tuple2).

word_test() ->
    lib_profile:tc_begin(),
    mod_role_chat:word_replace("哈哈"),
    lib_profile:tc_end().

modify_csv_data() ->
    FileDir = "/data/logs/monitor/",
    {ok, FileList} = file:list_dir(FileDir),
    modify_csv_data2(FileDir, FileList).

modify_csv_data2(FileDir, FileList) ->
    %% {FirstName, CPU, Mem, DiskWrite, Rec, Send, Load}
    List =
        [ begin
              case string:tokens(File, ".") of
                  [FileName, "csv"] ->
                      {CPU, Mem, DiskWrite, Rec, Send, Load} = modify_csv_data3(FileDir, File),
                      {lib_tool:to_integer(FileName), CPU, Mem, DiskWrite, Rec, Send, Load};
                  _ ->
                      []
              end
          end|| File <- FileList],
    List2 = lists:keysort(1, lists:flatten(List)),
    lists:foldr(
        fun({FileName, CPU, Mem, DiskWrite, Rec, Send, Load}, {Acc1, Acc2, Acc3, Acc4, Acc5, Acc6, Acc7}) ->
            {[FileName|Acc1], [CPU|Acc2], [Mem|Acc3], [DiskWrite|Acc4], [Rec|Acc5], [Send|Acc6], [Load|Acc7]}
        end, {[], [], [], [], [], [], []}, List2).


modify_csv_data3(FileDir, File) ->
    {ok, S} = file:open(FileDir ++ File, [read, {encoding, latin1}]),
    {CPUList, MemList, DiskWriteList, RecList, SendList, LoadList} = read_csv_file(io:get_line(S, ''), S, [], [], [], [], [], []),
    {lists:max(CPUList), lists:max(MemList), lists:max(DiskWriteList), lists:max(RecList), lists:max(SendList), lists:max(LoadList)}.


read_csv_file(eof, _S, CPUList, MemList, DiskWriteList, RecList, SendList, LoadList) ->
    {CPUList, MemList, DiskWriteList, RecList, SendList, LoadList};
read_csv_file(LineStr, S, CPUList, MemList, DiskWriteList, RecList, SendList, LoadList) ->
    LineStr2 = [ Value || Value <- LineStr, Value =/= 9 andalso Value =/= 10],
    case string:tokens(LineStr2, " ") of
        [_Time, CPU, Mem, DiskWrite, Rec, Send, Load] ->
            case erlang:is_integer(lib_tool:to_integer(CPU)) of
                true ->
                    CPUList2 = [lib_tool:to_integer(CPU)|CPUList],
                    MemList2 = [to_csv_size(Mem, "g")|MemList],
                    DiskWriteList2 = [to_csv_size(DiskWrite, "m")|DiskWriteList],
                    RecList2 = [to_csv_size(Rec, "m")|RecList],
                    SendList2 = [to_csv_size(Send, "m")|SendList],
                    LoadList2 = [lib_tool:to_float(Load)|LoadList],
                    read_csv_file(io:get_line(S, ''), S, CPUList2, MemList2, DiskWriteList2, RecList2, SendList2, LoadList2);
                _ ->
                    read_csv_file(io:get_line(S, ''), S, CPUList, MemList, DiskWriteList, RecList, SendList, LoadList)
            end;
        _ ->
            read_csv_file(io:get_line(S, ''), S, CPUList, MemList, DiskWriteList, RecList, SendList, LoadList)
    end.

to_csv_size(Mem, _Format) when erlang:length(Mem) =< 1 ->
    0;
to_csv_size(Mem, Format) ->
    {Size, Unit} = lib_tool:split(erlang:length(Mem) - 1, Mem),
    to_csv_size2(lib_tool:to_float(Size), string:to_lower(Unit), Format).


to_csv_size2(Size, "b", "m") ->
    to_csv_size2(Size/1024, "k", "m");
to_csv_size2(Size, "k", "m") ->
    to_csv_size2(Size/1024, "m", "m");
to_csv_size2(Size, "m", "m") ->
    Size;
to_csv_size2(Size, "g", "m") ->
    Size * 1024;
to_csv_size2(Size, "b", "g") ->
    to_csv_size2(Size/1024, "k", "g");
to_csv_size2(Size, "k", "g") ->
    to_csv_size2(Size/1024, "m", "g");
to_csv_size2(Size, "m", "g") ->
    to_csv_size2(Size/1024, "g", "g");
to_csv_size2(Size, "g", "g") ->
    Size.

get_port(String) ->
    Ports = erlang:ports(),
    get_port2(Ports, String).

get_port2([], _String) ->
    undefined;
get_port2([P|R], String) ->
    case erlang:port_to_list(P) =:= String of
        true ->
            P;
        _ ->
            get_port2(R, String)
    end.

test1() ->
    Sql = "INSERT INTO `db_test` (`id`, `name`, `quality`, `exp`, `grade`, `prep_grade`, `star_level`,
     `awake_level`, `attack`, `defense`, `hp`, `fighting`) VALUES (~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w)",
    List = lists:seq(1, 10000),

    Bt = time_tool:now_ms(),
    lists:foreach(
        fun(Id) ->
            Cmd = io_lib:format(Sql, [Id, "测试", 2, 10034, 232, 2, 1, 32, 533, 232343, 344, 645644]),
            emysql:execute(db_lib, Cmd)
        end, List),

    io:format("ok~n", []),
    Bt2 = time_tool:now_ms(),
    Bt2 - Bt.

decompile(Module) when is_atom(Module)->
    decompile(Module, erlang:atom_to_list(Module) ++ ".erl").
decompile(Module, ToFile) when is_atom(Module)->
    {ok,{_,[{abstract_code,{_,Data}}]}} = beam_lib:chunks(code:which(Module), [abstract_code]),
    SourceCode = erl_prettypr:format(erl_syntax:form_list(Data)),
    file:write_file(ToFile, SourceCode).
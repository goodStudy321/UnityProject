%% 多进程编译,修改自otp/lib/tools/src/make.erl
%% 解析Emakefile,根据获取{mods, options}列表,
%% 按照次序编译每项(解决编译顺序的问题)
%% 其中mods也可以包含多个模块,当大于1个时,
%% 可以启动多个process进行编译,从而提高编译速度.
-module(mmake).
-export([all/1, all/2, all/3, files/2, files/3]).

-include_lib("kernel/include/file.hrl").

-define(MakeOpts, [noexec, load, netload, noload]).


%% @doc
%% 是否显示编译信息，
%% 编译参数：{d,moutput} -- 是否显示更多的编译信息
%% 默认不显示更多的编译信息
%% {d,moutput} 即显示更多编译信息
%% -eval "case make:files([\"src/mmake.erl\"], [debug_info, {outdir, \"ebin\"},{d,moutput}]) of error -> halt(1); _ -> halt(0) end"
%% @end
-ifdef(moutput).
-define(CMESSAGE(Format, Data), io:format((Format), (Data))).
-else.
-define(CMESSAGE(Format, Data), ok).
-endif.

%% @doc
%% 是否开启自动检查hrl文件关联重编译
%% 编译参数：{d,ignore_hrl}
%% 默认不检查hrl自动关联重编译
%% {d,ignore_hrl} 不关联检查并重编译
%% -eval "case make:files([\"src/mmake.erl\"], [debug_info, {outdir, \"ebin\"},{d,ignore_hrl}]) of error -> halt(1); _ -> halt(0) end"
%% @end
-ifdef(ignore_hrl).
-define(IS_DEPEND_HRL,false).
-else.
-define(IS_DEPEND_HRL,true).
-endif.

all(Worker) when is_integer(Worker) ->
    all(Worker, []).

all(Worker, Options) when is_integer(Worker) ->
    init(),
    {MakeOpts, CompileOpts} = sort_options(Options, [], []),
    case read_emakefile('Emakefile', CompileOpts) of
        Files when is_list(Files) ->
            do_make_files(Worker, Files, MakeOpts);
        error ->
            error
    end.

%% @doc
%% 根据传入的编译规则编译
%% Emakefile内容变化参数
%% @end
-spec all(Worker, Options,  Emakefile) -> up_to_date | error when
    Worker :: integer(),
    Options :: [Option],
    Option :: noexec | load | netload | atom() | {atom(), term()} | {'d', atom(), term()},
    Emakefile :: [term()].
all(Worker, Options,  []) ->
    init(),
    {MakeOpts, CompileOpts} = sort_options(Options, [], []),
    Mods = [filename:rootname(F) || F <- filelib:wildcard("*.erl")],
    Files = [{Mods, CompileOpts}],
    do_make_files(Worker, Files, MakeOpts);
all(Worker, Options, Emakefile) ->
    init(),
    {MakeOpts, CompileOpts} = sort_options(Options, [], []),
    Files = transform(Emakefile, CompileOpts, [], []),
    do_make_files(Worker, Files, MakeOpts).


files(Worker, Fs) ->
    files(Worker, Fs, []).

files(Worker, Fs0, Options) ->
    Fs = [filename:rootname(F, ".erl") || F <- Fs0],
    {MakeOpts, CompileOpts} = sort_options(Options, [], []),
    case get_opts_from_emakefile(Fs, 'Emakefile', CompileOpts) of
        Files when is_list(Files) ->
            do_make_files(Worker, Files, MakeOpts);
        error -> error
    end.

do_make_files(Worker, Fs, Opts) ->
    ?CMESSAGE("worker:~p~nfs:~p~nopts:~p~n", [Worker, Fs, Opts]),
    process(Fs, Worker, lists:member(noexec, Opts), load_opt(Opts)).

sort_options([H | T], Make, Comp) ->
    case lists:member(H, ?MakeOpts) of
        true ->
            sort_options(T, [H | Make], Comp);
        false ->
            sort_options(T, Make, [H | Comp])
    end;
sort_options([], Make, Comp) ->
    {Make, lists:reverse(Comp)}.

%%% Reads the given Emakefile and returns a list of tuples: {Mods,Opts}
%%% Mods is a list of module names (strings)
%%% Opts is a list of options to be used when compiling Mods
%%%
%%% Emakefile can contain elements like this:
%%% Mod.
%%% {Mod,Opts}.
%%% Mod is a module name which might include '*' as wildcard
%%% or a list of such module names
%%%
%%% These elements are converted to [{ModList,OptList},...]
%%% ModList is a list of modulenames (strings)
read_emakefile(Emakefile, Opts) ->
    case file:consult(Emakefile) of
        {ok, Emake} ->
            transform(Emake, Opts, [], []);
        {error, enoent} ->
            %% No Emakefile found - return all modules in current
            %% directory and the options given at command line
            Mods = [filename:rootname(F) || F <- filelib:wildcard("*.erl")],
            [{Mods, Opts}];
        {error, Other} ->
            io:format("make: Trouble reading 'Emakefile':~n~p~n", [Other]),
            error
    end.

transform([{Mod, ModOpts} | Emake], Opts, Files, Already) ->
    case expand(Mod, Already) of
        [] ->
            transform(Emake, Opts, Files, Already);
        Mods ->
            transform(Emake, Opts, [{Mods, ModOpts ++ Opts} | Files], Mods ++ Already)
    end;
transform([Mod | Emake], Opts, Files, Already) ->
    case expand(Mod, Already) of
        [] ->
            transform(Emake, Opts, Files, Already);
        Mods ->
            transform(Emake, Opts, [{Mods, Opts} | Files], Mods ++ Already)
    end;
transform([], _Opts, Files, _Already) ->
    lists:reverse(Files).

expand(Mod, Already) when is_atom(Mod) ->
    expand(atom_to_list(Mod), Already);
expand(Mods, Already) when is_list(Mods), not is_integer(hd(Mods)) ->
    lists:concat([expand(Mod, Already) || Mod <- Mods]);
expand(Mod, Already) ->
    case lists:member($*, Mod) of
        true ->
            Fun = fun(F, Acc) ->
                M = filename:rootname(F),
                case lists:member(M, Already) of
                    true -> Acc;
                    false -> [M | Acc]
                end
                  end,
            lists:foldl(Fun, [], filelib:wildcard(Mod ++ ".erl"));
        false ->
            Mod2 = filename:rootname(Mod, ".erl"),
            case lists:member(Mod2, Already) of
                true -> [];
                false -> [Mod2]
            end
    end.

%%% Reads the given Emakefile to see if there are any specific compile
%%% options given for the modules.
get_opts_from_emakefile(Mods, Emakefile, Opts) ->
    case file:consult(Emakefile) of
        {ok, Emake} ->
            Modsandopts = transform(Emake, Opts, [], []),
            ModStrings = [coerce_2_list(M) || M <- Mods],
            get_opts_from_emakefile2(Modsandopts, ModStrings, Opts, []);
        {error, enoent} ->
            [{Mods, Opts}];
        {error, Other} ->
            io:format("make: Trouble reading 'Emakefile':~n~p~n", [Other]),
            error
    end.

get_opts_from_emakefile2([{MakefileMods, O} | Rest], Mods, Opts, Result) ->
    case members(Mods, MakefileMods, [], Mods) of
        {[], _} ->
            get_opts_from_emakefile2(Rest, Mods, Opts, Result);
        {I, RestOfMods} ->
            get_opts_from_emakefile2(Rest, RestOfMods, Opts, [{I, O} | Result])
    end;
get_opts_from_emakefile2([], [], _Opts, Result) ->
    Result;
get_opts_from_emakefile2([], RestOfMods, Opts, Result) ->
    [{RestOfMods, Opts} | Result].

members([H | T], MakefileMods, I, Rest) ->
    case lists:member(H, MakefileMods) of
        true ->
            members(T, MakefileMods, [H | I], lists:delete(H, Rest));
        false ->
            members(T, MakefileMods, I, Rest)
    end;
members([], _MakefileMods, I, Rest) ->
    {I, Rest}.


%% Any flags that are not recognixed as make flags are passed directly
%% to the compiler.
%% So for example make:all([load,debug_info]) will make everything
%% with the debug_info flag and load it.
load_opt(Opts) ->
    case lists:member(netload, Opts) of
        true ->
            netload;
        false ->
            case lists:member(load, Opts) of
                true ->
                    load;
                _ ->
                    noload
            end
    end.

%% 处理
process([{[], _Opts} | Rest], Worker, NoExec, Load) ->
    process(Rest, Worker, NoExec, Load);
process([{L, Opts} | Rest], Worker, NoExec, Load) ->
    Len = length(L),
    Worker2 = erlang:min(Len, Worker),
    ErtsVerStr = erlang:system_info(version),
    [ErtsVerChar | _] = string:tokens(ErtsVerStr, "."),
    case erlang:list_to_integer(ErtsVerChar) >= 6 of
        true ->
            %%R17 with new unicode support, may require conditional compiling for legacy code
            Opts2 = [{d, 'ERTS_AFTER_R17'} | Opts];
        _ ->
            Opts2 = Opts
    end,
    case catch do_worker(L, Opts2, NoExec, Load, Worker2) of
        error ->
            io:format("compile error~n"),
            error;
        ok ->
            process(Rest, Worker, NoExec, Load)
    end;
process([], _Worker, _NoExec, _Load) ->
    dump_meta_config(),
    up_to_date.

%% worker进行编译
do_worker(L, Opts, NoExec, Load, Worker) ->
    init_run_queue(L),
    % 启动进程
    case lists:keysearch(outdir, 1, Opts) of
        {value, {outdir, OutDir}} ->
            ok;
        _ ->
            OutDir = ""
    end,
    Ref = make_ref(),
    PIDs = [start_worker(Opts, NoExec, Load, self(), Ref, OutDir) || _ <- lists:seq(1, Worker)],
    do_wait_worker(length(PIDs), Ref).

%% initialize shared run queue of jobs
init_run_queue(L) ->
        catch ets:new(ets_run_queue, [named_table, public, set, {read_concurrency, true}]),
    ets:delete_all_objects(ets_run_queue),
    ets:insert(ets_run_queue, {index, 0}),
    init_run_queue(L, 1).
init_run_queue([], Count) ->
    ets:insert(ets_run_queue, {count, Count});
init_run_queue([F | L], Idx) ->
    ets:insert(ets_run_queue, {Idx, F}),
    init_run_queue(L, Idx + 1).

%% fetch a job from queue
%% @returns {ok,F}|done
pop_run_queue() ->
    [{_, Count}] = ets:lookup(ets_run_queue, count),
    pop_run_queue(Count).
pop_run_queue(Count) ->
    Idx = ets:update_counter(ets_run_queue, index, 1),
    case ets:lookup(ets_run_queue, Idx) of
        [{_, F}] -> {ok, F};
        [] when Count =< Idx ->
            done;
        [] ->
            %% 这一项任务丢失了?
            pop_run_queue(Count)
    end.

%% 等待结果
do_wait_worker(0, _Ref) ->
    ok;
do_wait_worker(N, Ref) ->
    receive
        {ack, Ref} ->
            do_wait_worker(N - 1, Ref);
        {error, Ref} ->
            throw(error);
        {'EXIT', _P, _Reason} ->
            do_wait_worker(N, Ref);
        _Other ->
            io:format("receive unknown msg:~p~n", [_Other]),
            do_wait_worker(N, Ref)
    end.


start_worker(Opts, NoExec, Load, Parent, Ref, OutDir) ->
    spawn_link(fun() -> worker_loop(Opts, NoExec, Load, Parent, Ref, OutDir) end).
%% workers fetch jobs from queue, quit when queue is empty
worker_loop(Opts, NoExec, Load, Parent, Ref, OutDir) ->
    case pop_run_queue() of
        {ok, F} ->
            case recompilep(coerce_2_list(F), NoExec, Load, Opts, OutDir) of
                error ->
                    Parent ! {error, Ref},
                    exit(error);
                {error, _, _} ->
                    Parent ! {error, Ref},
                    exit(error);
                _ ->
                    worker_loop(Opts, NoExec, Load, Parent, Ref, OutDir)
            end;
        _ ->
            Parent ! {ack, Ref}
    end.

recompilep(File, NoExec, Load, Opts, OutDir) ->
    ObjFile = get_out_filename(File, OutDir),
    Te = get_file_mtime(lists:append(File, ".erl")),
    case exists(ObjFile) of
        true ->
            To = get_file_mtime(ObjFile);
        false ->
            To = 0
    end,
    recompilep(Te, To, File, NoExec, Load, Opts, ObjFile).

get_out_filename(File, OutDir) ->
    ObjName = lists:append(filename:basename(File), code:objfile_extension()),
    case OutDir == "" of
        true ->
            ObjName;
        _ ->
            filename:join(coerce_2_list(OutDir), ObjName)
    end.

recompilep(Te, To, File, NoExec, Load, Opts, ObjFile) ->
    case get_meta_config(File) of
        {ok, {Deps, Te, To}} ->
            case ?IS_DEPEND_HRL andalso check_include_time(Deps) of
                changed ->
                    recompile(File, NoExec, Load, Opts, Te, ObjFile);
                _ ->
                    ?CMESSAGE("Skipped: ~s.erl\n", [File]),
                    ignore
            end;
        _ ->
            recompile(File, NoExec, Load, Opts, Te, ObjFile)
    end.

check_include_time([]) ->
    ignore;
check_include_time([{IncFile, Time} | L]) ->
    case catch get_file_mtime(IncFile) of
        Time ->
            check_include_time(L);
        _ ->
            changed
    end.

%% recompile2(ObjMTime, File, NoExec, Load, Opts)
%% Check if file is of a later date than include files.
recompile(File, NoExec, Load, Opts, Te, ObjFile) ->
    IncludePath = include_opt(Opts),
    case get_includes(lists:append(File, ".erl"), IncludePath) of
        error -> error;
        Deps ->
            case recompile(File, NoExec, Load, Opts) of
                error -> error;
                {error, _, _} = Err -> Err;
                _ ->
                    timer:sleep(1000), %% when using vm with external mount (eg. linux=>windows),  file writes take some time to complete
                    To = get_file_mtime2(ObjFile),
                    save_meta_config(File, Te, To, Deps),
                    ok
            end
    end.

include_opt([{i, Path} | Rest]) ->
    [Path | include_opt(Rest)];
include_opt([_First | Rest]) ->
    include_opt(Rest);
include_opt([]) ->
    [].

%% recompile(File, NoExec, Load, Opts)
%% Actually recompile and load the file, depending on the flags.
%% Where load can be netload | load | noload
%% @returns ModRet|BinRet|ErrRet|skipped|error
%%          ModRet = {ok,ModuleName} | {ok,ModuleName,Warnings}
%%          BinRet = {ok,ModuleName,Binary} | {ok,ModuleName,Binary,Warnings}
%%          ErrRet = error | {error,Errors,Warnings}
recompile(File, true, _Load, _Opts) ->
    io:format("Out of date: ~s.erl~n", [File]),
    error;
recompile(File, false, noload, Opts) ->
    io:format("Recompile: ~s.erl~n", [File]),
    compile:file(File, [report_errors, report_warnings, error_summary | Opts]);
recompile(File, false, load, Opts) ->
    io:format("Recompile: ~s.erl~n", [File]),
    c:c(File, Opts);
recompile(File, false, netload, Opts) ->
    io:format("Recompile: ~s.erl~n", [File]),
    c:nc(File, Opts).

exists(File) ->
    case file:read_file_info(File) of
        {ok, _} ->
            true;
        _ ->
            false
    end.

coerce_2_list(X) when is_atom(X) ->
    atom_to_list(X);
coerce_2_list(X) ->
    X.

%% @doc 获取erl模块依赖的hrl文件清单
%% @returns [{HrlFile,Time}]|error
get_includes(File, IncludePath) ->
    Path = [filename:dirname(File) | IncludePath],
    case epp:open(File, Path, []) of
        {ok, Epp} ->
            get_includes2(Epp, File, []);
        _Error ->
            error
    end.
get_includes2(Epp, File, Acc) ->
    case epp:parse_erl_form(Epp) of
        {ok, {attribute, 1, file, {File, 1}}} ->
            get_includes2(Epp, File, Acc);
        {ok, {attribute, 1, file, {IncFile, 1}}} ->
            AbsFile = filename:absname(IncFile),
            get_includes2(Epp, File, [{AbsFile, get_file_mtime(AbsFile)} | Acc]);
        {ok, _} ->
            get_includes2(Epp, File, Acc);
        {eof, _} ->
            epp:close(Epp),
            Acc;
        {error, _Error} ->
            get_includes2(Epp, File, Acc)
    end.


init() ->
    load_meta_config(),
    ets:new(ets_file_info_tmp, [named_table, set, public]).

%% @throws {file_not_found,File}
get_file_mtime(File) ->
    case ets:lookup(ets_file_info_tmp, File) of
        [] ->
            get_file_mtime2(File);
        [{File, MTime}] ->
            MTime
    end.
%% @throws {file_not_found,File}
get_file_mtime2(File) ->
    case file:read_file_info(File) of
        {ok, #file_info{mtime = MTime}} ->
            ets:insert(ets_file_info_tmp, {File, MTime}),
            MTime;
        _ ->
            erlang:throw({file_not_found, File})
    end.


%%--------------------
save_meta_config(File, ErlTime, BeamTime, Deps) ->
    DepsTime = [T || {_, T} <- Deps],
    MaxDepsTime = lists:max([0 | DepsTime]),
    AbsFile = filename:absname(File),
    case ErlTime > BeamTime orelse MaxDepsTime > BeamTime of
        true ->
            %% WARNING: time skewed
            ets:delete(ets_meta_config, AbsFile),
            error;
        _ ->
            ets:insert(ets_meta_config, {AbsFile, {Deps, ErlTime, BeamTime}}),
            C = ets:update_counter(ets_meta_config, dumps, 1),
            case C rem 20 of
                0 ->
                    dump_meta_config();
                _ ->
                    ignore
            end
    end,
    ok.
dump_meta_config() ->
    ?CMESSAGE("dump meta config: ~s~n", [filename:absname(get_meta_config_filename())]),
    ets:tab2file(ets_meta_config, get_meta_config_filename()),
    ok.

%% meta data includes obj and src file paths and modified times, for simplicity no checksum is used
load_meta_config() ->
    case ets:info(ets_meta_config, size) of
        undefined ->
            Filename = get_meta_config_filename(),
            case exists(Filename) of
                true ->
                    case ets:file2tab(Filename) of
                        {ok, _} ->
                            ?CMESSAGE("load meta config ~s: ~w~n", [filename:absname(Filename), ok]);
                        _ ->
                            ?CMESSAGE("init meta config: ok.~n", []),
                            ets:new(ets_meta_config, [set, named_table, public, {read_concurrency, true}, {keypos, 1}])
                    end;
                false ->
                    ?CMESSAGE("init meta config: ok.~n", []),
                    ets:new(ets_meta_config, [set, named_table, public, {read_concurrency, true}, {keypos, 1}])
            end,

            ok;
        _ ->
            ignore
    end,
    case ets:lookup(ets_meta_config, dumps) of
        [] ->
            %% initailize dump counter
            ets:insert(ets_meta_config, {dumps, 0});
        _ ->
            ignore
    end.

get_meta_config_filename() ->
    get_meta_dir() ++ "ets_meta_config".

%% @returns {ok,{Deps,ErlTime,BeamTime}}|{error,not_found}
%%          Deps    := [{HrlFile,HrlTime}]
get_meta_config(File) ->
    AbsFile = filename:absname(File),
    case ets:lookup(ets_meta_config, AbsFile) of
        [{_, D}] ->
            {ok, D};
        _ ->
            {error, not_found}
    end.

%% @doc 指定编译时间数据库放置的位置, 通过-meta_root命令行参数, 建议用源码目录(svn co目录)
get_meta_dir() ->
    case init:get_argument(meta_root) of
        {ok, [[Dir]]} ->
            Dir;
        _ ->
            ""
    end.

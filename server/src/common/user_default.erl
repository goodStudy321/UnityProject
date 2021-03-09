-module(user_default).

-compile([export_all]).
-include("user_default.hrl").


init() ->
    ok.

%% 干掉q()
q() ->
    '*** Hei! what do you want to do!'.

hh() ->
    Txt = "
%%%% ================================= [协议监控] ==========================================
%%%% t/1, %% t( RoleID::int() | Account::atom() )  =  trace 某玩家协议
%%%% t/2, %% t( RoleID::int(), TargetRecord::atom() | FilterRecords::[atom()] )  %% trace 某玩家协议,trace单个Record,或者过滤Records
%%%% 
%%%% t2/3, %%同t/2,第三个参数 filter | trace 表示过滤黑名单或者白名单
%%%% tf/1, %% 同 t(RoleID, [_, _, ..], filter) 过滤掉常用的无关协议
%%%% td/2 %%  同 t(RoleID, RecordsList, trace) %% 只打印某些协议
%%%% ================================= [函数监控] ============================================
%%%% wr/2, wr(Mod::atom(), Fun::atom())  %% 传入模块名与函数名,返回每次调用该函数的参数与返回值
%%%% wr/3, wr(Mod::atom(), Fun::atom(), Arg::int())  %% 传入模块名、函数名、参数个数, 返回每次调用该函数的参数与返回值
%%%% ================================= [前后端交互] ===========================================
%%%% tos/2,  %% tos(RoleID,#m_friend_list_tos{tab=1})  %% 模拟前端发消息给后端
%%%%
%%%% ==================================== [GM操作] ================================================
%%%% role_func/2, %% role_func( RoleID, fun() )  %% 在角色进程执行某函数
%%%% map_func/2, %% map_func( R oleID, fun() )  %% 在角色所处的地图进程执行某函数
%%%% kill/1 %% kill 掉某个进程
%%%% 
%%%% ==================================== [获取角色数据] =============================================
%%%% role_data/2, %% role_data( RoleID, ModName::atom() )   %% 返回 ModName:get_data()
%%%% role_dict/2, %% role_dict( RoleID, Key ) -> Val.  %% 在角色进程中调用 erlang:get(Key), 只返回值
%%%% role_map/2, %% role_map( RoleID, Key ) -> Val. %% 在角色所处地图进程中调用 erlang:get(Key),只返回值
%%%% map_dict/2, %% map_dict( MapName::atom(), key). %% 同上,传入地图进程注册名
%%%% 
%%%% role_base/1, %% 返回对应数据 {ok, #p_role_base{}}
%%%% role_attr/1, %% {ok, #p_role_attr{}}
%%%% role_pos/1,  %% {ok, #p_role_pos{}}
%%%% 
%%%% role_module_data/2, %% role_module_data( RoleID, Key )  %% 返回角色进程中跟Key有关的数据
%%%% role_map/1, %% role_map( RoleID ) 过滤返回角色有关的地图进程数据
%%%% pet_map/1, %% pet_map( PetID | RoleID ) 过滤返回宠物有关的地图进程数据
%%%% scryed_map/1 %% scryed_map( ScryedID | RoleID ) 过滤返回分身有关的地图进程数据
%%%% 
%%%% ===================================== [获取数据杂项] ==========================================
%%%% show_online/0, %% 显示在线角色
%%%% show_num/0, %% 显示在线和注册的角色数量
%%%% 
%%%% show_table/1, %% show_table( TableName::atom() )显示某个数据表的所有数据
%%%% get_compile_time/1 %% get_compile_time( ModName::atom() )获取某个模块内存中的编译时间
%%%% ==========================================================================================
",
io:format("~ts~n", [Txt]).

tos(RoleID, DataRecord) ->
    gateway_misc:send(RoleID, {gm_send_data, gateway_packet:robot_packet(DataRecord)}).

%%--------------------------------------------------------------------
%% user:
%%t(RoleID)                     -> tarce all Record return
%%t(RoleID,Record)              -> trace this Record
%%t(RoleID,RecordList)          -> filter this RecordList
%%--------------------------------------------------------------------
tf(RoleSpec) ->
    FilterList = [],
    io:format("FilterList:~p~n", [FilterList]),
    t2(RoleSpec, FilterList, filter).
td(RoleSpec, AtomList) ->
    io:format("TargetList:~p~n", [AtomList]),
    t2(RoleSpec,AtomList,trace).

t(RoleSpec) ->
    tf(RoleSpec).

t(RoleSpec, AtomList) when is_list(AtomList) ->
    t2(RoleSpec, AtomList, trace);
t(RoleSpec, RecordName) when is_atom(RecordName) ->
    t(RoleSpec, [RecordName]).


t2(RoleSpec, [], filter) ->
    t3(RoleSpec, undefined);
t2(RoleSpec, AtomList, filter)->
    Fun = fun(T) -> not is_fit_condition(T, AtomList) end,
    t3(RoleSpec,Fun);
t2(RoleSpec, AtomList, trace) ->
    Fun = fun(T) -> is_fit_condition(T, AtomList) end,
    t3(RoleSpec,Fun).

t3(RoleSpec, Fun) ->
    RoleID = get_role_id(RoleSpec),
    common_debugger:start_client_trace(RoleID, Fun, 400).

st(RoleSpec) ->
    RoleID = get_role_id(RoleSpec),
    common_debugger:stop_client_trace(RoleID).

role_func(RoleSpec,Func) ->
    RoleID = get_role_id(RoleSpec),
    case role_server:get_role_id() of
        RoleID ->
            Func();
        _ ->
            common_shell:call_role(RoleID, {func, Func})
    end.

a() ->
    world_online_server:get_all_info().

get_role_id(RoleSpec) when erlang:is_integer(RoleSpec) ->
    RoleSpec;
get_role_id(RoleSpec) ->
    RoleSpec.

%%热加载指定配置文件
r(ConfigName) ->
    lib_config:reload(ConfigName).


rcp(ConfigName) ->
  DesFilePath = lib_config:get_config_path(atom_to_list(ConfigName)),
  [_,RelPath] = re:split(DesFilePath,"config/",[{return,list}]),
  CompileAttr  = user_default:module_info(compile),
  {_,ModulePath} = lists:keyfind(source,1,CompileAttr),
  [OppPath,_] = re:split(ModulePath,"trunk/",[{return,list}]),
  SrcFilePath = OppPath ++ "trunk/config/" ++ RelPath,
  io:format("src file:~p\n", [SrcFilePath]),
  io:format("des file:~p\n", [DesFilePath]),
  case file:copy(SrcFilePath, DesFilePath) of
    {ok,_} -> next;
    {error,ErrR} -> io:format("copy error!:~p",[ErrR])
  end,
  r(ConfigName).

f(ConfigName, Key) ->
    lib_config:find(ConfigName, Key).

%% @doc 显示在线
show_online() ->
    world_online_server:get_online_roleinfos().

%% 显示mnesia全表
show_table(Table) ->
    get_mnesia_table_info(Table).

show_num() ->
    [{online_num, world_online_server:get_online_num()}, {total_num,get_total_num()}].

get_total_num() ->
    lists:foldl(
        fun(Key, AccNum) ->
            [Data] = mdb:dirty_read(db_mlogin_counter_p, Key),
            {r_mlogin_counter, {role, AgentID, ServerID}, LastRoleID} = Data,
            StartID = mlogin_misc:get_role_start_id(AgentID, ServerID),
            Num = (LastRoleID - StartID),
            AccNum + Num
        end,
        0, mdb:dirty_all_keys(db_mlogin_counter_p)).

info() ->
    common_debugger:i().

%% 杀掉某个进程
kill(Name) when erlang:is_atom(Name) ->
    case erlang:whereis(Name) of
        undefined ->
            case erlang:whereis(Name) of
                undefined ->
                    ignore;
                PID ->
                    erlang:exit(PID, kill)
            end;
        PID ->
            erlang:exit(PID, kill)
    end.

%% global 和 local的简写
whereis(Name) when erlang:is_atom(Name) ->
    case erlang:whereis(Name) of
        undefined ->
            case erlang:whereis(Name) of
                undefined ->
                    undefined;
                PID ->
                    PID
            end;
        PID ->
            PID
    end.


%% 获取指定表的所有数据
get_mnesia_table_info(SourceTable)->
    Pattern = get_whole_table_match_pattern(SourceTable),
    Res = mdb:dirty_match_object(SourceTable, Pattern),
    Res.
get_whole_table_match_pattern(SourceTable) ->
    A = mdb:table_info(SourceTable, attributes),
    RecordName = mdb:table_info(SourceTable, record_name),
    lists:foldl(
      fun(_, Acc) ->
              erlang:append_element(Acc, '_')
      end, {RecordName}, A).

wr(M, F) ->
    lib_trace:watch_return(M, F).

wr(M, F, A) ->
    lib_trace:watch_return(M, F, A).

%% A = 参数个数, P = PID
wr(P, M, F, A) ->
    lib_trace:watch_return(P, M, F, A).

%% Reload modules that have been modified since last load.  From Tobbe
%% Tornqvist, http://blog.tornkvist.org/, "Easy load of recompiled
%% code", which may in turn have come from Serge?

l() ->
    [c:l(M) || M <- mm()].

mm() ->
    modified_modules().

modified_modules() ->
    [M || {M, _} <- code:all_loaded(), 
	  module_modified(M) == true].

module_modified(Module) ->
    case code:is_loaded(Module) of
	{file, preloaded} ->
	    false;
	{file, Path} ->
	    CompileOpts = 
		proplists:get_value(compile, Module:module_info()),
	    CompileTime = proplists:get_value(time, CompileOpts),
	    Src = proplists:get_value(source, CompileOpts),
	    module_modified(Path, CompileTime, Src);
	_ ->
	    false
    end.

module_modified(Path, PrevCompileTime, PrevSrc) ->
    case find_module_file(Path) of
	false ->
	    false;
	ModPath ->
	    case beam_lib:chunks(ModPath, ["CInf"]) of
		{ok, {_, [{_, CB}]}} ->
		    CompileOpts =  binary_to_term(CB),
		    CompileTime = proplists:get_value(time,                             
						      CompileOpts),
		    Src = proplists:get_value(source, CompileOpts),
		    not (CompileTime == PrevCompileTime) and 
							   (Src == PrevSrc);
		_ ->
		    false
	    end
    end.

find_module_file(Path) ->
    case file:read_file_info(Path) of
	{ok, _} ->
	    Path;
	_ ->
	    %% may be the path was changed
	    case code:where_is_file(filename:basename(Path)) of
		non_existing ->
		    false;
		NewPath ->
		    NewPath
	    end
    end.

%% Reload all modules, regardless of age.
la() ->
    FiltZip = lists:filter(
	fun({_Mod, Path}) when is_list(Path) ->
		case string:str(Path, "/kernel-") +
		     string:str(Path, "/stdlib-") of
			0 -> true;
			_ -> false
		end;
	    (_) -> false
	end, code:all_loaded()),
    {Ms, _} = lists:unzip(FiltZip),
    lists:foldl(fun(M, Acc) ->
			case shell_default:l(M) of
				{error, _} -> Acc;
				_          -> [M|Acc]
			end
		end, [], Ms).

my_tracer() ->
    dbg:tracer(process, {fun my_dhandler/2, user}).

my_dhandler(TraceMsg, Acc) ->
    dbg:dhandler(filt_state_from_term(TraceMsg), Acc).

filt_state_from_term(T) when is_tuple(T), element(1, T) == state ->
    sTatE;
filt_state_from_term(T) when is_tuple(T), element(1, T) == chain_r ->
    cHain_R;
filt_state_from_term(T) when is_tuple(T), element(1, T) == g_hash_r ->
    g_Hash_R;
filt_state_from_term(T) when is_tuple(T), element(1, T) == hash_r ->
    hAsh_R;
filt_state_from_term(T) when is_tuple(T) ->
    list_to_tuple(filt_state_from_term(tuple_to_list(T)));
filt_state_from_term([H|T]) ->
    [filt_state_from_term(H)|filt_state_from_term(T)];
filt_state_from_term(X) ->
    X.

get_compile_time(Mod) ->
    case catch get_compile_info(Mod, time) of
        {Y,M,D,Hour,Min,Sec} -> {{Y,M,D},{Hour,Min,Sec}};
        _ -> error
    end.
get_compile_info(Mod, Info) ->
    {Info, CompileInfo} = lists:keyfind(Info, 1, erlang:get_module_info(Mod, compile)),
    CompileInfo.

%% Pid = all 代表全部进程
%% '_' 匹配任意值
trace_function(M, F, A) ->
    lib_trace:watch_return(all, M, F, A).

trace_function(Pid, M, F, A) ->
    lib_trace:watch_return(Pid, M, F, A).

is_fit_condition(T, AtomList) ->
    T2 = lib_tool:to_list(T),
    is_fit_condition2(T2, AtomList).

is_fit_condition2(_T, []) ->
    false;
is_fit_condition2(T, [Atom|R]) ->
    String = lib_tool:to_list(Atom),
    case string:str(T, String) of
        Integer when Integer > 0 ->
            true;
        _ ->
            is_fit_condition2(T, R)
    end.





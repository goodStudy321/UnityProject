%%%-------------------------------------------------------------------
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(common_reloader).

-include("global.hrl").

%% API
-export([
    reload_all/0,
    reload_config/1,
    reload_module/1
]).

reload_all() ->
    RootDir = common_config:get_server_root(),
    EbinPath = RootDir ++ "ebin",
    filelib:fold_files(EbinPath, ".+\.beam$", true,
        fun(E, _Acc) ->
            Module = lib_tool:to_atom(filename:basename(E, ".beam")),
            reload_module(Module),
            ok
        end, ok).

reload_config(FileList) when erlang:is_list(FileList) ->
    [begin reload_config(FileT) end || FileT <- FileList];
reload_config(FileT) ->
    File = lib_tool:to_list(FileT),
    case File of
        "common" ->
            lib_config:reload(FileT),
            ?ERROR_MSG("Module: common, reload: ok"),
            reload_beam_hook(FileT);
        "cfg" ++ _ -> %% cfg开头的文件
            ErlCfgFileDir = lib_config:get_config_path() ++ "erl/",
            FileName = ErlCfgFileDir ++ File ++ ".erl",
            compile:file(FileName, [{i, ErlCfgFileDir}, {outdir, common_config:get_server_root() ++ "ebin"}]),
            reload_module(FileT),
            ok;
        _ ->
            lib_config:reload(FileT)
    end.

reload_module(ModuleList) when erlang:is_list(ModuleList) ->
    [begin reload_module(Module) end || Module <- ModuleList];
reload_module(Module) ->
    Ret = c:l(Module),
    ?WARNING_MSG("Module:~w, reload:~w~n", [Module, Ret]),
    case Ret of
        {module, Module} ->
            ?TRY_CATCH(reload_beam_hook(Module)),
            ok;
        _ ->
            error
    end.

reload_beam_hook(Module) ->
    ServerID = common_config:get_server_id(),
    IsCenter = common_config:is_center_id(ServerID),
    IsCross = common_config:is_cross_server_id(ServerID),
    if
        IsCenter ->
            center_reload_beam_hook(Module);
        IsCross ->
            cross_reload_beam_hook(Module);
        true ->
            game_reload_beam_hook(Module)
    end.

%% 中央服配置重载
center_reload_beam_hook(Module) ->
    case Module of
        cfg_topology ->
            center_topology_server:reload_config();
        _ ->
            ok
    end.

cross_reload_beam_hook(_Module) ->
    ok.

game_reload_beam_hook(Module) ->
    case Module of %% 数量多的时候，就写成配置 {xxx, {func, M,F,A ++ [Module]} | {func, fun(Module)-> yyy end}}
        common ->
            world_activity_server:reload_config(),
            world_act_server:reload_config(),
            world_act_server:reload_common(),
            world_cycle_act_server:reload_config();
        cfg_activity ->
            world_activity_server:reload_config();
        cfg_act ->
            world_act_server:reload_config();
        cfg_auction_major_class ->
            world_auction_server:reload_config();
        cfg_discount_pay ->
            common_broadcast:bc_role_info_to_world({mod_role_discount_pay, online, []});
        cfg_daily_buy ->
            common_broadcast:bc_role_info_to_world({mod_role_daily_buy, online, []});
        rank_server ->
            rank_server:gm_set_heap_size();
        cfg_cycle_act ->
            world_cycle_act_server:reload_config();
        _ ->
            ok
    end.

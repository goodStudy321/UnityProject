:: erl里的路径跟windows下的路径，用法不同。。留意"/"与"\"的区别
set DEPS_DIRS=" db lib log script time mongodb pbkdf2 poolboy bson deps\ejson deps\emysql deps\json deps\mochiweb deps\sync deps\recon deps\meck "
set SHELL_DIR=%~dp0\..\
set META_DIR=%SHELL_DIR%\script\make\
cd ..

:: windows_make
erlc -I include/ -o ./ebin windows/windows_make.erl

:: init_make
md "ebin"
md "deps/script/ebin"
md "config/dyn"

:: mmake
del %SHELL_DIR%\deps\script\ebin\mmake.beam
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"deps/script/src/mmake.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
copy %SHELL_DIR%\deps\script\ebin\*.beam %SHELL_DIR%\ebin

:: make_pre
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"deps/lib/src/lib_tool.erl\",\"deps/log/src/log_loglevel.erl\",\"deps/lib/src/lib_config.erl\",\"src/common/common_config.erl\"], [{i,\"include\"}, {i,\"include\proto\"}, {i,\"config/erl\"}, {outdir, \"ebin\"}]) of error -> halt(1); _ -> halt(0) end"
cd src/pre 
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case mmake:all(10, [{outdir, \"../../ebin\"}]) of up_to_date -> halt(0); error -> halt(1) end"
cd %SHELL_DIR%

:: deps
for %%d in ("%DEPS_DIRS%") do (
	copy %SHELL_DIR%\deps\%%d\ebin\*.beam %SHELL_DIR%\ebin
	copy %SHELL_DIR%\deps\%%d\app\*.app %SHELL_DIR%\ebin
)
cd deps
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case mmake:all(10, []) of up_to_date -> halt(0); error -> halt(1) end."
cd %SHELL_DIR%

:: make_proto
escript ./script/make/gen_proto.es

:: make_module_etc
escript ./script/make/gen_cfg_module.es

:: make_mission
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"config/excel/cfg_mission_excel.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
escript ./script/make/gen_mission.es

:: make_drop
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"config/excel/cfg_drop_boss.erl\", \"config/excel/cfg_drop_config.erl\", \"config/excel/cfg_monster_i.erl\", \"config/excel/cfg_drop_equip.erl\", \"config/excel/cfg_equip_start_create_i.erl\", \"config/excel/cfg_family_boss_drop.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0)  end."
escript ./script/make/gen_drop.es

:: make_achievement
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"config/excel/cfg_achievement_excel.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0)  end."
escript ./script/make/gen_achievement.es

:: make_god_book
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"config/excel/cfg_god_book_excel.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0)  end."
escript ./script/make/gen_god_book.es

:: make_drop_item
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"config/excel/cfg_drop_item_excel.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0)  end."
escript ./script/make/gen_drop_item.es

:: make_special_drop
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"config/excel/cfg_special_drop_excel.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
escript ./script/make/gen_special_drop.es

:: make_treasure
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"config/excel/cfg_rune_treasure_excel.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0)  end."
escript ./script/make/gen_treasure.es

:: make_gold_log
escript ./script/make/gen_gold_log.es

:: make_record_info
escript ./script/make/gen_record_info.es

:: make_map_multi
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case make:files([\"src/map/map_compile.erl\"], [{outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
escript %SHELL_DIR%/ebin/map_compile.beam %SHELL_DIR%/config/map/ %SHELL_DIR%/config/map_dyn/ 

:: make_user_default_hrl
escript ./script/make/gen_user_default_hrl.es

:: erl_compile
erl -pa %SHELL_DIR%/ebin -noinput -meta_root %META_DIR% -eval "case mmake:all(30,[]) of up_to_date -> halt(0); error -> halt(1) end."

:: deploy
copy %SHELL_DIR%\config\app\*.app %SHELL_DIR%\ebin\
copy %SHELL_DIR%\ebin\user_default.beam %SHELL_DIR%\

pause
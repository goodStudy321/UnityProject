::启动脚本
md "logs"
set SERVER_DIR=%~dp0\..\
set t=%time:~0,8%
erl -name windows_loca1_1@127.0.0.1 -pa %SERVER_DIR%/ebin -server_root %SERVER_DIR% -os windows -smp enable +K true +t 10485760 -env ERL_MAX_ETS_TABLES 500000 -env ERL_NO_VFORK 1 +zdbbl 204800 -env ERL_CRASH_DUMP %SERVER_DIR%/windows/logs/%t%.erl_dump -s server_main start -hidden
pause
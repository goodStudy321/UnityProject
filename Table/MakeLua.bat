@echo off
REM ==========================================================
REM Copyright (C) , ???(Loong) jinqiqing@qq.com
REM Created by Loong on 2017-08-29 19:58:52
REM 生成客户端lua配置
REM ==========================================================

title="Excel导出lua配置"

set files= 
:loop
if "%1"=="" (
	set a=%files%
) else (
	set files=%files%  %1&shift /1&goto :loop
)

echo.
echo 开始Excel导出lua配置
echo.

set curDir=%~dp0

set exePath=%curDir%client\lua\exe\Loong.Excel.Lua.exe


if "%files%"==" " (
	goto :NOFILE

) else (
	goto :HASFILE
)

:NOFILE

set srcDir="SrcDir|%curDir%client\lua\proto"
set temp="Temp|%curDir%client\lua\exe\temp"
set comp="Company|Phantom CO,.LTD"
set headerSym="HeaderSym|*" 
set excelDir="ExcelDir|%curDir%\"


set output="Output|..\LuaCode\Conf"
::echo %output%

cd %curDir%

set path=%exePath% %srcDir% %temp% %comp% %output% %headerSym% %excelDir%
call %path%
goto :END

:HASFILE
set path=%exePath% %files%
call %path%
:END

echo.
echo 结束Excel导出lua配置
echo.

echo.
cd /d %curDir%
set protoDir=%curDir%client\lua\proto
set confDir=..\LuaCode\Conf

set allPath=%confDir%*%protoDir%
make_svn_commit "??" %allPath%

echo.


pause
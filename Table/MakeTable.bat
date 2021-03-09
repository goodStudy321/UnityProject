set CurPath=%~dp0
cd /d %CurPath%
rd %CurPath%.\client\tbl /S /Q
rd %CurPath%..\Assets\table /S /Q
rd %CurPath%.\client\css /S /Q
rem rd %CurPath%..\Pro\Assets\Script\Client\Table /S /Q

start %CurPath%Makelua

TblPacker.exe .\client

rem 转换名字为小写
setlocal
setlocal ENABLEDELAYEDEXPANSION
set path=%CurPath%client\tbl\
set suf="*.tbl"
rem %path% #使用变量
for /f "delims=" %%i in ('dir /b/s/a-d %path%\%suf%') do (
  set h="%%~ni"
  for %%j in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do set h="!h:%%j=%%j!"
  ren "%%i" "!h!"%suf%
)
endlocal

rem mklink /j %CurPath%..\Assets\table %CurPath%client\tbl\
rem mklink /j %CurPath%..\Pro\Assets\Script\Client\Table %CurPath%client\css

xcopy .\client\tbl\*.tbl ..\Assets\table\ /Y
xcopy .\client\css\*.cs ..\Pro\Assets\Script\Client\Table\ /Y

rem copy .\client\tbl\*.tbl ..\Assets\table
rem copy .\client\css\*.cs ..\Pro\Assets\Script\Client\Table


echo.

REM set protoDir=%curDir%client\
set confDir=..\Assets\table
set scriptDir=..\Pro\Assets\Script\Client\Table
set allPath=%confDir%*%scriptDir%
.\make_svn_commit "??" %allPath%



echo.

pause
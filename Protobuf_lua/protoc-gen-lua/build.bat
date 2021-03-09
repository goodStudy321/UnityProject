@echo off
set cur=%~dp0
cd /d %cur%
echo.
echo cur dir:%cd%
echo.
echo beg lua proto generate
echo.
::protoc --plugin=protoc-gen-lua=plugin\protoc_gen_lua.bat --lua_out=. person2.proto
::protoc --lua_out=./ person2.proto
protoc --plugin=protoc-gen-lua=plugin\build.bat --lua_out=. person2.proto
 
echo.
echo end lua proto generate 
echo. 
pause 
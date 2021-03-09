@echo off
set cur=%~dp0
cd /d %cur%
echo.
echo cur dir:%cd%
echo.
echo 开始生成lua-protocol
echo.

set output=../../LuaCode/Protol
set protoc=%cur%protoc-gen-lua/protoc.exe
set protoc_gen_lua=%cur%protoc-gen-lua/plugin/build.bat

cd proto

for %%i in (*.proto) do (    
	%protoc% --plugin=protoc-gen-lua=%protoc_gen_lua% --lua_out=%output% %%i  
	echo 导出: %%i  
  
)  

echo.
echo 结束生成lua-protocol
echo. 
pause 
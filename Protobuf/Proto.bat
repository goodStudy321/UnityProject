@echo off
set dir=%~dp0
cd /d %dir%

set protoDir=%dir%Proto
if not exist %protoDir% (
	mkdir %protoDir%
)

cd /d ../
set csharpDir=%cd%\Pro\Assets\Script\Client\Protocal

if not exist %csharpDir% (
	mkdir %csharpDir%
)

set namespace=Phantom.Protocal

cd /d %protoDir%
echo.
echo 协议Proto目录:%protoDir%
echo 协议CSharp目录:%csharpDir%
echo.

for /R %%i in ("*.proto") do (
	echo 解析协议文件:%%i
	%dir%protoGen.exe -i:%%i -o:%csharpDir%/%%~ni.cs -ns:%namespace%
)
echo.
echo 生成结束
echo.
pause
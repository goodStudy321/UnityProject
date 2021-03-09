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
echo Э��ProtoĿ¼:%protoDir%
echo Э��CSharpĿ¼:%csharpDir%
echo.

for /R %%i in ("*.proto") do (
	echo ����Э���ļ�:%%i
	%dir%protoGen.exe -i:%%i -o:%csharpDir%/%%~ni.cs -ns:%namespace%
)
echo.
echo ���ɽ���
echo.
pause
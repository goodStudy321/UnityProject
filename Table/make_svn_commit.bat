@echo off
REM ===========================================================================    
REM Copyright (C) , ???(Loong) jinqiqing@qq.com
REM Created by Loong on 2019-06-03 23:00:43
REM ===========================================================================    

set TortoiseProc="C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe"

if not exist %TortoiseProc% (
	set TortoiseProc="D:\Program Files\TortoiseSVN\bin\TortoiseProc.exe"
)

if not exist %TortoiseProc% (
	set TortoiseProc="TortoiseProc"
)

%TortoiseProc% /command:commit /logmsg:%1 /path:%2 /closeonend:0

pause
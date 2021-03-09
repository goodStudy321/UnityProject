package.cpath = package.cpath .. ";c:/Users/admin/.vscode/extensions/tangzx.emmylua-0.2.8-22/debugger/emmy/windows/x64/?.dll"
local dbg = require("emmy_core")
dbg.tcpListen("localhost", 9966)
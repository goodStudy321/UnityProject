--[[
  AU  : Loong
  TM  : 2018-04-20T11:55:57.615Z
  DES :
--]]
local my_tos = require("Protol/myperson_tos_pb")

TestLuaProto = {}

local My = TestLuaProto

function My.Receive(msg)
  --print("从服务器接收lua消息:", tostring(msg))
end

ProtoLsnr.Add(20002, My.Receive)



function My.Send()
  local msg = My.CreateMsg()
  --print("发送lua测试协议内容:", tostring(msg))
  ProtoMgr.Send(msg)
end


--创建消息
function My.CreateMsg()
  local msg = my_tos.myperson_tos()
  local random = math.random
  msg.header.cmd = random(1, 20)
  msg.header.seq = random(21, 40)
  msg.id = random(90000, 100000)
  msg.name = "Loong"
  msg.array:append(random(201, 300))
  msg.array:append(random(301, 400))
  return msg
end

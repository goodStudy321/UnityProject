--[[
 	author 	    :Loong
 	date    	:2018-04-04 10:03:49
 	descrition 	:累加计时器
--]]

AddTimer = iTimer:New{Name = "AddTimer"}

local base = iTimer
local My = AddTimer

function My:Ctor()
  base.Ctor(self)
  --已过时间提示
  self.past = ""
end

function My:Start()
  base.Start(self)
  self.seconds = 3600 * 12
  self:Invl()
end

function My:Invl()
  self.past = DateTool.FmtSec(self.cnt)
end

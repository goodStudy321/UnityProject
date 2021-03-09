--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-08-21 19:57:26
--==============================================================================


DateTimer = iTimer:New{Name = "DateTimer"}
local TimeSpan = System.TimeSpan
local My = DateTimer

local base = iTimer


function My:Ctor()
  base.Ctor(self)
  --剩余时间提示
  self.remain = ""
  --格式化选项(0:00天00时00分00秒,1:00D00H00M00S,2:00d00h00m00s,3:00:00:00:00)
  self.fmtOp = 0

  --true:位数选项0:无, 1:至少分数两位 2:至少小时两位,3:至少天数两位
  self.apdOp = 0
end

function My:Start()
  base.Start(self)
  self:Invl()
end

function My:Invl()
  local rs = self.seconds - self.cnt
  self.remain = DateTool.FmtSec(rs, self.fmtOp, self.apdOp)
end

function My:Dispose()
  self.fmtOp = 0
  self.apdOp = false
  base.Dispose(self)
end
--一天的倒计时
function My:OnedayDownStart( )
  self.seconds=TimeTool.GetSeverTimeRemain();
  self:Start();
end

return My

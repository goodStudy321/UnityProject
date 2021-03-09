--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-08-21 23:33:19
--==============================================================================

DatePlus = Super:New{Name = "DatePlus"}

local My = DatePlus

local TimeSpan = System.TimeSpan

function My:Ctor()
  --过去时间
  self.past = ""
  --总计时器
  self.cnt = 0
  --间隔时间
  self.invl = 1
  --间隔计时器
  self.invlCnt = 0
  --true:运行中
  self.running = false
  --true忽略时间缩放
  self.ignoreScale = true
end

--开始 参数为开始时间
function My:Start(beg)
  beg = beg or 0
  if self.running then return end
  self.cnt = Time.realtimeSinceStartup - beg
  self.running = true
  self:Format()
end

function My:Update()
  if not self.running then return end
  local delta = 0
  if self.ignoreScale then
    delta = Time.unscaledDeltaTime
  else
    delta = Time.deltaTime
  end
  self.cnt = self.cnt + delta
  self.invlCnt = self.invlCnt + delta
  if self.invlCnt > self.invl then
    self.invlCnt = 0
    self:Format()
  end
end

function My:Format()
  self.past = DateTool.FmtSec(self.cnt)
end

function My:Stop()
  self.running = false
  self:Reset()
end

function My:Reset()
  self.cnt = 0
  self.invlCnt = 0
end

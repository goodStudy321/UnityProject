--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 01:38:10
-- 可注册onValue
--=========================================================================

TweenValue = TweenBase:New{Name = "TweenValue"}

local My, base = TweenValue, TweenBase

function My:Ctor()
  base.Ctor(self)
  self.from = 1
  self.to = 0
  self.onValue = Event()
end

function My:Sample(t)
  local val = self.from + (self.to - self.from) * t
  self.onValue(val)
end

function My:Start(from, to, dur, delay)
  if self.running then return end
  self.from = from
  self.to = to
  base.Start(self, dur, delay)
end

function My:Dispose()
  base.Dispose(self)
  self.onValue:Clear()
end

return My

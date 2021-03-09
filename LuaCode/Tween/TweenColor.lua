 --=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 02:05:12
-- 颜色插值动画
--=========================================================================

TweenColor = TweenBase:New{Name = "TweenColor"}

local My, base = TweenColor, TweenBase

function My:Ctor()
  base.Ctor(self)
  self.color = Color.New()
  self.onValue = Event()
end

function My:Sample(t)
  local color, from, to = self.color, self.from, self.to
  color.r = from.r + (to.r - from.r) * t
  color.g = from.g + (to.r - from.r) * t
  color.b = from.b + (to.b - from.b) * t
  color.a = from.a + (to.a - from.a) * t
  self.onValue(color)
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

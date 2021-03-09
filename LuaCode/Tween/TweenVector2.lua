--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 01:38:24
-- 二维向量插值动画
--=========================================================================

TweenVector2 = TweenBase:New{Name = "TweenVector2"}

local My, base = TweenVector2, TweenBase

function My:Ctor()
  base.Ctor(self)
  self.vec = Vector2.New()
  self.onValue = Event()
end

function My:Sample(t)
  local vec, from, to = self.vec, self.from, self.to
  vec.x = from.x + (to.x - from.x) * t
  vec.y = from.y + (to.y - from.y) * t
  self.onValue(vec)
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

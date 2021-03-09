--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 01:38:32
-- 三维向量插值动画
--=========================================================================

TweenVector3 = TweenBase:New{Name = "TweenVector3"}

local My, base = TweenVector3, TweenBase

function My:Ctor()
  base.Ctor(self)
  self.vec = Vector3.New()
  self.onValue = Event()
end

function My:Sample(t)
  local vec, from, to = self.vec, self.from, self.to
  vec.x = from.x + (to.x - from.x) * t
  vec.y = from.y + (to.y - from.y) * t
  vec.z = from.z + (to.z - from.z) * t
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

--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 02:20:35
-- 变换组件属性基类,应该使用TweenPos,TweenEuler,TweenScale
--=========================================================================

TweenTranProp = TweenBase:New{Name = "TweenTranProp"}

local My, base = TweenTranProp, TweenBase

function My:Ctor()
  base.Ctor(self)
  self.vec = Vector3.New()
end

function My:Sample(t)
  local vec, from, to = self.vec, self.from, self.to
  vec.x = from.x + (to.x - from.x) * t
  vec.y = from.y + (to.y - from.y) * t
  vec.z = from.z + (to.z - from.z) * t
end

--from(Vector3):开始值
--to  (Vector3):结束值
--target(Transform):目标组件
--isLocal(boolean):相对
function My:Start(from, to, target, isLocal, dur, delay)
  if self.running then return end
  self.from = from
  self.to = to
  self.target = target
  self.isLocal = isLocal or false
  base.Start(self, dur, delay)
end

function My:Dispose()
  base.Dispose(self)
  self.target = nil
  self.isLocal = false
end

return My

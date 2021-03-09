--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 01:40:20
-- 变换组件插值动画
--=========================================================================


TweenTran = TweenBase:New{Name = "TweenTran"}

local My, base = TweenTran, TweenBase


function My:Ctor()
  self.pos = Vector3.New()
  self.euler = Vector3.New()
  self.scale = Vector3.New()
  base.Ctor(self)
end

function My:Sample(t)
  self:SetVec(self.bPos, self.ePos, self.pos)
  self:SetVec(self.bEuler, self.eEuler, self.euler)
  self:SetVec(self.bScale, self.eScale, self.scale)
  local target = self.target
  target.position = self.pos
  target.eulerAngles = self.euler
  target.localScale = self.scale
end

function My:SetVec(from, to, vec)
  vec.x = from.x + (to.x - from.x) * t
  vec.y = from.y + (to.y - from.y) * t
  vec.z = from.z + (to.z - from.z) * t
end

--from(Tranform):起始变换
--to  (Transform):结束变换
--target(Tranform):目标变换
function My:Start(from, to, target, dur, delay)
  if self.running then return end
  self.bPos = from.position
  self.ePos = to.position
  self.bEuler = from.eulerAngles
  self.eEuler = to.eulerAngles
  self.bScale = from.localScale
  self.eScale = to.localScale
  self.target = target
  base.Start(self, dur, delay)
end

function My:Dispose()
  base.Dispose(self)
  self.to = nil
  self.from = nil
  self.target = nil
end

return My

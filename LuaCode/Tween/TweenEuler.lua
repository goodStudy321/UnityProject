--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 01:39:26
-- 变换组件欧拉角插值动画
--=========================================================================

TweenEuler = TweenTranProp:New{Name = "TweenEuler"}

local My, base = TweenEuler, TweenTranProp

function My:Sample(t)
  base.Sample(self, t)
  if self.isLocal then
    self.target.localEulerAngles = self.vec
  else
    self.target.eulerAngles = self.vec
  end
end


return My

--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 01:38:44
-- 变换组件插值动画
--=========================================================================


TweenPos = TweenTranProp:New{Name = "TweenPos"}

local My, base = TweenPos, TweenTranProp

function My:Sample(t)
  base.Sample(self, t)
  if self.isLocal then
    self.target.localPosition = self.vec
  else
    self.target.position = self.vec
  end
end


return My

--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 01:39:16
-- 变换组件欧缩放插值动画
--=========================================================================

iTweenScale = TweenTranProp:New{Name = "iTweenScale"}

local My, base = iTweenScale, TweenTranProp

function My:Sample(t)
  base.Sample(self, t)
  self.target.localScale = self.vec
end


return My

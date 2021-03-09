--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-06-07 14:34:10
-- 前置引导条件
--=========================================================================


GuideLinkCond = GuideCond:New{Name = "GuideLinkCond"}

local My = GuideLinkCond

--通过上一个完成引导配置,判断是否可达成
function My:ChkTrig(cfg)
  local dic = self.dic
  local k = tostring(cfg.id)
  local linkCfg = dic[k]
  self:Trigger(k, linkCfg)
end

return My

--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 11/1/2018, 10:39:58 AM
-- 符文镶嵌标记
--=============================================================================

RuneEmbedFlag = Flag:New{Name = "RuneEmbedFlag"}

local My, base = RuneEmbedFlag, Flag


function My:Init()
  base.Init(self)
  RuneMgr.eExp:Add(self.Update, self)
  RuneMgr.eUpdateBag:Add(self.Update, self)
  RuneMgr.eUpdateEmbed:Add(self.Update, self)
end

function My:Update()
  self.red = false
  if not RuneMgr.isOpen then return end
  local exp = RuneMgr.exp
  local embedDic = RuneMgr.embedDic
  -- for k ,v in pairs(embedDic) do
  --     if (v.lvCfg.lv < 50) then
  --         if(v.lvCfg.upExp<=exp) then
  --             self.red = true
  --             break
  --         end
  --     end
  -- end
  
  local rmaxLv = 0
  for k, v in pairs(embedDic) do
    lv = v.lvCfg.lv
    rmaxLv = RuneMgr.GetMaxLv(v.cfg)
    if (lv < rmaxLv) then
      local upExp = v.lvCfg.upExp
      if(exp >= upExp) then
        self.red = true
        break
      end
    end
  end
  if RuneMgr.CanEmbed then
    self.red = true
  elseif RuneMgr.HasBetter then
    self.red = true
  end

  --iTrace.Error("Loong", "X1 CanEmbed:", RuneMgr.CanEmbed, "HasBetter:", RuneMgr.HasBetter)
  self.eChange(self.red)
end

return My

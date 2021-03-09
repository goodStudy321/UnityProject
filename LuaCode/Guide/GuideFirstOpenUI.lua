--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-06-20 17:46:09
-- 首次打开UI
--=========================================================================

GuideFirstOpenUI = GuideCond:New{ Name = "GuideFirstOpenUI" }

local My = GuideFirstOpenUI


function My:Init()
	euiopen:Add(self.UIOpen, self)
	--k:ui名,v:打开次数
	self.countDic =  {}
end


function My:UIOpen(name)
	local count = self.countDic[name] or 1
	if count > 1 then
		self.countDic[name] = self.countDic[name] + 1
	else
  		self.countDic[name] = 1
		local cfg = self.dic[name]
  		self:Trigger(k, cfg)
  	end
end


function My:Dispose()
	euiopen:Remove(self.UIOpen, self)
end


return My
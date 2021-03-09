--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-05-23 15:13:33
-- 血量更新条件
-- 参数1:判断ID是否相等,至于是什么ID不用管
-- 参数2:小于此值时条件达成
--=========================================================================

GuideHpCond = GuideCond:New{ Name = "GuideHpCond" }

local My, base = GuideHpCond, GuideCond


function My:Init()
	--添加血量更新事件
	NetBoss.eBossBlood:Add(self.HpChange,self)
	--条件配置列表(GuideCfg条目)
	self.lst = {}
end

--id(number)
--val(number):血量值
function My:HpChange(id, val)
	local lst,v,tArg1,tArg2 = self.lst
	for i=#lst,1,-1 do
		v = lst[i]
		tArg1 = v.tArg
		tArg2 = v.tArg2 or 1000000
		if tArg1 == id then
			if val < tArg2 then
				self.success(self, v)
				ListTool.Remove(lst, i)
			end
		end
	end
end

function My:SetCfg(cfg)
	if cfg == nil then return end
	self.lst[#self.lst + 1] = cfg 
end


function My:Dispose()
	base.Dispose(self)
	--移除血量更新事件
	NetBoss.eBossBlood:Remove(self.HpChange,self)
end


return My
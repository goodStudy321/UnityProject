--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-04-09 14:29:59
--=========================================================================

UISettingPushItem = Super:New{ Name = "UISettingPushItem" }

local My = UISettingPushItem

My.weeks = {"一","二","三","四","五","六","日"}

function My:Init(root, cfg)
	self.cfg = cfg
	local CG, des = ComTool.Get, self.Name
	local nameLbl = CG(UILabel, root, "name", des)
	nameLbl.text = cfg.name
	local cycleLbl = CG(UILabel, root, "cycle", des)
	cycleLbl.text = self:GetCycleText(cfg)
	local timeLbl = CG(UILabel, root, "time", des)
	timeLbl.text = self:GetTimeText(cfg)
	self.tog = CG(UIToggle, root, "active", des)
	self.tog.value = self:SetTogValue()
    UITool.SetLsnrClick(root,"active",des,self.OnTogChange, self, false)
end

--获取时间字符
function My:GetTimeText(cfg)
	local str = ""
	local len = #cfg.time
	for i,v in ipairs(cfg.time) do
		if v < 10 then 
			str = str .. "0" .. v
		else
			str = str .. v
		end
		if i < len then str = str .. ":" end
	end
	return str
end

--获取周期描述字符
function My:GetCycleText(cfg)
	local len = #cfg.cycle
	local weeks = self.weeks
	local str = ""
	for i,v in ipairs(cfg.cycle) do
		local week = weeks[v]
		str = str .. week
		if i < len then str = str .. "、" end
	end
	return str
end

function My:SetTogValue()
	do return PushMgr:IsActive(self.cfg.id) end
end


function My:OnTogChange()
	local cntr = self.cntr
	if cntr and cntr.OnTogChange then
		cntr:OnTogChange(self.cfg, self.tog.value)
	end
end


function My:Update()

end


function My:Dispose()
	TableTool.ClearUserData()
	self.cntr = nil
end


return My
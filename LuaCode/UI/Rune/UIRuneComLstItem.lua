--[[
 	author 	    :Loong
 	date    	:2018-01-25 14:49:58
 	descrition 	:UI符文合成列表条目
--]]
local base = require("UI/Cmn/UIListItem")

UIRuneComLstItem = base:New{Name = "UIListItem"}

local My = UIRuneComLstItem


function My:Init(root)
	base.Init(self, root)
	self.lockGo = TransTool.FindChild(root, "lock", self.Name)
	--self:SetLockActive()
end

--设置名称
function My:SetName(name)
  local cfg = self.cfg
  self.nameLbl.text = cfg and cfg.name or ("无:"..self.comCfg.id)
end

function My:SetLockActive()
	local tid = self.cfg.towerId
	local pass = CopyMgr:IsFinishCopy(tid)
	self.lockGo:SetActive(not pass)
end

function My:OnClick(go)
	local tid = self.cfg.towerId
	local pass = CopyMgr:IsFinishCopy(tid)
	if pass then
		base.OnClick(self, go)
	else
		local ly = tid - 40000
		local str = "通关九九窥星塔" .. ly .. "层开启"
		UITip.Warning(str)
	end
end

function My:Dispose()
  self.cntr = nil
  self.cfg = nil
  self.comCfg = nil
end

return My

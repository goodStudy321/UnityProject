--region UIFlowers.lua
--Date
--此文件由[HS]创建生成

require("UI/Flowers/UIFlowersSelectBase")
require("UI/Flowers/UIFlowersSelectPlay")
require("UI/Flowers/UIFlowersSelectType")
require("UI/Flowers/UIFlowersSend")
require("UI/Flowers/UIFlowersSendBC")
require("UI/Flowers/UIFlowersReceive")

UIFlowers = UIBase:New{Name = "UIFlowers"}
local M = UIFlowers

function M:InitCustom()
	local name = "可操作提示面板"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.CloseBtn = T(trans, "Close")
	self.SendV = UIFlowersSend:New(T(trans, "SendV"))
	self.SendV.base = self
	self.SendBCV = UIFlowersSendBC:New(T(trans, "SendBV"))
	self.SendBCV.base = self
	self.ReceiveV = UIFlowersReceive:New(T(trans, "ReceiveV"))
	self.ReceiveV.base = self
	self.Eff = T(trans, "Eff")
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.CloseBtn then
		E(self.CloseBtn, self.Close, self)
	end
end

function M:RemoveEvent()
end

function M:SetEvent(fn)
end

function M:SetSendInfo(pId, pName, iName, num, value)
	local bcv = self.SendBCV
	if bcv then
		bcv.PID = pId
		bcv.PName = pName
		bcv.IName = iName
		bcv.Num = num
		bcv.Value = value
	end
end


function M:SelectV(select)
	self:CloseV()
	if select == 1 then
		if self.SendV then
			self.SendV:SetActive(true)
		end
	elseif select == 2 then
		if self.SendBCV then
			self.SendBCV:SetActive(true)
			if self.Eff then self.Eff:SetActive(true) end
		end
	elseif select == 3 then
		if self.ReceiveV then
			self.ReceiveV:SetActive(true)
			if self.Eff then self.Eff:SetActive(true) end
		end
	end
end

function M:OpenCustom()
	self:SetEvent("Add")
	if FlowersMgr.FriendID == nil then
		self:SelectV(1)
	end
end

function M:CloseCustom()
	self:SetEvent("Remove")
	self:Clean()
end

function M:CloseV()
	if self.SendV then
		self.SendV:SetActive(false, false)
	end
	if self.SendBCV then
		self.SendBCV:SetActive(false)
	end
	if self.ReceiveV then
		self.ReceiveV:SetActive(false)
	end
end

function M:Clean()
	if self.SendV then
		self.SendV:Clean(false)
	end
    FlowersMgr.FriendID = nil
end

function M:DisposeCustom()
	self:RemoveEvent()
	if self.SendV then
		self.SendV:Dispose()
	end
	self.SendV = nil
	if self.SendBCV then
		self.SendBCV:Dispose()
	end
	self.SendBCV = nil
end

function M:Update()
end

return M
--endregion

--region UIFlowers.lua
--Date
--此文件由[HS]创建生成

UIFlowersReceive = {}
local M = UIFlowersReceive

local fMgr = FlowersMgr

M.TargetData = nil

function M:New(root)
	self.root = root
	local name = "可操作提示面板"
	local trans = self.root.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Des = C(UILabel, trans, "Des", name, false)
	self.BCBtn = T(trans, "Button1")
	self.KBtn = T(trans, "Button2")
	self.Close = T(trans, "Label")
	self:AddEvent()
	return M
end

function M:AddEvent()
	UITool.SetLsnrSelf(self.BCBtn, self.OnClickBCBtn, self)
	UITool.SetLsnrSelf(self.KBtn, self.OnClickKBtn, self)
	UITool.SetLsnrSelf(self.Close, self.OnClickClose, self)
end

function M:RemoveEvent()
end

function M:UpdateData()
	--[[
	local list = fMgr.ReceiveList
	if not list or #list <= 0 then return end
	self.TargetData = list[1]
	self:UpdateDes()
	table.remove(list, 1)
	]]--
	self.TargetData = fMgr.ReceiveInfo
	if not self.TargetData then return end
	self:UpdateDes()
	--fMgr.eReceive()
end

function M:UpdateDes()
	local data = self.TargetData
	if not data then return end
	local pName = "匿名玩家"
	local iName = "玫瑰花"
	local num = data.Num
	local value = 0 
	if data.IsAnonymous == false and not StrTool.IsNullOrEmpty(data.PName)  then
		pName = data.PName
	end
	if data.IID then
		local item = ItemData[tostring(data.IID)]
		if item then
			iName = item.name
			value = num * item.uFxArg[1]
		end
	end
	if self.Des then
		self.Des.text = string.format("[581F2A][88F8FF]%s[-]被您的魅力所倾倒，送上[f9a7b9]%s*%s[-]，您获得[f9a7b9]%s[-]点魅力值，互为好友还可增加[f9a7b9]%s[-]点亲密度[-]", pName, iName, num, value, value)
	end
end

function M:OnClickBCBtn(go)
	if not self.base then return end
	if not self.TargetData then return end
	if self.TargetData.IsAnonymous == true then
		UITip.Error("匿名玩家无法回赠")
		return
	end
	fMgr.FriendID = self.TargetData.PID
	self.base:SelectV(1)
end

function M:OnClickKBtn(go)
	if not self.base then return end
	if not self.TargetData then return end
	fMgr:ReqFlowerKiss(self.TargetData.PID)
	self.base:Close()
end

function M:OnClickClose(go)
	if not self.base then return end
	self.base:Close()
end


function M:SetActive(value)
	if self.root then 
		if value == true then
			self:UpdateData()
		end
		self.root:SetActive(value) 
	end
end

function M:Clean()
end

function M:Dispose()
	self:Clean()
	self:RemoveEvent()
	self.Des = nil
	self.Btn = nil
end
--endregion

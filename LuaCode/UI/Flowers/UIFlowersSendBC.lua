--region UIFlowers.lua
--Date
--此文件由[HS]创建生成

UIFlowersSendBC = {}
local M = UIFlowersSendBC

local fMgr = FriendMgr

M.base = nil

M.PID = nil
M.PName = nil
M.IName = nil
M.Num = nil
M.Value = nil

function M:New(root)
	self.root = root
	local name = "可操作提示面板"
	local trans = self.root.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Des = C(UILabel, trans, "Des", name, false)
	self.Btn = C(UIButton, trans, "Button", name, false)
	self:AddEvent()
	return M
end

function M:AddEvent()
	UITool.SetLsnrSelf(self.Btn.gameObject, self.OnClickBtn, self)
end

function M:RemoveEvent()
end

function M:UpdateData()
	self:UpdateDes()
end

function M:UpdateDes()
	local pName = "匿名玩家"
	local iName = "玫瑰花"
	local num = self.Num
	local value = self.Value
	if not StrTool.IsNullOrEmpty(self.PName) then
		pName = self.PName
	end
	if not StrTool.IsNullOrEmpty(self.IName) then
		iName = self.IName
	end
	if self.Des then
		self.Des.text = string.format("[581F2A]您向[88F8FF]%s[-]献上[f9a7b9]%s*%s[-]已成功送达！赠人玫瑰手留余香，您获得了[f9a7b9]%s[-]点魅力值！互为好友还可增加[f9a7b9]%s[-]点亲密度[-]", pName, iName, num, value, value)
	end
end

function M:OnClickBtn(go)
	if self.base then
		FlowersMgr.FriendID = self.PID
		self.base:SelectV(1)
	end
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

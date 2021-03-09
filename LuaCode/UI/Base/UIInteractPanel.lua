--region UIInteractPanel.lua
--交互
--此文件由[HS]创建生成
require("UI/UIFriend/UIFriend")

UIInteractPanel = UIBase:New{Name = "UIInteractPanel"}

local M = UIInteractPanel

M.mail = require("UI/Mail/UIMail")

local base = UIBase
--注册的事件回调函数

function M:InitCustom()
	local name = "LUA交互"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.CloseBtn = C(UIButton, trans, "Close", name, false)
	self.FToggle = C(UIToggle, trans, "TopBtn/HY", name, false)
	self.MToggle = C(UIToggle, trans, "TopBtn/YJ", name, false)
	UITool.SetLsnrClick(trans, "TopBtn/YJ", name, self.OnClickYJ, self)
	self.Friend = UIFriend:New(T(trans, "HY"))
	self.Friend.Parent = self
	local mailRoot = TransTool.Find(trans, "YJ", name)
	self.mail:Init(mailRoot)
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.CloseBtn then
		E(self.CloseBtn, self.OnClickCloseBtn, self)
	end
end

function M:RemoveEvent()
end

function M:Open()
	base.Open(self)
	--self.mail:Open()
end

function M:OpenCustom()
	self.Friend:Open()
end

function M:CloseCustom()
	self.mail:Close()
	self.Friend:Close()
end

function M:OnClickCloseBtn(go)
	self:Close()
end

function M:ShowFirend()
	--if self.MToggle then self.MToggle:Set(false,false) end
	if self.FToggle then self.FToggle:Set(true, true) end
end

function M:ShowChat()
	self:ShowFirend()
	local view = self.Friend
	if view then view:ShowChat() end
end

function M:ShowMail()
	--if self.FToggle then self.FToggle:Set(false,false) end
	if self.MToggle then self.MToggle:Set(true, true) end
	self.mail:Open()
end

function M:OnClickYJ()
	self.mail:Open()
end

function M:Clear()
	self.mail:Clear()
end

function M:DisposeCustom()
	self:RemoveEvent()
	if self.Friend then
		self.Friend:Dispose()
	end
	self.Friend = nil
	self.mail:Dispose()
end

return M
--endregion

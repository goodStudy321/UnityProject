--region UIOther.lua
--Date
--此文件由[HS]创建生成

require("UI.UIOther.UIOtherWearsShow")
require("UI.UIOther.UIOtherAttr")

UIOther = UIBase:New{Name ="UIOther"}
local M = UIOther

function M:InitCustom()
	self.Persitent = true;
	local name = "飘属性面板"
	local trans = self.root
	local T = TransTool.FindChild
	self.Wears = ObjPool.Get(UIOtherWearsShow)
	self.Wears:Init(T(trans, "Model/WearsShow"))
	self.Attr = ObjPool.Get(UIOtherAttr)
	self.Attr:Init(T(trans, "RoleAttr"))

end

function M:UpdateData()
	local info = UserMgr.OtherInfo
	if not info then self:Close() return end
	if self.Wears then self.Wears:UpdateInfo(info) end
	if self.Attr then self.Attr:UpdateInfo(info) end
end

function M:OpenCustom()
	self:UpdateData()
end

function M:CloseCustom()
end

function M:DisposeCustom()
	if self.Wears then
		self.Wears:Dispose()
		ObjPool.Add(self.Wears)
	end
	self.Wears = nil
	if self.Attr then
		self.Attr:Dispose()
		ObjPool.Add(self.Attr)
	end
	self.Attr = nil
end

return M

--endregion

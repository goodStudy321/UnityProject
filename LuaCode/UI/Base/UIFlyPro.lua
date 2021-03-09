--region UIFlyPro.lua
--Date
--此文件由[HS]创建生成
require("UI/UIFlyPro/UIFlyTop")
require("UI/UIFlyPro/UIFlyCenter")
require("UI/UIFlyPro/UIFlyBottom")
require("UI/UIFlyPro/UIFlyItem")

UIFlyPro = UIBase:New{Name ="UIFlyPro"}
local P = UIFlyPro

function P:InitCustom()
	self.Persitent = true;
	local name = "飘属性面板"
	local trans = self.root
	local T = TransTool.FindChild
	self.FlyTop = ObjPool.Get(UIFlyTop)
	self.FlyTop:Init(T(trans, "Top"))
	self.FlyCenter = ObjPool.Get(UIFlyCenter)
	self.FlyCenter:Init(T(trans, "Center"))
	--self.FlyBottom = ObjPool.Get(UIFlyBottom)
	--self.FlyBottom:Init(T(trans, "Bottom"))
	self.FlyItem = ObjPool.Get(UIFlyItem)
	self.FlyItem:Init(T(trans, "Item"))

	SceneMgr.eChangeEndEvent:Add(self.ChangeEndEvent, self)
end

function P:ConDisplay()
	do return true end
end

function P:OpenCustom()
	if self.FlyItem then
		self.FlyItem:Open()
	end
	
end

function P:CloseCustom()
	self:ChangeEndEvent(false)
	if self.FlyTop then
		self.FlyTop:Close()
	end
end

function P:ChangeEndEvent(isLoad)
	--[[
	if self.FlyCenter then
		self.FlyCenter:CleanItems()
	end
	]]--
	--[[
	if self.FlyTop then
		self.FlyTop:CleanItems()
	end
	]]--
end

function P:Update()
	if self.FlyTop then
		self.FlyTop:Update()
	end
	if self.FlyCenter then
		self.FlyCenter:Update()
	end
	--if self.FlyBottom then
	--	self.FlyBottom:Update()
	--end
	if self.FlyItem then
		self.FlyItem:Update()
	end
end

function P:DisposeCustom()
	SceneMgr.eChangeEndEvent:Remove(self.ChangeEndEvent, self)
	self:ChangeEndEvent(false)
	if self.FlyTop then
		self.FlyTop:Dispose()
		ObjPool.Add(self.FlyTop)
	end
	self.FlyTop = nil
	if self.FlyCenter then
		self.FlyCenter:Dispose()
		ObjPool.Add(self.FlyCenter)
	end
	self.FlyCenter = nil
	--if self.FlyBottom then
	--	self.FlyBottom:Dispose()
	--	ObjPool.Add(self.FlyBottom)
	--end
	--self.FlyBottom = nil
	if self.FlyItem then
		self.FlyItem:Dispose()
		ObjPool.Add(self.FlyItem)
	end
	self.FlyItem = nil
end

return P

--endregion

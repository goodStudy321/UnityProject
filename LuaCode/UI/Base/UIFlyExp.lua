--region UIFlyPro.lua
--Date
--此文件由[HS]创建生成
require("UI/UIFlyPro/UIFlyBottom")

UIFlyExp = UIBase:New{Name ="UIFlyExp"}
local P = UIFlyExp

function P:InitCustom()
	self.Persitent = true;
	local name = "飘经验面板"
	local trans = self.root
	local T = TransTool.FindChild
	self.FlyBottom = ObjPool.Get(UIFlyBottom)
	self.FlyBottom:Init(T(trans, "Bottom"))

	SceneMgr.eChangeEndEvent:Add(self.ChangeEndEvent, self)
end

function P:ConDisplay()
	do return true end
end

function P:OpenCustom()
end

function P:CloseCustom()
	self:ChangeEndEvent(false)
end

function P:ChangeEndEvent(isLoad)
end

function P:Update()
	if self.FlyBottom then
		self.FlyBottom:Update()
	end
end

function P:DisposeCustom()
	SceneMgr.eChangeEndEvent:Remove(self.ChangeEndEvent, self)
	self:ChangeEndEvent(false)
	if self.FlyBottom then
		self.FlyBottom:Dispose()
		ObjPool.Add(self.FlyBottom)
	end
	self.FlyBottom = nil
end

return P

--endregion

--[[
品质，icon，Lab
]]
BaseCell=Super:New{Name="BaseCell"}
local My = BaseCell

function My:CustomData(qua,iconPath,lab)
    if self.Qua then self.Qua.spriteName=UIMisc.GetQuaPath(qua) end
    if self.Icon then AssetMgr:Load(iconPath,ObjHandler(self.LoadIcon,self)) end
    if self.lab then self.lab.text=lab end
end

function My:LoadIcon(obj)
    self.Icon.mainTexture=obj
end

function My:DisposeCustom()
-- body
end

function My:Dispose()
    if self.Qua then self.Qua.spriteName=UIMisc.GetQuaPath(1) end
    if self.Icon then self.Icon.mainTexture=nil end
    if self.lab then self.lab.text="" end
end






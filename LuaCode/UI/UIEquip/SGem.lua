--[[
宝石格子位置类
--]]
local AssetMgr=Loong.Game.AssetMgr
SGem={Name="SGem"}
local My=SGem

function My:New(o)
	o =o or {}
	setmetatable(o,self)
	self.__index=self
	return o
end

function My:Init(go)
	self.go=go
	local TF=TransTool.FindChild
	local CG=ComTool.Get

	self.Qua=self.go:GetComponent(typeof(UISprite))
	self.Icon=CG(UITexture,self.Qua.transform,"Icon",self.Name,false)
	self.Lab =CG(UILabel,self.Qua.transform,"Label",self.Name,false)

end

function My:UpData(type_id)
	local item=ItemData[tostring(type_id)]
	if(item==nil)then iTrace.Error("Loong", "item==null") end
	self:UpQua(item)
	self:UpIcon(item)
	self:UpLab(item)
end

function My:UpQua(item)
	self.Qua.spriteName=UIMisc.GetQuaPath(item.quality)
end

function My:UpIcon(item)
	AssetMgr.Instance:Load(item.icon, ObjHandler(self.LoadIcon, self))
end

function My:LoadIcon(obj)
	self.Icon.mainTexture=obj
end

function My:UpLab(item)
	self.Lab.text=item.name
end


function My:Dispose()
	self.Lab.text=""
	self.Qua.spriteName=UIMisc.GetQuaPath(0)
	self.Icon.mainTexture=nil
	self.Icon.enabled=false
	self.Icon.enabled=true
end
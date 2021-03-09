--[[
足迹
]]
DisplayFoot=Super:New{Name="DisplayFoot"}
local My = DisplayFoot

function My:Init(go)
	self.go=go
    local trans = go.transform
    self.texture=trans:GetComponent(typeof(UITexture))
end

function My:LoadTex()
    AssetMgr:Load(self.path,ObjHandler(self.LoadCb,self))
end

function My:LoadCb(obj)
    self.texture.mainTexture=obj
end

function My.IsTrue(type_id)
    local istrue,path = false,nil
	local item = UIMisc.FindCreate(type_id)
	if item.uFx==41 then --看是否是足迹
		local temp = FashionAdvCfg[tostring(type_id)]
		if temp and temp.type==5 then
			istrue=true
			path=item.icon
		end
	end	
	return istrue,path
end

function My:Dispose()
    
end
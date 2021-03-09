--[[
头像框
]]
DisplayHead=Super:New{Name="DisplayHead"}
local My = DisplayHead

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
	if item.uFx==41 then --看是否是头像框
		local temp = FashionChat[tostring(tonumber(type_id)/100)]
		if temp and temp.type==2 then
			istrue=true 
			path=item.icon
		end
	end	
	return istrue,path
end

function My:Dispose()
    
end
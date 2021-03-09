--[[
仓库
]]
require("UI/UIStoreHouse/UIHouseY")
require("UI/UIBackpack/UIContentX")
UIStoreHouse=UIBase:New{Name="UIStoreHouse"}
local My = UIStoreHouse

function My:InitCustom( ... )
    local TF=TransTool.FindChild
    self.pre=TF(self.root,"bg/00")
	self.Panel=ObjPool.Get(UIHouseY)
	self.Panel:Init(TF(self.root,"bg"),1,false,self.pre)
    self.Panel:Open()
    
    UITool.SetBtnClick(self.root,"CloseBtn",self.Name,self.Close,self,false)
end

function My:DisposeCustom()
    if self.Panel then ObjPool.Add(self.Panel) end
end

return My
--[[
获取来源
--]]
require("UI/UIGet/UIGetBase")
UIGetItem=UIBase:New{Name="UIGetItem"}
local My = UIGetItem

function My:InitCustom()
    local trans = self.root
    local U = UITool.SetBtnClick
    U(trans,"CloseBtn",self.Name,self.Close,self)
    self.baseCell=ObjPool.Get(UIGetBase)
    self.baseCell:Init(trans,Vector3.New(0,49.5,0))
end

function My:UpData(part)  
    if part=="9" then
        self.baseCell:UpData(1)
    elseif part=="10" then
        self.baseCell:UpData(2)
    elseif part=="11" then
        self.baseCell:UpData(3)
    elseif part=="12" then
        self.baseCell:UpData(4)
    end
end

function My:CloseCustom()
    if self.baseCell then ObjPool.Add(self.baseCell) self.baseCell=nil end
end

return My
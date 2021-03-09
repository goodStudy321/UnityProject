--[[
V级限购
--]]
require("UI/UIVIPStore/VIPLvCell")
VIPPanel=Super:New{Name="VIPPanel"}
local My = VIPPanel

function My:Init(go)
    self.go=go
    local trans = go.transform
    local TF = TransTool.FindChild
    local CG = ComTool.Get
    self.grid=CG(UIGrid,trans,"Panel/Grid",self.Name,false)
    self.cPre=TF(trans,"C")

    self:UpData()
    self:OnRed()

    VIPMgr.eVIPStoreRed:Add(self.OnRed,self)
end

function My:UpData()
    for i,v in ipairs(VIPLv) do
        if i>1 then 
            local cell=ObjPool.Get(VIPLvCell)
            cell:Init(self.cPre,self.grid.transform)
            if not self.list then self.list={} end
            cell:UpData(i,v.vipTag) --TODO
            self.list[#self.list+1]=cell
        end
    end
end

function My:OnRed()
    local dic = VIPMgr.VipsRed["5"]
    for i,v in ipairs(self.list) do
        local state = dic[i] or false
        v:OnRed(state)
    end
end


function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.go:SetActive(false)
end

function My:Dispose()
    VIPMgr.eVIPStoreRed:Remove(self.OnRed,self)
    ListTool.ClearToPool(self.list)
    TableTool.ClearUserData(self)
    My=nil
end

--[[

--]]
require("UI/UIVIPStore/VIPStoreCell")
VIPStorePanel=Super:New{Name="VIPStorePanel"}
local My = VIPStorePanel

function My:Init(go)
    self.go=go
    local trans = go.transform
    local TF = TransTool.FindChild
    local CG = ComTool.Get
    self.grid=CG(UIGrid,trans,"Panel/Grid",self.Name,false)
    self.cPre=TF(trans,"C")
    self.lab=CG(UILabel,trans,"Label",self.Name,false)

    self:UpData()
end

function My:UpData(tp)
    ListTool.ClearToPool(self.list)
    local lv=VIPMgr.GetVIPLv() --当前等级
    local vipShow=nil
    if lv ==0 then
        vipShow=GlobalTemp["92"].Value2
    else
        self:UpDay(lv)
        local data = VIPLv[lv+1]
        vipShow= data.vipShow        
    end
    if vipShow then
        for i,v in ipairs(vipShow) do
            self:UpDay(v)
        end 
    end
    self.grid:Reposition()

    self.lab.text="每日24点重置，当前VIP "..VIPMgr.GetVIPLv()
end


function My:UpDay(lv)   
    local cell=ObjPool.Get(VIPStoreCell)
    cell:Init(self.cPre,self.grid.transform)
    if not self.list then self.list={} end
    cell:UpData(lv)
    self.list[#self.list+1]=cell
end

function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.go:SetActive(false)
end

function My:Dispose()
    ListTool.ClearToPool(self.list)
    TableTool.ClearUserData(self)
    My=nil
end
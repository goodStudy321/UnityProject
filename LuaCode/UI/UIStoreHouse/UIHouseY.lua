--[[

]]
require("UI/UIBackpack/UIContentY")
require("UI/UIBackpack/UIContentX")
UIHouseY=UIContentY:New{Name="UIHouseY"}
local My = UIHouseY

function My:InitCustom()
    if not self.list  then self.list={} end
    self:Create(7,6) 
end

function My:SetEvent(fn)
    SecretAreaMgr.eGood[fn](SecretAreaMgr.eGood,self.UpdateView,self)
end

function My:UpDataList(indexStart)
    local list = SecretAreaMgr.GoodsList
    local indexEnd = indexStart+self.Xnum-1
    if indexEnd+1>self.maxNum then indexEnd=self.maxNum-1 end
    for i=indexStart,indexEnd do
        local cell=self:GetCell(i)
        local kv = list[i+1]
        if kv then
            self:RefreshCell(kv,cell)
        else
            cell:Clean()
        end
        cell.index=i
    end
end

function My:RefreshCell(kv,cell)
    cell:UpData(kv.k,kv.v)
end

--一键取出
function My:SortOut()
    SecretAreaNetwork.ReqTakeOut()
end
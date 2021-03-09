require("UI/UIMoonLove/MScoreIt")

MoonScore=Super:New{Name="MoonScore"}
local My = MoonScore

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    local closeBtn = TFC(trans,"CloseBtn",name)
    self.grid = CG(UIGrid,trans,"bg/Panel/Grid",name)
    self.prefab = TF(trans,"bg/Panel/Grid/C",name)
    self.prefab.gameObject:SetActive(false)
    self.itemTab = {}
    US(closeBtn,self.Close,self)
    self:SetEvent("Add")
    self:RefreshData()
end

function My:SetEvent(fn)
    MoonLoveMgr.eMoonExchange[fn](MoonLoveMgr.eMoonExchange,self.RefreshData,self)
end

function My:Open()
    self:RefreshData()
    self.Gbj:SetActive(true)
end

function My:Close()
    self.Gbj:SetActive(false)
end

function My:RefreshData()
    local data = MoonLoveMgr:GetExchangeRew()
    local len = #data
    local itemTab = self.itemTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:SetActive(true)
            itemTab[i]:UpdateData(data[i])
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform,go.transform)
            local item = ObjPool.Get(MScoreIt)
            item:Init(go,self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(self.itemTab,item)
        end
    end
    self.grid:Reposition()
end

function My:AddPool()
    self:TabToPool(self.itemTab)
end

function My:TabToPool(tab)
    for k,v in pairs(tab) do
        ObjPool.Add(v)
        tab[k] = nil
    end
end

function My:Dispose()
    self:SetEvent("Remove")
    self:AddPool()
    TableTool.ClearUserData(self)
end
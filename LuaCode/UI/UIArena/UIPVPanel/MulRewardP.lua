MulRewardP = Super:New{Name = "MulRewardP"}
local My = MulRewardP

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.grid = CG(UIGrid,trans,"grid",name)
    self.prefab = TF(trans,"grid/reItem",name)
    self.prefab.gameObject:SetActive(false)
    self.itemTab = {}
end

function My:ActiveItems(ac)
    local tab = self.itemTab
    local len = #tab
    if len <= 0 then return end
    for i = 1,len do
        local it = tab[i]
        it:SetActive(ac)
    end
    self.grid:Reposition()
end

function My:RefreshData()
    local data = Peak:GetPVPRankRe(2)
    local len = #data
    local itemTab = self.itemTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpdateData(data[i])
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform,go.transform)
            local item = ObjPool.Get(MulRewardIt)
            item:Init(go)
            item.Gbj.name = (i+10)
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
    self:AddPool()
    TableTool.ClearUserData(self)
end
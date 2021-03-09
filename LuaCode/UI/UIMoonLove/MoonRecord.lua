require("UI/UIMoonLove/MRecordIt")

MoonRecord=Super:New{Name="MoonRecord"}
local My = MoonRecord

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    local closeBtn = TFC(trans,"CloseBtn",name)
    local sureBtn = TFC(trans,"surBtn",name)
    self.scV = CG(UIScrollView,trans,"bg/Panel",name)
    self.grid = CG(UIGrid,trans,"bg/Panel/Grid",name)
    self.prefab = TF(trans,"bg/Panel/Grid/des",name)
    self.prefab.gameObject:SetActive(false)
    self.itemTab = {}
    self.maxRecordIndex = 888888
    US(closeBtn,self.Close,self)
    US(sureBtn,self.Close,self)
    self:SetEvent("Add")
    self:RefreshData()
    -- self:AddLogs()
end

function My:SetEvent(fn)
    MoonLoveMgr.eAddRecord[fn](MoonLoveMgr.eAddRecord,self.AddLogs,self)
end

function My:Open()
    self.Gbj:SetActive(true)
    if not LuaTool.IsNull(self.scV) then
        self.scV:ResetPosition()
    end
end

function My:Close()
    self.Gbj:SetActive(false)
end

function My:AddLogs()
    local addLogsTab = MoonLoveMgr.moonInfoTab.addRecordTab
    if addLogsTab == nil or #addLogsTab == 0 then
        return
    end
    local data = addLogsTab
    local len = #data
    local itemTab = self.itemTab
    local name = 0
    for i = 1,len do
        self.maxRecordIndex = self.maxRecordIndex + i
        name = self.maxRecordIndex
        if not LuaTool.IsNull(self.prefab) then
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform,go.transform)
            local item = ObjPool.Get(MRecordIt)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            item:SetName(name)
            table.insert(self.itemTab,item)
        end
    end
    self.maxRecordIndex = self.maxRecordIndex - 1000
    if not LuaTool.IsNull(self.grid) then
        self.grid:Reposition()
    end
    if not LuaTool.IsNull(self.scV) then
        self.scV:ResetPosition()
    end
end

function My:RefreshData()
    -- local logsTab = MoonLoveMgr.moonInfoTab.addRecordTab
    -- if logsTab == nil then
    --     logsTab = MoonLoveMgr.moonInfoTab.recordTab
    -- end
    -- if logsTab == nil or #logsTab == 0 then
    --     return
    -- end
    local logsTab = MoonLoveMgr.moonInfoTab.recordTab
    if logsTab == nil or #logsTab == 0 then
        return
    end
    local data = logsTab
    local len = #data
    local max = 99999999888
    for i = 1,len do
        max = max + 1
        local go = Instantiate(self.prefab)
        TransTool.AddChild(self.grid.transform,go.transform)
        local item = ObjPool.Get(MRecordIt)
        item:Init(go)
        item:SetActive(true)
        item:UpdateData(data[i])
        item:SetName(max)
        table.insert(self.itemTab,item)
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
    self.maxRecordIndex = 888888
    self:SetEvent("Remove")
    self:AddPool()
    TableTool.ClearUserData(self)
end
AvItemInfo = Super:New{Name = "AvItemInfo"}

require("UI/UISoulBearst/AvSBCell")

local M = AvItemInfo

M.Quality = {"白色", "蓝色以下", "紫色以下", "橙色以下", "五元真晶", "全部品质"}
M.Index = {["白色"] = 1, ["蓝色以下"] = 2, ["紫色以下"] = 3,  ["橙色以下"] = 4, ["五元真晶"] = 0, ["全部品质"] = 100}

function M:Ctor()
    self.cellList = {}
    self.selectList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local FC = TransTool.FindChild
    local EA = EventDelegate.Add
    local EC = EventDelegate.Callback

    self.go = go
    
    self.quality = G(UIPopupList, trans, "Quality")
    self.tick = G(UIToggle, trans, "Tick")
    self.btnAdv = FC(trans, "BtnAdv")
    self.sView = G(UIScrollView, trans, "ScrollView")
    self.grid = G(UIGrid, self.sView.transform, "Grid")
    self.prefab = FC(self.grid.transform, "Cell")
    self.prefab:SetActive(false)

    self:InitPopupList()

    S(self.tick, self.OnToggle, self)
    S(self.btnAdv, self.OnAdv, self)
    EA(self.quality.onChange, EC(self.OnQuaSelect, self))
end

function M:InitPopupList()
    self.quality:Clear()
    local list = self.Quality
    for i=1,#list do
        self.quality:AddItem(list[i])
    end
    self.quality.value = list[#list]
end

function M:UpdateData(data)
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform, go.transform)
            local item = ObjPool.Get(AvSBCell)
            item:Init(go)
            item.eClick:Add(self.OnClick, self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.grid:Reposition()
end

function M:ClearSelectData()
    TableTool.ClearDic(self.selectList)
end

function M:OnQuaSelect()
    local quality = self.Index[self.quality.value] or 100
    local data = SoulBearstMgr:GetBagInfo(quality)
    self:ClearSelectData()
    self:CalExpAndGold()
    self:UpdateData(data)
    self.tick.value = false
end

function M:Refresh()
    self:OnQuaSelect()
end

function M:Open()
    self.quality.value = self.Quality[#self.Quality]
end

function M:OnClick(isSelect, data)
    if isSelect then
        TableTool.Add(self.selectList, data, "id")
    else
        TableTool.Remove(self.selectList, data, "id")
    end
    self:CalExpAndGold()
end

function M:OnToggle()
    self:ClearSelectData()
    local list = self.cellList
    for i=1,#list do
        if list[i]:IsActive() then
            list[i]:SetHighlight(self.tick.value)
            if self.tick.value then
                table.insert(self.selectList, list[i].data)
            end
        end
    end
    self:CalExpAndGold()
end

function M:CalExpAndGold()
    SoulBearstMgr:CalExpAndGold(self.selectList)
end

function M:OnAdv()
    local list = self.selectList
    local len = #list
    if len == 0 then
        UITip.Log("请选择强化材料")
        return
    end

    for i=1,len do
        if list[i].quality > 4 or (list[i].quality == 4 and list[i].star >=2) then
            MsgBox.ShowYesNo("所选装备中包含红色或橙色2星以上装备，是否继续强化？", self.YesCb, self)
            return
        end
    end
    SoulBearstMgr:ReqMythicalRefine(self.selectList)
end

function M:YesCb()
    SoulBearstMgr:ReqMythicalRefine(self.selectList)
end

function M:Dispose()
    self:ClearSelectData()
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M
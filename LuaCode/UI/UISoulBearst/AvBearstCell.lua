AvBearstCell = Super:New{Name = "AvBearstCell"}

require("UI/UISoulBearst/AvEquipCell")

local M = AvBearstCell

M.eClick =Event()

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.go = go
    self.icon = G(UISprite, trans, "Icon")
    self.name = G(UILabel, trans, "Name")
    self.score = G(UILabel, trans, "Score")
    self.highlight = FC(trans, "Highlight")
    self.tab = G(UITable, trans, "Table")
    self.prefab = FC(self.tab.transform, "Cell")
    self.tab.gameObject:SetActive(false)
    self.prefab:SetActive(false)

    UITool.SetLsnrSelf(go, self.OnClick, self, self.Name, false)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateName()
    self:UpdateScore()
    self:UpdateIcon()
    self:UpdateCell()
end

function M:GetEquipData()
    local list = {}
    local conds = self.data.condList
    for i=1,#conds do
        if conds[i].isUse then
            table.insert(list, conds[i].equipData)
        end
    end
    return list
end


function M:UpdateCell()
    local data = self:GetEquipData()
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
            TransTool.AddChild(self.tab.transform, go.transform)
            local item = ObjPool.Get(AvEquipCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.tab:Reposition()
end

function M:SetSelect(equipId)
    local list = self.cellList
    local len = #list
    for i=1,len do
        if list[i].data.id == equipId then
            list[i]:OnClick()
            return
        end
    end
    if len > 0 then
        list[1]:OnClick()
    end
end


function M:UpdateName()
    self.name.text = self.data.name
end

function M:UpdateScore()
    self.score.text = string.format("评分：%s", self.data.totalScore)
end

function M:UpdateIcon()
    self.icon.spriteName = self.data.spriteName
end

function M:SetHighlight(state)
    self.highlight:SetActive(state)
end

function M:Switch()
    self.tab.gameObject:SetActive(not self.tab.gameObject.activeSelf)
    self.tab:Reposition()
    self:SetHighlight(not self.highlight.activeSelf)
end

function M:OnEquipCell(data)
    local list = self.cellList
    for i=1,#list do
        list[i]:SetHighlight(list[i].data.id == data.id)
    end
    SoulBearstMgr:SetEquipId(data.id)
    SoulBearstMgr:SetCurSBId(data.user)
end

function M:OnClick()
    if self.data then
        M.eClick(self.data.id)
    end
end

function M:Reset()
    local list = self.cellList
    for i=1,#list do
        list[i]:SetHighlight(false)
    end
    self:SetHighlight(false)
    self:HideEquip()
end

function M:HideEquip()
    self.tab.gameObject:SetActive(false)
    self:SetHighlight(false)
end


function M:SetActive(state)
    self.go:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end


function M:Dispose()
    self.data = nil
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M
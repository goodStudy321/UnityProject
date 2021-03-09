AAVCell = Super:New{Name = "AAVCell"}

require("UI/Robbery/Ares/AAVEquipCell")

local M = AAVCell

M.eClick = Event()

function M:Ctor()
    self.cellList = {}
    self.texList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.go = go
    self.icon = G(UITexture, trans, "Icon")
    self.name = G(UILabel, trans, "Name")
    self.score = G(UILabel, trans, "Score")
    self.highlight = FC(trans, "Highlight")
    self.grid = G(UIGrid, trans, "Grid")
    self.prefab = FC(self.grid.transform, "Cell")
    self.grid.gameObject:SetActive(false)
    self.prefab:SetActive(false)
    self.redPoint = FC(trans, "RedPoint")

    UITool.SetLsnrSelf(go, self.OnClick, self, self.Name, false)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    AAVEquipCell.eClick[key](AAVEquipCell.eClick, self.OnEquipCell, self)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateName()
    self:UpdateScore()
    self:UpdateIcon()
    self:UpdateCell()
    self:UpdateRedPoint()
end

function M:UpdateRedPoint()
    self.redPoint:SetActive(self.data.equipRedPointState)
end

function M:UpdateCell()
    local data = self.data.equipList
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
            local item = ObjPool.Get(AAVEquipCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
   self.grid:Reposition()
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
    self.score.text = string.format("[00FF00FF]开光%s阶", self.data.level)
end


function M:UpdateIcon()
    AssetMgr:Load(self.data.texture, ObjHandler(self.SetIcon, self))
end

function M:SetIcon(tex)
    if self.data then
        self.icon.mainTexture = tex
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end


function M:SetHighlight(state)
    self.highlight:SetActive(state)
end

function M:Switch()
    self.grid.gameObject:SetActive(not self.grid.gameObject.activeSelf)
    self.grid:Reposition()
    self:SetHighlight(not self.highlight.activeSelf)
end

function M:OnEquipCell(data)
    local list = self.cellList
    for i=1,#list do
        list[i]:SetHighlight(list[i].data.id == data.id)
    end
end

function M:OnClick()
    if self.data then
        M.eClick(self.data)
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
    self.grid.gameObject:SetActive(false)
    self:SetHighlight(false)
end


function M:SetActive(state)
    self.go:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end


function M:Dispose() 
    self:SetLsnr("Remove")
    self.data = nil
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
    AssetTool.UnloadTex(self.texList)
end

return M
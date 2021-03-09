AresDecompView = Super:New{Name = "AresDecompView"}

require("UI/Robbery/Ares/ADVCell")

local M = AresDecompView

function M:Ctor()
    self.cellList = {}
    self.selectList = {}
end

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick

    self.go = go
    self.grid = G(UIGrid, trans, "CellList/ScrollView/Grid")
    self.prefab = FC(self.grid.transform, "Cell")
    self.prefab:SetActive(false)

    self.cost = G(UILabel, trans, "Cost")
    self.itemRoot = F(self.cost.transform, "ItemRoot")

    self.cell = ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(self.itemRoot)
    self.cell:UpData("21")

    SC(trans, "BtnClose", "", self.Close, self)
    SC(trans, "BtnDecompose", "", self.OnDecompose, self)


    self.value = 0

    self:InitCell()

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    ADVCell.eClick[key](ADVCell.eClick, self.OnClickCell, self)
end

function M:InitCell()
    local list = self.cellList
    for i=1,35 do
        local go = Instantiate(self.prefab)
        TransTool.AddChild(self.grid.transform, go.transform)
        local item = ObjPool.Get(ADVCell)
        item:Init(go)
        item:SetActive(true)
        table.insert(list, item)
    end
    self.grid:Reposition()
end

function M:Open()
    self:SetActive(true)  
    self:UpdateCell()
    self:SelectAll()
    self:UpdateCost()
end

function M:Close()
    self:SetActive(false)
end

function M:Refresh()  
    self:ClearSelect()
    self:UpdateCell()
    self:UpdateCost()
end

function M:UpdateCell()
    local data = AresMgr:GetCanDecompMateralData()
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
            local item = ObjPool.Get(ADVCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.grid:Reposition()
end

function M:UpdateCost()
    self.cost.text = string.format("[F4DDBDFF]%s[00FF00FF]+%s", RoleAssets.AresCoin, self.value) 
end

function M:SelectAll()
    self:ClearSelect()
    local list = self.cellList
    for i=1,#list do
        local cell = list[i]
        if cell:IsActive() and cell.data then
            cell:SetHighlight(true)
            self:AddSelect(list[i].data.id, list[i].data.num)
        end
    end
end

function M:OnClickCell(isSelect, id, num)
    if isSelect then
        self:AddSelect(id, num)
    else
        self:RemoveSelect(id, num)
    end
    self:UpdateCost()
end

function M:AddSelect(id, num)
    table.insert(self.selectList, id)
    self.value = self.value + AresMgr:GetDecompValue(id)*num
end

function M:RemoveSelect(id, num)
    TableTool.Remove(self.selectList,id)
    self.value = self.value - AresMgr:GetDecompValue(id)*num
end


function M:SetActive(state)
    self.go:SetActive(state)
end

function M:OnDecompose()
    if #self.selectList >0 then
        AresMgr:ReqWarGodDecompose(self.selectList)
    else
        UITip.Log("未选中任何分解材料")
    end
end

function M:ClearSelect()
    TableTool.ClearDic(self.selectList)
    self.value = 0
end

function M:Dispose()
    self:SetLsnr("Remove")
    TableTool.ClearUserData(self)
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
    TableTool.ClearDicToPool(self.cellList) 
    self:ClearSelect()
end

return M
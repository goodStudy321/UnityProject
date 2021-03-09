AvEquipInfo = Super:New{Name = "AvEquipInfo"}

require("UI/UISoulBearst/AvBearstCell")

local M = AvEquipInfo

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.sView = G(UIScrollView, trans, "ScrollView")
    self.tab = G(UITable, self.sView.transform, "Table")
    self.prefab = FC(self.tab.transform, "Cell")
    self.prefab:SetActive(false)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    AvBearstCell.eClick[key](AvBearstCell.eClick, self.OnBearstCell, self)
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
end

function M:UpdateEquipCellState(data)
    local list = self.cellList
    for i=1,#list do
        list[i]:OnEquipCell(data)
    end
end

function M:Refresh()
    self:UpdateCell()
end

function M:UpdateCell()
    local data = self.data
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
            local item = ObjPool.Get(AvBearstCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.tab:Reposition()
end

function M:Open()
    local mgr = SoulBearstMgr
    local data = mgr:GetActiveSBinfo()
    local bearstId = mgr:GetCurSBId()
    local equipId = mgr:GetEquipId()
    self:UpdateData(data)
    self:SetSelect(bearstId, equipId)
end

function M:SetSelect(bearstId, equipId)
    local list = self.cellList
    local len = #list
    for i=1, len do
        if list[i].data.id == bearstId then
            list[i]:OnClick()
            list[i]:SetSelect(equipId)
            return
        end
    end
   
    if len > 0 then
        list[1]:OnClick()
        list[1]:SetSelect()
    end
end


function M:Reset()
    local list = self.cellList
    for i=1,#list do
        list[i]:Reset()
    end
end


function M:OnBearstCell(id)
    local list = self.cellList
    for i=1,#list do
        if list[i].data.id ~= id then
            list[i]:HideEquip()
        else
            list[i]:Switch()
        end
    end
  --  SoulBearstMgr:SetCurSBId(id)
    self.tab:Reposition()
end 

function M:Dispose()
    self:SetLsnr("Remove")
    self.data = nil
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M
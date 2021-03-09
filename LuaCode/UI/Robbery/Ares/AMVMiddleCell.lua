AMVMiddleCell = Super:New{Name = "AMVMiddleCell"}

require("UI/Robbery/Ares/AresCell")

local M = AMVMiddleCell

M.eClick = Event()

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local F = TransTool.Find

    self.lock = FC(trans, "Lock")
    self.fx = FC(trans, "FX_biankuang")

    local root = F(trans, "ItemRoot")
    self.cell = ObjPool.Get(AresCell)
    self.cell:InitLoadPool(root)
    self.cell.eClickCell:Add(self.Click, self)
end

function M:UpdateData(data)
    self.data = data
    self.cell:UpdateData(data)
    self:UpdateLock()
    self:UpdateFX()
end

function M:UpdateFX()
    local state = AresMgr:GetMaterialCount(self.data.materialId) >= self.data.needCount
    self.fx:SetActive(not self.data.state and state)
end

function M:UpdateLock()
    self.lock:SetActive(not self.data.state)
end

function M:Click(data)
    M.eClick(data)
end

function M:Dispose()
    self.data = nil
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    TableTool.ClearUserData(self)
end

return M
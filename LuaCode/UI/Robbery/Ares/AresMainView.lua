AresMainView = Super:New{Name = "AresMainView"}

require("UI/Robbery/Ares/AMVSuitList")
require("UI/Robbery/Ares/AMVMiddleInfo")
require("UI/Robbery/Ares/AMVAttrInfo")

local M = AresMainView

M.eClickEquip = Event()
M.eOpenView = Event()


function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    
    self.go = go
    self.suitList = ObjPool.Get(AMVSuitList)
    self.middleInfo = ObjPool.Get(AMVMiddleInfo)
    self.attrInfo = ObjPool.Get(AMVAttrInfo)

    self.suitList:Init(FC(trans, "SuitList"))
    self.middleInfo:Init(FC(trans, "MiddelInfo"))
    self.attrInfo:Init(FC(trans, "AttrInfo"))

    self.aresIndex = 1;
    self:SetLsnr()
end

function M:SetLsnr()
    self.suitList.eClickCell:Add(self.OnClickCell, self)
end

function M:Open()
    self:SetActive(true)
    local data = AresMgr:GetAresData()
    self:UpdateData(data)
end

function M:Close()
    self:SetActive(false)
    self:Clear()
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end

function M:OnClickCell(data)
    self.middleInfo:UpdateData(data)
    self.attrInfo:UpdateData(data)
end

function M:UpdateData(data)
    self.suitList:UpdateData(data)
    self.suitList:SetDefSelect(self.aresIndex)
end

function M:Refresh()
    self.suitList:Refresh()
    self.middleInfo:Refresh()
    self.attrInfo:Refresh()
end

function M:Clear()
    self.suitList:Clear()
end

function M:Dispose()
    TableTool.ClearUserData(self)
    ObjPool.Add(self.suitList)
    ObjPool.Add(self.middleInfo)
    ObjPool.Add(self.attrInfo)
    self.suitList = nil
    self.middleInfo = nil
    self.attrInfo = nil
    self.aresIndex = 1;
end

return M
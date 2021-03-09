AresAdvView = Super:New{Name = "AresAdvView"}

require("UI/Robbery/Ares/AAVEquipInfo")
require("UI/Robbery/Ares/AAVAdvInfo")
require("UI/Robbery/Ares/AAVAttrInfo")

local M = AresAdvView

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild

    self.go = go

    self.equipInfo = ObjPool.Get(AAVEquipInfo)
    self.advInfo = ObjPool.Get(AAVAdvInfo)
    self.attrInfo = ObjPool.Get(AAVAttrInfo)

    self.equipInfo:Init(FC(trans, "EquipInfo"))
    self.advInfo:Init(FC(trans, "AdvInfo"))
    self.attrInfo:Init(FC(trans, "AttrInfo"))

    self.tog = FC(trans, "AresTog")

    UITool.SetLsnrClick(trans, "BtnHelp", self.Name, self.OnHelp, self)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    AAVEquipCell.eClick[key](AAVEquipCell.eClick, self.OnAAVEquipCell, self)
    AAVCell.eClick[key](AAVCell.eClick, self.OnAAVCell, self)
end

function M:UpdateAdvFx(isBaoji)
    self.advInfo:UpdateAdvFx(isBaoji)
end

function M:UpdateSuitAdvFx()
    self.advInfo:UpdateSuitAdvFx()
end

function M:OnAAVCell(data)
    self.equipInfo:UpdateCellState(data)
    self.attrInfo:UpdateData(data)
end

function M:OnAAVEquipCell(data)
    self.advInfo:UpdateData(data)
end

function M:Refresh()
    self.equipInfo:Refresh()
    self.attrInfo:Refresh()
    self.advInfo:Refresh()
end

function M:Open(aresId, equipId)
    self:SetActive(true)
    local data = AresMgr:GetCanAdvAresData()
    self.equipInfo:UpdateData(data)
    self.equipInfo:SetSelect(aresId, equipId)
end

function M:Close()
    self.equipInfo:Reset()
    self.advInfo:Reset()
    self:SetActive(false)
end

function M:SetActive(state)
    self.go:SetActive(state)
    self.tog:SetActive(state)
end

function M:OnHelp()
    UIComTips:Show(InvestDesCfg["1701"].des, Vector3(-232,225,0), nil, nil, nil, nil, UIWidget.Pivot.TopLeft)
end

function M:Dispose()
    self:SetLsnr("Remove")
    ObjPool.Add(self.equipInfo)
    ObjPool.Add(self.advInfo)
    ObjPool.Add(self.attrInfo)
    self.equipInfo = nil
    self.advInfo = nil
    self.attrInfo = nil
end

return M
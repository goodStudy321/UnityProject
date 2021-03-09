UISBAdvView = Super:New{Name = "UISBAdvView"}

require("UI/UISoulBearst/AvEquipInfo")
require("UI/UISoulBearst/AvAdvInfo")
require("UI/UISoulBearst/AvItemInfo")

local M = UISBAdvView

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild


    self.go = go

    self.equipInfo = ObjPool.Get(AvEquipInfo)
    self.equipInfo:Init(FC(trans, "EquipInfo"))

    self.advInfo = ObjPool.Get(AvAdvInfo)
    self.advInfo:Init(FC(trans, "AdvInfo"))

    self.itemInfo = ObjPool.Get(AvItemInfo)
    self.itemInfo: Init(FC(trans, "ItemInfo"))

    UITool.SetLsnrClick(trans, "BtnHelp", self.Name, self.OnHelp, self, false)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    AvEquipCell.eClick[key](AvEquipCell.eClick, self.UpdateAdv, self)
    SoulBearstMgr.eUpdateExpAndGold[key](SoulBearstMgr.eUpdateExpAndGold, self.UpdateExpAndGold, self)
end

function M:UpdateExpAndGold(exp, cost)
    self.advInfo:UpdateExpAndGold(exp, cost)
end

function M:UpdateAdv(data)
    self.advInfo:UpdateData(data)
    self.itemInfo:CalExpAndGold()
    self.equipInfo:UpdateEquipCellState(data)
end

function M:Open()
    self:SetActive(true)
    self.equipInfo:Open()
    self.itemInfo:Open()
end

function M:Refresh()
    self.equipInfo:Refresh()
    self.advInfo:Refresh()
end

function M:RefreshBag()
    self.itemInfo:Refresh()
end

function M:ChangeDoubleAdv()
    self.itemInfo:CalExpAndGold()
end

function M:OnHelp()
    local str = InvestDesCfg["12"].des
    UIComTips:Show(str, Vector3(0,216,0))
end

function M:Close()
    self.equipInfo:Reset()
    self:SetActive(false)
    SoulBearstMgr:SetCurSBId(0)
    SoulBearstMgr:SetEquipId(0)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end

function M:Dispose()
    self:SetLsnr("Remove")
    ObjPool.Add(self.equipInfo)
    ObjPool.Add(self.advInfo)
    ObjPool.Add(self.itemInfo)
    self.equipInfo = nil
    self.advInfo = nil
    self.itemInfo = nil
    TableTool.ClearUserData(self)
end

return M
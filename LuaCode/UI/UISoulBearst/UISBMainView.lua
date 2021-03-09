UISBMainView = Super:New{Name = "UISBMainView"}

require("UI/UISoulBearst/MvBearstInfo")
require("UI/UISoulBearst/MvMiddleInfo")
require("UI/UISoulBearst/MvAttrInfo")
require("UI/UISoulBearst/MvBagInfo")
require("UI/UISoulBearst/MvBuyView")

local M = UISBMainView

local aMgr = Loong.Game.AssetMgr

M.eOpenAdvView = Event()

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local S = UITool.SetLsnrSelf

    self.go = go

    self.activeNum = G(UILabel, trans, "ActiveNum")
    self.btnAdd = FC(self.activeNum.transform, "BtnAdd")
    self.addRedPoint = FC(self.btnAdd.transform, "RedPoint")

    self.btnAdvRedPoint = FC(trans, "BtnAdv/RedPoint")

    self.bearstInfo = ObjPool.Get(MvBearstInfo)
    self.bearstInfo:Init(FC(trans, "BearstInfo"))

    self.middleInfo = ObjPool.Get(MvMiddleInfo)
    self.middleInfo:Init(FC(trans, "MiddleInfo"))

    self.attrInfo = ObjPool.Get(MvAttrInfo)
    self.attrInfo:Init(FC(trans, "AttrInfo"))

    self.bagInfo = ObjPool.Get(MvBagInfo)
    self.bagInfo:Init(FC(trans, "BagInfo"))

    self.buyView = ObjPool.Get(MvBuyView)
    self.buyView:Init(FC(trans, "BuyView"))

    SC(trans, "BtnBag", self.Name, self.OnBag, self)
    SC(trans, "BtnAdv", self.Name, self.OnAdv, self)
    S(self.btnAdd, self.OnAdd, self)


    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    MvBearstInfo.eClick[key](MvBearstInfo.eClick, self.OnBearstCell, self)
    MvSBCell.eClick[key](MvSBCell.eClick, self.OpenBag, self)
    UISBEquipTip.eChange[key](UISBEquipTip.eChange, self.OpenBag, self)
    MvBagInfo.eClick[key](MvBagInfo.eClick, self.CloseBag, self)
end

function M:PlayFx()
    aMgr.LoadPrefab("FX_UI_jiesuo", GbjHandler(self.SetFx,self))
end

function M:SetFx(go)
    go.transform:SetParent( self.go.transform)
    go.transform.localPosition = Vector3(0,0,0)
    go.transform.localScale = Vector3.one
end

function M:Refresh()
    self.bearstInfo:Refresh()
    self.middleInfo:Refresh()
    self.attrInfo:Refresh()
end

function M:Open()
    self.data = SoulBearstMgr:GetSBInfo()
    self.bearstInfo:UpdateData(self.data)
    self.bearstInfo:Switch()
    self:UpdateSBNum()
    self:UpdateUnLockSB()
    self:UpdateAdvRedPoint()
    self:SetActive(true)
end

function M:RefreshBearst()
    self.bearstInfo:Refresh()
    self.middleInfo:UpdateCellsRedPoint()
    self:UpdateAdvRedPoint()
end

function M:RefreshBag()
    self.bagInfo:Refresh()
end

function M:UpdateSBAct()
    self.attrInfo:UpdateBtnState()
    self.attrInfo:UpdateAttr()
    self.middleInfo:UpdateIconState()
    self.middleInfo:UpdateFX1()
end

function M:Close()
    self:SetActive(false)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end

function M:UpdateSBNum()
    local mNum = SoulBearstMgr:GetCanActNum()
    self.activeNum.text = string.format("[F39800FF]激活神兽：[00FF00FF]%d[F4DDBDFF]/%d", SoulBearstMgr:GetActSBNum(), mNum)
    local index = 0
    for i=1,#SBOpenCfg do
        if mNum >= SBOpenCfg[i].num then
            index = i
        end
    end
    local state = SBOpenCfg[index+1] and true or false
    self.btnAdd:SetActive(state)
end

function M:UpdateUnLockSB()
    self.addRedPoint:SetActive(SoulBearstMgr:GetUnLockState())
end

function M:UpdateAdvRedPoint()
    self.btnAdvRedPoint:SetActive(SoulBearstMgr.AdvRedPoint)
end

function M:OnBearstCell(data)
    self.middleInfo:UpdateData(data)
    self.attrInfo:UpdateData(data)
    self.bagInfo:Close()
end

function M:OnBag()
    self.attrInfo:Close()
    self.bagInfo:Open()
end

function M:OnAdv()
    self.eOpenAdvView()
end

function M:OpenBag(part, quality)
    if self.bagInfo:TryOpen(part, quality) then
        self.attrInfo:Close()
    else
        UITip.Log("背包里没有符合条件的装备")
    end
end

function M:CloseBag()
    self.attrInfo:SetActive(true)
end

function M:OnAdd()
    self.buyView:Open()
end


function M:Dispose()
    self.data = nil
    self:SetLsnr("Remove")
    TableTool.ClearUserData(self)
    ObjPool.Add(self.bearstInfo)
    ObjPool.Add(self.middleInfo)
    ObjPool.Add(self.attrInfo)
    ObjPool.Add(self.bagInfo)
    ObjPool.Add(self.buyView)
    self.bearstInfo = nil
    self.middleInfo = nil
    self.attrInfo = nil
    self.bagInfo = nil
    self.buyView = nil
end

return M
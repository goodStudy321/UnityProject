UIAresPanel = UILoadBase:New{Name = "UIAresPanel"}

require("UI/Robbery/Ares/AresMainView")
require("UI/Robbery/Ares/AresAdvView")
require("UI/Robbery/Ares/AresDecompView")
require("UI/Robbery/Ares/AresEquipTip")

local M = UIAresPanel

function M:Init()
    local trans = self.GbjRoot.transform
    local FC = TransTool.FindChild

    self.go = trans.gameObject

    self.mainView = ObjPool.Get(AresMainView)
    self.advView = ObjPool.Get(AresAdvView)
    self.decompView = ObjPool.Get(AresDecompView)
    self.equipTip = ObjPool.Get(AresEquipTip)

    self.mainView:Init(FC(trans, "MainView"))
    self.advView:Init(FC(trans, "AdvView"))
    self.decompView:Init(FC(trans, "DecomposeView"))
    self.equipTip:Init(FC(trans, "EquipTip"))

    self.togGrid = FC(trans.parent, "spBG/TogChild")

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    AresMgr.eClickEquip[key](AresMgr.eClickEquip, self.OnClickEquip, self)
    AresMgr.eOpenView[key](AresMgr.eOpenView, self.OpenView, self)
    AresMgr.eRefresh[key](AresMgr.eRefresh, self.Refresh, self)
    AresMgr.eUpdateAdvFx[key](AresMgr.eUpdateAdvFx, self.UpdateAdvFx, self)
    AresMgr.eUpdateSuitAdvFx[key](AresMgr.eUpdateSuitAdvFx, self.UpdateSuitAdvFx, self)
end

function M:UpdateAdvFx(isBaoji)
    self.advView:UpdateAdvFx(isBaoji)
end

function M:UpdateSuitAdvFx()
    self.advView:UpdateSuitAdvFx()
end

function M:Refresh()
    local curView = self.curView
    if curView == AresMgr.MainView then
        self.mainView:Refresh()
    elseif curView == AresMgr.AdvView then
        self.advView:Refresh()
    elseif curView == AresMgr.DecompView then
        self.mainView:Refresh()
        self.decompView:Refresh()
    end
end

function M:OpenView(curView, aresId, equipId)
    self.curView = curView
    if curView == AresMgr.MainView then
        self.togGrid:SetActive(true)
        self.mainView:Open()
        self.advView:Close()
    elseif curView == AresMgr.AdvView then
        self.togGrid:SetActive(false)
        self.mainView:Close()
        self.advView:Open(aresId, equipId)
    elseif curView == AresMgr.DecompView then
        self.decompView:Open()
    end
end

function M:OnClickEquip(data)
    self.equipTip:UpdateData(data)
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:CloseC()  
    self.mainView:Close()
    self.advView:Close()
    self.decompView:Close()
    -- self:SetActive(false)
end

function M:IsActive()
    if not self.go then return end
    return self.go.activeSelf
end

function M:CanClose()
    return not self:IsActive() or self.mainView:IsActive()
end

function M:Open(t1,t2,t3)
    -- self:SetActive(true)
    self.mainView.aresIndex = t1;
    self:OpenView(AresMgr.MainView)
end

function M:Dispose()
    self:SetLsnr("Remove")
    -- TableTool.ClearUserData(self)
    ObjPool.Add(self.mainView)
    ObjPool.Add(self.advView)
    ObjPool.Add(self.decompView) 
    self.mainView = nil
    self.advView = nil
    self.decompView = nil
    self.curView =nil
end

return M
--[[
商城
--]]
local AssetMgr=Loong.Game.AssetMgr
require("UI/UIStore/Panel")
require("UI/UIStore/BuyPanel")

StorePanel=Super:New{Name="StorePanel"}
local My = StorePanel

function My:Init(go)
    local trans = go.transform
    self.go=go
    local TF = TransTool.FindChild
    local CG = ComTool.Get

    self.panel=ObjPool.Get(Panel)
    self.panel:Init(TF(trans,"Panel"))
    self.panel:CreateC(tp)

	self.buyPanel=ObjPool.Get(BuyPanel)
    self.buyPanel:Init(TF(trans,"BuyPanel"))
end

function My:UpData(tp)
    -- body
end

function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.go:SetActive(false)
end

function My:Dispose()
    if self.panel then ObjPool.Add(self.panel) self.panel=nil end
    if self.buyPanel then ObjPool.Add(self.buyPanel) self.buyPanel=nil end
    TableTool.ClearUserData(self)
    My=nil
end

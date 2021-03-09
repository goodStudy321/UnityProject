UICopyGetWayItem = Super:New{Name = "UICopyGetWayItem"}

local  M = UICopyGetWayItem

function M:Init(go, quickBuy, getWay)
    local S = UITool.SetLsnrSelf
    local G = ComTool.Get
    local root = go.transform
    
    self.go = go
    self.quickBuy = quickBuy
    self.getWay = getWay
    self.name = G(UILabel ,root, "Name")
    S(go, self.OnGetWay, self, nil, false)
end

function M:UpdateData(data)
    if not data then return end
    self.data = data
    self.name.text = data.name
end

function M:OnGetWay()
    local data = self.data
    if not data then return end 
    self.getWay:SetActive(false)
    local id = data.id
    if id == 1 or id == 2 or id == 3 then        
        -- local itemid = data.itemId
        -- StoreMgr.OpenStoreId(itemid)
        if self.quickBuy then
            self.quickBuy:Open(self.data)
        end
    elseif id == 4 then      
        UICompound:SwitchTg(2,nil,data.itemId)
        JumpMgr:InitJump(UICopy.Name, CopyType.Exp)
    end
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:Dispose()
    TableTool.ClearUserData(self)
    self.data = nil
    self.quickBuy = nil
    self.getWay = nil
end

return M
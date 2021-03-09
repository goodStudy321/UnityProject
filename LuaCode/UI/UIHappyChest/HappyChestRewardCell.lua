HappyChestRewardCell = Super:New{Name = "HappyChestRewardCell"}

local My = HappyChestRewardCell

function My:Init(go)
    local trans = go.transform
    local TFC = TransTool.FindChild

    self.go = go
    self.cell = ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(trans)

end

function My:SetActive(bool)
    self.go:SetActive(bool)
end

function My:UpdateData(data)
    if not data then return end
    local data = data
    self.cell:UpData(data.id, data.cnt, data.bd)
end

function My:Dispose()
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
    TableTool.ClearUserData(self)
end

return My





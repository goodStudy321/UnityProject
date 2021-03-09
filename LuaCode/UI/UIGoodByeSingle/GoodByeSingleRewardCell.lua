
GoodByeSingleRewardCell = Super:New{Name = "GoodByeSingleRewardCell"}

local My = GoodByeSingleRewardCell

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
    self.cell:UpData(data.n1, data.n2)
end

function My:Dispose()
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
    TableTool.ClearUserData(self)
end

return My
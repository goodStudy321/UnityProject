DTProgressCell = Super:New{Name = "DTProgressCell"}

local M = DTProgressCell

function M:Init(go)
    local G = ComTool.Get
    local trans = go.transform

    self.mTrans = go.transform
    self.mTraget = G(UILabel, trans, "Target")
    self.mCell = ObjPool.Get(UIItemCell)
    self.mCell:InitLoadPool(self.mTrans, 0.8)
    self.mCell.eClickCell:Add(self.OnClick, self)
end

function M:OnClick()
    if not self.mData then return end
    if self.mData.state == 2 then
        DayTargetMgr:ReqDayTargetProgress(self.mData.id)
    end
end

function M:UpdateData(data)
    if not data then return end
    self.mData = data
    self.mTraget.text = data.id
    self.mCell:UpData(self.mData.reward.k, self.mData.reward.v)
    self:Refresh()
end

function M:Refresh()
    self.mCell:SetGray(self.mData.state == 1, true)
    self.mCell:SetEff(self.mData.state == 2)
end

function M:SetPos(pos)
    self.mTrans.localPosition = pos
end

function M:Dispose()
    self.mData = nil
    self.mCell:DestroyGo()
    ObjPool.Add(self.mCell)
    self.mCell = nil
    TableTool.ClearUserData(self)
end

return M
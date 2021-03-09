DemonProRewardCell = Super:New{Name = "DemonProRewardCell"}

local M = DemonProRewardCell

function M:Init(go)
    local trans = go.transform
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf
    local G = ComTool.Get


    self.mItemRoot = F(trans, "ItemRoot")
    self.mBtnGet = FC(trans, "BtnGet")
    self.mBtnName = G(UILabel, self.mBtnGet.transform, "Name")

    S(self.mBtnGet, self.OnGet, self)
end

function M:UpdateData(data)
    if not data then return end
    self.mData = data
    self:InitCell()
    self:UpdateBtnStatus()
end

function M:OnGet()
    DemonMgr:ReqDemonBossHpReward(self.mData.Id)
end

function M:InitCell()
    if not self.mCell then
        self.mCell = ObjPool.Get(UIItemCell)
        self.mCell:InitLoadPool(self.mItemRoot)
        local data = self.mData.Rewards
        self.mCell:UpData(data.k, data.v)
    end
end

function M:UpdateBtnStatus()
    local status = self.mData.HadGet
    if status == 0 then
        UITool.SetGray(self.mBtnGet)
        self.mBtnName.text = "领取"
    elseif status == 1 then
        UITool.SetNormal(self.mBtnGet)
        self.mBtnName.text = "领取"
    elseif status == 2 then
        UITool.SetGray(self.mBtnGet)
        self.mBtnName.text = "已领取"
    end
end

function M:Dispose()
    self.mData = nil
    if self.mCell then
        self.mCell:DestroyGo()
        ObjPool.Add(self.mCell)
        self.mCell = nil
    end
    TableTool.ClearUserData(self)
end

return M
UIEscortRewardView = Super:New{Name = "UIEscortRewardView"}

require("UI/UIFamilyEscort/UIEscortItemCell")

local M = UIEscortRewardView

M.mCellList = {}

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf

    self.mGo = go
    self.mRemainCount = G(UILabel, trans, "RemainCount")
    self.mGrid = G(UIGrid, trans, "ScrollView/Grid")
    self.mPrefab = FC(self.mGrid.transform, "Cell")
    self.mTips = G(UILabel, trans, "Tips")
    self.mBtnBegin = FC(trans, "BtnBegin")
    self.mBtnName = G(UILabel, self.mBtnBegin.transform, "Name")
    self.mBtnFx = FC(self.mBtnBegin.transform, "fx_gm")


    self.mPrefab:SetActive(false)

    local btnHelp = FC(trans, "BtnHelp")
    
    S(self.mBtnBegin, self.OnBegin, self)
    S(btnHelp, self.OnHelp, self)
end

function M:UpdateData(data)
    if not data then return end
    self.mData = data 
    self:UpdateCells()
    self:Refresh()
end

function M:UpdateTips()
    local rob = FamilyEscortMgr:GetRobStatus()
    local isOpen= FamilyEscortMgr:GetOpenStatus()
    self.mTips.gameObject:SetActive(rob > 0 or not isOpen)
    local str = ""
    if rob == 1 then
        str = string.format("[99886BFF]（被拦截成功，奖励减少%s%%）[-]", GlobalTemp["150"].Value3)
    elseif rob == 2 then  
        str =  "[99886BFF]你已凭实力夺回损失的奖励[-]"
    elseif rob == 3 then
        str = "[99886BFF]盟友帮你抢回奖励，奖励无损失[-]"
    elseif not isOpen then
        str = "[F21919FF]（夜路危险，只可在9-23点进行护送）[-]"
    end
    self.mTips.text = str
end

function M:UpdateRemainCount()
    local remainCount = FamilyEscortMgr:GetEscortRemainTime()
    local totalCount = GlobalTemp["150"].Value2[1]
    self.mRemainCount.text = string.format("[99886BFF]剩余次数:%s/%s", remainCount, totalCount)
end

function M:UpdateBtnStatus()
    local state = FamilyEscortMgr:IsEscorting()
    if state then  
        self.mBtnName.text = "领取奖励"
        UITool.SetGray(self.mBtnBegin)
    else
        local hasReward = FamilyEscortMgr:GetHasRewardStatus()
        local state = hasReward == 1
        self.mBtnFx:SetActive(state)
        if state then
            self.mBtnName.text = "领取奖励"
        else
            self.mBtnName.text = "开始护送"
        end
        UITool.SetNormal(self.mBtnBegin)
    end
end

function M:UpdateCells()
    local data = self.mData.Rewards
    if data[1] then
        data[1].v = self.mData.expRatio * LvCfg[tostring(User.MapData.Level)].exp
    end
    local len = #data
    local list = self.mCellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
  
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.mPrefab)
            TransTool.AddChild(self.mGrid.transform, go.transform)
            local item = ObjPool.Get(UIEscortItemCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.mGrid:Reposition()
end

function M:Refresh()
    self:UpdateTips()
    self:UpdateRemainCount()
    self:UpdateBtnStatus()
end

function M:Open()
    self:SetActive(true)
end

function M:Close()
    self:SetActive(false)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:OnBegin()
    local hasReward = FamilyEscortMgr:GetHasRewardStatus()
    if hasReward == 1 then
        FamilyEscortMgr:ReqRoleEscortReward()
        return
    end

    local reaminTime = FamilyEscortMgr:GetEscortRemainTime()
    if reaminTime > 0 then
        FamilyEscortMgr:ReqRoleEscort(3)
    else
        UITip.Log("已没有护送次数，0点将重置")
    end   
end

function M:OnHelp()
    local des = InvestDesCfg["1035"].des
    UIComTips:Show(des, Vector3(0,0,0))
end

function M:Dispose()
    self.mData = nil
    TableTool.ClearDicToPool(M.mCellList)
    TableTool.ClearUserData(self)
end

return M
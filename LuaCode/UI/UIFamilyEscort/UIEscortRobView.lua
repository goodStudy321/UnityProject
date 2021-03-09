UIEscortRobView = Super:New{Name = "UIEscortRobView"}

require("UI/UIFamilyEscort/UIEscortRobCell")

local M = UIEscortRobView

local mMaxCount = 5

M.mCellList = {}

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get
    
    self.mGo = go
    self.mRemainCount = G(UILabel, trans, "RemainCount")
    self.mTips = FC(trans, "Tips")
    self.mScrollView = G(UIScrollView, trans, "Container/ScrollView")
    self.mWrapContent = G(UIWrapContent, self.mScrollView.transform, "WrapContent")
    self.mPrefab = FC(self.mWrapContent.transform, "Cell")
    self.mPrefab:SetActive(false)
    
    self.mScrollView.onDragFinished = function () self:OnDragFinished() end
    self.mWrapContent.onInitializeItem = UIWrapContent.OnInitializeItem(self.OnUpdateItem,self)

    UITool.SetLsnrClick(trans, "BtnHelp", self.Name, self.OnHelp, self)
end

function M:Open()
    self:SetActive(true)
    self:UpdateTips()
    self:ReqRobsData()
    self:UpdateRemianCount()   
end

function M:Close()
    self:SetActive(false)
end

function M:ReqRobsData()
    local data = FamilyEscortMgr:GetRobsData()
    local len = #data  
    if len < mMaxCount then
        local id, eTime = 0, 0
        if data[len] then
            id, eTime = data[len].Id, data[len].EndTime
        end
        --iTrace.Error("111111", id .. "," ..  eTime)
        FamilyEscortMgr:ReqRoleEscortList(id, eTime)
    else
        self:UpdateWrapContentIndex()
        self:UpdateData()
    end
end

function M:RefreshRobsData()
    local list = self.mCellList
    for i=1,#list do
        list[i]:UpdateFight()
    end
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:UpdateTips()
    local len = FamilyEscortMgr:GetRobsCount()
    self.mTips:SetActive(len == 0)
end

function M:UpdateData()
    self:UpdateTips()
    local data = FamilyEscortMgr:GetRobsData()
    local len = #data >= mMaxCount and mMaxCount or #data
    local list = self.mCellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

  
    for i=1, max do
        if i <= min then 
            list[i]:UpdateData(data[i])
            list[i]:SetActive(true)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.mPrefab)
            go.name = i
            TransTool.AddChild(self.mWrapContent.transform, go.transform)
            local item = ObjPool.Get(UIEscortRobCell)
            item:Init(go)       
            item:UpdateData(data[i])
            item:SetActive(true)
            table.insert(list, item)
        end
    end
    self.mWrapContent:SortAlphabetically()
    -- self.mScrollView:ResetPosition()
end

function M:UpdateWrapContentIndex()
    local len = FamilyEscortMgr:GetRobsCount()
    local minIndex = (1-len) > 0 and 0 or (1-len)
    ------iTrace.Error("minIndex", minIndex)
    self.mWrapContent.minIndex = minIndex
    self.mWrapContent.maxIndex = 0
end

function M:OnUpdateItem(go, index, realIndex)
    realIndex = 1-realIndex
    local data = FamilyEscortMgr:GetRobDataByIndex(realIndex)
    if not data then return end
    local list = self.mCellList
    local cell = list[index+1] 
    if not cell then return end
    cell:UpdateData(data)
end

function M:OnDragFinished()
    local data = FamilyEscortMgr:GetRobsData()
    local len = #data
    if len == 0 then return end
    --iTrace.Error("2222222", data[len].Id .. "," .. data[len].EndTime)
    FamilyEscortMgr:ReqRoleEscortList(data[len].Id, data[len].EndTime)
end

function M:UpdateRemianCount()
    local count = FamilyEscortMgr:GetRobRemainTime()
    local max = GlobalTemp["150"].Value2[2]
    self.mRemainCount.text = string.format("[F4DDBDFF]拦截剩余次数:%s/%s", count, max)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:OnHelp()
    local des = InvestDesCfg["1036"].des
    UIComTips:Show(des, Vector3(0,-255,0))
end

function M:Dispose()
    TableTool.ClearDicToPool(self.mCellList)
    TableTool.ClearUserData(self)
end

return M
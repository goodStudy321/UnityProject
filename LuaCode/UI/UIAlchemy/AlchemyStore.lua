AlchemyStore = Super:New{Name = "AlchemyStore"}

require("UI/UIAlchemy/AlchemyStoreCell")

local M = AlchemyStore

M.mCells = {}

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    
    self.mGo = go
    self.mGrid = G(UIGrid, trans, "Container/ScrollView/Grid")
    self.mPrefab = FC(self.mGrid.transform, "Cell")
    self.mPrefab:SetActive(false)

    self.mRemainTime = G(UILabel, trans, "RemainTime")
    self.mGold = G(UILabel, trans, "Gold")

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    FestivalActMgr.eUpdateActItemList[key](FestivalActMgr.eUpdateActItemList, self.UpdateItemList, self)
    FestivalActMgr.eUpdateItemRemainCount[key](FestivalActMgr.eUpdateItemRemainCount, self.UpdateItemRemainCount, self)
    RoleAssets.eUpAsset[key](RoleAssets.eUpAsset, self.UpdateGold, self)
    PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.GetAdd, self)
end

function M:GetAdd(action, dic)
    if action == 10414 then
        self.mDic = dic
        UIMgr.Open(UIGetRewardPanel.Name, self.OpenGetRewardCb, self)
    end
end

function M:OpenGetRewardCb(name)
    local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateData(self.mDic)
	end
end

function M:UpdateItemList(type)
    if type ~= FestivalActMgr.AlchemyStore then return end
    self:UpdateData()
end

function M:UpdateItemRemainCount(type)
    if type ~= FestivalActMgr.AlchemyStore then return end
    local list = self.mCells
    for i=1,#list do
        local cell = list[i]
        if cell:IsActive() then
            cell:UpdateRemainCount()
        end
    end
end


function M:UpdateTimer()
    local eDate = self.mData.eDate
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.mTimer then
            self.mTimer = ObjPool.Get(DateTimer)
            self.mTimer.invlCb:Add(self.InvlCb, self)
            self.mTimer.complete:Add(self.CompleteCb, self)
            self.mTimer.apdOp = 3
        end
        self.mTimer.seconds = seconds
        self.mTimer:Stop()
        self.mTimer:Start()
        self:InvlCb()
    end
end

function M:InvlCb()
    self.mRemainTime.text = string.format("剩余时间：%s", self.mTimer.remain) 
end

function M:CompleteCb()
    self.mRemainTime.text = ""
end


function M:UpdateCells()
    local data =self.mData.itemList
    if not data then return end
    local len = #data
    local list = self.mCells
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
            local item = ObjPool.Get(AlchemyStoreCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.mGrid:Reposition()
end

function M:UpdateGold()
    self.mGold.text = RoleAssets.Gold
end

function M:UpdateData()
    local data = FestivalActMgr:GetActInfo(FestivalActMgr.AlchemyStore)
    if not data then return end
    self.mData = data
    self:UpdateCells()
    self:UpdateTimer()
    self:UpdateGold()
end

function M:Open() 
    self:SetActive(true)
    self:UpdateData()
end

function M:Close()
    self:SetActive(false)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:Dispose()
    self.mData = nil
    self:SetLsnr("Remove")
    if self.mTimer then
        self.mTimer:AutoToPool()
        self.mTimer = nil
    end
    TableTool.ClearDicToPool(self.mCells)
    TableTool.ClearUserData(self)
end

return M
DemonAreaCell = Super:New{Name = "DemonAreaCell"}

require("UI/UIDemon/DemonRewardCell")

local M = DemonAreaCell

function M:Ctor()
    self.mCellList = {}
end

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf

    self.mGo = go
    self.mName = G(UILabel, trans, "Name")
    self.mLastOwner = G(UILabel, trans, "LastOwner")
    self.mBtnEnter= FC(trans, "BtnEnter")
    self.mLock = FC(self.mBtnEnter.transform, "Lock")
    self.mFx = FC(self.mBtnEnter.transform, "Fx")
    self.mBtnReward = FC(trans, "BtnReward")   
    self.mGrid = G(UIGrid, trans, "Grid")
    self.mPrefab = FC(self.mGrid.transform, "Cell")
    self.mPrefab:SetActive(false)

    S(self.mBtnEnter, self.OnEnter, self)
    S(self.mBtnReward, self.OnReward, self)
    S(self.mLastOwner, self.OnLastOwner, self, "", false)
end

function M:OnEnter()
    if not self.data then return end
    if self.data.CanEnter then
        if (self.data.WorldLevel - User.MapData.Level) > GlobalTemp["126"].Value3 then
            UITip.Log(string.format("等级不能低于boss%s级", GlobalTemp["126"].Value3))
        else
            MsgBox.ShowYesNo(string.format("%s为极度凶险之处，是否确定要进入?", self.data.Name), self.YesCb, self)     
        end
    else
        -- UITip.Log("当前副本已关闭，等待下一次刷新")
        UITip.Log("当前副本未开启")
    end
end

function M:YesCb()
    SceneMgr:ReqPreEnter(30021, true, true ,self.data.Id)
end

function M:OnReward()
    if not self.data then return end
    UIMgr.Open(UIDemonReward.Name)
end

function M:OnLastOwner()
    if not self.data then return end
    if #self.data.OwnerRewards == 0 then return end
    UICellsShow:Show(self.data.OwnerRewards)
end

function M:UpdateData(data)
    if not data then return end
    self.data = data
    self:UpdateCells()
    self:UpdateName()
    self:UpdateLock()
    self:UpdateLastOwner()
end

function M:UpdateLastOwner()
    local name = StrTool.IsNullOrEmpty(self.data.LastOwnerName) and "无" or self.data.LastOwnerName
    self.mLastOwner.text = string.format("[F4DDBDFF]上任击败者：[-][00FF00FF][u]%s[-][-]", name)
end

function M:UpdateCells()
    local fixedCount = #self.data.InevitableRewards
    local data = TableTool.CombList(self.data.InevitableRewards, self.data.IncidentalRewards)
    local len = #data
    len = len <= 6 and len or 6
    local list = self.mCellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i], i <= fixedCount)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.mPrefab)      
            TransTool.AddChild(self.mGrid.transform, go.transform)
            local cell = ObjPool.Get(DemonRewardCell)   
            cell:Init(go) 
            cell:SetActive(true)       
            cell:UpdateData(data[i], i <= fixedCount)
            table.insert(list, cell)
        end
    end
    self.mGrid:Reposition()
end

function M:UpdateName()
    local color = self.data.WorldLevel > User.MapData.Level and "[F21919FF]" or "[F39800FF]"
    self.mName.text = string.format("[F39800FF]%s(%s%s[-])", self.data.Name, color, self.data.WorldLevel)
end


function M:UpdateLock()
    self.mLock:SetActive(not self.data.CanEnter)
    self.mFx:SetActive(self.data.CanEnter)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
    TableTool.ClearDicToPool(self.mCellList)
end

return M
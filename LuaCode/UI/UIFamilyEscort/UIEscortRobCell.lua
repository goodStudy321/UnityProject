UIEscortRobCell = Super:New{Name = "UIEscortRobCell"}

local M = UIEscortRobCell

function M:Ctor()
    self.mCellList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get

    self.mGo = go
    self.mName = G(UILabel, trans, "Name")
    self.mTarget = G(UILabel, trans, "Target")
    self.mFight = G(UILabel, trans, "Fight")
    self.mScrollView = G(UIScrollView, trans, "ScrollView")
    self.mGrid = G(UIGrid,  self.mScrollView.transform, "Grid")

    UITool.SetLsnrClick(trans, "BtnRob" , self.Name, self.OnRob, self)
end

function M:OnRob()
    if not self.mData then return end
    FamilyEscortMgr:ReqRoleEscortRob(self.mData.RoleId)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:UpdateData(data)
    if not data then return end
    self.mData = data
    self:UpdateName()
    self:UpdateTarget()
    self:UpdateFight()
    self:UpdateCells()
end

function M:UpdateName()
    if not StrTool.IsNullOrEmpty(self.mData.ServerName) then
        self.mName.text = string.format("%s：%s", self.mData.ServerName, self.mData.Name)
    else
        self.mName.text = self.mData.Name 
    end
end

function M:UpdateTarget()
    self.mTarget.text = string.format("[F39800FF]护送目标：%s%s", UIMisc.LabColor(self.mData.Quality), self.mData.ModelName) 
end

function M:UpdateFight()
    self.mFight.text = string.format("战斗力：%s", self.mData.Fight)
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
            list[i]:UpData(data[i].k, data[i].v)
            list[i]:SetActive(true)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.mGrid.transform)
            item:UpData(data[i].k, data[i].v)
            table.insert(list, item)
        end
    end
    self.mGrid:Reposition()
    self.mScrollView:ResetPosition()
end

function M:Dispose()
    self.mData = nil
    TableTool.ClearListToPool(self.mCellList)
    TableTool.ClearUserData(self)
end

return M
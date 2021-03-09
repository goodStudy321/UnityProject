UIActDLItem = Super:New{Name = "UIActDLItem"}

local M = UIActDLItem

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local trans = go.transform

    self.go = go
    self.grid = G(UIGrid, trans, "Grid")
    self.des = G(UILabel, trans, "Des")
    self.btn = FC(trans, "Btn")
    self.Yes = FC(trans, "yes")
    self.No = FC(trans, "no")
 

    S(self.btn, self.OnClick, self)
end

function M:OnClick()
    if self.data then
        FestivalActMgr:ReqBgActReward(self.data.type, self.data.id)
    end
end

function M:UpdateData(data)
    self.data = data
    self:UpdateReward()
    self:UpdateCondition()
end

function M:UpdateCondition()
    self:UpdateBtnState()
    self:UpdateDes()
end

function M:UpdateBtnState()
     local state = self.data.state
     if state == 1 then
        self:SetState(false, true, false)
     elseif state == 2 then
        self:SetState(true, false, false)
     elseif state == 3 then
        self:SetState(false, false, true)
     end
end

function M:SetState(s1, s2, s3)
    self.btn:SetActive(s1)
    self.No:SetActive(s2)
    self.Yes:SetActive(s3)
end

function M:UpdateDes()
    local data = self.data
    self.des.text = data.des
end

function M:UpdateReward()
    local data = self.data.rewardList
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpData(data[i].id, data[i].num, data[i].effNum==1)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            self:CreateReward(data[i])
        end
    end
    self.grid:Reposition()
end


function M:CreateReward(data)
    local cell = ObjPool.Get(UIItemCell)
    cell:InitLoadPool(self.grid.transform, 0.7)
    cell:UpData(data.id, data.num, data.effNum==1)
    table.insert(self.cellList, cell)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:Dispose()
    self.data = nil
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M
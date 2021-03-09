DayTargetCell = Super:New{Name = "DayTargetCell"}

local M = DayTargetCell

function M:Ctor()
    self.mCells = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local FC = TransTool.FindChild

    self.mGo = go
    self.mDes = G(UILabel, trans, "Des")
    self.mPro = G(UILabel, trans, "Pro")
    self.mScore = G(UILabel, trans, "Score")
    self.mGrid = G(UIGrid, trans, "Grid")
    self.mBtnGet = FC(trans, "BtnGet")
    self.mBtnGo = FC(trans, "BtnGo")
    self.mDone = FC(trans, "Done")
    self.mDiff = G(UISprite, trans, "Diff")

    S(self.mBtnGet, self.OnGet, self)
    S(self.mBtnGo, self.OnGo, self, nil, false)
end

function M:OnGet()
    if self.mData then
        DayTargetMgr:ReqDayTargetReward(self.mData.id)
    end
end

function M:OnGo()
    if not self.mData then return end
    local getWay = self.mData.getWay
    if not getWay then return end
    local activeType = self.mData.activeType
    if not activeType then return end
    if activeType == 1 then
        UITabMgr.Open(getWay)
    elseif activeType == 2 then
        UITabMgr.OpenMenu(getWay)
    elseif activeType == 3 then
        local id = getWay[1]
        local way = GetWayData[tostring(id)]
        if not way then return end
        local uiName = way.uiName
        local b = way.b
        local s = way.s
        QuickUseMgr.Jump(uiName, b, s)
    end
end

function M:UpdateData(data)
    if not data then return end
    self.mData = data
    self:UpdateDes( data.des, data.condition, data.tParam, data.pro)
    self.mBtnGo:SetActive(data.state==1 and data.getWay ~= nil)
    self.mBtnGet:SetActive(data.state==2)
    self.mDone:SetActive(data.state==3)
    self:UpdateReward(data.rewardList)
    self:UpdateDiff(data.diff)
end

function M:UpdateDes(des, condition, tParam, score)
    self.mDes.text = des
    local num = condition < tParam and condition or tParam
    if self.mData.state == 3 then
        num = tParam
    end   
    self.mPro.text = string.format("[F39800FF]完成度([00FF00FF]%s/%s[-])",  num, tParam)
    self.mScore.text = string.format("[F39800FF]目标积分[00FF00FF]%s",  score)
end

function M:UpdateDiff(diff)
    local name = "model_jd"
    if diff == 1 then
        name = "model_jd"
    elseif diff == 2 then
        name = "model_ry"
    elseif diff == 3 then
        name = "model_kn"
    end
    self.mDiff.spriteName = name
end

function M:UpdateReward(data)
    local len = #data
    local list = self.mCells
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpData(data[i].k, data[i].v)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local cell = ObjPool.Get(UIItemCell)
            cell:InitLoadPool(self.mGrid.transform)
            cell:UpData(data[i].k, data[i].v)
            table.insert(self.mCells, cell)
        end
    end
    self.mGrid:Reposition()
end

function M:SetActive(state)
    self.mGo:SetActive(state)
end

function M:Dispose()
    self.mData = nil
    TableTool.ClearListToPool(self.mCells)
    TableTool.ClearUserData(self)
end

return M
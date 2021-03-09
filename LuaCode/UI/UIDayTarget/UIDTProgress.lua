UIDTProgress = Super:New{Name = "UIDTProgress"}

require("UI/UIDayTarget/DTProgressCell")

local M = UIDTProgress

M.Y = 10
M.mCells = {}


function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.mTrans = go.transform
    self.mScore = G(UILabel, trans, "Score")
    self.mSlider = G(UISlider, trans, "Progress")
    self.mPrefab = FC(self.mSlider.transform, "ItemRoot")
    self.mPrefab:SetActive(false)

    local sp = G(UISprite, trans, "Progress")
    self.mWidth = sp.width

    self:InitCell()
    self:UpdateSlider()
end


function M:InitCell()
    local data = DayTargetMgr:GetProRewardInfo()
    local totalPro = DayTargetMgr:GetTotalPro()
    local list = self.mCells
    for i=1,#data do
        local go =  Instantiate(self.mPrefab)
        TransTool.AddChild(self.mSlider.transform, go.transform)
        go:SetActive(true)
        local x = (data[i].id/totalPro) * self.mWidth
        local pos =  Vector3(x, self.Y, 0)
        local cell = ObjPool.Get(DTProgressCell)
        cell:Init(go)
        cell:UpdateData(data[i])
        cell:SetPos(pos)
        table.insert(list, cell)
    end
end

function M:UpdateCells()
    local list = self.mCells
    for i=1,#list do
        list[i]:Refresh()
    end
end


function M:UpdateSlider()
    local value = DayTargetMgr:GetCurPro()
    local totalPro = DayTargetMgr:GetTotalPro()
    self.mSlider.value = value/totalPro
    self.mScore.text = string.format("目标积分:%s", value)
end

function M:Dispose()
    TableTool.ClearDicToPool(self.mCells)
    TableTool.ClearUserData(self)
end

return M
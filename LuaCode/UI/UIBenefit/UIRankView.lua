UIRankView = Super:New{Name = "UIRankView"}

require("UI/UIBenefit/RankCell")

local M = UIRankView

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local trans = go.transform

    self.go = go
    local title = F(trans, "Title")
    self.titleValue1 = G(UILabel, title, "Value1")
    self.titleValue2 = G(UILabel, title, "Value2")
    self.titleValue3 = G(UILabel, title, "Value3")
    self.titleValue4 = G(UILabel, title, "Value4")

    self.sView = G(UIScrollView, trans, "ScrollView")
    self.panel = G(UIPanel, trans, "ScrollView")
    self.grid = G(UIGrid, self.sView.transform, "Grid")
    self.cell = FC(self.grid.transform, "Cell")
    self.cell:SetActive(false)
    self.sViewPos = self.sView.transform.localPosition

    local myRank = F(trans, "MyRank")
    self.myValue1 = G(UILabel, myRank, "Value1")
    self.myValue2 = G(UILabel, myRank, "Value2")
    self.myValue3 = G(UILabel, myRank, "Value3")
    self.myValue4 = G(UILabel, myRank, "Value4")
end

function M:UpdateData(data)
    if not data then return end
    self:UpdateCellData(data.rankList)
    self:UpdateMyRank(data.myData)
    self:UpdateTitle(data.titleData)
end


function M:UpdateMyRank(data)
    self.myValue1.text = data.Value1
    self.myValue2.text = data.Value2
    self.myValue3.text = data.Value3
    self.myValue4.text = data.Value4
end


function M:UpdateTitle(data)
    self.titleValue1.text = data.Value1
    self.titleValue2.text = data.Value2
    self.titleValue3.text = data.Value3
    self.titleValue4.text = data.Value4
end


function M:CreateCell(data)
    local go = Instantiate(self.cell)
    TransTool.AddChild(self.grid.transform, go.transform)
    local cell = ObjPool.Get(RankCell)
    cell:Init(go)
    cell:SetActive(true)
    cell:UpdateData(data)
    table.insert(self.cellList, cell)
end

function M:UpdateCellData(data)
    local len = #data
    local list = self.cellList
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
            self:CreateCell(data[i])
        end
    end
    self.grid:Reposition()
    self:ResetPosition()
end

function M:ResetPosition()
    self.sView:ResetPosition()
    self.sView.transform.localPosition = self.sViewPos
    self.panel.clipOffset = Vector2(0,0)
end


function M:SetActive(bool)
    self.go:SetActive(bool)
end


function M:ActiveSelf()
    return self.go.activeSelf
end

function M:Dispose()
    TableTool.ClearUserData(self)
    TableTool.ClearDicToPool(self.cellList)
end


return M
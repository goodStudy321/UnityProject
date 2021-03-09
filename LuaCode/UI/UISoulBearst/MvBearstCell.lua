MvBearstCell = Super:New{Name = "MvBearstCell"}

local M = MvBearstCell

function M:Ctor()
    self.eClick = Event()
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.go = go
    self.icon = G(UISprite, trans, "Icon")
    self.name = G(UILabel, trans, "Name")
    self.score = G(UILabel, trans, "Score")
    self.highlight = FC(trans, "Highlight")
    self.use = FC(trans, "Use")
    self.redPoint = FC(trans, "RedPoint")

    UITool.SetLsnrSelf(go, self.OnClick, self)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateName()
    self:UpdateScore()
    self:UpdateIcon()
    self:UpdateUse()
    self:UpdateRedPoint()
end

function M:UpdateName()
    self.name.text = self.data.name
end

function M:UpdateScore()
    self.score.text = string.format("评分：%s", self.data.totalScore)
end

function M:UpdateIcon()
    self.icon.spriteName = self.data.spriteName
end

function M:UpdateUse()
    self.use:SetActive(self.data.state==2)
end

function M:SetHighlight(state)
    if self:IsActive() then
        self.highlight:SetActive(state)
    end
end



function M:UpdateRedPoint()
    self.redPoint:SetActive(self.data.redPointState)
end

function M:OnClick()
    if self.data then 
        self.eClick(self.data)
    end
end


function M:SetActive(state)
    self.go:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end

function M:Dispose()
    self.data = nil
    self.eClick:Clear()
    TableTool.ClearUserData(self)
end

return M
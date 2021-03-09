ScoreBar = Super:New{Name = "ScoreBar"}

local M = ScoreBar

function M:Init(root)
    local G = ComTool.Get
    self.greenBar = G(UISlider, root, "GreenBar")
    self.greenScore = G(UILabel, root, "GreenBar/Score")
    self.greenName = G(UILabel, root , "GreenBar/Name")

    self.redBar = G(UISlider, root, "RedBar")
    self.redScore = G(UILabel, root, "RedBar/Score")
    self.redName = G(UILabel, root, "RedBar/Name")

    self.totalScore = GlobalTemp["36"].Value3
end

function M:InitInfo()
    local mgr = FamilyWarMgr
    local data = mgr:GetGreenCampData()
    self:UpdateGreenName(data.familyName)
    self:UpdateGreenInfo(data.score)

    data = mgr:GetRedCampData()
    self:UpdateRedName(data.familyName)
    self:UpdateRedInfo(data.score)
end

function M:UpdateScore()
    local mgr = FamilyWarMgr
    local data = mgr:GetGreenCampData()
    self:UpdateGreenInfo(data.score)

    data = mgr:GetRedCampData()
    self:UpdateRedInfo(data.score)
end

function M:UpdateRedInfo(value)
    self.redBar.value = value/self.totalScore
    self.redScore.text = string.format("%d/%d", value, self.totalScore)
end

function M:UpdateGreenInfo(value)
    self.greenBar.value = value/self.totalScore
    self.greenScore.text = string.format("%d/%d", value, self.totalScore)
end

function M:UpdateRedName(name)
    self.redName.text = name
end

function M:UpdateGreenName(name)
    self.greenName.text = name
end

function M:Dispose()
    TableTool.ClearUserData(self)
    self.totalScore = nil 
end

return M
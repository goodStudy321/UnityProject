--[[
 	authors 	:Liu
 	date    	:2018-5-2 10:27:40
 	descrition 	:答题排行榜项
--]]

UIAnswerRankIt = Super:New{Name = "UIAnswerRankIt"}

local My = UIAnswerRankIt

function My:Init(root)
    local CG = ComTool.Get
    self.go = root.gameObject
    self.isShow = false
    self.name = CG(UILabel, root, "Lab1")
    self.score = CG(UILabel, root, "Lab2")
    self.go:SetActive(false)
end

--设置排行榜项文本
function My:SetRankLab(rank, name, score)
    self.name.text = rank.."."..name
    self.score.text = score
end

--显示条目
function My:Show()
    if self.isShow then return end
    self.go:SetActive(true)
    self.isShow = true
end

--清理缓存
function My:Clear()
    self.isShow = false
    self.name = nil
    self.score = nil
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My
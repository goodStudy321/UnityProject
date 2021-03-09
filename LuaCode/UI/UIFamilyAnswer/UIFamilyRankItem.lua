--[[
 	authors 	:Liu
 	date    	:2018-5-30 10:35:00
 	descrition 	:道庭排行项
--]]

UIFamilyRankItem = Super:New{Name="UIFamilyRankItem"}

local My = UIFamilyRankItem

function My:Init(root)
    local CG = ComTool.Get
    self.go = root.gameObject
    self.rankLab = CG(UILabel, root, "lab")
    self.scoreLab = CG(UILabel, root, "scoreLab")
end

--设置排行榜项
function My:SetRankItem(rank, name, score)
    self.rankLab.text = rank..". "..name
    self.scoreLab.text = score.."分"
end

--清理缓存
function My:Clear()
    self.go = nil
    self.rankLab = nil
    self.scoreLab = nil
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My
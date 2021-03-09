--[[
 	authors 	:Liu
 	date    	:2019-6-13 12:08:00
 	descrition 	:道庭Boss副本排行项
--]]

UIFamilyBossRankIt = Super:New{Name="UIFamilyBossRankIt"}

local My = UIFamilyBossRankIt

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get

    self.rank = CG(UILabel, root, "rank", des)
    self.name = CG(UILabel,root, "name", des)
    self.damage = CG(UILabel, root, "damage", des)
end

--更新数据
function My:UpData(rank, name, hurtNum)
    self:Show()
    self.rank.text = rank
    self.name.text = name
    self.damage.text = CustomInfo:ConvertNum(tonumber(hurtNum))
end

--显示
function My:Show()
    self.rank.gameObject:SetActive(true)
    self.name.gameObject:SetActive(true)
    self.damage.gameObject:SetActive(true)
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My
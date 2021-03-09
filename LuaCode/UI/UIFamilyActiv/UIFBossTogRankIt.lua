--[[
 	authors 	:Liu
 	date    	:2019-6-13 10:00:00
 	descrition 	:道庭Boss项排行榜项
--]]

UIFBossTogRankIt = Super:New{Name="UIFBossTogRankIt"}

local My = UIFBossTogRankIt

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get

    self.bg1 = CG(UISprite, root, "bg1")
    self.bg2 = CG(UISprite, root, "bg2")
    self.bg3 = CG(UISprite, root, "bg3")
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.lab3 = CG(UILabel, root, "lab3")
    self.lab4 = CG(UILabel, root, "lab4")

    self.go = root.gameObject
end

--更新数据
function My:UpData(rank, name, joinCount, hurtNum, isShow)
    self.lab1.fontSize = 26
    if rank == 1 then
        self:SetShow("rank_icon_1", "rank_info_g")
    elseif rank == 2 then
        self:SetShow("rank_icon_2", "rank_info_z")
    elseif  rank == 3 then
        self:SetShow("rank_icon_3", "rank_info_b")
    else
        self.lab1.fontSize = 20
        self:SetShow(nil, nil)
    end
    self.bg2.gameObject:SetActive(isShow)
    self.lab1.text = rank
    self.lab2.text = name
    self.lab3.text = joinCount
    self.lab4.text = CustomInfo:ConvertNum(tonumber(hurtNum))
end

--设置显示
function My:SetShow(sprName1, sprName2)
    if sprName1 == nil or sprName2 == nil then
        self.bg1.gameObject:SetActive(false)
        self.bg3.gameObject:SetActive(false)
        return
    end
    self.bg1.spriteName = sprName1
    self.bg3.spriteName = sprName2
    
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My
--[[
 	authors 	:Liu
 	date    	:2018-4-10 15:09:28
 	descrition 	:青云之巅结算项
--]]

UITopFightEndIt = Super:New{Name="UITopFightEndIt"}

local My = UITopFightEndIt

function My:Init(root)
    local name = "青云之巅结算项";
    local CG = ComTool.Get;

    self.go = root.gameObject
    self.rank = CG(UILabel, root, "Rank", name)
    self.roleName = CG(UILabel, root, "Name", name)
    self.useTime = CG(UILabel, root, "Score", name)
    self.grid = CG(UIGrid, root, "Grid", name)
    self.rankSpr = CG(UISprite, root, "rankSpr", name) 
    self.rankBg = CG(UISprite, root, "rankBg", name)         
    self.cellList = {}   
end

--设置数据
function My:SetData(rank, roleName, useTime, floor, score, isSelf)
    self.go.name = rank + 100
    self.rank.text = rank
    self.roleName.text = roleName
    self:SetRankSpr(rank)
    local isPass = self:IsPass(floor, score)
    if not isPass then
        self.go:SetActive(false)
        return
    end
    local timeStr = CustomInfo:ConvertSec(useTime)
    -- local str = (isPass) and timeStr or "未通关"
    self.useTime.text = timeStr
    self:UpCell(rank)
end

--设置排行榜图片
function My:SetRankSpr(rank)
    local spr = self.rankSpr
    local bg = self.rankBg
    local rankCol = self.rank
    if rank <= 3 then
        spr.gameObject:SetActive(true)
        bg.gameObject:SetActive(true)
        if rank == 1 then
            rankCol.color = Color.New(243, 153, 0, 255) / 255.0
            spr.spriteName = "rank_icon_1"
            bg.spriteName = "rank_info_g"
        elseif rank == 2 then
            rankCol.color = Color.New(176, 61, 242, 255) / 255.0
            spr.spriteName = "rank_icon_2"
            bg.spriteName = "rank_info_z"
        elseif rank == 3 then
            rankCol.color = Color.New(0, 143, 252, 255) / 255.0
            spr.spriteName = "rank_icon_3"
            bg.spriteName = "rank_info_b"
        end
    end
end

--判断是否通关
function My:IsPass(floor, score)
    local info = TopFightInfo
    local key = tostring(floor)
    local cfg = TopFScoreCfg[key]
    if cfg == nil then return end
    if info.max == floor and score >= cfg.score then
        return true
    end
    return false
end

--更新Cell
function My:UpCell(rank)
    local parent = self.grid.transform
    local key = tostring(rank)
    local cfg = TopFRankCfg[key]
    if cfg == nil then return end
    local list = {}
    for i,v in ipairs(cfg.award) do
        table.insert(list, v)
    end
    for i,v in ipairs(list) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(parent, 0.7)
        cell:UpData(v.k, v.v)
        table.insert(self.cellList, cell)
    end
    self.grid:Reposition()
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end

-- 释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My
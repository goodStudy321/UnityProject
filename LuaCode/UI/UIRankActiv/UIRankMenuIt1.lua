--[[
 	authors 	:Liu
 	date    	:2018-7-25 09:45:00
 	descrition 	:开服活动界面项1
--]]

UIRankMenuIt1 = Super:New{Name = "UIRankMenuIt1"}

local My = UIRankMenuIt1

require("UI/UIRankActiv/UIRankAwardIt")

function My:Init(root)
    local des, Find = self.Name, TransTool.Find
    local CG,FindC = ComTool.Get, TransTool.FindChild
    local str = "Scroll View/Grid"

    self.itList1 = {}
    self.itList2 = {}

    self.grid = CG(UIGrid, root, str)
    self.noticeSpr = CG(UISprite, root, "noticeBg/spr")
    self.awardItem = FindC(root, str.."/awardItem", des)
    self.awardItem:SetActive(false)
    
    self:InitAItem()
end

--获取排行列表配置
function My:GetRankListCfg(cfg)
    local list1 = {}
    local list2 = {}
    local list3 = {}
    local list4 = {}
    for i=1, 4 do
        local award = cfg["rankAward"..i]
        local rank = cfg["rank"..i]
        table.insert(list1, award)
        table.insert(list2, rank)
    end
    for i=1, 5 do
        local baseAward = cfg["baseAward"..i]
        local baseCond = cfg["baseCond"..i]
        table.insert(list3, baseAward)
        table.insert(list4, baseCond)
    end
    return list1, list2, list3, list4
end

--更新奖励项
function My:UpData(id, state, rankState, rank)
    local cfg = RankActivCfg[id]
    if cfg == nil then return end
    local list1, list2, list3, list4 = self:GetRankListCfg(cfg)
    if list1 == nil or list2 == nil or list3 == nil or list4 == nil then return end

    local len = #self.itList1
    local norList = self.itList2
    local dic = RankActivInfo.stateDic
    for i,v in ipairs(self.itList1) do
        v:SetIndex(i)
        v:UpAwardItem(id, cfg, list1[i], list2[i], false)
        v:UpBtnState1(state, rankState, rank)
        v.go.name = 100 + i
    end
    
    for i=#norList, 1, -1 do
        local num = (#norList - i + 1) + len
        norList[i]:SetIndex(num)
        norList[i]:UpAwardItem(id, cfg, list3[i], list4[i], true)
        norList[i]:UpBtnState2(dic, i)
        norList[i].go.name = 100 + num
    end

    self.noticeSpr.spriteName = cfg.sprName
    self.grid:Reposition()
end

--初始化奖励项
function My:InitAItem()
    CustomMod:InitItems(4, self.awardItem, self.grid, self.itList1, UIRankAwardIt)
    CustomMod:InitItems(5, self.awardItem, self.grid, self.itList2, UIRankAwardIt)
end

--清理缓存
function My:Clear()

end
    
--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList1)
    ListTool.ClearToPool(self.itList2)
end

return My
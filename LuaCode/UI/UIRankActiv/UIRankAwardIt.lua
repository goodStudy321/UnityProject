--[[
 	authors 	:Liu
 	date    	:2018-7-25 09:45:00
 	descrition 	:排行奖励项
--]]

UIRankAwardIt = Super:New{Name = "UIRankAwardIt"}

local My = UIRankAwardIt

require("UI/UIRankActiv/UIRankAwardItem")

function My:Init(root)
	local des, SetB = self.Name, UITool.SetBtnClick
    local CG, FindC = ComTool.Get, TransTool.FindChild
    local Find, SetS = TransTool.Find, UITool.SetLsnrSelf

    self.itList = {}
    self.go = root.gameObject

    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab1/lab2")
    self.getLab = CG(UILabel, root, "getBtn/lab")
    self.yes = FindC(root, "yes", des)
    self.no = FindC(root, "no", des)
    self.getBtn = Find(root, "getBtn", des)
    self.getBtn.gameObject:SetActive(false)

    SetS(self.getBtn, self.OnGetAward, self, des)

    self:InitAItem(root, des)
end

--设置索引
function My:SetIndex(index)
    self.ItemIndex = index
end

--更新奖励物品
function My:UpAwardItem(id, cfg, awards, ranks, isMark)
    self.id = id
    self.temp1 = 0
    self.temp2 = 0
    local str1 = ""
    local str2 = ""
    for i,v in ipairs(ranks) do
        if i == 1 then self.temp1 = v else self.temp2 = v end
    end
    local val = (self.temp2==0 or self.temp1 == 1) and self.temp1 or self.temp1.."-"..self.temp2
    if cfg.id == 1 then
      --  print(val)
        str1 = (isMark) and string.format("等级达到%s级", val) or string.format("全服等级第%s名", val)
        str2 = (isMark) and string.format("可领取：") or string.format("且达到%s级可领取：", cfg.rankCriteria)
    elseif cfg.id == 2 then
        local valStr1 = (isMark) and RankActivMgr:GetMountsInfo(val) or val
        local valStr2 = RankActivMgr:GetMountsInfo(cfg.rankCriteria)
        str1 = (isMark) and string.format("坐骑达到%s", valStr1) or string.format("全服坐骑第%s名", val)
        str2 = (isMark) and string.format("可领取：") or string.format("且达到%s可领取：", valStr2)
    elseif cfg.id == 3 then
        str1 = (isMark) and string.format("套装战力达到%s", val) or string.format("全服套装第%s名", val)
        str2 = (isMark) and string.format("可领取：") or string.format("且达到%s战力可领取：", cfg.rankCriteria)
    elseif cfg.id == 4 then
        local valStr1 = (isMark) and RankActivMgr:GetPetInfo(val) or val
        local valStr2 = RankActivMgr:GetPetInfo(cfg.rankCriteria)
        str1 = (isMark) and string.format("伙伴达到%s", valStr1) or string.format("全服伙伴第%s名", val)
        str2 = (isMark) and string.format("可领取：") or string.format("且达到%s可领取：", valStr2)
    elseif cfg.id == 5 then
        str1 = (isMark) and string.format("印记战力达到%s", val) or string.format("全服印记第%s名", val)
        str2 = (isMark) and string.format("可领取：") or string.format("且达到%s战力可领取：", cfg.rankCriteria)
    elseif cfg.id == 6 then
        str1 = (isMark) and string.format("战力达到%s", val) or string.format("全服战力第%s名", val)
        str2 = (isMark) and string.format("可领取：") or string.format("且达到%s战力可领取：", cfg.rankCriteria)
    elseif cfg.id == 7 then    
        local numStr1 = (isMark) and RankActivMgr:GetFiveInfo(val) or val
        local valStr1= RankActivMgr:GetFiveInfo(cfg.rankCriteria) 
        str1 = (isMark) and string.format("通关%s",numStr1) or string.format("全服幻境第%s名", val)
        str2 = (isMark) and string.format("可领取：") or string.format("且通关%s可领取：",valStr1)
    end
    self.lab1.text = str1
    self.lab2.text = str2

    local list = self.itList
    self:HideAItem()
    for i,v in ipairs(awards) do
        list[i].go:SetActive(true)
        list[i]:UpCell(v)
    end
    for i,v in ipairs(cfg.markList) do
        if self.ItemIndex == v.k then
            if list[v.v] then list[v.v]:UpSpr() end
        end
    end
end

--更新排名按钮状态
function My:UpBtnState1(state, rankState, rank)
    self.index = 1
    local isRank = rank >= self.temp1 and rank <= self.temp2
    if state == 1 then
        self:UpSprState(false, false, true)
    else
        if isRank == true then
            self:UpSprState(rankState==2, rankState==3, rankState==1)
        else
            self:UpSprState(false, false, true)
        end
    end
end

--更新基础按钮状态
function My:UpBtnState2(dic, index)
    self.index = index + 1
    local key = tostring(index)
    local val = dic[key] or 1
    self:UpSprState(val==2, val==3, val==1)
end

--更新状态
function My:UpSprState(state1, state2, state3)
    local parent = self.getLab.transform.parent
    parent.gameObject:SetActive(state1)
    self.yes:SetActive(state2)
    self.no:SetActive(state3)
end

--初始化奖励物品
function My:InitAItem(root, des)
    local Find = TransTool.Find
    for i=1, 5 do
        local tran = Find(root, "item"..i, des)
        local it = ObjPool.Get(UIRankAwardItem)
        it:Init(tran)
        table.insert(self.itList, it)
    end
end

--点击获取奖励按钮
function My:OnGetAward(go)
    if self.id == nil or self.index == nil then return end
    RankActivMgr:ReqRankAward(self.id, self.index)
end

--隐藏奖励道具
function My:HideAItem()
    for i,v in ipairs(self.itList) do
        v.go:SetActive(false)
    end
end

--清理缓存
function My:Clear()
    self.temp1 = 0
    self.temp2 = 0
    self.id = nil
    self.index = nil
end
    
--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
end

return My
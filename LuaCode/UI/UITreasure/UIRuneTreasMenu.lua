--[[
 	authors 	:Liu
 	date    	:2018-7-7 15:00:00
 	descrition 	:符文寻宝界面
--]]

UIRuneTreasMenu = Super:New{Name="UIRuneTreasMenu"}

local My = UIRuneTreasMenu

require("UI/UITreasure/UIRuneTreasIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local str1 = "left/Scroll View/Grid"
    local str2 = "right/Scroll View/Grid"

    self.itList1 = {}
    self.itList2 = {}
    self.costList = {}
    self.countList = {}
    self.labList = {}
    self.sprList = {}
    self.texLabList = {}
    self.yPos = 0

    -- local gridTran = Find(root, str, des)
    -- local runeIt = FindC(root, str.."/item", des)
    -- local sRune = Find(root, "showRune", des)
    self.lab1 = FindC(root, "buyBtn1/lab1", des)
    self.redDot1 = FindC(root, "buyBtn1/redDot", des)
    self.redDot2 = FindC(root, "buyBtn2/redDot", des)
    self.eff = FindC(root, "buyBtn1/eff", des)
    self.freeLab = FindC(root, "buyBtn1/lab4", des)
    self.line1 = FindC(root, "buyBtn1/lab5", des)
    self.line2 = FindC(root, "buyBtn1/lab6", des)
    self.item1 = FindC(root, str1.."/item")
    self.item2 = FindC(root, str2.."/item")
    self.grid1 = CG(UIGrid, root, str1)
    self.grid2 = CG(UIGrid, root, str2)
    
    self:InitBuyBtn(root, Find, des)
    -- self:InitShowRune(sRune)
    self:UpShowPrice()

    self:InitRune(self.grid1, self.itList1, self.item1, 1)
    self:InitRune(self.grid2, self.itList2, self.item2, 2)
end

--初始化符文
function My:InitRune(grid, list, item, type)
    local cfgList = self:GetShowCfg(type)
    local Add = TransTool.AddChild
    for i,v in ipairs(cfgList) do
        if type == v.showType then
            local go = Instantiate(item)
            local tran = go.transform
            go.name = i + 1000
            Add(grid.transform, tran)
            local it = ObjPool.Get(UIRuneTreasIt)
            it:Init(tran, i, #cfgList, grid.cellHeight, type, v)
            table.insert(list, it)
        end
    end
    item:SetActive(false)
    grid:Reposition()
    self:UpTweenPos(list)
end

--更新位移动画
function My:UpTweenPos(list)
    for i,v in ipairs(list) do
        v:InitAnim()
    end
end

--获取展示配置
function My:GetShowCfg(type)
    local towerId = (CopyMgr.LimitTower==0) and 40001 or CopyMgr.LimitTower
    local cfg = CopyTowerTemp[tostring(towerId)]
    if cfg == nil then return end
    local treasureId = tostring(cfg.treasureId)
    local dic = TreasureInfo:GetShowDic()
    local list = dic[treasureId]
    if list == nil then return end
    local tempList = {}
    for i,v in ipairs(list) do
        if v.showType == type then
            table.insert(tempList, v)
        end
    end
    return tempList
end

--初始化购买按钮
function My:InitBuyBtn(root, Find, des)
    local str = "buyBtn"
    local SetS, CG = UITool.SetLsnrSelf, ComTool.Get
    local data = self:GetGlobalData()
    if data == nil then return end
    for i=1, 2 do
        local btn = Find(root, "btn"..i, des)
        local btnTran = Find(root, str..i, des)
        local costLab = CG(UILabel, btnTran, "lab3")
        local costSpr = CG(UISprite, btnTran, "spr1")
        local texLab = CG(UILabel, btnTran, "tex/lab")
        costLab.text = data[i].value
        table.insert(self.countList, data[i].id)
        table.insert(self.costList, data[i].value)
        table.insert(self.labList, costLab)
        table.insert(self.sprList, costSpr)
        table.insert(self.texLabList, texLab)
        SetS(btn, self.OnBuyClick, self, des)
	end
end

--点击购买按钮
function My:OnBuyClick(go)
    local data = self:GetGlobalData()
    if data == nil then return end
    if RuneMgr:BagIsFull() then
        UITip.Error("符文背包已满！")
        return
    end
    if go.name == "btn1" then
        if self:FreeTreas() then return end
        self:ReqTreas(1, data[1].id)
	elseif go.name == "btn2" then
		self:ReqTreas(2, data[2].id)
	end
end

--获取配置表数据
function My:GetGlobalData()
    local cfg = GlobalTemp["15"]
    if cfg == nil then return nil end
    return cfg.Value1
end

--请求符文寻宝
function My:ReqTreas(index, count)
    local info = RoleAssets
    local bindAndGold = info.GetCostAsset(3)
    local list =  self.costList
    local list1 = self.countList
    local tokens = UITreasure.rune.tokens
    local discount = list[index]/list[1]

    local bindGoldTotal = tokens * (list[index]/discount) + info.BindGold
    local goldTotal = tokens * (list[index]/discount) + info.Gold
    local bindAndGoldCost = tokens * (list[index]/discount) + bindAndGold

    
    self.goldTotalCost = bindAndGoldCost
    self.btnIndex = index
    self.costCount = count

    if bindGoldTotal < list[index] then
        MsgBox.ShowYesNo("您的绑定元宝不足，是否使用元宝抵扣", self.UseGoldCb, self)
        return
    end

    self:ReqTreasure()
    -- local total = tokens * (list[index]/discount) + info.Gold
    -- if total < list[index] then
    --     StoreMgr.JumpRechange()
    --     return
    -- end
    -- TreasureMgr:ReqRuneTreasure(count)
end


function My:UseGoldCb()
    local list = self.costList
    local goldTotal = self.goldTotalCost
    local index = self.btnIndex 

    if goldTotal < list[index] then
        StoreMgr.JumpRechange()
        return
    end
    self:ReqTreasure()
end

function My:ReqTreasure()
    local count = self.costCount
    TreasureMgr:ReqRuneTreasure(count)
end

--免费符文寻宝
function My:FreeTreas()
    local mgr = TreasureMgr
    if mgr.isEnd then
        mgr:ReqRuneTreasure(1)
        mgr.isEnd = false
        return true
    end
    return false
end

-- --初始化展示符文
-- function My:InitShowRune(sRune)
--     local cfg = RuneCfg["80100015"]
--     if cfg == nil then iTrace.Error("SJ", "符文ID为空：80100015") end
--     local it = ObjPool.Get(UIRuneTreasIt)
--     it:Init(sRune, cfg)
--     table.insert(self.itList, it)
-- end

--设置红点
function My:UpRedDot(index, isShow)
    if index == 2 then
        if isShow then
            self.redDot1:SetActive(true)
            local tokens = ItemTool.GetNum(TreasureMgr.idList[2])
            self:SetRedDot(true, tokens >= 10)
        else
            self:SetRedDot(false, false)
        end
    end
end

--设置红点状态
function My:SetRedDot(state1, state2)
    self.redDot1:SetActive(state1)
    self.redDot2:SetActive(state2)
end

--免费寻宝
function My:UpTreasStste(state)
    self.freeLab:SetActive(state)
    self.eff:SetActive(state)
    self.lab1:SetActive(not state)

    local cfg = GlobalTemp["15"]
    if cfg == nil then return end
    local id = cfg.Value2[1]
    local tokens = ItemTool.GetNum(id)
    self.line1:SetActive(tokens < 1 and state)
    self.line2:SetActive(tokens > 0 and state)
end

--更新显示价格
function My:UpShowPrice()
    local cfg = GlobalTemp["15"]
    local list1 = cfg.Value1
    local list2 = cfg.Value2
    local tokens = ItemTool.GetNum(list2[1])
    for i=1, 2 do
        self.labList[i].gameObject:SetActive(tokens<1)
        self.sprList[i].gameObject:SetActive(tokens<1)
        local go = self.texLabList[i].transform.parent.gameObject
        go:SetActive(tokens>0)
        if tokens>0 then
            local num = (i==2) and list1[2].value/list1[1].value or 1
            self.texLabList[i].text = num
        end
    end
end

--清理缓存
function My:Clear()
    self.goldTotalCost = nil
    self.btnIndex = nil
    self.costCount = nil
end
    
--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList1)
    ListTool.ClearToPool(self.itList2)
    -- AssetTool.UnloadByCfg(RuneCfg,"icon")
end

return My
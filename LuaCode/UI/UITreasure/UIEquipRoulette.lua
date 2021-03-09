--[[
 	authors 	:Liu
 	date    	:2018-6-27 12:00:00
 	descrition 	:装备寻宝轮盘
--]]

UIEquipRoulette = Super:New{Name="UIEquipRoulette"}

local My = UIEquipRoulette

function My:Init(root, index)
    local des, Find = self.Name, TransTool.Find
    self.countList = {}
    self.costList = {}

    self.rareDic = {}
    self.norList = {}
    self.rareList = {}

    self.index = index
    self:InitBuyBtn(root, Find, des)
    self:InitRareId()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
    UIGetRewardPanel.eDoublePop[func](UIGetRewardPanel.eDoublePop, self.OnDoublePop, self)
end

--打开获得界面
function My:OpenGetMenu()
    UIMgr.Open(UIGetRewardPanel.Name, self.RewardCb, self)
end

--道具添加
function My:OnAdd(action,dic)
    if UITreasure.curIndex == self.index then
        if action==10108 or action==10358 then
            self:SetRateList(dic)
        end
    end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        if #self.rareList > 0 then
            ui:UpRareData(self.rareList)
        else
            ui:UpdateData(self.norList)
        end
	end
end

--重复弹窗
function My:OnDoublePop()
    if UITreasure.curIndex == self.index then
        if #self.rareList > 0 and #self.norList > 0 then
            UIMgr.Open(UIGetRewardPanel.Name,self.DoubleCb,self)
        end
    end
end

--重复回调获得奖励界面
function My:DoubleCb(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(self.norList)
        self:ClearList()
	end
end

--设置稀有奖励列表
function My:SetRateList(dic)
    self:ClearList()
    for k,v in pairs(dic) do
        local key = tostring(v.k)
        local info = {}
        info.k = v.k
        info.v = v.v
        info.b = v.b
        if self.rareDic[key] then
            table.insert(self.rareList, info)
        else
            table.insert(self.norList, info)
        end
    end
end

--清空列表
function My:ClearList()
    ListTool.Clear(self.norList)
    ListTool.Clear(self.rareList)
end

--初始化购买按钮
function My:InitBuyBtn(root, Find, des)
    local str = "buyBtn"
    local data = self:GetGlobalData()
    if data == nil then return end
    local SetS, CG = UITool.SetLsnrSelf, ComTool.Get
    for i=1, 3 do
        local btnTran = Find(root, str..i, des)
        local costLab = CG(UILabel, btnTran, "costLab")
        costLab.text = data[i].value
        table.insert(self.countList, data[i].id)
        table.insert(self.costList, data[i].value)
        SetS(btnTran, self.OnBuyClick, self, des)
    end
end

--点击购买按钮
function My:OnBuyClick(go)
    local data = self:GetGlobalData()
    if data == nil then return end
    if go.name == "buyBtn1" then
        self:ReqTreas(1, data[1].id)
    elseif go.name == "buyBtn2" then
        self:ReqTreas(2, data[2].id)
    elseif go.name == "buyBtn3" then
        self:ReqTreas(3, data[3].id)
    end
end

--获取配置表数据
function My:GetGlobalData()
    local num = (self.index==TreasureInfo.equip) and 14 or 95
    local cfg = GlobalTemp[tostring(num)]
    if cfg == nil then return nil end
    return cfg.Value1
end

--请求寻宝
function My:ReqTreas(index, count)
    if UITreasure.curIndex ~= self.index then return end
    local info = RoleAssets
    local bindAndGold = info.GetCostAsset(3)
    local list = self.costList
    local list1 = self.countList
    local it = UITreasure.equip
    local keys = (it) and it.keys or 0
    local discount = list[index]/list[1]
    local bindGoldTotal = keys * (list[index]/discount) + info.BindGold
    local goldTotal = keys * (list[index]/discount) + info.Gold
    local bindAndGoldCost = keys * (list[index]/discount) + bindAndGold

    
    self.goldTotalCost = bindAndGoldCost
    self.btnIndex = index
    self.costCount = count

    if bindGoldTotal < list[index] then
        MsgBox.ShowYesNo("您的绑定元宝不足，是否使用元宝抵扣", self.UseGoldCb, self)
        return
    end

    -- if goldTotal < list[index] then
    --     StoreMgr.JumpRechange()
    --     return
    -- end

    self:ReqTreasure()
    
    -- local mgr = TreasureMgr
    -- if self.index == TreasureInfo.equip then
    --     mgr:ReqEquipTreasure(count)
    -- elseif self.index == TreasureInfo.top then
    --     mgr:ReqTopTreasure(count)
    -- end
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
    local mgr = TreasureMgr
    if self.index == TreasureInfo.equip then
        mgr:ReqEquipTreasure(count)
    elseif self.index == TreasureInfo.top then
        mgr:ReqTopTreasure(count)
    end
end

--初始化稀有奖励ID
function My:InitRareId()
    local dic = EquipIdMap
    local list = self:GetRareAwardList()
    for i,v in ipairs(list) do
        local key = tostring(v.iconId)
        local cfg = dic[key]
        if cfg then
            self:IsAdd(cfg.equip0)
            self:IsAdd(cfg.equip1)
            self:IsAdd(cfg.equip2)
            self:IsAdd(cfg.equip3)
        else
            self.rareDic[key] = true
        end
    end
end

--是否添加到列表中
function My:IsAdd(id)
    if id > 0 then
        local key = tostring(id)
        self.rareDic[key] = true
    end
end

--获取稀有奖励列表
function My:GetRareAwardList()
    local list = {}
    local tempCfg = TreasureInfo:GetCfg(self.index)
    for i,v in ipairs(tempCfg) do
        if v.isRare == 1 then
            table.insert(list, v)
        end
    end
    return list
end

--清理缓存
function My:Clear()
    self.costList = nil
    self.countList = nil
    self.goldTotalCost = nil
    self.btnIndex = nil
    self.costCount = nil
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    TableTool.ClearDic(self.rareDic)
end

return My
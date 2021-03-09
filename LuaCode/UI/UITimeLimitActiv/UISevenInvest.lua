--[[
 	authors 	:Liu
 	date    	:2019-3-22 10:10:00
 	descrition 	:七日投资
--]]

UISevenInvest = UIBase:New{Name = "UISevenInvest"}

local My = UISevenInvest

require("UI/UITimeLimitActiv/UISevenInvestIt")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.itList = {}

    self.lab = CG(UILabel, root, "bg1/lab2")
    self.item = FindC(root, "Grid/item1", des)
    self.btn = FindC(root, "bg1/btn", des)

    SetB(root, "bg1/btn", des, self.OnInvest, self)
    SetB(root, "close", des, self.Close, self)

    TimeLimitActivMgr:UpNorAction(2)

    self:InitLab()
    self:InitAItem()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = TimeLimitActivMgr
    mgr.eUpSevenAward[func](mgr.eUpSevenAward, self.UpSevenAward, self)
    mgr.eUpSevenInvest[func](mgr.eUpSevenInvest, self.UpSevenInvest, self)
end

--更新七日投资奖励
function My:UpSevenAward(id)
    self:UpBtns()
    local count = self:GetGoldCount(id)
    if count > 0 then
        local str = string.format("获得%s绑元", count)
        UITip.Log(str)
    else
        UITip.Log("领取成功")
    end
end

--更新投资按钮
function My:UpSevenInvest()
    self:UpBtns()
    self:UpBntState()
    UITip.Log("投资成功")
end

--初始化奖励项
function My:InitAItem()
    local Add = TransTool.AddChild
    local parent = self.item.transform.parent
    for i,v in ipairs(SevenInvestCfg) do
        if i > 7 then return end
        local go = Instantiate(self.item)
        local tran = go.transform
        Add(parent, tran)
        local it = ObjPool.Get(UISevenInvestIt)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
    self:UpBtns()
    self:UpBntState()
end

--更新按钮
function My:UpBtns()
    local info = TimeLimitActivInfo
    local dic = info:GetBtnData(info.sevenType)
    for i,v in ipairs(self.itList) do
        local key = tostring(v.cfg.id)
        local state = (dic) and dic[key] or nil
        v:UpBtnState(state)
    end
end

--点击投资
function My:OnInvest()
    local count = self:GetInvestGold()
    local gold = RoleAssets.Gold
    if gold < count then
        StoreMgr.JumpRechange()
        JumpMgr:InitJump(UISevenInvest.Name)
        return
    end
    TimeLimitActivMgr:ReqSevenInvest()
end

--获取投资元宝
function My:GetInvestGold()
    for i,v in ipairs(SevenInvestCfg) do
        return v.type
    end
end

--更新按钮状态投资按钮
function My:UpBntState()
    local info = TimeLimitActivInfo
    if info.isInvest == 1 then
        UITool.SetGray(self.btn)
    else
        UITool.SetNormal(self.btn)
    end
end

--获取元宝数量
function My:GetGoldCount(id)
    for i,v in ipairs(self.itList) do
        if id == v.cfg.id then
            return v.cfg.award[1].v
        end
    end
    return 0
end

--初始化文本
function My:InitLab()
    self.lab.text = self:GetInvestGold()
end

--清理缓存
function My:Clear()
	ListTool.ClearToPool(self.itList)
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
end

return My
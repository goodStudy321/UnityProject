--[[
 	authors 	:Liu
 	date    	:2018-5-24 20:32:59
 	descrition 	:在线奖励弹窗
--]]

UIAwardPopup = UIBase:New{Name = "UIAwardPopup"}

local My = UIAwardPopup

local Info = require("OnlineAward/OnlineAwardInfo")

function My:InitCustom()
    local CG, SetB = ComTool.Get, UITool.SetBtnClick
    local root = self.root
    local str = "Bg/getBtn"
    local item = TransTool.FindChild(root, "Bg/Scroll View/Grid/item", self.Name)
    self.timerLab = CG(UILabel, root, "Bg/timeLab")
    self.getLab = CG(UILabel, root, str.."/lab")
    self.eff = TransTool.FindChild(root, str.."/UI_BtnEff", self.Name)
    self.eff:SetActive(false)
    self.isGet = false
    self.cellList = {}
    SetB(root, "Bg/close", des, self.Close, self)
    SetB(root, str, des, self.OnClick, self)
    self:InitCell(item)
end

--点击领取按钮
function My:OnClick()
    if self.isGet then
        local awardList = self:GetShowItem()
        if awardList == nil then return end
        OnlineAwardMgr:ReqGetLvAward(Info.awardList[#Info.awardList])
    else
        self:Close()
    end
end

--初始化所有Cell
function My:InitCell(item)
    local Add = TransTool.AddChild
    local gridTran = item.transform.parent
    local awardList = self:GetShowItem()
    if awardList == nil then iTrace.Error("SJ", "奖励列表为空！") return end
    for i,v in ipairs(awardList) do
        local go = Instantiate(item)
        local tran = go.transform
        Add(gridTran, tran)
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(tran, 0.9)
        cell:UpData(v.k, v.v)
        table.insert(self.cellList, cell)
    end
    item:SetActive(false)
    gridTran:GetComponent(typeof(UIGrid)):Reposition()
end

--获取显示道具
function My:GetShowItem()
    local list = {}
    local index = 0
    local cfg = OnlineAwardCfg
    for k,v in pairs(cfg) do
        index = index + 1
        list[index] = v.id
    end
    table.sort(list)
    
    local len = #Info.awardList
    local now = #list - len
    if now == #list then return nil end
    local key = tostring(list[now+1])
    return cfg[key].award
end

--创建计时器
function My:CreateTimer(rTime)
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
    timer.seconds = rTime
    timer:Start()
    self:InvCountDown()
end

--间隔倒计时
function My:InvCountDown()
    if self.timerLab then
        self.timerLab.text = "[FF0000FF]"..self.timer.remain.."[F4DDBDFF]之后领取礼品"
    end
end

--结束倒计时
function My:EndCountDown()
    self.timerLab.text = "[F4DDBDFF]点击按钮领取礼品"
    self.getLab.text = "领取奖励"
    self.isGet = true
    self.eff:SetActive(true)
end

--清理缓存
function My:Clear()
    self.timerLab = nil
    self.getLab = nil
    self.isGet = nil
    self.eff = nil
    self.dic = nil
end

--重写释放资源
function My:DisposeCustom()
    self:Clear()
    if self.timer then
        self.timer:Stop()
		self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearListToPool(self.cellList)
end

return My
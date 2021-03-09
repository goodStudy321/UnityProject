--[[
 	authors 	:Liu
 	date    	:2019-04-17 16:20:00
 	descrition 	:任务奖励界面
--]]

UIJourneys = Super:New{Name = "UIJourneys"}

local My = UIJourneys

require("UI/UIBenefit/UIJourneysAwardIt")
require("UI/UIBenefit/UIJourneysCondIt")

function My:Init(go)
	local root = go.transform
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local str1 = "Container/Scroll View/Grid"
    local str2 = "countBg/Scroll View/Grid"

    self.go = go
    self.itList = {}
    self.condList = {}
    self.grid = CG(UIGrid, root, str1)
    self.explain = CG(UILabel, root, "spr/lab")
    self.countDown = CG(UILabel, root, "Countdown")
    self.lab = CG(UILabel, root, "countBg/titleBg/lab")
    self.item = FindC(root, str1.."/Cell", des)
    self.condGrid = CG(UIGrid, root, str2)
	self.condItem = FindC(root, str2.."/item", des)
	
    self:InitAwardIt()
    self:InitCondIt()
    self:UpActTime()
    self:UpLab()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = JourneysMgr
    mgr.eGetAward[func](mgr.eGetAward, self.RespGetAward, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10377 then		
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--响应获取奖励
function My:RespGetAward()
    self:UpAwardState()
    self.grid:Reposition()
end

--更新奖励状态
function My:UpAwardState()
    local dic = JourneysMgr.awardDic
    for i,v in ipairs(self.itList) do
        local key = tostring(v.cfg.id)
        if dic[key] then
            v:UpBtnState(dic[key])
        end
    end
end

--更新任务次数
function My:UpMissionCount()
    local dic = JourneysMgr.countDic
    for i,v in ipairs(self.condList) do
        
    end
end

--更新文本
function My:UpLab()
    local mana = JourneysMgr.mana
    self.lab.text = string.format("当前仙力值:%s", mana)
end

--初始化奖励项
function My:InitAwardIt()
    local Add = TransTool.AddChild
    local dic = JourneysMgr.awardDic
    for k,v in pairs(dic) do
        local cfg = self:GetAwardCfg(k)
        if cfg then
            local go = Instantiate(self.item)
            local tran = go.transform
            Add(self.grid.transform, tran)
            local it = ObjPool.Get(UIJourneysAwardIt)
            it:Init(tran, cfg)
            it:UpBtnState(v)
            table.insert(self.itList, it)
        end
    end
    self.item:SetActive(false)
    self.grid:Reposition()
end

--获取任务配置
function My:GetAwardCfg(key)
    local cfg = JourneysAwardCfg
    return cfg[key]
end

--初始化条件项
function My:InitCondIt()
    local Add = TransTool.AddChild
    local dic = JourneysMgr.countDic
    for k,v in pairs(dic) do
        local cfg = self:GetMissionCfg(k)
        if cfg then
            local go = Instantiate(self.condItem)
            local tran = go.transform
            Add(self.condGrid.transform, tran)
            local it = ObjPool.Get(UIJourneysCondIt)
            it:Init(tran, cfg)
            it:UpCondCount(v)
            table.insert(self.condList, it)
        end
    end
    self.condItem:SetActive(false)
    self.condGrid:Reposition()
end

--获取任务配置
function My:GetMissionCfg(id)
    for i,v in ipairs(JourneysMissionCfg) do
        if tonumber(id) == v.id then
            return v
        end
    end
    return nil
end

--更新活动时间
function My:UpActTime()
    local info = LivenessInfo:GetActInfoById(1029)
    if info == false then return end
    local eDate = info.eTime
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
        else
            self.timer:Stop()
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end

--间隔倒计时
function My:InvlCb()
    if self.countDown then
        self.countDown.text = string.format("活动结束倒计时：%s", self.timer.remain)
    end
end

--结束倒计时
function My:CompleteCb()
    self.countDown.text = "活动结束"
end

-- 打开面板
function My:Open()
    self.go:SetActive(true)
end

-- 关闭面板
function My:Close()
    self.go:SetActive(false)
end

--清理缓存
function My:Clear()
    self.dic = nil
end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    ListTool.ClearToPool(self.itList)
    ListTool.ClearToPool(self.condList)
end

return My
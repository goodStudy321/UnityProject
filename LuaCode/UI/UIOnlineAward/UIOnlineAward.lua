--[[
 	authors 	:Liu
 	date    	:2018-5-24 11:04:08
 	descrition 	:在线奖励(按钮)
--]]

UIOnlineAward = Super:New{Name = "UIOnlineAward"}

local My = UIOnlineAward
local Info = require("OnlineAward/OnlineAwardInfo")

function My:Init(root)
    local CG = ComTool.Get
    local GS, des = ComTool.GetSelf, self.Name

    self.go = root.gameObject
    self.isGet = false
    self.timerLab = CG(UILabel, root, "Root/TimerLab", des)
    self.timerLab.text = ""
    self.timerLab.gameObject:SetActive(true)

    -- UITool.SetBtnSelf(root, self.OnClick, self, self.Name)
    
    self:CreateTimer()
    self:SetLnsr("Add")
    self:InitTimer()
end

--设置监听
function My:SetLnsr(func)
    OnlineAwardMgr.eUpOnlineInfo[func](OnlineAwardMgr.eUpOnlineInfo, self.RespUpOnlineInfo, self)
    OnlineAwardMgr.eGetAward[func](OnlineAwardMgr.eGetAward, self.RespGetAward, self)
end

--响应更新在线奖励
function My:RespUpOnlineInfo()
    self:InitTimer()
end

--响应领取奖励
function My:RespGetAward(isAll)
    table.remove(Info.awardList, #Info.awardList)
    local ui = UIMgr.Get(UIAwardPopup.Name)
    if ui then ui:Close() end
    -- if #Info.awardList <= 0 then self:Hide() return end
    if isAll == 1 then self:Hide() return end
    self:UpTimer()
    UITip.Log("领取成功！")
    local actId = ActivityMgr.ZXJL
    SystemMgr:HideActivity(actId)
    self:InvCountDown()
end

--初始化计时器
function My:InitTimer()
    if Info.isAll == 1 then return end
    self:UpTimer()
end

-- --点击
-- function My:OnClick()
--     UIMgr.Open(UIAwardPopup.Name, self.OpenAwardPopup, self)
-- end

--在线奖励弹窗的回调方法
function My:OpenAwardPopup(name)
    local ui = UIMgr.Get(name)
	if(ui)then
		ui:CreateTimer(self.timer:GetRestTime())
    end
end

--更新按钮状态
function My:UpBtnState(rTime)
    local timer = self.timer
    if rTime >= 0 then
        self:UpGetState()
        self.isGet = true
    else
        timer:Start()
        self.timerLab.color = Color.red
        self.isGet = false
    end
end

--更新计时器
function My:UpTimer()
    self.timer:Stop()
    local rTime = Info.onlineTime - Info.awardList[#Info.awardList]*60
    self.timer.seconds = math.abs(rTime)
    self:UpBtnState(rTime)
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
    timer.fmtOp = 3
	timer.apdOp = 1
end

--间隔倒计时
function My:InvCountDown()
    local time = self.timer:GetRestTime()
    if self.timerLab then
        self.timerLab.text = self.timer.remain
    end
end

--结束倒计时
function My:EndCountDown()
    self:UpGetState()
end

--更新领取状态
function My:UpGetState()
    self.timer.seconds = 0
    local lab = self.timerLab
    lab.color = Color.green
    lab.text = "可领取"
    local actId = ActivityMgr.ZXJL
    SystemMgr:ShowActivity(actId)
end

--隐藏
function My:Hide()
    local amgr = ActivityMgr
	local k,v = amgr:Find(amgr.ZXJL)
    amgr:Remove(v)
    OnlineAwardMgr.State = false
end

--停止计时器
function My:StopTimer()
    if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清理缓存
function My:Clear()
    self.go = nil
    if self.timerLab then
        self.timerLab.gameObject:SetActive(false)
    end
    self.timerLab = nil
    self.isGet = false
end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    self:StopTimer()
end

return My
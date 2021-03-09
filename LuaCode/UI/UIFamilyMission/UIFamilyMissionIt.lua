--[[
 	authors 	:Liu
 	date    	:2019-6-15 16:00:00
 	descrition 	:帮派任务项
--]]

UIFamilyMissionIt = Super:New{Name = "UIFamilyMissionIt"}

local My = UIFamilyMissionIt

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.starList = {}
    self.cellList = {}
    self.cfg = nil
    self.state = nil
    self.id = nil
    self.lv = nil
    self.curIndex = nil
    self.count = nil
    self.leftTime = nil
    self.go = root.gameObject

    self.name = CG(UILabel, root, "name")
    self.starGrid = CG(UIGrid, root, "Grid")
    self.stateLab = CG(UILabel, root, "stateLab")
    self.btn1Lab = CG(UILabel, root, "btnStates/btn1/lab")
    self.speedLab = CG(UILabel, root, "btnStates/speedLab")
    self.grid = CG(UIGrid, root, "awardLab/Grid")
    self.progress = CG(UISlider, root, "progress")
    self.progressLab = CG(UILabel, root, "progress/lab")
    self.spr = CG(UISprite, root, "spr")
    self.btnSpr = CG(UISprite, root, "btnStates/btn1")
    self.complete = FindC(root, "complete", des)
    self.wait = FindC(root, "wait", des)
    self.star = FindC(root, "Grid/star", des)
    self.action = FindC(root, "btnStates/btn1/action", des)
    self.eff = FindC(root, "FX_saoguang", des)
    self.btn1 = FindC(root, "btnStates/btn1", des)
    self.btn2 = FindC(root, "btnStates/btn2", des)
    self.btn3 = FindC(root, "btnStates/btn3", des)
    self.star:SetActive(false)

    SetB(root, "btnStates/btn1", des, self.OnBtn1, self)
    SetB(root, "btnStates/btn2", des, self.OnBtn2, self)
    SetB(root, "btnStates/btn3", des, self.OnBtn3, self)

    self:CreateTimer()
end

--更新数据
function My:UpData(id, state, count, startTime, endTime)
    local cfg = FamilyMissionInfo:GetCfg(id)
    if cfg == nil then return end

    self.cfg = cfg
    self.id = id
    self.state = state
    self.lv = cfg.star
    self.count = count
    self.name.text = cfg.name
    self:UpStar(cfg.star)
    self:UpCell(cfg.award)
    self:UpState(state, count, startTime, endTime)
end

--更新任务状态
function My:UpState(state, count, startTime, endTime)
    if self.timer then self.timer:Stop() end
    local leftTime = 0
    local isStart = false

    if startTime and endTime then
        local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
        leftTime = endTime - sTime
        isStart = (sTime - startTime) >= 0
        self.leftTime = leftTime
    end

    if state == 0 then
        self:SetState(true, "接受任务", true, false)
    elseif state == 1 then
        self:SetState(not isStart, "放弃", not isStart, false)
    elseif state == 2 then
        self:SetState(true, "放弃", not isStart, true, count)
    elseif state == 3 then
        self:SetState(true, "领取奖励", true, false)
    elseif state == 4 then
        self:SetState(true, "放弃", true, false)
    end
    self.complete:SetActive(state==3)
    self.wait:SetActive((state==1 or state==2) and isStart)
    self.action:SetActive(state==3 or state==0)
    self:UpTimeLab(state, leftTime, isStart)
    self:SetName(state, isStart)
end

--更新任务状态
function My:SetState(state1, str, state2, state3, count)
    self:SetBtnState(state1, str)
    self:SetLabState(state2)
    self:SetSpeedLab(state3, count)
    self:UpBtnSpr(str=="放弃" or str=="接受任务")
end

--更新时间文本
function My:UpTimeLab(state, leftTime, isStart)
    local textStr = ""
    if state == 0 then
        local sec = self.cfg.time * 60
        local str = CustomInfo:ConvertSec(sec, 1)
        textStr = string.format("[00FF00FF]%s", str)

    elseif state == 1 or state == 2 then
        if isStart then self:UpTimer(leftTime) else textStr = "[F21919FF]等待中" end
    
    elseif state == 3 then
        -- textStr = "[00FF00FF]任务已完成"

    elseif state == 4 then
        --放弃状态
    end
    self.stateLab.text = textStr
end

--设置加速文本
function My:SetSpeedLab(state, count)
    self.speedLab.gameObject:SetActive(state)
    if state then
        local val = FamilyMissionInfo:GetMaxSpeed(VIPMgr.vipLv) or "??"
        self.speedLab.text = string.format("已加速（%s/%s）", count or "??", val)
    end
end

--设置文本状态
function My:SetLabState(state)
    self.stateLab.gameObject:SetActive(state and self.state~=3)
    self.progress.gameObject:SetActive(not state and self.state~=3)
end

--设置背景（随机）
function My:SetBg()
    local num = math.random(2, 6)
    self.spr.spriteName = "dt_b0"..num
end

--更新背景
function My:UpBg()
    local maxStar = FamilyMissionInfo.maxStar
    if self.cfg.star < maxStar and self.state == 0 then
        self:SetBg()
    end
end

--设置特效
function My:SetEff()
    local maxStar = FamilyMissionInfo.maxStar
    if self.cfg.star < maxStar and self.state == 0 then
        self.eff:SetActive(false)
        self.eff:SetActive(true)
    end
end

--更新按钮贴图
function My:UpBtnSpr(state)
    local str = (state==true) and "btn_task_2" or "btn_task_none"
    self.btnSpr.spriteName = str
end

--设置按钮状态
function My:SetBtnState(state, str)
    self.btn1:SetActive(state)
    self.btn2:SetActive(not state)
    self.btn3:SetActive(not state)
    self.btn1Lab.text = str
end

--更新道具
function My:UpCell(award)
    local Add = TransTool.AddChild
    local gridTran = self.grid.transform
    TableTool.ClearListToPool(self.cellList)

    for i,v in ipairs(award) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(gridTran, 0.8)
        cell:UpData(v.k, v.v)
        table.insert(self.cellList, cell)
    end
    self.grid:Reposition()
end

--更新星级
function My:UpStar(count)
    local Add = TransTool.AddChild
    local list = self.starList
    local gridTran = self.starGrid.transform
    local num = count - #list

    self:HideStar()
    if num > 0 then
        for i=1, num do
            local go = Instantiate(self.star)
            local tran = go.transform
            go:SetActive(true)
            Add(gridTran, tran)
            table.insert(self.starList, go)
        end
    end
    self:RefreshStar(count)
    self.starGrid:Reposition()
end

--刷新星级
function My:RefreshStar(count)
    for i=1, count do
        self.starList[i]:SetActive(true)
    end
end

--隐藏星级
function My:HideStar()
    for i,v in ipairs(self.starList) do
        v:SetActive(false)
    end
end

--点击按钮1
function My:OnBtn1()
    local state = self.state
    if state == nil or self.id == nil then return end
    local mgr = FamilyMissionMgr

    local str = "放弃任务后已进行的时间将清零，旧任务不会消失可重新接取"
    if state == 0 then
        mgr:ReqMissionState(self.id, 0)

    elseif state == 1 or state == 2 then
        self.curIndex = 2
        MsgBox.ShowYesNo(str, self.OnYes, self, "放弃")

    elseif state == 3 then
        mgr:ReqMissionState(self.id, 3)

    elseif state == 4 then
        -- iTrace.Error("放弃")
    end
end

--点击加速
function My:OnBtn2()
    local info = FamilyMissionInfo
    local maxVal = FamilyMissionInfo:GetMaxSpeed(VIPMgr.vipLv) or 0

    local state = self.state
    if state == nil or self.id == nil then return end
    if state == 1 then
        local count = self.count or 0
        if count >= maxVal then
            UITip.Log("当前加速次数已满")
        else
            self.curIndex = 1
            local str = string.format("[FFE9BDFF]请求其他道庭成员进行[00FF00FF]加速[-]，可以减少完成时间。\n[00FF00FF]当前加速次数：%s/%s", count, maxVal)
            MsgBox.ShowYes(str, self.OnYes, self)
        end
    end
end

--点击放弃
function My:OnBtn3()
    local state = self.state
    if state == nil or self.id == nil then return end
    if state == 1 then
        self.curIndex = 2
        local str = "放弃任务后已进行的时间将清零，旧任务不会消失可重新接取"
        MsgBox.ShowYesNo(str, self.OnYes, self, "放弃")
    end
end

--点击确定
function My:OnYes()
    if self.curIndex then
        FamilyMissionMgr:ReqMissionState(self.id, self.curIndex)
        self.curIndex = nil
    end
end

--设置名字
function My:SetName(state, isStart)
    local num = 0
    local cfg = self.cfg
    if state == 0 then
        num = cfg.id
    elseif state == 1 and not isStart then
        num = cfg.id + 10000
    elseif state == 1 and isStart then
        num = cfg.id + 30000
    else
        num = cfg.id + 50000
    end
    self.go.name = num
end

--更新计时器
function My:UpTimer(rTime)
	local timer = self.timer
	timer:Stop()
	timer.seconds = rTime
    timer:Start()
    self:InvCountDown()
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
    if self.leftTime then
        local curVal = self.timer:GetRestTime()
        local maxVal = self.cfg.time * 60
        self.progress.value = 1 - curVal/maxVal
        self.progressLab.text = string.format("[F4DDBDFF]%s", self.timer.remain)
    end
end

--结束倒计时
function My:EndCountDown()
    FamilyMissionMgr:ReqInfo()
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清空星级
function My:ClearStar()
    for i=#self.starList, 1, -1 do
        Destroy(self.starList[i])  
    end
    ListTool.Clear(self.starList)
end

--清理缓存
function My:Clear()
    self.cfg = nil
    self.state = nil
    self.id = nil
    self.lv = nil
    self.curIndex = nil
    self.count = nil
    self.leftTime = nil
    self:ClearTimer()
    self:ClearStar()
end
    
--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My
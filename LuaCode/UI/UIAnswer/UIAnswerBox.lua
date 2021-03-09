--[[
 	authors 	:Liu
 	date    	:2018-5-1 14:59:40
 	descrition 	:答题信息窗口
--]]

UIAnswerBox = Super:New{Name = "UIAnswerBox"}

local My = UIAnswerBox

local AssetMgr = Loong.Game.AssetMgr

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.effList = {}

    self.timeLab = CG(UILabel, root, "RTime")
    self.quesLab = CG(UILabel, root, "QuesLab")
    self.countLab = CG(UILabel, root, "countLab")
    self.rMark = FindC(root, "RightBtn/Mark", des)
    self.rBtn = FindC(root, "RightBtn", des)
    self.wMark = FindC(root, "WrongBtn/Mark", des)
    self.wBtn = FindC(root, "WrongBtn", des)
    self.tipsLab = FindC(root, "tipsLab", des)

    SetB(root, "RightBtn", des, self.OnRightClick, self)
    SetB(root, "WrongBtn", des, self.OnWrongClick, self)

    self:CreateTimer()
    self:InitQuesLab()
    self:InitMaskState()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	AnswerMgr.eAnswer[func](AnswerMgr.eAnswer, self.PrintMsg, self)
end

--更新问题
function My:UpQues(leftTime, ques, num)
    if ques == 0 then return end
    self.key = tostring(ques)
    local str = AnswerCfg[self.key].question
    self.quesLab.text = "[381813FF]"..str
    self:UpTimer(leftTime, 17)
    self.countLab.text = "第"..num.."/20题"
    self:UpShowTip(true)
    UIAnswer.tips:UpShow(false)
end

--活动结束
function My:ActivEnd(name)
    self:UpShowTip(false)
    self:UpBtnState(false)
    self.quesLab.text = "[381813FF]今日论道已结束，优胜者为[28FF00FF]"..name.."[381813FF],请明日再来"
end

--输出答案信息
function My:PrintMsg(res)
    self:UpTimer(0, 2)
    UIAnswer.tips:UpShow(true)
    UIAnswer.tips:UpRes(res)
    UIAnswer.tips:UpData()
    self:UpShowTip(false)
    self:SetEff(res)
end

--设置特效
function My:SetEff(index)
    if index == 1 then
        AssetMgr.LoadPrefab("FX_dadui", GbjHandler(self.LoadPrefabCb, self))
    else
        AssetMgr.LoadPrefab("FX_dadui_1", GbjHandler(self.LoadPrefabCb, self))
    end
end

--加载特效回调
function My:LoadPrefabCb(eff)
    local effName = eff.name..".prefab"
    table.insert(self.effList, effName)
end

--卸载特效
function My:UnloadEffs()
    if #self.effList > 0 then
        for i,v in ipairs(self.effList) do
            AssetMgr.Instance:Unload(v, false)
        end
    end
end

--点击正确按钮
function My:OnRightClick()
    if AnswerInfo.rPos == nil then return end
    self:SetNavPath(AnswerInfo.rPos)
end

--点击错误按钮
function My:OnWrongClick()
    if AnswerInfo.wPos == nil then return end
    self:SetNavPath(AnswerInfo.wPos)
end

--设置导航目标
function My:SetNavPath(pos)
    local pPos = FindHelper.instance:GetOwnerPos()
    if pPos.y > 13.2 then return end
    User:StartNavPath(pos, 30006, -1, 0)
end

--初始化遮罩状态
function My:InitMaskState()
    local posIndex = AnswerInfo.GetXPos()
    if posIndex == 1 then
        self:UpMaskState(true, false)
    else
        self:UpMaskState(false, true)
    end 
end

--更新遮罩状态
function My:UpMaskState(state, state1)
    self.isRight = false
    if state then self.isRight = true end
    self.rMark:SetActive(state)
    self.wMark:SetActive(state1)
end

--更新按钮状态
function My:UpBtnState(state)
    self.rBtn:SetActive(state)
    self.wBtn:SetActive(state)
    self.timeLab.gameObject:SetActive(state)
end

--初始化题目文本
function My:InitQuesLab()
    self.quesLab.text = "[381813FF]倒计时结束后活动正式开始，玩家可点击按钮进行答题，答题时间越快，获得积分越高！"
end

--更新计时器文本
function My:UpTimerLab(rTime)
    self.timeLab.text = rTime
end

--更新显示提示文本
function My:UpShowTip(state)
    self.tipsLab:SetActive(state)
end

--更新计时器
function My:UpTimer(leftTime, val)
    local time = leftTime + val
    self.timeLab.text = time
    self.timer:Restart(time, 1)
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()
    local rTime = self.timer:GetRestTime()
    self:UpTimerLab(math.floor(rTime))
end

--结束倒计时
function My:EndCountDown()
	
end

--清理缓存
function My:Clear()
    self.isRight = false
end

--释放资源
function My:Dispose()
    self:Clear()
    if self.timer then
        self.timer:Stop()
		self.timer:AutoToPool()
        self.timer = nil
    end
    self:UnloadEffs()
    self:SetLnsr("Remove")
end

return My
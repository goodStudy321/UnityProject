--[[
 	authors 	:Liu
 	date    	:2018-4-30 09:55:40
 	descrition 	:答题界面
--]]

UIAnswer = UIBase:New{Name = "UIAnswer"}

local My = UIAnswer

local strs = "UI/UIAnswer/"
require(strs.."UISkiItem")
require(strs.."UIAnswerBox")
require(strs.."UIAnswerRank")
require(strs.."UIAnswerAward")
require(strs.."UIAnswerExitTip")
require(strs.."UIAnswerTips")

function My:InitCustom()
	local des = self.Name
	local root = self.root
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.skiList = {}

	self.boxTran = Find(root, "Msgbox", des)
	self.rankTran = Find(root, "Rank", des)
	self.awardTran = Find(root, "RankAward", des)
	self.exitTipTran = Find(root, "ExitTip", des)
	self.tipsTran = Find(root, "TipsBg", des)
	self.exitBtn = FindC(root, "exitBtn", des)

	for i=1, 2 do
		local tran = Find(root, "Skills/SkillItem"..i, des)
		local it = ObjPool.Get(UISkiItem)
		it:Init(tran, i)
		table.insert(self.skiList, it)
	end
	if ScreenMgr.orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(root, "Rank", des, true)
	end

	SetB(root, "exitBtn", des, self.OnExit, self)

	self:InitModule()
	self:SetNavPos()
	self:AddLnsr()
end

--添加监听
function My:AddLnsr()
    self:SetLnsr("Add")
	local EH = EventHandler
	local EA = EventMgr.Add
	self.OnPlayerMove = EH(self.RespOnPlayerMove, self)
	EA("OnPlayerMove", self.OnPlayerMove)
	ScreenMgr.eChange:Add(self.ScrChg,self)
end

--移除监听
function My:RemoveLsnr()
    self:SetLnsr("Remove")
	local Re = EventMgr.Remove
	Re("OnPlayerMove", self.OnPlayerMove)
	ScreenMgr.eChange:Remove(self.ScrChg,self)
end

--屏幕发生旋转
function My:ScrChg(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "Rank", nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "Rank", nil, true, true)
	end
end

--设置监听
function My:SetLnsr(func)
	local mgr = AnswerMgr
	mgr.eUpShow[func](mgr.eUpShow, self.RespUpShow, self)
	mgr.eHurt[func](mgr.eHurt, self.RespHurt, self)
	UIMainMenu.eHide[func](UIMainMenu.eHide, self.RespBtnHide, self)
end

--响应玩家移动
function My:RespOnPlayerMove(x, z)
	if AnswerInfo.isEnd == 1 then return end
	if x < 3 then
		if self.abox.isRight then return end
		self.abox:UpMaskState(true, false)
	elseif x > 13 then
		if not self.abox.isRight then return end
		self.abox:UpMaskState(false, true)
	else
		return
	end
end

--响应更新显示
function My:RespUpShow(leftTime, ques, num)
	self:UpTimeLab(leftTime, ques)
	self.abox:UpQues(leftTime, ques, num)
end

--响应受击
function My:RespHurt(skill)
	local go = FindHelper.instance:GetSelfGo()
	if go then
		local FrMove = go:GetComponent(typeof(UnitFrMove))
		if FrMove then
			if skill == 2 then
				Destroy(FrMove)
				self:SetHurtState(false)
				self.isHurtTime = nil
			else
				self.isHurtTime = Time.realtimeSinceStartup
			end
		end
	end
end

--响应隐藏退出按钮
function My:RespBtnHide(value)
	if self.exitBtn then
		self.exitBtn:SetActive(value)
	end
end

--更新数据
function My:Update()
	if self.skiList then
		for i,v in ipairs(self.skiList) do
			v:Update()
		end
	end
	if self.isHurtTime then
		if Time.realtimeSinceStartup - self.isHurtTime > 4 then
			self:SetHurtState(false)
			self.isHurtTime = nil
		else
			self:SetHurtState(true)
		end
	end
end

--设置受击状态
function My:SetHurtState(state)
	for i,v in ipairs(self.skiList) do
		v.isHurt = state
	end
end

--更新倒计时文本
function My:UpTimeLab(leftTime, ques)
	if ques ~= 0 then return end
	local time = leftTime + 60
	self:CreateTimer()
	self.timer:Restart(time, 1)
end

--初始化模块
function My:InitModule()
	self.abox = ObjPool.Get(UIAnswerBox)
	self.abox:Init(self.boxTran)
	self.arank = ObjPool.Get(UIAnswerRank)
	self.arank:Init(self.rankTran)
	self.aAward = ObjPool.Get(UIAnswerAward)
	self.aAward:Init(self.awardTran)
	self.exitTip = ObjPool.Get(UIAnswerExitTip)
	self.exitTip:Init(self.exitTipTran)
    self.tips = ObjPool.Get(UIAnswerTips)
    self.tips:Init(self.tipsTran)
end

--设置导航位置
function My:SetNavPos()
	AnswerInfo.rPos = CustomInfo:FindNavPos("NavPos1")
	AnswerInfo.wPos = CustomInfo:FindNavPos("NavPos2")
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
    self.abox:UpTimerLab(math.floor(rTime))
end

--结束倒计时
function My:EndCountDown()
	self:ClearTimer()
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--重写UIBase方法，持续显示
function My:ConDisplay()
    do return true end
end

--点击退出按钮
function My:OnExit()
	MsgBox.ShowYesNo("是否退出场景？", self.YesCb, self)
end

--点击确定按钮
function My:YesCb()
    SceneMgr:QuitScene()
end

--清空数据
function My:ClearData()
	local skiList = self.skiList
	if #skiList > 0 then
		for i,v in ipairs(skiList) do
			ObjPool.Add(skiList[i])
			skiList[i] = nil
		end
	end
	ObjPool.Add(self.abox)
	self.abox = nil
	ObjPool.Add(self.arank)
	self.arank = nil
	ObjPool.Add(self.aAward)
	self.aAward = nil
	ObjPool.Add(self.exitTip)
	self.exitTip = nil
	ObjPool.Add(self.tips)
	self.tips = nil
end

--清理缓存
function My:Clear()
	
end

--释放资源
function My:DisposeCustom()
	self:Clear()
	self:RemoveLsnr()
	self:ClearTimer()
	self:ClearData()
end

return My
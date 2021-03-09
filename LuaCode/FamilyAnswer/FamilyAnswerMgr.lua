--[[
 	authors 	:Liu
 	date    	:2018-5-29 15:54:08
 	descrition 	:道庭答题管理
--]]

FamilyAnswerMgr = {Name = "FamilyAnswerMgr"}

local My = FamilyAnswerMgr

local Info = require("FamilyAnswer/FamilyAnswerInfo")

My.State = false
My.isHide = true

function My:Init()
	Info:Init()
	self:AddLnsr()
	self.eGetExp = Event()
	self.eUpRank = Event()
	self.eUpState = Event()
	self.eUpTimer = Event()
	self.eEndTimer = Event()
	self.eShowTip = Event()
	self.eIsCollection = Event()
	self.eAnswerTime = Event()
	self:CreateTimer()
	self:CreateAnswerTimer()
end

--添加监听
function My:AddLnsr()
    self:SetLnsr(ProtoLsnr.Add)
end

--移除监听
function My:RemoveLsnr()
    self:SetLnsr(ProtoLsnr.Remove)
end

--设置监听
function My:SetLnsr(func)
	func(21100,self.RespRank, self)
	func(21102,self.RespGetExp, self)
	func(21098,self.RespCollectInfo, self)
	func(21096,self.RespAnswerTime, self)
end

--响应答题时间
function My:RespAnswerTime(msg)
	local sTime = TimeTool.GetServerTimeNow()*0.001
	leftTime = msg.time - sTime
	-- iTrace.Error("time = "..msg.time.." leftTime = "..leftTime)
	self:UpTimer(leftTime, self.timer1)
end

--响应道庭答题排行榜
function My:RespRank(msg)
	Info:SetRankDic(Info.selfRankDic, msg.rank, msg.name, msg.score)
	for i,v in ipairs(msg.rank_list) do
		Info:SetRankDic(Info.allRankDic, v.rank, v.name, v.score)
	end
	self.eUpRank(Info.allRankDic)
end

--响应固定时间获取经验
function My:RespGetExp(msg)
	self.eGetExp(msg.exp)
end

--响应道庭答题活动开启或关闭
function My:RespActivInfo(status, endTime)
	FamilyAnswerInfo.activState = status
	if status == 2 then
		self.isHide = false
		self.State = true
		local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
		local leftTime = endTime - sTime
		self:UpTimer(leftTime, self.timer)
	else
		self.isHide = true
		self.State = false
		Info.coll = false
		self:StopTimer()
	end
	self.eUpState(status)
end

--响应采集信息
function My:RespCollectInfo(msg)
	if msg.collection == 1 then
		Info.coll = true 
		CollectMgr:SetStop(true)
	end
	self.eIsCollection(Info.coll)
end

--更新计时器
function My:UpTimer(rTime, timer)
	-- local timer = self.timer
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
end

--创建答题计时器
function My:CreateAnswerTimer()
    if self.timer1 then return end
    self.timer1 = ObjPool.Get(DateTimer)
    local timer = self.timer1
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()
	local remain1 = self.timer1:GetRestTime()
	self.eAnswerTime(remain1)

	local time = self.timer.remain
	local remain = self.timer:GetRestTime()
	self.eUpTimer(time, remain)
	if remain > 30 then
		self.eShowTip(time, false)
	else
		self.eShowTip(time, true)
	end
end

--结束倒计时
function My:EndCountDown()
	self.eEndTimer()
end

--是否隐藏计时器
function My:isHideTimer(state)
	self.isHide = state
end

--停止计时器
function My:StopTimer()
	if self.timer then self.timer:Stop() end
	if self.timer1 then self.timer1:Stop() end
end

--清理缓存
function My:Clear()
	self:StopTimer()
	CollectMgr:SetStop(false)
end

--释放资源
function My:Dispose()
	self:RemoveLsnr()
	TableTool.ClearFieldsByName(self,"Event")
end

return My
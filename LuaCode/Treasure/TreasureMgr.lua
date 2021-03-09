--[[
 	authors 	:Liu
 	date    	:2018-6-27 10:59:00
 	descrition 	:寻宝活动管理
--]]

TreasureMgr = {Name = "TreasureMgr"}

local My = TreasureMgr

local Info = require("Treasure/TreasureInfo")

--判断符文免费时间是否已结束
My.isEnd = false
--默认显示红点
My.isShow = false
--红点列表
My.actionDic = {}
--寻宝钥匙列表
My.idList = {}
--巅峰寻宝红点状态（0-默认 1-显示 2-隐藏）
My.state = 0
--系统id
My.sysIdList = {504, 60}

function My:Init()
	Info:Init()
	self:InitIdList()
	self:CreateTimer()
	self:SetLnsr(ProtoLsnr.Add)
	self.eUpWTreasLogs = Event()
	self.eUpSTreasLogs = Event()
	self.eUpRuneTreas =Event()
	self.eUpFreeTime = Event()
	self.eEndFreeTime = Event()
	UserMgr.eLvEvent:Add(self.LvChange, self)
	OpenMgr.eOpen:Add(self.RespOpen, self)
	OpenMgr.eOpenNow:Add(self.RespOpenNow, self)
end

--设置监听
function My:SetLnsr(func)
	func(21240,self.RespTreasureInfo, self)
	func(21242,self.RespUpWEquipTreasLogs, self)
	func(21252,self.RespUpSEquipTreasLogs, self)
	func(21244,self.RespUpWTopTreasLogs, self)
	func(21272,self.RespUpSTopTreasLogs, self)
	func(21262,self.RespRuneTreasure, self)
	func(20820,self.RespSortOutAll, self)
	PropMgr.eAdd:Add(self.RespAdd, self)
end

--响应道具获得
function My:RespAdd(tb)
	local id = tb.type_id
	for i,v in ipairs(My.idList) do
		if v == id then
			self:ShowAction(i)
		end
	end
end

--响应寻宝信息(响应时，界面还没有打开)
function My:RespTreasureInfo(msg)
	for i,v in ipairs(msg.world_equip_logs) do
		Info:SetWordLogs(v.id, v.str, false, 1)
	end
	for i,v in ipairs(msg.equip_logs) do
		table.insert(Info.sTreasLogs, v)
	end
	for i,v in ipairs(msg.world_summit_logs) do
		Info:SetWordLogs(v.id, v.str, false, 2)
	end
	for i,v in ipairs(msg.summit_logs) do
		table.insert(Info.topSTreasLogs, v)
	end
	Info.freeTime = msg.rune_free_time
	Info.equipLuckVal = msg.equip_weight
	Info.topLuckVal = msg.summit_weight
	self:UpTimer()
	self:UpRedDot()
end

--响应全服装备寻宝日志
function My:RespUpWEquipTreasLogs(msg)
	local logs = msg.world_equip_logs
	for i,v in ipairs(logs) do
		Info:SetWordLogs(v.id, v.str, true, 1)
	end
	self.eUpWTreasLogs(logs, 1)
end

--响应全服巅峰寻宝日志
function My:RespUpWTopTreasLogs(msg)
	local logs = msg.world_summit_logs
	for i,v in ipairs(logs) do
		Info:SetWordLogs(v.id, v.str, true, 2)
	end
	self.eUpWTreasLogs(logs, 3)
end

--请求装备寻宝
function My:ReqEquipTreasure(times)
	local msg = ProtoPool.GetByID(21251)
	msg.times = times
	ProtoMgr.Send(msg)
end

--响应装备寻宝
function My:RespUpSEquipTreasLogs(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	local logs = msg.add_log_list
	for i,v in ipairs(logs) do
		table.insert(Info.sTreasLogs, 1, v)
	end
	Info.equipLuckVal = msg.equip_weight
	self:UpRedDot()
	self.eUpSTreasLogs(logs, 1)
end

--请求巅峰寻宝
function My:ReqTopTreasure(times)
	local msg = ProtoPool.GetByID(21271)
	msg.times = times
	ProtoMgr.Send(msg)
end

--响应巅峰寻宝
function My:RespUpSTopTreasLogs(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	local logs = msg.add_log_list
	for i,v in ipairs(logs) do
		table.insert(Info.topSTreasLogs, 1, v)
	end
	Info.topLuckVal = msg.summit_weight
	self:UpRedDot()
	self.eUpSTreasLogs(logs, 3)
end

--请求符文寻宝
function My:ReqRuneTreasure(times)
	local msg = ProtoPool.GetByID(21261)
	msg.times = times
	ProtoMgr.Send(msg)
end

--响应符文寻宝
function My:RespRuneTreasure(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	Info.freeTime = msg.rune_free_time
	self:UpTimer()
	self:UpRedDot()
	self.eUpRuneTreas()
end

--请求装备寻宝仓库一键取出
function My:ReqSortOutAll(bagId)
	local msg = ProtoPool.GetByID(20819)
	msg.bag_id = bagId
	ProtoMgr.Send(msg)
end

--响应装备寻宝仓库一键取出
function My:RespSortOutAll(msg)
	local err = msg.err_code
	if (err>0) then
		UITip.Log(ErrorCodeMgr.GetError(err))
		return
	end
	UITip.Log("一键取出成功")
end

--响应等级变化
function My:LvChange()
    self:UpRedDot()
end

--响应开启功能
function My:RespOpen(id)
	if id == My.sysIdList[1] then
		self:UpRedDot()
	elseif id == My.sysIdList[2] then
		--化神寻宝
	end
end

--响应当前系统功能开启
function My:RespOpenNow(isUpdate, list)
	local isOpen = OpenMgr:IsOpen(My.sysIdList[2])
	if isUpdate == 0 then
		if isOpen then self.state = 2 end
	end
	if self.state == 2 then return end
	for i,v in ipairs(list) do
		if v == My.sysIdList[2] then
			self.state = 1
			self:UpRedDot()
			break
		end

	end
end

--设置巅峰寻宝默认红点
function My:SetTopAction()
	self.state = 2
	self:UpRedDot()
end

--显示红点
function My:ShowAction(index)
	if index == 2 then
		if not OpenMgr:IsOpen(My.sysIdList[1]) then return end
	end
	local key = tostring(index)
	local actId = ActivityMgr.XB
	SystemMgr:ShowActivity(actId, index)
	My.actionDic[key] = true
end

--更新红点
function My:UpRedDot()
	local actId = ActivityMgr.XB
	self:UpRuneAction(actId)
	self:UpEquipAction(actId)
	self:UpTopAction(actId)
end

--更新装备寻宝红点
function My:UpEquipAction(actId)
	local isEquipShow = self:IsAction(1)
	if isEquipShow then
		SystemMgr:ShowActivity(actId, 1)
		My.actionDic["1"] = true
    else
		SystemMgr:HideActivity(actId, 1)
		My.actionDic["1"] = false
	end
end

--更新符文寻宝红点
function My:UpRuneAction(actId)
	if not OpenMgr:IsOpen(My.sysIdList[1]) then return end
	local isRuneShow = self:IsAction(2)
	if Info.freeTime == 0 or self.isEnd or self.isShow or isRuneShow then
		SystemMgr:ShowActivity(actId, 2)
		My.actionDic["2"] = true
    else
		SystemMgr:HideActivity(actId, 2)
		My.actionDic["2"] = false
	end
end

--更新巅峰寻宝红点
function My:UpTopAction(actId)
	if not OpenMgr:IsOpen(My.sysIdList[2]) then return end
	local isTopShow = self:IsAction(3)
	if self.state == 1 or isTopShow then
		SystemMgr:ShowActivity(actId, 3)
		My.actionDic["3"] = true
    else
		SystemMgr:HideActivity(actId, 3)
		My.actionDic["3"] = false
	end
end

--判断是否显示红点
function My:IsAction(index)
	local tokens = ItemTool.GetNum(My.idList[index])
	if tokens > 0 then
		return true
	end
	return false
end

--初始化寻宝钥匙列表
function My:InitIdList()
	local list = {"14", "15", "95"}
	for i,v in ipairs(list) do
		local cfg = GlobalTemp[v]
		table.insert(My.idList, cfg.Value2[1])
	end
end

--创建计时器
function My:CreateTimer()
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--更新计时器
function My:UpTimer()
	local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
	local leftTime = Info.freeTime - sTime
	local timer = self.timer
	timer:Stop()
	timer.seconds = leftTime
	timer:Start()
end

--间隔倒计时
function My:InvCountDown()
    self.eUpFreeTime()
end

--结束倒计时
function My:EndCountDown()
	self.eEndFreeTime()
	self.isEnd = true
	self:UpRedDot()
end


--清理缓存
function My:Clear()
	Info:Clear()
	if self.timer then self.timer:Stop() end
	self.isEnd = false
end

--释放资源
function My:Dispose()
	self:SetLnsr(ProtoLsnr.Remove)
	UserMgr.eLvEvent:Remove(self.LvChange, self)
	OpenMgr.eOpen:Remove(self.RespOpen, self)
	OpenMgr.eOpenNow:Remove(self.RespOpenNow, self)
	TableTool.ClearFieldsByName(self,"Event")
end

return My
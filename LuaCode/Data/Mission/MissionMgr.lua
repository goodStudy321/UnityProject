--region MissionMgr.lua
--Date
--此文件由[HS]创建生成
require("Data/Mission/MissionNetwork")
require("Data/Mission/MissionTool")
require("Data/Mission/MissionNavPath")
require("Data/Mission/MissionFlowChart")
require("Data/Mission/Mission")
require("Data/Mission/MissionTarget")
require("Data/Mission/MissionTargetKill")
require("Data/Mission/MissionTargetTalk")
require("Data/Mission/MissionTargetCollection")
require("Data/Mission/MissionTargetPathfinding")
require("Data/Mission/MissionTargetFlowChart")
require("Data/Mission/MissionTargetItem")
require("Data/Mission/MissionTargetCopy")
require("Data/Mission/MissionTargetFighting")
require("Data/Mission/MissionTargetStrengthen")
require("Data/Mission/MissionTargetGetExp")
require("Data/Mission/MissionTargetSystem")
require("Data/Mission/MissionTargetLiveness")
require("Data/Mission/MissionTargetFriend")
require("Data/Mission/MissionTargetWorldBoss")
require("Data/Mission/MissionTargetCompose")
require("Data/Mission/MissionTargetOVO")
require("Data/Mission/MissionTargetAllStrengthen")
require("Data/Mission/MissionTargetMission")
require("Data/Mission/MissionTargetItemII")
require("Data/Mission/MissionTargetConfine")
require("Data/Mission/MissionTargetFamilyNum")
require("Data/Mission/MissionTargetFamilyEscort")
require("Data/Mission/MissionTargetFamilyRobbery")
require("Data/Mission/MissionTargetCopyFive")
MissionMgr = {Name="MissionMgr"}
local M = MissionMgr

local Network = MissionNetwork
local PP = UnityEngine.PlayerPrefs
local MD = User.MapData

--是否弹出主线引导菜单
M.MissionMenu = false

M.OpenFlyLv = 10
--事件
M.eAddMission = Event()
M.eUpdateMissStatus = Event()
M.eUpdateMissTarget = Event()
M.eCompleteEvent = Event()
M.eCleanMission = Event()

M.eEndUpdateMission = Event()	--任务更新完成
M.eNavPathEvent = Event()
M.eEndEscortMission = Event()
M.eCleanAllMission = Event()
M.eUpdateMission = Event()
M.ePlayMissionEffect = Event()

function M:Init()
	Network:Init()
	self.Main = nil							--主线任务
	self.FeederList = {} 					--支线任务
	self.TurnList = {}						--日常任务
	self.LivenessList = {}					--每日活跃任务（并入日常任务）
	self.FamilyList = {} 					--帮派任务
	self.Escort = nil 						--护送任务
	self.CurExecuteType = nil				--当前执行的任务类型
	self.CurExecuteChildType = nil 			--当前执行的任务子类型
	self.RewardGroup = nil
	self.DelRecord = {}						--删除任务缓存
	self.UpdateRecord = {} 					--更新任务缓存
	self.MainRed = 0
	self.FeederRed = 0
	self.TurnRed = 0
	self.FamilyRed = 0
	self.LivenessRed=0
	UserMgr.eLvEvent:Add(self.LvEvent, self)
	self:AddEvent()
end

function M:AddEvent()
	local M = EventMgr.Add
	self:UpdateEvent(M)
	Network:AddProto()
end

function M:RemoveEvent()
	local M = EventMgr.Remove 
	self:UpdateEvent(M)
	Network:RemoveProto()
end

function M:UpdateEvent(M)
   	local EH = EventHandler
	M("CreateNPC", EH(self.CreateNPC, self))
	--M("UpdateMission", EH(self.UpdateMission, self))
	--M("UpdateMissionTarget", EH(self.UpdateMissionTarget, self))
	M("NPCRelatedMission", EH(self.NPCRelatedMission, self))
	--M("MissionCancel", EH(self.MissionCancel, self))
	--M("ReceiveMissionSuccess", EH(self.ReceiveMissionSuccess, self))
	M("ExcuteMission", EH(self.AutoExecuteAction, self))
	M("ClickNPC", EH(self.ClickNPC, self))
	M("MissNavPathTrigger",EH(self.NavPathTrigger, self))
	--M("UpdateMissionEnd", EH(self.UpdateMissionEnd, self))
	--M("CleanAllMission",EH(self.CleanAllMission, self))
	M("DropEnd",EH(self.LvEvent, self))
	M("OnChangeScene", EH(self.ChangeSceneEnd, self))

end
--[[#############################################################]]--
function M:EnterGetMission(mission, isEvent)
	self:AddMission(mission)
	if isEvent == true then
		self.eAddMission(mission.mission_id)
	end
end

--[[#############################################################]]--
--获取任务
function M:GetMission(id, targets, status, succ)
	local key = tostring(id)
	local temp = MissionTemp[key]
	if not temp then return nil end
	local data = Mission:New()
	data.Key = key
	data.ID = id
	--data.Temp = temp
	data:UpdateTemp(temp)
	data:UpdateStatus(status)
	data.Succ = succ
	if not data then 
		iTrace.eError("hs",string.format("任务id %s 创建任务失败",id))
		return
	end
	data:CreateTarget()
	self:UpdateTargets(data, targets)
	User:RelatedNPC(data.ID, data.Status)
	return data
end

--[[############################添加 移除 替换任务#################################]]--
--添加任务
function M:AddMission(mission)
	local id = mission.mission_id
	local listens = mission.listen
	local status = mission.status --任务状态，1未接。2未完成，3可提交
	local succ = mission.succ_times --次数
	local key = tostring(id)
	if succ ~= nil then
	   	local temp = MissionTemp[key]
	   	if not temp then
		   iTrace.eError("hs",string.format("任务id[%s]不存在",id))
		   return
	   	end
		local mType = MissionType
		local t = temp.type
		local data = nil
	   	if t == mType.Main then
		   self:AddMainMission(mission)
		   Hangup:MissionUpdate(id, status)
		elseif t == mType.Feeder then
			local fList = self.FeederList	
			local data = self:UpdateMissList(fList, id, listens, status, succ)
			if status == MStatus.ALLOW_SUBMIT then
				local frist = self:FristFeeder(nil)
				if frist == 0 then 
					self:FristFeeder(true)
				end
			end
			if data.Temp.childType == 1 then
				self.eUpdateMission(id)
			end

		elseif t == mType.Turn then
			local tList = self.TurnList	
			self:UpdateMissList(tList, id, listens, status, succ)
	   	elseif t == mType.Family then
			local fList = self.FamilyList	
			self:UpdateMissList(fList, id, listens, status, succ)
		elseif t == mType.Escort then
			data = self:GetMission(id, listens, status, succ)
		   self:AddEscortMission(data)
		elseif t==mType.Liveness then
			local tList=self.LivenessList
			self:UpdateMissList(tList, id, listens, status, succ)
	   	end
	   	if t == self.CurExecuteType and status == MStatus.ALLOW_SUBMIT then
		   self:Execute(false)
	   	end
   	else
	   self:UpdateMissionStatus(id, MStatus.EXECUTE)
   	end
	   --self:Execute(false)
end

--添加主线任务
function M:AddMainMission(mission)
	local id = mission.mission_id
	local listens = mission.listen
	local status = mission.status --任务状态，1未接。2未完成，3可提交
	local succ = mission.succ_times --次数
	local key = tostring(id)
	local main = self.Main
	if main and main.ID == id then
		self:ChangeTargets(id, listens)
		main:UpdateStatus(status)
		return
	end
	if not SceneMgr.IsMissionScene() then
		self:ChangeMainMission(self:GetMission(id, listens, status, succ))
	else
		--如果在流程树场景中 退出场景后才能更新任务
		--这里UpdateRecord用于缓存当前需要变更的任务
		self:ChangeMainMission(nil)
		--[[
		local len = #self.UpdateRecord
		local index = nil
		for i=1, len do
			if self.UpdateRecord[i].mission_id == id then
				index = i
				break
			end
		end
		if not index then
			table.insert(self.UpdateRecord, mission)
		else
			self.UpdateRecord[index] = mission
		end
		]]--
		self:AddRecord(self.DelRecord, self.Main)
		self:AddRecord(self.UpdateRecord, mission)
		self.eEndUpdateMission()
		return
	end
	self:CheckAutoExecuteAction()
	local temp = MissionTemp[key]
	if not temp then return end
	self:EndFlowChartChangeScene(temp.jumpScreen, temp.screen)
end

--加入缓存记录
function M:AddRecord(list, mission)
	local len = #list
	local index = nil
	for i=1, len do
		if list[i].mission_id == id then
			index = i
			break
		end
	end
	if not index then
		table.insert(list, mission)
	else
		list[index] = mission
	end
end

--添加任务列表
function M:UpdateMissList(list, id, listens, status, succ)
	local key = tostring(id)
	local data = list[key]
	if data then
		data:UpdateStatus(status)
		data.Succ = succ
		--data:CreateTarget()
		self:UpdateTargets(data, listens)
	else
		data = self:GetMission(id, listens, status, succ)
	end	
	list[key] = self:AddOtherMission(list[key], data, list)
	return data
end

--添加其他任务
function M:AddOtherMission(first, data, list)
	local id = data.ID
	local key = data.Key
	local mission = list[key]
	if mission then
		if mission.Succ and mission.Succ ~= data.Succ then			--跑环任务检测环数奖励
			self:CheckReward(data.Temp, MissionType.Turn, mission.Succ) 
		end
	end
	list[key] = data
	return data
end

function M:AddEscortMission(data)
	local mission = self.Escort
	if mission then
		if mission.ID ~= data.ID then
			mission:Dispose()
			mission = nil
		else
			mission = data
			--self:UpdateMissionEnd()
			self.eEndEscortMission()
			return
		end
	end
	data.Status = MStatus.EXECUTE
	self.Escort = data
	--self:UpdateMissionEnd()
	self.eEndEscortMission()
end

function M:ChangeTargets(id, targets, isEvent)
	local data  = self:GetMissionForID(id)
	if data then
		self:UpdateTargets(data, targets)
		if isEvent == true then
			self.eUpdateMissTarget(id)
		end
	end
end

function M:UpdateTargets(data, targets)
	for i=1,#targets do
		local target = targets[i]
		if target then
			local t = target.type			--类型
			local v = target.val				--目标类型
			local n = target.num				--当前进度
			data:UpdateTarget(t, v, n, i)
			if data.Temp.childType == 1 then
				M.eUpdateMission(data.ID)
			end
		end
	end
end
--[[#############################################################]]--

--改变主线任务
function M:ChangeMainMission(miss)
	if self.Main then 
		if miss then
			self.eCleanMission(self.Main.ID)
			self.Main:Dispose() 
			self.Main = nil
		else
			self.Main:UpdateStatus(MStatus.COMPLETE)
		end	
	end
	if not miss then return end
	self.Main = miss
end

--场景切换完成
--是否有需要替换的任务
function M:ChangeSceneEnd()
	if not SceneMgr.IsMissionScene() then
		local delLen = #self.DelRecord
		if delLen > 0 then
			local mission = self.DelRecord[1]
			table.remove(self.DelRecord, 1)
			self.eCompleteEvent(mission.ID)
			self:CompleteMission(mission.ID)
		end

		local len = #self.UpdateRecord
		if len > 0 then
			local mission = self.UpdateRecord[1]
			table.remove(self.UpdateRecord, 1)
			local id = mission.mission_id
			local listens = mission.listen
			local status = mission.status --任务状态，1未接。2未完成，3可提交
			local succ = mission.succ_times --次数
			local key = tostring(id)
			local data = self:GetMission(id, listens, status, succ)
			if data then
				self:ChangeMainMission(data)
				self:CheckAutoExecuteAction()
				local temp = data.Temp
				if self.CurExecuteType == temp.type then
					self:EndFlowChartChangeScene(temp.jumpScreen, temp.screen)
				end
				self:UpdateMissionEnd()
			end
		end
	end
end

--更新任务状态
function M:UpdateMissionStatus(id, status, isEvent)
	local data  = self:GetMissionForID(id)
	if data then
		data:UpdateStatus(status) 
		self:UpdateMissionEffect(data.Status)
		User:RelatedNPC(data.ID, data.Status)
		if isEvent == true then 
			self.eUpdateMissStatus(id)
		end
	end
end

function M:CompleteMission(id, isComplete, isEvent)
	local mType = MissionType
	local data  = self:GetMissionForID(id)
	if data then
		local temp = data.Temp
		local t = nil
		local key = data.Key
		if self.Main and self.Main.ID == id then
			if not SceneMgr.IsMissionScene() then
				if isComplete == true then
					self.Main:UpdateStatus(MStatus.COMPLETE)		--主线任务取消了要显示可接任务
				else
					self.Main:Dispose()
					self.Main = nil
					self.eCleanMission(id)
				end
			else
				return
			end
		elseif self.FeederList and self.FeederList[key] then
			if isComplete == true then
				self:ChangeStatusMission(self.FeederList, id, key)
			else
				self:DestoryMission(self.FeederList, id, key)
			end
		elseif self.TurnList and self.TurnList[key] then
			t = mType.Turn 
			if isComplete == true then
				self:ChangeStatusMission(self.TurnList, id, key)
			else
				ring = self:DestoryMission(self.TurnList, id, key)
			end
		elseif self.LivenessList and self.LivenessList[key] then
			t = mType.Liveness 
			if isComplete == true then
				self:ChangeStatusMission(self.LivenessList, id, key)
			else
				ring = self:DestoryMission(self.LivenessList, id, key)
			end
		elseif self.FamilyList and self.FamilyList[key] then
			t = mType.Family 
			if isComplete == true then
				self:ChangeStatusMission(self.FamilyList, id, key)
			else
				ring = self:DestoryMission(self.FamilyList, id, key)
			end
		elseif self.Escort and self.Escort.ID == id then
			self.Escort:Dispose()
			self.Escort = nil
			self.eCleanMission(id)
		end
		if isComplete == true then 
			self:CheckReward(key, id, t, ring)
			User:RelatedNPC(id, MStatus.None)
			self.eCompleteEvent(id)
			if temp and temp.exp and temp.exp > 0 then
				self:UpdateMissionEffect(MStatus.COMPLETE)
			end
		end
		if isEvent then
			self.eUpdateMissStatus(id)
		end
	end
end

function M:ChangeStatusMission(dic, id, key)
	local mission = dic[key]
	if mission then
		self:UpdateMissionStatus(id, MStatus.COMPLETE)
		Hangup:MissionUpdate(id, MStatus.COMPLETE)
		self:UpdateMissionEnd()
	end
end

--销毁任务
function M:DestoryMission(dic, id, key)
	if dic[key] then
		dic[key]:Dispose()
	end
	dic[key] = nil
	self.eCleanMission(id)
	return ring
end

--[[############################交互#################################]]--
--检测跑环奖励并打开奖励UI
function M:CheckReward(temp, t, ring)
	local mType = MissionType
	if t and (t == mType.Turn or t == mType.Family) then
		if temp then
			local group = MissionGroupTemp[tostring(temp.group)]
			if group then
				local t1,t2 = math.modf(ring / group.ring)
				if t2 == 0 then 
					self.RewardGroup = group
					if self.RewardGroup then
						UIMgr.Open(UIGetRewardPanel.Name, self.OnShowReward, self)
					end
				end
			end
		end
	end
end
--跑环奖励UI打开
function M:OnShowReward(name)
	local ui = UIMgr.Dic[name]
	if ui then
		local temp = self.RewardGroup
		local list = nil
		local reward  = temp.reward
		if reward then
			list = {}
			local data = {}
			data.k = reward.id
			data.v = reward.num
			data.b = reward.bind >= 1
			table.insert(list,data)
		end
		if list then
			ui:UpdateData(list)
		else
			ui:Close()
		end
	end
end

--[[#############################################################]]--


--侦听npc创建 关联npc
function M:CreateNPC()
	if self.Main then
		User:RelatedNPC(self.Main.ID, self.Main.Status)
	end
end


--检测自动挂机
function M:CheckAutoExecuteAction()
	if User.instance.IsInitLoadScene == true then return end
	local mission = self:GetCurExecuteForType()
	if not mission then return end
	local isHg = Hangup:GetAutoHangup();
	if mission.IsAutoExcute == true or isHg == false then
		local temp = mission.Temp
		local stat = mission.Status 
		local receive = stat == MStatus.NOT_RECEIVE and temp.autoReceive == 1
		local submit = stat == MStatus.ALLOW_SUBMIT and temp.autoSubmit == 1
		local talk = stat == MStatus.ALLOW_SUBMIT and (temp.autoTalk == 1 or temp.tarType == MTType.TALK) 
		local flowChart =  isHg == false and temp.tarType == MTType.FlowChart and stat == MStatus.EXECUTE
		if receive == true or submit == true or talk == true or flowChart == true then
			mission:AutoExecuteAction()
		end
	end
end

--检查是否有可用的主线/日常
function M:CheckExecuteMainOrTurn()
	local escort = self.Escort
	if escort ~= nil then return true end
	local main = self.Main
	if main then
		if main.Temp.tarType == MTType.Confine then return false end
		if main:CheckLevel() == false then return true end
	end
	local list = self.TurnList
	if list then
		if LuaTool.Length(list) > 0 then return true end
	end
	if LuaTool.Length(self.LivenessList) > 0 then return true end 
	return false
end
-------------------------------------------------------------------------
--任务与npc关联
function M:NPCRelatedMission(npcid)
	if self.Main then self.Main:IsRelatedNpc(npcid) end
end

function M:AutoExecuteActionOfID(id)	
	local mission = self:GetMissionForID(id)
	if mission then
		if mission.Temp and mission.Temp.lv > MD.Level then
			--HM.IsSituFight = true
			return 
		end
		--HM.IsAutoHangup = true;
		if mission.Temp.tarType ~= MTType.Copy then		
			self:SetCurExecuteType(mission.Temp.type)	
		end
		mission:AutoExecuteAction(MExecute.ClickItem)
	end
end

--设置当前执行任务状态
function M:SetCurExecuteType(value)
	if App.IsDebug == true then
		iTrace.sLog("hs",string.format("改变任务类型 %s 为 %s",self.CurExecuteType, value))
	end
	self.CurExecuteType = value
end

function M:AutoExecuteActionOfType(type)	
	self:SetCurExecuteType(type)
	self:AutoExecuteAction(MExecute.ClickItem)
end

function M:AutoExecuteAction(execute)
	local mission = self:GetCurExecuteForType()
	if mission then
		local temp = mission.Temp
		if temp then
			iTrace.eLog("HS",string.format("测试 当前挂机执行的任务类型{类型%s；名字：}", temp.type, temp.name))
			if temp.lv > MD.Level then
			--HM.IsSituFight = true
				return 
			end
			if self:IsRebirth(mission) == true then
				return
			end
		end
		mission:AutoExecuteAction(execute)
	end
end

function M:ExecuteRebberyMiss()
	for i,v in ipairs(RobberyMissTemp) do
		local id = v.id
		if id ~= 0 then
			local data = self:GetMisForID(self.FeederList, id)
			if data then 
				data:AutoExecuteAction(MExecute.ClickItem)
				return
			end
		end
	end
end


function M:EndFlowChartChangeScene(jumpScreen, screen)
	if jumpScreen then
		self.JumpScreen = jumpScreen
		self.MissionScreen = screen
		SceneMgr.eChangeEndEvent:Add(self.ChangeEndEvent, self)
	end
end

function M:ChangeEndEvent(isLoad)
	if User.SceneId ~= self.MissionScreen then return end
	if self.JumpScreen then
		SceneMgr.eChangeEndEvent:Remove(self.ChangeEndEvent, self)
		--if SceneMgr.IsSpecial() == true then return end
		--iTrace.eWarning("hs","场景切换完成进入场景"..self.JumpScreen)
		SceneMgr:ReqPreEnter(self.JumpScreen, true)
   		self.JumpScreen = nil
   		self.MissionScreen = nil
   	end
end

function M:ClickNPC(npcid)
	if MarryInfo.npcId == npcid then--特殊处理点击红娘Npc
		if User.SceneId == MarryInfo.npcSId then
			if MarryInfo:IsOpen() then
				UIMarryInfo:OpenTab(4)
			else
				UITip.Log("系统未开启")
			end
			return
		end
    end


	if self.Main and self.Main:IsRelatedNpc(npcid) then
		--self.Main:ShowNPCPanel(npcid)
		self.Main:AutoExecuteAction(MExecute.ClickNpc)
		return
	end
	if self.TurnList then
		for k,v in pairs(self.TurnList) do
			if v:IsRelatedNpc(npcid) then
				v:AutoExecuteAction(MExecute.ClickNpc)
				return
			end
		end
	end
	if self.FamilyList then
		for k,v in pairs(self.FamilyList) do
			if v:IsRelatedNpc(npcid) then
				v:AutoExecuteAction(MExecute.ClickNpc)
				return
			end
		end
	end
	if EscortMgr:IsRelatedNpc(npcid) == true then return end
	UIMgr.Open(UINPCDialog.Name, function ()
	 		local ui = UIMgr.Dic[UINPCDialog.Name]
	 		if ui then
	 			ui:UpdateNPCClickData(npcid)
	 		end
	end)
end

function M:NavPathTrigger()
	self.eNavPathEvent()
end

function M:UpdateMissionEffect(static)
	self.ePlayMissionEffect(static)
	--[[
	local ui = UIMgr.Dic[UIMainMenuLeft.Name]
	if ui then
		ui:PlayMissionEffect(static)
	end
	]]--
end

--检查传入id任务是否完成
function M:CheckComplete(id)
	if not self.Main then return false end
	if self.Main.ID < id then return false end
	if self.Main.ID == id and self.Main.Status < MStatus.ALLOW_SUBMIT then
		return false
	end
	return true
end

function M:LvEvent()
	local isHg = Hangup:GetAutoHangup();
	if isHg == false then 
		return 
	end
	local isPause = Hangup:IsPause();
	if isPause == true then
		return;
	end
	self:UpdateMissionEnd()
	if User.IsInitLoadScene then return end
	if FlowChartMgr.Current then return end
	local mission = self:GetCurExecuteForType()
	if not mission then return end
	if MD.Level <= 1 then return end 
	mission:AutoExecuteAction()
end



function M:Execute(value)
	if not value or value == false then
		Hangup:SetAutoSkill(false);
	 end
	User.MissionState = value 
end

function M:UpdateCurMission(mission)
	if not mission then return end
	if not mission.Temp then return end
	
	if mission.Temp.tarType ~= MTType.Copy then
		self:SetCurExecuteType(mission.Temp.type)
	end
end

function M:GetMissionForID(id)
	if id == nil then
		return self.Main
	end
	if self.Main and self.Main.ID == id then
		return self.Main
	end
	if self.FeederList then
		local data = self:GetMisForID(self.FeederList, id)
		if data then return data end
	end
	if self.TurnList then
		local data = self:GetMisForID(self.TurnList, id)
		if data then return data end
	end
	if self.LivenessList then
		local data = self:GetMisForID(self.LivenessList, id)
		if data then return data end
	end
	if self.FamilyList then
		local data = self:GetMisForID(self.FamilyList, id)
		if data then return data end
	end
	if self.Escort and self.Escort.ID == id then
		return self.Escort
	end
	return nil
end

function M:GetMisForID(dic, id)
	for k,v in pairs(dic) do
		if v.ID == id then
			return v
		end
	end
	return nil
end

function M:GetCurExecuteForType()
	local t = self.CurExecuteType
	local lv = MD.Level
	if (t == nil or t == MissionType.Main)  then		
		if self.Main and self.Main.Temp and self.Main.Temp.lv <= lv then
			self:SetCurExecuteType(self.Main.Temp.type)
			return self.Main
		else
			local count = LuaTool.Length(self.TurnList)
			if count > 0 then
				self:SetCurExecuteType(MissionType.Turn)
			end
			local count1 = LuaTool.Length(self.LivenessList)
			if count1 > 0 then
				self:SetCurExecuteType(MissionType.Liveness)
			end
		end
	end
	if t == MissionType.Feeder  then
		local feeder = self:GetCurExecute(self.FeederList, self.CurExecuteChildType)
		if feeder and feeder.Temp.lv <= lv then
			if self.CurExecuteChildType and self.CurExecuteChildType ~= feeder.Temp.childType then 
				self.CurExecuteChildType = nil
			end
			if feeder.Temp.tarType ~= MTType.Copy then
				self:SetCurExecuteType(feeder.Temp.type)	
			end
			return feeder
		end
	end
	if t == MissionType.Turn then
		local turn = self:GetCurExecute(self.TurnList)
		if turn and turn.Temp.lv <= lv then
			self:SetCurExecuteType(turn.Temp.type)	
			return turn
		end
		local turn1 = self:GetCurExecute(self.LivenessList)
		if turn1 and turn1.Temp.lv <= lv then
			self:SetCurExecuteType(turn1.Temp.type)	
			return turn
		end
	end
	if t == MissionType.Family then
		local family = self:GetCurExecute(self.FamilyList)
		if family and family.Temp.lv <= lv then
			self:SetCurExecuteType(family.Temp.type)	
			return family
		end
	end
	
	if t == MissionType.Escort then
		local escort = self.Escort
		if escort then
			self:SetCurExecuteType(escort.Temp.type)	
			return escort
		end
	end
	self:Execute(false)
	--Hangup:ClearAutoInfo()
	--t = nil
	return nil
end

function M:GetCurExecute(dic, childType)
	if not dic then 
		--iTrace.eLog("hs", "查找的任务列表为nil")
		--HM:ClearAutoInfo()
		return nil
	end
	local data = nil
	for k,v in pairs(dic) do
		if v.Temp and v.Temp.lv <= MD.Level then
			data = v
			if childType then
				if childType == v.Temp.childType then
					data = v
					break
				end
			else
				data = v
				break
			end
		end
	end
	return data
end

function M:UpdateMissionEnd()
	self:UpdateRed()
	self.eEndUpdateMission()
	--[[
	if self.Escort then
		self:AutoExecuteActionOfType(MissionType.Escort)
	end
	]]--
end

function M:UpdateRed()
	self.MainRed = 0
	self.FeederRed = 0
	self.TurnRed = 0
	self.FamilyRed = 0
	self.LivenessRed=0
	local mission = self.Main
	if mission then
		if mission.Status == MStatus.ALLOW_SUBMIT then
			self.MainRed = 1
		end
	end
	self.FeederRed = self:CheckRed(self.FeederList)
	self.TurnRed = self:CheckRed(self.TurnList)
	self.LivenessRed=self:CheckRed(self.LivenessList)
	self.FamilyRed = self:CheckRed(self.FamilyList)
end

function M:CheckRed(dic)
	local num = 0
	if LuaTool.Length(dic) > 0 then
		for k,v in pairs(dic) do
			if v.Status == MStatus.ALLOW_SUBMIT then
				num = num + 1
			end
		end
	end
	return num
end

function M:IsExecuteEscort()
	local info = self.Escort
	if info then
		local status = info.Status
		if status == MStatus.EXECUTE or status == MStatus.ALLOW_SUBMIT then
			UITip.Error("正在护送状态，无法操作！")
			return true
		end
	end
	return false
end

--最后一个转生任务
function M:IsRebirth(mission)
	local value = mission.Temp.childType
	local status = mission.Status == MStatus.ALLOW_SUBMIT
	local next = StrTool.IsNullOrEmpty(mission.Temp.nextId)
	if value and status == true and next == true  then
		return true
	end
	return false
end

--是否改变执行的任务
function M:IsChangeExecuteMiss(miss)
	if miss then
		local temp = miss.Temp
		if temp then
			if self.CurExecuteType ~= nil and temp.type ~= self.CurExecuteType then
				local escort = self.Escort
				if escort ~= nil then
					if temp.type ~= MissionType.Escort then return false end
				end
				if SceneMgr:IsChangeScene(miss.Status ~= MStatus.ALLOW_SUBMIT) == false then return false end
			end
		end
	end
	return true
end

function M:ClickMenuTip(index)
	if index == 0 then
		UICopy:Show(CopyType.Exp)
	elseif index == 1 then
		UIArena.OpenArena(1)
	elseif index == 2 then
		UICopy:Show(CopyType.Equip)
	elseif index == 3 then
		EscortMgr:NavEscort()
	elseif index == 4 then
		LivenessMgr:AutoHangup()
	end
end

-- function M:OpenExpCopy(name)
-- 	local ui = UIMgr.Dic[name]
-- 	if(ui)then
-- 		ui:SetPage(2)
-- 	end
-- end

--
--获取第一次支线任务完成状态
-- value == true : 设置状态
function M:FristFeeder(value)
	local key = string.format( "%s_FristFeeder", MD.UID)
	if value then
		PP.SetInt(key, 1)
		self:SetFristFeederUI(true)
		return 1
	end
	return PP.GetInt(key)
end

function M:SetFristFeederUI(value)
	local ui = UIMgr.Dic[UIMainMenu.Name]
	if ui and ui.LeftView and ui.LeftView.MissionView then
		ui.LeftView.MissionView:SetFristFeeder(value)
	end
end

function M:AutoTalk(mission)
	if not mission then return false end
	if mission.Status ~= MStatus.ALLOW_SUBMIT then return false end
	local temp = mission.Temp
	if not temp then return false end
	 if temp.autoSubmit == 1 then return false end
	 if temp.autoTalk == 0 then return false end
	 if temp.npcSubmit and temp.npcSubmit ~= 0 then
		return true
	 end
	 return false
end

function M:AutoComplete(mission)
	if not mission then return false end
	if mission.Status ~= MStatus.ALLOW_SUBMIT then return false end
	local temp = mission.Temp
	if not temp then return false end
	 if temp.npcSubmit and temp.npcSubmit ~= 0 then return false end
	return true
end

function M:CleanAllMissionData( )
	if self.Main then 
		self.Main:Dispose()
		self.Main = nil
	end
	self:CleanDicMission(self.FeederList)
	self:CleanDicMission(self.TurnList)
	self:CleanDicMission(self.FamilyList)
	if self.Escort then 
		self.Escort:Dispose()
		self.Escort = nil
	end
end

function M:CleanDicMission(dic)
	if not dic then return end
	for k,v in pairs(dic) do
		v:Dispose()
		v = nil
	end
	TableTool.ClearDic(dic)
end

function M:CleanDelRecord()
	local list = self.DelRecord
	if not list then return end
	local len = #list
	while len > 0 do
		local miss = list[len]
		if miss then
			miss = nil
		end
		table.remove(self.DelRecord, len)
		len = #list
	end
end

function M:CleanUpdateRecord()
	local list = self.UpdateRecord
	if not list then return end
	local len = #list
	while len > 0 do
		local miss = list[len]
		if miss then
			miss = nil
		end
		table.remove(self.UpdateRecord, len)
		len = #list
	end
end

function M:CleanAllMission()
	self:CleanAllMissionData()
	self.eCleanAllMission()
	self:CleanDelRecord()
	self:CleanUpdateRecord()
end

function M:Clear()
	--Network:Clear()
	--self:SetFristFeederUI(false)
	self.CurExecuteType = nil				--当前执行的任务类型
	self:CleanAllMissionData()
	Hangup:ClearAutoInfo()
	iTrace.eLog("hs","####################### 重连/切换账号清理数据")
end

function M:Dispose()
	-- body
end

return M
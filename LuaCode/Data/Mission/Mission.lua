--region Mission.lua
--Date
--此文件由[HS]创建生成

Mission = {}
local My = Mission
local Error = iTrace.Error
local Log = iTrace.Log
local MNW = MissionNetwork
local MissTool = MissionTool

function My:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	o.Key = nil
	o.ID = nil
	o.Temp = nil
	o.Status = nil
	o.Succ = nil
	o.Target = nil
	o.NPType = nil
	o.CurExecute = nil
	o.NpcRTemp = nil
	o.NpcSTemp = nil
	return o
end

function My:UpdateTemp(temp)
	self.Temp = temp
	local rid = temp.npcReceive
	local sid = temp.npcSubmit
	if rid then
		self.NpcRTemp = NPCTemp[tostring(rid)]
		if not self.NpcRTemp then
			   Error("hs", string.format("任务寻路未没有在npc配置表中找到配置的NPCID:",rid))
			return
		end
	end
	if sid then
		self.NpcSTemp = NPCTemp[tostring(sid)]
		if not self.NpcSTemp then
			   Error("hs", string.format("任务寻路未没有在npc配置表中找到配置的NPCID:",sid))
			return
		end
	end
end

function My:CreateTarget()
	if not self.Temp then return end
	local list = self.Temp.tarList
	if not list or #list == 0 then
		iTrace.eLog("hs", string.format("%s任务目标为nil",self.ID))
   		--Error("hs", string.format("%s配置数据任务目标为nil, 创建任务目标失败",self.ID))
		return
	end
	self:ClearTarget()
	self.Target = {}
	local len = #list
	for i=1, len do
		local tar = list[i]
		local target = self:GetTarget(self.Temp.tarType)
		if target then
			target:Init(self)
			target:UpdateMTemp(self.Temp)
			target:UpdateTarData(tar.list)
		end
		table.insert(self.Target, target)
	end
	SceneMgr.eChangeEndEvent:Add(self.ChangeEndEvent, self)
end

function My:UpdateTarget(t, v, n, index)
	if not self.Target or not self.Target[index] then return end
	self.Target[index]:ServerData(t, v, n)
end

--获取任务目标
function My:GetTarget(t)
	if t == MTType.KILL then
		return MissionTargetKill.New()
	elseif t == MTType.TALK then
		return MissionTargetTalk.New()
	elseif t == MTType.COLLECTION then
		return MissionTargetCollection.New()
	elseif t == MTType.PATHFINDING then
		return MissionTargetPathfinding.New()
	elseif t == MTType.FlowChart then
		return MissionTargetFlowChart.New()
	elseif t == MTType.KILL_PR then
		return MissionTargetItem.New()
	elseif t == MTType.Copy then
		return MissionTargetCopy.New()
	elseif t == MTType.Fighting then
		return MissionTargetFighting.New()
	elseif t == MTType.Strengthen then
		return MissionTargetStrengthen.New()
	elseif t == MTType.GetExp then
		return MissionTargetGetExp.New()
	elseif t == MTType.System then
		return MissionTargetSystem.New()
	elseif t == MTType.Liveness then
		return MissionTargetLiveness.New()
	elseif t == MTType.Friend then
		return MissionTargetFriend.New()
	elseif t == MTType.WorldBoss then
		return MissionTargetWorldBoss.New()
	elseif t == MTType.Compose then
		return MissionTargetCompose.New()
	elseif t == MTType.OVO then
		return MissionTargetOVO.New()
	elseif t == MTType.AllStrengthen then
		return MissionTargetAllStrengthen.New()
	elseif t == MTType.Mission then
		return MissionTargetMission.New()
	elseif t == MTType.Item then
		return MissionTargetItemII.New()
	elseif t == MTType.Confine then
		return MissionTargetConfine.New()
	elseif t == MTType.FamilyNum then
		return MissionTargetFamilyNum.New()
	elseif t == MTType.FamilyEscort then
		return MissionTargetFamilyEscort.New()
	elseif t == MTType.FamilyRobbery then
		return MissionTargetFamilyRobbery.New()
	elseif t == MTType.CopyFive then
		return MissionTargetCopyFive.New()
 	end
	return nil
end

function My:GetCurTarget()
	if not self.Target then return end
    local len = #self.Target
    if len > 0 then
    	for i=1,len do
    		local target = self.Target[i]
    		if target then
    			if target:IsComplete() == false then
					return target
   				end
   			end
   		end
	end
	return nil
end

function My:GetTitle()
	local mType = MissionType
	local title = self.Temp.name
	--title = string.format("%s{%s}",title,mission.ID)
	local t = self.Temp.type
	if t == mType.Turn or t == mType.Family or t == mType.Escort then
		local succ = self.Succ % self.Temp.ring
		local ring = self.Temp.ring
		if t ~= mType.Escort then 
			if succ == 0 then
				succ = self.Temp.ring
			end
		elseif t == mType.Escort then 
			ring = 3
			succ = ring - EscortMgr.Num
		end
		return string.format("%s (%s/%s)",title, succ, ring)
	end
	return title
end

--获取任务描述
function My:GetTargetDes(c, checklv)
	if checklv == nil then checklv = true end
	if self.Temp and User.MapData.Level < self.Temp.lv then
		if checklv == true then
			return string.format("[ff0000]升到%s才能执行任务[-]", UserMgr:GetChangeLv(self.Temp.lv, false, true))
		else
			return self:GetTargetsDes(c, checklv)
		end
	end
	c = c or "42db70"
	if not self.Temp then return "任务目标" end
    if self.Status == MStatus.EXECUTE then
    	return self:GetTargetsDes(c)
    elseif self.Status == MStatus.NOT_RECEIVE then
        return self:GetNPCName(self.Temp.npcReceive)
	else
		return self:GetSubmitDes()
    end
    return string.format("通过[血魔洞窟]副本升级到%s级才能继续执行任务", self.Temp.lv);
end

function My:GetTargetsDes(c, checklv)
	if checklv == nil then checklv = true end
	if User.MapData.Level < self.Temp.lv then
		if checklv == true then
			return string.format("[ff0000]%s级才能继续执行任务[-]", self.Temp.lv)
		end
	end
    local des = self.Temp.customDes
    if StrTool.IsNullOrEmpty(des) == false then
       	return des
    end
	if self.Temp.lv <= User.MapData.Level or checklv == false then
		if self.Target then
     		local len = #self.Target
       		if len > 0 then
        		local des = ""
        		for i=1, len do
        	   		local target = self.Target[i]
        	  		des = string.format(target:TargetDes(), c)
        	   		if i < len then des = string.format("%s\n", des) end
        	   	end
        	   	return des
			end
		end
    end
    return self.Temp.name
end

function My:GetSubmitDes()
	local temp = self.Temp
	if not temp then return '' end
	if temp.tarType == MTType.Copy and not temp.childType then			
		return temp.customDes
	end
	if temp.customSubmitDes then
		return temp.customSubmitDes
	end
	return self:GetNPCName(temp.npcSubmit)
end

function My:GetNPCName(id)
    local npc = NPCTemp[tostring(id)]
    local des = ""
    if npc then 
        des = string.format("[c8d0e3]和[42db70]%s[-]对话", npc.name)
    end
    return des
end

function My:GetTalk()
	local talk = "任务对话"
	local temp = self.Temp
	if not temp then return "任务对话" end
    if self.Status == MStatus.EXECUTE then
    	talk = temp.talk
    elseif self.Status == MStatus.NOT_RECEIVE then
    	talk = temp.talkReceive
    else
    	talk = temp.talkSubmit
	end
    return talk
end 

--执行任务
function My:AutoExecuteAction(execute, fly, changeExecute)	
	if not execute then execute = MExecute.None end
	if changeExecute == nil then changeExecute = true end
	self.IsAutoExcute = false
	--刚进去不能执行任务
	if self:NotAllowExecute() then 
		local mapid = User.SceneId
		local scene = SceneTemp[tostring(mapid)]
		if scene then
			if scene.mapchildtype then
				UITip.Error("请先完成主线任务再执行")			
				return true
			end
		end
		--MissionMgr:Execute(false)
		--MissionMgr.CurExecuteType = nil
		Hangup:ClearAutoInfo()
		return 
	end
    if execute == MExecute.ClickNpc then
    	self.IsAutoExcute = true
	end
	if changeExecute == true then
		MissionMgr:Execute(true)
	end
	local mtype = self.Temp.type
	if mtype == MissionType.Turn or mtype == MissionType.Family then
		if VIPMgr.GetVIPLv() > 0 then
			fly = true
		end

		-- if VIPMgr.vipLv > 0 and VIPMgr.useFlyShoe == true then
		-- 	fly = true;
		-- elseif VIPMgr.vipLv > 0 and VIPMgr.useFlyShoe == false then
		-- 	UIMgr.Open(VipShoeMsg.Name, function()
		-- 		VipShoeMsg:SetExcuteFun(function()
		-- 			fly = true;
		-- 			self:MsgCallBack(execute, fly);
		-- 		end);
		-- 	end);

		-- 	return;
		-- end
	end

	self:MsgCallBack(execute, fly);

	-- if self.Status == MStatus.NOT_RECEIVE then
	-- 	if self.Temp.autoReceive == 1 then
    --         MNW:ReqAcceptMission(self.ID)
    --     else
    --     	self:AutoRAction(fly, execute)
	-- 	end
	-- elseif self.Status == MStatus.EXECUTE then
	-- 	self:AutoExeTAction(execute, false,  fly)
	-- elseif self.Status == MStatus.ALLOW_SUBMIT then
	-- 	if self.Temp.childType then
	-- 		UIMgr.Open(UIRebirth.Name)
	-- 		return
	-- 	end
	-- 	if self.Temp.autoSubmit == 1 then
    --         MNW:ReqCompleteMission(self.ID)
	-- 	else
	-- 		self:AutoSAction(fly, execute)
	-- 	end
	-- end
end

--// 回调回调
function My:MsgCallBack(execute, fly)
	HgPoint.SetHgupPoint(false);--每次执行任务都清除挂机点挂机
	if self.Status == MStatus.NOT_RECEIVE then
		if self.Temp.autoReceive == 1 then
            MNW:ReqAcceptMission(self.ID)
        else
        	self:AutoRAction(fly, execute)
		end
	elseif self.Status == MStatus.EXECUTE then
		self:AutoExeTAction(execute, false,  fly)
	elseif self.Status == MStatus.ALLOW_SUBMIT then
		if self.Temp.childType then
			UIMgr.Open(UIRebirth.Name)
			return
		end
		if self.Temp.autoSubmit == 1 then
            MNW:ReqCompleteMission(self.ID)
		else
			self:AutoSAction(fly, execute)
		end
	end
end
 
--执行任务领取
function My:AutoRAction(fly, execute)
	if self.Temp and self.Temp.npcReceive and self.Temp.npcReceive ~= 0 then
		local npcTemp = self.NpcRTemp 
		if npcTemp then
			if MissTool:IsEqualScreen(npcTemp) == true then					
				local dis = MissTool:Distance(MissTool:TargetPos(npcTemp.pos))
				if dis < MissTool.Dis then 
					self:NPCNPComplete() 
					return
				end
			end
		end
		self:NPCPathfinding(self.Temp.npcReceive, fly, self.Temp.type, execute)
	end
end

--执行人提交
function My:AutoSAction(fly, execute)
	if self.Temp then
		if self.Temp.npcSubmit and self.Temp.npcSubmit ~= 0 then
			if self.Temp.autoTalk == 0 then
				local npcTemp = self.NpcSTemp 
				if npcTemp then
					if MissTool:IsEqualScreen(npcTemp) == true then					
						local dis = MissTool:Distance(MissTool:TargetPos(npcTemp.pos))
						if dis < MissTool.Dis then 
							self:NPCNPComplete() 
							return
						end
					end
				end
				self:NPCPathfinding(self.Temp.npcSubmit, fly, self.Temp.type, execute)
			else
				self:ShowNPCPanel(self.Temp.npcSubmit)
			end
		else
            MNW:ReqCompleteMission(self.ID)
		end
	end
end

--执行任务目标
function My:AutoExeTAction(execute, change, fly)
	if not self.Target then return end
    local len = #self.Target
    if len > 0 then
    	for i=1,len do
    		local target = self.Target[i]
    		if target then
    			if target:IsComplete() == false then
    				if execute == MExecute.None and self.CurExecute ~= nil and self.CurExecute == target then
						if self.Temp.tarType == MTType.KILL or self.Temp.tarType == MTType.KILL_PR then	
								self:AutoExeTSelectAction(self.CurExecute, change, fly, execute)
    						return
    					end
					end
					self:AutoExeTSelectAction(target, change, fly, execute)
    				self.CurExecute = target
					return
   				end
   			end
   		end
   	end
end

function My:AutoExeTSelectAction(target, change, fly, execute)
	if not change then
		target:AutoExecuteAction(fly, execute)
	else
		target:ChangeEndEvent()
	end
end

--领取提交寻路
function My:NPCPathfinding(npcid, fly, type, execute)
	NPCMgr.instance:CheckLoad(npcid)
	MissionNavPath.Callback = function()
	 self:NPCNPComplete() 
	end
	MissionNavPath:NPCPathfinding(self.ID, npcid, 1.3, fly, self.Temp.type, execute)
end

--领取提交寻路完成
function My:NPCNPComplete()
	MissionNavPath.Callback = nil
	local npcid = nil
    if self.Status == MStatus.NOT_RECEIVE then
       	npcid = self.Temp.npcReceive
    elseif self.Status == MStatus.ALLOW_SUBMIT then
       	npcid = self.Temp.npcSubmit
	end
	self:ShowNPCPanel(npcid)
end

function My:ScreenNPComplete()
	self:AutoExecuteAction()
end

function My:ShowNPCPanel(npcid)
	if npcid then
		if self.Last and self.Last == self.Status then return end
		self.Last = self.Status
		if UIMgr.IsOpenUI() == true and self.ID ~= 900000 then
			self:MNWAction()
			return
		end 
		UIMgr.Open(UINPCDialog.Name, function()
			 local ui = UIMgr.Dic[UINPCDialog.Name]
			 if ui then
				 ui:UpdateNpcClickMissionData(npcid, self.ID)
			 end
		end)
	end
end

function My:ChangeEndEvent(isLoad)
	--iTrace.eWarning("hs", "任务id:"..self.ID)
	--if User.SceneId ~= self.Temp.screen then return end
	if self.Status == MStatus.COMPLETE or self.Status == MStatus.ALLOW_SUBMIT or self.Status == MStatus.Fail or self.Status == MStatus.None then 
		return 
	end
	self:AutoExeTAction(MExecute.None, true)
end

--NPC面板关闭
function My:MNWAction()
	if self.Status == MStatus.NOT_RECEIVE then
		MNW:ReqAcceptMission(self.ID)
	elseif self.Status == MStatus.ALLOW_SUBMIT then 
		MNW:ReqCompleteMission(self.ID)
	end
end

--是否是关联npc
function My:IsRelatedNpc(npcid)
	local value = false
	if self.Temp then
		if self.Temp.npcReceive == npcid and self.Status == MStatus.NOT_RECEIVE then
			value = true
		end
		if self.Temp.npcSubmit == npcid and self.Status == MStatus.ALLOW_SUBMIT then
			value = true
		end
		if self.Temp.tarType == MTType.TALK and self.Status == MStatus.EXECUTE then
			if self.Target then
   				local len = #self.Target 
    			if len > 0 then
    				for i=1,len do
    					local target = self.Target[i]
    					if target then
    						if target.TID == npcid then
    							value = true
    						end
    					end
    				end
    			end
			end
		end
	end
	--if value then
	--	NPCMgr.instance:NPCRelatedMission(self.ID, self.Status)
	--end
	return value
end

--任务完成改变场景
function My:ChangeScene()
end

function My:ClearTarget()
	if self.Target then
		local len = #self.Target
		while #self.Target > 0 do
			len = #self.Target
			self.Target[len]:Dispose()
			self.Target[len] = nil
			table.remove(self.Target, len)
		end
	end
end

function My:UpdateStatus(value)
	self.Status = value
	local temp = self.Temp
	if not temp then return end
	if temp and temp.type == MissionMgr.CurExecuteType then
		MissionMgr:Execute(false)
	end
	if temp.type ~= MTType.TALK then return end
	if MissionMgr.CurExecuteType == self.Temp.type and value == MStatus.ALLOW_SUBMIT then
		self:AutoExecuteAction()
	end
	--Hangup:SetAutoSkill(false);
end

function My:CheckLevel(tip)
	local temp = self.Temp
	if not temp then
		return true
	end
	local user = User.MapData
	if temp.lv > user.Level then 
		if tip then
			UITip.Error(string.format("升到%s级才能执行任务",temp.lv))
		end
		return true 
	end
	return false
end

--是否满足可以执行任务的先决条件
function My:NotAllowExecute(showlv)	
	if showlv == nil then showlv = true end
	if User.IsInitLoadScene == true then 
		iTrace.eLog("hs", "未第一次登入场景")
		return true 
	end
	if GameSceneManager.SceneLoadStateToInt == 0 then
		iTrace.eLog("hs", "场景加载状态")
		 return true
	end
	if User.IsJumpling == true then 
		iTrace.eLog("hs", "跳跃中不能执行")
		return true
	end
	if Mgr.IsLoadReady == true then return end
	local user = User.MapData
	if not user then 
		iTrace.eLog("hs", "获取角色数据失败")
		return true 
	end
	local temp = self.Temp
	if not temp then 
		iTrace.eLog("hs", "获取任务数据失败")
		return true 
	end
	if self:CheckLevel(showlv) == true then
		return true
	end
	--[[
	if self.Status == MStatus.COMPLETE then 
		iTrace.eLog("hs", string.format("任务ID:%s完成状态不能执行",self.ID))
		return  true
	end
	]]--
	local mapid = User.SceneId
	local scene = SceneTemp[tostring(mapid)]
	if scene then
		if scene.mapchildtype then
			if MissTool:IsAutoSubmit(self) == false then
				UITip.Error("请先完成主线任务再执行")			
			end
			return true
		end
		if scene.maptype == SceneType.Copy then
			local copy = CopyTemp[tostring(mapid)]
			if copy then
				if copy.type ~= CopyType.Mission then
					if copy.id ~= temp.screen then
						UITip.Error("副本场景不能执行任务")
						return true
					end
				else
					if temp.type ~= MissionType.Main then
						if MissTool:IsAutoSubmit(self) == false  then
							UITip.Error("主线任务场景不能执行其他任务")
							return true
						end
					end
				end
			end
		end
	end
	if temp.type ~= MissionType.Main then
		if MissTool:IsAutoSubmit(self) == false then
			local mission = MissionMgr.Main
			if mission then
				local mTemp = mission.Temp
				if mission:IsFlowChart() == true then
					UITip.Error("主线任务场景不能执行其他任务")
					return true
				end
				--[[
				if User.MapData.Level >= mTemp.lv then
					if mTemp.tarType == MTType.FlowChart or mTemp.tree then
						UITip.Error("主线任务场景不能执行其他任务")
						return true
					end
				end
				]]--
			end
		end
	end
	if MissionMgr.Escort ~= nil and self.ID ~= MissionMgr.Escort.ID then
		if MissTool:IsAutoSubmit(self) == false then
			UITip.Error("请先完成护送任务")
			return true
		end
	end
	return false
end

function My:IsFly()
	if User.MapData.Level < MissionMgr.OpenFlyLv then return false end
	local temp = self.Temp
	if not temp then return false end
	if temp.notFly and temp.notFly == 1 then return false end
	if temp.tree ~= nil and temp.Status ~= MStatus.ALLOW_SUBMIT then return false end
	if temp.type == MissionType.Escort then return false end
	local tarType = temp.tarType
	if tarType ~= MTType.KILL and tarType ~= MTType.TALK and tarType ~= MTType.COLLECTION and tarType ~= MTType.PATHFINDING and tarType ~= MTType.KILL_PR and tarType ~= MTType.Confine  then
		return false
	end
	return true
end

function My:IsFlowChart()
	if User.MapData.Level >= self.Temp.lv then
		local temp = self.Temp
		if temp then
			if temp.tree ~= nil or temp.tarType == MTType.FlowChart then
				if temp.tarType == MTType.TALK then
					local tars = self.Target
					local len = #tars
					local num = 0
					for i,v in ipairs(tars) do
						if v.IsEndFlowChart == true then
							num = num + 1
						end
					end
					if num >= len then return false end
				end
				return true
			end
		end
	end
	return false
end

function My:Dispose()
	if self.Temp and self.Temp.type == MissionType.Feeder and self.Temp.type == MissionMgr.CurExecuteType then 
		MissionMgr.CurExecuteType = nil
		Hangup:SetAutoHangup(false);
	end
	MissionMgr:Execute(false)
	SceneMgr.eChangeEndEvent:Remove(self.ChangeEndEvent, self)
	--Hangup:SetAutoSkill(false);
	--hmgr.IsAutoHangup = true
	MissionNavPath.Callback = nil
	MissionNavPath:Dispose()
	MissionFlowChart.EndSceneID = nil
	--MissionFlowChart:Dispose()
	--local E = EventMgr.Remove
	--E("NavPathComplete",self.OnNPComplete)
	--self.OnNPComplete = nil
	self:ClearTarget()
	self.CurExecute = nil
	self.Target = nil
	self.Key = nil
	self.ID = nil
	self.Temp = nil
	self.Status = nil
	self.Succ = nil
	self.NPType = nil
	self.Last = nil
	self.IsAutoExcute = nil
	
	self.NpcRTemp = nil
	self.NpcSTemp = nil
end


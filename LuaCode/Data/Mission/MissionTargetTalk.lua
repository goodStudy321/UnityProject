--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetTalk = baseclass(MissionTarget)
local M = MissionTargetTalk
local Error = iTrace.Error

local MNW = MissionNetwork
local MissTool = MissionTool

--构造函数
function M:Ctor()
	self.NTemp = nil			--npc配置表
	--self.NPCPos = nil
	self.OnIsShowUIDialog = nil
end

--更新任务配置表
function M:UpdateMTemp(temp)
	self:Super("UpdateMTemp", temp)
	self.IsEndFlowChart = self.Tree == nil
end

--更新目标数据
function M:UpdateTarData(tar)
	self.TID = tar[1] 			--NPCID
	self.SID = tar[2]
	self.LNum = 1
	self:Super("UpdateTarData", tar)
end

function M:UpdateTabelData()
	self.NTemp = NPCTemp[tostring(self.TID)]
	if not self.NTemp then 
   		Error("hs", string.format("NPCID：%s 不存在！！", self.TID))
   		return
   	end
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	self.Execute = execute
	if self.IsEndFlowChart == false then
		self:UpdateFlowChart()
		return
	end
	if not self.NTemp then return end
	local pos = MissTool:TargetPos(self.NTemp.pos)
	local dis = MissTool:Distance(pos)
	if dis < MissTool.Dis then 
    	self:CustomNPComplete()
    	return
	end
	--iTrace.sLog("hs","----------------> ".. tostring(uPos).."/"..tostring(self.NPCPos))
	self:NavPath(pos, self.SID, 1.3, 0, fly)
	MissionMgr:Execute(true)
end

--自定义寻路完成
function M:CustomNPComplete()
	if not self.TID then return end
	if not self.TID then
		iTrace.eError("hs", "self.TID is nil")
	end
	NPCMgr.instance:SetClickNPC(self.TID, false)
	local temp = self.Temp
	if temp.type ~= MissionType.Escort  then
		if temp and StrTool.IsNullOrEmpty(temp.talk) then
			MNW:ReqTriggerMission(temp.tarType, self.TID)
			if self.Miss then self.Miss:UpdateStatus(MStatus.ALLOW_SUBMIT) end
			return
		end
	end
	if UIMgr.IsOpenUI() == true then
		MNW:ReqTriggerMission(self.Temp.tarType, self.TID)
		if self.Miss then self.Miss:UpdateStatus(MStatus.ALLOW_SUBMIT) end
		return
	end 
	local ui = UIMgr.Get(UINPCDialog.Name)
	if ui == nil or ui.active ~= 1 then
		UIMgr.Open(UINPCDialog.Name, self.OpenNpcDialogCb, self)
	else
		ui:UpdateNpcClickMissionData(self.NTemp.id, self.Temp.id)
	end
end

function M:OpenNpcDialogCb(name)
	MissionMgr:Execute(true)
	local ui = UIMgr.Get(name)
 	if ui then
 		ui:UpdateNpcClickMissionData(self.NTemp.id, self.Temp.id)
 	end
end

function M:IsShowUIDialog(value)
	if value == false then
	 	EventMgr.Remove("IsShowUIDialog",self.OnIsShowUIDialog)
		 MNW:ReqTriggerMission(self.Temp.tarType, self.TID)
	end
end

function M:ChangeEndEvent(isLoad)
	self:UpdateFlowChart()
end

--任务描述
function M:TargetDes()
	local des = ""
	local tarName = "NPC名字"
	if self.NTemp then tarName = self.NTemp.name end
	des = string.format("[42db70]与[%s]%s[-]交谈", "%s", tarName) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	local E = EventMgr.Remove
	E("IsShowUIDialog",self.OnIsShowUIDialog)
	self.OnIsShowUIDialog  = nil
	self.NTemp = nil			
	--self.NPCPos = nil		
	self:Super("Dispose", isDestory)
end
--endregion

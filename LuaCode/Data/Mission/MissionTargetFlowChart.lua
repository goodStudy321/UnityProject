--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetFlowChart = baseclass(MissionTarget)
local M = MissionTargetFlowChart
local Error = iTrace.Error
local MNW = MissionNetwork
--构造函数
function M:Ctor()
    self.IsStartExecute = nil
end

function M:Init(i)
	self:Super("Init", i)
    self.IsStartExecute = false
    self.IsEnd = false
end

--更新目标数据
function M:UpdateTarData(tar)
	self.TID = tar[1]
	if not self.Tree then self.Tree = {} end
	self.Tree.id = tar[1]
	self.Tree.screen = tar[2]
	self.SID = tar[2]
	local x = tar[4]
	local z = tar[5]
	if x and z then
		self.NavPos = Vector3.New(x / 100, 0, z /100)
	else 
		self.NavPos = nil
	end
	self.STemp = SceneTemp[tostring(self.Tree.screen)]
	if not self.STemp then 
   		 iTrace.Error(string.format("场景ID：%s 不存在！！", self.Tree.screen))
   	end
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	self.Execute = execute
	local curSID = User.SceneId
	if curSID ~= self.Temp.screen and self.Tree and curSID ~= self.Tree.screen then 
		return
	end
	if self:IsFlowChartScene() then
		self:Super("AutoExecuteAction", execute)
	else
		if self.IsEndFlowChart == true then return end
		local name = FlowChartMgr.CurName
		if StrTool.IsNullOrEmpty(name) == false and name == tostring(self.Tree.id) then 
			if self.NavPos then
				self:NavPath(self.NavPos, self.STemp.map , 0, self.TID, fly)
			   else
				Hangup:SetAutoSkill(true);
			end
			return 
		end
	end

end

function M:IsFlowChartScene()
	if self.Temp then
	 	local fcid = nil
	 	if self.Tree then
	 		fcid = self.Tree.screen
			 if fcid and fcid ~= User.SceneId then
				 return true
			 end
	 	end 
	end
	return false
end

--流程树完成
function M:EndCallback(name, win)
	iTrace.eLog("hs", string.format( "结束流程树:", name))
	if not self.Tree or not self.Tree.id then return end
	if User.SceneId ~= self.Tree.screen then return end
	self.IsEndFlowChart = true
	local n = tostring(self.Tree.id)
	if name == n then 
		MissionFlowChart.EndCallback:Remove(self.EndCallback, self) 
		--self:JumpScene()
		local temp = self.Temp
		if temp then
			MissionFlowChart.OldSceneID = nil
			self.IsBlack = true
			if temp.flowJS then 
				SceneMgr.eChangeEndEvent:Add(self.OnFlowScene, self)
				--EventMgr.Add("OnChangeScene", EventHandler(self.OnFlowScene, self))
				Hangup:ClearAutoInfo();
				--// LY add begin
				UIMgr.Open("UILoading");
				--// LY add end
				--iTrace.eWarning("hs","流程树完成跳场景"..temp.screen)
				SceneMgr:ReqPreEnter(temp.screen, false)
				return
			end
			--iTrace.eWarning("hs","流程树完成跳场景"..temp.screen)
			SceneMgr:ReqPreEnter(temp.screen, false)
			MNW:ReqTriggerMission(temp.tarType, self.TID)
		end
    end
    self.IsStartExecute = false
	MissionMgr:Execute(false)
end

function M:OnFlowScene()
	SceneMgr.eChangeEndEvent:Remove(self.OnFlowScene, self)
	--EventMgr.Remove("OnChangeScene", EventHandler(self.JumpScene, self))
	local temp = self.Temp
	if not temp then return end
	MNW:ReqTriggerMission(temp.tarType, self.TID)
	--iTrace.eWarning("hs","流程树场景"..temp.flowJS)
	--SceneMgr:ReqPreEnter(temp.flowJS,false)
end

function M:JumpScene()
	if not self.Temp then return end
	local id = self.Temp.flowJS
	if not id then return end
	MissionFlowChart.OldSceneID = nil
	local scene = SceneTemp[tostring(self.Temp.flowJS)]
	if not scene then return end
	if SceneMgr.IsSpecial() == true then return end
	--iTrace.eWarning("hs","跳场景"..id)
	SceneMgr:ReqPreEnter(id, true)
end

function M:CustomNPComplete()
	Hangup:SetAutoSkill(true);
end

function M:ChangeEndEvent(isLoad)
	if self.IsBlack ~= nil and self.IsBlack == nil then
		self.IsBlack = nil
		Hangup:SetAutoSkill(false);
		Hangup:SetAutoHangup(true);
		self:JumpScene()
		return
	end
	self:UpdateFlowChart()
end

--释放或销毁
function M:Dispose(isDestory)	
	EventMgr.Remove("OnChangeScene", EventHandler(self.JumpScene, self))
	Hangup:SetAutoSkill(false);
	Hangup:SetAutoHangup(true);
	self.Tree = nil
    self.IsExecute = nil
    self.IsStartExecute = nil
	self:Super("Dispose", isDestory)
end
--endregion

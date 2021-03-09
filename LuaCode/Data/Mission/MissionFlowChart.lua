--region MissionFlowChart.lua
--Date
--此文件由[HS]创建生成
MissionFlowChart = {}
local MM = MissionFlowChart
MM.Tree = nil
MM.StartCallback = Event()
MM.EndCallback = Event()
MM.OldSceneID = nil
MM.EndSceneID = nil

--检测是否有任务流程树
function MM:Check(tree)
	self.Tree = tree
	if not self.Tree then
		return false
	end
	if User.IsInitLoadScene then return false end
	if tree and tree.screen ~= User.SceneId then
		local copy = CopyTemp[tostring(User.SceneId)]
		if copy and copy.type == CopyType.Mission then return true end
		if not self.OldSceneID or self.OldSceneID ~= User.SceneId then
			self.OldSceneID = User.SceneId 
		end
		if Mgr.IsLoadReady == false and User.IsMissionFlowChart == false then
			User.IsMissionFlowChart = true
			User.MissTargetID = 0;
			--iTrace.eWarning("hs", string.format("请求进入流程树：%s", tree.screen))
			SceneMgr:ReqPreEnter(tree.screen, true)
		end
	else
		self:ChangeEndEvent()
	end
	return true
end

--跳转场景
function MM:ChangeEndEvent(isLoad)
	User.IsMissionFlowChart = false
	local s = User.SceneId
	if self.Tree  and self.Tree.screen == User.SceneId then
		local copyTemp = CopyTemp[tostring(User.SceneId)]
		if copyTemp then
			if copyTemp.type == CopyType.Mission or copyTemp.type == CopyType.Light then

				GameSceneManager:EnterMissionClearScene()
				self.OnFlowChartStart = EventHandler(self.FlowChartStart, self)
    			EventMgr.Add("FlowChartStart", self.OnFlowChartStart)
				self.OnFlowChartEnd = EventHandler(self.FlowChartEnd, self)
				EventMgr.Add("FlowChartEnd", self.OnFlowChartEnd)
				iTrace.eLog("hs", string.format( "启动流程树：%s, 流程树场景id：%s,当前场景id：%s",self.Tree.id, self.Tree.screen, User.SceneId))
            	FlowChartMgr.Start(tostring(self.Tree.id))
            end
		end
	end
end

function MM:FlowChartStart()
	EventMgr.Remove("FlowChartStart", self.OnFlowChartStart)
	iTrace.eLog("hs", "启动流程树")
	if self.StartCallback then
		self.StartCallback()
	end
end

function MM:FlowChartEnd(name, win, closeScene)
	iTrace.eLog("hs", string.format("结束流程树:%s", name))
	local endTree = tonumber(name)
	if not self.Tree or endTree ~= self.Tree.id then return end
	if User.SceneId ~= self.Tree.screen then return end
    EventMgr.Remove("FlowChartEnd", self.OnFlowChartEnd)
	if self.EndCallback then
		self.EndCallback(name, win)
	end
	if self.OldSceneID then
		self.EndSceneID = User.SceneId
		--iTrace.eWarning("hs","流程树场景返回到"..self.OldSceneID)
		SceneMgr:ReqPreEnter(self.OldSceneID, true)
        self.OldSceneID = nil
	end
end

function MM:Dispose()
	self.Tree = nil
	self.StartCallback:Clear()
	self.EndCallback:Clear()
	self.OldSceneID = nil
	self.EndSceneID = nil
end
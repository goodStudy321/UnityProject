CopyTowerMgr = { Name = "CopyMove"}
local M = CopyTowerMgr

local TreeName = "tongtianta"

function M:StartFlowChart()
    if StrTool.IsNullOrEmpty(TreeName) == true then
        self:FlowChartEndCB(TreeName, nil, nil)
        return
	end
	
	UIMgr.Close(UICopyInfoPub.Name)
	UIMgr.Close(UICopyInfoTimer.Name)

	CutscenePlayMgr.instance:ClearPlayedCutsNames()

    self.OnFlowChartStart = EventHandler(self.FlowChartStartCB, self)
    EventMgr.Add("FlowChartStart", self.OnFlowChartStart)
    self.OnFlowChartEnd = EventHandler(self.FlowChartEndCB, self)
    EventMgr.Add("FlowChartEnd", self.OnFlowChartEnd)
    iTrace.eLog("hs", string.format( "启动流程树：%s, 当前场景id：%s",TreeName,  User.SceneId))
	FlowChartMgr.Start(TreeName)
	
end

function M:FlowChartStartCB()
	EventMgr.Remove("FlowChartStart", self.OnFlowChartStart)
	iTrace.eLog("hs", "TXTower启动流程树")
end

function M:FlowChartEndCB(name, win, closeScene)
	iTrace.eLog("hs", string.format("TXTower结束流程树:%s", name))
	if name ~= TreeName then return end
    EventMgr.Remove("FlowChartEnd", self.OnFlowChartEnd)
    
	CopyMgr:ClearCopyInfo()
	local screenid = self:GetIndex()
	if screenid then
		if screenid == 0 then return end
		if screenid ~= User.SceneId then
			SceneMgr.eChangeEndEvent:Add(self.ChangeScene, self)
			SceneMgr:ReqPreEnter(screenid, false)
        end
    end
    CopyMgr:ShowEffect()
end

function M:ChangeScene()
	SceneMgr.eChangeEndEvent:Remove(self.ChangeScene, self)
	Hangup:SetSituFight(true)
end

function M:GetIndex()
	local key = tostring(CopyType.TXTower)
	local data = CopyMgr.Copy[key]
	local indexOf = data.IndexOf
	local index = CopyMgr.TXTowerLimitIndex
	local curId = 0
	if index > 0 then
		curId = indexOf[index + 1]
	else
		curId = indexOf[1]
	end 
	return curId
end

function M:Clear()
	EventMgr.Remove("FlowChartStart", self.OnFlowChartStart)
    EventMgr.Remove("FlowChartEnd", self.OnFlowChartEnd)
end

return M
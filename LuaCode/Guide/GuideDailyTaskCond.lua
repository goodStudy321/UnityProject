--=========================================================================
-- 3分钟不动引导日常任务引导
--=========================================================================

GuideDailyTaskCond = GuideCond:New{ Name = "GuideDailyTaskCond" }

local My = GuideDailyTaskCond


function My:Init()
	UserMgr.eLvEvent:Add(self.AutoExe, self)
	LivenessMgr.eUpCount:Add(self.AutoExe, self)
	GuideTimeMgr.eUpdateAction:Add(self.TimeExe,self)
	self.NoScIdTab = {}
	self:NoShowScene()
end

function My:NoShowScene()
	-- local scIdTab = {30019,90021,90022,90023,90024,90025,90026}
	local tab = {}
	local scIdTab = GlobalTemp["202"].Value2
	for i = 1,#scIdTab do
		local scId = scIdTab[i]
		tab[scId] = scId
	end
	self.NoScIdTab = tab
end

function My:CheckExe()
	local lv = User.MapData.Level
	if lv < 160 then return false end
	local cfg = LivenessAwardCfg
    local total = cfg[#cfg].id
    local liveness = LivenessInfo.liveness
    local val = (liveness >= total) and total or liveness
	if val >= 200 then return false end
	return true
end

function My:AutoExe()
	local isExe = self:CheckExe()
	if isExe then
		GuideTimeMgr:ResetUpdate()
	end
end

function My:TimeExe()
	local isExe = self:CheckExe()
	local curSceneId = User.SceneId
	-- local scCfg = SceneTemp[tostring(curSceneId)]
	-- local scType = scCfg.maptype
	-- local scIdTab = {30019,90021,90022,90023,90024,90025,90026}
	if self.NoScIdTab[curSceneId] then
		return
	end
	if isExe then
		self:Start()
	end
end

function My:Start()
	for i,v in ipairs(GuideCfg) do
		if v.ty == 8 then
			self.success(self,v)
			break
		end
	end
end

function My:Dispose()
	TableTool.ClearDic(self.NoScIdTab)
	UserMgr.eLvEvent:Remove(self.AutoExe, self)
	LivenessMgr.eUpCount:Remove(self.AutoExe, self)
	GuideTimeMgr.eUpdateAction:Remove(self.TimeExe,self)
end


return My
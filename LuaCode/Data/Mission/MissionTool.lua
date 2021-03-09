--region Mission.lua
--Cell基类 只有Icon
--此文件由[HS]创建生成

MissionTool = {Name = "MissionTool"}
local M = MissionTool

M.Dis = 3.0

--npc是否在同场景或者距离内
function M:IsEqualScreen(npc)
	if not npc then return false end
	return npc.sceen == User.SceneId
end

--判定目标距离
function M:Distance(pos)
	return Vector3.Distance(UserMgr:GetPos(), pos)
end

--获取目标相对位置
function M:TargetPos(pos)
	return Vector3.New(pos.x * 0.01, 0, pos.z * 0.01)
end

--是否自动完成的任务
function M:IsAutoSubmit(mission)
	if mission and mission.Status == MStatus.ALLOW_SUBMIT then
		local temp = mission
		if temp then
			if not temp.npcSubmit or temp.autoSubmit == 1 then
				return true
			end
		end
	end
	return false
end

--是否是主线场景或主线流程树场景
function M:IsMainMissScene(miss)
	local temp = miss.Temp
	if not temp then return true end
	if temp.type ~= MissionType.Main then return true end
	local sceneid = User.SceneId
	if temp.screen ~= sceneid then	--不在主线场景
		local tree = temp.tree
		if tree and tree.screen == sceneid then 	--不在任务流程树
			return true
		end
		if temp.tarType == MTType.FlowChart then	--不在任务目标流程树
			local tar = temp.tarList[1].list
			if tar and tar[2] == sceneid then
				return true
			end
		end
		return false
	end
	return true
end

return M
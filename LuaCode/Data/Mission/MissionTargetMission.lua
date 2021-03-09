--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetMission = baseclass(MissionTarget)
local M = MissionTargetMission
local Error = iTrace.Error

--构造函数
function M:Ctor()
end

--更新任务配置表
function M:UpdateMTemp(temp)
	self:Super("UpdateMTemp", temp)
end

--更新目标数据
function M:UpdateTarData(tar)
	self.TID = tar[1]
	self.LNum = tar[2]
	self:Super("UpdateTarData", tar)
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	--UIArena.OpenArena(1)
	--MissionMgr:AutoExecuteActionOfType(self.TID)
	UIMgr.Open(UILiveness.Name)
end

--任务描述
function M:TargetDes()
	local des = ""
	local name = self:GetMissionTypeName(self.TID)
	local num = self.Num or 0
	des = string.format("完成[%s]%s[-]%s次(%s/%s)", "%s", name, self.LNum, num, self.LNum) 
	return des
end


function M:GetMissionTypeName(type)
	if type == MissionType.Main then
		return "主线任务"
	elseif type == MissionType.Feeder then
		return "支线任务"
	elseif type == MissionType.Turn	then
		return	"日常任务"
	elseif type == MissionType.Family then
		return "道庭任务"
	elseif type == MissionType.Escort then
		return "护送任务"
	end
	return "任务"
end

--释放或销毁
function M:Dispose(isDestory)
	self:Super("Dispose", isDestory)
end
--endregion

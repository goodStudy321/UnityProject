--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetSystem = baseclass(MissionTarget)
local M = MissionTargetSystem
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
	self.TID = tar[1] 			--目标
	self.SID = tar[2]		--系统类型
	self.LNum = tar[3]
	self:Super("UpdateTarData", tar)
end

function M:UpdateTabelData()

end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
end

--任务描述
function M:TargetDes()
	local des = ""
	--[[
	local tarName = "NPC名字"
	if self.NTemp then tarName = self.NTemp.name end
	des = string.format("与[%s]%s[-]交谈", "%s", tarName) 
	]]--
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	self:Super("Dispose", isDestory)
end
--endregion

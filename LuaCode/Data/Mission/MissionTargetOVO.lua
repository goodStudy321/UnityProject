--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetOVO = baseclass(MissionTarget)
local M = MissionTargetOVO
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
	self.LNum = tar[1]
	self:Super("UpdateTarData", tar)
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	UIArena.OpenArena(1)
end

--任务描述
function M:TargetDes()
	local des = ""
	local name = "竞技殿"
	if not self.Num then self.Num = 0 end
	des = string.format("挑战[%s]%s[-](%s/%s)", "%s", name, self.Num, self.LNum) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	self:Super("Dispose", isDestory)
end
--endregion

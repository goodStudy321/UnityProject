--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetConfine = baseclass(MissionTarget)
local M = MissionTargetConfine
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
	self.TID = tar[1] 			--NPCID
	self.LNum = 1
	self:Super("UpdateTarData", tar)
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	if execute == MExecute.ClickItem then
		UIRobbery:OpenRobbery(1)
	else
		Hangup:ClearAutoInfo()
	end
end


--任务描述
function M:TargetDes()
	local des = ""
	local name = "境界"
	local temp, index = self:GetTemp(self.TID)
	local cfg = AmbitCfg[index]
	if cfg then name = cfg.floorName end
	des = string.format("突破[%s]%s[-]", "%s", name) 
	return des
end

function M:GetTemp(id)
	local temp, index = BinTool.Find(AmbitCfg, id, "id")
	return temp, index
end

--释放或销毁
function M:Dispose(isDestory)
	self:Super("Dispose", isDestory)
end
--endregion

--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetStrengthen = baseclass(MissionTarget)
local M = MissionTargetStrengthen
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
	self.LNum = tar[2]
	self:Super("UpdateTarData", tar)
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	EquipMgr.OpenEquip(1)
end

--任务描述
function M:TargetDes()
	local des = ""
	if not self.Num then self.Num = 0 end
	des = string.format("[%s]%s[-]件装备强化至[00ff00]%s级[-](%s/%s)", "%s", self.LNum, self.TID, self.Num, self.LNum) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)	
	self:Super("Dispose", isDestory)
end
--endregion

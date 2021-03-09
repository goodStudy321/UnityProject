--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetCompose = baseclass(MissionTarget)
local M = MissionTargetCompose
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
	UICompound:SwitchTg(2)
end


--任务描述
function M:TargetDes()
	local des = ""
	local name = "道具"
	local item = ItemData[tostring(self.TID)]
	if item then name = item.name end
	local num = self.Num or 0
	des = string.format("合成[%s]%s[-](%s/%s)", "%s", name, num, self.LNum) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	self:Super("Dispose", isDestory)
end
--endregion

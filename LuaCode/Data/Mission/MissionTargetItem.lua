--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetItem = baseclass(MissionTargetKill)
local M = MissionTargetItem
local Error = iTrace.Error

--构造函数
function M:Ctor()
	self.ItemID = nil			--怪物配置表
	self.Item = nil
end

--更新目标数据
function M:UpdateTarData(tar)
	self.ItemID = tar[4] 			--怪物ID
	self.ItemNum = tar[5]
	self.Item = ItemData[tostring(self.ItemID)]
	self:Super("UpdateTarData", tar)
end

--任务描述
function M:TargetDes()
	local des = ""
	local tarName = "道具名字"
	if self.Item then tarName = self.Item.name end
	local num = self.Num or 0
	des = string.format("获得[%s]%s[-](%s/%s)", "%s", tarName, num, self.LNum) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	self.ItemID = nil			--怪物配置表
	self.Item = nil
	self:Super("Dispose", isDestory)
end
--endregion

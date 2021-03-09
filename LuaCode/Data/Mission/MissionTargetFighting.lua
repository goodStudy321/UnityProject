--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetFighting = baseclass(MissionTarget)
local M = MissionTargetFighting
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
	self.TID = tar[1] 			--戰鬥力
	self.LNum = tar[1]
	self:Super("UpdateTarData", tar)
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)

end

--任务描述
function M:TargetDes()
	local des = ""
	local num = self.Num or 0
	local cur = math.NumToStr(num)
	local limit = math.NumToStr(self.LNum)
	des = string.format("[%s]战力达到%s[-](%s/%s)", "%s", limit, cur, limit) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	self:Super("Dispose", isDestory)
end
--endregion

--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetFamilyRobbery = baseclass(MissionTarget)
local M = MissionTargetFamilyRobbery
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
	self.LNum = tar[1]			--数量
	self:Super("UpdateTarData", tar)
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	if CustomInfo:IsJoinFamily() then
		if FamilyEscortMgr:GetOpenStatus() then
			UIMgr.Open(UIFamilyEscort.Name)
		else
			UITip.Log("活动未开启")
		end
	end
end


--任务描述
function M:TargetDes()
	local des = ""
	if not self.Num then self.Num = 0 end
	des = string.format("完成道庭劫镖[%s]%s次[-](%s/%s)", "%s", self.LNum, self.Num, self.LNum) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	self:Super("Dispose", isDestory)
end
--endregion

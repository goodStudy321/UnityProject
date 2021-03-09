--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetFriend = baseclass(MissionTarget)
local M = MissionTargetFriend
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
	self.LNum = tar[1]
	self:Super("UpdateTarData", tar)
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	UIMgr.Open(UIFriendsRecommend.Name)
end


--任务描述
function M:TargetDes()
	local des = ""
	local num = self.Num
	des = string.format("拥有[%s]%s位好友[-](%s/%s)", "%s", self.TID, num, self.LNum) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	self:Super("Dispose", isDestory)
end
--endregion

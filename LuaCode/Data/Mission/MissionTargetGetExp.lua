--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetGetExp = baseclass(MissionTarget)
local M = MissionTargetGetExp
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
	UIMgr.Open(UICopy.Name, self.OpenUI)
end

function M:OpenUI(name)
	local ui = UIMgr.Dic[UICopy.Name]
	if ui then
		ui:SetPage(CopyType.Exp)
	end
end

--任务描述
function M:TargetDes()
	local des = ""
	if not self.Num then self.Num = 0 end 
	local cur = math.NumToStr(self.Num)
	local limit = math.NumToStr(self.LNum, true)
	des = string.format("单次副本获得[%s]%s经验[-]", "%s", limit) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)	
	self:Super("Dispose", isDestory)
end
--endregion

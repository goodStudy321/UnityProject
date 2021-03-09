--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetItemII = baseclass(MissionTargetItem)
local M = MissionTargetItemII
local Error = iTrace.Error

--构造函数
function M:Ctor()
	self.ItemID = nil			--怪物配置表
	self.Item = nil
end

--更新目标数据
function M:UpdateTarData(tar)
	self.System = tar[6] 			--系统ID
	self.Item = ItemData[tostring(self.ItemID)]
	self:Super("UpdateTarData", tar)
end

--[[
function M:AutoExecuteAction(fly, execute)
	if fly then
		self:Super("AutoExecuteAction", fly, execute)
	end
	local str1 = "打怪获得"
	local str2 = "商城购买"
	UIMissionView.eClickViewBtn:Add(self.ClickViewBtn, self)
	UIMissionView:UpdateView(self, str1, str2)
end
]]--

function M:ClickViewBtn(tar, str)
	if self ~= tar then return end
	if str == "Nav" then
		self:Super("AutoExecuteAction", self.Execute)
	elseif str == "System" then
		StoreMgr.OpenStore()
	end
	UIMissionView.eClickViewBtn:Remove(self.ClickViewBtn, self)
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
	UIMissionView.eClickViewBtn:Remove(self.ClickViewBtn, self)
	self.ItemID = nil			--怪物配置表
	self.Item = nil
	self:Super("Dispose", isDestory)
end
--endregion

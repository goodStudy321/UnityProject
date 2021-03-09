--[[
聊天信息的P结构
--]]
PlayerTb=Super:New{Name="PlayerTb"}
local My=PlayerTb

function My:Init(info)
	if not info then return end
	self.rId=info.role_id
	self.rN = info.role_name--角色名
	self.sex = info.sex --性别
	self.lv = info.level --等级
	self.cg = info.category --职业
	self.vip = info.vip_level --vip等级
	self.server = info.server_name --区服名字

	local skinList = info.skin_list --聊天皮肤
	if not self.skinList then self.skinList={} end
	if skinList then 
		for i,v in ipairs(skinList) do
			self.skinList[i]=v
		end
	end
end

function My:Dispose()
	ListTool.Clear(self.skinList)
	TableTool.ClearUserData(self)
end
--region SystemMgr.lua
--Date
--此文件由[HS]创建生成

SystemMgr = {Name="SystemMgr"}
local M = SystemMgr

M.eShowActivity = Event()
M.eHideActivity = Event()

M.eShowSystem = Event()
M.eHideSystem = Event()

M.SystemDic = {}

function M:Init()
	self:InitData()
	self:InitEvent()
end

function M:InitData()
	self.Activitys = {}
	--点击头像 UISystemView 红点
	self.Systems = {}
	--头像上红点
	self.SystemNum = 0
end

function M:InitEvent()
	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	self:SetFlagHandler(RuneMgr.embedFlag.eChange,fn,"ChangeRunEmbed")
	self:SetFlagHandler(RuneMgr.decomFlag.eChange,fn,"ChangeRunDecom")
	GWeaponMgr.flag.eChange[fn](GWeaponMgr.flag.eChange, self.ChangeGWeapon, self)
	MountsMgr.flag.eChange[fn](MountsMgr.flag.eChange, self.ChangeMount, self)
	MountAppMgr.eRespRed[fn](MountAppMgr.eRespRed, self.ChangeAppMount, self)
	WingMgr.flag.eChange[fn](WingMgr.flag.eChange, self.ChangeWing, self)
	MWeaponMgr.flag.eChange[fn](MWeaponMgr.flag.eChange, self.ChangeMWeapon, self)
	PetMgr.flag.eChange[fn](PetMgr.flag.eChange, self.ChangePet, self)
	-- PetMgr.eUpdatePetDev[fn](PetMgr.eUpdatePetDev, self.ChangePetDev, self) --伙伴吞噬红点移除养成系统到背包
	PetAppMgr.eRespRed[fn](PetAppMgr.eRespRed, self.ChangeAppPet, self)
	ThroneMgr.eComposeRed[fn](ThroneMgr.eComposeRed, self.ChangeThrone, self)
	ThroneMgr.eAdvRed[fn](ThroneMgr.eAdvRed, self.ChangeThrone, self)
	ThroneAppMgr.eRespRed[fn](ThroneAppMgr.eRespRed, self.ChangeThrone, self)

	EquipMgr.eComRed[fn](EquipMgr.eComRed, self.ChangeComEquip, self)
	EquipMgr.eRed[fn](EquipMgr.eRed, self.ChangeEquip, self)
	FashionMgr.eUpdateRedPoint[fn](FashionMgr.eUpdateRedPoint, self.ChangeFahion, self)
	InnateMgr.eRed[fn](InnateMgr.eRed, self.ChangeInnate, self)
	SkillMgr.eRed[fn](SkillMgr.eRed, self.ChangeSkill, self)
	ImmortalSoulMgr.eChangeSoul[fn](ImmortalSoulMgr.eChangeSoul, self.ChangeSoul, self)
	MarryMgr.eChangeMarry[fn](MarryMgr.eChangeMarry, self.ChangeMarry, self)
	SuccessMgr.eChangeAction[fn](SuccessMgr.eChangeAction, self.ChangeSucc, self)
	ElixirMgr.eAction[fn](ElixirMgr.eAction, self.ChangeElixir, self)
	FamilyMgr.eRed[fn](FamilyMgr.eRed, self.ChangeFamily, self);
	PicCollectMgr.eRed[fn](PicCollectMgr.eRed, self.ChangePicCollect, self);
	RobberyMgr.eSpRed[fn](RobberyMgr.eSpRed, self.ChangeSpirit, self);
	SMSMgr.eChangeRed[fn](SMSMgr.eChangeRed, self.UpdateSMSRed, self)
end

--设置红点事件
--e(Event):更新事件
--fn(string):添加/注册方法名
--hn(string):处理方法名
function M:SetFlagHandler(e,fn,hn)
	e[fn](e,self[hn],self)
end
----------------------------------------------

-- --境界
-- function M:ChangeAmbit(value)
-- 	self:ChangeActivity(value, ActivityMgr.JS, 2)
-- end

--时装
function M:ChangeFahion(value)
	self:ChangeActivity(value, ActivityMgr.JS, 1, 1)
end

--天赋
function M:ChangeInnate( value )
	self:ChangeActivity(value, ActivityMgr.JS, 3)
end

--技能
function M:ChangeSkill( value )
	self:ChangeActivity(value, ActivityMgr.JS, 2)
end

--成就
function M:ChangeSucc(value)
	self:ChangeActivity(value, ActivityMgr.JS, 3, 1)
end

--丹药
function M:ChangeElixir(value)
	self:ChangeActivity(value, ActivityMgr.JS, 5)
end

--符文镶嵌
function M:ChangeRunEmbed(value)
	self:ChangeActivity(value, ActivityMgr.FW, 1)
end

--符文分解
function M:ChangeRunDecom(value)
	self:ChangeActivity(value, ActivityMgr.FW, 2)
end

--------------------[[养成]]---------------------------
-- value 状态
-- t 1:进阶 2:丹药 3:皮肤 4:坐骑和伙伴幻化 5：宝座分解 6：宝座进阶 7：宝座幻化 8:伙伴吞噬
--页签ID:1--->坐骑  2--->法宝  3--->宠物  4--->神兵  5--->翅膀

--value:红点显示状态
--k:系统图标index
--i:区别系统中的不同模块
--t:相同模块不同功能的红点
function M:ChangeGWeapon(value, t)
	if OpenMgr:IsOpen(4) == false then return end
	self:ChangeActivity(value, ActivityMgr.YC, 4, t)
end

function M:ChangeMount(value, t)
	if OpenMgr:IsOpen(1) == false then return end
	self:ChangeActivity(value, ActivityMgr.YC, 1, t)
end

function M:ChangeAppMount(value,t)
	if OpenMgr:IsOpen(1) == false then return end
	self:ChangeActivity(value, ActivityMgr.YC, 1, t)
	self:ChangeActivity(value, ActivityMgr.YC, 11, t)
end

function M:ChangeWing(value, t)
	if OpenMgr:IsOpen(5) == false then return end
	self:ChangeActivity(value, ActivityMgr.YC, 5, t)
end

function M:ChangeMWeapon(value, t)
	if OpenMgr:IsOpen(2) == false then return end
	self:ChangeActivity(value, ActivityMgr.YC, 2, t)
end

function M:ChangePet(value, t)
	if OpenMgr:IsOpen(3) == false then return end
	self:ChangeActivity(value, ActivityMgr.YC, 3, t)
end

function M:ChangeAppPet(value, t)
	if OpenMgr:IsOpen(3) == false then return end
	self:ChangeActivity(value, ActivityMgr.YC, 3, t)
	self:ChangeActivity(value, ActivityMgr.YC, 10, t)
end

--伙伴吞噬  3 改 0 移到背包
function M:ChangePetDev(value, t)
	local lockStateCfg,isOpen = PetMgr:IsOpenDevour()
	if isOpen == false then return end
	self:ChangeActivity(value, ActivityMgr.YC, 0, t)
end

function M:ChangeThrone(value,t)
	if OpenMgr:IsOpen(6) == false then return end
	self:ChangeActivity(value,ActivityMgr.YC,6,t)
end

--------------------[[仙魂]]---------------------------
function M:ChangeSoul(value)
	self:ChangeActivity(value, ActivityMgr.XH, 1)
end

--------------------[[结婚]]---------------------------
function M:ChangeMarry(value)
	self:ChangeActivity(value, ActivityMgr.XL, 1)
end

--装备系统
function M:ChangeEquip(value, index,t)
	self:ChangeActivity(value, ActivityMgr.LQ, index,t)
end

--合成系统
function M:ChangeComEquip(value, index,t)
	self:ChangeActivity(value, ActivityMgr.LB3, index,t)
end

--------------------[[道庭]]---------------------------
--// 每日奖励 t: 1、每日奖励，2、申请列表，3、红包
function M:ChangeFamily(value, t, p)
	if FamilyMgr:JoinFamily() == false then
		return;
	end

	self:ChangeActivity(value, ActivityMgr.DT, t, p);
end

--图鉴
function M:ChangePicCollect(value, t)
	if PicCollectMgr:IsOpen() == false then return end
	self:ChangeActivity(value, ActivityMgr.TJ, 1, t);
end

--战灵
--t == 1 战灵
--t == 2 灵饰
--t == 3 战神套装
--t == 4 灵器
--value:红点状态
function M:ChangeSpirit(t,value)
	if OpenMgr:IsOpen(68) == false then return end
	local p = t + 1
	self:ChangeActivity(value, ActivityMgr.ZL,p,t);
end
--天机印
function M:UpdateSMSRed()
	if OpenMgr:IsOpen(706) == false then return end
	local state = SMSMgr.IsHole==true or SMSMgr.IsUpScore==true or SMSMgr.IsStrength == true
	self:ChangeActivity(state, ActivityMgr.TJY, 0);
end

-------------------------------------------------------
function M:Change(value, k, i, t)
	if value == true then
		self:ShowSystem(k, i, t)
	else
		self:HideSystem(k, i, t)
	end
end

function M:ChangeActivity(status, id, index, t)
	if status == true then
		self:ShowActivity(id, index, t)
	else
		self:HideActivity(id, index, t)
	end
end

--==============右上角 活动================--
function M:ShowActivity(id, page, t)
	if page == nil then page = 0 end
	if t == nil then t = 0 end
	local key = tostring(id)
	local page = tostring(page)
	local status = self:GetActivityIndex(id, page, t)
	if status == true then return end
	if not self.Activitys[key] then self.Activitys[key] = {} end
	if not self.Activitys[key][page] then self.Activitys[key][page]  = {} end
	table.insert(self.Activitys[key][page],t)
	self.eShowActivity(id)
end

function M:HideActivity(id, page, t)
	if t == nil then t = 0 end
	if page == nil then page = 0 end
	local key = tostring(id)
	local page = tostring(page)
	local status = self:GetActivityIndex(id, page, t)
	if statsu == false then return end
	local dic = self.Activitys[key]
	local index = nil
	if dic then
		local pages = dic[page]
		if pages then
			for i=1,#pages do
				if pages[i] == t then
					index = i;
				end
			end
		end
	end
	if index == nil then return end
	table.remove(dic[page], index)
	if #dic[page] == 0 then self.Activitys[key][page] = nil end
	if LuaTool.Length(self.Activitys[key]) == 0 then self.Activitys[key]=nil end
	self.eHideActivity(id)
end

function M:GetActivity(id)
	if self.Activitys then
		local key = tostring(id)
		for k,v in pairs(self.Activitys) do
			if k == key then 
				return true
			end
		end
	end
	return false
end

function M:GetActivityStatusForList(list)
	if list then
		for i=1,#list do
			if self:GetActivityStatusForLayer(list[i]) == true then
				return true
			end
		end
	end
	return false
end

function M:GetActivityStatusForLayer(layer)
	local dic = self.Activitys
	if dic then
		for k,v in pairs(dic) do
			local key, temp = ActivityMgr:Find(tonumber(k))
			if temp and temp.layer == layer then
				return true
			end
		end
	end
	return false
end

function M:GetActivityPage(id, page)
	--[[
	local value = false
	if self.Activitys then
		local key = tostring(id)
		for k,v in pairs(self.Activitys) do
			if k == key then
				if id == 306  then
					id = id * 1
				end
				value = true
				for i,j in ipairs(v) do
					if j == index then return true, i end
				end
			end
		end
	end
	return value, nil
	]]--
	if t == nil then t = 0 end
	local key = tostring(id)
	local p = tostring(page)
	local dic = self.Activitys
	for k,v in pairs(dic) do
		if key == k then
			for j,vv in pairs(v) do
				if j == p then
					return true
				end
			end
		end
	end
	return false
end

function M:GetActivityIndex(id, page, t)
	--[[
	local value = false
	if self.Activitys then
		local key = tostring(id)
		for k,v in pairs(self.Activitys) do
			if k == key then
				if id == 306  then
					id = id * 1
				end
				value = true
				for i,j in ipairs(v) do
					if j == index then return true, i end
				end
			end
		end
	end
	return value, nil
	]]--
	if t == nil then t = 0 end
	local key = tostring(id)
	local p = tostring(page)
	local dic = self.Activitys
	for k,v in pairs(dic) do
		if key == k then
			for j,vv in pairs(v) do
				if j == p then
					for i,vvv in ipairs(vv) do
						if vvv == t then
							return true
						end
					end
				end
			end
		end
	end
	return false
end
-------------------------------------

--==============头像系统================--
--id uisystem 索引id
--index --系统分页
function M:ShowSystem(id, index, t)
	if not t then t = 0 end
	local key = tostring(id)
	local k = tostring(index)
	local status = self:GetSystemType(id, index, t)
	if status == true then return end
	if not self.Systems[key] then self.Systems[key] = {} end 
	if not self.Systems[key][k] then self.Systems[key][k] = {} end
	table.insert(self.Systems[key][k], t)
	self.SystemNum = self.SystemNum + 1
	self.eShowSystem(id)
end

function M:HideSystem(id, index, t)
	if not t then t = 0 end
	local key = tostring(id)
	local k = tostring(index)
	local status = self:GetSystemType(id, index, t)
	if status == false then return end
	local dic = self.Systems[key]
	local ii = nil
	if not dic then return end
	local list = dic[k]
	if list then
		for i,v in ipairs(list) do
			if v == t then
				ii = i
				break
			end
		end
	end
	if not ii then return end
	table.remove(dic[k], ii)
	if #dic[k] == 0 then self.Systems[key][k] = nil end
	if LuaTool.Length(self.Systems[key]) == 0 then self.Systems[key]=nil end
	self.SystemNum = self.SystemNum - 1
	self.eHideSystem(id)
end

function M:GetSystem(id)
	if self.Systems then
		for k,v in pairs(self.Systems) do
			local kid = tonumber(k)
			if kid == id then return true end
		end
	end
	return false
end

function M:GetSystemIndex(id, index)
	if self.Systems then
		for k,v in pairs(self.Systems) do
			if tonumber(k) == id then
				for i,d in pairs(v) do
					if tonumber(i) == index then return true end
				end
			end
		end
	end
	return false
end

function M:GetSystemType(id, index, t)
	if not t then t = 0 end
	if self.Systems then
		for k,v in pairs(self.Systems) do
			if tonumber(k) == id then
				for j,c in pairs(v) do
					if tonumber(j) == index then
						for i,d in ipairs(c) do
							if d == t then return true end
						end
					end
				end
			end
		end
	end
	return false
end
-------------------------------------
function M:Reset()
	TableTool.ClearDic(self.Activitys)
	TableTool.ClearDic(self.Systems)
	self.SystemNum = 0
end

function M:Clear()
	self:Reset()
end

function M:Dispose()
	self:RemoveEvent()
end

return M
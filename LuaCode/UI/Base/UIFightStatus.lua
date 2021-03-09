--region UIFightStatus.lua
--Date
--此文件由[HS]创建生成

UIFightStatus = UIBase:New{Name ="UIFightStatus"}
local M = UIFightStatus

function M:InitCustom()
	self.Persitent = true;
	local name = "攻击模式"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	local S = UITool.SetLsnrSelf
	self.CloseBtn = T(trans, "Close")
	self.Peaceful = C(UIToggle, trans, "PeacefulToggle", name, false)
	self.Coercion = C(UIToggle, trans, "CoercionToggle", name, false)
	self.All = C(UIToggle, trans, "AllToggle", name, false)
	self.CrsSvr = C(UIToggle, trans, "CrsSvrToggle", name, false)
	self.BossExcl = C(UIToggle, trans, "BossExclToggle",name, false)


	S(self.CloseBtn, self.Close, self);
	
	EventDelegate.Set(self.Peaceful.onChange, EventDelegate.Callback(self.Select, self))
	EventDelegate.Set(self.Coercion.onChange, EventDelegate.Callback(self.Select, self))
	EventDelegate.Set(self.All.onChange, EventDelegate.Callback(self.Select, self))
	EventDelegate.Set(self.CrsSvr.onChange, EventDelegate.Callback(self.Select, self))
	EventDelegate.Set(self.BossExcl.onChange, EventDelegate.Callback(self.Select, self))
end

function M:Select(status)
	if status == false then return end
	local fightType = nil
	if self.Peaceful and self.Peaceful.value == true then
		fightType = FightStatus.PeaceMode
	elseif self.Coercion and self.Coercion.value == true  then
		fightType = FightStatus.ForceMode
	elseif self.All and self.All.value == true  then
		fightType = FightStatus.AllMode
	elseif self.CrsSvr and self.CrsSvr.value == true  then
		fightType = FightStatus.CrsSvrMode
	elseif self.BossExcl and self.BossExcl.value == true  then
		fightType = FightStatus.BossExclusive
	end
	if not fightType then return end
	if fightType == User.instance.MapData.FightType then return end

	local sceneId = tostring(User.instance.SceneId);
	if sceneId == "0" then
		return 0;
	end
	if SceneTemp[sceneId] == nil then
		return 0;
	end
	
	local fighmodel = SceneTemp[sceneId].fightmode;
	local result = false;
	for k in pairs(fighmodel) do
		if fightType == fighmodel[k] then
			result = true;
			break;
		end
	end
	if result then
		NetFightInfo.RequestChangeFightMode(fightType);
		self:Close()
	else
		UITip.Error(string.format("当前场景不能切换成%s战斗姿态",GetFightStatusTitle(fightType)))
		self:SetStatus(fightType, false)
		self:InitSet()
	end
end

function M:InitSet()
	local fightType = User.instance.MapData.FightType
	self:SetStatus(fightType)
end

function M:SetStatus(type, value)
	if not value then value = true end
	local toggle = nil
	self:SetGo(type);
	if type == FightStatus.PeaceMode then
		if self.Peaceful then toggle = self.Peaceful end
	elseif type == FightStatus.ForceMode or type == FightStatus.CampMode then
		if self.Coercion then toggle = self.Coercion end
	elseif type == FightStatus.AllMode then
		if self.All then toggle = self.All end
	elseif type == FightStatus.CrsSvrMode then
		if self.CrsSvr then toggle = self.CrsSvr end
	elseif type == FightStatus.BossExclusive then
		if self.BossExcl then toggle = self.BossExcl end
	end
	if not toggle then return end
	if value == true then toggle.value = value
	else toggle:Set(false, false, false) end
end

--设置对象
function M:SetGo(type)
	if type == FightStatus.BossExclusive then
		self.BossExcl.gameObject:SetActive(true);
		self.Peaceful.gameObject:SetActive(false);
		self.Coercion.gameObject:SetActive(false);
		self.All.gameObject:SetActive(false);
		self.CrsSvr.gameObject:SetActive(false);
	else
		self.BossExcl.gameObject:SetActive(false);
		self.Peaceful.gameObject:SetActive(true);
		self.Coercion.gameObject:SetActive(true);
		self.All.gameObject:SetActive(true);
		self.CrsSvr.gameObject:SetActive(true);
	end
end

function M:OpenCustom()
	self:InitSet()
end

function M:CloseCustom()
end

function M:DisposeCustom()
end

return M

--endregion

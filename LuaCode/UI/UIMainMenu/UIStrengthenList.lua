--region UIStrengthenList.lua
--Date
--此文件由[HS]创建生成

UIStrengthenList = {}
local M = UIStrengthenList

M.MaxShow = 5
local SMgr = SystemMgr
local AMgr = ActivityMgr

--注册的事件回调函数

function M:New(t)
	local name = "变强"
	self.GO = t.gameObject
	local trans = t
	local T = TransTool.FindChild
	local C = ComTool.Get
	
	self.Root = T(trans, "LeftCenter/MoveRoot/StrengthenBtn")
	self.Toggle = C(UIToggle, trans, "LeftCenter/MoveRoot/StrengthenBtn", name, false)
	--self.anchor = C(UIWidget,trans, "StrengthenBtn",name)
	--self.oriLeft = self.anchor.leftAnchor.absolute
	--self.oriRight = self.anchor.rightAnchor.absolute

	--self.StrengthenList = self.Root:GetComponent("UIMenuTip")
	--self.StrengthenList.items:Clear()

	--self:InitData()
	return M
end
--[[]
function M:InitData()
	local items = self.StrengthenList.items
	local list = StrengthenTemp
	for i=1,#list do
		local temp = list[i]
		if temp then 
			items:Add(temp.name)
		end
	end
end
]]--
------------------------------------------------------------------------------

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	--控件事件
	if self.Root then
		E(self.Root, self.ClickBtn, self, nil, false)
	end
	self:SetEvent("Add")
	self:UpdateEvent(EventMgr.Add)
end

function M:SetEvent(fn)
	VIPMgr.eUpAction[fn](VIPMgr.eUpAction, self.UpdateCustomItems, self)
	SMgr.eShowActivity[fn](SMgr.eShowActivity, self.UpdateCustomItems, self)
	SMgr.eHideActivity[fn](SMgr.eHideActivity, self.UpdateCustomItems, self)
	SMgr.eShowSystem[fn](SMgr.eShowSystem, self.UpdateCustomItems, self)
	SMgr.eHideSystem[fn](SMgr.eHideSystem, self.UpdateCustomItems, self)
	MarriageTreeMgr.eShowTree[fn](MarriageTreeMgr.eShowTree,self.UpdateCustomItems,self)
	ActPreviewMgr.eShow[fn](ActPreviewMgr.eShow,self.UpdateCustomItems,self)
	UIRedMenu.eClickMenu[fn](UIRedMenu.eClickMenu, self.UpdateStrengthen, self)
	euiclose[fn](euiclose, self.ColosUI, self)
end

function M:UpdateEvent(E)
end

function M:RemoveEvent()
	self:SetEvent("Remove")
	self:UpdateEvent(EventMgr.Remove)
end

function M:SetStatus(value)
	local toggle = self.Toggle
	if toggle then
		toggle.value = value
	end
end

function M:ColosUI(name)
	if name ~= UIRedMenu.Name then return end
	self:SetStatus(false)
end

----------
function M:ClickBtn(go)
	self:SetStatus(true)
	UIMgr.Open(UIRedMenu.Name)
end

function M:OpenSystemUI(k, i, t)
	if k == 6 then
		AdvMgr:OpenBySysID(i)
	elseif k == 7 then
		RuneMgr.OpenBySysIndex(i)
	elseif k == 2 then
		EquipMgr.OpenEquip(i,t)
	elseif k == 3 then
		--// 道庭技能
		if t == 6 then
			FamilyMgr:OpenFamilyWndTag(i, function() UIMgr.Open("UIFamilySkillWnd"); end);
		elseif t == 4 then--道庭Boss
			UIMgr.Open(UIFamilyBossIt.Name)
		else
			FamilyMgr:OpenFamilyWndTag(i);
		end
	elseif k == 4 then
		PicCollectMgr:OpenUI(t)
	elseif k == 1 then
		if i==1 and t == 1 then
			UIFashionPanel:ShowRPFashion()
		elseif i ==1 and t == 3 then
			UIMgr.Open(UISuccess.Name)
		elseif i==2 then
			UIRole:SelectOpen(2)
		elseif i==3 then
			UIRole.OpenIndex = 3
			UIMgr.Open(UIRole.Name);
		end
	end
end

function M:OpenActivityUI(temp, k, i)
	if not temp then return end
	local ui = temp.ui 
	local uicfg = UICfg[ui]
	if not uicfg then return end
	if k == 0 then
		VIPMgr.OpenVIP(i)
	elseif k == AMgr.XB then
		UITreasure:OpenTab(i)
	elseif k == AMgr.CJHL then 
		UILvAward:OpenTab(i)
	elseif k == AMgr.DJ then
		UIRobbery:OpenRobbery(i)
	elseif k == AMgr.ZL then
		UIRobbery:OpenRobbery(i)
	elseif k==AMgr.BOSS then 
		BossHelp.OpenBoss(i);
	elseif k==AMgr.VIPSC then
		StoreMgr.OpenVIPStore(i)
	elseif k==AMgr.JN then
		UIRole:SelectOpen(i)
	elseif k==AMgr.JS then
		if i == 3 then
			UIMgr.Open(UISuccess.Name)
		elseif i == 1 then
			UIMgr.Open(ui)
		else
			UIRole:SelectOpen(i)
		end
	elseif k == AMgr.YC then
		if i == 0 then --伙伴吞噬移到背包
			UIPetDevourPack.OpenPetDevPack()
		elseif i == 10 then --伙伴幻化
			UITransApp.OpenTransApp(2)
		elseif i == 11 then --坐骑幻化
			UITransApp.OpenTransApp(1)
		else
			AdvMgr:OpenBySysID(i)
		end
	elseif k==AMgr.LB1 then
		SuitMgr.OpenSuit()
	elseif k==AMgr.LQ then
		EquipMgr.OpenEquip(temp.page,temp.t)
	elseif k==AMgr.LB3 then
		UICompound:SwitchTg(temp.page,temp.t)
	elseif k==AMgr.DY then
		UIRole:SelectOpen(5)
	elseif k==AMgr.LB2 then
		UIRole:SelectOpen(6)
	else
		UIMgr.Open(ui)
	end
end

function M:UpdateStrengthen(temp)
	if not temp then return end
	if temp.type == 1 then
		self:OpenSystemUI(temp.ident, temp.page, temp.t)
	elseif temp.type == 2 or temp.type == 3 then
		self:OpenActivityUI(temp, temp.ident, temp.page)
	elseif temp.type == 4 then
		if temp.ui == "UIMarry" then
			UIMarry:OpenTab(temp.page)
		elseif temp.ui == "UIFuncOpen" then
			UIFuncOpen:OpenTag(temp.page)
		end
		
	end
end

function M:UpdateCustomItems()
	UIRedMenu:ClearCustomIndex()
	local indexs = UIRedMenu.CustomIndex
	local list = StrengthenTemp
	for i=1,#list do
		local temp = list[i]
		local value = false
		if temp.type == 1 then
			value = self:UpdateSystem(temp)
		elseif temp.type == 2 then
			value = self:UpdateActivity(temp)
		elseif temp.type == 3 then
			value = self:UpdateVip(temp)
		elseif temp.type == 4 then
			if temp.ui == "UIMarry" then
				value = MarriageTreeMgr:GetStatus()
			elseif temp.ui == "UIFuncOpen" then
				value =  ActPreviewMgr:IsOpen()
			end 
		end
		if value == true then
			TableTool.Add(indexs, temp.id)
		end
	end
	self.Root:SetActive(#indexs > 0)
	EventMgr.Trigger("MenuTipReposition")
end

--[[
function M:ScreenChange(orient, init)
	local reset = not UITool.IsResetOrient(orient)
	UITool.SetLiuHaiAbsolute(self.anchor, true, reset, self.oriLeft,self.oriRight, -1)
end
]]--
function M:UpdateSystem(temp)
	local ident = temp.ident
	local page = temp.page
	local t = temp.t
	return SMgr:GetSystemType(ident, page, t)
end

function M:UpdateActivity(temp)
	local ident = temp.ident
	local page = temp.page
	local t = temp.t
	return SMgr:GetActivityIndex(ident, page, t)
end

function M:UpdateVip(temp)
	local page = temp.page
	local key = tostring(page)
	local state =  VIPMgr.stateDic[key]
	return state and state == true
end

function M:Open()
	self:AddEvent()
	self:UpdateCustomItems()
end

function M:Close()
	self:SetStatus(false)
	self:RemoveEvent()
end

function M:Clear()
end


function M:Dispose()
end
--endregion

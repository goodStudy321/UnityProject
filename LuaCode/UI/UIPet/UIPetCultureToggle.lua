--region UIPetCultureToggle.lua
--Date
--此文件由[HS]创建生成
--local PetMgs = PetMessage.instance

UIPetCultureToggle = {}
local this = UIPetCultureToggle

--注册的事件回调函数

function UIPetCultureToggle:New(go, selectCallback, isActiveCallback , ShowSkillTipCallback)
	local name = "UI伙伴培养面板"
	self.gameObject = go
	self.SelectCallback = selectCallback
	self.ShowSkillTipCallback = ShowSkillTipCallback
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Panel = C(UIScrollView, trans, "ScrollView", name, false)
	self.Grid = C(UIGrid, trans, "ScrollView/Grid", name, false)
	self.Prefab = T(trans, "ScrollView/Grid/Item")
	self.Items = {}
	--解锁条件
	self.Active = UIPetActive:New(T(trans, "Active"))
	--右上角属性
	self.StepProperty = UIPetProperty:New(T(trans, "StepProperty"), isActiveCallback)

	self.SkillView = UIPetSkillScrollView.New(T(trans,"Skill"), ShowSkillTipCallback)
	self.SkillView:Init()

	self.CurSelectCell = nil

	self:InitData()
	return this
end

function UIPetCultureToggle:InitData()
	for i=1,#PetMgr.IDList do
		local key = tostring(PetMgr.IDList[i])
		if PetMgr.Dic[key] then
			self:AddItem(PetMgr.Dic[key])
		end
	end
--[[
	local num = PetMgs.List.Count
	num = num - 1
	for i=0,num do
		self:AddItem(PetMgs.List[i])
	end
	]]--
	self:CopyGridReposition()
end

--增加宠物选择Item
function UIPetCultureToggle:AddItem(data)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = go.name.."_"..tostring(data.KeyID)
	go.name = string.gsub(go.name, "%(Clone%)", "")
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one * 0.8
	UIEvent.Get(go).onClick = function(gameObject) self:OnClickItem(gameObject) end
	self.Items[tostring(data.KeyID)] = UICellSystemItem.New(go)
	self.Items[tostring(data.KeyID)]:Init()
	self.Items[tostring(data.KeyID)]:UpdateData(data)
end
--更新当前
function UIPetCultureToggle:UpdateData(data)
	if data ~= nil then
		for k,v in pairs(self.Items) do
			if v.Data.KeyID == data.KeyID then 
				v:UpdateData(data)
				if self.CurSelectCell.Data.KeyID == v.Data.KeyID then 
					self:OnClickItem(self.CurSelectCell.gameObject)
				end
			end
		end
	end
end
--更新说有i
function UIPetCultureToggle:UpdateAllData()
	for i=1,#PetMgr.IDList do
		local key = tostring(PetMgr.IDList[i])
		if PetMgr.Dic[key] then
			self:UpdateData(PetMgr.Dic[key])
		end
	end
	--[[
	local num = PetMgs.List.Count
	num = num - 1
	for i=0,num do
		self:UpdateData(PetMgs.List[i])
	end
	]]--
end

function UIPetCultureToggle:UpdateSkills(list, dic)
	if self.SkillView then self.SkillView:UpdateData(list, dic, true) end
end

--点击Items
function UIPetCultureToggle:OnClickItem(go)
	if self.CurSelectCell ~= nil then
		--if self.CurSelectCell.gameObject.name == go.name then return end
		self.CurSelectCell:IsSelect(false)
	end
	for k,v in pairs(self.Items) do
		if  v.gameObject and v.gameObject.name == go.name then 

			self.CurSelectCell = v 
			if self.CurSelectCell.Data.IsActive then
				self.Active:SetActive(false)
				self.StepProperty:UpdateData(self.CurSelectCell.Data)
				self.StepProperty:SetActive(true)
			else
				self.StepProperty:SetActive(false)
				self.Active:UpdateData(self.CurSelectCell.Data)
				self.Active:SetActive(true)
			end
			if self.CurSelectCell ~= nil then 
				self.CurSelectCell:IsSelect(true) 
				self:UpdateSkills(self.CurSelectCell.Data.SKillIDList, self.CurSelectCell.Data.SkillDic)
			end
			self:OnCallbackAction()
		end
	end
end

function UIPetCultureToggle:OnCallbackAction()
	if not self.CurSelectCell or not self.CurSelectCell.Data then return end
	if self.SelectCallback then self.SelectCallback(self.CurSelectCell.Data) end
	-- body
end

function UIPetCultureToggle:OnClickSkillItems(go)
	local index = string.gsub(go.name, "Item", "")
	index = tonumber(index)
	local id = self.CurSelectCell.Data.Info.openList.list[index - 1]
	if id == nil then return end
	local info = SkillLvTemp[tostring(id)]
	if info then
		if self.ShowSkillTip then self.ShowSkillTip(info) end
	end
end

function UIPetCultureToggle:UpdatePetStepExp()
	if not self.CurSelectCell then return end
	if self.StepProperty then self.StepProperty:UpdateData(self.CurSelectCell.Data) end
end

function UIPetCultureToggle:UpdateItemList()
	if self.StepProperty then self.StepProperty:UpdateItemList() end
end

function UIPetCultureToggle:CopyGridReposition()
	self.Grid:Reposition()
	if self.Grid:GetChildList().Count >= 4 then 
		self.Panel.isDrag = true
	else
		self.Panel.isDrag = false
	end
end

function UIPetCultureToggle:Open()
	if not self.CurSelectCell then
		local go = nil
		local key = nil
		for i=1,#PetMgr.IDList do
			key = tostring(PetMgr.IDList[i])
			if self.Items[key] and self.Items[key].Data then
				if self.Items[key].Data.IsActive == true then
					go =  self.Items[key].gameObject
				else
			 		break
				end
			end
		end
		if go ~= nil then
			self:OnClickItem(go)
		else
			if self.Items[tostring(PetMgr.IDList[1])] then self:OnClickItem(self.Items[tostring(PetMgr.IDList[1])].gameObject) end
		end
	end
	--[[
	if not self.CurSelectCell then
		if self.Items[tostring(PetMgr.IDList[1])] then
		 	self:OnClickItem(self.Items[tostring(PetMgr.IDList[1])].gameObject)
		end
	end
	]]--
end

function UIPetCultureToggle:Dispose()
end
--endregion

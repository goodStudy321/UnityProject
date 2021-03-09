--region UIPetDevourView.lua
--Date
--此文件由[HS]创建生成



UIPetDevourView = baseclass(UIScrollViewBase)

UIPetDevourView.CloseCB = nil
local Players = UnityEngine.PlayerPrefs

function UIPetDevourView:Ctor(go)
	-- Players.DeleteAll()
	local name = "UI伙伴吞噬装备窗口"	
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = self.trans
	local name = self.Name
	self.CloseBtn = T(trans, "closeBtn")
	self.Btn = C(UIButton, trans, "Button", name, false)
	--self.ASBtn = C(UIButton, trans, "ASBtn", name, false)
	self.GetStepExp = C(UILabel, trans, "GetExp", name, false)
	self.SelectP = T(trans, "Select")
	
	self.QMenu = C(UIPopupList, trans, "QualityMenu", name, false)
	self.SMenu = C(UIPopupList, trans, "StepMenu", name, false)
	self.Star = C(UIToggle, trans, "Toggle", name, false)
	self.DevTog = C(UIToggle, trans, "tog", name, false)

	self.ScrollLimit = 8
	self.MinCount = 32
	self.UseItems = {}
	self.ItemList = nil
	self.useEffectValue = 0
	self.ItemScale = 0.774

	self.sView = C(UIPanel, trans, "ScrollView")

	self.ExpSlider = C(UISprite, trans, "SlidBg/slid", name, false)
	self.Exp = C(UILabel, trans, "slidLab", name, false)
	self.Lv = C(UILabel, trans, "LevelLab", name, false)
	self.VipDesLab = C(UILabel, trans, "vDesLab", name, false)

	self.pMgr = PetMgr
	self.sView.clipOffset = Vector2.New(0,53)
	self.sView.transform.localPosition = Vector3.New(9,-86.5,0)
	self.addRate = 0

	return self
end

function UIPetDevourView:Init()
	self:UpdateItems(self.MinCount)
	self:AddEvent()
	self:UpdateLvExp()
	self.QMenu.items:Clear()
	self.SMenu.items:Clear()
	local func = function (a, b)
		return a > b
	end
	self.QMenuValue = {}
	self.SMenuValue = {}
	for k,v in pairs(ItemQuality) do
		if v == 0 or (v >= ItemQuality.Purple and v < ItemQuality.Powder) then
			table.insert(self.QMenuValue,v)
		end
	end
	table.sort(self.QMenuValue,func)
	for i=1,#self.QMenuValue do
		local index = self.QMenuValue[i]
		local v =  GetItemQualityName(index)
		self.QMenu.items:Add(v)
		if index == ItemQuality.Purple then
			self.QMenu.value = v
		end
	end

	for k,v in pairs(ItemStep) do
		if v == 0 or v >= ItemStep.Four then
			table.insert(self.SMenuValue, v)
		end
	end
	table.sort(self.SMenuValue,func)
	for i=1,#self.SMenuValue do
		local index = self.SMenuValue[i]
		local v = GetItemStepName(self.SMenuValue[i])
		self.SMenu.items:Add(v)
		if index == ItemQuality.All then
			self.SMenu.value = v
		end
	end
	self:HasPlayerKey()
	self.curPropCount = nil
	self.MenuCb = EventDelegate.Callback(function() self:Change() end)
	self:ShowDev()
end

function UIPetDevourView:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Btn then
		E(self.Btn, self.OnClickBtn, self)
	end
	--if self.ASBtn then
	--	E(self.ASBtn, self.OnClickASBtn, self)
	--end
	if self.gameObject then
		E(self.gameObject, self.OnClickMask, self)
	end
	if self.CloseBtn then
		E(self.CloseBtn, self.OnClickMask, self)
	end
	if self.Star then
		E(self.Star, self.Change, self,nil, false)
	end
	if self.DevTog then
		E(self.DevTog,self.DevTogChange,self,nil,false)
	end
	self:SetEvent("Add")
end

function UIPetDevourView:SetEvent(fn)
	self.pMgr.eUpdatePetExp[fn](self.pMgr.eUpdatePetExp, self.UpdateLvExp, self)
end

function UIPetDevourView:RemoveEvent()
	self:SetEvent("Remove")
end

function UIPetDevourView:Sort(a, b)
	-- local ia = ItemData[tostring(a.type_id)]
	-- local ib = ItemData[tostring(b.type_id)]
	-- if ia == nil or ib == nil then return a < b end
	-- return ia.quality < ib.quality
	local a = ItemData[tostring(a)]
	local b = ItemData[tostring(b)]
	return a.quality<b.quality
end

function UIPetDevourView:UpdateData()
	if self.gameObject.activeSelf == false then return end
	self:CleanCells()
	if self.GetStepExp then self.GetStepExp.text = tostring(self.useEffectValue) end

	local curQ = ItemQuality.All
	local curS = ItemStep.All
	-- if Players.HasKey("IntQ") then
	-- 	local qValue = Players.GetInt("IntQ")
	-- 	curQ = qValue
	-- end

	-- if Players.HasKey("IntS") then
	-- 	local sValue = Players.GetInt("IntS")
	-- 	curS = sValue
	-- end

	self.ItemList = PropMgr.GetQUARANKSTART(curQ, curS, 0)
	
	if self.ItemList == nil or #self.ItemList==0 then return end
	--table.sort(self.ItemList, function (a,b) return self:Sort(a,b) end)
	if not self.ItemList then 
		self.UseItems = {}
		self:CleanCells()
		return 
	end 
	self.ItemCount = #self.ItemList
	self:CheckItemsCount(self.ItemCount)
	self:UpdateSelect()
	self:GridReposition()
end

function UIPetDevourView:ShowDev()
    if Players.HasKey("ShowDev") then
        local togIndex = Players.GetInt("ShowDev")
        if togIndex == 1 then
            self.DevTog.value = true
        else
            self.DevTog.value = false
		end
	else
		self.DevTog.value = false
		Players.SetInt("ShowDev", 0)
    end
end

function UIPetDevourView:Change()
	self:UpdateSelect()
	-- body
end

function UIPetDevourView:DevTogChange()
	local val = self.DevTog.value
    if val == false then
        Players.SetInt("ShowDev", 0)
    else
        Players.SetInt("ShowDev", 1)
	end
	PetMgr:PetDevRedState(val)
end

function UIPetDevourView:HasPlayerKey()
	if Players.HasKey("QMenu") then
		local qValue = Players.GetString("QMenu")
		self.QMenu.value = qValue
	end
	if Players.HasKey("SMenu") then
		local sValue = Players.GetString("SMenu")
		self.SMenu.value = sValue
	end
end

function UIPetDevourView:UpdateSelect(value)
	local qMenu = self.QMenu.value
	local sMenu = self.SMenu.value
	Players.SetString("QMenu", qMenu)
	Players.SetString("SMenu", sMenu)
	if self.ItemList == nil or self.ItemCount == nil or self.ItemCount == 0 then return end
	local quality = ItemQuality.All
	local wearRank = ItemStep.All	
	local star = 0
	local qi = self.QMenu.items:IndexOf(self.QMenu.value)
	local si = self.SMenu.items:IndexOf(self.SMenu.value)
	if qi >= 0 then quality = self.QMenuValue[qi + 1] end
	if si >= 0 then wearRank = self.SMenuValue[si + 1] end
	if self.Star.value == true then star = 1 end
	Players.SetInt("IntQ", quality)
	Players.SetInt("IntS", wearRank)
	for i=1, self.ItemCount do
		local pro = self.ItemList[i]
		if pro then
			local key = tostring(pro.type_id)
			local temp = ItemData[key]
			local equip = EquipBaseTemp[key]
			local cell = self.Items[tostring(i-1)]
			if temp and cell and cell.trans then
				cell:UpData(temp, pro.num)
				if equip then
					if not value then
						local status = nil
						if (temp.quality <= quality or quality == ItemQuality.All) and (equip.wearRank <= wearRank or wearRank == ItemStep.All) then
							if not equip.startLv or star >= equip.startLv then
								status = true
							end
						end
						self:OnClickItem(cell.trans.gameObject, status, true)
					elseif value then
						self:OnClickItem(cell.trans.gameObject, value)
					end
				else 
					local v = value
					if not v then v = true end
					self:OnClickItem(cell.trans.gameObject, v, true)
				end
			end		
		end
	end
end

--[[#################################################################################################################]]--

function UIPetDevourView:OnClickItem(go, value, change)
	if not self.ItemList then return end
	local str = string.gsub(go.name, "Item_", "")
	if str == nil then
		return
	end
	local index = tonumber(str)
	if index == nil then
		return
	end
	local key = tostring(index)
	index = index + 1
	local pro = self.ItemList[index]
	if pro then
		local cost = 0
		local typeid = tostring(pro.type_id) 
		local temp = EquipBaseTemp[typeid]
		if temp then 
			cost = temp.petExp 
		else 
			temp = ItemData[typeid]
			if temp and temp.uFxArg then
				if temp.uFxArg[1] ~= nil then
					cost = temp.uFxArg[1] * pro.num
				end
			end
		end
		local go = self.UseItems[key]
		if not LuaTool.IsNull(go) then
			if not value then value = false
			elseif value == true and change == nil then value = not value end
			go:SetActive(value)
			if value == false then
				go.transform.parent = nil
				Destroy(go)
				self.UseItems[key] = nil
				self.useEffectValue = self.useEffectValue - cost
			end
		else
			if value == true then
				if  self.Items ~= nil and self.Items[key] and self.ItemList ~= nil and self.ItemCount >= index then
					local go = GameObject.Instantiate(self.SelectP)
					local trans = go.transform
					trans.parent = self.Items[key].trans
					trans.localScale = Vector3.one
					trans.localPosition = Vector3.zero
					self.UseItems[key] = go
					self.UseItems[key]:SetActive(true)
					self.useEffectValue = self.useEffectValue + cost
				end
			end
		end

		local vipLv = VIPMgr.vipLv
		if vipLv == nil or vipLv <= 0 then
			return
		end
		local vipCfg = VIPLv[vipLv+1]
		local vipDes = ""
		if self.VipDesLab and vipCfg.arg18 then
			vipDes = string.format("[ee9a9e]V%s吞噬经验加成[-][67cc67]+%s%s[-]",vipLv,vipCfg.arg18/100,"%")
		end
		local rate = self.addRate
		if rate == nil then
			rate = 0
		end
		local curVal = self.useEffectValue*(1+rate)
		curVal = math.ceil(curVal)
		if self.GetStepExp then
			self.GetStepExp.text = tostring(curVal)
		end
	end
end

--[[#################################################################################################################]]--

function UIPetDevourView:OnClickBtn(go)
	if self.UseItems == nil or LuaTool.Length(self.UseItems) == 0 then 
		UITip.Error("请选择需要吞噬精华的装备")
		return
	end
	local list = {}
	for k,v in pairs(self.UseItems) do
		local i = tonumber(k)
		i = i + 1
		if self.ItemList[i] then	
			table.insert(list, self.ItemList[i])
		end
	end
	PetMgr:ReqPetLevelUp(list)
	self.curPropCount = #self.ItemList - #list
	self.CloseCB()
	self:OnClickMask()
end

--function UIPetDevourView:OnClickASBtn(go)
--	self:UpdateSelect(true)
--end

function UIPetDevourView:OnClickMask(go)
	self.curPropCount = nil
	self:CleanCells()
	self:SetActive(false)
end

--[[#################################################################################################################]]--


--增加关联Cell
function UIPetDevourView:AddCell(key, go)
	self.Items[key] = ObjPool.Get(UIItemCell)
	self.Items[key]:Init(go)
	UIEventListener.Get(go).onClick = function(gameobject) 
		self:OnClickItem(gameobject, true)  
	end
end

--[[#################################################################################################################]]--

function UIPetDevourView:CleanCells()
	TableTool.ClearDic(self.ItemList)
	for k,v in pairs(self.UseItems) do
		v.transform.parent = nil
		Destroy(v)
		self.UseItems[k] = nil
	end
	self.useEffectValue = 0
	self:Super('CleanCells')
end

--更新等级经验
function UIPetDevourView:UpdateLvExp()
	local lv = self.pMgr.Level
	if not lv then lv = 1 end
	if self.Lv then self.Lv.text = tostring(lv) .. "级" end
	local exp = self.pMgr.Exp
	local limit = self.pMgr.LimitExp
	if limit == 0 then limit = 1 end
	local colorStr = exp < limit and "[e83030]" or "[00ff00]"
	if self.Exp then
		-- self.Exp.text = string.format("[00ff00]%s[-]/%s", exp, limit)
		self.Exp.text = colorStr .. exp .. "[-]" .. "/" .. limit
	end
	local value = exp / limit
	if self.ExpSlider then
		self.ExpSlider.fillAmountValue = value
	end
	local vipLv = VIPMgr.vipLv
	if vipLv == nil or vipLv <= 0 then
		return
	end
	local vipCfg = VIPLv[vipLv+1]
	local vipDes = ""
	local addRate = 0
	if self.VipDesLab and vipCfg.arg18 then
		addRate = vipCfg.arg18/10000
		vipDes = string.format("[ee9a9e]V%s吞噬经验加成[-][67cc67]+%s%s[-]",vipLv,vipCfg.arg18/100,"%")
	end
	self.addRate = addRate
	self.VipDesLab.text = vipDes
end

function UIPetDevourView:Open()
	EventDelegate.Add(self.QMenu.onChange,  self.MenuCb)
	EventDelegate.Add(self.SMenu.onChange,  self.MenuCb)
end

function UIPetDevourView:Close()
	if self.MenuCb then
		EventDelegate.Remove(self.QMenu.onChange,  self.MenuCb)
		EventDelegate.Remove(self.SMenu.onChange,  self.MenuCb)
	end
end

function UIPetDevourView:Dispose(isDestory)
	self:Super('Dispose',isDestory)
	self:RemoveEvent()
	TableTool.ClearDic(self.QMenuValue)
	TableTool.ClearDic(self.SMenuValue)
	self.QMenuValue = nil
	self.SMenuValue = nil
	self.ExpSlider = nil
	self.Exp = nil
	self.Lv = nil
	self.pMgr = nil
	self.sView = nil
	self.VipDesLab = nil

	self.Btn = nil
	self.GetStepExp = nil
	self.ScrollLimit = nil
	self.MinCount = nil
	self.UseItems = nil
	self.ItemList = nil
	self.useEffectValue = nil
	self.ItemCount = nil
	self.addRate = nil
end
--endregion

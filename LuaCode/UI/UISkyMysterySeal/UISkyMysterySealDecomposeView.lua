--region UISkyMysterySealDecomposeView.lua
--Date
--此文件由[HS]创建生成



UISkyMysterySealDecomposeView = baseclass(UIScrollViewBase)

local Players = UnityEngine.PlayerPrefs

local bufferKey = "SMSDMenu"

function UISkyMysterySealDecomposeView:Ctor(go)
	local name = "天机印分解"	
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = self.trans
	local name = self.Name
	self.CloseBtn = T(trans, "closeBtn")
	self.Btn = C(UIButton, trans, "Button", name, false)
	self.ItemRoot = T(trans, "ItemRoot")
	self.GetStepExp = C(UILabel, trans, "GetExp", name, false)
	self.SelectP = T(trans, "Select")
	
	self.QMenu = ObjPool.Get(UIPopDownMenu)
	local bNs = {"无", "蓝色及以下","紫色及以下","紫1星及以下","橙1星及以下","橙2星及以下","红1星及以下","红2星及以下","红3星及以下"}
	local icons = {"","depot_b","depot_p", "depot_y", "massage", "star_light","star_light","star_light","star_light"}
	self.QMenu.MAX_SHOW_BTN_NUM = #bNs
	self.QMenu:Init(T(trans, "QualityMenu"),bNs[1], bNs, 46, function(fIndex) self:Change(fIndex) end,true, "Icon", icons)

	self.Toggle = C(UIToggle, trans, "Toggle", name, false)

	self.ScrollLimit = 7
	self.MinCount = 28
	self.UseItems = {}
	self.ItemList = {}
	self.useEffectValue = 0

	self.sView = C(UIPanel, trans, "ScrollView")
	EventDelegate.Set(self.Toggle.onChange, EventDelegate.Callback(function() self:OnChangeTog() end))
	return self
end

function UISkyMysterySealDecomposeView:OnChangeTog()
	local qMenu = 0
	if self.Toggle.value == true then
		qMenu = self.QMenu.curClickIndex + 1
		local data = SMSMgr.DecomposeMenu[qMenu]
		SMSNetwork:ReqOptTos(data.quality, data.star)
	end
end

function UISkyMysterySealDecomposeView:Init()
	self:UpdateItems(self.MinCount)
	self:AddEvent()
	self.QMenu:SynBtnIndexShow(1)
	self:HasPlayerKey()

	local item = ItemData[tostring(SMSMgr.CostItem)]
	if item then
		self.Cell = ObjPool.Get(UIItemCell)
		self.Cell:InitLoadPool(self.ItemRoot.transform)
		self.Cell:UpData(item)
	end

	self.curPropCount = nil
end

function UISkyMysterySealDecomposeView:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Btn then
		E(self.Btn, self.OnClickBtn, self)
	end
	if self.CloseBtn then
		E(self.CloseBtn, self.OnClickMask, self)
	end
	self:SetEvent("Add")
end

function UISkyMysterySealDecomposeView:SetEvent(fn)
end

function UISkyMysterySealDecomposeView:RemoveEvent()
	self:SetEvent("Remove")
end

function UISkyMysterySealDecomposeView:UpdateData()
	if self.gameObject.activeSelf == false then return end
	self:CleanCells()
	local getExp = self.GetStepExp
	if getExp then getExp.text = tostring(self.useEffectValue) end
	--self.ItemList = SMSMgr.WarehouseInfos
	local list = self.ItemList
	SMSMgr:GetDecomposeItems(list, -1)
	if #list > 1 then
		table.sort(list,function(a, b) return SMSMgr:DSort(a,b) end)
	end
	if list == nil or #list==0 then return end
	if not list then 
		self.UseItems = {}
		self:CleanCells()
		return 
	end 
	self.ItemCount = #list
	self:CheckItemsCount(self.ItemCount)
	self:UpdateSelect()
	local toggle = self.Toggle
	if toggle then toggle.value = SMSMgr.DecomposeQuality > 0 end
	self:GridReposition()
end

function UISkyMysterySealDecomposeView:Change()
	self:UpdateSelect()
	self:OnChangeTog()
end

function UISkyMysterySealDecomposeView:HasPlayerKey()
	local qValue = SMSMgr:GetDecomposeData()
	if qValue > 0 then
		self.QMenu:SynBtnIndexShow(qValue)
	end
	self.Toggle.value  = qValue > 0
end

function UISkyMysterySealDecomposeView:UpdateSelect(value)
	local qMenu = self.QMenu.curClickIndex + 1
	local selectInfo = SMSMgr.DecomposeMenu[qMenu]
	if self.ItemList == nil or self.ItemCount == nil or self.ItemCount == 0 then return end
	local quality = selectInfo.quality
	local star = selectInfo.star
	for i=1, self.ItemCount do
		local pro = self.ItemList[i]
		if pro then
			local key = tostring(pro.type_id)
			local temp = ItemData[key]
			local cell = self.Items[tostring(i-1)]
			if temp and cell and cell.trans then
				cell:UpData(temp, pro.num)
				cell:UpdateIconArr(false)
				local status = nil
				local sms = SMSProTemp[tostring(temp.id)]
				if sms then
					if sms.quality < quality  then
						status = true
					elseif sms.quality == quality then				
						if sms.star <= star then
							status = true
						end
					end
				end
				self:OnClickItem(cell.trans.gameObject, status, true)
			end	
			local sms = SMSProTemp[key]
			if sms and sms.index ~= 999 then
				local status = SMSMgr:GetScoreCompare(pro.type_id)
				if status == -1 then
				end
			end	
		end
	end
end

--[[#################################################################################################################]]--

function UISkyMysterySealDecomposeView:OnClickItem(go, value, change)
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

		local temp = ItemData[typeid]
		if temp and temp.uFxArg then
			if temp.uFxArg[1] ~= nil then
				cost = temp.uFxArg[1] * pro.num
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
		if self.GetStepExp then
			self.GetStepExp.text = string.format( "[99886B]%s[-] [00ff00]+ %s[-]", SMSMgr.CostNum, tostring(self.useEffectValue)) 
		end
	end
end

--[[#################################################################################################################]]--

function UISkyMysterySealDecomposeView:OnClickBtn(go)
	if self.UseItems == nil or LuaTool.Length(self.UseItems) == 0 then 
		UITip.Error("请选择需要吞噬精华的装备")
		return
	end
	local list = {}
	for k,v in pairs(self.UseItems) do
		local i = tonumber(k)
		i = i + 1
		if self.ItemList[i] then	
			table.insert(list, self.ItemList[i].id)
		end
	end
	SMSNetwork:ReqGoodsRefineTos(list)
	self.curPropCount = #self.ItemList - #list
	--self:OnClickMask()
end

function UISkyMysterySealDecomposeView:OnClickMask(go)
	self.curPropCount = nil
	self:CleanCells()
	self:SetActive(false)
end

--[[#################################################################################################################]]--


--增加关联Cell
function UISkyMysterySealDecomposeView:AddCell(key, go)
	self.Items[key] = ObjPool.Get(UIItemCell)
	self.Items[key]:Init(go)
	UIEventListener.Get(go).onClick = function(gameobject) 
		self:OnClickItem(gameobject, true)  
	end
end

--[[#################################################################################################################]]--

function UISkyMysterySealDecomposeView:CleanCells()
	TableTool.ClearDic(self.ItemList)
	for k,v in pairs(self.UseItems) do
		v.transform.parent = nil
		Destroy(v)
		self.UseItems[k] = nil
	end
	self.useEffectValue = 0
	self:Super('CleanCells')
end

function UISkyMysterySealDecomposeView:Open()
end

function UISkyMysterySealDecomposeView:Close()
end

function UISkyMysterySealDecomposeView:Dispose(isDestory)
	self:Super('Dispose',isDestory)
	self:RemoveEvent()
	if self.Cell then
		self.Cell:DestroyGo()
		ObjPool.Add(self.Cell)
	end
	self.sView = nil

	if self.QMenu then
		ObjPool.Add(self.QMenu);
		self.QMenu = nil;
	end

	self.Btn = nil
	self.GetStepExp = nil
	self.ScrollLimit = nil
	self.MinCount = nil
	self.UseItems = nil
	self.ItemList = nil
	self.useEffectValue = nil
	self.ItemCount = nil
end
--endregion

--region UIPicCollectDevourView.lua
--Date
--此文件由[HS]创建生成



UIPicCollectDevourView = baseclass(UIScrollViewBase)

local Players = UnityEngine.PlayerPrefs

local bufferKey = "PCQMenu"

local PCMgr = PicCollectMgr

function UIPicCollectDevourView:Ctor(go)
	local name = "UI伙伴吞噬装备窗口"	
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
	local bNs = {"蓝色及以下","紫色及以下", "橙色及以下", "红色及以下", "粉色及以下"}
	local icons = {"depot_b","depot_p", "depot_y", "massage", "star_light"}
	self.QMenu.MAX_SHOW_BTN_NUM = #bNs
	self.QMenu:Init(T(trans, "QualityMenu"),bNs[1], bNs, 46, function(fIndex) self:Change(fIndex) end,true, "Icon", icons)

	self.ScrollLimit = 8
	self.MinCount = 32
	self.UseItems = {}
	self.ItemList = {}
	self.useEffectValue = 0

	self.sView = C(UIPanel, trans, "ScrollView")

	return self
end

function UIPicCollectDevourView:Init()
	self:UpdateItems(self.MinCount)
	self:AddEvent()
	self.QMenu:SynBtnIndexShow(ItemQuality.Blue - 2)
	self:HasPlayerKey()

	local item = ItemData["17"]
	if item then
		self.Cell = ObjPool.Get(UIItemCell)
		self.Cell:InitLoadPool(self.ItemRoot.transform)
		self.Cell:UpData(item)
	end

	self.curPropCount = nil
end

function UIPicCollectDevourView:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Btn then
		E(self.Btn, self.OnClickBtn, self)
	end
	if self.CloseBtn then
		E(self.CloseBtn, self.OnClickMask, self)
	end
	self:SetEvent("Add")
end

function UIPicCollectDevourView:SetEvent(fn)
end

function UIPicCollectDevourView:RemoveEvent()
	self:SetEvent("Remove")
end

function UIPicCollectDevourView:Sort(a, b)
	local ai = ItemData[tostring(a.type_id)]
	local bi = ItemData[tostring(b.type_id)]
	local astatus = 0 
	local bstatus = 0 
	local aCheck = TableTool.Contains(PCMgr.PicEXP, ai.id)
	local bCheck = TableTool.Contains(PCMgr.PicEXP, bi.id)
	if aCheck ~= bCheck then
		return aCheck> bCheck
	end
	local apic = PCMgr:GetPicForId(a.type_id)
	if apic then
		if apic.star >= PCMgr.FullStar and apic.lv >= PCMgr.FullLv then
			astatus = 1
		end
	end
	local bpic = PCMgr:GetPicForId(b.type_id)
	if bpic then
		if bpic.star >= PCMgr.FullStar and bpic.lv >= PCMgr.FullLv then
			bstatus = 1
		end
	end
	if astatus ~= bstatus then
		return astatus < bstatus
	end
	return ai.quality>bi.quality
end

function UIPicCollectDevourView:UpdateData()
	if self.gameObject.activeSelf == false then return end
	self:CleanCells()
	if self.GetStepExp then self.GetStepExp.text = tostring(self.useEffectValue) end
	local list = self.ItemList
	PropMgr.UseGetDic(list, {PCMgr.ResolveUseEff})
	PCMgr:ResolveFilter(list)
	if #list > 1 then
		table.sort(list,function(a, b) return self:Sort(a,b) end)
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
	self:GridReposition()
end

function UIPicCollectDevourView:Change()
	self:UpdateSelect()
	-- body
end

function UIPicCollectDevourView:HasPlayerKey()
	if Players.HasKey(bufferKey) then
		local qValue = Players.GetInt(bufferKey)
		if qValue ~= "number" then return end
		self.QMenu:SynBtnIndexShow(qValue)
	end
end

function UIPicCollectDevourView:UpdateSelect(value)
	local qMenu = self.QMenu.curClickIndex + 2
	Players.SetInt(bufferKey, qMenu)
	if self.ItemList == nil or self.ItemCount == nil or self.ItemCount == 0 then return end
	local quality = ItemQuality.White
	if qMenu and qMenu> 0 then quality = qMenu end
	for i=1, self.ItemCount do
		local pro = self.ItemList[i]
		if pro then
			local key = tostring(pro.type_id)
			local temp = ItemData[key]
			local cell = self.Items[tostring(i-1)]
			if temp and cell and cell.trans then
				cell:UpData(temp, pro.num)
				local status = nil
				if TableTool.Contains(PCMgr.PicEXP, temp.id) ~= -1 then
					status = true
				else
					if (temp.quality <= quality or quality == ItemQuality.All) then
						local pic = PCMgr:GetPicForId(temp.id)
						if pic then
							if pic.star >= PCMgr.FullStar and pic.lv >= PCMgr.FullLv then
								status = true
							end
						end
					end
				end
				self:OnClickItem(cell.trans.gameObject, status, true)
			end		
		end
	end
end

--[[#################################################################################################################]]--

function UIPicCollectDevourView:OnClickItem(go, value, change)
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

		local temp = PicCollectCostTemp[typeid]
		if temp then 
			cost = temp.cost * pro.num
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
		if self.GetStepExp then
			self.GetStepExp.text = tostring(self.useEffectValue)
		end
	end
end

--[[#################################################################################################################]]--

function UIPicCollectDevourView:OnClickBtn(go)
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
	PCMgr:ReqResolvePic(list)
	self.curPropCount = #self.ItemList - #list
	self:OnClickMask()
end

function UIPicCollectDevourView:OnClickMask(go)
	self.curPropCount = nil
	self:CleanCells()
	self:SetActive(false)
end

--[[#################################################################################################################]]--


--增加关联Cell
function UIPicCollectDevourView:AddCell(key, go)
	self.Items[key] = ObjPool.Get(UIItemCell)
	self.Items[key]:Init(go)
	UIEventListener.Get(go).onClick = function(gameobject) 
		self:OnClickItem(gameobject, true)  
	end
end

--[[#################################################################################################################]]--

function UIPicCollectDevourView:CleanCells()
	TableTool.ClearDic(self.ItemList)
	for k,v in pairs(self.UseItems) do
		v.transform.parent = nil
		Destroy(v)
		self.UseItems[k] = nil
	end
	self.useEffectValue = 0
	self:Super('CleanCells')
end

function UIPicCollectDevourView:Open()
end

function UIPicCollectDevourView:Close()
end

function UIPicCollectDevourView:Dispose(isDestory)
	self:Super('Dispose',isDestory)
	self:RemoveEvent()
	if self.Cell then
		self.Cell:DestroyGo()
		ObjPool.Add(self.Cell)
	end
	self.PCMgr = nil
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

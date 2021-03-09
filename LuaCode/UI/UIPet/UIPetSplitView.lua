--region UIPetSplitView.lua
--Date
--??ļ??[HS]???????


UIPetSplitView = baseclass(UIScrollViewBase)


function UIPetSplitView:Ctor(go, isActiveCallback)
	self.Name = "UIPetSplitView"
	self.IsActiveCallback = isActiveCallback
	local C = ComTool.Get

	self.CloseBtn = C(UIButton, self.trans, "CloseBtn", self.Name, false)
	self.Btn = C(UIButton, self.trans, "Button", self.Name, false)
	self.GetStepExp = C(UILabel, self.trans, "GetExp", self.Name, false)
	self.CurItemData = nil
	self.CurItemCell = nil
	self.ScrollLimit = 8
	self.MinCount = 32
	return this
end

function UIPetSplitView:Init()
	self:UpdateItems(self.MinCount)
	self:UpdateData()
	self:AddEvent()
end


function UIPetSplitView:AddEvent()
	if self.CloseBtn then
		UIEvent.Get(self.CloseBtn.gameObject).onClick = function(gameObject) self:OnClickCloseBtn(gameObject) end
	end
	if self.Btn then
		UIEvent.Get(self.Btn.gameObject).onClick = function(gameObject) self:OnClickBtn(gameObject) end
	end
end

function UIPetSplitView:UpdateData()
	self:CleanCells()
	self.ItemList = PropMgr:GetFTb(4)
	if not self.ItemList then 
		self.CurItemCell = nil
		return 
	end 
	self:CheckItemsCount(self.ItemList.Count)
	self:UpdateItemData()
	self:GridReposition()
	if self.Items and self.Items["0"] then self:OnClickItem(self.Items["0"].gameObject) end
end

function UIPetSplitView:UpdateItemData()
	if self.ItemList == nil or self.ItemList.Count == 0 then return end
	for i=0,self.ItemList.Count - 1 do
		local key = tostring(self.ItemList[i].type_id)
		local item = ItemData[key]
		if self.Items[tostring(i)] and item then
			self.Items[tostring(i)]:UpdateIcon(item.icon)
			self.Items[tostring(i)]:UpdateLabel(self.ItemList[i].num)
			self.Items[tostring(i)]:UpdateQuality(item.quality)
		end
	end
end

--[[#################################################################################################################]]--

function UIPetSplitView:OnClickItem(go)
	local str = string.gsub(go.name, "Item_", "")
	local index = tonumber(str)
	if self.ItemList.Count == 0 or self.ItemList.Count <= index then 
		self.CurItemCell = nil
		return 
	end
	if self.CurItemCell ~= nil and self.CurItemCell.gameObject.name ~= go.name then
		self.CurItemCell:IsSelect(false)
	end
	local key = tostring(self.ItemList[index].type_id)
	local item = ItemData[key]
	if self.Items[tostring(index)] and self.ItemList[index] and item then
		local useEffectValue = 0
		if item.uFxArg[1] then
			useEffectValue = item.uFxArg[1]
		end
		useEffectValue = self.ItemList[index].num * useEffectValue
		self.GetStepExp.text = tostring(useEffectValue)
		self.CurItemData = self.ItemList[index]
		self.CurItemCell = self.Items[tostring(index)]
		self.CurItemCell:IsSelect(true)
	end
end

function UIPetSplitView:OnClickBtn(go)
	if self.CurItemData == nil then 
		UITip.Error("请选择需要分解精华的道具")
		return
	end
	NetworkMgr.ReqUseItem(self.CurItemData.id, self.CurItemData.num)
end

function UIPetSplitView:OnClickCloseBtn(go)
	self:CleanCells()
	self:SetActive(false)
	if self.IsActiveCallback then self.IsActiveCallback(true) end
end

--[[#################################################################################################################]]--


--增加关联Cell
function UIPetSplitView:AddCell(key, go)
	self.Items[key] = UICellSelect.New(go)
	self.Items[key]:Init()
end

--[[#################################################################################################################]]--


function UIPetSplitView:CleanCells()
	self:Super('CleanCells')
	self.CurItemData = nil
	self.CurItemCell = nil
end

function UIPetSplitView:Dispose(isDestory)
	self.CurItemData = nil
	self.CurItemCell = nil
	self:Super('isDestory')
end
--endregion

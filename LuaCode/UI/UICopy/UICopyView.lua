--region UICopyView.lua
--Date	
--此文件由[HS]创建生成

UICopyView = Super:New{Name = "UICopyView"}
local M = UICopyView

function M:Init(go)
	local name = self.Name
	self.go = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Panel = C(UIScrollView, trans, "CopyList", name, false)
	self.Grid = C(UIGrid, trans, "CopyList/Grid", name, false)
	self.Prefab = T(trans, "CopyList/Grid/Item")

	self.Rect = ObjPool.Get(UICopyRect)
	self.Rect:Init(T(trans, "Rect"))

	self.Items = {}
	self.SelectItem = nil
	self:InitData()
end

function M:Open()
	if not self.copyType then
		self:CustomOpen(CopyType.Exp)
	end
	self.go:SetActive(true)
end

function M:Close()
	self.go:SetActive(false)
end


function M:IsActive()
	return self.go.activeSelf
end

function M:InitData()
	local list = CopyMgr.Copy
	if not list then return end
	self:AddTypeItem(CopyMgr.Exp, 1)
	self:AddTypeItem(CopyMgr.STD, 2)
	self:AddTypeItem(CopyMgr.Glod, 3)
	-- self:AddTypeItem(CopyMgr.ZLT, 5)
	self:AddTypeItem(CopyMgr.XH, 4)
end

function M:AddTypeItem(key, index)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = key
	local trans = go.transform
	trans.parent = self.Grid.transform
	trans.localScale = Vector3.one
	trans.localPosition = Vector3.zero
	go:SetActive(true)
	local item = ObjPool.Get(UICellCopyItem)
	item:Init(go, index)
	self.Items[key] = item
	UITool.SetLsnrSelf(go, self.ClickItems, self, nil, false)
	self:UpdateItems(key)
end

function M:UpdateRedPoint(_type, bool)
	self.Items[tostring(_type)]:UpdateRedPoint(bool)
end

function M:GetAllRedPointState()
	local items = self.Items
	for k,v in pairs(items) do
		if v:GetRedPointActive() then
			return true
		end
	end
	return false
end

function M:UpdateItems(key)
	local info = CopyMgr:GetCurCopy(key)
	if not self.Items then return end
	local item = self.Items[key]
	item:UpdateInfo(info)
end



function M:CustomOpen(copyType)
	if not copyType then return end
	local items = self.Items
	if not items then return end
	local item = items[tostring(copyType)]
	if item then
		self.copyType = copyType
		self:ClickItems(item.GO)
	end
end

function M:ClickItems(go)
	local key = go.name
	local item = self.Items[key]
	if not item then return end
	if item:IsOpen() == false then
		return 
	end
	if self.SelectItem then
		if self.SelectItem.GO.name == item.GO.name then
			return
		end
		self.SelectItem:IsSelect(false)
	end
	self.SelectItem = item
	self.copyType = tonumber(key)
	item:IsSelect(true)
	if self.Rect then
		self.Rect:UpdateData(item.Info, item.Temp)
	end
end

function M:UpdateCopyData(t)
	local item = self.Items[tostring(t)]
	if item then
		item:UpdateRealInfo()
	end
	local rect = self.Rect
	if rect then
		rect:UpdateView()
	end
end

function M:UpdateCopyExpGuideTimes()
	local rect = self.Rect
	if rect then
		rect:UpdateCopyExpGuideTimes()
	end
end

function M:UpdateUserLv()
	local items = self.Items
	if not items then return end
	for k,v in pairs(items) do
		v:UpdateRealInfo()
	end
	local item = self.SelectItem
	if not item then
		item = items[tostring(CopyMgr.Exp)]
	end
	if item and self.Rect then
		self.Rect:UpdateData(item.Info, item.Temp)
	end
end

function M:Dispose()
	self.SelectItem = nil
	if self.Rect then
		ObjPool.Add(self.Rect)
	end
	self.Rect = nil
	TableTool.ClearDicToPool(self.Items)
	self.Items = nil
	self.copyType = nil
end

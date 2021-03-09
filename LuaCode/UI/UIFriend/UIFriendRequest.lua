--region UIFriendRequest.lua
--好友请求列表
--此文件由[HS]创建生成

require("UI/UIFriend/UIFriendRequestItem")

UIFriendRequest = UIBase:New{Name ="UIFriendRequest"}
local M = UIFriendRequest

local fMgr = FriendMgr

M.BufferItems = {}
M.Items = {}

function M:InitCustom()
	local name = "好友请求列表"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Panel = C(UIPanel, trans, "ScrollView", name, false)
	self.SV = C(UIScrollView, trans, "ScrollView", name, false)
	self.Grid = C(UIGrid, trans, "ScrollView/Grid", name, false)
	self.Prefab = T(trans, "ScrollView/Grid/Item", name, false)
	self.DefaultPos = self.Panel.transform.localPosition
	self:InitBufferItems()
	self.Add = C(UIButton, trans, "Add", name, false)
	self.Remove = C(UIButton, trans, "Remove", name, false)
	self.CloseBtn = C(UIButton, trans, "Close", name, false)
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Add then	
		E(self.Add, self.OnClickAdd, self)
	end
	if self.Remove then	
		E(self.Remove, self.OnClickRemove, self)
	end
	if self.CloseBtn then
		E(self.CloseBtn, self.OnClickCloseBtn, self)
	end
end

function M:RemoveEvent()
end

function M:OnClickAdd(go)
	local items = self.Items
	local limit = fMgr.FirendLimit
	local friendNum = #fMgr.FriendList
	local len = #items
	local addNum = 0
	local isTip = true
	while len > 0 do
		local item = self.Items[len]
		if friendNum + addNum < limit then
			item:OnClickAdd()
		else
			if isTip == true then
				isTip = false
				UITip.Error(string.format("好友数量已达到上限：%s人", limit))
			end
			item:OnClickRemove()
		end
		table.remove(self.Items, len)
		table.insert(self.BufferItems, item)
		len = #self.Items
		addNum = addNum + 1
	end
	UITip.Error("已全部同意")
	self:OnClickCloseBtn(nil)
end

function M:OnClickRemove(go)
	local items = self.Items
	local len = #items
	while len > 0 do
		local item = self.Items[len]
		item:OnClickRemove()
		table.remove(self.Items, len)
		table.insert(self.BufferItems, item)
		len = #self.Items
	end
	UITip.Error("已全部拒绝")
	self:OnClickCloseBtn(nil)
end

function M:OnClickCloseBtn(go)
	self:Close()
end

function M:InitBufferItems()
	local buffer = self.BufferItems
	for i=1,50 do
		self:AddItem(i, buffer)
	end
end

function M:AddItem(index, buffer)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = tostring(index)
	go.transform.parent = self.Grid.transform
	go.transform.localScale = Vector3.one
	go.transform.localPosition = Vector3.zero
	local data = ObjPool.Get(UIFriendRequestItem)
	data.Base = self
	data:Init(go)
	table.insert(buffer, data)
end

function M:GridReposition()
	local grid = self.Grid
	if grid then
		grid:Reposition()
	end
	local sv = self.SV
	if sv then
		if #self.Items > 3 then
			sv.isDrag = true
		else
			sv.isDrag = false
		end
	end
	local panel = self.Panel
	if panel then
		panel.transform.localPosition = self.DefaultPos
		if panel then
			panel.clipOffset = Vector2.zero
		end
	end
end

-----------------------更新数据----------------------------
function M:UpdateData()
	local list = fMgr.RequestList
	local num = #list
	local buffer = self.BufferItems
	local curNum = #buffer
	if num > curNum then
		for i= curNum + 1,num do
			self:AddItem(i, buffer)
		end
	end 
	for i=1,num do
		local pos = #buffer
		local item = buffer[pos]
		item:UpdateData(list[i])
		table.remove(buffer, pos)
		table.insert(self.Items, item)
	end
	self:GridReposition()
end



function M:Clear()
	local len = #self.Items
	while len > 0 do
		local item = self.Items[len]
		item:Clear()
		table.remove(self.Items, len)
		table.insert(self.BufferItems, item)
		len = #self.Items
	end
end
-----------------------------------------------

function M:OpenCustom()
	self:UpdateData()
end

function M:CloseCustom()
	self:Clear()
end

--释放或销毁
function M:DisposeCustom()
	self:RemoveEvent()
end
--endregion
return M

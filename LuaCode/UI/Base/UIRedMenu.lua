--region UIRedMenu.lua
--Date
--此文件由[HS]创建生成

UIRedMenu = UIBase:New{Name ="UIRedMenu"}
local M = UIRedMenu
M.eClickMenu = Event()
M.Items = {}
M.CustomIndex = {}

M.LimitPos = Vector3.New(0, -1.4, 0)
M.LimitRect = Vector4.New(0,0, 190, 260)
--[[
M.Offset = 29.5
M.cellH = 65
M.LimitBgSize = Vector2.New(207, 318)
]]--

--注册的事件回调函数

function M:InitCustom()
	self.Persitent = true;
	local name = "红点面板"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.BG = T(trans, "BG")
	self.anchor = C(UIWidget,trans, "BG",name)
	self.oriLeft = self.anchor.leftAnchor.absolute
	self.oriRight = self.anchor.rightAnchor.absolute
	self.SV = C(UIScrollView, trans, "BG/Scroll View", name, false)
	self.Panel = C(UIPanel, trans, "BG/Scroll View", name, false)

	self.Container = T(trans, "Container")
--	self.Background = C(UISprite, trans, "Container/Sprite", name, false)
--	self.Tip = self.Background.gameObject.transform

	self.Grid = C(UIGrid, trans, "BG/Scroll View/Grid", name, false)
	self.Prafab = T(trans, "BG/Scroll View/Grid/Item")

	for i=1,30 do
		self:AddItem(i)
	end
	self:AddEvent()
	self:ScreenChange(ScreenMgr.orient, true)
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Container then
		E(self.Container,self.OnClickContainer, self, nil, false)
	end
	
end
function  M:SetEvent(fn)
	ScreenMgr.eChange[fn](ScreenMgr.eChange, self.ScreenChange, self)
end

function M:RemoveEvent()
end

function M:ScreenChange(orient, init)
	local reset = not UITool.IsResetOrient(orient)
	rReset = not reset
	UITool.SetLiuHaiAbsolute(self.hrWidget, true, rReset, self.hrOriLeft,self.hrOriRight, -1)
end

function M:ShowMenu()
	local indexs = self.CustomIndex
	local len = #indexs
	if len > 1 then 
		table.sort(indexs,function(a,b)
        	return a < b
		end)
	end
	self:UpdateItems(len)
	for i=1,len do
		local temp = StrengthenTemp[indexs[i]]
		if temp then
			self:UpdateUIData(i, temp)
		end
	end
	self:GridRepositionlen(len)
end

function M:UpdateItems(len)
	local iLen = #self.Items
	if iLen < len then
		for i=iLen,len do
			self:AddItem(i)
		end
	elseif iLen > len then
		for i=len + 1,iLen - 1 do
			self:RemoveItem(i)
		end
	end
end

function M:UpdateUIData(index, temp)
	local items = self.Items
	if not items then return end
	local item = items[index]
	if not item then return end
	item.Name.text = temp.name
	item.Temp = temp
	item.Root.gameObject:SetActive(true)
end

function M:AddItem(index)
	local go = GameObject.Instantiate(self.Prafab)
	go.name = tostring(index)
	local trans = go.transform
	trans.parent = self.Grid.transform
	trans.localPosition = Vector3.zero
	trans.localScale = Vector3.one

	UITool.SetLsnrSelf(go,self.ClickMenu, self, nil, false)
	
	local C = ComTool.Get
	local T = TransTool.FindChild
	local item = {}
	item.Root = go
	item.Name = C(UILabel, trans, "Label", n, false)
	table.insert(self.Items, item)
end

function M:RemoveItem(index)
	local key = tostring(index)
	local item = self.Items[index]
	if not item then return end
	if item.Root then item.Root.gameObject:SetActive(false) end
	if item.Temp then item.Temp = nil end
end

function M:GridRepositionlen(len)
	local panel = self.Panel
	local grid = self.Grid
	local sv = self.SV
	--[[
	local bg = self.Background
	local pos = self.LimitPos
	local rect = self.LimitRect
	local offset = self.Offset 
	if len <= 4 then
		local h = len * self.cellH
		rect = Vector4.New(rect.x, rect.y, rect.z, h)		
	end
	if bg then
		bg.height = rect.w + offset
	end
	]]--
	if sv then
		if len > 4 then
			sv.isDrag = true
		else
			sv.isDrag = false
		end
	end
	if panel then
		panel.transform.localPosition = self.LimitPos
		panel.clipOffset = Vector2.zero
	end
	if grid then
		grid.transform.localPosition = Vector3.New(0,self.LimitRect.w / 2,0)
	end
	if self.Grid then
		self.Grid:Reposition()
	end
end

function M:UpdateAction(index, action)
	local data = self.Items[index]
	if not data then return end
	data.Action:SetActive(action)
end

function M:ClickMenu(go, isPressed)
	if isPressed == true then return end
	local index =  tonumber(go.name)
	local items = self.Items
	if not items then return end
	local item = items[index]
	if not item then return end
	if item.Temp then
		self.eClickMenu(item.Temp)
	end
	self:Close()
end

function M:OnClickContainer(go)
	self:ClearItems()
	self:Close()
end

function M:OpenCustom()
	self:ShowMenu()
end

function M:CloseCustom()
end

function M:ClearItems()
	local items = self.Items
	local len = #items
	for i=1,len do
		self:RemoveItem(i)
	end
end

function M:ClearCustomIndex()
	local indexs = self.CustomIndex
	if not indexs then return end
	local len = #indexs
	while len > 0 do
		table.remove(indexs, len)
		len = #indexs
	end
end

--是否能被记录
function M:CanRecords()
	do return false end
end

function M:DisposeCustom()
	self:RemoveEvent()
end

return M
--endregion

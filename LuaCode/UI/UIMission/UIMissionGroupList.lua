--region UIMission.lua
--Date
--此文件由[HS]创建生成

UIMissionGroupList = Super:New{Name ="UIMissionGroupList"}
local M = UIMissionGroupList
local mMgr = MissionMgr


function M:Init(go, parent)
	self.Root = go
	self.Parent = parent
	local name = "UIMissionGroupList"
	local trans = self.Root.transform
	local T = TransTool.FindChild
	local C = ComTool.Get

	self.SV = C(UIScrollView, trans, "Scroll View", name, false)
	self.Panel = C(UIPanel, trans, "Scroll View", name, false)
	self.Grid = C(UIGrid, trans, "Scroll View/Grid", name, false)
	self.Prefab = T(trans, "Scroll View/Grid/Item")
	self.Items = {}
	self.DefaultPos = self.Panel.transform.localPosition
	for i=1,20 do
		self:AddItem(i)
	end
	self.Num = 0
	self.CurSelect = 0
	self.LastID = 0
end

function M:UpdateDic(dic)
	local list = self:GetList(dic) 
	if not list then return end
	for i=1, #list do
		self:UpdateItem(list[i])
	end
end

function M:UpdateItem(mission)
	self.Num = self.Num + 1
	local item = self.Items[self.Num]
	if item then 
		item:UpdateData(mission) 
		item:SetActive(true)
		if mission.ID == self.LastID then
			self.LastID  = 0
			self.CurSelect = self.Num
			self:ClickItem(item.Root)
		else
			self:UpdateSelect(self.Num, false)
		end
	end
end

function M:UpdateItems()
	local items = self.Items
	local len = #items
	if not len or len == 0 then return end
	for i=1,len do
		local item = items[i]
		if item and item.Miss then
			local id = item.Miss.ID
			local miss = mMgr:GetMissionForID(id)
			if miss then
				item:UpdateData(miss) 
				if item:IsSelect() == true then
					self:ClickItem(item.Root)
				end
			end
		end
	end
end

function M:GetList(dic)
	if not dic then return nil end
	local list = {}
	for k,v in pairs(dic) do
		if v.Temp then
			if v.Temp.type == MissionType.Feeder and v.Temp.childType ~= nil then
			else
				table.insert(list, v)
			end
		end
	end
	if #list > 1 then
		table.sort(list,function (am,bm)
			if am and bm then
				local aid = am.ID
				local bid = bm.ID
				if am.Status == MStatus.ALLOW_SUBMIT then
					ac = 4
				elseif am.Status == MStatus.NOT_RECEIVE then
					if am:CheckLevel() == false then
						ac = 3
					else
						ac = 1
					end
				elseif am.Status == MStatus.EXECUTE then
					ac = 2
				end
				if bm.Status == MStatus.ALLOW_SUBMIT then
					bc = 4
				elseif bm.Status == MStatus.NOT_RECEIVE then
					if bm:CheckLevel() == false then
						bc = 3
					else
						bc = 1
					end
				elseif bm.Status == MStatus.EXECUTE then
					bc = 2
				end
				if ac ~= bc then
					return ac > bc
				end
				if aid == 900000 then
					local i = math.floor(bid/10000)
					if i > 1 then return aid > bid end
				end
				if bid == 900000 then
					local i = math.floor(aid/10000)
					if i > 1 then return aid > bid end
				end
				return  am.ID < bm.ID
			end
			return 0
		end)
	end
	return list
end

function M:AddItem(index)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = tostring(index)
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	item = ObjPool.Get(UIMissionGroupItem)
	item:Init(go)
	UITool.SetLsnrSelf(go, self.ClickItem, self, "", false)
	table.insert(self.Items, item)
end

function M:ClickItem(go)
	local index = tonumber(go.name)
	self:UpdateSelect(self.CurSelect, false)
	self:UpdateSelect(index, true)
	self.CurSelect = index
end

function M:UpdateSelect(index, value)
	if not index or index <= 0 then return end
	local item = self.Items[index]
	if item then
		item:UpdateSelect(value)
		if value == true then
			local miss = item.Miss
			if miss then
				self.LastID = miss.ID
				local parent = self.Parent
				if parent then
					parent:UpdateData(miss.ID)
				end
			end
		end
	end
end

function M:Reset(reset, resetGrid)
	if resetGrid == nil then resetGrid = true end
	if resetGrid == true then
		self:GridReposition()
	end
	if reset == true then
		self.CurSelect = 0
		self.LastID = 0
		local item = self.Items[1]
		if item then
			if item.Root and item.Root.activeSelf == true then
				self:ClickItem(item.Root)
			end
		end
	else
		local item = self.Items[self.CurSelect]
		if item then
			if item.Root and item.Root.activeSelf == true then
				self:ClickItem(item.Root)
			end
		end
	end
end

function M:GridReposition()
	local grid = self.Grid
	if grid then
		grid:Reposition()
	end
	local sv = self.SV
	if sv then
		if self.Num > 4 then
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

function M:ChangeLv()
	local items = self.Items
	if items then
		local len = #items
		local num = self.Num
		if len >= num and num > 0  then
			for i=1,num do
				items[i]:ChangeLv()
			end
		end
	end
	self:UpdateSelect(self.CurSelect, true)
end

function M:CleanMission(id)
	if self.LastID == id then 
		self.LastID = 0 
		self.CurSelect = 0
	end
end

function M:ClickMenuTip(name, tt, str, index)
	if not tt or tt ~= MenuType.Mission then return end
	local menus = self.MenuTip.items
	if not menus then return end
	local index = menus:IndexOf(str)
	MissionMgr:ClickMenuTip(index)
end

function M:ClickBtn(go)
	local index = self.CurSelect
	if not index or index <= 0 then return end
	local item = self.Items[index]
	if not item then return end
	local miss = item.Miss
	if not miss then return end
	if miss:NotAllowExecute(false) == true then
		return
	end
	local temp = miss.Temp
	if miss:CheckLevel() == true then return end
	if miss.Status == MStatus.COMPLETE then return end
	Hangup:ClearAutoInfo()
	User:ResetMisTarID()
	mMgr:Execute(false)
	if miss.Temp and miss.Temp.type == MissionType.Feeder and not miss.Temp.childType then
		Hangup:SetAutoHangup(false);
	else
		Hangup:SetAutoHangup(true);
	end
	mMgr.CurExecuteType = miss.Temp.type
	mMgr.CurExecuteChildType = miss.childType
	if temp.type ~= MissionType.Feeder or miss.Status ~= MStatus.ALLOW_SUBMIT then
		  MissionMgr:UpdateCurMission(miss)
	end
	miss:AutoExecuteAction(MExecute.ClickItem, false) 
	if self.Parent then self.Parent:Close() end
end

function M:SetActive(value)
	local root = self.Root
	if root then root:SetActive(value) end
	if value == false then self:CleanItems() end
end

function M:RestActiveNum()
	local num = self.Num
	if num > 0 then
		for i=1,num do
			local item = self.Items[i]
			if item then 
				item:SetActive(false)
			end
		end
	end
	self.Num = 0
	self.CurSelect = 0
end

function M:GetMission()
	local index = self.CurSelect
	if not index or index <= 0 then return nil end
	local item = self.Items[index]
	if not item then return nil end
	return item.Miss
end

function M:CleanItems()
	local items = self.Items
	if not items then return end
	for i,v in ipairs(items) do
		v:SetActive(false)
	end
end

function M:DestroyItems()
	local items = self.Items
	if not items then return end
	local len = #items
	while len > 0 do
		local v = items[len]
		table.remove(self.Items, len)
		if v then
			v:Dispose()
			ObjPool.Add(v)
			TableTool.ClearDic(v)
			v = nil
			len = #items
		end
	end
end

function M:Dispose()
	self:DestroyItems()
	self.Items = nil
	self.SV = nil
	self.Panel = nil
	self.Grid = nil
	self.Prefab = nil
	TableTool.ClearDic(self)
end

return M

--endregion

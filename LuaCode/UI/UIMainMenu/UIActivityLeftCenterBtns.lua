--region UIActivityLeftCenterBtns.lua
--Date
--此文件由[HS]创建生成

UIActivityLeftCenterBtns = UIActivityBaseBtns:New{Name="UIActivityLeftCenterBtns"}
local M = UIActivityLeftCenterBtns

local aMgr = ActivityMgr
local sMgr = SurverMgr
local oMgr = OpenMgr


function M:CustomInit(trans)
	local name = "左中部按钮区"
	self.LeftCenter = TransTool.FindChild(trans, "LeftCenter", name, false)
	self.anchor = ComTool.Get(UIWidget, trans, "LeftCenter", name, false)
	self.oriLeft = self.anchor.leftAnchor.absolute
	self.oriRight = self.anchor.rightAnchor.absolute
	self.ItemRoot = TransTool.FindChild(trans, "LeftCenter/Root", name, false)
	self.Items = {}
	self.LayerKey = "6"
end

function M:ScreenChange(orient, init)
	local reset = UITool.IsResetOrient(orient)
	UITool.SetLiuHaiAbsolute(self.anchor, true, reset, self.oriLeft,self.oriRight)
end

--更新数据
function M:InitData()
	local dic = aMgr.Info
	local temps = dic[self.LayerKey]
	if temps then
		local len = #temps
		for j=1,len do
			local temp = temps[j]
			if temp then
				if temp.id ~= aMgr.CDGN then
					if temp.layer ~= aMgr.CDGN then
						self:AddItem(temp, true)
					else
						if self.Menus then self.Menus:AddItem(temp) end
					end
				end
			end
		end
	end
	self:CheckItems()
	self:RenovatePos()
end

--自定义增加item
function M:CustomAddItem(layer, item, change)
	local root = self.ItemRoot
	if LuaTool.IsNull(root) then return end
	if change == true then layer = 6 end
	self:CheckLayer(layer)
	local k = self.LayerKey
	item.Root.parent = root.transform
	item.CurLayer = layer
	table.insert(self.Items[k],item)
end

--自定义移除item
function M:CustomRemoveItem(layer, index)
	local k = self.LayerKey
	local items = self.Items
	if items[k] and items[k][index] then
		local btn = items[k][index]
		btn:Reset()
		btn.GO:SetActive(false)
		btn.Root.parent = self.ItemRoot.transform
		self:SetItem(btn)
		table.remove(items[k], index)
	end
end

--获取按钮组
function M:GetItems(layer)
	if not self.Items then return nil, self.LayerKey end
	return self.Items[self.LayerKey], self.LayerKey
end

--获取按钮目标位置
function M:GetTargetPos(layer, index)
	local startX = 0
	local xp,yp = 0,0
	xp = startX + (self.OffsetX * (index - 1))
	return Vector3.New(xp , yp, 0)
end

function M:CustomShowActEff(temp, data, go)
	if self:IsDeploy() == false and not temp.zoom then return end
	if self.Parent.Parent and self.Parent.Parent.active ~=1 then return end
	self:StartCountDown()
end

function M:GetTarPos(temp)
	local index = self:ItemsCount() + 1
	 return self.Parent, self:GetTargetPos(0, index)
end

--检测已有按钮
function M:CheckItem(layer, id)
	local items = self.Items[self.LayerKey]
	if not items then return false end
	for i,v in ipairs(items) do
		if v.Temp and v.Temp.id == id then
			local od = self.OpenDatta
			if not od or od.GO.name ~= v.GO.name then
				if v.GO then v.GO:SetActive(true) end
			end
			return true, v.Root.localPosition
		end
	end
	return false, nil
end

--按钮排序
function M:SortItems(layer)
	local k = tostring(layer)
	local items, tarLayer = self:GetItems(layer)
	if not items then return end
	if #items <= 1 then return end
	table.sort(items, function(a,b) 
		local al,bl,ai,bi,ac,bc = 0
		if a.Temp then
			al = a.Temp.layer
			ai = a.Temp.index
			ac = a.Temp.change
			if ac == nil then ac = 0 end
		end
		if b.Temp then
			bl = b.Temp.layer
			bi = b.Temp.index
			ac = a.Temp.change
			if bc == nil then bc = 0 end
		end
		if al ~= bl and (al ==6 or bl == 6) then
			return al > bl
		end
		if al == bl and al ~=6 and bl ~= 6 then
			return ac < bc
		end
		return ai < bi
	end)
end

function M:BlackItem()
	local items = self.Items[self.LayerKey]
	local temp = nil
	if items then
		for i,v in ipairs(items) do
			if v.Temp.layer ~= 6 then
				temp = v.Temp
			end
		end
	end
	if temp ~= nil then
		self.Parent:RemoveSystem(temp)
		self.Parent:AddSystem(temp) 
	end
end

function M:ItemsCount()
	local items = self.Items[self.LayerKey]
	if items then return #items end
	return 0
end

function M:IsExist(temp)
	local items = self.Items[self.LayerKey]
	if items then
		for i,v in ipairs(items) do
			if v.Temp.type == temp.type then
				return true
			end
		end
	end
	return false
end

function M:CheckItems()
	local items = self.Items[self.LayerKey]
	if items then
		if #items > 3 then
			local temp = nil
			for i,v in ipairs(items) do
				if v.Temp.layer ~= 6 and self.Parent:GetChangeRemove(v.Temp) == false then
					temp = v.Temp
					return
				end
			end
			if temp ~= nil then
				self:RemoveSystem(v.Temp)
			end
		end
	end
end


function M:Dispose()
end
--endregion

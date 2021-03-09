--region UIActivityRightCenterBtns.lua
--Date
--此文件由[HS]创建生成

UIActivityRightCenterBtns = UIActivityBaseBtns:New{Name="UIActivityRightCenterBtns"}
local M = UIActivityRightCenterBtns

local aMgr = ActivityMgr
local sMgr = SurverMgr
local oMgr = OpenMgr


function M:CustomInit(trans)
	local name = "左中部按钮区"
	self.RigthCenter = TransTool.FindChild(trans, "RigthCenter", name, false)
	self.ItemRoot = TransTool.FindChild(trans, "RigthCenter/Root", name, false)
	self.Items = {}
end

--更新数据
function M:InitData()
	local dic = aMgr.Info
	for i=4,5 do
		local k = tostring(i)
		local temps = dic[k]
		if temps then
			local len = #temps
			for j=1,len do
				local temp = temps[j]
				if temp then
					local change = self.Parent:GetChange(temp)
					if change == false then
						if temp.id ~= aMgr.CDGN then
							if temp.layer ~= aMgr.CDGN then
								self:AddItem(temp, true)
							else
								if self.Menus then self.Menus:AddItem(temp) end
							end
						end
					else
						self.Parent:AddSystem(temp)
					end
				end
			end
		end
	end
	self:RenovatePos()
end

--自定义增加item
function M:CustomAddItem(layer, item, change)
	local root = self.ItemRoot
	if LuaTool.IsNull(root) then return end
	self:CheckLayer(layer)
	local k = tostring(layer)
	item.Root.parent = root.transform
	item.CurLayer = layer
	table.insert(self.Items[k],item)
end

--自定义移除item
function M:CustomRemoveItem(layer, index)
	local k = tostring(layer)
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

--获取按钮目标位置
function M:GetTargetPos(layer, index)
	local startX = 0
	local startY = 0
	local xp,yp = 0,0
	layer = layer - 3
	xp = startX + (self.OffsetX * (index - 1))
	yp = startY - (self.OffsetY * (layer - 1))
	return Vector3.New(xp , yp, 0)
end

--获取按钮目标位置
function M:GetTargetPos(layer, index)
	local startX = 0
	local startY = 0
	local xp,yp = 0,0
	layer = layer - 3
	xp = startX + (self.OffsetX * (index - 1))
	yp = startY - (self.OffsetY * (layer - 1))
	return Vector3.New(xp , yp, 0)
end

--自定义playTween
function M:CustomPlayTween(value, changeScene)
	local items = self.Items
	if not items then return end
	for k,v in pairs(items) do
		for i=1,#v do
			local data = v[i]
			if data then
				if data.Temp and data.Temp.zoom ~= 1 then
					data.Root.gameObject:SetActive(true)
					data:PlayTween(value, changeScene)
				end
			end
		end
	end
end

function M:SpecialPlayTween(value,changeScene)
	local items = self.Items
	if not items then return end
	for k,v in pairs(items) do
		for i=1,#v do
			local data = v[i]
			if data then
				data.Root.gameObject:SetActive(true)
				data:PlayTween(value, changeScene)
			end
		end
	end
end

function M:GetTarPos(temp)
	local pos = nil
	local root = nil
	local parent = self.Parent
	if parent then
		local isDeploy = parent.IsDeploy
		if isDeploy == false and not temp.zoom then
			root = parent.gameObject.transform
			pos = parent.MiniMapZoomBtn.transform.localPosition
			pos.x = pos.x - 21
			pos.y = pos.y - 21
		else
			local layer = temp.layer
			local index = temp.index
			root = self.ItemRoot
			pos = self:AddSystem(temp, false)
		end
	end
	return root, pos
end

function M:Dispose()
end
--endregion

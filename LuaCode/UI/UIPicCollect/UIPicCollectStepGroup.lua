--region UIPicCollectStepGroup.lua
--Date
--此文件由[HS]创建生成


UIPicCollectStepGroup = Super:New{Name="UIPicCollectStepGroup"}
local M = UIPicCollectStepGroup

local PCMgr = PicCollectMgr

function M:Init(go, parent)
	self.Root = go
	local name = "图鉴套牌窗口"
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Parent = parent
	self.PicGroup = ObjPool.Get(UIPicCollectGroup)
	self.PicGroup:Init(T(trans, "Pics"), nil)

	self.NameLab = C(UILabel, trans, "GroupName", name, false)
	self.Grid = C(UIGrid, trans, "Pros/Grid", name ,false)
	self.Prefab = T(trans, "Pros/Grid/Item")

	self.CloseBtn = T(trans, "CloseBtn")

	local E = UITool.SetLsnrSelf
	if parent then
		E(self.CloseBtn, parent.ShowBaseView, parent)
	end

	self.Items = {}
end

function M:AddItem(index, tkey, gkey, temp)
	local go = GameObject.Instantiate(self.Prefab)
	go:SetActive(true)
	local t = go.transform
	t.name = tostring(index)
	t.parent = self.Grid.transform
	t.localScale = Vector3.one
	t.localPosition = Vector3.zero
	local cell = ObjPool.Get(UIPicCollectGroupPro)
	cell:Init(go)
	cell:UpdatePic(tkey, gkey, temp)
	table.insert(self.Items, cell)
end

function M:UpdateData(tkey, temp)
	local gkey = math.floor(temp.id/100) 
	local groupV = self.PicGroup
	if groupV then
		groupV:ShowGroup(tkey, gkey)
	end
	local namelab = self.NameLab
	if namelab then namelab.text = temp.name end
	local list = PCMgr:GetPicPros(tkey, gkey)
	if list then
		local len = #list
		for i=1,len do
			self:AddItem(i, tkey, gkey, list[i])
		end
		self.Grid:Reposition()
		self:Reposition(len)
	end
end

function M:UpdateGroupActive(id)
	if not self.Items then return end
	for i,v in ipairs(self.Items) do
		if v.Temp and v.Temp.id == id then
			v:UpdateActive()
		end
	end
end

function M:Reposition(len)
	if self.UISV then
		if len > 4 then
			self.UISV.isDrag = true
		else
			self.UISV.isDrag = false
		end
	end
end

function M:UpdateAction()
	local items = self.Items
	if not items then return end
	for i,v in ipairs(items) do
		v:UpdateAction()
	end
end

function M:SetActive(value)
	if self.Root then
		self.Root:SetActive(value)
	end
	if value == false then
		self:Clear()
	end
end

function M:Clear()
	if self.Items then
		local len = #self.Items
		while len > 0 do
			local item = self.Items[len]
			if item then
				item:Dispose()
			end
			ObjPool.Add(self.Items[len])
			table.remove(self.Items, len)
			len = #self.Items
		end
	end
	if self.PicGroup then
		self.PicGroup:Clear()
	end
end

function M:Dispose()
	if self.PicGroup then
		self.PicGroup:Dispose()
		ObjPool.Add(self.PicGroup)
	end
end
--endregion

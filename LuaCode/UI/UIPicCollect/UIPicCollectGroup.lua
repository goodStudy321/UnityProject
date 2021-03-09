--region UIPicCollectBase.lua
--Date
--此文件由[HS]创建生成


UIPicCollectGroup = Super:New{Name="UIPicCollectGroup"}
local M = UIPicCollectGroup

local PCMgr = PicCollectMgr

function M:Init(go, parent)
	local name = "图鉴图组"
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Parent = parent
	self.UISV = go:GetComponent("UIScrollView")
	self.Panel = go:GetComponent("UIPanel")
	self.Grid = C(UIGrid, trans, "Grid", name, false)
	self.Prefab = T(trans, "Grid/Item")
	self.DefaultPos = self.Panel.transform.localPosition
	self.Items = {}
end

function M:OpenDefault()
	local list = self.Items
	if list and #list > 0 then
		local parent = self.Parent
		if parent then
			if parent.DefaultPic ~= nil then
				for i,v in ipairs(list) do
					if v.PicId == parent.DefaultPic then
						self:ClickPic(v.Root)
						return
					end
				end
			else
				for i,v in ipairs(list) do
					if PCMgr:GetPicToRed(v.PicId) == true then
						parent.DefaultPic = v.PicId
						self:OpenDefault()
						return
					end
				end
			end
		end
		local go = list[1].Root
		self:ClickPic(go)
	end
end

function M:ShowGroup(tKey, gKey)
	self:Clear()
	local tDic = PCMgr.TypeDic[tKey]
	if not tDic then return end
	local gDic = tDic[gKey]
	if not gDic then return end
	local list = PCMgr:GetList(gDic)
	local len = #list
	for i=1,len do
		local key = list[i]
		self:AddItem(tKey, gKey, key)
	end
	self.Grid:Reposition()
	self:Reposition(len)
end

function M:AddItem(tKey, gKey, key)
	local go = GameObject.Instantiate(self.Prefab)
	go:SetActive(true)
	local t = go.transform
	--t.name = string.format("%s_%s_%s",tKey, gKey, key)
	t.parent = self.Grid.transform
	t.localScale = Vector3.one
	t.localPosition = Vector3.zero
	local cell = ObjPool.Get(UIPicCollectItem)
	cell:Init(go, self.Parent == nil)
	cell:UpdateData(tKey, gKey, key)
	table.insert(self.Items, cell)
	UITool.SetLsnrSelf(go, self.ClickPic, self)
end

function M:ClickPic(go)
	local name = go.name
	local item = self.SelectItem
	local items = self.Items
	if not items then return end
	local len = #items
	if item then
		item:SetSelect(false)
	end
	if StrTool.IsNullOrEmpty(name) then return end
	for i=1,len do
		if items[i].Root.name == name then
			self.SelectItem = items[i]
			self.SelectItem:SetSelect(true)
		end
	end
	local parent = self.Parent 
	if parent then
		parent:SelectPic(go)
	end
	self:RepositionSelect(go)
end

function M:RepositionSelect(go)
	local pos = go.transform.localPosition
	local offset = pos.y
	local panel = self.Panel
	if panel then
		local defultpos = self.DefaultPos
		local py =  self.DefaultPos.y - offset
		panel.transform.localPosition = Vector3.New(defultpos.x, py, defultpos.z)
		local clip = Vector2.New(0,offset)
		panel.clipOffset = clip
		local sv = self.UISV 
		if sv then
			sv:RestrictWithinBounds(true,false,true)
		end
	end
end

function M:Reposition(len)
	if self.UISV then
		if len > 3 then
			self.UISV.isDrag = true
		else
			self.UISV.isDrag = false
		end
	end
	if self.Panel then
		self.Panel.transform.localPosition = self.DefaultPos
		if self.Panel then
			self.Panel.clipOffset = Vector2.zero
		end
	end
end

function M:UpdatePic(temp, data)
	if not self.Items then return end
	for i,v in ipairs(self.Items) do
		if v.PicId == temp.picId then
			v:UpdatePic(data)
		end
	end
end

function M:UpdateAction()
	if not self.Items then return end
	for i,v in ipairs(self.Items) do
		v:UpdateAction()
	end
end

function M:Clear()
	local panel = self.Panel
	if panel then
		panel:Refresh()
	end
	local uisv = self.UISV
	if uisv then
		uisv:DisableSpring()
	end
	local list = self.Items
	if list then
		local len = #list
		while len > 0 do
			local cell = list[len]
			if cell then
				cell:Dispose()
			end
			cell = nil
			table.remove(self.Items, len)
			len = #list
		end
	end
	self.SelectItem = nil
end

function M:Dispose()
	local list = self.Items
	if list then
		local len = #list
		while len > 0 do
			local sp = list[len]
			if sp then
				sp:Dispose(sp)
			end
			sp = nil
			table.remove(self.Items, len)
			len = #list
		end
	end
	list = nil
end
--endregion

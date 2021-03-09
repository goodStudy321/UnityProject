--region UISVAreaBase.lua
--///////////布局样式////////////
--(-x,y)		|		{x,y}
--				|
--		  (-1,1)|(1,1)
--一一一一一一一一一一一一一一一
--		 (-1,-1)|(-1,1)
--				|
--(-x,-y)		|		{x,-y}
--///////////////////////////
--UIScrollView基类
--此文件由[HS]创建生成

UISVAreaBase = Super:New{Name = "UISVAreaBase"}
local M = UISVAreaBase
------公开设置
M.CellSizeH 	= 144		--横向格子尺寸
M.CellSizeV 	= 144		--纵向格子尺寸
M.LimitH		= 60		--横向最大数量 --60
M.LimitV		= 30		--纵向最大数量 --30
M.Horizontal 	= 5		--横向实际数量
M.Vertical 		= 5		--纵向实际数量
---------------------
M.Cells = {}			--容器
------私有
local OffsetH 	= 0			--横向偏移值
local OffsetV 	= 0 		--纵向偏移值
local POS = nil --panel最初的位置
----------------------

--初始化
--构造函数
function M:Init(go)
	local name = "UISVAreaBase"
	self.Root = go
	self.trans = self.Root.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	--获取控件
	self.Panel = self.Root:GetComponent("UIPanel")
	if not self.Panel then 
		self.Panel = C(UIPanel, self.trans, "Panel", name, false) 
	end
	POS=self.Panel.transform.localPosition
	self.Prefab = T(self.trans, "Panel/Item")
	self.W=T(self.trans,"Panel/w")

	self:CustomInit(go)
	OffsetH = math.ceil(self.Horizontal / 2)
	OffsetV = math.ceil(self.Vertical / 2)
	self.Panel.onClipMove = function(p) 
		self:MoveEvent(p) 
	end
end

--更新格子
function M:UpdateCells(H,V)
	self:Clean()
	
	local E = UITool.SetLsnrSelf
	local prefab = self.Prefab
	local panel = self.Panel
	local csH = self.CellSizeH
	local csV = self.CellSizeV
	local originH = H - OffsetH
	local endH = H + OffsetH
	local originV = V - OffsetV
	local endV = V + OffsetV
	for i = originH, endH do
		for j = originV, endV do
			local go = Instantiate(prefab)
			local ch,cv = self:ChangeHV(i, j)
			go.name = string.format("%s_%s",ch,cv)
			go.transform.parent = prefab.transform.parent
			go.transform.localScale = Vector3.one
			local x = csH * i
			local y = csV * j
			go.transform.localPosition = Vector3.New(x, y, 0)
			go:SetActive(true)
			self:CustomCells(go,ch,cv)
			E(go, self.OnClickCell, self, nil, false)
			--self:SetItemData(i, j)
		end
	end
	local x = H * csH
	local y = V * csV
	panel.transform.localPosition = Vector3.New(-x, -y , 0)+POS
	panel.clipOffset = Vector2.New(x, y)
end

function M:ResetCells(H,V)
	self:CustomResetCells()
	local E = UITool.SetLsnrSelf
	local prefab = self.Prefab
	local panel = self.Panel
	local csH = self.CellSizeH
	local csV = self.CellSizeV
	local originH = H - OffsetH
	local endH = H + OffsetH
	local originV = V - OffsetV
	local endV = V + OffsetV
	local index = 1
	local cells = self.Cells
	for i = originH, endH do
		for j = originV, endV do
			local cell = cells[index]
			if cell then
				local go = cell.Root
				if LuaTool.IsNull(go) == false then
					local key = go.name
					local ch,cv = self:ChangeHV(i, j)
					go.name = string.format("%s_%s",ch,cv)
					local x = csH * i
					local y = csV * j
					go.transform.localPosition = Vector3.New(x, y, 0)
					go:SetActive(true)
					self:ChangeCellPos(cell,key,ch,cv)
					index = index + 1
				end
			end
		end
	end
	local x = H * csH
	local y = V * csV
	panel.transform.localPosition = Vector3.New(-x, -y , 0)+POS
	panel.clipOffset = Vector2.New(x, y)
end

function M:MoveEvent(panel)
	--do return end
	if self:ActiveSelf() == false then return end  
	local cells = self.Cells
	local len = #cells
	if len == 0 then return end
	local csH = self.CellSizeH
	local csV = self.CellSizeV
	local h = self.Horizontal
	local v = self.Vertical
	local panel = self.Panel
	local pPos = panel.transform.localPosition
	for i=1,len do
		local root = cells[i].Root
		local pos = root.transform.localPosition
		local isChange = false
		if pPos.x + pos.x < -(OffsetH + 1) * csH then
			pos.x = pos.x + (h+1) * csH
			isChange = true
		elseif pPos.x + pos.x >  (OffsetH+1) * csH then
			pos.x = pos.x - (h+1) * csH
			isChange = true
		end
		if pPos.y + pos.y < -(OffsetV + 1) * csV then
			pos.y = pos.y + (v+1) * csV
			isChange = true
		elseif pPos.y + pos.y > (OffsetV + 1) * csV then
			pos.y = pos.y - (v+1) * csV
			isChange = true
		end
		if isChange == true then
			root.transform.localPosition = pos
			local ch,cv = self:ChangeHV(pos.x / csH, pos.y / csV)
			self:ChangeCellPos(cells[i],root.name, ch, cv)
			root.name = string.format("%s_%s", ch, cv)
			self:UpdateCellInfo(cells[i], ch, cv)
		end
	end
end

function M:ChangeHV(h,v)
	local mh = self.LimitH
	local mv = self.LimitV
	h = math.fmod(h, mh ) 
	v = math.fmod(v, mv ) 
	if h > mh then
		mh = h - mh
	elseif h < 1 then
		h = mh - math.abs(h) 
	end
	if v > mv then
		v = v - mv
	elseif v < 1 then
		v = mv - math.abs(v) 
	end
	return h, v
end

function M:GetCell(hv)
	local cells = self.Cells
	for i,v in ipairs(cells) do
		if LuaTool.IsNull(v.Root) == false then
			if v.Root.name == hv then
				return v
			end
		end
	end
	return nil
end

--设置显示隐藏 显示的时候刷新数据
function M:SetActive(value)
	if self.Root then self.Root:SetActive(value) end
	if value == true then 
		self:Open()
		self:UpdateData() 
	else
		self:Close()
	end
end

function M:ActiveSelf()
	if self.Root then 
		return self.Root.activeSelf 
	end
	return false
end

function M:Open()
	-- body
end

function M:Close()
	-- body
end

--清除Item Cell数据
function M:CleanCells()
	self:CustomCleanCells()
	if not self.Items then return end
	for k,v in pairs(self.Items) do
		v:Clean()
	end
end

--清楚数据
function M:Clean()
	local cells = self.Cells
	local len = #cells
	while len > 0 do
		local info = cells[len]
		table.remove(cells, len)
		info.Root.transform.parent = nil
		Destroy(info.Root)
		ObjPool.Add(info)
		info = nil
		len = #cells
	end
	self:CustomCleanCells()
end

--释放或销毁
function M:Dispose(isDestory)
	self:Clean()
	self:CustomDispose(isDestory)
	self.Root = nil
	self.trans = nil
	self.Panel = nil
	self.Prefab = nil
	self.Cells = nil
	if isDestory then
		self.Root.transform.parent = nil
		GameObject.Destroy(self.Root)
	end
end

--////////////////////////////////自定義函數

--自定义初始化 
--设置参数
--其他控件
function M:CustomInit(go) end

--自定義容器
--類脚本容器
--脚本參數必須有 Root = go
function M:CustomCells(go) 
	--[[
	local info = {}
	info.Root = go
	table.insert(self.Cells, info)
	]]--
end

--更新/設置cell数据
function M:UpdateCellInfo(cell, h,v)
	-- body
end

function M:ChangeCellPos(key, h, v)
	-- body
end

--点击cell
function M:OnClickCell(go)
end

function M:CustomResetCells()
	
end

--清楚容器數據
function M:CustomCleanCells()
end

function M:CustomDispose(isDestory)
	-- body
end

--////////////////////////////////自定義函數
--endregion

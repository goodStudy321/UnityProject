--region UISVRepeatBase.lua
--UIScrollView基类
--此文件由[HS]创建生成

UISVRepeatBase = UIBase:New{Name = "UISVRepeatBase"}
local M = UISVRepeatBase

M.SizeItem = 97			--格子尺寸
M.SizeItemH = 0			--格子纵向尺寸 0：通用SizeItem
M.SizeOffset = 41		--偏移值 cell不能左上对齐
M.LimitHorizontal = 5	--一行最多
M.MinVertical = 4    	--最少行
M.MaxVertical = 20 		--最多行
M.OffsetVertical = 2 	--前后补充列数量
M.LimitNum = 0 			--格子总数


M.Infos = {}			--数据

M.Places = {}			--位置容器

M.Items = {}

--初始化
--构造函数
function M:Init(go)
	self.Name = "UISVRepeatBase"
	self.gameObject = go
	self.trans = self.gameObject.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	--获取控件
	self.SV = self.gameObject:GetComponent("UIScrollView")
	if not self.SV then 
		self.SV = C(UIScrollView, self.trans, "ScrollView", self.Name, false) 
	end
	local trans = self.SV.transform
	self.Panel = self.SV.gameObject:GetComponent("UIPanel")
	self.Rect = C(UIWidget, trans, "Rect", self.Name, false)
	self.Prefab = T(trans, "Rect/Item")
	self.OriginPos = self.Rect.transform.localPosition
	self.PanelPos = self.Panel.transform.localPosition
	self:CustomInit(go)
	local limit = (self.MinVertical + self.OffsetVertical) * self.LimitHorizontal
	self:UpdateItems(limit)
	self:UpdateRectSize()
	self:AddEvent()
	local sv = self.SV
	if sv then
		sv.onDragStarted = function() self.IsMove = true end
		sv.onDragFinished = function() self:LateUpdate() end
		sv.onMomentumMove = function() self:LateUpdate() end
		sv.onStoppedMoving = function() self.IsMove = false end
	end
end

--注册侦听事件
function M:AddEvent() end

function M:RemoveEvent() end

--更新Items 判断进行增加/移除
function M:UpdateItems(limit)
	if limit == nil or limit == 0 then 
		self:CleanCells()  
		return 
	end 
	self.LimitNum = limit
	for i=1,limit do
		self:AddItem(i)
	end					
end

--增加Item
--param 位置
function M:AddItem(index)
	local key = tostring(index)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = key
	go.transform.parent = self.Rect.transform
	go.transform.localScale = Vector3.one
	self:UpdateItemPos(go.transform, index)
	go:SetActive(true)
	table.insert(self.Items, go)
	self:AddCell(key, go)
end

--设置最大
function M:UpdateMaxVertical(len)
	local v = math.round(len / self.LimitHorizontal) - self.OffsetVertical
	if v <= self.MinVertical then
		self.MaxVertical = self.MinVertical
	else 
		self.MaxVertical = v
	end
end

function M:UpdateItemPos(trans, index)
	index = index - 1
	local offset = self.SizeItem 
	local offsetH = self.SizeItemH
	local sizeOffset = self.SizeOffset
	if offsetH == 0 then offsetH = offset end
	local limit = self.LimitHorizontal
	local y = math.modf(index / limit) * offsetH + sizeOffset
	local x = math.floor(index % limit) * offset + sizeOffset
	trans.localPosition = Vector3.New(x, -y, 0)
end

--增加关联Cell
function M:AddCell(key, go)
	local cell = ObjPool.Get(UIItemCell)
	cell:Init(go)
	UITool.SetLsnrSelf(go, self.OnClickItem, self)
	self.Places[key] = cell
end

function M:UpdateCells()
	self:Reposition()
	local limit = self.LimitNum
	for i=1, limit do
		self:UpdateCellInfo(i)
	end
end

--更新指定位置格子数据
function M:UpdateCellInfo(place)
	local cell = self.Places[tostring(place)]
	if cell and cell.trans then
		local pro = self.Infos[place]
		if pro then
			local key = tostring(pro.type_id)
			local temp = ItemData[key]
			if temp then
				cell:UpData(temp, pro.num)
				self:CustomCellInfo(temp, cell)
			else
				cell:Clean()
			end
		else
			cell:Clean()
		end	
	end
end

function M:CustomCellInfo(temp, cell)
	-- body
end

--点击ItemCell
function M:OnClickItem(go)
end

--设置拖动容器尺寸
function M:UpdateRectSize()
	local h = LuaTool.GetIntPart(self.LimitNum / self.LimitHorizontal)
	local size = self.SizeItemH
	if size == 0 then size = self.SizeItem end
	local w = LuaTool.GetIntPart(h * size)
	self.Rect.height = w;
end

function M:LateUpdate()
	if not self.IsMove  then return end
	local sv = self.SV
	local maxv = self.MaxVertical
	local ninv = self.MinVertical
	local offi = self.SizeItem
	local offih = self.SizeItemH
	local sizeOffset = self.SizeOffset
	local offv = self.OffsetVertical
	local lh = self.LimitHorizontal
	local panel = self.Panel
	local y = panel.transform.localPosition.y
	if offih == 0 then offih = offi end
	--if y <= 0 or y >= offi * (maxv - ninv) then return end
	local dic = self.Places
	for k,v in pairs(dic) do
		if LuaTool.IsNull(v.trans)==false then
			local isChange = false
			local pos = v.trans.localPosition
			local root = v.trans.gameObject
			local iy = y + pos.y
			local place = tonumber(root.name);
			local change = 0
			local mH = -offih * (maxv + offv)
			if iy >= offv * offih then
				pos.y = pos.y - (ninv + offv) * offih 
				if pos.y >= mH then 
					self.LimitNum = self.LimitNum + 1
					self:UpdateRectSize()
					change = place + (ninv + offv) * lh
					isChange = true
				end
			elseif iy <= -(offv + ninv - 1) * offih then
				pos.y = pos.y + (ninv + offv) * offih 
				if pos.y <= 0 then
					self.LimitNum = self.LimitNum - 1
					self:UpdateRectSize()
					change = place - (ninv + offv)* lh
					isChange = true
				end
			end
			if isChange == true then
				v.trans.localPosition = pos
				root.name = tostring(change)
				dic[tostring(place)] = nil
				dic[tostring(change)] = v
				self:UpdateCellInfo(change)
			end
		end
	end
end

function M:Reposition()
	local rect = self.Rect
	local panel = self.Panel
	local h = 0
	if LuaTool.IsNull(rect)==false then
		h = rect.transform.localPosition.y
		rect.transform.localPosition = self.OriginPos
	end
	if LuaTool.IsNull(panel)==false then
		panel.transform.localPosition = self.PanelPos
		panel.clipOffset = Vector2.zero
	end
	local items = self.Items
	local places = self.Places
	local len = #items
	if len > 0 then
		for i=1,len do
			local go = items[i]
			if go then
				local key = items[i].name
				local cell = places[key]
				places[key] = nil
				self:UpdateItemPos(go.transform, i)
				items[i].name = tostring(i)
				places[go.name] = cell
			end
		end
	end
end

--设置显示隐藏 显示的时候刷新数据
function M:SetActive(value)
	if self.gameObject then self.gameObject:SetActive(value) end
	if value == true then 
		self:UpdateData() 
	end
end

function M:ActiveSelf()
	if self.gameObject then 
		return self.gameObject.activeSelf 
	end
	return false
end

--清除Item Cell数据
function M:CleanCells()
	self:CustomCleanCells()
	if not self.Places then return end
	for k,v in pairs(self.Places) do
		v:Clean()
	end
end

--移除Item
function M:CleanItems()
	TableTool.ClearDic(self.Infos)
	if self.Places then
		for k,v in pairs(self.Places) do
			ObjPool.Add(v)
			v = nil
		end
	end
	local items = self.Items
	local len = #items
	while len >0 do
		local go = items[len]
		table.remove(self.Items, len)
		go.transform.parent = nil
		Destroy(go)
		len = #items
	end
end

--清楚数据
function M:Clean()
	self:CleanItems()
	self:CustomClean()
end

--释放或销毁
function M:Dispose(isDestory)
	self:Clean()
	self:CustomDispose(isDestory)
end

--自定义初始化
function M:CustomInit(go) end

function M:CustomCleanCells() end

function M:CustomClean() end

function M:CustomDispose(isDestory) end
--endregion

--region UISecretAreaSV.lua
--Date
--此文件由[HS]创建生成



UISecretAreaSV = UISVAreaBase:New{Name = "UISecretAreaSV"}

local M = UISecretAreaSV

local SAMgr = SecretAreaMgr


function M:CustomInit(go)
	local rect = SAMgr.Rect
	self.LimitH = rect[1]
	self.LimitV = rect[2] 
	self.Horizontal = 8
	self.Vertical = 6
	self.SelectCell = nil
	self.SelectKey = nil
	self.CellDic = {}			--key指向Cell
end

function M:CustomCells(go,h,v)
	local cell=ObjPool.Get(AreaCell)
	cell:Init(go)
	table.insert(self.Cells, cell)
	self:UpdateCellInfo(cell, h, v)
end

function M:UpdateCellInfo(cell, h,v)
	local key = string.format("%s_%s",h,v)
	self.CellDic[key] = cell
	self:SetItemDataForKey(key)
end

function M:ChangeCellPos(cell,key, h, v)
	--local cell = self.CellDic[key]
	self.CellDic[key] = nil
	if cell then
		local newKey = string.format("%s_%s",h,v)
		self.CellDic[newKey] = cell
		--cell:NoMoved()
		self:SetItemDataForKey(newKey)

		local ma = string.format("%s_%s",SAMgr.Origin.x,SAMgr.Origin.y)
		if key==ma then
			self:ShowMoveState(false)
		end
		if newKey==ma then 
			self:ShowMoveState(true)
			self:UpCanMove()
		end
	else
		iTrace.eError("xiaoyu","   key: "..key)
	end
end


--[[#########################]]--
function M:SetItemData(h,v)
	self:SetItemDataForKey(string.format("%s_%s",h,v))
end

--[[#########################]]--
--更新数据
function M:SetItemDataForKey(hv)
	local cell = self:GetCell(hv)
	if not cell then return end
	cell:UpData(hv)
	if self.SelectKey and hv == self.SelectKey then
		cell:Select(true)
	end
end

--更新九宫 可行走
function M:UpdateNight(value)
	local dic = SAMgr.NightRoundDic
	for k,v in pairs(dic) do
		local cell = self:GetCell(k)
		if cell then
			if value == false then
				cell:HasMoved()
			else
				cell:UpData(k)
			end		
		end
	end
	if value==true then self:UpCanMove()end
end


--显示可移动ui
function M:UpCanMove()
    local origin = SAMgr.Origin
	local key =  string.format("%s_%s",origin.x,origin.y)
	local cell = self:GetCell(key)
	if not cell then
		return
	end
	if LuaTool.IsNull(cell.Root) then return end
	if LuaTool.IsNull(self.W) then return end

	self:ShowMoveState(true)
	self.W.transform.parent=cell.Root.transform
	self.W.transform.localPosition=Vector3.zero
end

function M:ShowMoveState(isActive)
	if LuaTool.IsNull(self.W) then return end
	self.W.gameObject:SetActive(isActive)
end

function M:SetCanMove()
	local dic = SAMgr.NightRoundDic
	for k,v in pairs(dic) do
		local cell = self:GetCell(k)
		if cell then
			cell:CanMove(v)
		end
	end
end
--[[#########################]]--

function M:OnClickCell(go)
	local key = go.name
	if self.SelectCell then
		if self.SelectCell.key == key then return end
		self.SelectCell:Select(false)
	end
	local cell = self:GetCell(key)
	if not cell then return end
	self.SelectCell = cell
	self.SelectCell:Select(true)
	self.SelectKey = key
	SAMgr.eClickCell(key)
end
--[[#########################]]--
function M:ResetOrigin()
	local origin = SAMgr.Origin
	local key =  string.format("%s_%s",origin.x,origin.y)
	local cell = self:GetCell(key)
	if not cell then
		return
	end
	if LuaTool.IsNull(cell.Root) then return end
	self:OnClickCell(cell.Root)
	self:UpCanMove()
end

function M:ResetOriginCells()
	if self.SelectCell then
		self.SelectCell:Select(false)
	end
	self.SelectKey = nil
	local origin = SAMgr.Origin
	self:ResetCells(origin.x, origin.y)
	self:ResetOrigin()
end
--[[#########################]]--
function M:CustomCleanCells()
	self.SelectCell = nil
	self.SelectKey = nil
	TableTool.ClearDic(self.CellDic)
end

function M:CustomResetCells()
	-- body
end

function M:CustomDispose(isDestory)
	self.SelectCell = nil
	self.SelectKey = nil
end
--endregion



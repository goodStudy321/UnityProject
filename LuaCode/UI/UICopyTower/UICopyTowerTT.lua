UICopyTowerTT = Super:New{Name ="UICopyTowerTT"}

local M = UICopyTowerTT
local cMgr = CopyMgr

function M:Ctor()
    self.Rewards = {}
    self.Receives = {}
end

function M:Init(go)
	local name = "lua爬塔副本"
	local C = ComTool.Get
	local T = TransTool.FindChild
    local F = TransTool.Find
    
    self.go = go

	local trans = go.transform

	self.Right = T(trans, "Right")

	self.CurFloor = C(UILabel, trans, "FloorBg/CurFloor") 

	local root = self.Right.transform
	self.Floor = C(UILabel, root, "Floor", name, false)
	self.EnterBtn = T(root, "Enter")
	self.RewardG = C(UIGrid, root, "CurGrid", name, false)
	
	self.eff = T(trans, "UI_tx_H")
	self.Root = T(trans, "Container")
	self.ReceiveG = C(UIGrid, trans, "Container/TargetGrid", name, false)

	self.CellParent = T(trans, "Container/Container")
	self.Cell = ObjPool.Get(UIItemCell)
	self.Cell:InitLoadPool(TransTool.Find(self.CellParent.transform, "CellRoot"))

	self.Double = T(trans, "Container/Double")
	self.Double:SetActive(CopyMgr:IsDoubleCopy(CopyType.Tower))

	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.EnterBtn then	
		E(self.EnterBtn, self.OnEnterBtn, self)
	end

	FightVal.eChgFv:Add(self.UpdateData, self);
	self:SetEvent("Add")
end

function M:RemoveEvent()
	FightVal.eChgFv:Remove(self.UpdateData, self);
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	cMgr.eUpdateTower[fn](cMgr.eUpdateTower, self.UpdateData, self)
	cMgr.eUpdateGetReward[fn](cMgr.eUpdateGetReward, self.UpdateGetReward, self)
end

---------------------------------------------------
function M:UpdateData()
	local key = tostring(CopyType.Tower)
	local data = cMgr.Copy[key]
	local list = data.Dic
	if not list then return end
	local indexOf = data.IndexOf
	if not data then 
		iTrace.eError("hs","CopyMgr.Copy中没有找到爬塔副本的数据")
		return
	end
	local id = cMgr.LimitTower
	local curId = id
	if id ~= 0 then
		local index = indexOf[tostring(id)]
		if index < 1 then index = 0 end
		index = index + 1
		if list[index] then
			curId = list[index].id
		else
			curId = nil
		end
	else
		curId = list[1].id
	end
	self:UpdateReceive(indexOf)
	local key = tostring(curId)
	local index = indexOf[key]
	local temp = CopyTemp[key]
	self.Temp = temp
	if not temp then
		self.Right:SetActive(false)
		return
	end	
	self:UpdateCurFloor(index)
	local tower = CopyTowerTemp[key]
	if not tower then
		iTrace.eError("HS", string.format("id{%s}爬塔副本不存在",key))
		return 
	end
	self:UpdateReward(tower.endR)
end

function M:UpdateReward(data)
	if not data then return end
	self:UpdateCell(data, self.Rewards, self.RewardG)
end

function M:UpdateReceive(indexOf)
	local tower = self:OpenLock()
	if self.Root then
		self.Root:SetActive(tower ~= nil)
	end
	if not tower then 
		return 
	end
	local data = tower.receiveR
	if data then
		self:UpdateCell(data, self.Receives, self.ReceiveG)
	end
	local hold = tower.hold
	if hold then
		local item = ItemData[tostring(hold)]
		if item then
			self:UpdateShowCell(item)
		end
	else
		self.CellParent:SetActive(false)
	end
	if indexOf then
		local index = indexOf[tostring(tower.id)]
		if index > 0 then
			self:UpdateFloor(index)
		end
	end
end

function M:UpdateFloor(floor)
	if self.Floor then
		self.Floor.text = string.format("通关第%s层", floor)
	end
end

function M:UpdateShowCell(item)
	local cell = self.Cell
	if cell then
		cell:UpData(item)
	end
end


function M:UpdateCurFloor(floor)
	self.CurFloor.text = string.format("第%s层", floor)
end

---------------------------------------------------


function M:UpdateCell(data, list, grid)
	local len = #data
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
			list[i]:SetActive(true)
            list[i]:UpData(data[i].k, data[i].v)
        elseif i <= count then
            list[i]:SetActive(false)
        else
			local cell = ObjPool.Get(UIItemCell)
			cell:InitLoadPool(grid.transform)
			cell:UpData(data[i].k, data[i].v)
			table.insert(list, cell)
        end
    end
    grid:Reposition()
end


function M:OpenLock()
	local list = cMgr.TowerReceives
	if not list then return end
	local len = #list
	for i=1,len do
        local data = list[i]
        if cMgr.LimitTower < data.ID then
            return CopyTowerTemp[tostring(data.ID)]
        end
	end
	return nil
end


function M:OnEnterBtn(go)
	if self.Temp then
		SceneMgr:ReqPreEnter(self.Temp.id, true, true)
	end
end


--=-----------------------------------------
function M:UpdateGetReward(go)
	UIMgr.Open(UIGetRewardPanel.Name, self.UpdateGetRewardData, self)
end

function M:UpdateGetRewardData(name)
	local ui = UIMgr.Dic[name]
	if ui then
		if not cMgr.GetRewardId then ui:Close() return end
		local tower = CopyTowerTemp[tostring(cMgr.GetRewardId)]
		if not tower then ui:Close() return end
		local rewards = tower.receiveR
		local list = nil
		if rewards then
			list = {}
			for i,v in ipairs(rewards) do
				local data = {}
				data.k = v.k
				data.v = v.v
				data.b = false
				table.insert(list,data)
			end
		end
		if not list then ui:Close() return end
		ui:UpdateData(list)
		cMgr.GetRewardId = nil
	end
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:Open()
    self:SetActive(true)
	self:UpdateData()
	self:SetEff(true)
end

function M:Close()
	self:SetActive(false)
	self:SetEff(false)
end

function M:SetEff(state)
	self.eff:SetActive(state)
end

function M:Dispose()
	self:RemoveEvent()
	self.Temp = nil
	TableTool.ClearDicToPool(self.Rewards)
	TableTool.ClearDicToPool(self.Receives)
	self.Cell:DestroyGo()
	ObjPool.Add(self.Cell)
    self.Cell = nil
    TableTool.ClearUserData(self)
end

return M


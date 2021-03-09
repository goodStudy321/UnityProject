UICopyTowerTX = Super:New{Name ="UICopyTowerTX"}

local M = UICopyTowerTX
local cMgr = CopyMgr

function M:Ctor()
	self.Rewards = {}
	self.Limit = 1
end

function M:Init(go)
	local name = "lua爬塔副本"
	local C = ComTool.Get
	local T = TransTool.FindChild
    local F = TransTool.Find
    
    self.go = go

	local trans = go.transform

	self.SelectV = T(trans, "SelectView")

	self.BlackBtn = T(trans, "SelectView/BlackBtn")


	self.SelectBtn = T(trans, "SelectBtn")
	self.RankBtn = T(trans, "Right/RankBtn")
	self.EnterBtn = T(trans, "Right/Enter")
	self.RedBtn = T(trans, "Right/RankBtn/Action")

	self.ToadyFinish = T(trans, "Right/ToadyFinish")

	self.RewardSV = C(UIScrollView, trans, "Right/ScrollView", name, false)
	self.RewardG = C(UIGrid, trans, "Right/ScrollView/CurGrid", name, false)

	self.CurFloor = C(UILabel, trans, "FloorBg/CurFloor") 

	self.QuickTime = C(UILabel, trans, "Right/QuickTime")
	self.QuickName = C(UILabel, trans, "Right/QuickName")
	self.MinFight = C(UILabel, trans, "Right/MinFight")
	self.MinNames = C(UILabel, trans, "Right/MinFightName")
	
	self.eff = T(trans, "Texture/Sprite/UI_tx_H")

	self.Panel = C(UIPanel, trans, "SelectView/ScrollView", name, false)
	self.Content = C(UIWrapContent, trans, "SelectView/ScrollView/Grid", name, false)
	self.Center = C(UICenterOnChild, trans, "SelectView/ScrollView/Grid", name, false)
	self.Enter = T(trans, "SelectView/Enter")
	self.LimitBtn = T(trans, "SelectView/LimitBtn")
	self.Items = {}
	for i=1,3 do
		local lab = C(UILabel, trans, string.format("SelectView/ScrollView/Grid/L%s", i))
		self.Items[lab.gameObject.name] = lab
	end

	self.SelectID = nil
	self.Index = nil
	self:AddEvent()
end

function M:AddEvent()
	self.Panel.onClipMove = function(p) 
		self:MoveEvent(p) 
	end
	self.Content.onInitializeItem = function(go, index, realIndex)
		self:UpdateItemInfo(go, index, realIndex)
	end
	self.Center.onCenter = function(go)
		self:UpdateCenterSelect(go)
	end
	local E = UITool.SetLsnrSelf
	if self.BlackBtn then	
		E(self.BlackBtn, self.OnBlackBtn, self)
	end
	if self.SelectBtn then	
		E(self.SelectBtn, self.OnSelectBtn, self)
	end
	if self.RankBtn then	
		E(self.RankBtn, self.OnRankBtn, self)
	end
	if self.EnterBtn then	
		E(self.EnterBtn, self.OnEnterBtn, self)
	end
	if self.Enter then	
		E(self.Enter, self.OnEnter, self)
	end
	if self.LimitBtn then	
		E(self.LimitBtn, self.OnLimitBtn, self)
	end

	--FightVal.eChgFv:Add(self.UpdateData, self);
	self:SetEvent("Add")
end

function M:RemoveEvent()
	--FightVal.eChgFv:Remove(self.UpdateData, self);
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	--cMgr.eUpdateGetReward[fn](cMgr.eUpdateGetReward, self.UpdateGetReward, self)
	cMgr.eUpdateSelectTXTowerInfo[fn](cMgr.eUpdateSelectTXTowerInfo, self.UpdateSelectTXTowerInfo, self)
end

---------------------------------------------------
function M:UpdateData()
	self:UpdateUIShow(cMgr.TXTowerLimitIndex)
end

function M:UpdateUIShow(index)
	local key = tostring(CopyType.TXTower)
	local data = cMgr.Copy[key]
	local list = data.Dic
	if not list then return end
	local indexOf = data.IndexOf
	if not data then 
		iTrace.eError("hs","CopyMgr.Copy中没有找到太虚爬塔副本的数据")
		return
	end
	self.Limit = #indexOf
	local id = 0
	if index == -1 then 
		index = 1 
		id = indexOf[index]
	else
		if index < #indexOf  then
			id = indexOf[index + 1]
		else
			id = indexOf[index]
		end
	end
	if id == 0 then 
		iTrace.eError("hs","CopyMgr.Copy.IndexOf中没有找到太虚爬塔副本的数据")
		return 
	end
	self:UpdateCurFloor(index)
	local key = tostring(id)
	local temp = CopyTemp[key]
	self.Temp = temp
	if not temp then
		return
	end	
	self.Index = index
	self:UpdateReward(temp.sor0, temp.id)
	self.SelectID = temp.id
	cMgr:ReqUniverseFloorInfo(id)
end

function M:UpdateCurFloor(floor)
	if cMgr.TXTowerLimit ~= 0 then floor = floor + 1 end
	if floor == 0 then floor = 1 end
	if floor > self.Limit then floor = self.Limit end
	self.CurFloor.text = string.format("第%s层", floor)
end

function M:UpdateReward(data, id)

	local value = CopyMgr:GetTXTodayFinish(id)
	self.ToadyFinish:SetActive(value)
	self.RewardG.gameObject:SetActive(not value)

	if not data then return end
	self:UpdateCell(data, self.Rewards, self.RewardG)
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

function M:MoveEvent(panel)
	if self.SelectV.activeSelf == false then return end
end

function M:UpdateItemInfo(go, index, rIndex)
	local cur = self.Index
	if cur == nil then cur = cMgr.TXTowerLimitIndex end
	cur = cur + 1
	if cur > self.Limit then cur = self.Limit end
	local layer = cur + rIndex
	layer = self:GetLayer(layer)
	self.Items[go.name].text = layer
end

function M:GetLayer(layer)
	local limit = cMgr.TXTowerLimitIndex
	if not limit then 
		limit = 1
	else
		limit = limit + 1 
	end
	if cMgr.TXTowerLimit == 0 then limit = 1 end
	if limit > self.Limit then limit = self.Limit end
	if layer < 1 then
		layer = limit + layer
	elseif layer > limit then
		layer = layer-limit
	end
	if layer < 1 or layer > limit then
		layer = self:GetLayer(layer)
	end
	return layer
end

function M:UpdateCenterSelect(go)
	if LuaTool.IsNull(go) == true then return end
	local str = self.Items[go.name].text
	if StrTool.IsNullOrEmpty(str) then
		iTrace.eError("hs","太虚选层错误")
		return
	end
	local layer = tonumber(str)
	local key = tostring(CopyType.TXTower)
	local data = cMgr.Copy[key]
	local indexOf = data.IndexOf
	if not data then 
		iTrace.eError("hs","CopyMgr.Copy中没有找到太虚爬塔副本的数据")
		return
	end
	local 
	id = indexOf[layer]
	if id == 0 then 
		iTrace.eError("hs","CopyMgr.Copy.IndexOf中没有找到太虚爬塔副本的数据")
		return 
	end
	self.SelectID = id
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

function M:OnBlackBtn(go)
	self:SetSelectActive(false)
	if self.Temp then
		self.SelectID = self.Temp.id
	end
end

function M:OnSelectBtn(go)
	self:SetSelectActive(true)
end

function M:OnRankBtn(go)
	JumpMgr:InitJump(UICopyTowerPanel.Name,CopyType.TXTower)
	UIMgr.Open(UITongtianRank.Name,self.TTCb,self)
end

function M:TTCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:OpenTabByIdx(1)
	end
end


function M:OnEnterBtn(go)
	local id = self.SelectID
	if id ~= nil then
		--[[
		if CopyMgr:GetTXTodayFinish(id) == true then
			UITip.Error("今日已通关该副本，不能继续挑战")
			return 
		end
		]]--
		SceneMgr:ReqPreEnter(id, true, true)
	end
end

function M:OnEnter(go)
	local index = CopyMgr:GetTxIndex(self.SelectID)
	if index == -1 then return end
	self:UpdateUIShow(index - 1)
	self:ResetSelectView()
end

function M:OnLimitBtn(go)
	local data = cMgr.Copy[tostring(CopyType.TXTower)]
	local list = data.Dic
	if not list then 
		UITip.Error("未达到挑战资格")
		return 
	end
	local indexOf = data.IndexOf
	if not indexOf then 
		UITip.Error("未达到挑战资格")
		return 
	end
	local index = cMgr.TXTowerLimitIndex
	if index == -1 then 
		index = 1
	else
		if #indexOf > index then
			index = index + 1
		end
	end
	self:UpdateUIShow(index - 1)
	self:ResetSelectView()
end

function M:ResetSelectView()
	local panel = self.Panel
	panel.transform.localPosition = Vector3.New(0, -6.35, 0)
	panel.clipOffset = Vector2.zero
	local content = self.Content
	content:SortAlphabetically()
	content:WrapContent()
	self:SetSelectActive(false) 
	self:SetEff(true)
end

function M:UpdateSelectTXTowerInfo(fname, ftime, pname, power)
	local qn = fname
	if StrTool.IsNullOrEmpty(fname) == true then 
		qn = "暂无记录"
	end
	local qt = ""
	if ftime ~= 0 then
		qt = DateTool.FmtSS(ftime)
	end
	local pn = pname
	if StrTool.IsNullOrEmpty(pname) == true then 
		pn = "暂无记录"
	end
	local mf = tostring(power)
	if power == 0 then
		mf = ""
	end
	self.QuickName.text = qn
	self.QuickTime.text = qt
	self.MinNames.text = pn
	self.MinFight.text = mf
end

function M:UpdateRed(state)
	self.RedBtn:SetActive(state == true)
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

function M:SetSelectActive(value)
	self.SelectV:SetActive(value)
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
	self:SetSelectActive(false) 
	self.SelectID = nil
	self.Index = nil
end

function M:SetEff(state)
	self.eff:SetActive(state)
end

function M:Dispose()
	self:RemoveEvent()
	self.Temp = nil
	TableTool.ClearDicToPool(self.Rewards)
    TableTool.ClearUserData(self)
end

return M


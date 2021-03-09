--region UIMyTeamSetCopy.lua
--Date
--此文件由[HS]创建生成

UIMyTeamSetCopy = {}
local M = UIMyTeamSetCopy

local II = UIWrapContent.OnInitializeItem
local CC = UICenterOnChild.OnCenterCallback
local F = SpringPanel.OnFinished
local tMgr = TeamMgr
local uMgr = UserMgr
M.MinRestrict = 0
M.MaxRestrict = 0
M.DragNum = 6



--注册的事件回调函数

function M:New(go)
	local name = "队伍设置副本"
	self.GO = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Panel = C(UIPanel, trans, "Panel/CopyList", name, false)
	self.ScrollView = C(UIScrollView, trans, "Panel/CopyList", name, false)

	self.copyGrid = C(UIGrid, trans, "Panel/CopyList/Grid")
	self.wildCPa = T(trans, "Panel/CopyList/Grid/copy1")
	self.marryCPa = T(trans, "Panel/CopyList/Grid/copy2")

	self.equipCopy = T(trans, "Panel/CopyList/Grid/copy3/equipCopy")
	self.equipCSelec = T(trans, "Panel/CopyList/Grid/copy3/equipCopy/Select")
	self.TweenerECopy = C(UITweener, trans, "Panel/CopyList/Grid/copy3/Tween", name, false)
	self.PlayTweenECopy = C(UIPlayTween, trans, "Panel/CopyList/Grid/copy3/equipCopy", name, false)

	self.Grid = C(UIGrid, trans, "Panel/CopyList/Grid/copy3/Tween/Grid")
	self.Prefab = T(trans, "Panel/CopyList/Grid/copy3/Tween/Grid/Item")
	self.Prefab.gameObject:SetActive(false)
	--self.IsDirect = C(UIToggle, trans, "Toggle", name, false)
	self.MinLevel = C(UIWrapContent, trans, "Panel/MinLevel/MinC", name, false)
	self.MinLvClick = C(UICenterOnChild, trans, "Panel/MinLevel/MinC", name, false)
	self.MinLvItems = self:GetlVItems(self.MinLevel)
	self.MaxLevel = C(UIWrapContent, trans, "Panel/MaxLevel/MaxC", name, false)
	self.MaxLvClick = C(UICenterOnChild, trans, "Panel/MaxLevel/MaxC", name, false)
	self.MaxLvItems = self:GetlVItems(self.MaxLevel)

	self.ConfirmBtn = T(trans, "Panel/Confirm")

	self.CurSelectCell = nil
	self.MinSelect = nil
	self.MaxSelect = nil
	self.Temp = nil
	self.MinLv = 0
	self.MaxLv = 0
	self:AddEvent()
	self:InitView()
	
	return M	
end

function M:GetlVItems(parent)
	if not parent then return nil end
	local size = parent.transform.childCount
	local trans = parent.transform
	local items = {}
	for i=1,size do
		local label = ComTool.Get(UILabel, trans, "Item"..i, "创建队伍面板", false)
		table.insert(items, label)
	end
	return items
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	local func = II(self.ChangeLevel, self)
	if self.MinLevel then
   		self.MinLevel.onInitializeItem = func
   	end
	if self.MaxLevel then
   		self.MaxLevel.onInitializeItem = func
   	end
   	if self.MinLvClick then
   		self.MinLvClick.onFinished = F(self.MinLvClickHander, self)
   	end
   	if self.MaxLvClick then
   		self.MaxLvClick.onCenter = CC(self.MaxLvClickHander, self)
	end
	if self.ConfirmBtn then
		E(self.ConfirmBtn, self.OnConfirmBtn, self)
	end
	if self.GO then
		E(self.GO, self.OnClose, self, nil, false)
	end
	if self.equipCopy then	
		E(self.equipCopy, self.OnEquipCBtn, self)
	end
end

function M:RemoveEvent()
end
 
function M:InitView()
	self.TeamCopy = {}
	local index = 0
	local list = CopyMgr.TeamCopy.IndexOf
	local dic = CopyMgr.TeamCopy.Dic
	if list then
		local len = #list
		for i=1,len do
			local k = tostring(list[i])
			local temp = dic[k]
			if temp then
				self:AddTeamCopy(i, k, temp)
			end
		end
		self:Reposition()
	end
end

--默认选择当前可进入
function M:SelectCanEnter()
	local copy = CopyMgr:GetCurCopy(CopyMgr.Equip)
	if copy then
		local items = self.TeamCopy
		local key = tostring(copy.Temp.id)--默认选中第一个
		if items and items[key] then
			self:ClickCell(items[key].GO)
			self:UpdateBG()
		end
	end
end

--默认选择野外挂机可进入
function M:SelectWildEnter()
	-- self:UpdateTitle(false)
	-- local copy = CopyMgr:GetCurCopy(CopyMgr.Equip)
	-- if copy then
		local data = GlobalTemp["60"]
		local copyId = data.Value3

		local items = self.TeamCopy
		-- local key = "20000"--默认选中第一个
		local key = tostring(copyId)
		if items and items[key] then
			self:ClickCell(items[key].GO)
			self:UpdateBG()
		end
	-- end
end

function M:UpdateBG()
	local list = CopyMgr.TeamCopy.IndexOf
	local dic = CopyMgr.TeamCopy.Dic
	if list then
		local len = #list
		for i=1,len do
			local k = tostring(list[i])
			local team = self.TeamCopy[k]
			if team ~= nil then
				local temp = dic[k]
				team:UpdateBGState(temp)
			end
		end
	end
end


--根据副本id选择
function M:SelecOneCanEnter(copyId)
	local items = self.TeamCopy
	local key = tostring(copyId)--默认选中一个
	if items and items[key] then
		self:ClickCell(items[key].GO)
	end
	local copyInfo = CopyTemp[key]
	local minLv = copyInfo.lv
	TeamMgr:ReqSetCopyTeam(copyId, minLv, 1000)
end

function M:AddTeamCopy(index, key, temp)
	if not self.TeamCopy[key] then
		local copyTemp = CopyTemp[key]
		local go = GameObject.Instantiate(self.Prefab)
		go.name = key
		if copyTemp.type == 0 then
			go.transform.parent = self.wildCPa.transform
			go.transform.localPosition = Vector3.New(-80,180,0)
			go.transform.localScale = Vector3.one
			self:SetPrefabData(go,key,temp)
		elseif copyTemp.type == 16 then
			go.transform.parent = self.marryCPa.transform
			go.transform.localPosition = Vector3.New(-80,180,0)
			go.transform.localScale = Vector3.one
			self:SetPrefabData(go,key,temp)
		elseif copyTemp.type == 3 then
			local pos = go.transform.localPosition
			go.transform.parent = self.Grid.transform
			go.transform.localPosition = pos
			go.transform.localScale = Vector3.New(0.9,0.9,0.9)
			self:SetPrefabData(go,key,temp)
		end
	end
end

function M:SetPrefabData(go,key,temp)
	go:SetActive(true)
	local team = UICellTeamSelectCopy.New(go)
	team:Init()
	team:UpdateData(temp)
	-- team:UpdateBG(index)
	UITool.SetLsnrSelf(go, self.ClickCell, self, nil, false)
	self.TeamCopy[key] = team
end

function M:ClickCell(go)
	local cell = self.TeamCopy[go.name]
	if not cell then return end
	local temp = cell.Temp
	if temp.lv > User.MapData.Level then
		UITip.Error(string.format("等级不足，需要%s级进入【%s】", temp.lv, temp.name))
		return 
	end
	if temp.pre and not CopyMgr:GetPreCopy(CopyMgr.Equip, temp.pre) then
		UITip.Error(string.format("没有达到该副本的进入条件"))
		return
	end
	self.MinLvClick:Recenter()
	self.MaxLvClick:Recenter()
	if self.CurSelectCell then
		if self.CurSelectCell.Temp.id == temp.id then 
			return 
		end
		self.CurSelectCell:IsSelect(false)
	end

	local copyTemp = CopyTemp[tostring(cell.Temp.id)]
	if copyTemp.type == 16 or copyTemp.type == 0 then
		-- local pt = self.PlayTweenECopy
		-- if pt and pt.isPlayStatus == true then 
		-- 	pt:Play(false) 
		-- end
		self:UpdateTitle(false)
	end

	self.CurSelectCell = cell
	self.CurSelectCell:IsSelect(true)
	if self.CurSelectCell and self.CurSelectCell.Temp then
		self.Temp = self.CurSelectCell.Temp
		self.MinRestrict = self.Temp.lv
		self.MaxRestrict = 400
		-- self.MaxRestrict = User.MapData.Level
		-- if self.MinRestrict > self.MaxRestrict then
		-- 	self.MaxRestrict = self.MinRestrict
		-- end
	else
		self.Temp = nil
	end
	self.MinLevel:Reset()
	self.MaxLevel:Reset()
end

function M:ClickTitle()
	self:Reposition()
end

function M:OnEquipCBtn()
	self:UpdateTitle(self.TweenerECopy.IsForward)
end

function M:UpdateTitle(isForward)
	if isForward then
		self.equipCSelec:SetActive(true)
	else
		self.equipCSelec:SetActive(false)
	end
end

function M:Reposition()
	if self.ScrollView then
		local len = LuaTool.Length(self.TeamCopy)
		if len > self.DragNum then
			self.ScrollView.isDrag = true
		else
			self.ScrollView.isDrag = false
		end
	end
end

function M:ChangeLevel(go, wrapIndex, realIndex)
	local name = go.transform.parent.name
	local list = nil
	local itemIndex = wrapIndex + 1
	if self.MinLevel.name == name then
		list = self.MinLvItems
		if list then
			if self.MaxRestrict ~= 0 then
				real = self:GetRealIndex(realIndex, self.MinRestrict, self.MaxRestrict)
			else
				real = ""
			end
			if list[itemIndex] then
				local lvStr = self:GetGodLv(real)
				list[itemIndex].text = lvStr
			end
		end
		self:MinLvClickHander()
	elseif self.MaxLevel.name == name then
		list = self.MaxLvItems
		if list then
			if self.MaxRestrict ~= 0 then
				real = self:GetRealIndex(realIndex, tMgr.LimitLv, tMgr.LimitLv)
			else
				real = ""
			end
			if list[itemIndex] then
				local lvStr = self:GetGodLv(real)
				list[itemIndex].text = lvStr
			end
		end
		self:MaxLvClickHander()
	end
end

function M:GetRealIndex(realIndex, restrict, limitLv)	
	local real = realIndex
	real = real * -1 
	if restrict ~= 0 then
		local m = (limitLv - restrict + 1) 
		real = real % m
	else
		real = real % limitLv
	end
	real = real + 1
	if real <= 0 then
		real = limitLv + real
	else
		if restrict > 0 then
			real = real + restrict - 1
		end
	end
	return real
end

function M:MinLvClickHander()
	local go = self.MinLvClick.centeredObject
	if not go then return end
	if self.MinLvItems then
		for i,v in ipairs(self.MinLvItems) do
			if v.name == go.name then
				if not StrTool.IsNullOrEmpty(v.text) then
					local lv = self:GetLv(v)
					self.MaxRestrict = 400
					self.MinLv = lv
					self.MaxLevel:Reset()
					if self.MinSelect then
						self.MinSelect.color = Color.New(248, 215, 180, 255) / 255
					end
					self.MinSelect = v
					self.MinSelect.color = Color.New(1, 1, 1)
				end
				return
			end
		end
	end
end

function M:MaxLvClickHander()
	local go = self.MaxLvClick.centeredObject
	if not go then return end
	if self.MaxLvItems then
		for i,v in ipairs(self.MaxLvItems) do
			if v.name == go.name then
				if not StrTool.IsNullOrEmpty(v.text) then
					local lv = self:GetLv(v)
					self.MaxLv = lv
					if self.MaxSelect then
						self.MaxSelect.color = Color.New(248, 215, 180, 255) / 255
					end
					self.MaxSelect = v
					self.MaxSelect.color = Color.New(1, 1, 1)
				end
				return
			end
		end
	end
end

--普通等级转换化神等级
function M:GetGodLv(lv)
	-- local isGodLv = uMgr:IsGod(lv)
	-- if isGodLv == true then
	-- 	local godLv = lv - 370
	-- 	lv = string.format("化神%s",godLv)
	-- elseif isGodLv == false then
	-- 	lv = lv
	-- end
	return lv
end

--化神等级转换普通等级
function M:GetLv(godLv)
	local lv = godLv.text
	-- local lvStrLen = string.len(lv)
	-- if lvStrLen > 3 then
	-- 	lv = string.sub(lv,7,string.len(lv))
	-- 	lv = lv + 370
	-- end
	lv = tonumber(lv)
	return lv
end

function M:OnConfirmBtn(go)
	local id = 0
	local min = 0
	local max = 0
	if self.Temp then	
		id = self.Temp.id
	else
		self:SetActive(false)
		return 
	end
	if self.MinLv then
		min = self.MinLv
	end
	if self.MaxLv then
		max = self.MaxLv
	end
	-- if min> User.MapData.Level then
	-- 	UITip.Error("最小限制等级不能大于角色等级")
	-- 	return
	-- end
	if max < User.MapData.Level then
		UITip.Error("最大限制等级不能小于角色等级")
		return
	end
	TeamMgr:ReqSetCopyTeam(id, min, max)
	self:SetActive(false)
end

function M:OnClose()
	self:SetActive(false)
end

function M:SetActive(value)
	if self.GO then
		self.GO:SetActive(value)
	end
end

function M:Clean()
	if self.TeamCopy then 
		for k,v in pairs(self.TeamCopy) do
			self.TeamCopy[k]:Dispose(true)
			TableTool.ClearDic(self.TeamCopy[k])
			self.TeamCopy[k] = nil
		end
	end
end

function M:Dispose()
	self:Clean()
	self.Panel = nil
	self.ScrollView = nil
	self.Prefab = nil
	--self.IsDirect = nil

	self.copyGrid = nil
	self.wildCPa = nil
	self.marryCPa = nil
	self.equipCopy = nil
	self.equipCSelec = nil
	self.TweenerECopy = nil
	self.PlayTweenECopy = nil

	self.MinLevel = nil
	self.MinLvClick = nil
	self.MinLvItems = nil
	self.MaxLevel = nil
	self.MaxLvClick = nil
	self.MaxLvItems = nil
	self.CurSelectCell = nil
	self.Temp = nil
	self.MinLv = nil
	self.MaxLv = nil
   	self.OnClickCell = nil
   	self.OnClickTitle = nil
   	self.OnChangeLevel = nil
   	self.OnMinLvClick = nil
   	self.OnMaxLvClick = nil
   	self.TeamCopy = nil
end
--endregion

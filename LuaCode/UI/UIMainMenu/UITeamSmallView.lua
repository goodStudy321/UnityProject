--region UITeamSmallView.lua
--Date
--此文件由[HS]创建生成
require("UI/UITeam/UICellTeamBase")
require("UI/UITeam/UICellSmallTeamPlayer")

UITeamSmallView =Super:New{Name="UITeamSmallView"}
local M = UITeamSmallView

--注册的事件回调函数

function M:New1(go)
	local name = "UI主界面组队窗口"
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.NotLv = T(trans, "NotLevel")
	self.NoTeam = T(trans, "NoTeam")
	self.NoMatch = T(trans,"NoMatch")
	self.MatchName = C(UILabel, trans, "NoMatch/CopyName", name, false)
	self.MatchBtn = C(UIButton, trans, "NoMatch/CancleBtn")
	self.CreateBtn = C(UIButton, trans, "NoTeam/CreateBtn")
	self.JoinBtn = C(UIButton, trans, "NoTeam/JoinBtn")
	self.Panel = C(UIPanel, trans, "Panel", name, false)
	self.ScrollView = self.Panel.gameObject:GetComponent("UIScrollView")
	self.Grid = C(UIGrid, trans, "Panel/Container", name, false)
	self.Prefab = T(trans,"Panel/Container/Item")
	self.BuffRoot = C(UISprite, trans, "Buff", name, false)

	self.TeamBtn = C(UIButton, trans, "Buff/TeamBtns/TeamBtn")
	self.ExitTeamBtn = C(UIButton, trans, "Buff/TeamBtns/ExitBtn")

	self.Buffs = {}
	for i=1,3 do
		local b = C(UISprite, trans, string.format("Buff/Icon%s", i), name, false)
		table.insert(self.Buffs, b)
	end
	self.BuffValue = C(UILabel, trans, "Buff/Value", name, false)
	self.ScrollLimit = 3
	self.OpenLv = 0
	self.Items = {}
	local temp = SystemOpenTemp["7"]
	if temp then self.OpenLv = temp.trigParam end
	self:UpdateView()
	self:AddEvent()
	return self
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	--控件事件
	E(self.CreateBtn, self.OnClickCreateBtn, self)
	E(self.JoinBtn, self.OnClickJoinBtn, self)
	E(self.MatchBtn, self.OnClickMatchBtn, self)

	E(self.TeamBtn, self.OnClickTeamBtn, self)
	E(self.ExitTeamBtn, self.OnClickExitTeamBtn, self)

	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	TeamMgr.eUpdateCaptID[fn](TeamMgr.eUpdateCaptID, self.UpdateCaptID, self)
	TeamMgr.eUpdateMatchStatus[fn](TeamMgr.eUpdateMatchStatus, self.UpdateMatchState, self)
end

function M:UpdateView()
	local noLvB = false
	local noTeamB = false
	local panelB = false
	self.NoMatch:SetActive(true)
	if User.MapData.Level < self.OpenLv then
		noLvB = true
	else
		if not TeamMgr.TeamInfo.TeamId then
			noTeamB = true
			self.NoMatch:SetActive(false)
		else
			panelB = true
			self.NoMatch:SetActive(false)
		end
		self:UpdatePanel()
	end
	self.NotLv:SetActive(noLvB)
	self.NoTeam:SetActive(noTeamB)
	self.Panel.gameObject:SetActive(panelB)
	self.BuffRoot.gameObject:SetActive(panelB)
end

function M:UpdateMatchState()
	local isMatch = TeamMgr.IsMatching
	self.matchCopyId = TeamMgr.MatchCopyId
	local isShowNoTeam = true
	if LuaTool.IsNull(self.NoTeam) then return end
	self.NoTeam:SetActive(not isMatch)
	self.NoMatch:SetActive(isMatch)
	if isMatch and self.matchCopyId > 0 then  --匹配中。。。。
		self.NoTeam:SetActive(false)
		self.NoMatch:SetActive(true)
		local copyData = CopyTemp[tostring(self.matchCopyId)]
		local name = copyData.name
		self.MatchName.text = name
	elseif isMatch == false and self.matchCopyId > 0 then --匹配队伍成功
		UITip.Log("已成功匹配队伍")
		self.NoMatch:SetActive(false)
	end
end

function M:LeaveTeam()
end

function M:UpdatePanel()
	local list = TeamMgr.TeamInfo.Player
	if not list then return end
	local items = self.Items
	local iLen =  #items
	local len = #list
	if iLen == nil then iLen = 0 end
	if len == nil then len = 0 end
	if iLen < len then
		for i=iLen + 1,len do
			local v = list[i]
			self:AddPlayerItem(v)
			-- local icon = self.Buffs[i]
			-- if icon then icon.color = Color.New(1,1,1,1) end
		end
	elseif iLen > len then
		local num = iLen - len
		while num > 0 do
			local cell = items[num]
			if cell then
				cell:Dispose(true)
				cell = nil
			end
			table.remove(self.Items, num)
			-- local icon = self.Buffs[num]
			-- if icon then icon.color = Color.New(1,1,1,0.4) end
			num = num - 1
		end
	end
	self:GridReposition()
	for i=1,len do
		local v = list[i]
		if v then
			local key = tostring(v.ID)
			local cell = items[i]
			if cell then
				cell:UpdateData(v)
			end
		end
	end
	self:ClearBuffs()
	for i = 1,len do
		local icon = self.Buffs[i]
		if icon then icon.color = Color.New(1,1,1,1) end
	end
	if self.BuffValue then
		local buff = "无"
		if len > 1 then
			buff = tostring((len - 1) * 15).."%"
		end
		self.BuffValue.text = buff
	end
end

function M:AddPlayerItem(data)
	if not data then return end
	local go = GameObject.Instantiate(self.Prefab)
	go.name = tostring(data.ID)
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	local cell = UICellSmallTeamPlayer.New(go)
	cell:Init()
	--cell:UpdateData(data)
	table.insert(self.Items, cell)
end

--重置ScrollView是否可以拖动状态
function M:GridReposition()
	self.Grid:Reposition()
	if self.Grid:GetChildList().Count >= self.ScrollLimit then 
		self.ScrollView.isDrag = true
	else
		self.ScrollView.isDrag = false
	end
end

function M:UpdateIcon()
	local list = self.Items
	if not list then return end
	if list == nil then return end
	if #list ==0 then return end
	--print("------------------>>> ",tostring(list[1]),list[1].Name)
	for i,v in ipairs(list) do
		v:RestIcon()
	end 
end

function M:UpdateCaptID()
	local list = self.Items
	if not list then return end
	for i,v in ipairs(list) do
		v:UpdateCap()
	end 
end

function M:OnClickCreateBtn(go)
	--TeamMgr:ReqCreateTeam()
	UIMgr.Open(UIMyTeam.Name,M.CreateTeamCb)
end

function M.CreateTeamCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:OnCreateBtn()
	end	
end

function M:OnClickJoinBtn(go)
	UIMgr.Open(UITeam.Name, M.OpenUITeam)
end

--默认选中当前可进入副本
-- function M.OpenUITeam(name)
-- 	local ui = UIMgr.Dic[name]
-- 	if ui then 
-- 		ui:ClickDefCell()
-- 	end
-- end

--默认选中野外挂机
function M.OpenUITeam(name)
	local ui = UIMgr.Dic[name]
	if ui then 
		ui:SelectWildEnter()
	end
end

function M:OnClickMatchBtn()
	TeamMgr:ReqTeamMatch(self.matchCopyId, false)
end

function M:OnClickTeamBtn()
	UIMgr.Open(UIMyTeam.Name)
end

function M:OnClickExitTeamBtn()
	TeamMgr:ReqLeave()
end

function M:Clear()
	local len = #self.Items
	while len > 0  do
		local cell = self.Items[len]
		if cell then
			cell:Dispose(true)
			cell = nil
		end
		table.remove(self.Items, len)
		len = #self.Items
	end
	self:ClearBuffs()
end

function M:ClearBuffs()
	if self.Buffs then
		for i,v in ipairs(self.Buffs) do
			v.color = Color.New(1,1,1,0.4)
		end
	end
end

function M:GetHeight()
	if self.NotLv.activeSelf == true then
		return 40
	elseif self.NoTeam.activeSelf == true then
		return 210
	elseif self.Panel.gameObject.activeSelf == true then
		if not self.Items then return 0 end
		local count = #self.Items * 62
		local add = 0
		if self.BuffRoot.gameObject.activeSelf == true then
			local pos = self.Panel.transform.localPosition
			local h = pos.y + self.Panel.height / 2
			local pos1 = self.BuffRoot.transform.localPosition
			self.BuffRoot.transform.localPosition = Vector3.New(pos1.x, h - count, pos1.z)
			add = self.BuffRoot.height
		end
		return count + add + 5
	end
	return 0;
end

function M:Dispose()
	self:Clear()
	self:RemoveEvent()
end
--endregion

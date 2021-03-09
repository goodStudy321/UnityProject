--region UITeam.lua
--好友
--此文件由[HS]创建生成
require("UI/UICell/UICellTeamSelect")
UITeam = UIBase:New{Name ="UITeam"}

local M = UITeam
local tMgr = TeamMgr

M.DragNum = 9

M.copyId = nil

--注册的事件回调函数

function M:InitCustom()
	name = "lua好友"
	local go = self.gbj
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.CloseBtn = C(UIButton, trans, "CloseBtn", name, false)
	self.CreateBtn = C(UIButton, trans, "Create", name, false)
	self.CreateLab = C(UILabel, trans, "Create/Label", name, false)
	self.MatchBtn = C(UIButton, trans, "Match", name, false)
	self.CleanMatchBtn = C(UIButton, trans, "CleanMatch", name, false)
	self.ResetBtn = C(UIButton, trans, "Reset", name, false)
	self.desLab = C(UILabel,trans,"Sprite/desLab",name,false)

	self.copyGrid = C(UIGrid, trans, "CopyList/Grid")
	self.wildCPa = T(trans, "CopyList/Grid/copy1")
	self.marryCPa = T(trans, "CopyList/Grid/copy2")

	self.equipCopy = T(trans, "CopyList/Grid/copy3/equipCopy")
	self.equipCSelec = T(trans, "CopyList/Grid/copy3/equipCopy/Select")
	self.TweenerECopy = C(UITweener, trans, "CopyList/Grid/copy3/Tween", name, false)
	self.PlayTweenECopy = C(UIPlayTween, trans, "CopyList/Grid/copy3/equipCopy", name, false)

	self.Panel = C(UIPanel, trans, "CopyList", name, false)
	self.ScrollView = C(UIScrollView, trans, "CopyList", name, false)
	self.Grid = C(UIGrid, trans, "CopyList/Grid/copy3/Tween/Grid")
	self.Prefab = T(trans, "CopyList/Grid/copy3/Tween/Grid/Item")
	self.Prefab.gameObject:SetActive(false)
	self.TPanel = C(UIPanel, trans, "TeamList", name, false)
	self.TScrollView = C(UIScrollView, trans, "TeamList", name, false)
	self.TGrid = C(UIGrid, trans, "TeamList/Container", name, false)
	self.TPrefab = T(trans, "TeamList/TeamItem")

	self.TScrollLimit = 3
	self.TeamCopy = {}      
	self.TeamList = {}
	self:InitView()
	self:AddEvent()
	self.TweenerECopy.gameObject:SetActive(true)

	self:UpdateTitle(self.TweenerECopy.gameObject.activeSelf)
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.CloseBtn then	
		E(self.CloseBtn, self.OnCloseBtn, self)
	end
	if self.CreateBtn then	
		E(self.CreateBtn, self.OnCreateBtn, self)
	end
	if self.MatchBtn then
		E(self.MatchBtn, self.OnMatchBtn, self)
	end
	if self.CleanMatchBtn then
		E(self.CleanMatchBtn, self.OnMatchBtn, self)
	end
	if self.ResetBtn then	
		E(self.ResetBtn, self.OnResetBtn, self)
	end
	if self.ResetBtn then	
		E(self.ResetBtn, self.OnResetBtn, self)
	end
	if self.equipCopy then	
		E(self.equipCopy, self.OnEquipCBtn, self, nil, false)
	end
	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	tMgr.eUpdateMatchTeamList[fn](tMgr.eUpdateMatchTeamList, self.OnUpdateTeamList, self)
	tMgr.eUpdateMatchStatus[fn](tMgr.eUpdateMatchStatus, self.UpdateBtn, self)
	tMgr.eCreateTeamSuccess[fn](tMgr.eCreateTeamSuccess, self.CreateTeamSuccess, self)
	tMgr.eUpdateApplyInfo[fn](tMgr.eUpdateApplyInfo, self.UpdateApplyInfos, self)
	tMgr.eUpdateMatchTeam[fn](tMgr.eUpdateMatchTeam, self.UpdateMatchTeam, self)
end
 
function M:InitView()
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
		-- self:Reposition()
	end
	self:UpdateBtn()
end

function M:UpdateApplyInfos()
	UIMgr.Open(UIMyTeam.Name)
	self:Close()
end

function M:UpdateMatchTeam()
	local isMatch = tMgr.IsMatching
	local matchCopyId = tMgr.MatchCopyId
	if isMatch == false and matchCopyId ~= nil and matchCopyId > 0 then
		self:Close()
		UIMgr.Open(UIMyTeam.Name)
	end
end

function M:AddTeamCopy(index, key, temp)
	local copyCfg = CopyTemp[key]
	if copyCfg and (copyCfg.type == 20 or copyCfg.type == 21) then
		return
	end
	if not self.TeamCopy[key] then
		local copyTemp = CopyTemp[key]
		local go = GameObject.Instantiate(self.Prefab)
		go.name = key
		if copyTemp.type == 0 then
			go.transform.parent = self.wildCPa.transform
			go.transform.localPosition = Vector3.New(-5,233,0)
			go.transform.localScale = Vector3.one
			self:SetPrefabData(index,go,key,temp)		
		elseif copyTemp.type == 16 then
			go.transform.parent = self.marryCPa.transform
			go.transform.localPosition = Vector3.New(-5,233,0)
			go.transform.localScale = Vector3.one
			self:SetPrefabData(index,go,key,temp)
		elseif copyTemp.type == 3 then
			local pos = go.transform.localPosition
			pos.y = pos.y - 105
			go.transform.parent = self.Prefab.transform.parent
			go.transform.localPosition = pos
			go.transform.localScale = Vector3.New(0.9,0.9,0.9)
			self:SetPrefabData(index,go,key,temp)
		end
	end
end

function M:SetPrefabData(index,go,key,temp)
	go:SetActive(true)
	local team = UICellTeamSelectCopy.New(go)
	team:Init()
	team:UpdateData(temp)
		-- team:UpdateBG(index)
	-- team:UpdateBGState(temp)
	UITool.SetLsnrSelf(go, self.ClickCell, self, nil, false)
	self.TeamCopy[key] = team
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

function M:UpdateBtn()
	local value = false
	if self.CurSelectCell and self.CurSelectCell.Temp then
		value = true
	end
	if self.CreateLab then
		local t = "创建队伍"
		-- if value == true then
		-- 	t = "我的队伍"
		-- end
		self.CreateLab.text = t
	end
	local isMatch = tMgr.IsMatching
	local matchCopyId = tMgr.MatchCopyId
	local info = tMgr.TeamInfo
	local id = info.TeamId --判断自己是否有队伍
	local strLab = ""
	if id ~= nil then
		strLab = ""
	elseif #tMgr.CopyTeamList == 0 and isMatch == false and id == nil then
		strLab = "还没有队伍，赶紧创建自己的队伍!"
	elseif isMatch and id == nil then
		strLab = "正在为你匹配队伍……"
	end

	-- iTrace.Error("GS","isMatch==",isMatch," MatchCopyId==",matchCopyId," #tMgr.CopyTeamList=",#tMgr.CopyTeamList)
	self.desLab.text = strLab
	if self.MatchBtn then
		self.MatchBtn.gameObject:SetActive(not isMatch)
		self.MatchBtn.Enabled = value
	end
	if self.CleanMatchBtn then
		self.CleanMatchBtn.gameObject:SetActive(isMatch)
		self.CleanMatchBtn.Enabled = value
	end
	if self.ResetBtn then
		self.ResetBtn.Enabled = value
	end
end
---------------------------------------------------

function M:OnUpdateTeamList()
	self.TGridTran = self.TGrid.transform
	local list = tMgr.CopyTeamList
	local len = #list

	local info = tMgr.TeamInfo
	local id = info.TeamId --判断自己是否有队伍

	local desStr = ""
	self:TClean()
	if len == 0 then
		if id ~= nil then
			self.desLab.text = ""
		elseif tMgr.IsMatching == false then
			self.desLab.text = "还没有队伍，赶紧创建自己的队伍!"
		end
		return 
	end
	self.desLab.text = desStr
	for i=1,len do
		local team = list[i]
		if team then
			self:AddTeamItem(tostring(team.TeamId), team)
		end
	end
	-- self:TReposition()
	self.TGrid:Reposition()
end

function M:AddTeamItem(key, data)
	local go = GameObject.Instantiate(self.TPrefab)
	go.name = key
	go.transform.parent = self.TGrid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	local team = UICellTeamSelect.New(go)
	team:Init()
	team:UpdateData(data)
	self.TeamList[key] = team
end

function M:OpenCustom()
	local cell = self.CurSelectCell
	if cell then
		self:ClickCell(cell)
	end
	self:UpdateBtn()
end

---------------------------------------------------
function M:ClickDefCell()
	local copy = CopyMgr:GetCurCopy(CopyMgr.Equip)
	self.guideState = false
	if copy then
		local copyId = copy.Temp.id
		-- self.guideState = CopyMgr:StartGuide(copyId,2)
		self:ClickCell()
		self:UpdateBG()
	end
end

--默认选择野外挂机可进入
function M:SelectWildEnter()
	self.copyId = GlobalTemp["60"].Value3
	self:ClickCell()
	self:UpdateBG()
end

function M:ClickCell(go)
	local userLv = User.MapData.Level
	local cell = nil
	local isInit = true
	if self.copyId then
		cell = self.TeamCopy[tostring(self.copyId)]
		self.copyId = nil
	else
		cell = self.TeamCopy[go.name]
	end
	if not cell then return end
	if cell.Temp.lv > userLv then 
		isInit = false
	end
	if not cell:IsOpen(isInit)then
		return 
	end

	local copyTemp = CopyTemp[tostring(cell.Temp.id)]
	if copyTemp.type == 16 or copyTemp.type == 0 then
		-- local pt = self.PlayTweenECopy
		-- if pt and pt.isPlayStatus == true then 
		-- 	pt:Play(false) 
		-- end
		self:UpdateTitle(false)
	end

	if self.CurSelectCell then
		if self.CurSelectCell.Temp.id == cell.Temp.id then 
			return 
		end
		self.CurSelectCell:IsSelect(false)
	end

	self.CurSelectCell = cell
	self.CurSelectCell:IsSelect(true)
	local temp = cell.Temp
	if temp then
		self.Key = tostring(temp.id)
		tMgr:GetCopyTeamList(temp.id)
		self.selectCopyId = temp.id
	end
	self:UpdateBtn()
end

function M:OnCloseBtn(go)
	self:Close()
end

function M:OnCreateBtn(go)
	-- self:Close()
	-- UIMgr.Open(UIMyTeam.Name)

	-- local info = TeamMgr.TeamInfo
	-- if not info.TeamId then 
	-- 	MsgBox.ShowYesNo("您当前没有队伍， 是否创建队伍？", self.YesCb, self)
	-- 	return
	-- end
	local isMatch = tMgr.IsMatching
	if isMatch then
		local cell = self.CurSelectCell
		if not cell or not cell.Temp then
			return
		end
		local id = cell.Temp.id
		tMgr:ReqTeamMatch(id, false)
	end
	TeamMgr:ReqCreateTeam()
end

function M:YesCb()
	TeamMgr:ReqCreateTeam()
end

function M:OnMatchBtn(go)
	local cell = self.CurSelectCell
	if not cell or not cell.Temp then
		UITip.Error("请选择队伍！！！")
		return
	end
	local id = cell.Temp.id
	if go.name == self.MatchBtn.name then
		tMgr:ReqTeamMatch(id, true)
	elseif go.name == self.CleanMatchBtn.name then
		tMgr:ReqTeamMatch(id, false)
	end
end

function M:CreateTeamSuccess()
	if M.CurSelectCell == nil then
		return
	end
	TeamMgr.CurCopyId = M.CurSelectCell.Temp.id
	M:Close()
	UIMgr.Open(UIMyTeam.Name,M.CreateTeamCb)
end

function M.CreateTeamCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:OnCopyEnter()
	end	
end

function M:OnResetBtn()
	local cell = self.CurSelectCell
	if not cell or not cell.Temp then return end
	local temp = cell.Temp 
	if not temp then return end
	tMgr:ChearCopyTeamList()
	tMgr:GetCopyTeamList(temp.id)
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

--重置ScrollView是否可以拖动状态
function M:TReposition()
	if self.TGrid:GetChildList().Count > self.TScrollLimit then 
		self.TScrollView.isDrag = true
	else
		self.TScrollView.isDrag = false
	end
	self.TGrid:Reposition()
end

function M:CloseCustom()
	if self.CurSelectCell then
		self.CurSelectCell:IsSelect(false)
		self.CurSelectCell = nil
		self:TClean()
	end
	self.guideState = false
end

function M:Clean()
	if self.TeamCopy then
		for k,v in pairs(self.TeamCopy) do
			v:Dispose(true)
			self.TeamCopy[k] = nil
		end
	end
end

function M:TClean()
	if self.TeamList then
		for k,v in pairs(self.TeamList) do
			v:Dispose(true)
			self.TeamList[k] = nil
		end
	end
end

function M:DisposeCustom()
	self:Clean()
	self:TClean()
	self.CloseBtn = nil
	self.CreateBtn = nil
	self.ResetBtn = nil
	self.desLab = nil

	self.equipCopy = nil

	self.Panel = nil
	self.ScrollView = nil
	self.Prefab = nil

	self.TPanel = nil
	self.TScrollView = nil
	self.TGrid = nil
	self.TPrefab = nil

	self.copyGrid = nil
	self.wildCPa = nil
	self.marryCPa = nil

	self.OnClickCell = nil
	self.OnClickTitle = nil

	self.TScrollLimit = nil
	self.copyId = nil
end

return M
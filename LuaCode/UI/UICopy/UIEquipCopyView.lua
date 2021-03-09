--region UIEquipCopyView.lua
--Date	
--此文件由[HS]创建生成

UIEquipCopyView = Super:New{Name = "UIEquipCopyView"}
local M = UIEquipCopyView
local tMgr = TeamMgr

M.eClose = Event()
M.Items = {}

function M:Init(go)
	local name = self.Name
	self.go = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	local E = UITool.SetLsnrSelf

	self.Num = C(UILabel, trans, "Num", name, false)
	self.NumBtn = C(UIButton, trans, "NumBtn", name, false)
	self.Btn1 =  T(trans, "Button1")
	self.Btn2 =  T(trans, "Button2")
	self.Btn3 =  T(trans, "CleanMatch")

	self.Btn2Lab = C(UILabel,trans,"Button2/Label")
	self.Btn2Lab.text = "加入队伍"

	self.Panel = C(UIScrollView, trans, "ScrollView", name, false)
	self.PanelC = C(UIPanel,trans,"ScrollView", name, false)
	self.Grid = C(UIGrid, trans, "ScrollView/Grid", name, false)
	self.Prefab = T(trans, "ScrollView/Grid/Item")

	E(self.NumBtn, self.OnClickNumBtn, self)
	E(self.Btn1, self.OnClickBtn1, self)
	E(self.Btn2, self.OnClickBtn2, self)
	E(self.Btn3, self.OnClickBtn3, self)

	self.SelectItem = nil
	self:InitData()
end

function M:Open()
	self.isGuide = false
	UIGuide.eOnClickArea:Add(self.ClickGuide,self)
	self.go:SetActive(true)
	local copyId = self.Temp.id
	-- local state = CopyMgr:StartGuide(copyId,1)
end

function M:Close()
	UIGuide.eOnClickArea:Remove(self.ClickGuide,self)
	self.go:SetActive(false)
	self.isGuide = false
end

function M:IsActive()
	return self.go.activeSelf
end

function M:ClickGuide(guideCfg)
	if guideCfg then
		self.isGuide = true
	end
end

function M:InitData()
	local copy = CopyMgr.Copy
	if not copy then return end
	local data = copy[CopyMgr.Equip]
	if not data then return end
	local list = data.IndexOf
	local dic = data.Dic
	if not list then return end
	local len = #list
	local needLv = User.MapData.Level
	for i=1,len do
		local k = list[i]
		if k then
			local info = dic[tostring(k)]
			if info then
				self:AddItem(k, info)
			end
		end
	end
	self.Grid:Reposition()
	self:UpdateData(data)
	self:UpdateSelect(true)
	self:UpdateBtnStatus()
end

function M:AddItem(id, info)
	local go = GameObject.Instantiate(self.Prefab)
	local k = tostring(id)
	go.name = k
	local trans = go.transform
	trans:SetParent(self.Grid.transform)
	trans.localScale = Vector3.one
	trans.localPosition = Vector3.zero
	go:SetActive(true)
	local item = ObjPool.Get(UICellEquipCopyItem)
	item:Init(go)
	item:UpdateInfo(info)
	self.Items[k] = item
	UITool.SetLsnrSelf(go, self.ClickItems, self, nil, false)
end

function M:UpdateBtnStatus()
	local info = tMgr.TeamInfo
	local isMatch = tMgr.IsMatching
	local isTeam = false
	local isCapt = false
	if info then
		local id = info.TeamId
		local captId = info.CaptId
		isTeam = id ~= nil
		isCapt = captId and tostring(captId) == User.MapData.UIDStr
	end
	if self.Btn1 then
		self.Btn1:SetActive(not isTeam or isCapt)
	end
end

function M:UpdateData(data)
	self:UpdateNum()
end

--副本剩余次数
function M:UpdateNum()
	local value = ""
	local temp = self.Temp
	if not temp then return end
	local copyData = CopyMgr.Copy[tostring(temp.type)]
	local max = temp.num
	if copyData then
		local cNum = copyData.Num
		max = max + copyData.Buy
		local rato = string.format("(%s/%s)", max-cNum, max)
		if cNum < max then
			value = string.format("[F8D7B4]%s[-]", rato)
		else
			value = string.format("[ff0000]%s[-]", rato)
		end
	end
	if self.Num then
		self.Num.text = value
	end
	if self.NumBtn then
		self.NumBtn.Enabled = max > 0
	end
end

function M:UpdateSelect(isInit)
	local copy = CopyMgr:GetCurCopy(CopyMgr.Equip)
	if copy then
		local items = self.Items
		local key = tostring(copy.Temp.id)--默认选中第一个
		if items and items[key] then
			self:ClickItems(items[key].GO, isInit)
		end
	end
end

function M:ClickItems(go, isInit)
	local key = go.name
	local item = self.Items[key]
	if not item then return end
	if not item:IsOpen(isInit)then
		return 
	end
	if self.SelectItem then
		if self.SelectItem.GO.name == item.GO.name then
			return
		end
		self.SelectItem:IsSelect(false)
	end
	self.SelectItem = item
	item:IsSelect(true)
	self.Temp = item.Temp
	local copy = CopyMgr.Copy
	local data = copy[CopyMgr.Equip]
	if not data then return end
	self:UpdateData(data)
end

function M:OnClickNumBtn(go)
	local temp = self.Temp
	if not item then return end
	local copyData = CopyMgr.Copy[tostring(temp.type)]
	local offset = temp.buy
	if copyData then
		local buy = copyData.Buy
		local max = temp.buy
		offset = max - buy
		if offset == 0 then
			MsgBox.ShowYes("已达到今日的购买上限，不能继续购买次数")
		else
			MsgBox.ShowYesNo(string.format("还能购买%s次副本进入,是否购买？", offset),self.OnBuyCopyNum,self)
		end
	end
end

function M:OnBuyCopyNum()
	local temp = self.Temp
	if not temp then return end
	local copyData = CopyMgr.Copy[tostring(temp.type)]
	local buy = copyData.Buy
	local cost = temp.bCost[buy+1] or temp.bCost[#temp.bCost]
	if RoleAssets.Gold < cost then
		MsgBox.ShowYes(string.format("购买进入次数需要%s元宝。元宝不足，不能购买", cost))
	else
		CopyMgr:ReqCopyBuyTimes(temp.id)
	end
end

--点击按钮1
function M:OnClickBtn1(go)
	local temp = self.Temp
	if not temp then 
		MsgBox.ShowYes("没有副本信息")
		return 
	end

	if User.MapData.Level < temp.lv then
		MsgBox.ShowYes("进入失败，不满足进入等级")
		return
	end

	local info = TeamMgr.TeamInfo
	if not info.TeamId then 
		MsgBox.ShowYesNo("您当前没有队伍， 是否创建队伍？", self.YesCb, self)
		return
	end
	self:EnterCopyCondi()
end

function M:YesCb()
	TeamMgr:ReqCreateTeam()
end

--判断进入副本队伍条件
function M:EnterCopyCondi()
	local info = tMgr.TeamInfo
	if not info then return end
	local list = info.Player
	local len  = #list
	local isCaptInCopy = false
	local isInCopy = false
	local roleName = nil
	local isOnLine = true
	local mapId = nil
	local sceneData = nil
	local sceneType = nil
	for i=1,len do
		local data = list[i]
		mapId = tostring(data.MapId)
		sceneData = SceneTemp[mapId]
		sceneType = sceneData.maptype
		if data.ID == info.CaptId and sceneType == 2 then
			isCaptInCopy = true
		elseif data.IsOnline == false then
			isOnLine = false
			roleName = data.Name
		elseif data.ID ~= info.CaptId and sceneType == 2 then
			isInCopy = true
			roleName = data.Name
		end
	end
	if isCaptInCopy == true then
		UITip.Error("你仍在副本中，无法执行该操作")
		return
	elseif isOnLine == false and roleName then
		local str = string.format("%s已离线",roleName)
		UITip.Error(str)
		return
	elseif isInCopy == true and roleName then
		local str = string.format("%s仍在副本中",roleName)
		UITip.Error(str)
		return
	elseif len < 3 then
		MsgBox.ShowYesNo("队伍人数不足3人，是否继续",self.ContinueCb,self)
		return
	elseif len >= 3 then
		tMgr:ReqStartCopyTeam(self.Temp.id,true)
		UIMgr.Close(UICopy.Name)
	end
end

function M:ContinueCb()
	if self.Temp then
		if self.Temp.id == 0 then
			UITip.Error("请选择副本")
			return
		end
		tMgr:ReqStartCopyTeam(self.Temp.id,true)
		UIMgr.Close(UICopy.Name)
	end
end

--点击按钮2
function M:OnClickBtn2(go)
	local temp = self.Temp
	if not temp then 
		MsgBox.ShowYes("没有副本信息")
		return 
	end
	local isGuide = self.isGuide
	local info = TeamMgr.TeamInfo
	local teamId = info.TeamId
	if isGuide == true then
		self:GuideDef()
		self.eClose()
	elseif teamId == nil then
		UITeam.copyId = temp.id
		UIMgr.Open(UITeam.Name, self.OpenUITeam, self)
		self.eClose()
	elseif teamId ~= nil then
		TeamMgr.CurCopyId = temp.id
		UIMgr.Open(UIMyTeam.Name,self.CreateTeamCb,self)
		self.eClose()
	end
end

--引导处理
function M:GuideDef()
	local teamId = TeamMgr.TeamInfo.TeamId
	if teamId ~= nil and teamId > 0 then
		TeamMgr:ReqLeave()
	end
	TeamMgr:ReqTeamGuideMatch()
end

function M:OpenUITeam(name)
	local ui = UIMgr.Dic[name]
	if ui then 
		ui:ClickDefCell()
	end
end

function M:CreateTeamCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:OnCopyEnter()
	end	
end

function M:OnClickBtn3(go)
	local temp = self.Temp
	if not temp then 
		MsgBox.ShowYes("没有副本信息")
		return 
	end
	tMgr:ReqTeamMatch(temp.id, false)
end

function M:UpdateCopyData(t)
	local data = CopyMgr.Copy[CopyMgr.Equip]
	if not data then return end
	self:UpdateData(data)
	self:UpdateUserLv()
	self:UpdateSelect()
end

function M:UpdateUserLv()
	local items  = self.Items
	if items then
		for k,v in pairs(items) do
			v:UpdateRealInfo()
		end
	end
end

function M:Dispose()
	self.SelectItem = nil
	TableTool.ClearDicToPool(self.Items)
	self.Temp = nil
	TableTool.ClearUserData(self)
end

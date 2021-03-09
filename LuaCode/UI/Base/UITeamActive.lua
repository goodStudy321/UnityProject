--region UITeamActive.lua
--好友
--此文件由[HS]创建生成

UITeamActive = UIBase:New{Name ="UITeamActive"}

local M = UITeamActive
local tMgr = TeamMgr

M.EnumInvite = 1
M.EnumApply = 2
M.EnumEnter = 3

--注册的事件回调函数

function M:InitCustom()
	local name = "lua队伍相关面板"
	local go = self.gbj
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.TeamRoot  = T(trans, "Team")
	self.Invite = T(trans, "Team/Invite")
	self.Apply = T(trans, "Team/Apply")
	self.Icon = C(UITexture, trans, "Team/Icon", name, false)
	self.IconObj = T(trans,"Team/Icon")
	self.NameLab = C(UILabel, trans, "Team/Name", name, false)
	self.Lv = C(UILabel, trans, "Team/Lv", name, false)

	self.TimeLab = C(UILabel, trans, "Agree/TimeLab", name, false)
	
	self.DownCount = C(UISprite, trans, "EnterCopy/Slider", name, false)
	
	self.TimerTool = ObjPool.Get(DateTimer)
	self.TimerTool.invlCb:Add(self.InvCountDown, self)
	self.TimerTool.complete:Add(self.EndCountDown, self)

	self.isChapter = nil

	self.EnterInfo = {}
	self.EnterInfo.Name = {}
	self.EnterInfo.Icon = {}
	self.EnterInfo.IconObj = {}
	self.EnterRoot = T(trans, "EnterCopy")
	local len = tMgr.PlayerLimit
	for i=1, len do
		local lab = C(UILabel, trans, string.format("EnterCopy/Name%s",i))
		local icon = C(UITexture, trans, string.format("EnterCopy/Icon%s",i))
		local iconObj = T(trans, string.format("EnterCopy/Icon%s",i))
		table.insert(self.EnterInfo.Name, lab)
		table.insert(self.EnterInfo.Icon, icon)
		table.insert(self.EnterInfo.IconObj, iconObj)
	end

	self.AgreeBtn = T(trans, "Agree")
	self.RefuseBtn = T(trans, "Refuse")
	self.CancelBtn = T(trans, "Cancel")
	self.Type = 0
	self.ActiveInfo = nil
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.AgreeBtn then
		E(self.AgreeBtn, self.OnAgreeBtn, self)
	end
	if self.RefuseBtn then	
		E(self.RefuseBtn, self.OnRefuseBtn, self)
	end
	if self.CancelBtn then	
		E(self.CancelBtn, self.OnRefuseBtn, self)
	end
	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	tMgr.eUpdateJoinCopyTeamReady[fn](tMgr.eUpdateJoinCopyTeamReady, self.UpdateJoinCopyTeamReady, self)
	tMgr.eRefuseJoinCopy[fn](tMgr.eRefuseJoinCopy, self.RefuseJoinCopy, self)
	tMgr.eRefuseoinTeam[fn](tMgr.eRefuseoinTeam, self.RefuseJoinTeam, self)
	--tMgr.eUpdateApplyInfo[fn](tMgr.eUpdateApplyInfo, self.UpdateApplyInfo, self)
end
---------------------------------------------------

--倒计时间隔回调
function M:InvCountDown()
	local s = 1
	if self.TimerTool then
		s = 1 - self.TimerTool.pro
	end
	self.Times = self.Times - 1
	self.TimeLab.text = self.Times
	if self.DownCount then
		self.DownCount.fillAmountValue = s
	end
end

--倒计时结束回调
function M:EndCountDown()
	self:InvCountDown()
	if self.EnterRoot.gameObject.activeSelf == false then
		self.Type = self.EnumInvite
		self:OnAgreeBtn()
	else
		tMgr:ReqJoinCopyTeamReady(true)
	end
	self:Close()
end


-------------------------------------------------

function M:CheckInfo(list, str)
	if not list then
		self:Close()
		return nil
	end
	local len = #list
	if len == 0 then
		UITip.Error(nil)
		self:Close()
		return nil
	end
	self.ActiveInfo = list[1]
	return self.ActiveInfo
end

function M:ShowTeam(value)
	if self.TeamRoot then self.TeamRoot:SetActive(value) end
end

function M:ShowEnter(value)
	if self.EnterRoot then self.EnterRoot:SetActive(value) end
end

function M:UpdateBtn(value)
	if self.AgreeBtn then
		self.AgreeBtn:SetActive(value)
	end
	if self.RefuseBtn then
		self.RefuseBtn:SetActive(value)
	end
	if self.CancelBtn then
		self.CancelBtn:SetActive(not value)
		self.isChapter = not value
	end
end

function M:UpdateIcon(path)	
	if self.Icon then
		self:UnloadIcon()
		if StrTool.IsNullOrEmpty(path) then	
			self.Icon.mainTexture = nil
			self.Icon.gameObject:SetActive(false)
			self.Icon.gameObject:SetActive(true)
			return
		end
		path = string.format( "tx_0%s.png", path)
		self.IconName = path
		AssetMgr:Load(path,ObjHandler(self.SetIcon, self))
	end
end

function M:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = tex
	end
end

function M:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

function M:UpdateName(value)
	if self.NameLab then
		self.NameLab.text = value
	end
end

function M:UpdateLv(value)
	if self.Lv then
		self.Lv.text = value
	end
end

function M:ShowInvite(value)
	if self.Invite then
		self.Invite:SetActive(value)
	end
end

function M:ShowApply(value)
	if self.Apply then
		self.Apply:SetActive(value)
	end
end
---------------------------------------------------
function M:OnShowInvite()
	local info = self:CheckInfo(tMgr.InviteInfo,"没有组队邀请")
	if not info then return end
	self.Type = self.EnumInvite
	self:ShowTeam(true)
	self:ShowInvite(true)
	self:UpdateName(info.Name)
	self:UpdateLv(info.Lv)
	self:UpdateIcon(info.Career)
end

---------------------------------------------------

function M:OnShowApply()
	local info = self:CheckInfo(tMgr.ApplyInfo,"没有加入队伍请求")
	if not info then return end
	self.Type = self.EnumApply
	self:ShowTeam(true)
	self:ShowApply(true)
	self:UpdateName(info.Name)
	self:UpdateLv(info.Lv)
	self:UpdateIcon(info.Career)
end

---------------------------------------------------
function M:OnShowEnterCopy()
	local info = tMgr.EnterCopy
	if not info or not info.CopyId then
		UITip.Error("没有副本进入信息")
		return 
	end
	self.Type = self.EnumEnter
	self:ShowEnter(true)
	self:UpdatePlayerInfo()
	self:UpdateJoinCopyTeamReady()
	self:UpdateBtn(TeamMgr.TeamInfo and TeamMgr.TeamInfo.CaptId ~= User.MapData.UIDStr)
end

function M:UpdatePlayerInfo()
	local info = tMgr.TeamInfo
	if not info then self:Close() end
	local players = info.Player
	if not players then self:Close() end
	local UIInfo = self.EnterInfo
	if not UIInfo then self:Close() end
	local icons =  UIInfo.Icon
	local labs = UIInfo.Name
	local len = #players
	for i=1,len do
		local player = players[i]
		if player then
			local lab = labs[i]
			if lab then
				lab.text = player.Name
				lab.gameObject:SetActive(true)
			end
			local icon = icons[i]
			if icon then
				icon.gameObject.name = tostring(player.ID)
				self:UpdateOtherIcon(icon, player.Career)
				icon.gameObject:SetActive(true)
			end
		end
	end
end

function M:UpdateOtherIcon(icon, value)
	if StrTool.IsNullOrEmpty(value) then	
		icon.mainTexture = nil
		icon.gameObject:SetActive(false)
		icon.gameObject:SetActive(true)
		return
	end
	local path = string.format( "tx_0%s.png", value)
	self.TeamIconName = path
	local del = ObjPool.Get(DelLoadTex)
	del:Add(icon)
	del:SetFunc(self.SetTeamIcon,self)
	AssetMgr:Load(path,ObjHandler(del.Execute, del))
end

function M:SetTeamIcon(tex, icon)
	if icon then
		icon.mainTexture = nil
		icon.mainTexture = tex
	end
end

function M:UnloadTeamIcon()
	if not StrTool.IsNullOrEmpty(self.TeamIconName) then
		AssetMgr:Unload(self.TeamIconName, ".png", false)
	end
end

function M:RefuseJoinCopy()
	if self.isChapter then
		UIMgr.Open(UIMyTeam.Name)
	end
	self:Close()
end

function M:RefuseJoinTeam()
	self:Close()
end

function M:UpdateJoinCopyTeamReady()
	local data = tMgr.EnterCopy
	if not data then return end
	local icons =  self.EnterInfo.Icon
	local iconsObj = self.EnterInfo.IconObj
	if not icons then return end
	if not iconsObj then return end
	local list = data.Readys
	if not list then return end
	local len = #list
	local iLen = #icons
	for i=1,len do
		local id = list[i].ID
		for j=1,iLen do
			local icon = icons[j]
			local iconObj = iconsObj[j]
			if icon and not LuaTool.IsNull(iconObj) and iconObj.name == tostring(id) then
				local color = Color.New(1,1,1,1)
				if list[i].Ready == false then
					color = Color.New(0,1,1,1)
				end
				iconObj:SetActive(true)
				icon.color = color
			end
		end
	end
end

---------------------------------------------------
function M:OnAgreeBtn(go)
	local info = self.ActiveInfo 
	local t = self.Type
	if t == self.EnumInvite then
		if not info then
			UITip.Error("缺少玩家数据")
			return
		end
		tMgr:ReqInviteReplyTeam(1, info.TeamId, info.ID)
		self:Close()
	elseif t == self.EnumApply then
		if not info then
			UITip.Error("缺少玩家数据")
			return
		end
		tMgr:ReqTeamApplyReply(1, info.ID)
		self:Close()
	elseif t == self.EnumEnter then
		tMgr:ReqJoinCopyTeamReady(true)
		self:Close()
	end
end

function M:OnRefuseBtn(go)
	local info = self.ActiveInfo 
	local t = self.Type
	if t == self.EnumInvite then
		if not info then
			UITip.Error("缺少玩家数据")
			return
		end
		tMgr:ReqInviteReplyTeam(2, info.TeamId, info.ID)
		tMgr:RemoveInviteReplyData(info.ID)
	elseif t == self.EnumApply then
		if not info then
			UITip.Error("缺少玩家数据")
			return
		end
		tMgr:ReqTeamApplyReply(2, info.ID)
		tMgr:RemoveApplyReplyData(info.ID)
	elseif t == self.EnumEnter then
		tMgr:ReqJoinCopyTeamReady(false)
		self:Close()
	end
	-- self:Close()
end

function M:OpenCustom()
	self.Times = 10
	if self.TimerTool then
		self.TimerTool.seconds = self.Times
		self.TimerTool:Start()
	end
end

function M:CloseCustom()
	self:RemoveEvent()
	self:Clean()
end

function M:Clean()
	self:UnloadIcon()
	self:UnloadTeamIcon()
	self:ShowTeam(false)
	self:UpdateIcon(nil)
	self:UpdateName("")
	self:UpdateLv("")
	self:ShowInvite(false)
	self:ShowApply(false)
	self:ShowEnter(false)
	self:UpdateBtn(true)
	local UIInfo = self.EnterInfo
	if not UIInfo then self:Close() end
	local icons =  UIInfo.Icon
	local len = #icons
	for i=1,len do
		local icon = icons[len]
		if icon then
			icon.gameObject:SetActive(false)
			self:UpdateOtherIcon(icon, nil)
		end
	end
	local labs = UIInfo.Name
	local len = #labs
	for i=1,len do
		local lab = labs[len]
		if lab then
			lab.gameObject:SetActive(false)
		end
	end
	if self.TimerTool then 
		self.TimerTool:Stop()
	end
end

function M:DisposeCustom()
	if self.TimerTool then self.TimerTool:AutoToPool() end
	self.TeamRoot  = nil
	self.Invite = nil
	self.Apply = nil
	self.Icon = nil
	self.iconObj = nil
	self.NameLab = nil
	self.Lv = nil
	self.Type = nil
	self.AgreeBtn = nil
	self.TalkBtn = nil
	self.isChapter = nil
end

return M
--endregion

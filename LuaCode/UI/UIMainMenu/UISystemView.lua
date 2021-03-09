--region UISystemView.lua
--Date
--此文件由[HS]创建生成


UISystemView = {}
local M = UISystemView
local tMgr = TeamMgr
local fMgr = FriendMgr
local mMgr = MailMgr

require("UI/UIMainMenu/UISysActBtn")

--注册的事件回调函数

function M:New(go)
	local actMsg = ActivityMsg
	local name = "UI主界面系统按钮窗口"
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Items = {}

	self.Items.NewMail = C(UIButton, trans, "NewMail", name, false)
	self.Items.NewFriend = C(UIButton, trans, "NewFriend", name, false)
	self.Items.TeamInvite = C(UIButton, trans, "TeamInvite", name, false)
	self.Items.TeamApply = C(UIButton, trans, "TeamApply", name, false)
	self.Items.RedPacket = C(UIButton, trans, "RedPacket", name, false)
	self.Items.NewPropose = C(UIButton, trans, "NewPropose", name, false)
	self.Items.NewFamilyHelp = C(UIButton, trans, "NewFamilyHelp", name, false)
	self.Items.NewChat = C(UIButton,trans,"NewChat",name,false)
	self.Items.NewFlowers = C(UIButton,trans,"NewFlowers",name,false)
	self.Items.NewTreasure = C(UIButton,trans,"NewTreasure",name,false)
	self.Items.BtnLove=T(trans,"BtnLove");
	self.Items.LvLimitBuyBtn=T(trans,"LvlimitBtn");

	self.sysActTab = {}
	self.sysActDataTab = {}
	self.Items.ThrUniBtn=T(trans,"ThrUniBtn"); --诛仙战场  10001  ZXZC
	self.Items.PeakBtn=T(trans,"PeakBtn"); --仙峰论剑	10002  XFLJ
	self.Items.FamilyActBtn=T(trans,"FamilyActBtn"); --守卫道庭	10003	SWDT
	self.Items.FamilyAnswBtn=T(trans,"FamilyAnswBtn"); --道庭答题	10006  DTDT
	self.Items.FamilyWarBtn=T(trans,"FamilyWarBtn"); --道庭大战	10010  DTDZ
	self.Items.FamilyBossBtn=T(trans,"FamilyBossBtn"); --道庭神兽	10012  DTSS
	self.Items.TopFightBtn=T(trans,"TopFightBtn"); --逍遥神坛	10008   XYST
	self.Items.DemonBtn=T(trans,"DemonBtn"); --魔域禁地 	10011  MYBS
	self.Items.AnswerBtn=T(trans,"AnswerBtn"); --蜀山论道 	10004	SSLD
	self.sysActTab[actMsg.ZXZC] = self.Items.ThrUniBtn
	self.sysActTab[actMsg.XFLJ] = self.Items.PeakBtn
	self.sysActTab[actMsg.SWDT] = self.Items.FamilyActBtn
	self.sysActTab[actMsg.DTDT] = self.Items.FamilyAnswBtn
	self.sysActTab[actMsg.DTDZ] = self.Items.FamilyWarBtn
	self.sysActTab[actMsg.DTSS] = self.Items.FamilyBossBtn
	self.sysActTab[actMsg.XYST] = self.Items.TopFightBtn
	self.sysActTab[actMsg.MYBS] = self.Items.DemonBtn
	self.sysActTab[actMsg.SSLD] = self.Items.AnswerBtn

	for k,v in pairs(self.sysActTab) do
		local data = ObjPool.Get(UISysActBtn)
		data:Init(k,v)
		self.sysActDataTab[k] = data
	end

	self.LvLimitRed = T(trans,"LvlimitBtn/Red")
	self.DayLimTime = C(UILabel,trans,"LvlimitBtn/TimerLab",name,false)
	self.NewMailGo = self.Items.NewMail.gameObject
	self.NewMailGo:SetActive(false)

	self.anchor = ComTool.Get(UIWidget, trans, "NewMail", name, false)
	self.oriLeft = self.anchor.leftAnchor.absolute
	self.oriRight = self.anchor.rightAnchor.absolute

	self.SortList = {}

	self:AddEvent()
	self:RequestFriendStatus()
	return M
end

function M:ScreenChange(orient, init)
	local reset = UITool.IsResetOrient(orient)
	UITool.SetLiuHaiAbsolute(self.anchor, true, reset, self.oriLeft,self.oriRight)
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	local newMail = self.Items.NewMail
	if newMail then
		E(newMail, self.OnClickNewMailBtn, self)
	end
	local newFriend = self.Items.NewFriend
	if newFriend then
		E(newFriend, self.OnClickNewFriendBtn, self)
	end
	local teamInvite = self.Items.TeamInvite
	if teamInvite then
		E(teamInvite, self.OnClickTeamInviteBtn, self)
	end
	local teamApply = self.Items.TeamApply
	if teamApply then
		E(teamApply, self.OnClickTeamApplyBtn, self)
	end
	local redPacket = self.Items.RedPacket
	if redPacket then
		E(redPacket, self.OnClickRedPacketBtn, self)
	end
	local newPropose = self.Items.NewPropose
	if newPropose then
		E(newPropose, self.OnClickNewProposeBtn, self)
	end
	local NewFamilyHelp = self.Items.NewFamilyHelp
	if NewFamilyHelp then
		E(NewFamilyHelp, self.OnClickNewFamilyHelpBtn, self)
	end
	local newChat = self.Items.NewChat
	if newChat then
		E(newChat,self.OnClickNewChat,self)
	end
	local newFlowers = self.Items.NewFlowers
	if newFlowers then
		E(newFlowers,self.OnClickNewFlowers,self)
	end
	local newTreasure = self.Items.NewTreasure
	if newTreasure then
		E(newTreasure,self.OnClickNewTreasure,self)
	end
	local LvLimitBuyBtn = self.Items.LvLimitBuyBtn
	if LvLimitBuyBtn then
		E(LvLimitBuyBtn, self.OnOpenLvBuy, self)
	end
	local btnLove = self.Items.BtnLove
	if btnLove then
		E(btnLove, self.OnClickLove, self)
	end
	--euiopen:Add(self.OpenNewMail, self)
	self:SetEvent("Add")
end

function M:RemoveEvent()
	--euiopen:Remove(self.OpenNewMail, self)
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	CopyMgr.eMarryCopyRequest[fn](CopyMgr.eMarryCopyRequest, self.MarryCopyRequest, self)
	LvLimitBuyMgr.eOpenOrClose[fn](LvLimitBuyMgr.eOpenOrClose, self.OpenOrClose, self)
	LvLimitBuyMgr.eUpdateTime[fn](LvLimitBuyMgr.eUpdateTime, self.UpdateTime, self)
	tMgr.eUpdateInviteInfo[fn](tMgr.eUpdateInviteInfo, self.UpdateInviteInfo, self)
	tMgr.eUpdateApplyInfo[fn](tMgr.eUpdateApplyInfo, self.UpdateApplyInfo, self)
	fMgr.eUpdateRequest[fn](fMgr.eUpdateRequest, self.RequestFriendStatus, self)
	mMgr.eOwnNew[fn](mMgr.eOwnNew, self.RespNewLtr, self)
	FamilyMgr.eUpdateRedPack[fn](FamilyMgr.eUpdateRedPack, self.UpdateRedPacket, self)
	euiopen[fn](euiopen, self.OpenNewMail, self)
	MailMgr.eOpen[fn](MailMgr.eOpen,self.RespOpen,self)
	MailMgr.eRespDel[fn](MailMgr.eRespDel,self.RespDelMail,self)
	MailMgr.eRespGoods[fn](MailMgr.eRespGoods,self.SetMailActive,self)
	MarryMgr.eShowPop[fn](MarryMgr.eShowPop, self.RespProposeOpen, self)
	FamilyMissionMgr.eHelpBtn[fn](FamilyMissionMgr.eHelpBtn, self.RespHelpBtn, self)
	FlowersMgr.eReceive[fn](FlowersMgr.eReceive, self.UpdateFlowersStatus, self)
	TreasureMapMgr.eReceive[fn](TreasureMapMgr.eReceive, self.UpdateTreasureStatus, self)

	FriendMgr.eRed[fn](FriendMgr.eRed, self.PrivateChat, self)
	RedPacketActivMgr.eCheckBtn[fn](RedPacketActivMgr.eCheckBtn, self.UpdateRedPacket, self);

	ActivityMsg.eActivityInfo[fn](ActivityMsg.eActivityInfo, self.UpdateAcInfo, self);
	ActivityMsg.eUpdateTime[fn](ActivityMsg.eUpdateTime, self.UpdateAcTime, self);
end

function M:OnClickNewMailBtn(go)

	local name = go.name
	local Items = self.Items
	local O = UIMgr.Open
	if name == Items.NewMail.name then
		O(UIInteractPanel.Name, self.OpenMailUISucc, self)
	end
end

function M:RespOpen(err,idStr)
	self:SetMailActive(err,1)
end

function M:RespDelMail(err,op,id)
	self:SetMailActive(err,op)
end

function M:SetMailActive(err,op)
	if err>0 then return end
	if(op == 0) then
		self.NewMailGo:SetActive(false)
	else
		local at = MailMgr.HasGoods()
		self.NewMailGo:SetActive(at)
	end
end

function M:OpenEquip(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:SwatchTg(1)
	end
end

function M:OpenMailUISucc(name)
	local ui = UIMgr.Dic[name]
	if not ui then return end
	ui:ShowMail()
end

function M:OpenFriendUISucc(name)
	local ui = UIMgr.Dic[name]
	if not ui then return end
	ui:ShowChat()
end

function M:RequestFriendStatus()
	local icon = self.Items.NewFriend
	if icon then
		if #FriendMgr.RequestList > 0 then
			icon.gameObject:SetActive(true)
			self:UpdateSortList(icon.gameObject, true)
		else
			icon.gameObject:SetActive(false)
			self:UpdateSortList(icon.gameObject, false)
		end
	end
end

function M:UpdateApplyInfo()
	local icon = self.Items.TeamApply
	if icon then
		local len = #tMgr.ApplyInfo
		if len > 0 then
			-- icon.gameObject:SetActive(true)
		else
			-- icon.gameObject:SetActive(false)
		end
	end
end

function M:UpdateRedPacket()
	local icon = self.Items.RedPacket
	if icon then
		if FamilyMgr:HasRedPacket() == true then
			icon.gameObject:SetActive(true)
			self:UpdateSortList(icon.gameObject, true)
			FamilyMgr.eRed(true, 3, 2);
		else
			icon.gameObject:SetActive(false)
			self:UpdateSortList(icon.gameObject, false)
			FamilyMgr.eRed(false, 3, 2);
		end
	end
end

function M:UpdateInviteInfo()
	local icon = self.Items.TeamInvite
	if icon then
		local len = #tMgr.InviteInfo
		if len > 0 then
			icon.gameObject:SetActive(true)
			self:UpdateSortList(icon.gameObject, true)
		else
			icon.gameObject:SetActive(false)
			self:UpdateSortList(icon.gameObject, false)
		end
	end
end

function M:UpdateAcInfo(actInfo)
	local acId = actInfo.id
	local state = actInfo.status
	if self.sysActTab[acId] == nil then
		return
	end
	local actData = self.sysActDataTab[acId]
	if state == 0 or state == 2 then
		actData:SetGOAc(true)
		self:UpdateSortList(actData.GO.gameObject, true)
		if state == 2 then
			actData:SetTimeLab("开启中")
		end
	elseif state == 3 then
		actData:SetGOAc(false)
		self:UpdateSortList(actData.GO.gameObject, false)
	end
end

--acId :  活动id
--curTime :  准备开启的剩余时间
--advState :  准备开启状态
function M:UpdateAcTime(acId,curTime,advState)
	local actTab = self.sysActTab
	if actTab[acId] == nil then return end
	local actData = self.sysActDataTab[acId]
	actData:SetGOAc(true)
	self:UpdateSortList(actData.GO.gameObject, true)
	if advState == true then
		actData:SetTimeLab(curTime)
	else
		actData:SetTimeLab("")
	end
end

--
function M:OnClickNewFriendBtn(go)
	--UIMgr.Open(UIFriendRequestPanel.Name)
	UIMgr.Open(UIFriendRequest.Name)
	self:RequestFriendStatus()
end

function M:OnClickTeamApplyBtn(go)
	local icon = self.Items.TeamApply
	if icon then
		icon.gameObject:SetActive(false)
		self:UpdateSortList(icon.gameObject, false)
	end
	UIMgr.Open(UITeamActive.Name,self.OnShowApply, self)
end

--// 点击红包提示按钮
function M:OnClickRedPacketBtn(go)
	local rpActList1, rpActList2, rpActList3, rpActList4 = RedPacketActivMgr:GetAllRedState();

	local icon = self.Items.RedPacket
	if icon then
		icon.gameObject:SetActive(false);
		self:UpdateSortList(icon.gameObject, false)
	end
	if rpActList2 ~= nil and #rpActList2 > 0 then
		UILvAward:OpenTab(9);
		return ;
	end
	--UIMgr.Open(UITeamActive.Name, self.OnShowApply, self)
	--UIMgr.Open(UIFamilyRedPWnd.Name)

	--// 1、未发送；2、未领取；3、已领取；4、已领完
	local rpList1, rpList2, rpList3, rpList4 = FamilyMgr:GetAllRedPacketData();
	
	FamilyMgr.checkRP = true;
	if rpList2 ~= nil and #rpList2 > 0 then
		UIMgr.Open(UIGiftMoneyWnd.Name);
	elseif rpList1 ~= nil and #rpList1 > 0 then
		UIMgr.Open(UIFamilyRedPWnd.Name);
	end
end

--响应提亲弹窗
function M:RespProposeOpen(id)
	local btn = self.Items.NewPropose
	if btn == nil then return end
	if id == -1 then
		btn.gameObject:SetActive(false)
		self:UpdateSortList(btn.gameObject, false)
		return
	end
	btn.gameObject:SetActive(true)
	self:UpdateSortList(btn.gameObject, true)
end

--响应道庭任务求助按钮
function M:RespHelpBtn(state)
	local btn = self.Items.NewFamilyHelp
	if not btn then return end
	btn.gameObject:SetActive(state)
	-- self:UpdateSortList(btn.gameObject, state)
end

function M:UpdateFlowersStatus()
	local btn = self.Items.NewFlowers
	if not btn then return end
	local value = #FlowersMgr.ReceiveList > 0
	btn.gameObject:SetActive(value)
	self:UpdateSortList(btn.gameObject, value)
end

function M:UpdateTreasureStatus()
	local btn = self.Items.NewTreasure
    local teamMgr = TeamMgr
	local teamInfo = teamMgr.TeamInfo
	local capId = teamInfo.CaptId
	local userId = User.MapData.UIDStr
	local isShow = TreasureMapMgr.isTreasureTeam
	local isShowMainIcon = TreasureMapMgr.isShowMainUIIcon
	if isShow == isShowMainIcon then
		return
	end
	TreasureMapMgr.isShowMainUIIcon = isShow
	if capId and tostring(capId) == userId then
		btn.gameObject:SetActive(isShow)
		self:UpdateSortList(btn.gameObject, isShow)
	end
end

--等级限购
function M:OpenOrClose(bool)
	local btn = self.Items.LvLimitBuyBtn
	if LuaTool.IsNull(btn) == true then return end
	self.Items.LvLimitBuyBtn:SetActive(bool)
	self.LvLimitRed:SetActive(bool)
	self:UpdateSortList(btn.gameObject, bool)
	self.DayLimTime.gameObject:SetActive(bool)
end

function M:UpdateTime(time)
	if not time then return end
	self.DayLimTime.gameObject:SetActive(true)
	self.DayLimTime.text = time
end

--点击提亲信息
function M:OnClickNewProposeBtn(go)
	UIProposePop:OpenTab(1)
end

--点击道庭任务求助
function M:OnClickNewFamilyHelpBtn()
	UIMgr.Open(UIFamilyHelp.Name)
end

--私聊
function M:PrivateChat(id,state)
	local go = self.Items.NewChat.gameObject
	self:UpdateSortList(go, state)
	go:SetActive(state)
end

function M:MarryCopyRequest()
	local btn = self.Items.BtnLove
	if not LuaTool.IsNull(btn) then
		btn:SetActive(true)
		self:UpdateSortList(btn.gameObject, true)
	end
end

--好友聊天
function M:OnClickNewChat()
	UIMgr.Open(UIInteractPanel.Name, self.OpenFriendUISucc, self)
end

--收花
function M:OnClickNewFlowers()
	FlowersMgr:OpenUI(3)
end

--宝藏
function M:OnClickNewTreasure()
	local treasureInfo = TreasureMapMgr.TreasureDataInfo
	if treasureInfo == nil then return end
	local sceneId = treasureInfo.mapId
	if sceneId == nil then return end
	TreasureMapMgr:MainNavStart()
	local pos = treasureInfo.pos
	User:StartNavPath(pos, sceneId, -1, 0)
end
--[[
function M:OpenFriendUISucc(name)
	local ui = UIMgr.Dic[name]
	if not ui then return end
	ui:ShowFirend()
end
]]--
function M:OnShowInvite(name)
	local ui = UIMgr.Dic[name]
	if ui then
		ui:OnShowInvite()
	end
end

function M:OnShowApply(name)
	local ui = UIMgr.Dic[name]
	if ui then
		ui:OnShowApply()
	end
end

function M:OnClickTeamInviteBtn(go)
	local icon = self.Items.TeamInvite
	if icon then
		icon.gameObject:SetActive(false)
		self:UpdateSortList(icon.gameObject, false)
	end
	UIMgr.Open(UITeamActive.Name,self.OnShowInvite, self)
end


function M:ClickShowMsg(value, info)
	if not info then return end
	local t = 1
	if value == false then
		t = 2
		tMgr:RemoveInviteReplyData(info.InviteID)
	end
	Mgr.ReqInviteReplyTeam(t, info.TeamId, info.InviteID)
end

--有新邮件通知
function M:RespNewLtr()
	local ui = UIMgr.Get(UIInteractPanel.Name)
	local op = (ui == nil) or (ui.active == 0)
	if op then
		self.NewMailGo:SetActive(true)
	else
		MailMgr.ReqGet()
	end
	UITip.Log("您有新的邮件")
end

function M:OpenNewMail(name)
	if name == "UIMail" then
		self.NewMailGo:SetActive(false)
	end
end

function M:OnOpenLvBuy()
	UIMgr.Open(UILvLimitBuyWnd.Name)
	self.LvLimitRed:SetActive(false)
end


-- function M:CloseToTx()
-- 	self.LvLimitBtnTx:SetActive(true)
-- end


function M:OnClickLove()
	local btn = self.Items.BtnLove
	if LuaTool.IsNull(btn) == false then
		btn:SetActive(false)
		self:UpdateSortList(btn.gameObject, false)
	end
	MsgBox.ShowYesNo("您的仙侣请求您购买仙侣副本次数？",self.BuyLoveCb,self)
end

function M:UpdateSortList(go, value)
	local list = self.SortList
	local isCheck, index = self:IsCheck(go.name)
	if value == true then
		if isCheck == false then
			table.insert(list, go)
			self:SortPos()
		end
	else
		if isCheck == true then
			table.remove(list, index)
			self:SortPos()
		end
	end
end

function M:SortPos()
	local list = self.SortList
	if list then
		for i=1,#list do
			local go = list[i]
			if LuaTool.IsNull(go) == false then
				local x = 0
				local y = 0
				if i <= 4 then
					x = (i - 1) * 90
				else
					x = math.floor((i - 1)/4) * 90
					y = 60
				end
				go.transform.localPosition = Vector3.New(x,y,0)
			end
		end
	end
end

function M:IsCheck(name)
	local list = self.SortList
	for i,v in ipairs(list) do
		if v.name == name then
			return true, i
		end
	end
	return false, -1
end

function M:Clear()
	if self.Items then
		for k,v in pairs(self.Items) do
			v.gameObject:SetActive(false)
		end
	end
	local list = self.SortList
	local len = #list
	while len > 0 do
		table.remove(self.SortList, len)
		len = #self.SortList
	end
end

function M:Dispose()
	TableTool.ClearDic(self.sysActTab)
	TableTool.ClearDic(self.sysActDataTab)
	self:RemoveEvent()
end
--endregion

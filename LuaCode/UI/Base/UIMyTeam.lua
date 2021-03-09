--region UIMyTeam.lua
--好友
--此文件由[HS]创建生成
require("UI/UICell/UICellTeamSelectCopy")
require("UI/UITeam/UICellTeamBase")
require("UI/UITeam/UIMyTeamPlayer")
require("UI/UITeam/UIMyTeamSetCopy")
require("UI/UITeam/UIMyTeamView")
require("UI/UITeam/UIMyTeamApply")
require("UI/UITeam/UIMyTeamInvite")

UIMyTeam = UIBase:New{Name ="UIMyTeam"}

local M = UIMyTeam
local tMgr = TeamMgr
local uMgr = UserMgr
M.rewardIndex = 0


--注册的事件回调函数

function M:InitCustom()
	local name = "lua我的队伍"
	local go = self.gbj
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.MyTeam = UIMyTeamView:New(self.gbj)
	self.SetView = UIMyTeamSetCopy:New(T(trans, "SetView"))

	self.NameLab = C(UILabel, trans, "Name", name, false)
	self.Lv = C(UILabel, trans, "Lv", name, false)
	self.GodSp = C(UISprite, trans, "Lv/GodSp", name, false)
	self.SetBtn =  T(trans, "Set")
	self.TalkBtn = T(trans, "Talk")
	self.TalkBtnBox = C(BoxCollider,trans,"Talk",name,false)
	self.TalkBg = C(UISprite,trans,"Talk/Background",name,false)
	self.TalkTimeLab = C(UILabel,trans,"Talk/Label",name,false)
	self.ApplyBtn = C(UIButton, trans, "Apply", name, false)
	self.CreateBtn = T(trans, "Create")
	self.ExitBtn = T(trans, "Exit")
	self.MatchBtn = T(trans, "Match")
	self.OpenBtn = T(trans,"Open")
	self.MatchLab = C(UILabel, trans, "Match/Label", name, false)
	self.MatchLab.text = "进入副本"

	self.CleanMatch = T(trans, "CleanMatch")
	self.CloseBtn = T(trans, "CloseBtn")

	self.RewardGrid = C(UIGrid, trans, "Reward", name, false)
	self.cellList = {}

	self.BuffRoot = C(UISprite, trans, "Buff", name, false)
	-- self.BuffRoot.gameObject:SetActive(false)
	self.Buffs = {}
	for i=1,3 do
		local b = C(UISprite, trans, string.format("Buff/Icon%s", i), name, false)
		table.insert(self.Buffs, b)
	end
	self.BuffValue = C(UILabel, trans, "Buff/Value", name, false)

	self.InvitePanel = UIMyTeamInvite:New(T(trans, "InvitPanel"))
	self.InvitePanel.GO:SetActive(false)

	self.timer = ObjPool.Get(iTimer)
	self.timer.invlCb:Add(self.InvlCb, self)
	self.timer.complete:Add(self.Cb, self)
	
	self.EquipCopyId = nil

	self.honorNumLab = C(UILabel,trans,"Honor/hon/num",name)
	self.honorTex = C(UITexture,trans,"Honor/hon/honorTxt",name)
	self.honorTipBtn = T(trans,"Honor/hon/tipBtn",name)
	self.tipPanel = T(trans,"Honor/tipPanel",name)
	self.tipTitleLab = C(UILabel,trans,"Honor/tipPanel/title",name)
	self.tipDesLab = C(UILabel,trans,"Honor/tipPanel/msg",name)
	self.tipYesBtn = T(trans,"Honor/tipPanel/yesBtn",name)
	self.tipCloseBtn = T(trans,"Honor/tipPanel/CloseBtn",name)

	self:AddEvent()
	self:SetEvent("Add")
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.SetBtn then
		E(self.SetBtn, self.OnSetBtn, self)
	end
	if self.TalkBtn then	
		E(self.TalkBtn, self.OnTalkBtn, self)
	end
	if self.ApplyBtn then	
		E(self.ApplyBtn, self.OnApplyBtn, self)
	end
	if self.CreateBtn then	
		E(self.CreateBtn, self.OnCreateBtn, self)
	end
	if self.ExitBtn then	
		E(self.ExitBtn, self.OnExitBtn, self)
	end
	if self.MatchBtn then	
		E(self.MatchBtn, self.OnMatchBtn, self)
	end
	if self.OpenBtn then	
		E(self.OpenBtn, self.OnOpenBtn, self)
	end
	if self.CleanMatch then	
		E(self.CleanMatch, self.OnMatchBtn, self)
	end
	if self.CloseBtn then	
		E(self.CloseBtn, self.OnCloseBtn, self)
	end	
	if self.honorTipBtn then	
		E(self.honorTipBtn, self.OpenTipPanel, self)
	end	
	if self.tipYesBtn then	
		E(self.tipYesBtn, self.CloseTipPanel, self)
	end	
	if self.tipCloseBtn then	
		E(self.tipCloseBtn, self.CloseTipPanel, self)
	end	
end


function M:SetEvent(fn)
	tMgr.eUpdateTempData[fn](tMgr.eUpdateTempData, self.UpdateTeamInfo, self)
	tMgr.eUpdateApplyInfo[fn](tMgr.eUpdateApplyInfo, self.UpdateApplyInfo, self)
	tMgr.eUpdateMatchStatus[fn](tMgr.eUpdateMatchStatus, self.UpdateBtnStatus, self)
	tMgr.eUpdateCaptID[fn](tMgr.eUpdateCaptID, self.UpdateTeamInfo, self)
	tMgr.eLeaveTeam[fn](tMgr.eLeaveTeam, self.ExitTeam, self)
	tMgr.eUpdateBuff[fn](tMgr.eUpdateBuff, self.UpdateBuff, self)
	CopyMgr.eUpdateCopyHonor[fn](CopyMgr.eUpdateCopyHonor, self.SetHonorLab, self)
end

function M:LoadTex()
	local pId = GlobalTemp["201"].Value3
	pId = tostring(pId)
	local itCfg = ItemData[pId]
	if itCfg == nil then
		iTrace.eError("GS","道具表不存配置  id：",pId)
		return
	end
	local path = itCfg.icon
    AssetMgr:Load(path,ObjHandler(self.SetIcon,self))
end

function M:SetIcon(tex)
    self.honorTex.mainTexture = tex
    self.texName = tex.name
end

function M:ClearIcon()
    if self.texName then
        AssetMgr:Unload(self.texName,false)
        self.texName = nil
    end
end

function M:SetHonorLab()
	local own = CopyMgr:GetCopyHonor()
	-- iTrace.eError("GS","own===",own)
	local max = GlobalTemp["201"].Value2[2]
	local str = string.format("今日可得：%s/%s",own,max)
	self.honorNumLab.text = str
end

function M:SetTipDesLab()
	local des = InvestDesCfg["2025"].des
	self.tipDesLab.text = des
end

function M:OpenTipPanel()
	-- self:SetTipPanelState(true)
	UIComTips:Show(InvestDesCfg["2025"].des, Vector3(-232,-29,0), nil, nil, 17, 540, UIWidget.Pivot.TopLeft)
end

function M:CloseTipPanel()
	self:SetTipPanelState(false)
end

function M:SetTipPanelState(ac)
	self.tipPanel:SetActive(ac)
end

function M:UpdateBuff()
	local list = TeamMgr.TeamInfo.Player
	if not list then return end
	local len = #list
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

function M:ClearBuffs()
	if self.Buffs then
		for i,v in ipairs(self.Buffs) do
			v.color = Color.New(1,1,1,0.4)
		end
	end
end

function M:UpdateTeamInfo()
	self:UpdateCopy()
	self:UpdateBtnStatus()
	self:UpdateBuff()
	if self.MyTeam then
		self.MyTeam:UpdateData()
	end
end

--退出队伍
function M:ExitTeam()
	-- iTrace.Error("GS","#tMgr.TeamInfo.Player===",#tMgr.TeamInfo.Player)
	tMgr.MatchCopyId = nil
	self:Close()
	UIMgr.Open(UITeam.Name, self.OpenUITeamCopy, self)
end

function M:OpenUITeamCopy(name)
	local ui = UIMgr.Dic[name]
	if ui then 
		ui:SelectWildEnter()
	end
end

function M:UpdateCopy(info)
	local info = tMgr.TeamInfo
	local name = "【无】"
	local lv = "【无】"
	local id = info.CopyId
	local min = info.MinLv
	local max = info.MaxLv
	local wailId = GlobalTemp["60"].Value3
	if id then
		local temp = CopyTemp[tostring(id)]
		if temp then
			name = temp.name
		end
		if id == wailId then
			name = "野外挂机"
		end
	end
	if id == 0 then
		lv = "【无限制】"
	else
		if min and max then
			-- local isGodLv = uMgr:IsGod(min)
			-- if isGodLv == true then
			-- 	local godLv = min - 370
			-- 	min = string.format("化神%s",godLv)
			-- end
			-- isGodLv = uMgr:IsGod(max)
			-- if isGodLv == true then
			-- 	local godLv = max - 370
			-- 	max = string.format("化神%s",godLv)
			-- end
			lv = string.format("【%s-%s】", min, max)
		end
	end
	if self.NameLab then
		self.NameLab.text = name
	end
	if self.Lv then
		self.Lv.text = lv
	end
end

function M:UpdateBtnStatus()
	local info = tMgr.TeamInfo
	local id = info.TeamId
	local value = id == nil
	local isMatch = tMgr.IsMatching
	local isCapt = tostring(info.CaptId) == User.MapData.UIDStr
	if self.SetBtn then
		self.SetBtn:SetActive(not value and isCapt)
	end
	
	-- if isMatch then
	-- 	tMgr.eIsMatching(isMatch)
	-- elseif not isMatch then

	-- end
	if self.CreateBtn then
		self.CreateBtn:SetActive(value)
	end
	if self.ExitBtn then
		self.ExitBtn:SetActive(not value)
	end
	if self.ApplyBtn then
		self.ApplyBtn.Enabled = not value
	end
	if self.MatchBtn then
		self.MatchBtn:SetActive(not value and not isMatch and isCapt)
	end
	if self.CleanMatch then
		self.CleanMatch:SetActive(not value and isMatch and isCapt)
	end

	local isTreasure = TreasureMapMgr.isTreasureTeam
	local isTreasureOpen = TreasureMapMgr.isTreasureOpen
	self.OpenBtn:SetActive(isTreasure and not isTreasureOpen)
	self.MatchBtn:SetActive(not isTreasure)
	self.ExitBtn:SetActive(not isTreasure)

	local wailId = GlobalTemp["60"].Value3
	if info.CopyId == wailId then
		self.MatchBtn:SetActive(false)
	end
	if not isMatch then self:UpdateCopy(nil) end
	-- if id == nil then
	-- 	self:ExitTeam()
	-- end
end

function M:UpdateApplyInfo()
end

function M:OnSetCopyInfo(copyid)
	if self.SetView then
		self.SetView:SelecOneCanEnter(copyid)
	end
end

---------------------------------------------------
function M:OnSetBtn(go)
	if tMgr.IsMatching and tMgr.IsMatching == true then
		UITip.Error("正在匹配中，取消匹配才能重新选择")
		return
	end
	if self.SetView then
		self.SetView:SetActive(true)
		-- self.SetView:SelectCanEnter()  
		self.SetView:SelectWildEnter()  
	end
end

function M:OnTalkTime()
	local totalTime = 30
	self.time=totalTime
    self.timer.seconds=self.time
    self.TalkTimeLab.text=tostring(self.time)
	self.timer:Start()
    self:TalkState(true,totalTime)
end

--发送组队邀请到聊天界面组队频道
--index:0 其他地图
--index：1 藏宝地图
function M:OnTalkBtn(go)
	local isTreasure = TreasureMapMgr.isTreasureTeam
	local index = 0
	if isTreasure == true then
		index = 1
	end
	TeamMgr:ReqRecruit(index)
	self:OnTalkTime()
end

function M:OnApplyBtn(go)
end

-- --主界面入口进入
-- function M:OnCreateBtn(go)
-- 	tMgr:ReqCreateTeam()
-- 	self:OnSetBtn()
-- end

--主界面入口进入 默认选择野外挂机
function M:OnCreateBtn()
	TeamMgr:ReqCreateTeam()
	local data = GlobalTemp["60"]
	local minLv = data.Value2[1]
	local maxLv = data.Value2[2]
	local copyId = data.Value3
	TeamMgr:ReqSetCopyTeam(copyId,minLv,maxLv)
end

--从副本界面快捷创建队伍
function M:OnCopyEnter()
	local copyid = tMgr.CurCopyId
	if copyid ~= nil then
		self:OnSetCopyInfo(copyid)
	end
	tMgr.CurCopyId = nil
end

function M:OnExitBtn(go)
	tMgr:ReqLeave()
end

--原功能的匹配逻辑 
function M:False_OnMatchBtn(go)
	if go.name == self.MatchBtn.name then
		local info = tMgr.TeamInfo
		local id = info.TeamId
		if id == 0 then
			UIMgr.Open(UITeam.Name)
			self:Close()
		else
			self:OnSetBtn(nil)
		end
	elseif go.name == self.CleanMatch.name then
		local info = tMgr.TeamInfo
		if info then
			tMgr:ReqTeamMatch(info.CopyId, false)
		end
	end
end

--现在改为进入副本的逻辑
function M:OnMatchBtn(go)
	local info = tMgr.TeamInfo
	if not info then return end
	local copyId = info.CopyId
	tMgr:MatchTeamCondition(copyId)
end

--点击开启按钮
function M:OnOpenBtn()
	self:Close()
	local isTreasureOpen = TreasureMapMgr.isTreasureOpen
	local isPathing = TreasureMapMgr.isPathing
	if isPathing then
		QuickUseMgr.YesCb()
		return
	elseif isTreasureOpen == false then
		TreasureMapMgr:OnStartDig()
		UIMgr.Open(UICollection.Name)
	end
end

function M:OpenUITeam(name)
	local ui = UIMgr.Dic[name]
	if ui then 
		ui:ClickCell()
	end
end

function M:InvlCb()
	if not self.time then return end
	self.time=self.time-1
	self.TalkTimeLab.text=tostring(self.time)
end

function M:Cb()
	self:TalkState(false)
end

function M:TalkState(state,time)
    local text = "一键喊话"
	if(state==true)then
		self.TalkBg.color=Color.New(0,1,1,1)
		self.TalkTimeLab.text = tostring(time)		
	else
		self.TalkBg.color=Color.New(1,1,1)
		self.TalkTimeLab.text = text
    end
    self.TalkBtnBox.enabled = not state
end

function M:OnCloseBtn(go)
	local isTreasureT= TreasureMapMgr.isTreasureTeam
	local isTreasureUse = TreasureMapMgr.isTreasureUse
	local isTreasureOpen = TreasureMapMgr.isTreasureOpen
	self:Close()
	if isTreasureOpen == true then
		return
	end
	if isTreasureT == true and isTreasureUse == false then
		TreasureRewardBox.OpenTreasure()
	end
end

function M:OpenCustom()
	local isTreasure = TreasureMapMgr.isTreasureTeam
	self.RewardGrid.gameObject:SetActive(isTreasure)
	self.BuffRoot.gameObject:SetActive(not isTreasure)
	self:UpdateRewardCell()
	self:UpdateTeamInfo()
	self:OpenHonor()
end

function M:OpenHonor()
	self:LoadTex()
	self:SetHonorLab()
	self:SetTipDesLab()
end

function M:UpdateRewardCell()
	if TreasureMapMgr.usePropId == 0 then
		return
	end
    local id = tostring(TreasureMapMgr.usePropId)
    local cfg = TreasureCfg[id]
    local rewards = cfg.rewards
    if rewards == nil then iTrace.eError("GS","请检查【藏宝图】奖励配置") return end
    local len = #rewards
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    local propid = 0
    local propNum = 0
  
    for i=1, max do
        if i <= min then
            propid = rewards[i].k
            propNum = rewards[i].v
            list[i]:UpData(propid,propNum)
            list[i].trans.gameObject:SetActive(true)
        elseif i <= count then
            list[i].trans.gameObject:SetActive(false)
        else
            propid = rewards[i].k
            propNum = rewards[i].v
            local cell = ObjPool.Get(Cell)
            cell:InitLoadPool(self.RewardGrid.transform,0.7)
            cell:UpData(propid,propNum)
            cell.trans.gameObject:SetActive(true)
            table.insert(list, cell)
        end
    end
    self.RewardGrid:Reposition()
end

function M:ClearItems()
end

function M:DisposeCustom()
	self:SetEvent("Remove")
	self:ClearIcon()
	TableTool.ClearListToPool(self.cellList)
	self:ClearBuffs()
	if self.SetView then
		self.SetView:Dispose()
	end
	self.SetView = nil
	if self.MyTeam then
		self.MyTeam:Dispose()
	end
	self:TalkState(false)
	self.timer:Stop()
	self.MyTeam = nil
	self.NameLab = nil
	self.Lv = nil
	self.GodSp = nil
	self.SetBtn = nil
	self.TalkBtn = nil
	self.ApplyBtn = nil
	self.CreateBtn = nil
	self.ExitBtn = nil
	self.MatchBtn = nil
	self.CloseBtn = nil
	self.TalkBtnBox = nil
	self.TalkBg = nil
	self.TalkTimeLab = nil
	self.MatchLab = nil
	self.copyId = nil
	self.EquipCopyId = nil
end

return M
--endregion

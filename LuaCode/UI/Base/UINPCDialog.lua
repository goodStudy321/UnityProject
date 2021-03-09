--region UINPCDialog.lua
--Date �Ի�UI
--此文件由[HS]创建生成

UINPCDialog = UIBase:New{Name = "UINPCDialog"}

local M = UINPCDialog
M.Right = 0
M.LEFT = 1

local MNW = MissionNetwork
local JoyStickCtrl = JoyStickCtrl.instance


--ע�����¼��ص�����
local Error = iTrace.eError
local NPCMgr = NPCMgr.instance

function M:InitCustom()
	local name = "luaNPC对话框窗口"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.NameLabel = C(UILabel, trans, "Con/Name", name, false)
	self.TalkLabel = C(UILabel, trans, "Con/Panel/Talk", name, false)
	self.TE = C(TypewriterEffect, trans, "Con/Panel/Talk", name, false)
	self.MRoot = T(trans, "Con/Root")
	self.Reward = T(trans, "Con/Reward")
	self.Grid = C(UIGrid, trans, "Con/Reward/Grid", name, false)
	self.Button = T(trans, "Con/Reward/Button")
	self.BtnLabel = C(UILabel, trans, "Con/Reward/Button/Label", name, false)

	self.lBg = T(trans, "BGCamera/Panel/lBg")
	self.rBg = T(trans, "BGCamera/Panel/rBg")
	self.lArr = T(trans, "Container/lArr")
	self.rArr = T(trans, "Container/rArr")

	self.IsActive = false

	self.CountDown = nil
	self.IsCountDown = false

	self:InitData()
	self:AddEvent()
end

function M:InitData()
	self.Talk = {}
	--self.Timer = 2
	local left = tostring(self.LEFT)
	self.Talk[left] = {}
	self.Talk[left].NamePos = Vector3.New(-181.2, - 202, 0)
	self.Talk[left].TxtPos = Vector3.New(-246.1, - 241.5801, 0)
	self.Talk[left].TxtWidth = 795
	self.Talk[left].ModPos = Vector3.New(350,-431, 76173)
	self.Talk[left].ModAngles = Vector3.New(0, -15, 0)
	self.Talk[left].ModOffset = 24
	--self.Talk[left].BgAngles = Vector3.zero
	local right = tostring(self.Right)
	self.Talk[right] = {}
	self.Talk[right].NamePos = Vector3.New(181.2, - 202, 0)
	self.Talk[right].TxtPos = Vector3.New(-533, - 241.5801, 0)
	self.Talk[right].TxtWidth = 795
	self.Talk[right].ModPos = Vector3.New(-350, -431, 76173)
	self.Talk[right].ModAngles = Vector3.New(0, 15, 0)
	self.Talk[right].ModOffset = 24
	--self.Talk[right].BgAngles = Vector3.New(0, 180, 0)

	self.End = {}
	self.End[left] = {}
	self.End[left].NamePos = self.Talk[left].NamePos
	self.End[left].TxtPos = self.Talk[left].TxtPos
	self.End[left].TxtWidth = 549
	self.End[left].ModPos = self.Talk[left].ModPos
	self.End[left].ModAngles = self.Talk[left].ModAngles
	self.End[left].ModOffset = self.Talk[left].ModOffset
	--self.End[left].BgAngles = self.Talk[left].BgAngles
	self.End[left].IsReward = true

	self.ModTool = RoleSkin:New()

	self.NPCTemp = nil
	self.Mission = nil
	self.NPCMod = nil
	self.TalkList = {}
	self.Cells = {}
	self.page = 1
	self.Mod = nil
	self.Timer = 5
end

function M:AddEvent()

	local EH = EventHandler
	self.OnUpdateClickNpcData = EH(self.UpdateNpcClickData, self)
	self.OnUpdateNodeData = EH(self.UpdateNodeData, self)

	local S = UITool.SetLsnrSelf
	local E = EventMgr.Add
	if self.root then
		S(self.root, self.OnClick, self, nil, false)
	end
	if self.Button then
		S(self.Button, self.OnClickButton, self)
	end

	E("UpdateDataUINPCPanel", self.OnUpdateClickNpcData)
	--("UpdateDataUIDialogList", self.OnUpdateNodeData)

end

function M:RemoveEvent()
	local E = EventMgr.Remove
	E("UpdateDataUINPCPanel", self.OnUpdateClickNpcData)
	--E("UpdateUIDialog", self.OnUpdateUIDialog)
	--E("UpdateDataUIDialog",self.OnUpdateDataUIDialog)
	--E("UpdateDataUIDialogList", self.OnUpdateNodeData)

end

--流程节点数据
function M:UpdateNodeData(list)
	local len = list.Count - 1
	for i = 0, len do
		local info = list[i]
		local talk = {}
		talk.modName = info.modelName
		talk.name = info.name
		talk.talk = info.text
		if info.left == true then
			talk.dir = self.LEFT
		else
			talk.dir = self.Right
		end
		talk.timer = info.timer
		table.insert(self.TalkList, talk)
	end
	self:UpdatePage(self.page)
end

--更新点击获得NPC数据
function M:UpdateNPCClickData(npcid)
	self:UpdateNPCData(npcid)
	self:UpdateNPCDes()
	self:UpdatePage(self.page)
end

--更新点击的npc获得任务数据
function M:UpdateNpcClickMissionData(npcid, missionid)
	if self.Mission and self.Mission.ID == missionid then return end
	self:UpdateNPCData(npcid)
	if self:UpdateMissionData(missionid) == true then
		self:UpdatePage(self.page)
	end
end

--更新npc数据
function M:UpdateNPCData(id)
	self.NPCTemp  = NPCTemp[tostring(id)]
	local temp = self.NPCTemp
	if not temp then
		Error("hs", string.format("NPCTemp配置表中不存在 NPCID :", id))
		return
	end
	if not temp.reset or temp.reset == 0 then
		User:ResetCamera()
	end

	local modeID = nil
	if temp.uiMod then
		modeID = temp.uiMod
	else
		modeID = temp.modeID
	end
	local npcbase = RoleBaseTemp[tostring(modeID)]
	if npcbase then
		self.NPCMod = npcbase.path
	end
end
 
--获取npc描述
function M:UpdateNPCDes()
	local temp = self.NPCTemp
	if not temp then return end
	local talk = {}
	if self.NPCMod then
		talk.modName = self.NPCMod
	end
	talk.name = temp.name
	talk.talk = temp.talk
	--// LY add begin
	--// 播放角色配音
	talk.audioFN = temp.audio;
	--// LY add end
	talk.pose = temp.pose

	talk.dir = self.LEFT
	talk.timer = self.Timer
	talk.isReward = false
	table.insert(self.TalkList, talk)
end

--更新任务数据
function M:UpdateMissionData(id)
	if not id then return false end
	self.Mission = MissionMgr:GetMissionForID(id)
	if not self.Mission or not self.Mission.Temp then
		Error("hs", string.format("MissionMgr中不存在 MissionID :", id))
		return false
	end
	local temp = self.Mission.Temp
	if self.Mission.Status == MStatus.NOT_RECEIVE then
		self:UpdateTalk(temp.talkReceive, temp.takeMAudio, id, true)
	elseif self.Mission.Status == MStatus.EXECUTE then
		self:UpdateTalk(temp.talk, temp.inMAudio, id, false)
	elseif self.Mission.Status == MStatus.ALLOW_SUBMIT then
		self:UpdateTalk(temp.talkSubmit, temp.finMAudio, id, true)
	end
	return true
end

function M:UpdateTalk(list, audioList, missid, isReward)
	if not list then
		return
	end
	for i = 1, #list do
		local talk = {}
		local data = list[i]
		if data.k == 0 then
			talk.modName = User.Mod
			talk.name = User.MapData.Name
			talk.dir = self.Right
		elseif data.k == 1 then
			if self.NPCMod then
				talk.modName = self.NPCMod
			end
			local temp = self.NPCTemp
			if temp then
				talk.name = temp.name
				talk.pose = temp.pose
			end
			talk.dir = self.LEFT
		end
		talk.talk = data.s
		talk.audioFN = nil;
		if audioList ~= nul and #audioList >= i then
			talk.audioFN = audioList[i];
		end
		talk.timer = self.Timer
		talk.isReward = isReward
		table.insert(self.TalkList, talk)
	end
end

function M:UpdatePage(page)
	if not self.TalkList then return end
	local limit = #self.TalkList
	local offset = nil
	local data = nil
	if page < limit then
		offset = self.Talk
	elseif page == limit then
		if not self.Mission or self.Mission.Status == MStatus.EXECUTE then
			offset = self.Talk
		else
			offset = self.End
		end
	else
		if self.IsActive == true then return end
		self:UpdateActive()
		return
	end
	self:UpdateUI(self.TalkList[page].dir, offset)
	self:UpdateUIData(self.TalkList[page])
end

function M:UpdateUI(dir, offset)
	if not offset then return end
	local data = offset[tostring(dir)]
	if not data then return end
	if self.NameLabel then
		self.NameLabel.transform.localPosition = data.NamePos
	end
	if self.TalkLabel then
		self.TalkLabel.transform.localPosition = data.TxtPos
		self.TalkLabel.width = data.TxtWidth
	end
	if self.MRoot then
		self.MRoot.transform.localPosition = data.ModPos
		self.MRoot.transform.localEulerAngles = data.ModAngles
	end
	local value = dir == self.LEFT
	local isReward = data.IsReward and data.IsReward == true
	if self.lBg then
		self.lBg:SetActive(value)
	end
	if self.rBg then
		self.rBg:SetActive(not value)
	end
	if self.lArr then
		self.lArr:SetActive(value and not isReward)
	end
	if self.rArr then
		self.rArr:SetActive(not value)
	end
	if self.Reward then
		self.Reward:SetActive(isReward)
	end
end

function M:UpdateUIData(data)
	if not data then return end
	--[[
	if self.lBg then
		LayerTool.Set(self.lBg, 21)
	end
	if self.rBg then
		LayerTool.Set(self.rBg, 21)
	end
	]]--
	if self.NameLabel then
		self.NameLabel.text = data.name
	end
	if self.TalkLabel then
		self.TalkLabel.text = data.talk
	end
	--// LY add begin
	--// 播放角色配音
	if data.audioFN ~= nil then
		--Audio:Play(data.audioFN, 1);
		Audio:PlayTheOne(data.audioFN, 1);
	end
	--// LY add end
	if self.TE then
		self.TE:ResetToBeginning()
	end
	if self.Mod then
		self:UnloadMod()
	end
	if self.ModTool then
		self:UnloadModTool()
	end
	if self.BtnLabel then
		local label = "交谈"
		if self.Mission then
			if self.Mission.Status == MStatus.NOT_RECEIVE then
				label = "领取"
			elseif self.Mission.Status == MStatus.ALLOW_SUBMIT then
				label = "提交"
			end
		end
		self.BtnLabel.text = label
	end
	if self.page == #self.TalkList and data.isReward and data.isReward == true then
		self:UpdateReward()
	end
	if self.MRoot then
		if self.Mod then return end
		if data.dir == self.LEFT then
			if not self.Mod then
				self.ModName = data.modName
				local del = ObjPool.Get(DelGbj)
				del:Add(data)
				del:SetFunc(self.LoadModCb,self)
				Loong.Game.AssetMgr.LoadPrefab(data.modName, GbjHandler(del.Execute,del))
			end
		else
			if self.ModTool then
				self.ModTool.eLoadModelCB:Add(self.LoadModelCB, self)
				local str = ""
				local sex = User.MapData.Sex
				if sex == 0 then
					str = "P_Female01_UI_idle"
				elseif sex == 1 then
					str = "P_Male01_UI_idle"
				end
				if not StrTool.IsNullOrEmpty(str) then
					self.ModTool:CreateSelf(self.MRoot.transform, str)
				else
					iTrace.eError("hs", "没有获取正确的待机动画")
				end
			end
		end
	end
	if self.IsCountDown == true or data.timer == 0 then return end
	self.CountDown = os.time()
	self.IsCountDown = true
end

function M:UnloadMod()
	if not self.Mod then return end
	Destroy(self.Mod)
	--[[
	if not StrTool.IsNullOrEmpty(self.ModName) then
		AssetMgr:Unload(self.ModName, ".prefab", false)
	end
	]]--
	self.ModName = nil
	self.Mod = nil
end

function M:UnloadModTool()
	if not self.ModTool then return end
	self.ModTool.eLoadModelCB:Remove( self.LoadModelCB, self)
	self.ModTool:Clear()
end

function M:LoadModCb(go,data)	
	self.Mod = go
	if self.active ~= 1 or (self.TalkList and self.page and self.TalkList[self.page] and self.TalkList[self.page].dir ~= self.LEFT) then 
		self:UnloadMod() 
		return 
	end
	if LuaTool.IsNull(go) == false then
		LayerTool.Set(go.transform, 19)
		local root = self.MRoot.transform
		go.transform.parent = root
		self:UpdateModelInfo(go, root, data)
	end
end

function M:LoadModelCB(go)
	if self.active ~= 1 or (self.TalkList and self.page and self.TalkList[self.page] and self.TalkList[self.page].dir ~= self.Right) then 
		self:UnloadModTool() 
		return 
	end
	self.ModTool.eLoadModelCB:Remove( self.LoadModelCB, self)
	local data = self.TalkList[self.page]
	if not data then return end
	self:UpdateModelInfo(go, self.MRoot.transform, data)
end

function M:UpdateModelInfo(go, root, data)
	local pos = Vector3.zero
	local sOffset = root.localScale.x
	local eOffset = Vector3.zero
	if data.dir == 1 then
		if self.NPCTemp then
			if self.NPCTemp.uix then
				pos.x = self.NPCTemp.uix / 100
			end
			if self.NPCTemp.uiy then
				pos.y = self.NPCTemp.uiy / 100
			end
			if self.NPCTemp.uiz then
				pos.z = self.NPCTemp.uiz / 100
			end
			if self.NPCTemp.uis then
				sOffset = self.NPCTemp.uis / 100
			end
			if self.NPCTemp.uie then
				eOffset.y = self.NPCTemp.uie / 100
			end
		end
	elseif data.dir == 0 then
		sOffset = 360
	end
	root.localScale = Vector3.one * sOffset
	go.transform.localPosition = pos
	go.transform.localScale = Vector3.one
	go.transform.localEulerAngles = eOffset
	self:UpdateAnim(data.pose)
end

function M:UpdateAnim(pose)
	if not pose then return end
	local mod = self.Mod
	if not mod then return end
	local event = ComTool.GetSelf(UnitUIAnimEvent, mod, "UnitUIAnimEvent")
	if not event then event = ComTool.Add(mod, UnitUIAnimEvent) end
	if event then
		event.startClipName = pose
		event:Begin()
	end
end

function M:StopCountDown()
	self.IsCountDown = false
end

function M:EndTimer()
	self:StopCountDown()
	self:OnClick(nil)
end

--更新奖励
function M:UpdateReward()
	self:CleanReward()
	local mission = self.Mission
	if not mission then return end
	local temp = mission.Temp
	if not temp then return end
	if temp.type ~= MissionType.Escort then
		self:UpdateMissionReward(temp)
	else
		self:UpdateEscortReward()
	end
	self.Grid:Reposition()
end

function M:UpdateMissionReward(temp)
	local exp = temp.exp
	local item = temp.item
	if exp and exp ~= 0 then
		if temp.expType == 0 then
			self:AddItemData(100, exp, false)
		else
			self:AddItemData(100, PropTool.GetExp(exp/10000), false)
		end
	end
	if item then
		local count = #item
		for i = 1, count do
			local data = item[i]
			if data and data.id ~= 0 then
				self:AddItemData(data.id, data.num, data.bind == 1)
			end
		end
	end
end

function M:UpdateEscortReward()
	local temp = EscortTemp[tostring(EscortMgr.FairyID)]
	if not temp then return end
	local isDouble = false
	local data = LivenessInfo:GetActInfoById(1012)
	if data then 
		isDouble = data.val == 1
	end
	local copper = temp.r_copper
	if isDouble == true then copper = copper * 2 end
	if copper and copper > 0 then
		self:AddItemData(1, copper, false)
	end
	local lv = User.MapData.Level
	local lvTemp = LvCfg[lv]
	if lvTemp then
		local exp = Mathf.Floor(lvTemp.exp * (temp.expRatio / 10000))
		if isDouble == true then exp = exp * 2 end
		if exp > 0 then
			self:AddItemData(100, exp, false)
		end
	end
	self.Grid:Reposition()
end

function M:UpdateActive()
	self.IsActive = true
	local mission = self.Mission
	if mission then
		if mission.Status == MStatus.NOT_RECEIVE then
			MNW:ReqAcceptMission(mission.ID)
		elseif mission.Status == MStatus.EXECUTE then
			if mission.Temp.type == MissionType.Escort then
				User.MissionState = true
				self:Close()
				EscortMgr:UpdateMissionStatus()
				User.MissionState = false
				return 
			else	
				--iTrace.eError("hs","-------->>> UpdateActive "..tostring(mission.ID).." "..tostring(mission.Status))
				MNW:ReqTriggerMission(mission.Temp.tarType, self.NPCTemp.id)
			end
		elseif mission.Status == MStatus.ALLOW_SUBMIT then
			if mission.Temp.type == MissionType.Escort then
				EscortMgr:ReqFairyFinishTos()
			else
				MNW:ReqCompleteMission(mission.ID)
			end
		end
	end
	self:Close()
end

--add奖励
function M:AddItemData(id, value, bind)
	if value == 0 then return end
	local key = tostring(id)
	local dicKey = key..tostring(bind)
	if self.Cells[dicKey] then return end
	local item = ItemData[key]
	if not item then
		local create = ItemCreate[key]
		if create then
			local cate = User.MapData.Category
			if cate == 1 then
				item = ItemData[tostring(create.w1)]
			else
				item = ItemData[tostring(create.w2)]
			end
		end
		if not item then 
			iTrace.eLog("hs",string.format("任务奖励道具ID[%s]不存在",key))
			return 
		end
	end
	local cell = ObjPool.Get(UIItemCell)
	cell:InitLoadPool(self.Grid.transform)
	cell.trans.name = tostring(id)
	cell:UpData(item, tonumber(value))
	cell:UpBind(bind)
	table.insert(self.Cells, cell)
end

function M:OnClick(go)
	if self.TE then
		if self.TE.isActive == true then
			self.TE:Finish()
			return
		end
	end
	self:StopCountDown()
	self.IsCountDown = false
	if not self.page then return end
	self.page = self.page + 1
	self:UpdatePage(self.page)
end

function M:OnClickButton(go)
	if self.IsActive == true then return end
	self:UpdateActive()
end

function M:CleanReward()
	local list = self.Cells
	if list then
		local l = #list
		while l > 0 do
			local cell = list[l]
			if cell then
				table.remove(list, l)
				cell:Destroy()
				ObjPool.Add(cell)
				cell = nil
			end
			l = #list
		end
		self.Cells = {}
	end
	if self.Grid then
		local childs = self.Grid:GetChildList()
		local count = childs.Count
		for i=0,count - 1 do
			local trans = childs[i]
			if not LuaTool.IsNull(trans) then
				trans.parent = nil
				Destroy(trans.gameObject)
			end
		end
		childs:Clear()
	end
end

function M:Clean()
	self:StopCountDown()
	self.IsActive = false
	self.IsCountDown = false
	self:CleanReward()
	self.NPCTemp = nil
	self.Mission = nil
	self.NPCMod = nil
	TableTool.ClearDic(self.TalkList)
	self.page = 1
	self.Timer = 5
	if self.NameLabel then
		self.NameLabel.text = ""
	end
	if self.TalkLabel then
		self.TalkLabel.text = ""
	end
	if self.Reward then
		self.Reward:SetActive(false)
	end
	self:UnloadMod()
	self:UnloadModTool()
	--MissionMgr:Execute(false)
end

function M:Update()
	if not self.IsCountDown or self.IsCountDown == false then return end
	if not self.CountDown then return end
	if os.time() - self.CountDown >= self.Timer then
		self.CountDown = os.time()
		self:EndTimer()
	end
end

function M:OpenCustom()
	self:CleanReward()
	self.IsActive = false
	JoyStickCtrl:SetJsCtrl(false);	
end

function M:CloseCustom()
	self:Clean()
	JoyStickCtrl:SetJsCtrl(true);	
end

function M:DisposeCustom()
	--self:Clean()
	if self.ModTool then 
		self.ModTool:Dispose()
	end
	self.ModTool = nil
	self.CountDown = nil
	self.IsCountDown = nil
	self.Timer = nil
	self.Cells = nil
	self.NPCTemp = nil
	self.Mission = nil
	self.NPCMod = nil
	self.Mod = nil
	self.TalkList = nil
	self.page = nil
	self.NameLabel = nil
	self.TalkLabel = nil
	self.MRoot = nil
	self.Reward = nil
	self.Grid = nil
	self.Button = nil
	self.BtnLabel = nil
	self.Bg = nil
	self.Bg1 = nil
    --TableTool.ClearUserData(self);
end

return M
--endregion

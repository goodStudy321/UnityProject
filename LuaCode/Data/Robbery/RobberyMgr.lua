RobberyMgr = {Name="RobberyMgr"}
local My = RobberyMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

My.eUpdateStateInfo = Event()
My.eUpdateSpiInfo = Event()
My.eUpdateSpiRefInfo = Event()
My.eUpdateMissionInfo = Event()

My.eUpdateStRedState = Event()
My.eUpdateSpRedState = Event()
My.eCloseRobberyUI = Event()
My.eUpInfo=Event()
My.eSpRed = Event()--主界面战灵红点
My.eStateSpRed = Event() --境界界面战灵红点
My.eOpenSpUI = Event() --获取战灵，打开战灵界面
My.FlySkillId = 0
My.StateSpRedTab = {}

-- --小东西的刷新
-- My.eMssState =Event();

--index == 1 战灵
--index == 2 灵饰
--index == 3 战神套装
--index == 4 灵器
--value:红点状态
function My:StateSpRed(index,value)
	self.StateSpRedTab[index] = value
	self.eStateSpRed(index,value) --境界界面战灵红点
	self.eSpRed(index,value) --主界面战灵红点
end

function My:Clear()
	self.roSuccess = false
	self.RobberyState = 0
	self.RobberySceneId = 500001
	self.RobberyFlowChar = "dujie"
	self.StateInfoTab = {}
	self.SpiriteInfoTab = {}
	self.RoMissionInfoTab = {}
	self.RoSortMissinTab = {}
	self.isSecond = false -- 是否是第二次发送协议
	self.StateSpRedTab = {} --境界战灵红点

	--境界等级--10 01 (10:大境界， 01 小境界)
	self.curState=0;
	self.BigCurState=0;
	self.SmallCurState=0;
	self.roleLimit = false
	--根据大境界和小境界获得境界表数据 如 大境界：10  小境界：0 ~ 5
	self.AmbitInfo= {};
	--记录不同的境界
	self.AmbNumTab = {}

	--最大境界
	local AmbMaxInfo = AmbitCfg[#AmbitCfg]
	local maxStateId = AmbMaxInfo.id
	local maxBig = self:GetBigState(maxStateId)
	local maxSmall = self:GetSmallState(maxStateId)
	self.StateInfoTab.maxBigState = maxBig
	self.StateInfoTab.maxSmallState = maxSmall

	self:InitAmbitCfg()
	self:InitSpiriteLvCfg()
	self.isStateRed = false
	self.isPrayRed = false
	self.isSpiriteRed = false
	self.isMissRed = false
end

function My:Init()
	self:Clear()
	self:AddProto()
	-- self.propIdTab = {30401,105,106,30402}
end

function My:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
	PropMgr.eUpdate:Add(self.UpdatePropNum, self)
	CopyMgr.eCopyState:Add(self.CopeyState,self)
	RobEquipsMgr.eRfrRed:Add(self.RfrSpirEqRed,self);
	PrayMgr.eUpdataData:Add(self.RfrPrayRed,self);
	PrayMgr.eChangeRes:Add(self.RfrPrayRed,self);
	OpenMgr.eOpenNow:Add(self.InitRedState, self)
	SceneMgr.eChangeEndEvent:Add(self.ChangeScene, self)
	-- UserMgr.eLvUpdate:Add(self.UpdateLv, self)
end

function My:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
	PropMgr.eUpdate:Remove(self.UpdatePropNum, self)
	CopyMgr.eCopyState:Remove(self.CopeyState,self)
	RobEquipsMgr.eRfrRed:Remove(self.RfrSpirEqRed,self);
	PrayMgr.eUpdataData:Remove(self.RfrPrayRed,self);
	PrayMgr.eChangeRes:Remove(self.RfrPrayRed,self);
	OpenMgr.eOpenNow:Remove(self.InitRedState, self)
	SceneMgr.eChangeEndEvent:Remove(self.ChangeScene, self)
	-- UserMgr.eLvUpdate:Remove(self.UpdateLv, self)
end

function My:ChangeScene()
	local sceneId = User.SceneId
	if sceneId == self.RobberySceneId then
		-- iTrace.eError("GS","sceneId==",sceneId)
		self:StarRobberyTree()
	end
end

--渡劫流程树
function My:StarRobberyTree()
    FlowChartUtil.eStart:Add(self.RoTreeStart, self)
	FlowChartUtil.eEnd:Add(self.RoTreeEnd, self)
	FlowChartMgr.Start(self.RobberyFlowChar)
end

function My:RoTreeStart(name)
    FlowChartUtil.eStart:Remove(self.RoTreeStart, self)
end

function My:RoTreeEnd(name)
    FlowChartUtil.eEnd:Remove(self.RoTreeEnd, self)
	self:ClearTree()
end

function My:ClearTree()
	local charMgr = FlowChartMgr
	local name = charMgr.CurName
    if StrTool.IsNullOrEmpty(name) == false then
		if name == self.RobberyFlowChar then
			charMgr.Remove(name)
			charMgr.Current = nil
			-- return
		end
    else
        charMgr.Current = nil
	end
	self:ReqUpState()
	-- SceneMgr:QuitScene()
end

function My:ProtoHandler(Lsnr)
	Lsnr(23000, self.RespStateInfo, self)	 -- " m_confine_info_toc  境界信息  "  
	Lsnr(23016, self.RespSpiritC, self)	  -- " m_war_spirit_change_toc  战灵信息改变 "
	Lsnr(23018, self.RespSpiritU, self)	   -- " m_war_spirit_up_toc   战灵升级  "
	Lsnr(23020, self.RespMissionU, self)	  -- " m_confine_mission_toc   境界任务更新  "
	Lsnr(23034, self.RespStateUpExp, self)   -- " m_confine_up_toc   境界提升返回  "

	Lsnr(23028, self.RespStateCalc, self)   -- " m_confine_calc_toc   用于是否需要打副本，显示任务的临界判断  "
end

--闭关红点
function My:RfrPrayRed()
	local prayRed = nil
	if PrayMgr.todayTimes == 0 then
		prayRed = true
	else
		prayRed = false
	end
	self.isPrayRed = prayRed
	self.eUpdateStRedState(self.isPrayRed)
	self:InitRedState()
end

--渡劫副本状态 
--1，成功   2，失败
function My:CopeyState(state)
	local curSceneId = User.SceneId
	curSceneId = tostring(curSceneId)
	local temp = CopyTemp[curSceneId]
	if not temp then iTrace.eError("GS","渡劫副本配置id:" .. curSceneId .. "为空") return end
	if temp.type == 17 then --渡劫副本类型
		self.RobberyState = state
	end
end

--灵器红点刷新(主界面境界图标)
function My:RfrSpirEqRed()
	local actId = ActivityMgr.DJ
	local red = RobEquipsMgr.SpirHasRed();
	self:StateSpRed(5,red);--设置战灵界面“战灵”按钮红点
	if red == true then
		SystemMgr:ShowActivity(actId,5)
	else
		SystemMgr:HideActivity(actId,5)
	end
end

--根据等级限制是否显示红点
--true:不显示红点信息
--flase:显示红点信息
function My:UpdateLv()
	local roleLv = User.MapData.Level
	local isLv = false
	local curStateDate = self:GetCurStateInfo()
	if curStateDate == nil then return end
	local limitLv = curStateDate.needLv
	if limitLv > 0 and roleLv <= limitLv then
		isLv = true
		-- self:ClearRedState()
	elseif limitLv == 0 and roleLv > limitLv then
		isLv = false
	end
	self.roleLimit = isLv
end

--登陆时返回信息
function My:RespStateInfo(msg)
	local state = msg.confine --10 01 (10:大境界， 01 小境界)
    local curSpiritId= msg.war_spirit -- 当前战灵id
    local spiritTab = msg.war_spirit_list -- 战灵列表
	local curMission = msg.mission  -- (mission_id,status(false   true),times)
	-- iTrace.Error("GS","state==",state,"  curSpiritId=",curSpiritId,"   spiritTab=",#spiritTab,"  curMission=",#curMission)
	self.curSpiId = curSpiritId
	self.spiTab = spiritTab
	self.curState = state
	self.isReward = msg.reward --副本奖励领取状态 true:已领，需要去打副本 rostate==5， false:没领，不需要打副本 rostate==1
	self.BigCurState=self:GetBigState(state);
	self.SmallCurState=self:GetSmallState(state);
	self:InitRoMissionInfo(curMission)
	self:InitStateInfo(state)
	self:InitSpiriteInfo(curSpiritId,spiritTab,nil)
	self:IsRobberyCopy()

	RobEquipsMgr:SetSpirEquipsLock(msg.war_spirit_lock_info);
	RobEquipsMgr:InitSpirEquips(spiritTab);

	My.eUpInfo()
end

--请求修炼返回
function My:RespStateUpExp(msg)
	if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
		return
	end
	local state = msg.confine  --新的境界
	-- iTrace.Error("GS"," get server  请求修炼返回   state==",state)
	self.isSecond = false --是否是第二次发送协议
	self.aniIndex = 0 --用来判断动画状态
	if self.curState == state then
		self.isSecond = true
	end
	self.curState = state
	self:InitStateInfo(state)
	local preCfg = self:GetPreCfg(state)
	local amTab = self.AmbitInfo
	local bigState = self:GetBigState(state)
	local smallState = self:GetSmallState(state)
	local curCfg = amTab[bigState][smallState]
	local RoleCate = User.MapData.Sex
	local copyId = curCfg.needCopyId
	local skilTab = curCfg.getSkill
	local skilBookTab = curCfg.getBook
	local skilTabLen = #skilTab
	local skilBookLeb = #skilBookTab
	local isSkill = skilTabLen > 0
	local curTab = isSkill == true and skilTab or skilBookTab
	local skillId = RoleCate == curTab[1].k and curTab[1].v or curTab[2].v
	self.FlySkillId = skillId
	if preCfg.needCopyId == 0 and self.isSecond == false then --主线任务突破
		if isSkill then
			if state == 1001 then
				self:NoRobberyTip()
			else
				UIRobberyTip:OpenRobberyTip(0)
			end
		else
			UIRobberyTip:OpenRobberyTip(1)
		end
	elseif preCfg.needCopyId > 0 then --渡劫界面突破
		if self.isSecond == true then
			self.RobberyState = 5
			self.aniIndex = 1
			self.isReward = true
		else
			self.isReward = false
			self.RobberyState = 1
			self.aniIndex = 2
			if isSkill then
				UIRobberyTip:OpenRobberyTip(0)
			else
				UIRobberyTip:OpenRobberyTip(1)
			end
		end
	end
	self.eUpdateStateInfo()
	self.eUpInfo()
end

function My:NoRobberyTip()
	local skillId = self.FlySkillId
    if skillId > 0 then
        skillId = tostring(skillId)
        local isSKill = SkillLvTemp[skillId] and 1 or 2
        if isSKill == 1 then
			local cfg = SkillLvTemp[skillId]
			if cfg == nil then
				iTrace.eError("GS","检查 境界配置表配置，  SkillLvTemp 不存在 id为:" .. skillId .. " 的配置")
				return
			end
			OpenMgr:OpenSkill(skillId)
			self.FlySkillId = 0
			self:ReqRobbery()
		end
	end
end

--是否需要打副本临界判断
function My:RespStateCalc(msg)
	local isReward = msg.reward
	-- local upMission = msg.update_mission
	self.isReward = isReward --副本奖励领取状态 true:已领，需要去打副本 rostate==5， false:没领，不需要打副本 rostate==1
	-- self:InitRoMissionInfo(upMission)
	self:MissionState()
end

function My:IsRobberyCopy()
	local sceneId = User.SceneId
	sceneId = tostring(sceneId)
	local temp = CopyTemp[sceneId]
	if temp == nil then
		return
	end
	if temp.type == CopyType.Disaster then
		CopyMgr.eUpdateCopyCur()
	end
end

--是否显示战灵按钮
function My:IsShowSpBtn()
	local isShow = false
    local limitS = SystemOpenTemp["68"].trigParam
	local cfg = self:GetCurCfg()
	if cfg == nil then
		return
	end
	local curState = cfg.id
	if curState >= limitS then
		isShow = true
	end
    return isShow
end

--是否显示战灵红点
--index:0 未开启  1：显示   2：隐藏
function My:IsShowSpRed()
	local index = 0
	local spRed = self.isSpiriteRed
	local isOpen = self:IsShowSpBtn()
	if isOpen == false then
		index = 0
	elseif spRed == true then
		index = 1
	elseif spRed == false then
		index = 2
	end
	return index
end

--获取上一个境界配置
--用来过滤境界在副本中弹窗
function My:GetPreCfg(curState)
	if curState == nil then
		curState = self.curState
	end
	if curState == nil then
		return
	end
	local amTab = self.AmbitInfo
	local bigState = self:GetBigState(curState)
	local smallState = self:GetSmallState(curState)
	if amTab[bigState] == nil then
		return
	end
	local cur = amTab[bigState][smallState]
	if smallState == 0 then
		return cur
	end
	local preSmall = smallState - 1
	local preBig = bigState - 1
	local preCfg = amTab[bigState][preSmall]
	local maxFloor = 1
	if preCfg == nil then
		preCfg = amTab[preBig][1]
		maxFloor = preCfg.floorMax
		preCfg = amTab[preBig][maxFloor]
	end
	return preCfg
end

--获取当前境界配置
function My:GetCurCfg(state)
	local curState = self.curState
	local state = state
	if state ~= nil then
		curState = state
		local cfg = self:GetCurRewCfg(curState)
		return cfg
	end

	local missState = self.RobberyState
	if missState == 1 then --更具任务判断当前境界
		local cfg = self:GetPreCfg()
		return cfg
	end
	if curState == nil or curState == 0 then
		return
	end
	local bigState = self:GetBigState(curState)
	local smallState = self:GetSmallState(curState)
	if smallState == nil or bigState == nil then
		return
	end
	if self.AmbitInfo == nil then
		return
	end
	local amb = self.AmbitInfo
	local curCfg = amb[bigState][smallState]
	return curCfg
end

--获取下一个境界配置
function My:GetNextCfg()
	local missState = self.RobberyState
	if missState == 1 then --更具任务判断当前境界
		local curState = self.curState
		if curState == nil or curState == 0 then
			return
		end
		local bigState = self:GetBigState(curState)
		local smallState = self:GetSmallState(curState)
		if smallState == nil or bigState == nil then
			return
		end
		if self.AmbitInfo == nil then
			return
		end
		local amb = self.AmbitInfo
		if amb[bigState] == nil then
			return
		end
		local curCfg = amb[bigState][smallState]
		return curCfg
	end

	local curState = self.curState
	if curState == nil then
		return
	end
	local bigState = self:GetBigState(curState)
	local smallState = self:GetSmallState(curState)
	if smallState == nil or bigState == nil then
		return
	end
	local amb = self.AmbitInfo
	if amb == nil or amb[bigState] == nil then
		return
	end
	local cur = amb[bigState][smallState]
	if cur == nil then
		return
	end
	local nextSmall = smallState + 1
	local nextBig = bigState + 1
	local nextCfg = amb[bigState][nextSmall]
	local maxState = AmbitCfg[#AmbitCfg].id
	if maxState == curState then
		nextCfg = cur
	end
	if nextCfg == nil then
		nextCfg = amb[nextBig][1]
	end
	if nextCfg == nil then --最大境界
		nextCfg = cur
	end
	return nextCfg
end


--获取当前境界奖励配置
function My:GetCurRewCfg(state)
	local curState = self.curState
	local state = state
	if state ~= nil then
		curState = state
	end
	if curState == nil or curState == 0 then
		return
	end
	local bigState = self:GetBigState(curState)
	local smallState = self:GetSmallState(curState)
	if smallState == nil or bigState == nil then
		return
	end
	if self.AmbitInfo == nil then
		return
	end
	local amb = self.AmbitInfo
	if amb[bigState] == nil or amb[bigState][smallState] == nil then
		return
	end
	local curCfg = amb[bigState][smallState]
	return curCfg
end

function My:GetCurStateIndex()
	local curState = self:GetCurCfg()
	if curState.id == 1000 then
		return 0
	end
    local bigState = self:GetBigState(curState.id)
	local index = (bigState - 10) + 1
	return index
end

--请求更换战灵返回
function My:RespSpiritC(msg)
	local err = msg.err_code -- 1 无此战灵  2 战灵已装备
	-- iTrace.Error("GS"," 请求更换战灵返回 err====",err)
	if err == 3 then
		local restTime = msg.time
		if restTime > 0 then
			UITip.Error("%s秒可更换战灵",restTime)
			return
		end
	end
	if not CheckErr(err) then return end
	local curSpiritId = msg.war_spirit --当前战灵的id
	local spiritTab = msg.war_spirit_list
	self.curSpiId = curSpiritId
	self.spiTab = spiritTab
	self:UpdateSpRed(spiritTab)
	self:InitSpiriteInfo(curSpiritId,spiritTab,nil)
	self.eUpdateSpiInfo()
end

--请求战灵升级返回
function My:RespSpiritU(msg)
	local err = msg.err_code -- 1 战魂丹不足  2 已满级
	if not CheckErr(err) then return end
	local upSpiritInfo = msg.war_spirit -- 升级战灵 (id,level,exp)
	local curSpiritId = self.curSpiId
	local spiritTab = self.spiTab
	self:InitSpiriteInfo(curSpiritId,spiritTab,upSpiritInfo)
	self.eUpdateSpiRefInfo()
end

--境界任务更新
function My:RespMissionU(msg)
	-- iTrace.Error("GS"," get server  respMission up")
	local addMissionInfo = msg.add_mission  -- 增加任务 (mission_id,status(false   true),times)
	local updateMissionInfo = msg.update_mission  -- 更新任务 (mission_id,status(false   true),times)
	local delMission = msg.del_mission -- 完成任务 [int32]
	self:InitRoMissionInfo(addMissionInfo,addMissionInfo,updateMissionInfo,delMission)
	-- iTrace.eError("GS"," ------- 渡劫任务刷新------")
	self.eUpdateMissionInfo()
end

--请求修炼
function My:ReqUpState()
	local msg = ProtoPool.GetByID(23035) -- m_confine_process_tree_tos
	-- msg.type = type
	Send(msg)
end

--请求更换战灵
function My:ReqChangeSp(spiriteId)
	local msg = ProtoPool.GetByID(23015) -- m_war_spirit_change_tos
	msg.id = spiriteId
	Send(msg)
end

--请求战灵升级
function My:ReqUpLvSp(spiriteId,num)
	local msg = ProtoPool.GetByID(23017) -- m_war_spirit_up_tos
	msg.war_spirit = spiriteId
	msg.num = num
	Send(msg)
end

--提交境界任务
function My:ReqMission(missionId)
	local msg = ProtoPool.GetByID(23019) -- m_confine_mission_tos
	msg.mission = missionId
	Send(msg)
end

--发送渡劫
function My:ReqRobbery()
	local msg = ProtoPool.GetByID(23023) 
    Send(msg)
end

--通过境界Id获取大境界id
--state  境界Id 如： 1002
function My:GetBigState(state)
	local bigState = math.modf(state/100)
	return bigState
end

--通过境界Id获取小境界id
--state  境界Id 如： 1002
function My:GetSmallState(state)
	local smallState = state%100
	return smallState
end
--获得当前AmbitInfo信息
function My:GetCurStateInfo()
	if self.BigCurState == 0 then
		return
	end
	return self.AmbitInfo[self.BigCurState][self.SmallCurState];
end


--通过境界Id获取小境界id
--state  境界Id 如： 1002
function My:GetAmbitId(state)
	local bigState = self:GetBigState(state)
	local ambitCfgId = bigState - 10 + 1
	return ambitCfgId --根配置的境界决定 目前 id范围是 1~21 锻体~先祖
end

--初始化境界数据（存储最新的数据）
function My:InitStateInfo(state)
	local bigState = self:GetBigState(state)
	self.BigCurState=bigState;
	local smallState = self:GetSmallState(state)
	self.SmallCurState=smallState;
	local ambitCfgId = self:GetAmbitId(state)
	-- iTrace.Error("GS","big===",bigState,"  small=",smallState)
	self.StateInfoTab.StateId = state
	self.StateInfoTab.bigState = bigState
	self.StateInfoTab.smallState = smallState
	self.StateInfoTab.ambitCfgId = ambitCfgId

	self.isStateRed = self:UpdateStateRedProp()
	self.eUpdateStRedState(self.isStateRed)
	self:InitRedState()
end

--初始化战灵数据（存储最新的数据）
-- curSpiritId:当前战灵id  
-- spTab:其余战灵(tab)
-- upSpInfo:当前升级战灵 tab  （id,level,exp）
function My:InitSpiriteInfo(curSpiritId,spTab,upSpInfo)
	if #spTab == 0 then
		return
	end
	if curSpiritId ~= nil then
		self.SpiriteInfoTab.curId = curSpiritId
	end
	local tempTab = {}
	if upSpInfo ~= nil then
		local curUpId = upSpInfo.id
		local curUpLv = upSpInfo.level
		local curUpExp = upSpInfo.exp
		self.SpiriteInfoTab.curUpId = curUpId
		self.SpiriteInfoTab.curUpLv = curUpLv
		self.SpiriteInfoTab.curUpExp = curUpExp
		for i = 1,#spTab do
			local info = spTab[i]
			if info.id == curUpId then
				info.id = curUpId
				info.level = curUpLv
				info.exp = curUpExp
			end
			table.insert(tempTab,info)
		end
	end
	self.SpiriteInfoTab.spTab = spTab
	if tempTab and #tempTab > 0 then
		self.SpiriteInfoTab.spTab = tempTab
	end
	local otherSpCount = #spTab
	local spiriteTab = {}
	for i = 1,otherSpCount do
		local info = spTab[i]
		local id = info.id
		if spiriteTab[id] == nil then
			spiriteTab[id] = {}
		end
		spiriteTab[id].id = info.id
		spiriteTab[id].lv = info.level
		spiriteTab[id].exp = info.exp
	end
	self.SpiriteInfoTab.spiriteTab = spiriteTab
	self.isSpiriteRed = self:UpdateSpRedProp()
	self.eUpdateSpRedState(self.isSpiriteRed)
	self:InitRedState()
end

--可以用来判断是否有红点(有战灵获取时的红点)
-- self.spRedId 获取新战灵的id self.spRedId ~=nil 有红点  self.spRedId == nil 没有红点
function My:UpdateSpRed(getSpInfo)
	local spId = nil
	local len = #getSpInfo
	for i = 1,len do
		local info = getSpInfo[i]
		local id = info.id
		if self.SpiriteInfoTab.spiriteTab == nil or self.SpiriteInfoTab.spiriteTab[id] == nil then
			spId = id
		end
	end
	self.spRedId = spId
	self:ShowSpModel(spId)
end


function My:ShowSpModel(spId)
	local spId = spId
	if spId ~= nil and spId > 0 then
		spId = tostring(spId)
		local spCfg = SpiriteCfg[spId]
		local modId = spCfg.uiMod
		UIShowGetCPM.OpenCPM(modId)
	end
end

--初始化任务数据（存储最新的数据）
-- curMission:当前任务   （mission_id,status(false   true),times）
function My:InitRoMissionInfo(curMission,addMissionInfo,updateMissionInfo,delMission)
	if curMission ~= nil and #curMission > 0 then
		local len  = #curMission
		for i = 1,len do
			local info = curMission[i]
			local id = info.mission_id
			if self.RoMissionInfoTab[id] == nil then
				self.RoMissionInfoTab[id] = {}
			end
			self.RoMissionInfoTab[id].missId = info.mission_id
			self.RoMissionInfoTab[id].status = info.status
			self.RoMissionInfoTab[id].times = info.times
			self.RoMissionInfoTab[id].delMission = nil
		
		end
		-- self.isMissRed = self:UpdateMisRedProp(curMission)
		-- self.eUpdateStRedState(self.isMissRed)
		-- self:InitRedState()
	end

	if addMissionInfo ~= nil and #addMissionInfo > 0 then
		local len = #addMissionInfo
		for i = 1,len do
			local info = addMissionInfo[i]
			local id = info.mission_id
			if self.RoMissionInfoTab[id] == nil then
				self.RoMissionInfoTab[id] = {}
				self.RoMissionInfoTab[id].missId = info.mission_id
				self.RoMissionInfoTab[id].status = info.status
				self.RoMissionInfoTab[id].times = info.times
				self.RoMissionInfoTab[id].delMission = nil
			end	
		end
		-- self.isMissRed = self:UpdateMisRedProp(addMissionInfo)
		-- self.eUpdateStRedState(self.isMissRed)
		-- self:InitRedState()
	end

	if updateMissionInfo ~= nil and #updateMissionInfo > 0 then
		local len = #updateMissionInfo
		for i = 1,len do
			local info = updateMissionInfo[i]
			local id = info.mission_id
			if self.RoMissionInfoTab[id] ~= nil then
				self.RoMissionInfoTab[id].missId = info.mission_id
				self.RoMissionInfoTab[id].status = info.status
				self.RoMissionInfoTab[id].times = info.times
				self.RoMissionInfoTab[id].delMission = nil
				-- self.eMssState(self.RoMissionInfoTab[id]);
			end	
		end
		-- self.isMissRed = self:UpdateMisRedProp(updateMissionInfo)
		-- self.eUpdateStRedState(self.isMissRed)
		-- self:InitRedState()
	end

	if delMission ~= nil and #delMission > 0 then
		self.roSuccess = true
		local len = #delMission
		for i = 1,len do
			local id = delMission[i]
			self.RoMissionInfoTab[id]=nil;
		end
	end
	self:MissionState()
end

--初始化境界修炼配置表信息（只初始化一次）
function My:InitAmbitCfg()
	local len = #AmbitCfg
	for i = 1,len do
		local info = AmbitCfg[i]
		local ambId = info.id

		local bigState = math.floor(ambId/100)
		local smallState = ambId % 100

		if self.AmbitInfo[bigState] == nil then
			self.AmbitInfo[bigState] = {}
			table.insert(self.AmbNumTab,info)
		end
		self.AmbitInfo[bigState][smallState] = info
	end
end

--初始化战灵配置表信息（只初始化一次）
function My:InitSpiriteLvCfg()
	self.SpiriteLvInfo = {}
	local len = #SpiriteLvCfg
	for i = 1,len do
		local info = SpiriteLvCfg[i]
		if self.SpiriteLvInfo[info.spiriteId] == nil then
			self.SpiriteLvInfo[info.spiriteId] = {}
		end
		self.SpiriteLvInfo[info.spiriteId][info.lv] = info
	end
end

--更新境界红点数据
function My:UpdateStateRedProp()
	local isRedState = false
	local upPropId = 117 --渡劫丹 id
	local upNum = PropMgr.TypeIdByNum(upPropId)
	local missionTab = self.RoMissionInfoTab
	local curAmb = self:GetCurCfg()
	if curAmb == nil or missionTab == nil then
		return
	end
	local needUp = curAmb.costNum
	if upNum > 0 and upNum >= needUp then
		isRedState = true
	end

	for k,v in pairs(missionTab) do
		if v~=nil then
			if v.status == 1 then
				isRedState = false
				break
			end
        end
	end
	return isRedState
end

--更新战灵红点数据
function My:UpdateSpRedProp()
	if self.roleLimit == true then
		return false
	end
	local warPropId = 30402  --战魂丹 id
	local warNum = PropMgr.TypeIdByNum(warPropId)

	local totalExp = 0
	local needExp = 0
	if warNum > 0 then
		local cfg = ItemData[tostring(warPropId)]
		local exp1 = cfg.uFxArg[1] * warNum
		totalExp = totalExp + exp1
	end

	local smallState = self.StateInfoTab.smallState
	local bigState = self.StateInfoTab.bigState
	if smallState == nil or bigState == nil then
		return
	end
	local curAmb = self.AmbitInfo[bigState][smallState]
	local curStateId = curAmb.id

	local curSpList = self.SpiriteInfoTab.spTab
	if curSpList == nil then
		return
	end
	local spLen = #curSpList
	if spLen == 0 then
		return false
	end
	local maxLv = SpiriteLvCfg[#SpiriteLvCfg].lv
	for i = 1,spLen do
		local info = curSpList[i]
		local spId = info.id
		local spLv = info.level
		local spExp = info.exp
		local curSpData = self:GetCurSpiriteCfg(spId,spLv)
		local needState = curSpData.getState
		local limitExp = curSpData.exp
		needExp = limitExp - spExp
		if warNum > 0 and curStateId >= needState and spLv < maxLv and totalExp >= needExp  then
			return true
		end
	end
	return false
end

--更新任务红点数据
function My:UpdateMisRedProp(missionTab)
	-- if self.roleLimit == true then
	-- 	return false
	-- end
	local state = false
	local len = #missionTab
	for i = 1,len do
		local info = missionTab[i]
		local id = info.mission_id
		local status = info.status
		if status == 2 then
			state = true
			break
		end
	end
	return state
end

--任务状态：
--state:0 任务为完成或未领取   state:1 不需要打副本      state：5  需要打副本
function My:MissionState()
	self.RobberyState = 0
	local RMI = self.RoMissionInfoTab
    if RMI==nil then return end
    local temp = {}
    for k,v in pairs(RMI) do
        table.insert(temp,v)
    end
    table.sort(temp,function(a,b) return a.missId < b.missId end)
	local index1 = 0 --未完成
	local index2 = 0 --未领取
	local index3 = 0 --已领取
	local state = 0
	local isReward = self.isReward
	local len = #temp

	self.isMissRed = self:UpdateMisRedProp(temp)
	self.eUpdateStRedState(self.isMissRed)
	self:InitRedState()


	for i = 1,len do
		local info = temp[i]
		local status = info.status
		if status == 1 then
			index1 = index1 + 1
		elseif status == 2 then
			index2 = index2 + 1
		elseif status == 3 then
			index3 = index3 + 1
		end
	end
	if index3 == len then --全部已领取状态
		if isReward == true then
			state = 5 --需要打副本
		else
			state = 1 --不需要打副本
		end
	else
		state = 0 
	end
	self.RoSortMissinTab = temp
	self.RobberyState = state
end

--根据道具数量更新红点
function My:UpdatePropNum()
	self.isStateRed = self:UpdateStateRedProp()
	self.isSpiriteRed = self:UpdateSpRedProp()
	self.eUpdateStRedState(self.isStateRed)
	self.eUpdateSpRedState(self.isSpiriteRed)
	self:InitRedState()
end

--初始化主界面境界按钮红点状态
function My:InitRedState()
	local actId = ActivityMgr.DJ
	-- local spActId = ActivityMgr.ZL
	if self.isStateRed == nil then
		self.isStateRed = false
	end
	if self.isSpiriteRed == nil then
		self.isSpiriteRed = false
	end
	if self.isMissRed == nil then
		self.isMissRed = false
	end

	local prayRed = nil
	local isOpen = PrayMgr:IsOpen()
	if PrayMgr.todayTimes == 0 and isOpen == true then
		prayRed = true
	else
		prayRed = false
    end

	self.isPrayRed = prayRed
	if self.isStateRed == true or self.isMissRed == true or prayRed == true then
		SystemMgr:ShowActivity(actId,1)
	elseif self.isStateRed == false and self.isMissRed == false and prayRed == false then
		SystemMgr:HideActivity(actId,1)
	end
	
	if self.isSpiriteRed == true then
		SystemMgr:ShowActivity(actId,2)
		self:StateSpRed(1,true)
	else
		SystemMgr:HideActivity(actId,2)
		self:StateSpRed(1,false)
	end

	-- local mainRedS = self:IsShowSpRed()
	-- if mainRedS == 0 then
	-- 	return
	-- elseif mainRedS == 1 then
	-- 	SystemMgr:ShowActivity(spActId)
	-- elseif mainRedS == 2 then
	-- 	SystemMgr:HideActivity(spActId)
	-- end
end



--获取当前状态战灵的信息
-- spiriteId:战灵id
-- lv:战灵等级
function My:GetCurSpiriteCfg(spiriteId,lv)
	if self.SpiriteLvInfo then
		return self.SpiriteLvInfo[spiriteId][lv]
	end
end

--获取当前战灵的技能列表
--spiriteId:战灵id
function My:GetCurSpSkillTab(spiriteId)
	local spMaxLv = self:GetSpMaxLv(spiriteId)
	if spMaxLv == 0 then
		iTrace.eError("GS","当前战灵可升最大等级为0")
		return
	end
	if self.SpiriteLvInfo then
		return self.SpiriteLvInfo[spiriteId][spMaxLv].skills
	end
end

--获取战灵最大等级
function My:GetSpMaxLv(spiriteId)
	local maxLv = 0
	local data = SpiriteLvCfg
	for i = 1,#data do
		local cfg = data[i]
		local curLv = cfg.lv
		if cfg.spiriteId == spiriteId then
			if curLv > maxLv then
				maxLv = curLv
			end
		end
	end
	return maxLv
end

--判读当前战灵是否解锁
--true:未解锁  false:已解锁
function My:IsLockCurSp()
	local spiriteInfo = self.SpiriteInfoTab
	local curSpId = SpiritGMgr:GetCurSPId()
    if spiriteInfo.spiriteTab == nil then
        return true
    elseif spiriteInfo.spiriteTab ~= nil and spiriteInfo.spiriteTab[curSpId] == nil then
        return true
    end
    return false
end

--判断战灵是否解锁
--true:未解锁  false:已解锁
function My:IsLockSp(spId)
	local spiriteInfo = self.SpiriteInfoTab
    if spiriteInfo.spiriteTab == nil then
        return true
    elseif spiriteInfo.spiriteTab ~= nil and spiriteInfo.spiriteTab[spId] == nil then
        return true
    end
    return false
end

function My:ClearRedState()
	self.isStateRed = nil
	self.isSpiriteRed = nil
	self.isMissRed = nil
	self.isPrayRed = false
	self:InitRedState()
	self.eUpdateStRedState(false)
	self.eUpdateSpRedState(false)
end

--任务跳转获取途径
function My:JumpGetWayUI(jumpTab,pos,title)
	GetWayFunc.RoMGetWay(jumpTab,pos,title)
end

--任务配置中跳转界面处理
function My:JumpUI(falg)
	local missionId = nil
	if falg > 10000 then
		missionId = falg
	end
	if missionId then
		self:ExeMainMission(missionId)
		return
	end
	local openUID = math.modf(falg/10)
	local falgId = falg % 100
	if openUID == 10 then  --养成界面
		if falgId == 1 then  --神兵
			AdvMgr:OpenBySysID(4)
		elseif falgId == 2 then  --宝物
			AdvMgr:OpenBySysID(2)
		elseif falgId == 3 then  --翅膀
			AdvMgr:OpenBySysID(5)
		elseif falgId == 4 then  --坐骑
			AdvMgr:OpenBySysID(1)
		elseif falgId == 5 then  --宠物
			AdvMgr:OpenBySysID(3)
		elseif falgId == 6 then -- 宠物升级界面
			PetMgr:OpenPetExpUI()
		end
	elseif openUID == 20 then  --装备界面
		if falgId == 1 then  --装备强化
			EquipMgr.OpenEquip(1)
		elseif falgId == 2 then  --装备镶嵌
			EquipMgr.OpenEquip(3)
		elseif falgId == 4 then  --装备进阶
			--EquipMgr.OpenEquip(2,1)
			UITip.Log("系统暂未开启")
		end
	elseif openUID == 30 then  --符文界面
		if falgId == 1 then --符文
			RuneMgr.OpenBySysIndex(1)
		end
	elseif openUID == 40 then  --其他
		if falgId == 1 then --九九窥星塔
			local userLv = User.instance.MapData.Level
			local limitLv = ActivityTemp["109"].lv
			local isOpen = userLv >= limitLv
			if isOpen then
				UICopyTowerPanel:Show(CopyType.Tower)
			else
				UITip.Error("系统未开启")
				JumpMgr:Clear()
			end
		elseif falgId == 2 then  --青竹院
			local other,isOpen = CopyMgr:GetCurCopy("1")
			if isOpen then
				UICopy:Show(CopyType.Exp)
			else
				UITip.Error("系统未开启")
				JumpMgr:Clear()
			end
		elseif falgId == 3 then  --失落谷
			local other,isOpen = CopyMgr:GetCurCopy("7")
			if isOpen then
				UICopy:Show(CopyType.SingleTD)
			else
				UITip.Error("系统未开启")
				JumpMgr:Clear()
			end
		elseif falgId == 4 then --百湾角
			local other,isOpen = CopyMgr:GetCurCopy(CopyType.Glod)
			if isOpen then 
				UICopy:Show(CopyType.Glod)
			else	
				UITip.Error("系统未开启")
				JumpMgr:Clear()
			end
		elseif falgId == 7 then --幽魂林
			local other,isOpen = CopyMgr:GetCurCopy("15")
			if isOpen then
				UICopy:Show(CopyType.XH)
			else
				UITip.Error("系统未开启")
				JumpMgr:Clear()
			end
		elseif falgId == 8 then --五行幻境
			UIRobbery:OpenRobbery(11)
			return
		end
	elseif openUID == 50 then  --竞技殿
		if falgId == 1 then --决战瑶台
			local isOpen = UITabMgr.IsOpen(ActivityMgr.JJD)
			if isOpen == false then
				-- UITip.Error("系统未开启")
				JumpMgr:Clear()
				return
			end
			UIArena.OpenArena(1)
		elseif falgId == 3 then  --仙峰论道
			local isOpen = ActivityMsg.ActIsOpen(10002)
			if isOpen then
				UIArena.OpenArena(2)
			else
				UITip.Error("活动未开启")
				JumpMgr:Clear()
				return
			end

		elseif falgId == 6 then  --诛仙战场
			local isOpen = ActivityMsg.ActIsOpen(10001)
			if isOpen then
				UIArena.OpenArena(4)
			else
				UITip.Error("活动未开启")
				JumpMgr:Clear()
				return
			end
		end
	elseif openUID == 60 then  --BOSS
		if falgId == 1 then --世界BOSS
			local isCanEquiped = PropMgr.GetCanEquipUp()
			if isCanEquiped then
				UIRole:SelectOpen(4)
			else
				UIMgr.Open(UIBoss.Name)
			end
		elseif falgId == 2 then
			UIMgr.Open(UIBoss.Name)
		end
	elseif openUID == 70 then  --仙盟
		if FamilyMgr:JoinFamily() == false then
			UITip.Error("请加入道庭")
			UIMgr.Open(UIFamilyListWnd.Name)
			JumpMgr:Clear()
			return
		end
		if falgId == 1 then --守卫仙盟
			UIMgr.Open(UIFamilyDefendWnd.Name)
		elseif falgId == 2 then  --仙盟宴会
			UIMgr.Open(UIFamilyAnswerIt.Name)
		elseif falgId == 3 then  --讨伐仙盟
			UIMgr.Open(UIFamilyBossIt.Name)
		elseif falgId == 4 then  --仙盟战
			UIMgr.Open(UIFamilyWar.Name)
		elseif falgId == 5 then   --道庭护送
			-- if FamilyEscortMgr:GetOpenStatus() then
			-- 	UIMgr.Open(UIFamilyEscort.Name)
			-- else
			-- 	UITip.Log(string.format("%s级开启", ActivityTemp["103"].lv))
			-- 	JumpMgr:Clear()
			-- end
			UIMgr.Open(UIFamilyMainWnd.Name)
		elseif falgId == 6 then  --道庭宝箱
			-- UIMgr.Open(UIFamilyDepotWnd.Name)
			UIMgr.Open(UIFamilyMainWnd.Name)
		elseif falgId == 7 then  --道庭任务
			-- if OpenMgr:IsOpen(33) then
			-- 	UIMgr.Open(UIFamilyMission.Name)
			-- else
			-- 	UITip.Log("系统未开启")
			-- 	JumpMgr:Clear()
			-- end
			UIMgr.Open(UIFamilyMainWnd.Name)
		end
		-- self:CloseUIRobbery()
		-- self.eCloseRobberyUI()
	elseif openUID == 80 then  --技能
		if falgId == 1 then
			UIRole.OpenIndex = 2
			UIMgr.Open(UIRole.Name)
		end
	elseif openUID == 90 then
		if falgId == 1 then
			SuitMgr.OpenSuit(1)
		end
	elseif falg == 1001 then -- 变强界面(UIGuideJump)
		UIMgr.Open(UIGuideJump.Name)
	elseif falg == 1101 then --好友界面(UIFriendsRecommend)
		UIMgr.Open(UIFriendsRecommend.Name)
		self:SendOpenFUI()
	end
	JumpMgr:InitJump(UIRobbery.Name,1)
end

function My:CloseUIRobbery()
	local active = UIMgr.GetActive(UIRobbery.Name)
	if active ~= -1 then
		UIMgr.Close(UIRobbery.Name)
	end
end

--打开好友界面发送协议，完成该任务
function My:SendOpenFUI()
	local msg = ProtoPool.GetByID(26113)
	msg.action = 1
	Send(msg)
end

--渡劫主线任务处理
function My:ExeMainMission(missionId)
	local mMgr = MissionMgr
	if mMgr.Main == nil then
		return
	end
	local curMainId = mMgr.Main.ID
	if not curMainId then
		return
	end
	if missionId > curMainId then
		Hangup:SetAutoHangup(true)
		mMgr:AutoExecuteActionOfID(curMainId)
		-- mMgr:AutoExecuteAction(MExecute.ClickItem)
	else
		Hangup:SetAutoHangup(true)
		mMgr:AutoExecuteActionOfID(curMainId)
		-- mMgr:AutoExecuteAction(MExecute.ClickItem)
	end
	self.eCloseRobberyUI()
end

--  当前境界信息 --主界任务显示调用
--  eUpdateStateInfo  境界更新事件
function My:GetAmbCurInfo()
	-- local smallState = self.StateInfoTab.smallState
    -- local bigState = self.StateInfoTab.bigState
	-- if smallState == nil or bigState == nil then
	-- 	return
	-- end
	local cur = self:GetCurCfg()
	if cur == nil then
		return
	end
	local smallState = cur.step.k
	local floorName = ""
	local maxFloor = cur.floorMax
	floorName = cur.floorName
	return floorName,smallState,maxFloor
end

--获取境界奖励配置，有显示优先级
--state:境界id
--优先级：战灵＞技能＞技能书＞天赋书（只有这4个有模型） > 战灵装备孔
function My:GetCurSReward(state)
	local temp = {}
	local cfg = self:GetCurRewCfg(state)
	local openSp = cfg.openSp
	if openSp > 0 then --开启战灵id
		table.insert(temp,openSp)
	end
	local rewardId = self:GetSkillOrSkillBook(cfg)
	if rewardId then --技能/技能书/天赋书
		table.insert(temp,rewardId)
	end
	--返回战灵id和装备槽部位
	local spId,part = RobEquipsMgr.GetOpSpirEq(state)
	if part then
		table.insert(temp,part)
	end

	local ringId = self:GetRingRew(cfg)
	if ringId > 0 then
		table.insert(temp,ringId)
	end
	return temp
end

--通过大境界获取最大小境界
function My:GetMaxSmallbyBig(bigState)
	local bigState = bigState
	local smallState = 1
	if smallState == nil or bigState == nil then
        return
	end
	local abInfo = self.AmbitInfo
	local cur = abInfo[bigState][smallState]
	local floor = cur.floorMax
	return floor
end

--获取当前境界所有属性信息，奖励信息
function My:GetStateInfo(bigState)
    local bigState = bigState
	local smallState = 1
    if smallState == nil or bigState == nil then
        return
	end
	local abInfo = self.AmbitInfo
	local cur = abInfo[bigState][smallState]
	local floor = cur.floorMax
	local propTab = {}
	local rewardTab = {}
	local hpType,atkType,defType,armType,ampdamType,damredType = 1,2,3,4,11,12
	local hpNum,atkNum,defNum,armNum,ampdamNum,damredNum = 0,0,0,0,0,0
	for i = 1,floor do
		local kv = {}
		local curInfo = abInfo[bigState][i]
		local ambId = curInfo.id
		-- rewardTab = self:GetCurSReward(ambId)
		local openSpId = curInfo.openSp
		local rewardId = self:GetSkillOrSkillBook(curInfo)
		table.insert(rewardTab,rewardId)
		if openSpId > 0 then
			openSpId = openSpId
			table.insert(rewardTab,openSpId)
		end
		--返回战灵id和装备槽部位
		local spId,part = RobEquipsMgr.GetOpSpirEq(ambId)
		if part then
			table.insert(rewardTab,part)
		end

		local hpVal = curInfo.hp
		local atkVal = curInfo.atk
		local defVal = curInfo.def
		local armVal = curInfo.arm
		local ampdamVal = curInfo.ampdam
		local damredVal = curInfo.damred
		hpNum = hpNum + hpVal
		atkNum = atkNum + atkVal
		defNum = defNum + defVal
		armNum = armNum + armVal
		ampdamNum = ampdamNum + ampdamVal
		damredNum = damredNum + damredVal
	end
	if hpNum > 0 then
		propTab[1] = hpNum
	end
	if atkNum > 0 then
		propTab[2] = atkNum
	end
	if defNum > 0 then
		propTab[3] = defNum
	end
	if armNum > 0 then
		propTab[4] = armNum
	end
	if ampdamNum > 0 then
		propTab[11] = ampdamNum
	end
	if damredNum > 0 then
		propTab[12] = damredNum
	end
	return propTab,rewardTab
end

--获取技能或技能书或天赋书奖励
--cfg:配置信息
function My:GetSkillOrSkillBook(cfg)
	if cfg == nil then
		iTrace.eError("GS","传入境界配置cfg为空")
		return
	end
	local RoleCate = User.MapData.Sex --角色性别
	local curInfo = cfg
	if curInfo.id == 1000 then
		return
	end
	local curF = curInfo.floorName
	local skills = curInfo.getSkill
	local skillBooks = curInfo.getBook
	local reInfo = #skills > 0 and skills or skillBooks
	local rewardId = RoleCate == reInfo[1].k and reInfo[1].v or reInfo[2].v
	if rewardId == nil or rewardId == 0 then
		iTrace.eError("GS","检查  " .. curF .. ":获得技能/获得技能书/天赋书配置")
	end
	return rewardId
end

--获取脚下光环奖励
--cfg:配置信息
function My:GetRingRew(cfg)
	if cfg == nil then
		iTrace.eError("GS","传入境界配置cfg为空")
		return 0
	end
	-- local RoleCate = User.MapData.Sex --角色性别
	local curInfo = cfg
	if curInfo.id == 1000 then
		return 0
	end
	-- local curF = curInfo.floorName
	-- local skills = curInfo.getSkill
	-- local skillBooks = curInfo.getBook
	-- local reInfo = #skills > 0 and skills or skillBooks
	-- local rewardId = RoleCate == reInfo[1].k and reInfo[1].v or reInfo[2].v
	-- if rewardId == nil or rewardId == 0 then
		-- 	iTrace.eError("GS","检查  " .. curF .. ":获得技能/获得技能书/天赋书配置")
		-- end
	local rewardId = curInfo.ringId
	return rewardId
end

function My:Dispose()
	self:RemoveProto()
end

return My
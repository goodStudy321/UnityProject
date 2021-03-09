--region CopyMgr.lua
--Date
--此文件由[HS]创建生成
require("Data/Copy/CopyMove")
require("Data/Copy/CopyTowerMgr")
CopyMgr = {Name="CopyMgr"}
local M = CopyMgr
local Send = ProtoMgr.Send

M.Tower = tostring(CopyType.Tower)
M.Exp = tostring(CopyType.Exp)
M.Glod = tostring(CopyType.Glod)
M.Equip = tostring(CopyType.Equip)
M.Five = tostring(CopyType.Five)
M.STD = tostring(CopyType.SingleTD)
M.PBoss = tostring(CopyType.PBoss)
M.XH = tostring(CopyType.XH)
M.Loves = tostring(CopyType.Loves)
M.ZLT = tostring(CopyType.ZLT)
M.ZHTower = tostring(CopyType.ZHTower)
M.TreasureTeam = tostring(CopyType.TreasureTeam)
M.TXTower = tostring(CopyType.TXTower)
M.Copy = {}
M.Copy[M.Tower] = {}
M.Copy[M.Exp] = {}
M.Copy[M.Glod] = {}
M.Copy[M.Equip] = {}
M.Copy[M.STD] =  {}
M.Copy[M.PBoss] =  {}
M.Copy[M.XH] = {}
M.Copy[M.Loves] = {}
M.Copy[M.ZLT] = {}
M.Copy[M.ZHTower] = {}
M.Copy[M.TreasureTeam] = {}
M.Copy[M.TXTower] = {}
M.CopyInfo = {}

M.eCopyState=Event()
M.eInitCopyInfo = Event()
M.eUpdateTower=Event()

M.eUpdateCopyInfo = Event()
M.eUpdateCopyData = Event()
M.eUpdateCopyExpGuideTimes = Event()
M.eUpdateCopyStar = Event()
M.eUpdateCopyStatus = Event()
M.eUpdateCopyATime = Event()
M.eUpdateCopyITime = Event()
M.eUpdateCopyCur = Event()
M.eUpdateCopySub = Event()

M.eCopyInfoCountDown = Event()
M.eUpdateCopyExpInfo = Event()
M.eUpdateGetReward = Event()
M.eUpdateCopyCleanReward = Event()
M.eUpdateSuccessListEnd = Event()
M.eUpdateCreateMonster = Event()
M.eUpdateRedPoint = Event()


M.eUpdateImmortalDrop = Event()
M.eUpdateImmortalRemainMonster = Event()
M.eUpdateImmortalRunMonster = Event()
M.eUpdateImmortalUseSkill = Event()
M.eUpdateImmortalInfo = Event()
M.eImmortalStart = Event()
M.eUpdateGuardNum = Event()
M.eUpdateGuardFx = Event()

M.eMarryCopyRequest = Event()
M.eMarryCopyIcon = Event()
M.eMarryCopySelect = Event()
M.eMarryCopyFinish = Event()
M.eMarryCopySweet = Event()

M.eFirstPassCopy = Event()

M.eExpCheerStatus =Event()

M.eUpdateCopyExpMergeTimes = Event()
M.eUpdateSelectTXTowerInfo = Event()
M.eUpdateCopyEndStatus = Event()

M.eUpdateCopyHonor = Event()

M.PlayStartTree = false

function M:Init()
	self:InitData()
	self:AddProto()
end

function M:InitData(init)
	self.Copy[self.Tower].IndexOf = {}
	self.Copy[self.Tower].Dic = {}
	self.Copy[self.Exp].IndexOf = {}
	self.Copy[self.Exp].Dic = {}
	self.Copy[self.Glod].IndexOf = {}
	self.Copy[self.Glod].Dic = {}
	self.Copy[self.Equip].IndexOf = {}
	self.Copy[self.Equip].Dic = {}
	self.Copy[self.STD].Dic = {}
	self.Copy[self.STD].IndexOf = {}
	self.Copy[self.PBoss] = {}
	self.Copy[self.PBoss].Dic = {}
	self.Copy[self.PBoss].IndexOf = {}
	self.Copy[self.XH].Dic = {}
	self.Copy[self.XH].IndexOf = {}
	self.Copy[self.Loves].Dic = {}
	self.Copy[self.Loves].IndexOf = {}
	self.Copy[self.ZLT].Dic = {}
	self.Copy[self.ZLT].IndexOf = {}
	self.Copy[self.ZHTower].Dic = {}
	self.Copy[self.ZHTower].IndexOf = {}
	self.Copy[self.TreasureTeam].Dic = {}
	self.Copy[self.TreasureTeam].IndexOf = {}
	self.Copy[self.TXTower].Dic = {}
	self.Copy[self.TXTower].IndexOf = {}
	self.TeamCopy = {}
	self.TeamCopy.IndexOf = {}
	self.TeamCopy.Dic = {}

	self.TowerReceives = {}
	self.CopyCleanRewards = {}
	self:CreateCopyDic() 
	self:SortTower()
	self:ResetCopyIndexOf()

	self.LimitTower = 0	--副本id
	self.TXTowerLimit = 0
	self.TXTowerLimitIndex = -1
	self.TXTowerTimer = 0
	self.TxTowerEndStatus = 0
	self.GetExp = "0"

	self.AllExp = "0"
	self.AllSilver = 0
	self.AllItems = {}
	self.GetRewardId = nil
	self.CopyEndTime = nil
	self.CopyEndStar = nil
	self.CopyHonor = 0
	--仙侣副本次数  0：有次数    1：没有次数  
	self.HaveRwdIndex = 0
end

function M:AddProto()
	local EH = EventHandler
	self.OnChangeLevel = EH(self.UpdateCopyRedPoint, self)
	self.OnUpdateCopyCreate = EH(self.UpdateCopyCreate, self)
 	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")	
  	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveProto()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:UpdateEvent(e)
	e("UpdateCopyCreate", self.OnUpdateCopyCreate)
	--e("m_pickUp",self.OnUpdateDropItem)
	e("OnChangeLv", self.OnChangeLevel)
end

function M:SetEvent(fn)
	SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent, self.ChangeSceneEnd, self)
end

function M:ProtoHandler(Lsnr)
	Lsnr(21600, self.RespCopyListToc, self)	
	Lsnr(21602, self.RespCopyItemUpdateToc, self)	
	Lsnr(21604, self.RespCopyInfoToc, self)
	Lsnr(21614, self.RespCopyInfoUpdateToc, self)		
	Lsnr(21606, self.RespCopySuccessUpdate, self)	
	Lsnr(21610, self.RespCopyTowerUpdate, self)	
	Lsnr(21612, self.RespCopyTowerReward, self)	
	Lsnr(21618, self.RespCopyExpUpdate, self)	
	Lsnr(21624, self.RespCopyExpCheerTip, self)	
	Lsnr(21626, self.RespCopyExpCheerStatus, self)	
	Lsnr(21628, self.RespCopyFirstPast, self)	
	Lsnr(21632, self.RespCopyClen, self)
	Lsnr(21634, self.RespCopyExpGuideTimes, self)	
	Lsnr(21642, self.RespCopyBuyTimes, self)	
	Lsnr(21644, self.RespCopyRestart, self)	
	Lsnr(24300, self.RespCopyCheerTimes, self)
	Lsnr(24302, self.RespCopyCheer, self)
	Lsnr(24302, self.RespCopyCheer, self)
	Lsnr(21640, self.RespCopyCdRemove, self)


	Lsnr(23102, self.RespCopyImmortalDrop, self)	
	Lsnr(23104, self.RespCopyImmortalInfo, self)	
	Lsnr(23106, self.RespCopyImmortalRemainMonster, self)	
	Lsnr(23108, self.RespCopyImmortalRunMonster, self)	
	Lsnr(23110, self.RespCopyImmortalStart, self)	
	Lsnr(23112, self.RespCopyImmortalSetGuard, self)	
	Lsnr(23114, self.RespCopyImmortalResetGuard, self)
	Lsnr(23116, self.RespCopyImmortalUseSkill, self)
	Lsnr(23118, self.RespCopyImmortalSummonBoss, self)
	Lsnr(23120, self.RespCopyImmortalAutoSummonBoss, self)

	Lsnr(23644, self.RespMarryCopyRequest, self)
	Lsnr(23646, self.RespMarryCopyBuy, self)
	Lsnr(23650, self.RespMarryCopyIcon, self)
	Lsnr(23652, self.RespMarryCopySelect, self)
	Lsnr(23654, self.RespMarryCopyFinish, self)
	Lsnr(23648, self.RespMarryCopySweet, self)

	Lsnr(21652, self.RespCopyExpMergeTimes, self)

	Lsnr(21670, self.RespCopyMaxUniverseUpdate, self)

	Lsnr(24922, self.RespUniverseFloorInfo, self)
	Lsnr(20680, self.RespCopyHonor, self)
end


function M:RespCopyHonor(msg)
	self.CopyHonor = msg.honor
	-- iTrace.eError("GS","msg.honor===",msg.honor)
	self.eUpdateCopyHonor()
end

function M:GetCopyHonor()
	local honor = self.CopyHonor
	return honor
end

function M:SetHaveRwdIndex(index)
	self.HaveRwdIndex = index
end

function M:RespCopyMaxUniverseUpdate(msg)
	self:UpdateCopyTXTowerLimit(msg.max_universe)
	self:UpdateCopyTXTowerTimer(msg.universe_use_time)
	self.TxTowerEndStatus = msg.status --"0正常通关 1最低战力 2最快通关"
	self.eUpdateCopyEndStatus()
end

function M:RespUniverseFloorInfo(msg)
	local fRoleId = msg.fast_role_id
	local fRoleName = msg.fast_role_name
	local time = msg.use_time
	local pRoleId = msg.power_role_id
	local pRoleName = msg.power_role_name
	local pServerName = msg.power_server_name
	local power = msg.power
	self.eUpdateSelectTXTowerInfo(fRoleName, time, pRoleName, power)
end

--//经验副本合并次数返回
function M:RespCopyExpMergeTimes(msg)
	if msg.err_code ~= 0 then
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	else
		self:UpdateCopyExpMergeTimes(msg.merge_times)
	end
end

--//经验副本合并次数
function M:ReqCopyExpMergeTimes(merge_times)
	local msg = ProtoPool.GetByID(21651)
	msg.merge_times = merge_times
    ProtoMgr.Send(msg)
end


--情侣副本
--请求情侣购买次数
function M:ReqMarryCopyRequest()
	local msg = ProtoPool.GetByID(23643)
    ProtoMgr.Send(msg)
end

--请求情侣购买次数返回
function M:RespMarryCopyRequest(msg)
	if msg.err_code ~= 0 then
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	else
		if tostring(msg.from_role_id) ~= tostring(User.MapData.UID) then
			self.eMarryCopyRequest(msg.from_role_id)
		else
			UITip.Log("已请求对方购买")
		end
	end
end

function M:RespMarryCopyBuy()
	UITip.Log("仙侣副本次数已增加")
end


-- 结束时弹出的图标选择
function M:RespMarryCopyIcon(msg)
	self.eMarryCopyIcon(msg.item_list, msg.end_time)
end

--情侣选择物品
function M:ReqMarryCopySelect(id)
	local msg = ProtoPool.GetByID(23651)
	msg.item = id
    ProtoMgr.Send(msg)
end

--情侣选择物品返回
function M:RespMarryCopySelect(msg)
	if msg.err_code ~= 0 then
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	else
		self.eMarryCopySelect(msg.item)
	end
end

--图标选择完毕 or 超时
function M:RespMarryCopyFinish(msg)
	self.CopyInfo.rewardType = msg.reward_type
	self.eMarryCopyFinish()
end

--甜蜜度信息更新
function M:RespMarryCopySweet(msg)
	self.CopyInfo.isDecrease = msg.is_decrease
	self.CopyInfo.remainTime = msg.remain_time
	self.eMarryCopySweet(msg.is_decrease, msg.remain_time)
end



--塔防副本
--掉落信息
function M:RespCopyImmortalDrop(msg)
	self.eUpdateImmortalDrop(msg.drop_list)
end

--进入地图推送信息
function M:RespCopyImmortalInfo(msg)
	local info = self.CopyInfo

	local skillDic = {}
	local skillList = msg.skill_list

	local now = TimeTool.GetServerTimeNow()*0.001
	for i=1,#skillList do
		local v = skillList[i]
		local key = tostring(v.id)
		local temp = {}
		local cd = v.val-now
		temp.cd = cd<0 and 0 or cd
		temp.time = v.type
		temp.id = v.id
		skillDic[key] = temp
	end

	info.skillDic = skillDic
	info.remainNum = msg.remain_num
	info.runNum = msg.run_num
	info.summonBossRound = msg.summon_boss_round
	info.isAuto = msg.is_auto_summon
	self:UpdateGuardCount(msg.guard_list)
	self.eUpdateImmortalInfo()
end

--剩余怪物更新
function M:RespCopyImmortalRemainMonster(msg)
	self.CopyInfo.remainNum = msg.remain_num
	self.eUpdateImmortalRemainMonster(msg.remain_num)
end

--逃跑怪物数量更新
function M:RespCopyImmortalRunMonster(msg)
	self.CopyInfo.runNum = msg.run_num
	self.eUpdateImmortalRunMonster(msg.run_num)
end

--请求开启副本
function M:ReqCopyImmortalStart()
	local msg = ProtoPool.GetByID(23109)
    ProtoMgr.Send(msg)
end

--开启副本
function M:RespCopyImmortalStart(msg)
	if msg.err_code ~= 0 then
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	else
		self.eImmortalStart()
	end
end

--请求守卫信息设置
function M:ReqCopyImmortalSetGuard(id, type)
	local msg = ProtoPool.GetByID(23111)
	local t = msg.guard_list
	t.id = id 
	t.val = type
    ProtoMgr.Send(msg)
end

--守卫信息设置
function M:RespCopyImmortalSetGuard(msg)
	if msg.err_code == 0 then
		local info = self.CopyInfo
		local guard = msg.guard_list
		info.guardDic[tostring(guard.id)] = guard.val
		self:UpdateGuardNum(info.guardDic)
		self.eUpdateGuardFx(guard.id, guard.val)
	else
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end

--请求复用配置
function M:ReqCopyImmortalResetGuard()
	local msg = ProtoPool.GetByID(23113)
    ProtoMgr.Send(msg)
end

--复用配置
function M:RespCopyImmortalResetGuard(msg)
	if msg.err_code == 0 then
		self:UpdateGuardCount(msg.guard_list)
		self.eUpdateGuardFx()
	else
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end

--请求使用技能
function M:ReqCopyImmortalUseSkill(skill_id)
	local msg = ProtoPool.GetByID(23115)
	msg.skill_id = skill_id
    ProtoMgr.Send(msg)
end

--使用技能
function M:RespCopyImmortalUseSkill(msg)
	if msg.err_code == 0 then
		local skill = msg.skill
		local cd = skill.val-TimeTool.GetServerTimeNow()*0.001
		self.eUpdateImmortalUseSkill(skill.id, cd, skill.type)
	else
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end

--请求召唤boss
function M:ReqCopyImmortalSummonBoss()
	local msg = ProtoPool.GetByID(23117)
    ProtoMgr.Send(msg)
end

--召唤boss
function M:RespCopyImmortalSummonBoss(msg)
	if msg.err_code == 0 then
		self.CopyInfo.summonBossRound = msg.summon_boss_round
	else
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end

--请求自动召唤boss
function M:ReqCopyImmortalAutoSummonBoss(isAuto)
	local msg = ProtoPool.GetByID(23119)
	msg.is_auto_summon = isAuto
    ProtoMgr.Send(msg)
end

--请求自动召唤boss
function M:RespCopyImmortalAutoSummonBoss(msg)
	if msg.err_code == 0 then
		self.CopyInfo.isAuto = msg.is_auto_summon
	else
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end


--上线推送
function M:RespCopyListToc(msg)
	local list = msg.copy_list
	local len = #list
	FiveElmtMgr.curMaxCopyId=msg.cur_five_elements
	for i=1,len do
		local info = list[i]
		if info then
			local type = info.copy_type
			local times = info.enter_times
			local buy = info.buy_times
			local canEnter = info.can_enter_time
			local itemAdd = info.item_add_times
			local cleanTimes = info.clean_times
			self:UpdateCopyData(type, times, buy, canEnter, itemAdd, cleanTimes, true)
			local stars = info.star_list
			local slen = #stars
			for i=1,slen do
				local star = stars[i]
				self:UpdateCopyStar(type, star.id, star.val, true)
			end
		end
	end	
	self.HaveRwdIndex = msg.is_have_times
	local rList = msg.tower_reward_list
	local rlen = #rList
	for i=1,rlen do
		self:UpdateTowerReward(rList[i], true)
	end
	self:UpdateCopyTowerData(msg.tower_id, true)
	self:UpdateCopyExpGuideTimes(msg.exp_finish_times, msg.exp_enter_times)

	-- FiveElmtMgr:InitFvElmt(msg.five_elements_cds);
	self:UpdateCopyExpMergeTimes(msg.exp_merge_times)
	FiveElmtMgr:InitFvElmt(msg);
	self:UpdateCopyTXTowerLimit(msg.max_universe, true)
	self:UpdateCopyTXTowerTimer(msg.universe_use_time, true)
	self:UpdateCopyRedPoint()
	self.eInitCopyInfo()
end

--副本信息更新
function M:RespCopyItemUpdateToc(msg)
	local info = msg.copy_item
	if info then
		local type = info.copy_type
		local times = info.enter_times
		local buy = info.buy_times
		local canEnter = info.can_enter_time
		local itemAdd = info.item_add_times
		local cleanTimes = info.clean_times
		self:UpdateCopyData(type, times, buy, canEnter, itemAdd, cleanTimes, false)
		local stars = info.star_list
		local slen = #stars
		for i=1,slen do
			local star = stars[i]
			self:UpdateCopyStar(type, star.id, star.val, false)
		end
		self:UpdateCopyRedPoint()
	end
end

--副本面板信息
function M:RespCopyInfoToc(msg)
	local mapid = msg.map_id
	local status = msg.status
	local startTime = msg.start_time
	local endTime = msg.end_time
	local cur = msg.cur_progress
	local sub = msg.sub_progress
	local totalWave = msg.all_wave
	self:UpdateCopyInfo(mapid, status, startTime, endTime, cur, sub, totalWave)
	--设置副本自动挂机移动位置
	CopyMove:SetMovePos(mapid, cur)
end

--副本信息更新
function M:RespCopyInfoUpdateToc(msg)
	local list = msg.kv_list
	for i=1, #list do
		local id = list[i].id
		local value = list[i].val
		if id == 1 then
			self:UpdateCopyStatus(value)
		elseif id == 2 then
			self:UpdateCopyStartTime(value)
		elseif id == 3 then
			self:UpdateCopyEndTime(value)
		elseif id == 4 then
			self:UpdateCopyCur(value)
		elseif id == 5 then
			self:UpdateCopySub(value)
		end
	end
end


--副本成功结算面板
function M:RespCopySuccessUpdate(msg)
	self:UpdateSuccessUpdate(tostring(msg.exp))
	local list = msg.goods_list
	local len = #list
	for i=1,len do
		local info = list[i]
		if info then
			self:UpdateSuccessListUpdate(info.id, info.val)
		end
	end
	self.eUpdateSuccessListEnd(self.CopyEndStar, self.AllItems)
end

--爬塔副本进度更新
function M:RespCopyTowerUpdate(msg)
	self:UpdateCopyTowerData(msg.tower_id)
end

--领取爬塔副本额外奖励返回
function M:RespCopyTowerReward(msg)
	-- if not self:CheckErr(msg.err_code) then return end
	-- self:UpdateTowerReward(msg.tower_reward_id)
	-- self:UpdateTowerRedPoint()
end

--经验副本经验更新
function M:RespCopyExpUpdate(msg)
	self:UpdateCopyExpInfo(msg.exp)
end


--副本鼓舞次数推送
function M:RespCopyCheerTimes(msg)
	local list = msg.cheer_list
	local len = #list
	for i=1,2 do
		self:UpdateCopyCheerInfo(i, 0, 0)
	end
	for i=1,#list do
		local cheer = list[i]
		self:UpdateCopyCheerInfo(cheer.id, cheer.silver_cheer_times, cheer.all_cheer_times)
	end
end

-- 副本鼓舞返回
function M:RespCopyCheer(msg)
	if self:CheckErr(msg.err_code) then
		local cheer = msg.cheer
		self:UpdateCopyCheerInfo(cheer.id, cheer.silver_cheer_times, cheer.all_cheer_times)
	end
end

--经验副本鼓舞提示
function M:RespCopyExpCheerTip(msg)
	local status = msg.status
	if status == 1 then
		UITip.Error("银两鼓舞次数不足")
	elseif status == 2 then
		UITip.Error("元宝鼓舞次数不足")
	elseif status == 3 then
		UITip.Error("银两、元宝鼓舞次数不足")
	end
end

--经验副本状态设置返回
function M:RespCopyExpCheerStatus(msg)
	self.Copy[self.Exp].IsSilverAuto = msg.is_silver_auto
	self.Copy[self.Exp].IsGoldAuto = msg.is_gold_auto
	self.Copy[self.Exp].FirstSet = msg.has_first_open
	self.eExpCheerStatus()
end

function M:RespCopyFirstPast(msg)
	self.isFirstPass = true
	self.eFirstPassCopy(msg.copy_type)
end


--扫荡副本返回
function M:RespCopyClen(msg)
	--if not CheckErr(msg.err_code) then return end
	if msg.err_code ~= 0 then
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
		return
	end
	self.CopyCleanRewards = {}
	local mapid = msg.map_id
	local num = msg.num
	local exp = msg.add_exp
	local list = msg.goods_list
	self:UpdateCopyClean(100, exp)
	local len = #list
	for i=1,len do
		local item = list[i]
		if item then
			self:UpdateCopyClean(item.type_id, item.num)
		end
	end
	self.eUpdateCopyCleanReward()
end

function M:RespCopyExpGuideTimes(msg)
	self:UpdateCopyExpGuideTimes(msg.exp_finish_times, msg.exp_enter_times)
	self:UpdateCopyRedPoint()
end


--副本cd清除返回
function M:RespCopyCdRemove(msg)
	if msg.err_code ~= 0 then
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end

--请求清除副本cd
function M:ReqCopyCdRemove(copy_id)
	local msg = ProtoPool.GetByID(21639)
	msg.copy_id = copy_id
	Send(msg)
end

--购买挑战次数成功
function M:RespCopyBuyTimes(msg)
	if msg.err_code == 0 then
		UITip.Log("购买挑战次数成功")
	else
		local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
	end
end

--副本重开返回
function M:RespCopyRestart(msg)
	if not self:CheckErr(msg.err_code) then return end
	Hangup:SetSituFight(true)
end
----------------------------------------------------------------------------------------
function M:ReqUniverseFloorInfo(id)
	local msg = ProtoPool.GetByID(24921)
	msg.copy_id = id
	Send(msg)
end

--领取爬塔副本额外奖励
function M:ReqCopyTowerReward(id)
	local msg = ProtoPool.GetByID(21611)
	msg.tower_id = id
	Send(msg)
end

--副本鼓舞
function M:ReqCopyCheer(id, asset_type)
	local msg = ProtoPool.GetByID(24301)
	msg.id = id
	msg.asset_type = asset_type
	Send(msg)
end


--经验副本状态设置
function M:ReqCopyExpCheerStatus(is_silver_auto, is_gold_auto)
	local copy = self.Copy[self.Exp]
	copy.IsSilverAuto = is_silver_auto
	copy.IsGoldAuto = is_gold_auto
	copy.FirstSet = true
	local msg = ProtoPool.GetByID(21625)
	msg.is_silver_auto = is_silver_auto
	msg.is_gold_auto = is_gold_auto
	Send(msg)
end

--扫荡副本
function M:ReqCopyCleanTos(id, num, boss_num)
	local msg = ProtoPool.GetByID(21631)
	msg.map_id = id
	msg.num = num
	msg.boss_num = boss_num or 0
	Send(msg)
end

--购买挑战次数
function M:ReqCopyBuyTimes(id)
	local msg = ProtoPool.GetByID(21641)
	msg.map_id = id
	Send(msg)
end

--副本重开
function M:ReqCpoyRestart()
	local msg = ProtoPool.GetByID(21643)
	Send(msg)
end

----------------------------------------------------------------------------------------

function M:CreateCopyDic()
	for k,v in pairs(CopyTemp) do
		local data = nil
		if v.type == CopyType.Tower then
			self:UpdateTower(k,v)
		else
			data = self:GetCopy(k,v)
		end
		if v.isTeam == 1 then
			self:CreateTeamCopyDic(v)
		end
	end
	self:ResetTeamCopyDic()
end

function M:UpdateTower(k, v)
	table.insert(self.Copy[self.Tower].Dic,v)
	local tower = CopyTowerTemp[k]
	if tower then
		if tower.receiveR then
			local data = {}
			data.ID = tower.id
			data.Status = false
			table.insert(self.TowerReceives, data)
		end
	end
end

function M:GetCopy(k,temp)
	local t = temp.type
	if t == CopyType.Mission then 
		return nil
	elseif t == CopyType.Tower then 
		return nil
	elseif t == CopyType.Light then 
		return nil 
	elseif t == CopyType.Team then 
		return nil 
	end
	local key = tostring(t)
	local data = self.Copy[key]
	if not data then 
		return nil 
	else
		data.Num = 0
		data.Buy = 0
		data.itemAdd = 0
	end
	table.insert(data.IndexOf, temp.id)
	data.Dic[k] = {}
	local child = self.Copy[key].Dic[k]
	child.Temp = temp
	--child.Star = 0
	return child
end

function M:SortTower()
	table.sort(self.TowerReceives, function (a,b) return a.ID < b.ID end)
	local dic = self.Copy[self.Tower].Dic
	local indexof = self.Copy[self.Tower].IndexOf
	table.sort(dic, function (a,b) return a.id < b.id end)
	for i=1,#dic do
		local temp = dic[i]
		if temp then
			indexof[tostring(temp.id)] = i
		end
	end
end

function M:ResetCopyIndexOf()
	for k,v in pairs(self.Copy) do
		table.sort(v.IndexOf, function (a,b) return a < b end)
		--[[
		for i=1,#v.List do
			local temp = v[i]
			if temp then
				v.IndexOf[tostring(temp.id)] = i
			end
		end
		]]--
	end
end

function M:CreateTeamCopyDic(v)
	local id = v.id
	local t = tostring(id)
	if not self.TeamCopy[t] then
		self.TeamCopy.Dic[t] = v
		table.insert(self.TeamCopy.IndexOf,id)
	end
end

function M:ResetTeamCopyDic()	
	table.sort(self.TeamCopy.IndexOf, function (a,b) return a < b end)
end
--------------------------------


---------------------------------
function M:UpdateCopyData(_type, num, buy, timer, itemAdd, cleanTimes, init)
	local key = tostring(_type)
	local data = self.Copy[key]
	if data then
		data.Num = num
		data.Buy = buy
		data.Timer = timer
		data.itemAdd = itemAdd
		data.CleanTimes = cleanTimes
		if not init then self.eUpdateCopyData(_type) end
	end
end

function M:UpdateCopyExpGuideTimes(exp_finish_times, exp_enter_times)
	local info = self.Copy[self.Exp]
	info.FinishTimes = exp_finish_times --//新手经验副本完成次数
	info.EnterTimes = exp_enter_times   --//新手经验副本可以进入的次数
	self.eUpdateCopyExpGuideTimes()
end

function M:UpdateCopyExpMergeTimes(mergeTimes)
	local info = self.Copy[self.Exp]
	info.MergeTimes = mergeTimes --//经验副本合并次数
	self.eUpdateCopyExpMergeTimes()
end

--太虚通天塔最新通关
function M:UpdateCopyTXTowerLimit(limit, value)
	self.TXTowerLimit = limit
	local data = self.Copy[tostring(CopyType.TXTower)]
	if data then
		local indexOf = data.IndexOf
		if indexOf then 
			self.TXTowerLimitIndex = TableTool.Contains(indexOf, limit)
		end
	end
end

--太虚通天塔最短时间通关
function M:UpdateCopyTXTowerTimer(timer, value)
	self.TXTowerTimer = timer
end

--通过id获得太虚塔的层数
function M:GetTxIndex(id)
	local data = self.Copy[tostring(CopyType.TXTower)]
	if data then
		local indexOf = data.IndexOf
		if indexOf then 
			return TableTool.Contains(indexOf, id)
		end
	end
	return -1
end

--通过id获得太虚塔今日通关状态
function M:GetTXTodayFinish(id)
	return self.TXTowerLimit >= id
end

--五行副本红点
function M:UpdateFiveRed( Key )
	local state = false
    if Key==self.Five then
	  state=FiveElmtMgr.Red
	  self.eUpdateRedPoint(Key, state)
	end
	return state
end

--更新副本红点
function M:UpdateRedPoint(key)
	local state = false
	local dic = self:GetCurCopy(key)
	local data = self.Copy[key]	
	if dic and dic.Temp and data then	
		local temp = dic.Temp	
		if key == self.Exp and  data.FinishTimes and data.FinishTimes < GlobalTemp["133"].Value3 then
			state = data.EnterTimes > 0
		elseif key == self.TXTower then
			state = temp.lv <= User.MapData.Level and TongtianRankMgr.isRed == true
		else
			state = data.Buy + data.itemAdd + temp.num > data.Num and temp.lv <= User.MapData.Level
		end
		self.eUpdateRedPoint(key, state)
	end
	return state
end

--更新副本红点
function M:UpdateCopyRedPoint()	
	local list = {self.Exp, self.STD, self.Glod, self.XH--[[, self.ZLT--]]}
	local len = #list
	local copyState = false
	local equipState = false
	local loveState = false
	local FiveState = false
	local ZHTowerState = false
	for i=1,len do
		local state = self:UpdateRedPoint(list[i])
		if not copyState then
			copyState = state
		end
	end
	equipState = self:UpdateRedPoint(self.Equip)
	FiveState = self:UpdateFiveRed(self.Five)
	local actId = ActivityMgr.FB
	if copyState or equipState or FiveState then
		SystemMgr:ShowActivity(actId)
	else
		SystemMgr:HideActivity(actId)
	end

	loveState = self:UpdateRedPoint(self.Loves)
	MarryMgr:SetActionDic(2 ,loveState)

	self:UpdateCopyTowerRedPoint()
end

function M:UpdateCopyTowerRedPoint()
	ZHTowerState = self:UpdateRedPoint(self.ZHTower)
	TXTowerState = self:UpdateRedPoint(self.TXTower)
	local actId = ActivityMgr.TTT
	if ZHTowerState or TXTowerState then
		SystemMgr:ShowActivity(actId)
	else
		SystemMgr:HideActivity(actId)
	end
end

function M:UpdateCopyStar(_type, mapID, star, init)
	local tKey= tostring(_type)
	local cKey = tostring(mapID)
	local data = self.Copy[tKey]
	if data and data.Dic then
		local child = data.Dic[cKey]
		if child then
			child.Star = star
			if not init then self.eUpdateCopyStar(_type, mapID) end
		end
	end
end

--更新副本状态
function M:UpdateCopyStatus(isEnd)
	local info = self.CopyInfo
	info.IsEnd = isEnd 
	local temp = CopyTemp[tostring(info.mapid)]
	if not temp then return end
	if isEnd ~= 0 then 
		if not temp.endTree or isEnd ~= 1 then
			self:PlayEnd()
		else
			self:StartFlowChart(temp.endTree)
		end
	end	
	M.eCopyState(isEnd)
end

--更新副本开始时间
function M:UpdateCopyStartTime(sTime)
	local info = self.CopyInfo
	local now = TimeTool.GetServerTimeNow()*0.001
	info.st = sTime>now and sTime-now or 0
	info.ST = sTime
	self.eUpdateCopyATime(info.ATime, info.st) 
end

--更新副本结束时间
function M:UpdateCopyEndTime(eTime)
	local info = self.CopyInfo
	local now = TimeTool.GetServerTimeNow()*0.001
	info.ATime = eTime-now
	self.eUpdateCopyATime(info.ATime, info.st) 
end

--更新副本当前进度
function M:UpdateCopyCur(cur)
	local info = self.CopyInfo
	info.Cur = cur
	local temp = CopyTemp[tostring(info.mapid)]	
	if not temp then return end
	local cTemp = self:GetChilTemp(temp, info)
	if cTemp then self.eUpdateCopyITime(cTemp.interval) end 
	self.eUpdateCopyCur()
	CopyMove:SetMovePos(info.mapid, cur)
end

--更新副本附进度
function M:UpdateCopySub(sub)
	local info = self.CopyInfo
	info.Sub = sub
	self.eUpdateCopySub()
end

--副本内的数据
function M:UpdateCopyInfo(mapid, isEnd, sTime, eTime, cur, sub, totalWave)
	local temp = CopyTemp[tostring(mapid)]
	if temp then
		if temp.type == CopyType.Mission or temp.type == CopyType.Light then
			return
		end
	else
		return 
	end	
	
	local now = TimeTool.GetServerTimeNow()*0.001
	local info = self.CopyInfo
	info.mapid = mapid
	info.IsEnd = isEnd
	info.Cur = cur
	info.Sub = sub
	info.ST = sTime  --服务器副本开始时间戳
	info.ATime = now>sTime and eTime-now or eTime-sTime --副本剩余时间
	info.st = sTime>now and sTime-now or 0  --副本准备剩余时间
	info.totalWave = totalWave
	self:OpenCopyInfo(temp)
end


function M:OpenCopyInfo(temp)
	local type = temp.type
	local name = nil
	if type == CopyType.Exp then
		name = UICopyInfoExp.Name
	elseif type == CopyType.Glod 
		or type == CopyType.Equip
		or type == CopyType.ZLT
		or type == CopyType.ZHTower
	then
		name = UICopyInfoCmn.Name
	elseif type == CopyType.SingleTD then
		name = UICopyInfoTD.Name
	elseif type == CopyType.GWD
		or type == CopyType.MLGK
		or type == CopyType.YML
		or type == CopyType.HYC
		or type == CopyType.PBoss
		or type == CopyType.Tower
		or type == CopyType.Hjk
		or type == CopyType.TreasureBoss
		or type == CopyType.TXTower
	then
		name = UICopyInfoPub.Name
	elseif type == CopyType.Disaster then
		name = UIRobberyInfo.Name
	elseif type == CopyType.XM 
		or type == CopyType.Fever
	then
		name = UICopyInfoXM.Name
	elseif type == CopyType.XH then
		name = UICopyInfoTower.Name
	elseif type == CopyType.Loves then
		name = UICopyInfoLove.Name
	elseif type == CopyType.TreasureTeam then
		name = UICopyInfoTreasure.Name
	elseif type == CopyType.Five then
		name = UICopyFvElmnt.Name
	end

	if name then
		self.uiName = name	
		local info = self.CopyInfo
		local temp = CopyTemp[tostring(info.mapid)]
		if temp and temp.startTree and not self.PlayStartTree then
			self.PlayStartTree = true
			self:StartFlowChart(temp.startTree)
		else
			self:OpenUICopyInfo()
		end
	end
end

function M:OpenUICopyInfo()
	local active = UIMgr.GetActive(self.uiName)
	if active < 1 then
		UIMgr.Open(self.uiName)
	elseif active == 1 then
		self.eUpdateCopyInfo()			
	end
	self:UpdateCopyStatus(self.CopyInfo.IsEnd)
end
 
--爬塔进度id
function M:UpdateCopyTowerData(towerID, init)
	if self.LimitTower == towerID then return end
	self.LimitTower = towerID
	self:UpdateTowerRedPoint()
	if not init then self.eUpdateTower(towerID) end
end

--更新爬塔红点
function M:UpdateTowerRedPoint()
	-- local data = self.TowerReceives
	-- local len = #data
	-- local state = false
	-- for i=1,len do
	-- 	if data[i].Status == false and data[i].ID <= self.LimitTower then
	-- 		state = true
	-- 		break
	-- 	end
	-- end
	-- local actId = ActivityMgr.TTT
	-- if state then
	-- 	SystemMgr:ShowActivity(actId)
	-- else
	-- 	SystemMgr:HideActivity(actId)
	-- end
end

--副本鼓舞数据
function M:UpdateCopyCheerInfo(id, silverTimes, allTimes)
	local info = self.CopyInfo
	if not info then return end
	if not info.cheerInfo then
		info.cheerInfo = {}
	end
	local cheerInfo = info.cheerInfo
	if not cheerInfo[id] then
		cheerInfo[id] = {}
	end
	cheerInfo[id].silverTimes = silverTimes
	cheerInfo[id].allTimes = allTimes
end

function M:UpdateCopyExpInfo(exp)
	self.GetExp = exp
	self.eUpdateCopyExpInfo()
end

function M:UpdateSuccessUpdate(exp)
	self.AllExp = exp
	local temp = tonumber(exp)
	if temp <= 0 then 
		return 
	end
	--self.AllSilver = silver
	self:UpdateSuccessListUpdate(ItemID.EXP, temp)
end

function M:UpdateSuccessListUpdate(id, num)
	local data = {}
	data.k = id
	data.v = num
	table.insert(self.AllItems, data)
end

function M:UpdateTowerReward(id, init)
	local list = self.TowerReceives
	local len = #list
	for i=1,len do
		local data = self.TowerReceives[i]
		if not init and data.ID == self.GetRewardId then
			self.eUpdateGetReward()
		end
		if id == data.ID then
			data.Status = true
		end
	end
end

function M:UpdateCopyClean(id, num)
	local data = {}
	data.k = id
	data.v = num
	table.insert(self.CopyCleanRewards, data)
end


--副本创建的unit
function M:UpdateCopyCreate(typeid)
	local temp = MonsterTemp[tostring(typeid)]
	if not temp then return end
	self.eUpdateCreateMonster(temp)
end

--更新掉落物
function M:UpdateDropItem(err, id)
	if err ~= 0 then return end
	local info = self.CopyInfo
	if not info.IsEnd then return end
	if not info.Drops then info.Drops = {} end
	table.insert(info.Drops, id)
end

--更新仙魂副本守卫设置数据
function M:UpdateGuardCount(guardList)
	local info = self.CopyInfo

	local guardDic = {}
	local len = #guardList
	for i=1,len do
		guardDic[tostring(guardList[i].id)] = guardList[i].val
	end
	info.guardDic = guardDic
	self:UpdateGuardNum(guardDic)
end

--更新仙魂副本守卫数量
function M:UpdateGuardNum(guardDic)
	local info = self.CopyInfo
	local guardNum = {}
	local temp = GlobalTemp["48"].Value1
	for k,v in pairs(temp) do
		guardNum[tostring(v.id)] = v.value
	end

	for k,v in pairs(guardDic) do
		local key = tostring(v)
		local num = guardNum[key]
		if num then
			guardNum[key] = num-1
		end
	end

	info.guardNum = guardNum
	self.eUpdateGuardNum(guardNum)
end


function M:GetChilTemp(temp, info)
	local t = temp.type
	if not info.Cur then return nil end
	local index = info.Cur
	if index == 0 then index = index + 1 end
	local id = temp.id * 100 + index
	local child = nil
	local key = nil
	key = tostring(id)
	if t == CopyType.Exp then
		key = tostring(temp.id)
		child = CopyExpTemp[key]
	elseif t == CopyType.Glod then
		child = CopyGlodTemp[key]
	elseif t == CopyType.Equip then
		child = CopyEquipTemp[key]
	elseif t == CopyType.SingleTD then
		child = CopyTDTemp[key]
	elseif t == CopyType.ZLT then
		child = CopyZLTTemp[key]
	elseif t == CopyType.ZHTower then
		child = CopyZHTowerTemp[key]
	elseif t == CopyType.TreasureTeam then
		child =  CopyTreasureTemp[key]
	end
	return child
end

function M:IsFinishCopy(id, isTower)
	if isTower == nil then 
		isTower = true 
	end
	if isTower then
		if id <= self.LimitTower then
			return true	
		end
	else
		local temp = CopyTemp[tostring(id)]
		if not temp then
			iTrace.eLog("HS",string.format("IsFinishCopy id{%s} is not copyid.",id))
			return false
		end
		local type = temp.type
		local t = self.Copy[tostring(type)]
		if not t then
			iTrace.eLog("HS",string.format("IsFinishCopy id{%s} is not copytype.",id))
			return false
		end
		local copy = t.Dic[tostring(id)] 
			if copy.Star and copy.Star > 0 then
			return true
		end
	end
	return false
end

function M:OpenTXEndPanel()
	local temp = CopyTemp[tostring(User.SceneId)]
	if not temp then return end
	UIMgr.Open(UIEndPanelTX.Name,self.OpenUIEndPanel, self)
end

function M:OpenEndPanel()
	local temp = CopyTemp[tostring(User.SceneId)]
	if not temp then return end
	UIMgr.Open(UIEndPanel.Name,self.OpenUIEndPanel, self)
end


function M:OpenUIEndPanel(name)
	local ui = UIMgr.Dic[name]
	if not ui then return end
	ui:UpdateData(self.CopyInfo.IsEnd, self.AllItems)
	local t = self.CopyInfo.rewardType
	if not t then return end
	ui:UpdateRewardTitle(string.format("获得“%s”奖励", t==57 and "心有灵犀" or "缘差一线"))
end

function M:CopyInfoCountDown(time)
	self.eCopyInfoCountDown(time)
end

function M:ClearCopyInfo()
	self.CopyInfo = {}
	self.AllItems = {}
	self.GetExp = "0"
	self.AllExp = "0"
	self.AllSilver = 0
	self.CopyEndStar = nil
	self.CopyEndTime = nil
	self.IsEnd = nil
	self.uiName= nil
	self.TxTowerEndStatus = 0
end


function M:StartTimer()
	-- print("==============================================================>  SceneMgr:LastScene "..tostring(SceneMgr.Last))
	-- print("==============================================================>  SceneMgr:OpenScene "..tostring( User.SceneId))
	-- if SceneMgr.Last == 40001 and User.SceneId ~= 40001 then
	-- 	self.eTowerFirstOut(SceneMgr.Last)
	-- end

	if not self.timer then
		self.timer = ObjPool.Get(iTimer)
		self.timer.complete:Add(self.OpenUICopy, self)
	end
	self.timer.seconds = 0.5
	self.timer:Start() 
end

function M:OpenUICopy()
	local last = SceneMgr.Last
	if last then
		if SceneMgr.Last ~= User.SceneId then
			local temp = CopyTemp[tostring(last)]
			if temp then
				local type = temp.type
				if type == CopyType.Loves then
					 UIMarry:OpenTab(2)
				elseif type == CopyType.ZHTower then
					UICopyTowerPanel:Show(type)
				elseif type == CopyType.Exp
				or type == CopyType.Glod 
				or type == CopyType.Equip 
				or type == CopyType.SingleTD 
				or type == CopyType.XH
				or type == CopyType.ZLT
				or type ==  CopyType.ZHTower 
				then
					UICopy:Show(type)
				end
			end
		end
	end 
end

function M:ChangeSceneEnd(isLoad)
	if self.isFirstPass then
		self.isFirstPass = false
		return 
	end
	if isLoad then
		self:StartTimer()
	end
end

--副本流程树
function M:StartFlowChart(three)
	self.OnFlowChartStart = EventHandler(self.FlowChartStart, self)
	EventMgr.Add("FlowChartStart", self.OnFlowChartStart)
	self.OnFlowChartEnd = EventHandler(self.FlowChartEnd, self)
	EventMgr.Add("FlowChartEnd", self.OnFlowChartEnd)
	FlowChartMgr.Start(three)
end

function M:FlowChartStart()
	EventMgr.Remove("FlowChartStart", self.OnFlowChartStart)
	UIMgr.Close(self.uiName)
end

function M:FlowChartEnd()
	EventMgr.Remove("FlowChartEnd", self.OnFlowChartStart)
	if not self.uiName then return end
	UIMgr.Open(self.uiName, self.OpenUICb, self)
end

function M:OpenUICb()
	local info = self.CopyInfo
	if info.IsEnd ~= 0 then
		self:PlayEnd()
	else
		self:OpenUICopyInfo()
	end
end

function M:PlayEnd()
	local info = self.CopyInfo
	local temp = CopyTemp[tostring(info.mapid)]
	if not temp.wait or temp.wait == 0 then
		if temp.type == CopyType.TXTower then
			self:OpenTXEndPanel()
		else
			self:OpenEndPanel() 
		end
	else
		self.eUpdateCopyStatus(temp.wait) 
	end
end

--获取当前可通过的副本
function M:GetCurCopy(key)
	local copyType = tonumber(key)
	local data = self.Copy[tostring(key)]
	local copy = nil
	local isOpen = false
	local floor = 1
	local lv = 0
	local needLv = User.MapData.Level
	if copyType ~= CopyType.Tower and copyType ~= CopyType.Five then
		if data then
			local list = data.IndexOf
			local dic = data.Dic
			if list and dic then
				local len = #list
				for i=1,len do
					local id = list[i]
					local info = dic[tostring(id)]
					if needLv < info.Temp.lv then 
						lv = info.Temp.lv
						break 
					end
					copy = info
					isOpen = true
					floor = i
					if copyType == CopyType.Equip then 
						if (not copy.Star or needLv < copy.Temp.lv) then
							break 
						end		
					elseif (not copy.Star or copy.Star < 3)  then
						break
					end
				end
				if not copy then
					local id = list[1]
					copy = dic[tostring(id)]
				end
			end
		end
	elseif copyType == CopyType.Tower  then--通天塔数据结构和其他不一样
		if data then
			local indexOf = data.IndexOf
			local dic = data.Dic
			if self.LimitTower == 0 then
				copy = dic[1] 
			else
				copy = dic[indexOf[tostring(self.LimitTower)]]
			end
			isOpen = needLv>= copy.lv
			floor = indexOf[tostring(copy.id)]
			lv = copy.lv
		end
	elseif copyType == CopyType.Five  then
		copy=FiveElmtMgr.curMaxCopyId
		isOpen=FiveElmtMgr.IsOpen()
		lv=FiveElmtMgr.OpenLv()
	end
	return copy, isOpen, floor, lv
end

function M:IsOpen(copyId)
	local temp = CopyTemp[tostring(copyId)]
	if not temp then return false end
	local type = temp.type
	local copy, isOpen = self:GetCurCopy(type)
	if not isOpen then return false end
	return copyId <= copy.Temp.id
end


function M:GetPreCopy(key, id)
	if not id then return true end
	local data = self.Copy[key]
	if data then
		local dic = data.Dic
		if dic then
			local info = dic[tostring(id)]
			if info and info.Star then
				return true
			end
		end
	end
	return false
end

--获取副本数据 type：副本类型，  id :副本id
function M:GetCopyData(type, id)
	local data = self.Copy[tostring(type)]
	if not data then return end
	local dic = data.Dic[tostring(id)]
	if dic then
		return dic.Temp
	end
end

--获取下一个难度副本Id  type：副本类型，  id :副本id
function M:GetNextLvCopyId(type, id)
	local data = self.Copy[tostring(type)]
	if not data then return end
	local list = data.IndexOf
	if list then 
		local index = nil
		for i=1,#list do
			if list[i] == id then
				index = i+1
				break
			end
		end
		if index and list[index] then
			return list[index]
		end
	end
end

function M:GetCopyHarmCheer()
	local info = self.CopyInfo
	local cheerInfo = info.cheerInfo
	if not cheerInfo then return end
	local harmInfo = cheerInfo[1]
	return harmInfo
end

function M:GetCopyDefCheer()
	local info = self.CopyInfo
	local cheerInfo = info.cheerInfo
	if not cheerInfo then return end
	local defInfo = cheerInfo[2]
	return defInfo
end


function M:GetCopyCheerById(id)
	if id == 1 then
		return self:GetCopyHarmCheer()
	elseif id == 2 then
		return self:GetCopyDefCheer()
	end
end


function M:IsDoubleCopy(id)
	local info = FestivalActMgr:GetActInfo(FestivalActMgr.CopyDb)
	if not info then return false end
	local itemList = info.itemList
	if itemList  then
		local isOpen = TimeTool.GetServerTimeNow()*0.001 - info.sTime >= 0
		return TableTool.Contains(itemList, {remainCount = id}, "remainCount") ~= -1 and isOpen
	end
	return false
end



function M:CloseUICopy()
	UIMgr.Close(UICopy.Name)
end

function M:ShowEffect()
	Loong.Game.AssetMgr.LoadPrefab("FX_UI_Wave", GbjHandler(self.LoadEffectEnd,self))
end

function M:LoadEffectEnd(go)
	go.transform:SetParent(UIMgr.Root.transform)
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
end

function M:GSub(name)
	local t = {"一" , "二",  "三", "四" , "五",  "六", "七" , "八", "九", "十"}	
	local nStr = name
	for i=1,#t do
		local temp, num = string.gsub(name, t[i], "")
		if num > 0 then
			nStr = temp
			break
		end
	end
	return nStr
end



function M:CheckErr(err_code)
	if err_code == 0 then
		return true
	else
		local err = ErrorCodeMgr.GetError(err_code)
		UITip.Log(err)
		return false
	end
end

function M:ResetFirstPass()
	self.isFirstPass = false
end

function M:GetCopyNum(copyCfg)
	local copyType = copyCfg.type
	local copyData = self.Copy[tostring(copyType)]
	local maxNum = copyCfg.num
	local hNum = 0
	local isChange = false
	local haveRwIndex = self.HaveRwdIndex
	if copyData then
		-- local curNum = copyData.Num
		-- maxNum = maxNum + copyData.Buy + copyData.itemAdd
		-- hNum = maxNum - curNum
		local curNum = 0
		if copyData.Num ~= nil then
			curNum = copyData.Num
		end
		if copyData.Buy ~= nil then
		maxNum = maxNum + copyData.Buy
		end
		if copyData.itemAdd ~= nil then
		maxNum = maxNum + copyData.itemAdd
		end
		hNum = maxNum - curNum
	else
		iTrace.eError("GS","不存在数据，副本类型： ",copyType)
	end
	-- iTrace.eError("GS","name==",copyCfg.name,"  maxNum==",maxNum,"  buyNum==",copyData.Buy,"  curNum==",copyData.Num,"  haveRwIndex==",haveRwIndex,"  hNum==",hNum)
	if copyType == CopyType.Loves then
		if hNum <= 0 and haveRwIndex == 0 then
			hNum = 1
			isChange = true
		elseif hNum <= 0 and haveRwIndex == 1 then
			hNum = hNum
		end
	end
	local curHonor = self:GetCopyHonor()
	local maxHonor = GlobalTemp["201"].Value2[2]
	return hNum,curHonor,maxHonor,isChange
end

function M:Clear()
	self:ClearCopyInfo()
	self:ResetFirstPass()
	self:ClearDic()
	self:InitData()
	CopyTowerMgr:Clear()
end

function M:ClearDic()
	TableTool.ClearDic(self.Copy[self.Exp])
	TableTool.ClearDic(self.Copy[self.Tower])
	TableTool.ClearDic(self.Copy[self.Glod])
	TableTool.ClearDic(self.Copy[self.Equip])
	TableTool.ClearDic(self.Copy[self.STD])
	TableTool.ClearDic(self.Copy[self.PBoss])
	TableTool.ClearDic(self.Copy[self.XH])
	TableTool.ClearDic(self.Copy[self.Loves])
	TableTool.ClearDic(self.Copy[self.ZLT])
	TableTool.ClearDic(self.Copy[self.ZHTower])
	TableTool.ClearDic(self.Copy[self.TreasureTeam])
	TableTool.ClearDic(self.Copy[self.TXTower])
end

function M:Dispose()
	self:RemoveProto()
end

return M

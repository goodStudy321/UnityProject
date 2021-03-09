--// 道庭活动管理器 

FamilyActivityMgr = Super:New{Name = "FamilyActivityMgr"}

local mgrPre = {};
local iLog = iTrace.Log;
local iError = iTrace.Error;
local ET = EventMgr.Trigger;
--刷新守护者血量事件
FamilyActivityMgr.eRfrDftHP = Event();
--守卫道庭活动状态事件
FamilyActivityMgr.eFmlDftState = Event();
--守卫道庭活动开启状态
FamilyActivityMgr.FmlDftState = false;
--主界面倒计时
FamilyActivityMgr.eUpTimer = Event()
FamilyActivityMgr.eEndTimer = Event()


--// 初始化
function FamilyActivityMgr:Init()

	if mgrPre.init ~= nil and mgrPre.init == true then
 		return;
	end

 	--iLog("LY", " FamilyActivityMgr create !!! ");
	mgrPre.init = false;
	
	--创建计时器
	self:CreateTimer()

	--// 重置帮派守卫信息
	self:ResetTDInfo();

 	self:AddLsnr();

 	mgrPre.init = true;
end

--// 重置帮派守卫信息
function FamilyActivityMgr:ResetTDInfo()
	--// 帮派守卫信息
	mgrPre.tdInfo = {};
	--// 总波数
	mgrPre.tdInfo.totalWave = 0;
	--// 当前波数
	mgrPre.tdInfo.curWave = 0;
	--// 击败怪物数量
	mgrPre.tdInfo.killNum = 0;
	--// 怪物突袭时间
	mgrPre.tdInfo.assaultTime = 0;
	--//刷怪时间
	mgrPre.tdInfo.rfMonsTime = 0;
	--// 伤害排行
	mgrPre.tdInfo.rankInfos = {};
	--// 自身排行信息
	mgrPre.tdInfo.selfInfo = nil;
	--// 获得经验更新
	mgrPre.tdInfo.exp = 0;
	--//雕像血量
	mgrPre.DftHPDic = {};
	--守卫结束信息
	mgrPre.EndInfo = {};
	--//道庭守卫结束
	mgrPre.EndInfo.dftEnd = false;
	--//道庭守卫是否战赢
	mgrPre.EndInfo.isWin = false;
	--//星级
	mgrPre.EndInfo.star = 0;
	--//打怪数量（结束时）
	mgrPre.EndInfo.killMonsNum = 0;
	--//打怪奖励经验
	mgrPre.EndInfo.killMonsExp = 0;
	--//星级奖励经验
	mgrPre.EndInfo.starExp = 0;
	--//排行奖励经验
	mgrPre.EndInfo.harmRankExp = 0;
end

--// 添加监听
function FamilyActivityMgr:AddLsnr()
	ProtoLsnr.AddByName("m_family_td_info_toc", self.TDInfoToC, self);
	ProtoLsnr.AddByName("m_family_td_info_update_toc", self.TDInfoUpdateToC, self);
	ProtoLsnr.AddByName("m_family_td_rank_info_toc", self.TDRankInfoToC, self);
	ProtoLsnr.AddByName("m_family_td_exp_toc", self.TDExpToC, self);
	ProtoLsnr.AddByName("m_family_td_hp_toc",self.UpdateDftsHp,self);
	ProtoLsnr.AddByName("m_family_td_end_toc",self.TDEnd,self);
end

--创建计时器
function FamilyActivityMgr:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function FamilyActivityMgr:InvCountDown()
	local time = self.timer.remain
	local sec = self.timer:GetRestTime()
	self.eUpTimer(time, sec)
end

--结束倒计时
function FamilyActivityMgr:EndCountDown()
	self.eEndTimer()
end

--// 清理缓存
function FamilyActivityMgr:Clear()
	self:ResetTDInfo();
	
	mgrPre.init = false;
	--停止计时器
	if self.timer then self.timer:Stop() end
end

function FamilyActivityMgr:Dispose()
	
end

---------------------------------- 向服务器请求 ----------------------------------

--// 请求排行数据
function FamilyActivityMgr:ReqRankInfo()
	local msg = ProtoPool.Get("m_family_td_rank_info_tos");
    ProtoMgr.Send(msg);
end

-------------------------------------------------------------------------------



---------------------------------- 监听函数部分 ----------------------------------

--道庭守卫活动监听
function FamilyActivityMgr:FamilyDft(status, endTime)
	if status == 2 then
		self.FmlDftState = true;
		local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
		local leftTime = endTime - sTime
		self.timer:Restart(leftTime, 1)

		FamilyMgr.eRed(true, 3, 5);
	else
		self.FmlDftState = false;
		FamilyMgr.eRed(false, 3, 5);
	end
	self.eFmlDftState(status)
end

--// 道庭守卫信息到达
function FamilyActivityMgr:TDInfoToC(msg)
	if msg == nil then
		return;
	end

	mgrPre.tdInfo.totalWave = msg.all_wave;
	mgrPre.tdInfo.curWave = msg.wave;
	mgrPre.tdInfo.killNum = msg.kill_num;
	mgrPre.tdInfo.assaultTime = tonumber(msg.assault_time);
	mgrPre.tdInfo.rfMonsTime = msg.next_wave_time;
	mgrPre.EndInfo.dftEnd = false;

	UIDftRfMons:Open(msg.next_wave_time);
	self:SetDftsHp(msg.hp_list)

	--// 触发新数据事件
	ET("NewFTDInfo");
end

--设置守护者血量
function FamilyActivityMgr:SetDftsHp(hp_list)
	if hp_list == nil then
		return;
	end
	local len = #hp_list;
	for i = 1,len do
		self:SetDftHp(hp_list[i].id,hp_list[i].val,true);
	end
end

--更新守护者血量
function FamilyActivityMgr:UpdateDftsHp(msg)
	self:SetDftHp(msg.hp.id,msg.hp.val,false);
end

--设置守护者血量
function FamilyActivityMgr:SetDftHp(k,v,bInit)
	local monsId = k;
	local hpPer = v / 10000;
	mgrPre.DftHPDic[monsId] = hpPer;
	self.eRfrDftHP(monsId,hpPer,bInit);
end

--守卫结束
function FamilyActivityMgr:TDEnd(msg)
	mgrPre.EndInfo.dftEnd = true;
	mgrPre.EndInfo.isWin = msg.is_succ;
	mgrPre.EndInfo.star = msg.star;
	mgrPre.EndInfo.killMonsNum = msg.kill_num;
	mgrPre.EndInfo.killMonsExp = msg.kill_monster_exp;
	mgrPre.EndInfo.starExp = msg.star_exp;
	mgrPre.EndInfo.harmRankExp = msg.rank_exp;
	UIDftExit:Open();
end

--// 道庭守卫信息更新到达
function FamilyActivityMgr:TDInfoUpdateToC(msg)
	if msg == nil or msg.kv_list == nil then
		iError("LY", "FamilyActivityMgr");
		return;
	end

	for i = 1, #msg.kv_list do
		local key = msg.kv_list[i].id;
		local value = msg.kv_list[i].val;
		--// 波数更新("FAMILY_TD_UPDATE_WAVE")
		if key == 1 then
			mgrPre.tdInfo.curWave = value;
		--// 击败数量更新("FAMILY_TD_UPDATE_KILL_NUM")
		elseif key == 2 then
			mgrPre.tdInfo.killNum = value;
		--// 当前副本状态更新(val为2时结束)("FAMILY_TD_UPDATE_STATUS")
		elseif key == 3 then
			--// 副本结束
		--// 更新突袭时间("FAMILY_TD_UPDATE_ASSAULT_TIME")
		elseif key == 4 then
			mgrPre.tdInfo.assaultTime = value;
			ET("NewFTDAssaultTime");
			return;

		elseif key == 5 then
			mgrPre.tdInfo.rfMonsTime = value;
			UIDftRfMons:Open(value);
		end
	end

	--// 触发新数据事件
	ET("NewFTDInfo");
end

--// 道庭守卫排行信息返回
function FamilyActivityMgr:TDRankInfoToC(msg)
	if msg == nil or msg.rank_info == nil or #msg.rank_info <= 0 then
		return;
	end

	mgrPre.tdInfo.rankInfos = {};
	for i = 1, #msg.rank_info do
		local rankI = {};
		rankI.roleId = msg.rank_info[i].role_id;
		if rankI.roleId == nil then
			rankI.roleId = 0;
		end
		rankI.roleName = msg.rank_info[i].role_name;
		if rankI.roleName == nil then
			rankI.roleName = "";
		end
		rankI.rank = msg.rank_info[i].rank;
		if rankI.rank == nil then
			rankI.rank = 0;
		end
		rankI.damage = msg.rank_info[i].damage;
		if rankI.damage == nil then
			rankI.damage = 0;
		else
			rankI.damage = tonumber(rankI.damage);
		end

		mgrPre.tdInfo.rankInfos[#mgrPre.tdInfo.rankInfos + 1] = rankI;

		if rankI.roleId == User.MapData.UIDStr then
			mgrPre.tdInfo.selfInfo = rankI;
		end
	end

	self:ReRankInfo();

	--// 触发排名更新事件
	ET("NewFTDRank");
end

--// 道庭守卫获得经验更新
function FamilyActivityMgr:TDExpToC(msg)
	if msg == nil then
		return;
	end

	mgrPre.tdInfo.exp = msg.exp;

	--// 触发新数据事件
	ET("NewFTDInfo");
end

-------------------------------------------------------------------------------

---------------------------------- 处理数据部分 ----------------------------------

--// 整理伤害排行
function FamilyActivityMgr:ReRankInfo()
	if mgrPre.tdInfo == nil or mgrPre.tdInfo.rankInfos == nil then
		return;
	end

	table.sort(mgrPre.tdInfo.rankInfos, function(a, b)
		return a.rank < b.rank;
	end);
end

-------------------------------------------------------------------------------

---------------------------------- 获取数据部分 ----------------------------------

--// 获取总波数
function FamilyActivityMgr:GetTotalWave()
	if mgrPre.tdInfo == nil or mgrPre.tdInfo.totalWave == nil then
		return 0;
	end

	return mgrPre.tdInfo.totalWave;
end

--// 获取当前波数
function FamilyActivityMgr:GetCurWave()
	if mgrPre.tdInfo == nil or mgrPre.tdInfo.curWave == nil then
		return 0;
	end

	return mgrPre.tdInfo.curWave;
end

--// 获取当前打怪数量
function FamilyActivityMgr:GetKillNum()
	if mgrPre.tdInfo == nil or mgrPre.tdInfo.killNum == nil then
		return 0;
	end

	return mgrPre.tdInfo.killNum;
end

--// 获取当前经验
function FamilyActivityMgr:GetExp()
	if mgrPre.tdInfo == nil or mgrPre.tdInfo.exp == nil then
		return 0;
	end

	return tonumber(mgrPre.tdInfo.exp);
end

--// 获取排行信息
function FamilyActivityMgr:GetRankInfo()
	if mgrPre.tdInfo == nil then
		return nil;
	end

	return mgrPre.tdInfo.rankInfos;
end

--// 获取自身排行信息
function FamilyActivityMgr:GetSelfRank()
	if mgrPre.tdInfo == nil then
		return nil;
	end

	return mgrPre.tdInfo.selfInfo;
end

--// 获取突袭时间
function FamilyActivityMgr:GetAssaultTime()
	if mgrPre.tdInfo == nil or mgrPre.tdInfo.assaultTime == nil then
		return 0;
	end

	local serverTime = TimeTool.GetServerTimeNow();
	serverTime = serverTime / 1000;
	local time = mgrPre.tdInfo.assaultTime - serverTime;

	if time < 0 then
		time = 0;
	end

	return time;
end

--获取刷新怪物时间
function FamilyActivityMgr.GetRfMonsTime()
	if mgrPre.tdInfo == nil or mgrPre.tdInfo.rfMonsTime == nil then
		return 0;
	end
	local serverTime = TimeTool.GetServerTimeNow();
	serverTime = serverTime / 1000;
	local time = mgrPre.tdInfo.rfMonsTime - serverTime;
	if time <= 0 then
		time = 0;
	end
	return time;
end

--获取道庭守卫结束信息
function FamilyActivityMgr.GetDftEndInfo()
	return mgrPre.EndInfo;
end

-------------------------------------------------------------------------------

return FamilyActivityMgr;
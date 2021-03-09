--region TeamMgr.lua
--Date
--此文件由[HS]创建生成

require("Proto/ProtoMgr")

TeamMgr = {Name="TeamMgr"}
local M = TeamMgr
local Send = ProtoMgr.Send
local iError = iTrace.Error;
-- local CheckErr = ProtoMgr.CheckErr

M.LimitLv = 1000
M.PlayerLimit = 3
M.eUpdateInviteInfo = Event()
M.eUpdateTempData = Event()
M.eUpdateApplyInfo = Event()
M.eUpdateMatchTeamList = Event()
M.eUpdateMatchStatus = Event()
M.eUpdateCaptID = Event()
M.eUpdateJoinCopyTeamReady = Event()
M.eRefuseJoinCopy = Event()
M.eCreateTeamSuccess = Event()
M.eRespInviteSuccess = Event()

M.eIsMatching = Event()

M.eLeaveTeam = Event()

M.eUpdateMatchTeam = Event()

M.eRefuseoinTeam = Event()
M.eUpdateBuff = Event()

--记录当前选择的装备副本ID
M.CurCopyId = nil

function M:Init()
	--指定副本队伍列表
	self.CopyTeamList = {}
	--队伍信息
	self.TeamInfo = {}
	--队伍成员信息
	self.TeamInfo.Player = {}
	---邀请信息
	self.InviteInfo = {}
	--申请列表
	self.ApplyInfo = {}
	--进入副本准备
	self.EnterCopy = {}
	self.EnterCopy.Readys = {}
	--是否匹配
	self.IsMatching = false
	self.MatchCopyId = nil
	self:AddProto()
end

function M:AddProto()
	self.OnChangeLevel = EventHandler(self.UpdateLevel, self)
	self:ProtoHandler(ProtoLsnr.Add)
	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")
	EventMgr.Add("OnReName",EventHandler(self.UpdateName,self))
end

function M:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
	EventMgr.Remove("OnReName",EventHandler(self.UpdateName,self))
end

function M:UpdateEvent(M)	
	M("OnChangeLv", self.OnChangeLevel)
end

function M:SetEvent(fn)
	SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent, self.OnChangeEndEvent, self)
end

function M:ProtoHandler(Lsnr)
	Lsnr(20502, self.RespCreateTeam, self)	
	Lsnr(20512, self.RespInviteTeam, self)	
	Lsnr(20514, self.RespInviteReplyTeam, self)	
	Lsnr(20522, self.RespApplyTeam, self)	
	Lsnr(20532, self.RespApplyReplyTeam, self)	
	Lsnr(20542, self.RespLeaveTeam, self)	
	Lsnr(20552, self.RespTeamKick, self)	
	Lsnr(20562, self.RespTeamCaptain, self)	
	Lsnr(20600, self.RespInitTeamInfo, self)	
	Lsnr(20602, self.RespUpdateTeamInfo, self)	
	Lsnr(20652, self.RespGetTeamList, self)	
	Lsnr(20654, self.RespSetCopyTeam, self)
	Lsnr(20662, self.RespStartCopyTeam, self)
	Lsnr(20664, self.RespJoinCopyTeamReady, self)
	Lsnr(20666, self.RespTeamCopyStop, self)
	Lsnr(20672, self.RespTeamMatch, self)
	Lsnr(20674, self.RespRecruit, self)
end

--创建队伍返回
function M:RespCreateTeam(msg)
	if not self:CheckErr(msg.err_code) then return end
	--UIMgr.Open(UIMyTeam.Name)
	self:ClearInviteInfo()
	self.eCreateTeamSuccess()
end

--邀请加入队伍返回
function M:RespInviteTeam(msg)
	local err = msg.err_code
	if not self:CheckErr(err) then return end
	self.eRespInviteSuccess(msg.invited_role_id)
	local info = msg.invite_role
	local id = info.role_id
	if id == User.MapData.UIDStr then return end
	if self.TeamInfo.TeamId then return end
	if self:CheckInfo(self.InviteInfo, id) ~= nil then return end
	local data = {}
	data.TeamId =  msg.team_id
	data.ID = id
	data.Name = info.role_name
	data.Lv = info.role_level
	data.Career = info.category
	data.Sex = info.sex
	table.insert(self.InviteInfo, data)
	self.eUpdateInviteInfo()
end

--处理邀请加入队伍返回
function M:RespInviteReplyTeam(msg)
	local err = msg.err_code
	if not self:CheckErr(err) then return end
	local t = msg.op_type
	local id = msg.invite_role_id
	if id == User.MapData.UIDStr then 
		self:RemoveInfo(self.InviteInfo, id)
		return
	 end
	local name = msg.reply_role_name
	if t == 1 then
		UITip.Error(string.format("%s 加入队伍！！", name))
	elseif t == 2 then
		UITip.Error(string.format("%s 拒绝加入队伍！！", name))
		self.eRefuseoinTeam()
	end
end

--申请加入队伍返回
function M:RespApplyTeam(msg)
	local err = msg.err_code
	if not self:CheckErr(err) then return end
	-- self:eUpdateApplyInfo()
	local info = msg.apply_role
	local id = info.role_id
	-- if id == User.MapData.UIDStr then return end
	if self:CheckInfo(self.ApplyInfo, id) ~= nil then return end
	local data = {}
	data.ID = info.role_id
	data.Name = info.role_name
	data.Lv = info.role_level
	data.Career = info.category
	data.Sex = info.sex
	if temp then return end
	table.insert(self.ApplyInfo, data)
	self:eUpdateApplyInfo()
end

--处理申请加入队伍返回
function M:RespApplyReplyTeam(msg)
	local err = msg.err_code
	if not self:CheckErr(err) then return end
	local id = msg.apply_role_id
	if id == User.MapData.UIDStr then return end
	self:RemoveInfo(self.ApplyInfo, id)
	self:eUpdateTempData()
	self:eUpdateApplyInfo()
end

--离开队伍返回
function M:RespLeaveTeam(msg)
	if not self:CheckErr(msg.err_code) then return end
	if not self.TeamInfo.Player then self.TeamInfo.Player = {} end
	local len = #self.TeamInfo.Player
	while len > 0 do
		self.TeamInfo.Player[len] = nil
		table.remove(self.TeamInfo.Player, len)
		len = #self.TeamInfo.Player
	end
	for k,v in pairs(self.TeamInfo) do
		self.TeamInfo[k] = nil
	end
	TableTool.ClearDic(self.TeamInfo.Player)
	TableTool.ClearDic(self.TeamInfo)
	self.IsMatching = false
	self:ClearApplyInfo()
	self.eUpdateTempData()
	self.eLeaveTeam()
end

--踢除队员返回
function M:RespTeamKick(msg)
	if not self:CheckErr(msg.err_code) then return end
end

--提升队长返回
function M:RespTeamCaptain(msg)
	if not self:CheckErr(msg.err_code) then return end
	self.TeamInfo.CaptId = msg.captain_id
	if tostring(self.TeamInfo.CaptId) ~= User.MapData.UIDStr then
		self:ClearApplyInfo()
	end
	self.eUpdateCaptID()
end

--队伍信息，上线推送返回
function M:RespInitTeamInfo(msg)
	local info = msg.team_info
	if not info then
		iTrace.eError("hs","队伍信息，上线推送team_info为空")
		return
	end
	local teamInfo = self.TeamInfo
	if teamInfo then
		teamInfo.TeamId = info.team_id
		teamInfo.CopyId = info.copy_id
		teamInfo.MinLv = info.min_level
		teamInfo.MaxLv = info.max_level
		-- teamInfo.IsMatch = info.is_matching
		teamInfo.CaptId = info.captain_role_id
	end
	local list = info.role_list
	local len = #list
	for i=1,len do
		local data = list[i]
		local id = data.role_id
		local name = data.role_name
		local lv = data.role_level
		local career = data.category
		local sex = data.sex
		local isOnline = data.is_online
		local mapId = data.map_id
		local skinList = data.skin_list
		self:UpdateTeamRoleInfo(id, name, lv, career, sex, isOnline,mapId,skinList)
	end
	if teamInfo.TeamId then
		self:ClearInviteInfo()
	end
	self.eUpdateTempData()
end

--组队成员加入、更新、退出返回
function M:RespUpdateTeamInfo(msg)
	local del = msg.del_role_id
	local info = msg.role
	if del and del ~= 0 then
		self:DelTeamRoleInfo(del)
	end
	if info then
		local id = info.role_id
		if id ~= 0 and id ~= del then
			local name = info.role_name
			local lv = info.role_level
			local career = info.category
			local sex = info.sex
			local isOnline = info.is_online
			local mapId = info.map_id
			local skinList = info.skin_list
			self:UpdateTeamRoleInfo(id, name, lv, career, sex, isOnline,mapId,skinList)
			self:RemoveInfo(self.ApplyInfo, id)
		end
	end
	self.eUpdateTempData()
end

--获取某个分类的队伍信息返回
function M:RespGetTeamList(msg)
	local list = msg.copy_teams
	if not list then
		iTrace.eError("hs","获取某个分类的队伍信息copy_teams为空")
		return
	end
	local id = 0
	local myInfo = self.TeamInfo
	if myInfo then id = myInfo.TeamId end
	local len = #list
	self:ChearCopyTeamList()
	for i=1,len do
		local info = list[i]
		if id ~= info.team_id then
			local data = self:UpdateCopyTeamList(info.team_id, info.min_level, info.max_level, info.team_roles,info.captain_role_id)
			if data then
				table.insert(self.CopyTeamList, data)
			end
		end
	end
	table.sort(self.CopyTeamList,function(a,b) return a.TeamId > b.TeamId end)
	self.eUpdateMatchTeamList()
end

--设置副本信息返回
function M:RespSetCopyTeam(msg)
	if not self:CheckErr(msg.err_code) then return end
	if self.TeamInfo then
		self.TeamInfo.CopyId = msg.copy_id
		self.TeamInfo.MinLv = msg.min_level
		self.TeamInfo.MaxLv = msg.max_level
	end
	self.eUpdateTempData()
end

--进入副本队伍准备确认返回
function M:RespStartCopyTeam(msg)
	if not self:CheckErr(msg.err_code) then return end
	local data = self.EnterCopy 
	if data then
		data.CopyId = msg.enter_copy_id
	end
	UIMgr.Close(UIMyTeam.Name)
	UIMgr.Open(UITeamActive.Name,self.OnShowEnterCopy, self)
end

--进入副本队伍准备返回
function M:RespJoinCopyTeamReady(msg)
	if not self:CheckErr(msg.err_code) then return end
	local id = msg.role_id
	if id == 0 then 
		return 
	end
	if not self.EnterCopy.Readys then self.EnterCopy.Readys = {} end
	local dic = self.EnterCopy.Readys
	local info = {}
	info.ID = id
	info.Ready = true
	local index = self:CheckInfo(self.EnterCopy.Readys, id)
	if not index then
		table.insert(self.EnterCopy.Readys, info)
	else
		self.EnterCopy[index] = info
	end
	self:IsCanGetLoveRw()
	self.eUpdateJoinCopyTeamReady()
end

function M:IsCanGetLoveRw()
	local copyId = self.EnterCopy.CopyId
	-- iTrace.eError("GS","enterCopyId===",copyId)
	if copyId then
		copyId = tostring(copyId)
		local copyCfg = CopyTemp[copyId]
		local copyType = copyCfg.type
		if copyType == CopyType.Loves then
			local data = CopyMgr.Copy[CopyMgr.Loves]
			local total = data.Buy + data.itemAdd + copyCfg.num
			local haveNum = total - data.Num
			if haveNum > 0 then
				CopyMgr:SetHaveRwdIndex(0)
			else
				CopyMgr:SetHaveRwdIndex(1)
			end
		end
	end
end

--队长开启时，有队员不满足条件
function M:RespTeamCopyStop(msg)
	local t = msg.type
	local id = msg.role_id
	if not self.TeamInfo.Player then self.TeamInfo.Player = {} end
	if not self.EnterCopy.Readys then self.EnterCopy.Readys = {} end
	local list = self.TeamInfo.Player
	if not list then return end
	if t == 8 then
		local str = "本次准备超时,请重新发起！"
		MsgBox.ShowYes(str,nil,nil,nil)
		return
	end
	if id == 0 then return end
	local len = #list
	for i=1,len do
		local info = list[i]
		if info and info.ID == id then
			local name = info.Name
			if not StrTool.IsNullOrEmpty(name) then
				if t == 1 then
					UITip.Error(string.format("玩家【%s】等级没有达到进入副本条件",name))
				elseif t == 2 then
					UITip.Error(string.format("玩家【%s】该副本难度未开启",name))
				elseif t == 3 then
					UITip.Error(string.format("玩家【%s】正在副本中",name))
				elseif t == 4 then
					UITip.Error(string.format("玩家【%s】离线中",name))
				elseif t == 5 then
					UITip.Error(string.format("玩家【%s】拒绝进入副本",name))
					local key = tostring(key)
					local dic = self.EnterCopy.Readys
					local info = {}
					info.ID = id
					info.Ready = true
					local index = self:CheckInfo(self.EnterCopy, id)
					if not index then
						table.insert(self.EnterCopy, info)
					else
						self.EnterCopy[index] = info
					end
					self.eRefuseJoinCopy()
				elseif t == 6 then
					UITip.Error(string.format("玩家【%s】副本次数不足",name))
				end
				return
			end
		end
	end
end

--匹配队伍返回
function M:RespTeamMatch(msg)
	if not self:CheckErr(msg.err_code) then return end
	self.IsMatching = msg.is_matching
	self.MatchCopyId =  msg.copy_id
	if not self.IsMatching then
		if self.TeamInfo then
			self.TeamInfo.CopyId = nil
			self.TeamInfo.MinLv = nil
			self.TeamInfo.MaxLv = nil
		end
	end
	self.eUpdateMatchStatus()
	self.eUpdateMatchTeam()
end

--index:0 其他地图
--index：1 藏宝地图
function M:ReqRecruit(index)
	local msg = ProtoPool.GetByID(20673)
	msg.sub_type = index
	ProtoMgr.Send(msg)
end

--队伍招募返回
function M:RespRecruit(msg)
	local err = msg.err_code
	if err==0 then
		local name=msg.role_info.role_name
		local mapId=msg.map_id
		local minLv = msg.min_level
		local maxLv=msg.max_level
		local teamId=msg.team_id
		local index = msg.sub_type
		ChatMgr.SetTeam(name,mapId,minLv,maxLv,teamId,index)
	else
		UITip.Log(GetError(err))
	end
end

--现在改为进入副本的逻辑
function M:MatchTeamCondition(copyId)
	local info = self.TeamInfo
	if not info then return end
	self.copyId = copyId
	local list = info.Player
	if list == nil or #list == nil then
		return
	end
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
	end
	if len >= 3 then
		if self.copyId == 0 then
			UITip.Error("请选择副本")
			return
		end
	end
	self:ReqStartCopyTeam(self.copyId)
end

function M:ContinueCb()
	if M.copyId then
		if M.copyId == 0 then
			UITip.Error("请选择副本")
			return
		end
		self:ReqStartCopyTeam(M.copyId)
	end
end

--[[######################proto start##########################]]--

--创建队伍
function M:ReqCreateTeam()
	local msg = ProtoPool.GetByID(20501)
	Send(msg)
end

--邀请加入队伍
function M:ReqInviteTeam(id)
	local msg = ProtoPool.GetByID(20511)
	msg.role_id = id
	Send(msg)
end

--处理邀请加入队伍 1为同意加入 2为拒绝加入
function M:ReqInviteReplyTeam(t, teamid, id)
	local msg = ProtoPool.GetByID(20513)
	msg.op_type = t
	msg.team_id = teamid
	msg.role_id = id
	Send(msg)
end

--申请加入队伍
function M:ReqTeamApply(teamid, id)
	local msg = ProtoPool.GetByID(20521)
	msg.team_id = teamid
	msg.role_id = id
	Send(msg)
end

--处理申请加入队伍 1同意加入 2为拒绝加入
function M:ReqTeamApplyReply(t, id)
	self:RemoveInfo(self.ApplyInfo, id)
	local msg = ProtoPool.GetByID(20531)
	msg.op_type = t
	msg.role_id = id
	Send(msg)
end

--离开队伍
function M:ReqLeave()
	local msg = ProtoPool.GetByID(20541)
	Send(msg)
end

--踢出队员
function M:ReqTeamKick(id)
	local msg = ProtoPool.GetByID(20551)
	msg.role_id = id
	Send(msg)
end

--提升队长
function M:ReqTeamSetCaptain(id)
	local msg = ProtoPool.GetByID(20561)
	msg.role_id = id
	Send(msg)
end

--获取某个分类的队伍信息
function M:GetCopyTeamList(id)
	local msg = ProtoPool.GetByID(20651)
	msg.copy_id = id
	Send(msg)
end

--设置副本相关信息
function M:ReqSetCopyTeam(id, min, max)
	local msg = ProtoPool.GetByID(20653)
	msg.copy_id = id
	msg.min_level = min
	msg.max_level = max
	Send(msg)
end

--进入副本准备确认
function M:ReqStartCopyTeam(id)
	if self.TeamInfo.CaptId and self.TeamInfo.CaptId ~= User.MapData.UIDStr then
		UITip.Log("队长才可以进入副本")
		return
	end
	local nextSceneInfo = SceneTemp[tostring(id)];
	if nextSceneInfo == nil then
		iError("LY", "Can not get scene info : ".. id);
		return;
	end

	local nextSceneResName = StrTool.Concat(nextSceneInfo.res, ".unity");
	if Loong.Game.AssetMgr.Instance:Exist(nextSceneResName) == false then
		--UITip.Log("场景资源尚未加载完成!");
		UIMgr.Open(UIDownload.Name)
		iError("LY", "Scene res is not exist : "..nextSceneResName);
		return;
	end
	local msg = ProtoPool.GetByID(20661)
	msg.enter_copy_id = id
	Send(msg)
end

--所有队员准备 or 拒
function M:ReqJoinCopyTeamReady(value)
	local msg = ProtoPool.GetByID(20663)
	msg.is_ready = value --true：接受 false：拒绝
	Send(msg)
end

--匹配副本
function M:ReqTeamMatch(id, match)
	local msg = ProtoPool.GetByID(20671)
	msg.copy_id = id
	msg.matching = match
	Send(msg)
end

--机器人引导匹配副本
function M:ReqTeamGuideMatch()
	local msg = ProtoPool.GetByID(20669)
	Send(msg)
end

--[[#########################proto end##########################]]--

---------------------------------------------------------------------

--更新队伍成员信息
function M:UpdatePlayerInfo(data, id, name, lv, career, sex, isOnline,mapId,skinList)
	data.ID = id
	data.Name = name
	data.Lv = lv
	data.Career = career
	data.Sex = sex
	data.IsOnline = isOnline
	data.MapId = mapId
	data.SkinList = skinList
end

--更新队友信息
function M:UpdateTeamRoleInfo(id, name, lv, career, sex, isOnline,mapId,skinList)
	if not self.TeamInfo.Player then self.TeamInfo.Player = {} end
	local list = self.TeamInfo.Player
	local i = self:CheckInfo(list, id)
	if i ~= nil then
		self:UpdatePlayerInfo(list[i], id, name, lv, career, sex, isOnline,mapId,skinList)
	else
		local data = {}
		table.insert(list, data)
		local index = #list
		self:UpdatePlayerInfo(list[index], id, name, lv, career, sex, isOnline,mapId,skinList)
	end
end

--更新获取某个分类的队伍信息
function M:UpdateCopyTeamList(teamid, min, max, players,capId)
	if teamid == nil then return nil end
	local team = {}
	team.Player = {}
	team.TeamId = teamid
	team.MinLv = min
	team.MaxLv = max
	team.CaptainId = capId
	local len = #players
	for i=1,len do
		local data = players[i]
		if data then 
			self:UpdateCopyTeamInfo(team.Player,data)
		end
	end
	return team
end

--更新副本队伍信息
function M:UpdateCopyTeamInfo(info, data)
	local player = {}
	player.ID = data.role_id
	player.Name = data.role_name
	player.Lv = data.role_level
	player.Career = data.category
	player.Sex = data.sex
	player.IsOnline = data.is_online
	player.MapId = data.map_id
	player.SkinList = data.skin_list
	table.insert(info, player)
end

--清理副本队伍列表
function M:ChearCopyTeamList()
	if self.CopyTeamList then
		for k,v in pairs(self.CopyTeamList) do
			v = nil
		end
		TableTool.ClearDic(self.CopyTeamList)
		-- TableTool.ClearDicToPool(self.CopyTeamList)
	end
end

---------------------------------------------

function M:OnShowEnterCopy(name)
	local ui = UIMgr.Dic[name]
	if ui then
		ui:OnShowEnterCopy()
	end
end

function M:OnChangeEndEvent(isLoad)
	local data = self.EnterCopy
	if data.CopyId == User.SceneId then
		TableTool.ClearDic(self.EnterCopy.Readys)
		TableTool.ClearDic(self.EnterCopy)
	end
end

function M:RemoveInviteReplyData(id)
	local info = self.InviteInfo
	if not info then return end
	self:RemoveInfo(info, id)
end

function M:RemoveApplyReplyData(id)
	local info = self.ApplyInfo
	if not info then return end
	self:RemoveInfo(info, id)
end

function M:RemoveInfo(list, id)
	local index = 0
	for i=1,#list do
		local data = list[i]
		if data and data.ID == id then
			index = i
		end
	end
	if index > 0 then
		list[index] = nil
	end
	table.remove(list, index)
end


--队员移除更新
function M:DelTeamRoleInfo(id)
	if id == User.MapData.UIDStr then return end
	local index = self:CheckInfo(self.TeamInfo.Player, id)
	if index ~= nil then
		local data = self.TeamInfo.Player[index]
		table.remove(self.TeamInfo.Player, index)
		data = nil
	end
end

--更新获取某个分类的队伍信息结束
function M:UpdateCopyTeamEnd()
	UIMgr.Open(UITeam.Name, self.OpenUITeamCb, self)
end

function M:OpenUITeamCb(name)
	local ui = UIMgr.Get(name)
	ui:UpdateTeamList()
end

function M:UpdateLevel()
	local teamInfo = self.TeamInfo
	if not teamInfo then
		iTrace.eError("hs","队伍信息 队伍信息为nil")
	end
	local list = self.TeamInfo.Player
	if not list or #list == 0 then return end
	for i,v in ipairs(list) do
		if v.ID == User.MapData.UIDStr then
			v.Lv = User.MapData.Level
		end
	end
	-- self.eUpdateTempData()
end

--玩家名字更改
function M:UpdateName(UID,name)
	local uid = tostring(UID)
	local name = name
	local teamInfo = self.TeamInfo
	if not teamInfo then
		iTrace.eError("hs","队伍信息 队伍信息为nil")
	end
	local list = self.TeamInfo.Player
	if not list or #list == 0 then return end
	for i,v in ipairs(list) do
		if v.ID == uid then
			v.Name = name
		end
	end
	self.eUpdateTempData()
end

--判断玩家是不是和自己一个队伍
--roleId:玩家Id
function M:IsSameTeam(roleId)
	local roleId = tostring(roleId)
	local teamId = self.TeamInfo.TeamId
	local list = self.TeamInfo.Player --队伍成员信息
	local isSame = false
	if teamId == nil or list == nil or #list == 0 then --自己没有队伍
		return false
	end
	for i = 1,#list do
        local info = list[i]
		local ID = tostring(info.ID)
		if roleId == ID then
			isSame = true
			break
		end
	end
	return isSame
end


function M:ClickMenuTip(str, id)
	if str == "我的队伍" then
		UIMgr.Open(UIMyTeam.Name)
	elseif str == "提升队长" then
		self:ReqTeamSetCaptain(id)
	elseif str == "移出队伍" then
		self:ReqTeamKick(id)
	elseif str == "离开队伍" then
		self:ReqLeave()
	elseif str == "同意" then
		self:ReqTeamApplyReply(1, id)
	elseif str == "拒绝" then
		self:ReqTeamApplyReply(2, id)
	end
end

--------------------------------------------
function M:CheckInfo(list, id)
	if not list then return nil end
	local len = #list
	for i=1,len do
		local info = list[i]
		if info then
			if info.ID == id then
				return i
			end
		end
	end
	return nil
end

--队伍面板邀请加入队伍
function M:InvitePutInTeam(index)
	local info = self.TeamInfo
	local list = self.TeamInfo.Player
	self.InvitePutInTeamIndex = index
	UIMgr.Close(UIMyTeam.Name)
	UIMgr.Open(UIInteractPanel.Name, self.ShowFriend, self)
end

function M:ShowFriend(name)
	local ui = UIMgr.Dic[name]
	if ui then
		ui:ShowFirend()
	end
end

function M:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Error(err)
	    return false
    end
    return true
end

--清除邀请
function M:ClearInviteInfo()
	if not self.InviteInfo then return end
	local len = #self.InviteInfo
	while len > 0 do
		local info = self.InviteInfo[len]
		table.remove(self.InviteInfo, len)
		info = nil
		len = #self.InviteInfo
	end
	TableTool.ClearDic(self.InviteInfo)
	self.eUpdateInviteInfo()
end

--清除申请
function M:ClearApplyInfo()
	if not self.ApplyInfo then return end
	local len = #self.ApplyInfo
	while len > 0 do
		local info = self.ApplyInfo[len]
		table.remove(self.ApplyInfo, len)
		info = nil
		len = #self.ApplyInfo
	end
	TableTool.ClearDic(self.ApplyInfo)
	self.eUpdateApplyInfo()
end

function M:ClearTeamInfo()
	TableTool.ClearDic(self.TeamInfo.Player)
	TableTool.ClearDic(self.TeamInfo)
	
end

function M:Clear()
	TableTool.ClearDic(self.CopyTeamList)
	TableTool.ClearDic(self.TeamInfo.Player)
	TableTool.ClearDic(self.TeamInfo)
	TableTool.ClearDic(self.ApplyInfo)
	TableTool.ClearDic(self.EnterCopy.Readys)
	TableTool.ClearDic(self.EnterCopy)
	--是否匹配
	self.IsMatching = false
	self.MatchCopyId = nil
end

function M:Dispose()
	self:RemoveProto()
end

return M
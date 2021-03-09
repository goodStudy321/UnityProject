TreasureMapMgr = {Name = "TreasureMapMgr"}
local My = TreasureMapMgr

--升级红点
My.eReceive = Event()

My.TreasureMapInfo = {}
My.TreasureDataInfo = {}

My.usePropId = 0 --使用道具id

My.isTreasureTeam = false --是否为藏宝图队伍状态
My.isTreasureCollec = false -- 是否正在挖宝
My.isTreasureProp = false --判段背包是否有道具，有，提示继续挖宝
My.isTreasureOpen = false -- 判断传送门是否开启  用来判断组队开启和退出队伍按钮状态
My.isTreasureUse = false  --判断宝藏道具是否已经开启过
My.enterSceneId = 0 --记录进入场景的id
My.isShowMainUIIcon = false --主界面藏宝图标显示
My.isPathing = false --是否寻路中
My.curSceneId = 0 --记录当前场景的id
My.curProtalId = 0 --记录当前场景的传送门id
My.curPropInfo = nil --当前传送门信息
My.propEventId = 0
--初始化
function My:Init()
	self:ProtoHandler(ProtoLsnr.Add)
	EventMgr.Add("OnChangeScene", EventHandler(self.OpenEnterUI, self))
	EventMgr.Add("ClickCtrlPortal",EventHandler(self.EnterPortal, self))
	PropMgr.eUpdate:Add(self.UpdateProp, self)
end

function My:Clear()
	self.isTreasureTeam = false
	self.isTreasureCollec = false
	self.isTreasureProp = false
	self.isTreasureOpen = false
	self.isTreasureUse = false
	self.isShowMainUIIcon = false
	self.isPathing = false
	self.enterSceneId = 0 
	self.curSceneId = 0
	self.curProtalId = 0
	self.usePropId = 0
	self.propEventId = 0
	self.curPropInfo = nil
	self:ProtoHandler(ProtoLsnr.Remove)
	EventMgr.Remove("ClickCtrlPortal",EventHandler(self.EnterPortal, self))
	TableTool.ClearDic(self.TreasureMapInfo)
	PropMgr.eUpdate:Remove(self.UpdateProp, self)
end

--添加事件监听
function My:ProtoHandler(Lsnr)
	Lsnr(24230, self.RespInfo,self)
	Lsnr(24228, self.RespTreaInfo,self)
end

--藏宝图状态信息推送
--boss，组队副本
function My:RespInfo(msg)
	local temp = {}
	temp.endTime = msg.end_time
	temp.propId = msg.type_id
	temp.eventId = msg.event_id
	temp.mapId = msg.map_id
	local pos = msg.pos
	local po = MapHelper.instance:GetPositon(pos)
	temp.pos = po
	self.usePropId = temp.propId
	self.TreasureDataInfo = temp
	self:CurProtalState()
	if temp.eventId == 0 then
		self:OnEndTreasure()
		self.eReceive()
		return
	end
	UITip.Log("恭喜成功开启宝藏！")
	self.enterSceneId = temp.mapId
end

--获得固定奖励
function My:RespTreaInfo(msg)
	local eventId = msg.event_id
	self.propEventId = 0
	if eventId ~= nil and eventId == 101 then
		self.propEventId = eventId
		UITip.Log("恭喜成功开启宝藏！")
		-- self:GetNewTreasure()
		self:OnEndTreasure()
		self.eReceive()
	end
end

function My:OpenEnterUI(sceneId)
	self:CurProtalState(sceneId)
	local scId = self.enterSceneId
	if scId == 0 then
		return
	end
	if sceneId == scId then
		self:GetNewTreasure()
		self.enterSceneId = 0
	end
end

function My:CurProtalState(sceneId)
	if sceneId == nil and self.curSceneId ~= 0 then
		sceneId = self.curSceneId
	end
	local endTime = self.TreasureDataInfo.endTime
	if endTime == nil then
		endTime = 0
	end
	local curTime = os.time()
	local showTime = endTime - curTime
	local isShow = (showTime > 0)
	local scId = sceneId
	for k,v in pairs(TreasureCfg) do
		local pos = v.pos
		local len = #pos
		for i = 1,len do
			local info = pos[i]
			local sId = info.sceneId
			if sId == scId then
				local protalId = info.protalId
				self.curProtalId = protalId
				self.curSceneId = sId
				if protalId == nil then
					return
				end
				local portalInfo = self:GetPortalById(protalId)
				portalInfo:SetActive(isShow)
				if showTime > 0 then
					portalInfo:StartDiscount(showTime)
				end
				self.curPropInfo = portalInfo
			end
		end
	end
end

--点击传送门
function My:EnterPortal()
	local temp = self.TreasureDataInfo
	if temp == nil or temp.eventId == nil  then
		iTrace.eError("GS","传送门信息不存在")
		return
	end
	local cfg = TreasureBaseCfg[tostring(temp.eventId)]
	if cfg == nil then
		iTrace.eError("GS","配置信息不存在")
		return
	end
	local sceneId = cfg.sceneId
	TeamMgr:MatchTeamCondition(sceneId)
end

function My:GetNewRewardTreasure()
	local eventId = self.TreasureDataInfo.eventId
end

function My:UpdateProp()
	local eventId = self.propEventId
	local propId = 0
	if eventId > 0 and eventId == 101 then
		self:GetNewTreasure()
		self.propEventId = 0
	end
end

function My:GetNewTreasure()
	local propId = 0
	for k,v in pairs(TreasureCfg) do
		local propNum = PropMgr.TypeIdByNum(v.id)
		if propNum > 0 then
			propId = v.id
			break
		end
	end
	if propId == 0 then
		return
	end
	self.usePropId = propId
	local str = "是否继续开启藏宝图？"
	MsgBox.ShowYesNo(str,self.YesCb, self, "前往开启" , self.NoCb, self, "取消")
end

function My:NewTreasure(propId)

end

function My:YesCb()
	local propId = self.usePropId
	self.isTreasureUse = false
	local treasureInfo = self:GetTreasureInfo(propId)
	local x = treasureInfo.x/100
	local y = treasureInfo.y/100
	local z = treasureInfo.z/100
	local vecPos = Vector3.New(x,y,z)
	local sceneId = treasureInfo.sceneId
	User:StartNavPath(vecPos, sceneId, -1, 0)
end

function My:NoCb()
    
end

--获取传送门
--portalId：唯一id,需在场景中配置
function My:GetPortalById(portalId)
	return MapHelper.instance:GetCtrlPortalById(portalId)
end

function My:Update()
	local endTime = self.TreasureDataInfo.endTime
	if endTime == nil or endTime == 0 then
		self.isTreasureOpen = false
		-- self.eReceive()
		return
	end
	local nowTime = os.time()
	local time = endTime - nowTime
	if Time.frameCount % 10 == 0 then
		if time <= 0 then
			self.isTreasureTeam = false
			self.isTreasureOpen = false
			self.eReceive()
			return
		end
		self.isTreasureOpen = true
		self.isTreasureTeam = true
		self.eReceive()
	end
end

--玩家队伍状态有三种
-- 1---> 为小队队长
-- 2---> 不是小队队长
-- 3---> 没有队伍
function My:UserTeamState()
    local index = 0
    local teamMgr = TeamMgr
	local teamInfo = teamMgr.TeamInfo
	local teamId = teamInfo.TeamId
	local capId = teamInfo.CaptId
	local userId = User.MapData.UIDStr
	if capId and tostring(capId) == userId then --有队伍，且玩家为队长
        index = 1
	elseif capId and tostring(capId) ~= userId then --有队伍，且玩家不为队长
		teamMgr:ReqLeave()
		teamMgr:ReqCreateTeam()
		self:SetTeamInfo()
        index = 2
	elseif capId == nil then --没有有队伍
		teamMgr:ReqCreateTeam()
		self:SetTeamInfo()
        index = 3
    end
    return index
end

function My:SetTeamInfo()
	local data = GlobalTemp["60"]
	local minLv = data.Value2[1]
	local maxLv = data.Value2[2]
	local copyId = data.Value3
	TeamMgr:ReqSetCopyTeam(copyId,minLv,maxLv)
end

--获取藏宝图信息
function My:GetTreasureInfo(propId)
	self.isPathing = true
	EventMgr.Add("NavPathComplete",EventHandler(self.NavComplete, self))
	TableTool.ClearDic(self.TreasureMapInfo)
	local userLv = User.MapData.Level
	local cfg = TreasureCfg[tostring(propId)]
	local posTab = cfg.pos
	local len = #posTab
	for i = 1,len do
		local temp = {}
		local info = posTab[i]
		local minLv = info.minLv
		local maxLv = info.maxLv
		if userLv >= minLv and userLv <= maxLv then
			temp.x = info.x
			temp.y = info.y
			temp.z = info.z
			temp.sceneId = info.sceneId
			table.insert(self.TreasureMapInfo,temp)
		end
	end
	local infoLen = #self.TreasureMapInfo
	local index = math.random(1,infoLen)
	local data = self.TreasureMapInfo[index]
	return self.TreasureMapInfo[index]
end

function My:NavComplete(t, missid)
	if t ~= PathRType.PRT_PATH_SUC then return end
	EventMgr.Remove("NavPathComplete",EventHandler(self.NavComplete, self))
	self.isPathing = false
	self:OpenUI()
end

--主界面点击藏宝图
function My:MainNavStart()
	EventMgr.Add("NavPathComplete",EventHandler(self.MainComplete, self))
end

function My:MainComplete(t, missid)
	if t ~= PathRType.PRT_PATH_SUC then return end
	EventMgr.Remove("NavPathComplete",EventHandler(self.MainComplete, self))
	self:EnterPortal()
end

--teamState:
-- 1---> 为小队队长
-- 2---> 不是小队队长
-- 3---> 没有队伍
function My:OpenUI()
	local teamState = self:UserTeamState()
	if teamState == 1 then
		TreasureRewardBox.OpenTreasure()
	else
		UIMgr.Open(UIMyTeam.Name)
	end
end

--开始挖宝数据
function My:OnStartDig()
	self.isTreasureCollec = true
	CollectMgr.state = CollectState.Running
    CollectMgr.dur = 2
end

--挖宝UI结束
function My:OnEndDig()
	self.isTreasureCollec = false
	CollectMgr.state = CollectState.None
	CollectMgr.dur = 0
	self.isTreasureUse = true
end

--奇遇结束
function My:OnEndTreasure()
	self.isTreasureTeam = false
	self.isTreasureUse = true
end

function My:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Log(err)
	    return true
    end
    return false
end

return My

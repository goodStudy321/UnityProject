--region FaeriesMgr.lua
--Date
--此文件由[HS]创建生成

EscortMgr = {Name="EscortMgr"}
local M = EscortMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

M.eInit = Event()
M.eReceive = Event()
M.eComplete = Event()

M.OpenLv = 130
M.Ring = 3
M.MissID = 900000

function M:Init()
	self.IsOpenReward = false
	self.Num = 0
	self.FairyID = 1
	self.Reward = 1
	self.MissionTemp = MissionTemp[tostring(self.MissID)]
	self.DoubleTime = self:GetDoubleTimer()
	self.Lab = nil
	self.IsCountDown = false
	self.TimerTool = ObjPool.Get(iTimer)
	self.TimerTool.invlCb:Add(self.InvCountDown, self)
    self.TimerTool.complete:Add(self.EndCountDown, self)
	self:AddEvent()
end

function M:GetDoubleTimer()
	local temp = XsActiveCfg["1012"]
	if temp then
		local list = temp.timeStr 
		if list then
			local timeList = {}
			local len = #list
			for i=1,len do
				local str = list[i]
				if not StrTool.IsNullOrEmpty(str) then
					local data = {}
					data.des = str
					local strs = StrTool.Split(str, "-")
					if strs then
						data.st = self:GetSec(strs[1])
						data.et = self:GetSec(strs[2])
					end
					table.insert(timeList, data)
				end
			end
			return timeList
		end
	end
	return nil
end

function M:GetSec(str)
	local strs = StrTool.Split(str, ":")
	if StrTool.IsNullOrEmpty(strs) then return 0 end
	local h = tonumber(strs[1]) * 3600
	local m = tonumber(strs[2]) * 60
	local s =tonumber(strs[3])
	return h + m + s
end

--倒计时间隔回调
function M:InvCountDown()
	local lab = self.Lab
	if lab then 
		local s = nil
		local timer = self.TimerTool
		if timer then s = timer.seconds - timer.cnt end
		if s then
			lab.text = DateTool.FmtSec(s, 3, 2)
		end
	end
end

--倒计时结束回调
function M:EndCountDown()
	self:InvCountDown()
	self:ClearTimer()
end

function M:AddEvent()
	self.OnInitOwner = EventHandler(self.InitOwner, self)
	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")
	self:ProtoHandler(ProtoLsnr.Add)
    euiclose:Add(self.CloseUI,self);
end

function M:RemoveEvent()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
	self:ProtoHandler(ProtoLsnr.Remove)
    euiclose:Remove(self.CloseUI,self);
end

function M:UpdateEvent(M)	
	M("InitOwner", self.OnInitOwner)
end

function M:SetEvent(fn)
	MissionMgr.eEndEscortMission[fn](MissionMgr.eEndEscortMission, self.UpdateMission, self)
	SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent, self.ChangeEndEvent, self)
end

function M:ProtoHandler(Lsnr)
	Lsnr(26000, self.RespFairyInfoToc, self)	
	Lsnr(26002, self.RespFairyGetTaskToc, self)	
	Lsnr(26004, self.RespFairyFinishToc, self)	
end
-----------------------------------------------------
--返回护送仙灵信息
function M:RespFairyInfoToc(msg)
	self.Num = msg.times
	self.FairyID = msg.fairy_id
	local value = self:IsExecute()
	User.IsEscort = value
	if value == true then
		self:CreateModel()
	end
	self.eInit()
end

--领取护送仙灵任务
function M:RespFairyGetTaskToc(msg)
	if not CheckErr(msg.err_code) then 
		self.FairyID = 1
		return 
	end
	self.Num = msg.times
	self:CreateModel()
	User.IsEscort = true
	self.eReceive()
end

--完成
function M:RespFairyFinishToc(msg)
	if not CheckErr(msg.err_code) then return end
	self.Reward = self.FairyID
	self.FairyID = 1
	self:ShowUIGetRewardPanel()
	self:UnloadMode()
	User.IsEscort = false
	self.eComplete()
end
------------------------------------------------------
--领取护送仙灵任务
function M:ReqFairyGetTaskTos(id)
	self.FairyID = id
	local msg = ProtoPool.GetByID(26001)
	msg.fairy_id = id
	Send(msg)
end

--完成护送仙灵任务
function M:ReqFairyFinishTos()
	local msg = ProtoPool.GetByID(26003)
	Send(msg)
end
------------------------------------------------------

function M:UpdateMission()
	local mission = MissionMgr.Escort
	if mission then
		MissionMgr:AutoExecuteActionOfType(MissionType.Escort)
	end
end

function M:ChangeEndEvent()
	local value = self:IsExecute()
	if value == true then
		self:CreateModel()
	end
end

function M:IsDoubleTime(st, et)
	local cur = TimeTool.GetTodaySecond()
	if cur < st then return -1 end
	if cur > et then return 1 end
	return 0
end

function M:GetDoubleTime()
	local list = self.DoubleTime
	local value = "无"
	local is = -1
	if list then
		for i=1,#list do
			local time = list[i]
			if time then
				local st = DateTool.FmtSec(time.st, 3, 2)
				local et = DateTool.FmtSec(time.et, 3, 2)
				if StrTool.IsNullOrEmpty(st) == false and StrTool.IsNullOrEmpty(et) == false then
					st = string.sub(st, 0 ,5)
					et = string.sub(et, 0 ,5)
				end
				local v = string.format("%s-%s", st, et)
				local cleck = self:IsDoubleTime(time.st, time.et)
				if cleck ~= 1 then
					return v, cleck
				elseif cleck == 1 and i == 1 then					
					value = v
					is = cleck
				end
			end
		end
	end
	return value, is
end

function M:GetDoubleCountDown()
	local list = self.DoubleTime
	local value = "无"
	local is = -1
	if list then
		for i=1,#list do
			local time = list[i]
			if time then
				local st = time.st
				local et = time.et
				local cleck = self:IsDoubleTime(st, et)
				if cleck == 0 then
					local cur = TimeTool.GetTodaySecond()
					local offset = et - st
					return offset - (cur - st)
				end
			end
		end
	end
	return 0
end

function M:GetDoubleCountDownTest()
	local data = LivenessInfo:GetActInfoById(1012)
	local t = 0
	if data then
		t = (data.eTime - TimeTool.GetServerTimeNow()/ 1000)
		if t < 0 then t = 0 end
	end
	return t
end

function M:ShowUIGetRewardPanel()
	if self.IsOpenReward == true then return end
	if self.Reward and self.Reward <= 1 then return end
	UIMgr.Open(UIGetRewardPanel_II.Name, self.OpenGetRewardComplete, self)
	self.IsOpenReward = true
end

function M:OpenGetRewardComplete(name)
	local ui = UIMgr.Dic[UIGetRewardPanel_II.Name]
	if ui then
		local isDouble = false
		local data = LivenessInfo:GetActInfoById(1012)
		if data then 
			isDouble = data.val == 1
		end
		local list = {}
		local temp = EscortTemp[tostring(self.Reward)]
		if not temp then return end
		local copper = temp.r_copper
		if isDouble == true then copper = copper * 2 end
		if copper and copper > 0 then
			local data = {}
			data.k = 1
			data.v = copper
			data.b = false
			table.insert( list, data)
		end
		local lv = User.MapData.Level
		local lvTemp = LvCfg[tostring(lv)]
		if lvTemp then
			local exp = Mathf.Floor(lvTemp.exp * (temp.expRatio / 10000))
			if isDouble == true then exp = exp * 2 end
			if exp > 0 then
				local data = {}
				data.k = 100
				data.v = exp
				data.b = false
				table.insert(list, data)
			end
		end
		ui:UpdateData(list, UIGetRewardPanel_II.Escort)
	end
	self.Reward = self.FairyID
end

function M:OpenUI()
	UIMgr.Open(UIEscort.Name, self.OpenUIComplete, self)
end

function M:OpenUIComplete(name)
	local ui = UIMgr.Dic[UIEscort.Name]
end

function M:CloseUI(name)
	if name ~= UIGetRewardPanel_II.Name then return end
	self.IsOpenReward = false
end

--正在执行
function M:IsExecute()
	if self.FairyID and self.FairyID > 1 then
		return true
	end
	return false
end

function M:CreateModel()
	local temp = EscortTemp[tostring(self.FairyID)]
	if not temp then return end
	local role = RoleBaseTemp[tostring(temp.mod)]
	if not role then return end
	if StrTool.IsNullOrEmpty(role.path) then return end
	self:UnloadMode()
	self.ModName = role.path
	local del = ObjPool.Get(DelGbj)
	del:Add(role)
	del:SetFunc(self.LoadModCb,self)
	Loong.Game.AssetMgr.LoadPrefab(role.path, GbjHandler(del.Execute,del))
end

function M:LoadModCb(go, temp)
	self.Model = go
	local target = User.Pos
	local trans = go.transform
	trans.eulerAngles = Vector3.zero
	trans.position = Vector3.New(target.x, target.y ,target.z - 5)
	trans.localScale = Vector3.one
	self.Model.name = temp.path
	LayerTool.Set(trans, 12)
	local uf = go:AddComponent(typeof(UnitFollow))
	uf.mDeltaY = 1.5
	uf:UpdateTitle(temp.name)
end

function M:UnloadMode()
	if self.Model then
		Destroy(self.Model)
		if not StrTool.IsNullOrEmpty(self.ModName) then
			AssetMgr:Unload(self.ModName,".prefab", false)
		end
	end
	self.Model = nil
	self.ModName = nil
end

function M:SetTimeLab(lab)
	if not lab then 
		if self.TimerTool then
			self.TimerTool:Stop()
		end
		self.Lab = nil
		return 
	end
	local s = self:GetDoubleCountDownTest()
	lab.gameObject:SetActive(s > 0)
	lab.text = DateTool.FmtSec(s, 3, 2)
	self.Lab = lab
	if self.TimerTool then
		self.TimerTool.cnt = 0
		self.TimerTool.seconds = s
		if self.IsCountDown == true then return end
		self.IsCountDown = false
		self.TimerTool:Start()
	end
end

function M:IsRelatedNpc(npcid)
	local temp = self.MissionTemp
	if not temp then return false end
	if temp.npcReceive == npcid then
		self:OpenUI() 
		return true
	end
	if temp.npcSubmit == npcid then
		self:NavEscort(true)
		return true
	end
	return false
end

function M:NavEscort(value)
	if not SceneMgr:IsChangeScene() then 
		return 
	end
	if not value and value ~= false then value = true end
	local mission = MissionMgr.Escort
	if mission then
		MissionMgr:AutoExecuteActionOfType(MissionType.Escort)
	else	
		if value == true then
			local amgr = ActivityMgr
			if not amgr:CheckLv(amgr.XLHS) then
				UITip.Error("等级不足，功能未开启")
				return
			end
			if self.Num > 0 then
				MsgBox.ShowYesNo(string.format("还有%s次护送机会，是否前往进行护送？",self.Num),self.OKBtn,self,nil, nil ,self, nil, 5)
			else
				UITip.Error("今天的护送次数已经用完了")
			end
		end
	end
end

function M:OKBtn()
	local temp = MissionTemp[tostring(self.MissID)]
	if temp then
		local id = temp.npcReceive
		MissionNavPath.Callback = function()
		 self:OpenUI() 
		end

		local vip = VIPMgr.GetVIPLv() > 0
		local item = PropMgr.TypeIdByNum(31015) > 0
		local t = false
		if vip == true or item == true then
			t = true
		end
		User:StopNavPath()
		MissionMgr.CurExecuteType = MissionType.Escort
		EventMgr.Add("NavPathComplete",EventHandler(self.NavComplete, self))
		MissionNavPath:NPCPathfinding(self.MissID, id, 1.3, t, 0)
	end
end

function M:NavComplete(t, missid)
	if self.MissID ~= missid then return end
	if t ~= PathRType.PRT_PATH_SUC then return end
	EventMgr.Remove("NavPathComplete",EventHandler(self.NavComplete, self))
	self:OpenUI()
end

function M:UpdateMissionStatus()
	local mission = MissionMgr.Escort
	if mission then
		MissionMgr:UpdateMissionStatus(mission.ID, MStatus.ALLOW_SUBMIT)
		Hangup:MissionUpdate(mission.ID, MStatus.ALLOW_SUBMIT)
		MissionMgr:AutoExecuteAction(false)
	end
end

function M:Update()
end

function M:ClearTimer()
	if self.TimerTool then 
		self.TimerTool:Stop()
	end
	self.IsCountDown = false
end

function M:Clear()
	self.IsOpenReward = false
	self.Num = 0
	self.FairyID = 1
	self.Reward = 1
	self:UnloadMode()
	self:ClearTimer()
end

function M:Dispose()
	self:Clear()
	self:RemoveEvent()
end

return M
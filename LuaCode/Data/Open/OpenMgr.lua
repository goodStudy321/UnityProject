--region OpenMgr.lua
--Date
--此文件由[HS]创建生成

OpenMgr = {Name="OpenMgr"}
local M = OpenMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

--开启事件
M.eOpen=Event()
M.eOpenActivity = Event()
M.eOpenNow = Event()
M.eFlyEnd = Event()

--开启系统效果结束事件
M.eOpenFxComplete = Event()

M.eShowSysEff = Event()					--头像系统
M.eShowActEff = Event()					--按钮系统
M.eShowSkillEff = Event()				--技能系统

M.ZBQH = 11 --装备强化
M.TTT = 21	--通天塔
M.FWXB = 23 --符文的开启ID
M.FWHC = 22 --符文合成
M.XM = 31 --道庭
M.ZBXL = 15 --装备洗练
M.TJ = 59

M.FlyIconPause = "OpenFlyIcon"

local OperationType={
    IsOnLine = 0,     --上线推送
    IsUpdate = 1,     --更新推送
}
local OpenType={
    System = 1,     --系统开启
    Skill = 2,      --技能开启
	Passive = 3 	--被动技能
}
function M:Init()
	self.IsOpenSystem = {}
	self.OpenList = {}
	self.OperationList = {}
	self:AddProto()
	self:AddLsnr()
end

function M:AddLsnr()
	EventMgr.Add("FlyFinish", EventHandler(self.FlyFinish,self))
end

function M:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:ProtoHandler(Lsnr)
	Lsnr(22430, self.RespFunctionListToc, self)	
end
------------------------------------------------------------------------------------
--邀请加入队伍返回
function M:RespFunctionListToc(msg)
	local isUpdate = msg.op_type	--0：上线推送 1：更新推送
	local list = msg.id_list
	local len = #list
	for i=1,len do
		local id = list[i]
		self:OpenSystem(id, isUpdate)
	end
	self:OpenSystemEnd(isUpdate)
	self.eOpenNow(isUpdate, list)
end
--------------------------------------------------------------------------------------

function M:OpenSystem(id, t)
	local key = tostring(id)
	if self.OpenList[key] then return end
	local temp = SystemOpenTemp[key]
	if not temp then return end
	if t == OperationType.IsUpdate and self.IsOpenSystem[key] == nil then 
		self.OpenList[key] = temp
	end
	self.IsOpenSystem[key] = temp
	if id == self.TTT then ActivityMgr:UpdateTower(2) end
	if temp.lvid then
		self.eOpenActivity(temp.lvid)
	end
	if t == OperationType.IsOnLine then
		MountGuide:ChkOpen(id);
		return
	end
	self.eOpen(id)
end

function M:OpenSystemEnd(t)
	if t == OperationType.IsOnLine then return end
	for k,v in pairs(self.OpenList) do
		self:OpenSystemAction(v)
		self.OpenList[k] = nil
	end
	TableTool.ClearDic(self.OpenList)
	self:OpenUI()
end

function M:FlyFinish(name)
	self.eOpenFxComplete(name)
end

function M:OpenSystemAction(temp)
	if temp.openType == OpenType.System then
		if temp.openAnim == 1 then
			--User:OpenSystemAnime(temp.id, temp.delay)
			self.ShowModTemp = temp
			self.ShowModData = self:GetOpenData(temp)
			if temp.sDelay and temp.sDelay > 0 then
				self:DelayOpen(temp)
			else
				self:OpenUIShowPendant()
			end
			return 
		end
	end
	local data = self:GetOpenData(temp)
	if not data then return end
	local isFirstPay = self:AcrossFirstPay(data)
	if isFirstPay == true then return end
	table.insert(self.OperationList, data)
end

--过滤首充第一次和第二次弹窗数据
--（原因：新功能开启的UI会将界面顶掉）
function M:AcrossFirstPay(data)
	local temp = data.Temp
	local openId = temp.id
	if openId == 49 or openId == 50 then
		return true
	end
	return false
end

function M:DelayOpen(temp)
	if not self.timer then
		self.timer = ObjPool.Get(iTimer)
		self.timer.complete:Add(self.OpenUIShowPendant, self)
	end
	local timer = self.timer
	timer.seconds = temp.sDelay*0.001
	timer:Start()
end

function M:OpenUIShowPendant()
	UIMgr.Open(UIShowPendant.Name, self.OpenModCb, self)
end

function M:OpenModCb(name)
	local temp = self.ShowModTemp
	local data = self.ShowModData
	if not temp then return end
	local ui = UIMgr.Get(name)
	if ui then
		ui:ShowPendantItem(temp, data)
	end
	self.ShowModTemp = nil
	self.ShowModData = nil
end

function M:OpenUI()
	local count = #self.OperationList
	if count == 0 then 
		return 
	end
	UIMgr.Open(UIOperationTip.Name, self.OpenCb, self)
end

function M:OpenCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateOperation()
	end
end

--开启技能
function M:OpenSkill(id)
	local skillLv = SkillLvTemp[id]
	if not skillLv then return end
	local data = {}
	data.ID = id
	data.Other = skillLv.index - 1
	local baseid = math.floor(id / 1000)
	local skillbase = SkillBaseTemp[tostring(baseid)] 
	if not skillbase then return end
	data.Name = skillbase.name 
	data.Icon = skillbase.icon
	if skillLv.type == 1 then
		data.flyType = 1
		data.Type = 2
	else
		data.flyType = 2
		data.Type = 3
	end
	table.insert(self.OperationList, data)
	self:OpenUI();
end


--获取开启数据
function M:GetOpenData(temp)
	local id = temp.id
	local type = temp.type
	local targetid = nil
	local data = {}
	if id < 100 or id >= 200 then 	--系統
		data.ID = temp.id
		data.Type = OpenType.System
		data.Name = temp.des
		if temp.icon then
			data.Icon = temp.icon[1]
		end
	elseif id >= 100 and id < 200 then --技能
		local list = temp.objID
		if not list then return nil end
		local sex = User.MapData.Sex
		if not sex then return nil end
		sex = sex + 1
		if #temp.objID == 1 then
			targetid = tostring(temp.objID[1])
		else
			targetid = tostring(temp.objID[sex])
		end
		local skillLv = SkillLvTemp[targetid]
		if not skillLv then return end
		data.Other = skillLv.index - 1
		local baseid = targetid / 1000
		baseid = math.floor(baseid)
		local skillbase = SkillBaseTemp[tostring(baseid)] 
		if not skillbase then return end
		data.ID = temp.targetid
		data.Type = data.openType
		data.Name = skillbase.name 
        data.Icon = skillbase.icon
	end
	data.flyType = temp.flyType
	data.Temp = temp
	if not data.Name or not data.Icon then return nil end
	return data
end

--判断系统是否开放
--return,true:开放
function M:IsOpen(k)
	if type(k) == "number" then
		k = tostring(k)
	end
	if self.OpenList[k] then return true end
	if self.IsOpenSystem[k] then return true end
	return false
end

--通过系统等级表判断是否开启
function M:IsOpenForId(lvid)
	for k,v in pairs(self.IsOpenSystem) do
		if v.lvid == lvid then
			return true
		end
	end
	for k,v in pairs(self.OpenList) do
		if v.lvid == lvid then
			return true
		end
	end
	return false
end

--通过系统等级表判断是否开启
function M:IsOpenForType(type)
	for k,v in pairs(self.IsOpenSystem) do
		local temp = ActivityTemp[tostring(v.lvid)]
		if temp then
			if temp.type == type then
				return true
			end
		end
	end
	for k,v in pairs(self.OpenList) do
		local temp = ActivityTemp[tostring(v.lvid)]
		if temp then
			if temp.type == type then
				return true
			end
		end
	end
	return false
end

--是否有开启队列
function M:IsCheckOpenList()
	local list = self.OperationList
	if not list or #list ==0 then
		return false
	end
	return true
end

--显示飘向特效
function M:ShowFlyEffect(data, go)
	if LuaTool.IsNull(go) == true then return end
	go:SetActive(false)
	local fly = data.flyType
	if fly == 1 then
		self.eShowSkillEff(data, go)
	elseif fly == 2 then
		self.eShowSysEff(data, go)
	elseif fly == 3 then
		self.eShowActEff(data, go)
	end
end

function M:IsShowEffToActivity(id)
	for k,v in pairs(SystemOpenTemp) do
		if v.lvid == id then
			if v.lvid == id and v.flyType ~= nil and StrTool.IsNullOrEmpty(v.icon) == false then
				return true
			end
		end
	end
	return false
end

function M:Clear()
	if self.timer then self.timer:Stop() end
	TableTool.ClearDic(self.IsOpenSystem)
	TableTool.ClearDic(self.OpenList)
	local list = self.OperationList
	if list then
		for i,v in ipairs(list) do
			TableTool.ClearDic(v)
			list[i] = nil
		end
	end
end

function M:Dispose()
	self:RemoveProto()
end

return M
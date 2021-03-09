--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-04-09 00:59:13
-- 推送通知管理
-- 1,每周循环周期,通知ID = (id * 10 + 星期几数字)
-- 2,每月循环周期,通知ID = (id * 100 + 第几天数字)
--=========================================================================

PushMgr = Super:New{ Name = "PushMgr" }

local My = PushMgr
local DateTime = System.DateTime


--一天的间隔/毫秒
My.dayInterval = 24 * 60 * 60 * 1000

--星期的间隔/毫秒
My.weekInterval = 7 * My.dayInterval

function My:Init()
	if App.isEditor then return end
	--CS/本地代码通知的中间类型

	if App.IsIOS() then
		CSPush = Loong.Game.iOSPush.Instance 
	else 
		CSPush = Loong.Game.AndroidPush.Instance
		CSPush:Clear()
	end
	--k:通知配置ID,v:true:开启
	self.prefDic = {}
	--true:包含
	self.weekLst = {}
	CSPush:Init()
	self:ReadPrefs()
	if self.isFirst then
		self:StartAll()
	else
		self:Restart()
	end
end

function My:StartAll()
	for i,cfg in ipairs(PushCfg) do
		if cfg.at == 1 then
			self:AddFromNow(cfg)
		end
	end
	self:Apply()
	self.isFirst = false

end

--读取用户设置的缓存数据
--数据名:PrefData,是id的列表
function My:ReadPrefs()
	local k = self.Name .. "PrefData"
	self.prefKey = k
	local str = nil
	local prefData = nil
	if PlayerPrefs.HasKey(k) then
		str = PlayerPrefs.GetString(k)
	end
	if StrTool.IsNullOrEmpty(str) then
		prefData = {}
		self.isFirst = true
	else
		prefData = json.decode(str)
	end
	if prefData then 
		for i,v in ipairs(prefData) do
			self.prefDic[v] = true
		end
	end
	self.prefData = prefData
	-- if App.IsDebug then
	-- 	iTrace.sLog("Loong",self.Name,", Read data: ",str)
	-- end
end

--重新启动
function My:Restart()
	for i,cfg in ipairs(PushCfg) do
		if cfg.at == 1 then
			local k = tostring(cfg.id)
			if self.prefDic[k] then
				self:AddFromNow(cfg)
				self:RemoveNotInCfg(cfg)
			end
		else
			self:RemoveWeeks(cfg)
		end
	end
	self:Apply()
end

--保存
--cfg(PushCfg条目)
--active:true开启,false关闭
function My:Save(cfg, active)
	if App.isEditor then return end
	if cfg == nil then return end
	local id = cfg.id
	if active == false then 
		self:Remove(cfg)
	else
		self:AddFromNow(cfg)
	end
	self:Apply()
end

function My:IsActive(id)
	if App.isEditor then return end
	local k = tostring(id)
	if self.prefDic[k] == true then return true end
	do return false end
end

function My:AddFromNow(cfg)
	local k = tostring(cfg.id)
	self.prefDic[k] = true
	self:SetWeek(cfg)
end

--设置每周开始的活动
function My:SetWeek(cfg)
	local now = 1
	local now = DateTime.Now
	local dayOfWeek = now.DayOfWeek:ToInt()
	local time = cfg.time
	local timeLen = #time
	local s = ((timeLen>2) and time[3] or 0)
	local m = ((timeLen>1) and time[2] or 0)
	local h = ((timeLen>0) and time[1] or 0)
	local cycle = cfg.cycle
	local nowTarget = DateTime.New(now.Year,now.Month,now.Day,h,m,s)
	local nowTicks = tonumber(tostring(now.Ticks))
	local nowTargetTicks = tonumber(tostring(nowTarget.Ticks))
	local difTick = (nowTargetTicks - nowTicks)/10000
	difTick = math.round(difTick)
	local ival = My.weekInterval
	local day, mills,noticeID = 0, 0,0
	for i,v in ipairs(cycle) do
		if v < dayOfWeek then
			day = (7 - dayOfWeek + v) 
		elseif(v == dayOfWeek) then
			day = ((difTick<0) and 7 or 0)
		else
			day = (v - dayOfWeek)
		end
		mills = day * My.dayInterval + difTick
		noticeID = My.GetID(cfg.id ,v)
		if App.IsDebug then
			--iTrace.sLog("Loong","SetWeek, ",noticeID,", v:",v, " ,difTick:" ,difTick ," ,day:",day,", dayOfWeek:",dayOfWeek," ,mills:",mills)
		end
		CSPush:AddFromNow(noticeID,"PhantomGame",cfg.name,cfg.text,mills,ival)
	end
end

--移除一星期内配置的引导
function My:Remove(cfg)
	local id = cfg.id
	local k = tostring(id)
	self.prefDic[k] = nil
	for i,v in ipairs(cfg.cycle) do
		local noticeID = My.GetID(id, v)
		CSPush:Remove(noticeID)
	end
end

--移除不再配置中的通知
function My:RemoveNotInCfg(cfg)
	local weekLst = self.weekLst
	for i=1,7  do
		weekLst[i] = false
	end
	for i,v in ipairs(cfg.cycle) do
		weekLst[v] = true
	end
	for i,v in ipairs(weekLst) do
		if v == false then
			local noticeID = My.GetID(cfg.id, i)
			CSPush:Remove(noticeID)
		end
	end
end

--移除一星期内所有天数的引导
function My:RemoveWeeks(cfg)
	local id = cfg.id
	local k = tostring(id)
	self.prefDic[k] = nil
	for i=1,7 do
		local noticeID = My.GetID(id, i)
		CSPush:Remove(noticeID)
	end
end

--获取通知ID
--id(number):配置ID
--dayOfWeek(number):星期几数字
function My.GetID(id,dayOfWeek)
	do return id * 10 + dayOfWeek end
end

--应用修改
function My:Apply()
	self:SaveData()
	CSPush:Save()
end

function My:SaveData()
	local prefDic = self.prefDic
	local prefData = self.prefData
	ListTool.Clear(prefData)
	for k,v in pairs(prefDic) do
		table.insert(prefData, k)
	end
	local data = json.encode(prefData)
	PlayerPrefs.SetString(self.prefKey,data)
	PlayerPrefs.Save()
	-- if App.IsDebug then
	-- 	iTrace.sLog("Loong",self.Name,", Save data: ",data)
	-- end
end


function My:Clear()
	-- body
end


function My:Dispose()

end


return My
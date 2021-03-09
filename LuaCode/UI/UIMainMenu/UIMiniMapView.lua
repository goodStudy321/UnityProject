--region UIMiniMapView.lua
--Date
--此文件由[HS]创建生成


UIMiniMapView = {}
local M = UIMiniMapView

--注册的事件回调函数

function M:New(go)
	local name = "UI主界面小地图窗口"
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.MapName = C(UILabel, trans, "Name", name, false)
	self.Pos = C(UILabel, trans, "Pos", name, false)
	self.Pos.text = ""
	self.WIFI = C(UISprite, trans, "WIFI", name, false)
	self.NetType = C(UILabel, trans, "NetType", name, false)
	self.ServerTimes = C(UILabel, trans, "ServerTimes", name, false)
	self.Electricity = {}
	for i=1,5 do
		local d = T(trans, string.format("Electricity/item%s",i))
		table.insert(self.Electricity, d)
	end

	self.IsCountDown = false
	self.ServerTimer = nil
	self.Timer = nil
	--self.OnPlayerMove = function (x, y) self:PlayMoveHandler(x, y) end
    self.OnChangeScene = function (id) self:UpdateData(id) end
	self:UpdateData()
	self:AddEvent()
	return self
end

function M:AddEvent()
	local M = EventMgr.Add
	--M("OnPlayerMove",self.OnPlayerMove)
	M("OnChangeScene", self.OnChangeScene)
	self:SetEvent("Add")
end

function M:RemoveEvent()
	local M = EventMgr.Remove
	--M("OnPlayerMove",self.OnPlayerMove)
	M("OnChangeScene", self.OnChangeScene)
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	NetObserver.eChange[fn](NetObserver.eChange, self.UpdateAndroidInfo, self)
end

function M:UpdateData()
	local temp = SceneTemp[tostring(User.SceneId)]
	if temp then
		--self.MapName.text = string.format("%s{%s}",GameSceneManager.SceneInfo.name,User.SceneId)
		self.MapName.text = string.format("%s",temp.name)
	else
		self.MapName.text = "未知地域"
	end
end

function M:UpdateName()
end

function M:PlayMoveHandler(x, y)
	--self.Pos.text = math.modf(x) .. ",".. math.modf(y)
end

function M:UpdateServerTimes()
	if self.ServerTimes then
		local s = TimeTool.GetTodaySecond()
		local txt = DateTool.FmtSec(s, 3, 2)
		txt = string.sub(txt, 0 ,5)
		self.ServerTimes.text = txt
	end
end

function M:UpdateAndroidInfo()
	local di = Device
	self:UpdateNetValue(di)
	self:UpdateeLElectricity(di)
end

function M:UpdateNetValue(di)
	local type = di.NetType
	local isWifi = false
	if type == 'wifi' then
		isWifi = true
	end
	if self.NetType then
		self.NetType.text = ((type=="unknown") and "未知" or type)
		self.NetType.gameObject:SetActive(not isWifi)
	end
	if self.WIFI then
		self.WIFI.gameObject:SetActive(isWifi)
		local lv = di.WifiRSSI --五级
		local value = 0
		local color = 1
		if lv == 5 then value = 1
		elseif lv == 4 then value = 0.706
		elseif lv == 3 then value = 0.486
		elseif lv == 2 then value = 0.302
		elseif lv == 1 then 
			value = 1
			color = 0 
		end
		self.WIFI.fillAmountValue = value
		self.WIFI.color = Color.New(color,1,1,1)
		self.WIFI:MakePixelPerfect()
	end
end

function M:UpdateeLElectricity(di)
	local lv = di.BatteryLv
	if self.Electricity then
		if lv < 0 then lv = 0 end
		lv = math.ceil((lv * 100 ) / 20)
		local l = lv + 1
		if l <= 5 then
			for i = l, 5 do
				self.Electricity[i]:SetActive(false)
			end
		end
		for i=1,lv do
			self.Electricity[i]:SetActive(true)
		end
	end
end

function M:Open()
	self:UpdateServerTimes()
	self:UpdateAndroidInfo()
	self.IsCountDown = true
	local t = os.time()
	self.ServerTimer = t
	self.Timer = t
end

function M:Close()
	self.IsCountDown = false
	self.ServerTimer = nil
	self.Timer = nil
end

function M:SetActive(value)
	if self.gameObject then
		self.gameObject:SetActive(value)
	end
end

function M:Update()
	if self.IsCountDown == true then
		if self.Timer then
			local t = os.time()
			if t - self.ServerTimer > 1 then
				self.ServerTimer = t
				self:UpdateServerTimes()
			end
			if t -  self.Timer > 60 then
				self.Timer = t
				self:UpdateAndroidInfo()
			end
		end
	end
end

function M:Dispose()
	self:Close()
	self:RemoveEvent()
end
--endregion

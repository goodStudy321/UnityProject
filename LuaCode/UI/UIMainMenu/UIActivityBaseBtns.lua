--region UIActivityBaseBtns.lua
--Date
--此文件由[HS]创建生成


UIActivityBaseBtns = Super:New{Name="UIActivityBaseBtns"}
local M = UIActivityBaseBtns

local aMgr = ActivityMgr
local sMgr = SurverMgr
local oMgr = OpenMgr
local UE = UIFly.EndDelegate


M.Type={
    None = 1,
    Move = 2
}

M.StartX = 20
M.StartY = -5

M.ItemRoot = nil
M.Items = nil
M.OpenData = nil

--注册的事件回调函数

function M:Init(parent, go)
	self.Parent = parent
	local name = "UI主界面按钮窗口"
	self.Root = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.ZoomAction = T(trans, "ActivityZoomBtn/Action")
	self:CustomInit(trans)
	
	self.TimerTool = ObjPool.Get(DateTimer)
	self.TimerTool.complete:Add(self.EndTimer, self)
	self.TimerTool.seconds = 1.2

	self.OffsetX = 87.6
	self.OffsetY = 80

	return M
end

function M:InitData() end

--增加item
function M:AddItem(temp, active, change)
	if not temp then 
		return false 
	end
	if temp.type == aMgr.TS and SkyBookMgr.IsClose == true then
		return false
	end
	local layer = temp.layer
	local check, target = self:CheckItem(layer, temp.id)
	if check == true then 
		return false
	end
	local item = self:GetItem()
	item:UpdateTemp(temp)
	local t = item.Root
	self:CustomAddItem(layer, item, change)
	t.localScale = Vector3.one
	item.GO:SetActive(active)
	--item:Play(self:IsSpecial())
	if active == false then 
		if self.OpenData then
			if type(self.OpenData) ~= "table" then
				self.OpenData:SetActive(true)
			end
		end
		self.OpenData = item.GO
	end
	self:SortItems(layer)
	return true
end

--移除item
function M:RemoveItem(temp, index)
	if temp.type == aMgr.XLHS then
		EscortMgr:SetTimeLab(nil)
	end
	self:CustomRemoveItem(temp.layer, index)
end

--检查层级数据 没有数据就创建一个新的
function M:CheckLayer(layer)
	local items = self.Items
	if not items then return end
	local k = tostring(layer)
	if not items[k] then
		items[k] = {}
	end
end

--检测已有按钮
function M:CheckItem(layer, id)
	local items = self.Items
	if not items then return false end
	for k,v1 in pairs(items) do
		for i,v in ipairs(v1) do
			if v.Temp and v.Temp.id == id then
				local od = self.OpenDatta
				if not od or od.GO.name ~= v.GO.name then
					if v.GO then v.GO:SetActive(true) end
				end
				return true, v.Root.localPosition
			end
		end
	end
	return false, nil
end

--获取按钮组
function M:GetItems(layer)
	if not self.Items then return nil, layer end
	return self.Items[tostring(layer)], layer
end

function M:CustomAddItem(layer, item, change)
	-- body
end

--从缓存获取item
function M:GetItem()
	local parent = self.Parent
	if not parent then return end
	return parent:GetItem()
end

--item压入缓存
function M:SetItem(item)
	local parent = self.Parent
	if not parent then return end
	return parent:SetItem(item)
end

function M:SortItems(layer)
	local k = tostring(layer)
	local items, tarLayer = self:GetItems(layer)
	if not items then return end
	if #items <= 1 then return end
	table.sort(items, function(a,b) return a.Temp.index < b.Temp.index end)
end

--加入系统
function M:AddSystem(temp, active, change)
	 if temp.name == "绝版守护" then
		iTrace.sLog("","")
	 end
	if not temp then return end
	if not change then change = false end
	local check, target = self:CheckItem(temp.layer, temp.id)
	if check == true then 
		return target
	end
	--增加按钮完成后 设置位移/位置
	if self:AddItem(temp, active, change) == true then
		if not temp then return end
		local items, tarLayer = self:GetItems(temp.layer)
		local value, index = false, -1
		if items then
			value,index = BinTool.FindProName(items, temp.id, "id")
		end
		if value then 
			local len = #items
			if index < len then
				for i = index + 1, len do
					local data = items[i]
					if data and data.Root and data.Temp then
						local pos = self:GetTargetPos(data.Temp.layer, i)
						data.Root.gameObject:SetActive(true)
						if not data.Temp.zoom or self:IsSpecial()==true then
							self:SetTweenPos(data.TweenPos, pos)
							data:PlayTween(self:IsDeploy())
							--[[
							if data.TweenPos then
								data.TweenPos:Play(self:IsDeploy())
							end
							]]--
						else
							data:StopTweenVector3()
							data.Root.localPosition = pos
						end
					end
				end
			end
		end
		if index > 0 then
			local data = items[index]
			if data then
				local pos = self:GetTargetPos(temp.layer, index)
				local fPos,tPos = self:SetTweenPos(data.TweenPos, pos)
				if tPos ~= nil then
					data.Root.localPosition = tPos 
				else
					data.Root.localPosition = pos
				end
				local play = self:IsDeploy()
				if self:IsSpecial() == false or tonumber(tarLayer) >= 6 then
					if data.Temp.zoom == 1 then
						play = true
					end
				end
				data:PlayTween(play)
				target = data.Root.localPosition
			end
		end
	end
	return target
end

--移除系统
function M:RemoveSystem(temp)
	if not temp then return end
	local check, target = self:CheckItem(temp.layer, temp.id)
	if check == false then return end
	local items, tarLayer = self:GetItems(temp.layer)
	local value, index = false, -1
	if items then
		value,index = BinTool.FindProName(items, temp.id, "id")
	end
	local len = #items
	self:RemoveItem(temp, index)
	if value and index < len then
		for i = index, len do
			local data = items[i]
			if data and data.Root and data.Temp then
				local pos = self:GetTargetPos(data.Temp.layer, i)
				self:SetTweenPos(data.TweenPos, pos)
				if not data.Temp.zoom then 
					data:PlayTween(self:IsDeploy())
					--[[
					if data.TweenPos then
						data.TweenPos:Play(self:IsDeploy())
					end
					]]--
				else
					data:StopTweenVector3()
					data.Root.localPosition = pos
				end
			end
		end
	end
end

--获得按钮目标位置
function M:GetTargetPos(layer, index)
	return Vector3.zero
end

--设置TweenPostion
function M:SetTweenPos(tween, pos, remove, noReset)
	local fPos, tPos = nil, nil
	if not remove then
		fPos = Vector3.New(pos.x + self.OffsetX,pos.y,pos.z)
		tPos = pos
	else
		fPos = pos
		tPos = Vector3.New(pos.x - self.OffsetX,pos.y,pos.z)
	end
	tween.old = fPos
	tween.new = tPos
	return fPos, tPos
end

----------------------------------------------------------------

--系统开启特效播放
function M:ShowActEff(temp, go)
	local root, tarPos = self:GetTarPos(temp)
	if tarPos == nil then
		iTrace.eError("hs",string.format( "按钮 %s 获取为空",temp.name))
		return
	end
	local parent = root
	if not parent then 
		Destroy(go)
		return 
	end 
	go.transform.parent = parent.transform
	go.transform.localScale=Vector3.one
	local fly = ComTool.Add(go, UIFly)
	if fly then
		local pos = go.transform.localPosition
		fly.anchors1 = Vector3.New(pos.x - 100, pos.y + 100,0)
		fly.anchors2 = Vector3.New(pos.x - 200 ,pos.y + 200,0)
		fly.targetPos = tarPos
		fly.time = 1
		fly.endDelay = 0
		fly.onEndEvent = UE(self.FlyEnd, self)
	end
	local scale = ComTool.Add(go, TweenScale)
	if scale then
		scale.from = go.transform.localScale
		scale.to = Vector3.New(0.8,0.8,0.8)
		scale.duration = 1
	end
	go:SetActive(true)
	if self.OpenData ~= nil then
		Hangup:Pause(OpenMgr.FlyIconPause)
	end
	self:CustomShowActEff(temp)
end

function M:CustomShowActEff(temp) 
	if self.Parent.Parent and self.Parent.Parent.active ~=1 then return end
	self:StartCountDown()
	-- body
end

function M:StartCountDown()
	if not self.OpenData then 
		return 
	end
	if self.IsCountDown == true then return end
	self.IsCountDown = true
	self.TimerTool:Start()
end

function M:EndTimer()
	local data = self.OpenData
	if not data then return end
	if type(data) == "table" then
		data:ShowOpenEffect()
	else
		data.gameObject:SetActive(true)
	end
	OpenMgr.eFlyEnd()
	self.OpenData = nil
	self.IsCountDown = false
	self:FlyEnd()
end

function M:FlyEnd(go)
	if Hangup:IsPause() == true then
		Hangup:Resume(OpenMgr.FlyIconPause)
		MissionMgr:Execute(false)
	end
end

function M:GetTarPos(temp)
	return nil, nil
end
--[[[缓存item]]--

--刷新按钮位置
function M:RenovatePos()
	local items = self.Items
	if not items then return end
	local value = self:IsSpecial()
	for k,v in pairs(items) do
		for i=1,#v do
			local data = v[i]
			if data then
				local pos = self:GetTargetPos(tonumber(k), i)
				data.Root.localPosition = pos
				self:SetTweenPos(data.TweenPos, pos, nil, true)
				data:Play(value)
			end
		end
	end
end

function M:CustomPlayTween(value)
	-- body
end

function M:SpecialPlayTween(value)
	-- body
end

--更新红点状态
function M:UpdateAction(type, isAdd)
	local status = false
	local items = self.Items
	if items then
		for k,v in pairs(items) do
			for i,btn in ipairs(v) do
				if btn:IsCheckType(type) == true then
					btn:UpdateActive()
					status = true
				end
			end
		end
	end
	if status == true then return end
end

function M:IsDeploy()
	if self.Parent then
		return self.Parent.IsDeploy
	end
	return false
end

function M:IsSpecial()
	if self.Parent then
		return self.Parent.IsSpecial
	end
	return false
end

function M:ItemsCount()
	return 0
end

function M:IsExist(temp)
	local key = tostring(temp.layer)
	local items = self.Items[key]
	if items then
		for i,v in ipairs(items) do
			if v.Temp.type == temp.type then
				return true
			end
		end
	end
	return false
end

function M:Open()
	self:StartCountDown()
end

function M:Close()
	self:EndTimer()
	if self.TimerTool then self.TimerTool:Stop() end
end

function M:Update()
end

function M:Clear(isReconnect)
	if self.Items then
		for k,v in pairs(self.Items) do
			local len = #v
			while len > 0 do
				local item = v[len]
				item:Reset()
				item.GO:SetActive(false)
				self:SetItem(item)
				table.remove(v, len)
				len = #v
			end
		end
	end
	self.OpenData = nil
	self.IsCountDown = false
	if self.TimerTool then self.TimerTool:Stop() end
end

function M:Dispose()
	if self.TimerTool then
		self.TimerTool:AutoToPool()
	end
	self.TimerTool = nil
end
--endregion

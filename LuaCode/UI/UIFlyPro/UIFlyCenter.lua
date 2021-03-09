--region UIFlyBottom.lua
--Date
--此文件由[HS]创建生成


UIFlyCenter = {}
local E = UIFlyCenter
local UE = UIFly.EndDelegate
E.Name = "飘属性"

E.Key = "Pro"
E.Timing = 0
E.Interval = 0.3
E.IsFly = false

E.IdleList = {}
E.FlyList = {}
--注册的事件回调函数

function E:New()
	return self
end

function E:Init(go)
	self.Root = go
	local name = self.Name
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	--self.Bg = C(UIWidget, trans, "Container", name, false)
	self.Prefab = T(trans, "Container/Item")
	for i=1,10 do
		table.insert(self.IdleList, self:GetItem(i))
	end
	self:AddEvent()
end

function E:AddEvent()
   	local EH = EventHandler
   	self.OnUpdatePro = EH(self.UpdatePro, self)
   	self.OnUpdateProEnd = EH(self.UpdateProEnd, self)
	local M = EventMgr.Add
	M("OnUpdatePro", self.OnUpdatePro)
	--M("OnUpdateProEnd", self.OnUpdateProEnd)
end

function E:RemoveEvent()
	local M = EventMgr.Remove
	M("OnUpdatePro", self.OnUpdatePro)
	--M("OnUpdateProEnd", self.OnUpdateProEnd)
end

function E:UpdatePro(id, old, new)
	if id == ProType.ATTR_MOVE_SPEED then return end
	local name = GetProName(id)
	if StrTool.IsNullOrEmpty(name) then
		if id == 0 then return end
		iTrace.eError("hs", string.format("未从属性表找到指定id:%s",id))
		return
	end
	--local data = self:GetItem()
	local len = #self.IdleList
	if len <=0 then return end
	local data = self.IdleList[len]
	table.remove(self.IdleList, len)
	UIFly.AddGo(self.Key, data.Item)
	self.FlyList[data.Item.name] = data
	data.Name.text = name
	data.Value.text = old
	data.Add.text = new
	self.IsFly = true
end

function E:GetItem(index)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = tostring(index)
	go.transform.parent = self.Prefab.transform.parent
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	local flyAlpha = ComTool.Add(go, UIFlyAlpha)
	if flyAlpha then
		flyAlpha.anchors1 = Vector3.New(0,40,0)
		flyAlpha.anchors2 = Vector3.New(0,70,0)
		flyAlpha.targetPos = Vector3.New(0,100,0)
		flyAlpha.time = 1.1
		flyAlpha.isFade = true
		flyAlpha.fadeIn = 0.1
		flyAlpha.fadeOut = 0.8
		flyAlpha.isDestroy = false
		flyAlpha.onEndEvent = UE(self.FlyEnd, self)
	end
	local C = ComTool.Get
	local t = go.transform
	local name = "飘属性Item"
	local data = {}
	data.Item = go
	data.Name =  C(UILabel, t, "Name", name, false)
	data.Value =  C(UILabel, t, "Value", name, false)
	data.Add =  C(UILabel, t, "Add", name, false)
	return data
end

function E:FlyEnd(go)
	if LuaTool.IsNull(go) == true then return end
	local name = go.name
	go:SetActive(false)
	local data = self.FlyList[name]
	if data == nil then return end
	self.FlyList[name] = nil
	table.insert(self.IdleList, data)	
end

function E:Update()
	if not self.IsFly then return end
	if self.Timing and self.Timing == 0 then
		local list = UIFly.GetList(self.Key)
		if not list then self.IsFly = false return end
		if list.Count > 0 then
			local fly = list[0]
			fly:Play()
			UIFly.Remove(self.Key, fly)
			self.Timing = Time.realtimeSinceStartup
		elseif list.Count == 0 then
			self.IsFly = false
		end
	else
		if Time.realtimeSinceStartup - self.Timing  > self.Interval then
			self.Timing = 0
		end
	end
end

function E:ClearList()
	local idle = self.IdleList
	local len = #idle
	while len > 0 do
		local data = idle[len]
		if data then
			TableTool.ClearDic(data)
		end
		table.remove(self.IdleList, len)
		len = #self.IdleList
	end

	local fly = self.FlyList
	if fly then
		for k,v in pairs(fly) do
			TableTool.ClearDic(v)
			v = nil
		end
	end
end

function E:Dispose()
	self:RemoveEvent()
	self:ClearList()
	TableTool.ClearDic(self.IdleList)
	TableTool.ClearDic(self.FlyList)
	UIFly:Dispose(self.Key)
end
--endregion

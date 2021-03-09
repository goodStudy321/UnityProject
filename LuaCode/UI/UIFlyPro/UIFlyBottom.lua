--region FlyBottom.lua
--Date
--此文件由[HS]创建生成


UIFlyBottom = {}
local E = UIFlyBottom
local UE = UIFly.EndDelegate

E.Name = "飘经验"

E.Key = "Exp"

E.Timing = 0
E.Interval = 0.5
E.IsFly = false
E.IdleList = {}
--注册的事件回调函数

function E:New()
	return self
end

function E:Init(go)
	self.Root = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Prefab = T(trans, "Exp")
	for i=1,10 do
		table.insert(self.IdleList, self:GetItem())
	end
	self:AddEvent()
end

function E:AddEvent()
	local M = EventMgr.Add
	self:UpdateEvent(M)
end

function E:RemoveEvent()
	local M = EventMgr.Remove
	self:UpdateEvent(M)
end

function E:UpdateEvent(M)
   	local EH = EventHandler
	M("OnAddExp", EH(self.UpdateAddExp, self))
end

function E:UpdateAddExp(e, killMonster, buff)
	local exp = tonumber(e)
	local b = tonumber(buff)
	if StrTool.IsNullOrEmpty(exp) then return end
	if exp <= 0 then return end
	if killMonster then 
		self:UpdateFlyExp(exp, b)
	end
end

function E:GetItem()
	local go = GameObject.Instantiate(self.Prefab)
	go.transform.parent = self.Prefab.transform.parent
	go.transform.localPosition = Vector3.New(-60,0,0)
	go.transform.localScale = Vector3.one
	local flyAlpha = ComTool.Add(go, UIFlyAlpha)
	if flyAlpha then
		flyAlpha.anchors1 = Vector3.New(-60,40,0)
		flyAlpha.anchors2 = Vector3.New(-60,80,0)
		flyAlpha.targetPos = Vector3.New(-60,160,0)
		flyAlpha.time = 3
		flyAlpha.isFade = true
		flyAlpha.fadeIn = 0.5
		flyAlpha.fadeOut = 0.5
		flyAlpha.isDestroy = false
		flyAlpha.onEndEvent = UE(self.FlyEnd, self)
	end
	return go
end

function E:FlyEnd(go)
if LuaTool.IsNull(go) == true then return end
	go:SetActive(false)
	table.insert(self.IdleList, go)
end

function E:UpdateFlyExp(exp, buff)
	if exp == 0 then return end
	local list = UIFly.GetList(self.Key)
	if list and list.Count >= 10 then
		return
	end
	local idle = self.IdleList
	if #idle == 0 then return end
	local go = idle[1]
	table.remove(idle, 1)

	local lab = go:GetComponent("UILabel")
	if lab then 
		if buff ~= 0 then
			lab.text = string.format("%s (+%s%%)", exp, math.floor(buff))
		else
			lab.text = tostring(exp)
		end
	end
	UIFly.AddGo(self.Key, go)
	self.IsFly = true
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

function E:Dispose()
	self.IsFly = nil
	self:RemoveEvent()
	TableTool.ClearDic(self.IdleList)
	UIFly:Dispose(self.Key)
end
--endregion

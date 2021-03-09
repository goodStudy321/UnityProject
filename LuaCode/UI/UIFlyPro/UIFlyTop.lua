--region UIFlyTop.lua
--Date
--此文件由[HS]创建生成


UIFlyTop = {}
local M = UIFlyTop

local UpLvSound = 109
local Ass = Loong.Game.AssetMgr.LoadPrefab

M.Name = "飘经验"
M.FlyLimit = 4			--飘字限制数量
M.FlyInv = 1 			--飘字间隔
M.MItems = {}
M.IdleList = {}
M.ActiveList = {}
M.MissExp = 0
--注册的事件回调函数

function M:New()
	return self
end

function M:Init(go)
	self.Root = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	--------------------------------------
	self.OnPlayTween= EventDelegate.Callback(self.OnMissFinished, self)
	self.MissRoot = C(UIWidget, trans, "Miss","任务获得奖励" , false)
	self.MissPlay = C(UIPlayTween, trans, "Miss", "任务获得奖励", false)
	EventDelegate.Add(self.MissPlay.onFinished, self.OnPlayTween)
	for i=1,5 do
		local go = T(trans, string.format("Miss/Item%s",i))
		table.insert(self.MItems, self:GetData(go))
	end
	-----------------------------------------]
	self.OnPlayTweenCallback = EventDelegate.Callback(self.OnTweenFinished, self)
	local prefab = T(trans, "Other/Item")
	for i=1,10 do
		local go = GameObject.Instantiate(prefab)
		go.transform.parent = prefab.transform.parent
		go.transform.localScale = Vector3.one
		go.transform.localPosition = prefab.transform.localPosition
		table.insert(self.IdleList, self:GetData(go, true))
		go:SetActive(true)
	end
	prefab.gameObject:SetActive(false);
	---------------------------------------------------------------------
	self.Eff = T(trans, "Eff/UI_HeroLevelUp_Text")
	self.CurLv = User.MapData.Level
	self.GetList = {}
	self.FlyItem = false
	self.FirstTime = 0

	self:AddEvent()
end

function M:GetData(go, isPlayTween)
	local info = {}
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	info.Root = go
	info.Icon = C(UITexture, trans, "Cell/Icon", "UpdateFlyItemData", false)
	info.Quality = C(UISprite, trans, "Cell/Quality", "UpdateFlyItemData", false)
	info.Bind = T(trans, "Cell/Bind")
	info.Des = C(UILabel, trans, "Des", "UpdateFlyItemData", false)
	if isPlayTween == true then
		info.Widget = go:GetComponent("UIWidget")
		info.Play = go:GetComponent("UIPlayTween")
		EventDelegate.Add(info.Play.onFinished, self.OnPlayTweenCallback)
		info.Tweens = go:GetComponentsInChildren(typeof(UITweener), true)
	end
	return info
end

function M:AddEvent()
	local M = EventMgr.Add
	self:UpdateEvent(M)
	MissionMgr.eCompleteEvent:Add(self.CompleteMission, self)
    PropMgr.eGetAdd:Add(self.OnGetAdd, self)
end

function M:RemoveEvent()
	local M = EventMgr.Remove
	self:UpdateEvent(M)
	MissionMgr.eCompleteEvent:Remove(self.CompleteMission, self)
    PropMgr.eGetAdd:Remove(self.OnGetAdd, self)
end

function M:UpdateEvent(M)
   	local EH = EventHandler
	M("OnAddExp", EH(self.UpdateAddExp, self))
	--M("mDropAdd", EH(self.DropAdd, self))
	M("OnChangeLv", EH(self.UpdateLevel, self))
end

function M:UpdateAddExp(e, killMonster, buff)
	local exp = tonumber(e)
	if StrTool.IsNullOrEmpty(exp) then return end
	if exp <= 0 then return end
	if not killMonster then 
		self:UpdateFlyExp(exp)
	end
end

function M:UpdateFlyExp(exp)
	if self.MissExp == exp then return end
	local idle = self.IdleList
	if #idle == 0 then return end
	local expInfo = {};
	expInfo.k = 100;
	expInfo.v = exp;
	expInfo.b = nil;
	table.insert(self.GetList, expInfo);
	if self.FlyItem == true then return end
	self.FirstTime = 0
	self.FlyItem = true
	-- self:UpdateFlyItem(idle, 100, exp, nil)
end

function M:DropAdd(id, bind)
	local idle = self.IdleList
	if #idle == 0 then return end
	self:UpdateFlyItem(idle, id, 1, bind)
end

function M:OnGetAdd(action,getList)
	if action==10101 then return end
	if action==0 then return end
	if #getList == 0 then return end
	local idle = self.IdleList
	if #idle == 0 then return end
	for i,v in ipairs(getList) do
		local item = {}
		item.k = v.k
		item.v = v.v
		item.b = v.b
		table.insert(self.GetList, item)
	end
	if self.FlyItem == true then return end
	self.FirstTime = 0
	self.FlyItem = true
end

function M:UpdateFlyItem(idle, id, num, isBind)
	local item = ItemData[tostring(id)]
	if not item then return end
	--self:ClearMItemData()
	local info = idle[1]
	table.remove(idle, 1)
	table.insert(self.ActiveList, info)
	if info then
		local icon = info.Icon
		local quality = info.Quality
		local bind = info.Bind
		local des = info.Des
		local root = info.Root
		if icon then 
			info.Root.name = item.icon
			local del = ObjPool.Get(Del1Arg)
			del:SetFunc(self.SetIcon, self)
			del:Add(icon)
			AssetMgr:Load(item.icon,ObjHandler(del.Execute, del))
		end
		if quality then
			quality.spriteName = string.format("cell_%s", item.quality)
		end
		if bind then
			local b = isBind and isBind == 1
			bind:SetActive(b)
		end
		if des then
			if num == 1 then
				des.text = item.name
			else
				des.text = string.format("%s %s", num, item.name)
			end
		end
		if info.Play then info.Play:Play(true) end
	end
end

function M:ClearFlyItem()
	local active = self.ActiveList
	while #active > 0 do
		info = active[1]
		table.remove(active, 1)
		if info then
			local tweens = info.Tweens
			if tweens then 
				local len = tweens.Length - 1
				for i=0,len do
					tweens[i].enabled = false
					tweens[i]:ResetToBeginning()
				end
			end
			if info.Widget then info.Widget.alpha = 0 end
		end
		table.insert(self.IdleList, info)
	end
end

function M:OnTweenFinished()
	local active = self.ActiveList
	if #active == 0 then return end
	local info = active[1]
	table.remove(active, 1)
	table.insert(self.IdleList, info)
end


--======================================升级==========================================--
--更新等级
function  M:UpdateLevel()
	local data= User.instance.MapData
	if self.CurLv < data.Level then
		if self.CurLv and self.CurLv > 1 then
			if self.Eff then
				self.Eff:SetActive(true)
			end
		end
		self.CurLv = data.Level
	end
end
--======================================升级==========================================--

--======================================任务==========================================--
--完成任务
function M:CompleteMission(id)
	local mission = MissionTemp[tostring(id)]
	if not mission then return end
	self:ClearMItemData()
	self:ClearFlyItem()
	local index = 0
	local item = mission.item
	if item then
		index = #item
		for i=1,index do
			local it = item[i]
			self:UpdateMItemData(i, it.id, it.num, it.bind)
		end
	end
	local exp = mission.exp
	if not exp then
		--iTrace.eError("hs","表没配经验奖励")
		exp = 0
		return
	end
	if mission.expType == 1 then
		exp = PropTool.GetExp(exp/10000)
	end
	if exp and exp > 0 then
		index = index + 1
		self:UpdateMItemData(index, 100, exp, nil)
		self.MissExp = exp
	end
	if index == 0 then return end
	local play = self.MissPlay
	if play then
		play:Play(true)
	end
end

function M:UpdateMItemData(index, id, num, bind)

	if id == 0 then return end
	local item = ItemData[tostring(id)]
	if not item then return end
	local items = self.MItems
	local info = items[index]
	if info then
		local icon = info.Icon
		local quality = info.Quality
		local bind = info.Bind
		local des = info.Des
		local root = info.Root
		if icon then 
			info.Root.name = item.icon
			local del = ObjPool.Get(Del1Arg)
			del:SetFunc(self.SetIcon, self)
			del:Add(icon)
			del:Add(item.icon)
			AssetMgr:Load(item.icon,ObjHandler(del.Execute, del))
		end
		if quality then
			quality.spriteName = string.format("cell_%s", item.quality)
		end
		if bind then
			local b = isBind and isBind == 1
			bind:SetActive(b)
		end
		if des then
			if num == 1 then
				des.text = item.name
			else
				des.text = string.format("%s %s", num, item.name)
			end
		end
		if root then
			root:SetActive(true)
		end
	end
end

function M:ClearMItemData()
	self.MissExp = 0
	local items = self.MItems
	if items == nil then return end
	local len = #items
	for i=1,len do
		local info = items[i]
		if info then
			self:UnloadPic(info)
			local icon = info.Icon
			local quality = info.Quality
			local bind = info.Bind
			local des = info.Des
			local root = info.Root
			if icon then icon.mainTexture = nil end
			if quality then quality.spriteName = "" end
			if bind then bind:SetActive(false) end
			if des then des.text = "" end
			if root then root:SetActive(false) end
		end
	end
end

function M:UnloadPic(info)	
	if not StrTool.IsNullOrEmpty(info.Root.name) then
		self:UnloadPicPath(info.Root.name)
	end
end

function M:UnloadPicPath(path)
	AssetMgr:Unload(path, ".png", false)
end

function M:OnMissFinished()
	self.MissExp = 0
	if self.MissRoot then
		self.MissRoot.alpha = 0
	end
end
--======================================任务==========================================--
function M:SetIcon(t,icon, path)
	if icon then
		icon.mainTexture = t 
	else
		self:UnloadPicPath(path)
	end
end

function M:Close()
	self:ClearFlyItem()
	self:ClearMItemData()
	self.FirstTime = 0
	self.FlyItem = false
	local list = self.GetList
	if list then
		local len = #list
		while len>0 do
			local kv = list[len]
			table.remove( list, len)
			TableTool.ClearDic(kv)
			len = #list
		end
	end
end

function M:Update()
	if self.FlyItem == true then
		if TimeTool.GetServerTimeNow()*0.001 - self.FirstTime >= 0.8 then
			local list = self.GetList
			if list then
				local kv = list[1]
				table.remove(list, 1)
				if kv then
					self:UpdateFlyItem(self.IdleList, kv.k, kv.v, kv.b)
				end
				if #list == 0 then
					self.FlyItem = false
					self.FirstTime = 0
					return
				end
				self.FirstTime = TimeTool.GetServerTimeNow()*0.001
			end
		end
	end
end

function M:Dispose()
	self:RemoveEvent()
	TableTool.ClearDic(self.MItems)
end
--endregion

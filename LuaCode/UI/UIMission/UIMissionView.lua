--region UIMissionView.lua
--主菜单任务窗口
--此文件由[HS]创建生成

UIMissionView = {}
local M = UIMissionView
M.eClickViewBtn = Event()

local mMgr = MissionMgr

--注册的事件回调函数

function M:New(go)
	self.Root = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	local name = "主菜单任务窗口"
	self.View = T(trans, "View")
	self.NavBtn = T(trans, "View/NavPath")
	self.NavLab = C(UILabel, trans, "View/NavPath/Label", name, false)
	self.SystemBtn = T(trans, "View/System")
	self.SystemLab = C(UILabel, trans, "View/System/Label", name, false)

	self.ChapterRoot = C(UISprite, trans, "ChapterItem", name, false)
	self.ChapterRoot.gameObject:SetActive(true)
	self.Chapter = C(UILabel, trans, "ChapterItem/Chapter", name, false)
	self.Title = C(UILabel, trans, "ChapterItem/Title", name , false)
	self.Slider = C(UISlider, trans, "ChapterItem/Slider", name, false)
	self.Progress = C(UILabel, trans, "ChapterItem/Progress", name, false)

	self.MainTip = T(trans, "MainTip")
	self.FristFeeder = T(trans, "FristFeeder")

	self.Panel = C(UIPanel, trans, "Panel", name, false)
	self.ScrollView = self.Panel.gameObject:GetComponent("UIScrollView")
	self.Container = C(UIWidget, trans, "Panel/Container", name, false)
	self.Prefab = T(trans,"Panel/Container/Item")
	self.MainEff = T(trans, "Panel/Container/eff/UI_kuansg")
	self.Items = {}
	for i=1,10 do
		self:AddItem(i)
	end
	self.MissIds = {}
	self.MissionTarget = nil
	self:UpdateMission()
	UITool.SetLsnrSelf(self.NavBtn, self.OnClickNavBtn, self)
	UITool.SetLsnrSelf(self.SystemBtn, self.OnClickSystemBtn, self)
	UITool.SetLsnrSelf(self.ChapterRoot, self.OnChapterRoot, self, nil, false)
	RobberyMgr.eUpdateStateInfo:Add(self.UpdateChapter, self)
	return self
end

function M:OnClickNavBtn(go)
	self.eClickViewBtn(self.MissionTarget, "Nav")
	self:ViewActive(false)
end

function M:OnClickSystemBtn(go)
	self.eClickViewBtn(self.MissionTarget, "System")
	self:ViewActive(false)
end

function M:OnChapterRoot(go)
	UIRobbery:OpenRobbery(1)
	--UIMgr.Open(UIChapterPanel.Name)
	--UIMgr.Open(UIChapterEff.Name)
end

function M:ViewActive(value)
	if self.View then self.View:SetActive(value) end
	if not value then self.MissionTarget = nil end
end

function M:UpdateView(tar, str1, str2)
	self.MissionTarget = tar
	if self.NavLab then self.NavLab.text = str1 end
	if self.SystemLab then self.SystemLab.text = str2 end
	self:ViewActive(true)
end

function M:UpdateChapter(id)
	--[[
	local mMain = mMgr.Main
	if self.ChapterRoot then
		self.ChapterRoot.gameObject:SetActive(mMain ~= nil) 
	end
	if not mMain or not mMain.Temp then 
		--[[
		local id = mMain.ID
		if not id then
			iTrace.eError("hs", "################### 主线任务数据为nil")
		else
			iTrace.eError("hs", "################### 主线任务数据为nil"..tostring(id))
		end
		return 
	end
	if not id then id = mMain.Temp.chapter end
	--if id ~= mMain.Temp.chapter then return end
	local chapter = mMain.Temp.chapter
	if mMain.Temp.cEnd then chapter = mMain.Temp.cEnd end
	local c = chapter % 100
	local cTemp = ChapterTemp[c]
	if not cTemp then return end
	if self.Chapter then self.Chapter.text = cTemp.index end
	if self.Title then self.Title.text = cTemp.name end
	local slider = 0
	local num = 0
	local limit = cTemp.limit
	local data = ChapterMgr.ChapterDic[tostring(cTemp.id)]
	if data then
		num = data.Num
		slider = num / limit
	end
	if self.Slider then self.Slider.value = slider end
	if self.Progress then self.Progress.text = string.format("(%s/%s)", num, limit) end
	]]--

	local name, cur, limit = RobberyMgr:GetAmbCurInfo()
	if StrTool.IsNullOrEmpty(name) == true then return end
	if cur == nil then return end
	if limit == nil then return end
	local title = self.Title
	local slider = self.Slider 
	local pro = self.Progress
	if title then
		title.text = name
	end
	if slider then
		slider.value = cur / limit
	end
	if pro then
		pro.text = string.format("(%s/%s)", cur, limit)
	end
end

--更新任务
function M:UpdateMission()
	local mMain = mMgr.Main
	local mFeeder= mMgr.FeederList
	local mTrun= mMgr.TurnList
	local mLiveness=mMgr.LivenessList
	local mFaiml = mMgr.FamilyList
	local mEscort = mMgr.Escort
	local t = {}
	if self.MainEff then self.MainEff:SetActive(mMain ~= nil) end
	if mMain then
		table.insert(t, mMain)
	end
	if mEscort then
		table.insert(t, mEscort)
	end
	if mFeeder then
		for k,v in pairs(mFeeder) do
			table.insert(t, v)
		end
		if LuaTool.Length(mFeeder) == 0 then
			self:SetFristFeeder(false)
		end
	end
	if mTrun then
		for k,v in pairs(mTrun) do
			table.insert(t, v)
		end
	end
	if mLiveness then
		for k,v in pairs(mLiveness) do
			table.insert(t, v)
		end
	end
	if mFaiml then
		for k,v in pairs(mFaiml) do
			table.insert(t, v)
		end
	end
	--[[
	table.sort(t,function (a,b)
		local ac = 0
		local bc = 0
		if a.Status == MStatus.ALLOW_SUBMIT then
			ac = 1
		end
		if b.Status == MStatus.ALLOW_SUBMIT then
			bc = 1
		end
		return ac < bc
	end)
	]]--
	local len = #t

	local ilen = #self.Items
	if len > ilen then
		for i=ilen + 1,len do
			self:AddItem(i)
		end
	elseif len < ilen then
		for i=len + 1,ilen do
			self:HideItem(i)
		end
	end

	for i=1,len do
		self:UpdateItem(i, t[i])
	end
	self:Reposition()
end

-------------------------------------------------------------
--[[
function M:PairsDic(dic)
	local iter = dic:GetEnumerator() 
    while iter:MoveNext() do
        local v = iter.Current.Value
		self:UpdateItem(v)
    end
end
]]--

	--[[
--检测任务
function M:CheckMission(mission)
	if self.Items[mission.Key] ~= nil then
		self.Items[mission.Key]:UpdateData(mission)
	else
		self:UpdateItem(mission)
	end
end
	]]--

function M:AddItem(index)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = tostring(index)
	go:SetActive(true)
	go.transform.parent = self.Container.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	UITool.SetLsnrSelf(go, self.OnClickItem, self, nil, false)
	item = ObjPool.Get(UIMissionItem)
	item:Init(go)
	if not self.Items then self.Items = {} end
	table.insert(self.Items, item)
end

function M:HideItem(index)
	local items = self.Items
	if items then
		local item = items[index]
		if item then
			item:SetActive(false)
		end
	end
end

function M:UpdateItem(index, mission)
	local items = self.Items
	if items then
		local item = items[index]
		if item then
			item:UpdateData(mission)
			item:SetActive(true)
		end
	end
end

--[[
--更新Item
function M:UpdateItem(mission)
	if not mission or not mission.Key then 
		return 
	end
	local go = GameObject.Instantiate(self.Prefab)
	go.name = mission.Key
	go:SetActive(true)
	go.transform.parent = self.Container.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	UITool.SetLsnrSelf(go, self.OnClickItem, self, nil, false)
	item = ObjPool.Get(UIMissionItem)
	item:Init(go)
	item:UpdateData(mission)
	if not self.Items then self.Items = {} end
	self.Items[mission.Key] = item
end
]]--

--等级更新
function M:UpdateLv()
	local items = self.Items
	if not items then return end
	local len = #items
	for i=1,len do
		local v = items[i]
		if v then
			v:ChangeLv()
			v:UpdateFlyStatus()
			v:UpdateDes()
			v:UpdateHeight()
			if v.Mission and not v.Mission.Temp then
				v:AutoExecuteAction()
			end
			--[[
			if v.Mission.Temp.type == MissionType.Main then
				v:AutoExecuteAction()
			end
			]]--
		end
	end
end

function M:Reposition()
	local items = self.Items
	if not items then return end
	local value = 0
	self:SortItems()
	local len = #items
	for i=1,len do
		local item = items[i]
		if item then
			local go = item.gameObject
			if go and go.activeSelf == true then
				item:UpdatePos(value)
				value = value + item:GetHeight()
			end
		end
	end
	local panel = self.Panel
	if panel then
		if value - panel.height <  panel.clipOffset.y then
			local y = 0.6
			--if mMgr.Main == nil then y = 74.32 end
			panel.transform.localPosition = Vector3.New(166.39,y,0)
			panel.clipOffset = Vector2.zero
		end
	end
	if value > 144 then
		self.ScrollView.isDrag = true
	else
		self.ScrollView.isDrag = false
	end
end

function M:SortItems()
	local items = self.Items
	if not items or #items <= 1 then return end
	table.sort(items,function (a,b)
		local ac = 0
		local bc = 0
		local am = a.Mission
		local bm = b.Mission
		local ai = tonumber(a.trans.name)
		local bi = tonumber(b.trans.name)
		local at = 0
		local bt = 0
		if LuaTool.Length(am) ~=0 and LuaTool.Length(bm) ~=0 then
			local aid = am.ID
			local bid = bm.ID
			if am.Temp and am.Temp.type == MissionType.Main then
				ac = 2
			elseif am.Status == MStatus.ALLOW_SUBMIT then
				ac = 1
			end
			if bm.Temp and bm.Temp.type == MissionType.Main then
				bc = 2
			elseif bm.Status == MStatus.ALLOW_SUBMIT then
				bc = 1
			end
			if ac ~= bc then
				return ac > bc
			end
			if aid == 900000 then
				local i = math.floor(bid/10000)
				if i > 1 then return aid > bid end
			end
			if bid == 900000 then
				local i = math.floor(aid/10000)
				if i > 1 then return aid > bid end
			end
			if am.Temp and am.Temp.tarType == MTType.Confine then
				at = 1
			end
			if bm.Temp and bm.Temp.tarType == MTType.Confine then
				bt = 1
			end
			if at ~= bt then
				return at > bt 
			end
			return  aid < bid
		end
		return ai < bi
	end)
end

--[[
function M:GetIdList()
	local list = {}
	for k,v in pairs(self.Items) do
		local mission = v.Mission
		if mission then 
			table.insert(list,mission.ID)
		end
	end
	table.sort(list,function (a,b)
		local ac = 0
		local bc = 0
		local am = self.Items[tostring(a)].Mission
		local bm = self.Items[tostring(b)].Mission
		if am then
			if am.Temp.type == MissionType.Main then
				ac = 2
			elseif am.Status == MStatus.ALLOW_SUBMIT then
				ac = 1
			end
		end
		if bm then
			if bm.Temp.type == MissionType.Main then
				bc = 2
			elseif bm.Status == MStatus.ALLOW_SUBMIT then
				bc = 1
			end
		end
		if ac ~= bc then
			return ac > bc
		end
		if a == 900000 then
			local i = math.floor(b/10000)
			if i > 1 then return a > b end
		end
		if b == 900000 then
			local i = math.floor(a/10000)
			if i > 1 then return a > b end
		end
		return a < b
	end)
	return list
end
]]--
function M:OnClickItem(go)
	if Hangup:IsPause() == true then	
		Hangup:Resume(OpenMgr.FlyIconPause)
		MissionMgr:Execute(false)
	end
	local id = tonumber(go.name)
	local items = self.Items
	if not items then return end
	local index = -1
	for i,v in ipairs(items) do
		if v.Mission and v.Mission.ID == id then
			index = i
			break
		end
	end
	if index == -1 then return end
	local item = self.Items[index]
	if item then
		--User:ClearPlayerNavState(0)
		if item:IsShowMenuTip() == true then return end
		if item.Mission then
			mMgr:SetCurExecuteType(item.Mission.Temp.type)
			if mMgr:IsRebirth(item.Mission) then
				UIMgr.Open(UIRebirth.Name)
				return
			end
			if mMgr:IsChangeExecuteMiss(item.Mission) == false then
				if mMgr:AutoComplete(item.Mission) == true then
					item:AutoExecuteAction(nil, false)
					return
				end
				local miss = mMgr.Escort
				if miss then 
					UITip.Error("正在护送状态，不能执行其他任务！")
				end
				return
			end
			 if item.Mission:CheckLevel() == false then
				Hangup:ClearAutoInfo()
				User:ResetMisTarID()
				mMgr:Execute(false)
				if item.Mission and item.Mission.Temp and item.Mission.Temp.type == MissionType.Feeder and not item.Mission.Temp.childType then
					Hangup:SetAutoHangup(false);
				else
					Hangup:SetAutoHangup(true);
				end
				mMgr.CurExecuteType = item.Mission.Temp.type
				mMgr.CurExecuteChildType = item.Mission.Temp.childType
			end
		end
		item.Mission.Last = nil
		local m = MissionMgr:GetMissionForID(item.Mission.ID)
		if m then m.Last = nil end
		item:AutoExecuteAction()
	end
	self:SetMainTip(false)
	self:SetFristFeeder(false)
end

function M:UpdateAutoHangup(value)
	if User.MapData.Level >= 45 then return end
	if value == true then
		self.IsShowTip = nil
		self:SetMainTip(false)
	else
		if self.IsShowTip then return end
		self.IsShowTip = os.time()
	end
end

function M:SetMainTip(value)
	if self.MainTip then self.MainTip:SetActive(value) end
end

function M:SetFristFeeder(value)
	if self.FristFeeder then
		self.FristFeeder:SetActive(value)
		if value == true then
			if self.Panel then
				self.Panel.transform.localPosition = Vector3.New(166.39,0.6,0)
				self.Panel.clipOffset = Vector2.zero
			end
		end
	end
end

function M:CleanMission(id)
	self:UpdateMission()
	--[[
	local key = tostring(id)
	if self.Items[key] ~= nil then
		self.Items[key]:Dispose()
		ObjPool.Add(self.Items[key])
		self.Items[key] = nil
		table.remove(self.Items, key)
	end
	self:Reposition()
	]]--
end

function M:CleanAllMission()
	self:CleanItems()
end

function M:CleanItems()
	local items = self.Items
	if not items then return end
	for i,v in ipairs(items) do
		v:SetActive(false)
	end
	self:Reposition()
end

function M:DestroyItems()
	local items = self.Items
	if not items then return end
	local len = #items
	while len > 0 do
		local v = items[len]
		table.remove(self.Items, len)
		if v then
			v:Dispose()
			ObjPool.Add(v)
			TableTool.ClearDic(v)
			v = nil
		end
		local len = #items
	end
	self:Reposition()
end

function M:GetHeight()
	local items = self.Items
	if not items then return 0 end
	local len = #items
	local h = 0
	for i=1,len do
		local item = items[i]
		if item  then
			h = h + item:GetHeight()
		end
	end
	if self.ChapterRoot and self.ChapterRoot.gameObject.activeSelf == true then
		h = h + self.ChapterRoot.height
	end
	return h
end

function M:Update()
	if App.isEditor == true then
		return;
	end
	if self.IsShowTip then
		if os.time() - self.IsShowTip >= 10 then
			self:SetMainTip(true)
			self.IsShowTip = nil
		end
 	end
end

function M:Clear()
	self:CleanItems()
	self:SetFristFeeder(false)
end

function M:Dispose()
	RobberyMgr.eUpdateStateInfo:Remove(self.UpdateChapter, self)
	self:RemoveEvent()
	self:DestroyItems()
end
--endregion

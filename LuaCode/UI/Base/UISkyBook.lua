--region UISkyBook.lua
--Date
--此文件由[HS]创建生成
require("UI/UISkyBook/UISkyBookBossCell")
require("UI/UISkyBook/UISkyBookItem")

UISkyBook = UIBase:New{Name ="UISkyBook"}
local M = UISkyBook
local sbMgr = SkyBookMgr

function M:InitCustom()
	local name = "飘属性面板"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.CloseBtn = T(trans, "CloseBtn")

	self.Togs = {}
	local len = LuaTool.Length(SkyBookTypeTemp)
	for i=1,len do
		local data = {}
		data.toggle = C(UIToggle, trans, string.format("ToggleGroup/T%s", i), name, false)
		data.lab1 = C(UILabel, trans, string.format("ToggleGroup/T%s/Label", i), name, false)
		data.lab2 = C(UILabel, trans, string.format("ToggleGroup/T%s/Checkmark/Label", i), name, false)
		data.Action = T(trans, string.format("ToggleGroup/T%s/Action", i))
		table.insert(self.Togs, data)
		data.toggle.gameObject:SetActive(true)
	end

	self.Pic = C(UITexture, trans, "Texture", name, false)
	self.RewardName = C(UILabel, trans, "Reward/Name", name, false)
	self.Effect = C(UILabel, trans, "Reward/Effect", name, false)
	self.Rate = C(UILabel, trans, "Reward/Rate", name, false)
	self.Btn = C(UIButton, trans, "Reward/Button", name, false)
	self.BtnBG = C(UISprite, trans, "Reward/Button/Background", name, false)
	self.BtnEffect = T(trans, "Reward/Button/Background/FX_UI_Button ")
	self.Label = C(UILabel, trans, "Reward/Button/Label", name, false)
	self.Icon = C(UITexture, trans, "Reward/Icon", name, false)

	self.Panel = C(UIPanel, trans, "ScrollView", name, false)
	self.UISV = C(UIScrollView, trans, "ScrollView", name, false)
	self.Grid = C(UIGrid, trans, "ScrollView/Grid", name, false)
	self.Prefab = T(trans, "ScrollView/Grid/Item", name, false)
	

	self.Grid.onCustomSort = function (a, b)
		return self:SortGrid(a,b)
	end
	

	self.Items = {}
	self.Index = "1"
end

function M:AddEvent()
	self.OnUpdateToggles = EventHandler(self.UpdateToggles, self)
	self.OnClickMenuTipAction = EventHandler(self.ClickMenuTipAction, self)
	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")
	local E = UITool.SetLsnrSelf
	if self.CloseBtn then
		E(self.CloseBtn, self.ClickCloseBtn, self)
	end
	if self.Btn then
		E(self.Btn, self.ClickBtn, self)
	end
	if self.Togs then
		for i,v in ipairs(self.Togs) do
			E(v.toggle, self.ClickTogBtn, self)
		end
	end
end

function M:RemoveEvent()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
end

function M:UpdateEvent(M)	
	M("OnChangeLv", self.OnUpdateToggles)
	M("ClickMenuTipAction", self.OnClickMenuTipAction)
end

function M:SetEvent(fn)
	sbMgr.eUpdate[fn](sbMgr.eUpdate, self.UpdateSkyBook, self)
	sbMgr.eGetReward[fn](sbMgr.eGetReward, self.UpdateStatus, self)
	sbMgr.eGetTypeReward[fn](sbMgr.eGetTypeReward, self.UpdateRewardBtn, self)
end

function M:ClickCloseBtn(go)
	self:Close()
end

function M:UpdateToggles()
	if not self.Togs then return end
	local index = nil
	for i,v in ipairs(self.Togs) do
		local temp = SkyBookTypeTemp[tostring(i)]
		if temp then 
			local name = "?????"
			if sbMgr:IsOpen(i) == true then
			--if true then
				if StrTool.IsNullOrEmpty(temp.name) == false then
					name = temp.name
				end
				local value = sbMgr:IsCheckType(temp)
				if not index and value == true then index = i end
				if v.Action then v.Action:SetActive(value) end
			end
			if v.lab1 then v.lab1.text = name end
			if v.lab2 then v.lab2.text = name end
		end
	end
	return index
end

function M:SelectTog(index)
	if not index then return end
	local tog = self.Togs[index]
	if not tog or not tog.toggle then return end
	tog.toggle:CustomAction(true)
	self:ClickTogBtn(tog.toggle.gameObject)
end

function M:ClickMenuTipAction(name, tt, str, index)
	if not tt or tt ~= MenuType.SkyBook then return end
	sbMgr:ClickMenuTipAction(str)
end

function M:ClickBtn(go)
	sbMgr:ReqGetTypeReward(tonumber(self.Index))
end

function M:ClickTogBtn(go)
	local t = string.gsub(go.name, "T", "")
	if StrTool.IsNullOrEmpty(t) then return end
	local lIndex = tonumber(self.Index)
	local cIndex = tonumber(t)
	local isOpen = sbMgr:IsOpen(cIndex, true)
	--local isOpen = true
	if isOpen == false then
		if self.Togs[lIndex] then
			self.Togs[lIndex].toggle:Set(true, true, false)
		end
		if self.Togs[cIndex] then
			self.Togs[cIndex].toggle:Set(false, true, false)
		end
		return
	end
	self.Index = t
	self:UpdateView()
	
	if self.UISV then
		self.UISV:Press(false)
	end
	if self.Panel then
		self.Panel.clipOffset = Vector2.zero
		self.Panel.transform.localPosition = Vector3.New(36.6, -26, 0)
	end
	
end

function M:UpdateSkyBook(k, index, id)
	local list = self.Items
	for i,v in ipairs(list) do
		if v.Temp and v.Temp.id == id then
			local data = sbMgr.TypeDic[k]
			if data then
				local info = data.List[index]
				if info then
					v:UpdateData(info)
				end
			end
		end
	end
	self:UpdateToggles()
end

function M:UpdateStatus(id)
	local list = self.Items
	for i,v in ipairs(list) do
		if v.Temp and v.Temp.id == id then
			v:UpdateStatus(1,1, id)
		end
	end
	self:UpdateRewardBtn(self.Index)
	self.Grid:Reposition()
end

------------------------------------------------------------

function M:UpdateView()
	local index = self.Index
	local data = sbMgr.TypeDic[index]
	if not data then return end
	self:UpdatePic(data.Temp)
	self:UpdateItems(data.List)
	self:UpdateSkill(data.Temp)
	self:UpdateRewardBtn(self.Index)
end

function M:UpdatePic(temp)
	local path = temp.pic
	if self.Pic then
		self:UnloadPic()
		if StrTool.IsNullOrEmpty(path) then	
			self.Pic.mainTexture = nil
			self.Pic.gameObject:SetActive(false)
			self.Pic.gameObject:SetActive(true)
			return
		end
		self.PicName = path
		AssetMgr:Load(path,ObjHandler(self.SetPic, self))
	end
end

function M:UpdateSkill(temp)
	local lvid = temp.skill
	if not lvid then return end
	local id = math.floor(lvid / 1000)
	local sTemp = SkillBaseTemp[tostring(id)]
	if not sTemp then return end
	if self.RewardName then
		self.RewardName.text = sTemp.name
	end
	if self.Effect then
		self.Effect.text = sTemp.des
	end
	if self.Icon then
		self:UnloadSkillIcon()
		local path = sTemp.icon
		if StrTool.IsNullOrEmpty(path) then	
			self.Icon.mainTexture = nil
			self.Icon.gameObject:SetActive(false)
			self.Icon.gameObject:SetActive(true)
			return
		end
		self.IconName = path
		AssetMgr:Load(path,ObjHandler(self.SetIcon, self))
	end
end

function M:UpdateRewardBtn(t)
	local type = tostring(t)
	if type ~= self.Index then return end
	local data = sbMgr.TypeDic[type]
	if not data then return end
	local cur = self:GetNum()
	local max = #data.List
	local sName = "领取"
	local active = cur >= max
	if data.Reward == true then
		sName = "已领取"
		active = false
	end
	if self.Label then
		self.Label.text = sName
	end
	if self.Btn then
		if active == true then			
			self.BtnBG.spriteName = "btn_figure_non_avtivity"
		else
			self.BtnBG.spriteName = "btn_figure_down_avtivity"
		end
		self.Btn.isEnabled = active
	end
	if self.BtnEffect then
		self.BtnEffect:SetActive(active)
	end
	self:UpdateRate(data.List)
	self:UpdateToggles()
end

function M:UpdateRate(list)
	if self.Rate then
		if not list then
			self.Rate.text = ""
			return
		end
		local cur = self:GetNum()
		local max = #list
		self.Rate.text = string.format("%s/%s", cur, max)
	end
end

function M:SetPic(tex)
	if self.Pic then
		self.Pic.mainTexture = tex
	end
end

function M:UnloadPic()
	if not StrTool.IsNullOrEmpty(self.PicName) then
		AssetMgr:Unload(self.PicName, ".png", false)
	end
	self.PicName = nil
end

function M:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = tex
	end
end

function M:UnloadSkillIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

function M:UpdateItems(list)
	max=0
	if not list then return end
	local len = #list
	local iLen = #self.Items
	if len > iLen then
		local l = iLen + 1
		for i=l,len do
			self:AddItem(i)
		end
	elseif iLen > len then
		local l = len + 1
		for i=l,iLen do
			self:HideItem(i)
		end
	end
	for i=1,len do
		self:UpdateItemData(i, list[i])
	end
	self.Grid:Reposition()
	self:Reposition(len)
end

function M:UpdateItemData(index, data)
	if not data then return end
	local cell = self.Items[index]
	if cell then 
		cell:UpdateData(data)
		cell:SetActive(true)
	end
end

function M:AddItem(index)
	local go = GameObject.Instantiate(self.Prefab)
	go:SetActive(true)
	local t = go.transform
	t.name = tostring(index)
	t.parent = self.Grid.transform
	t.localScale = Vector3.one
	t.localPosition = Vector3.zero
	local cell = ObjPool.Get(UISkyBookItem)
	cell:Init(go)
	table.insert(self.Items, cell)
end

function M:HideItem(index)
	local cell = self.Items[index]
	if cell then cell:SetActive(false) end
end

function M:SortGrid(a, b)
	local i1 = tonumber(a.name)
	local i2 = tonumber(b.name)
	local items = self.Items
	if items then
		local item1 = items[i1]
		local item2 = items[i2]
		if item1 and item2 then
			local s1 = item1:State()
			local s2 = item2:State()
			if s1 < s2 then
				return 1
			elseif s1 == s2 then
				if i1 > i2 then
					return  1
				elseif i1 == i2 then
					return 0
				end
			end
		end
	end
	return -1
end

function M:Reposition(len)
	if self.UISV then
		if len > 4 then
			self.UISV.isDrag = true
		else
			self.UISV.isDrag = false
		end
	end
end

function M:GetNum()
	local num = 0
	if self.Items then
		for i,v in ipairs(self.Items) do
			if v:IsReach() == true then
				num = num + 1
			end
		end
	end	
	return num
end
--------------------------------------------------------------

function M:OpenCustom()
	self:SelectTog(self:UpdateToggles())
	self:UpdateView()
	self:AddEvent()
end

function M:CloseCustom()
	self:RemoveEvent()
end

function M:ClearBookItem()
	if self.Items then
		for k,v in pairs(self.Items) do
			v:Dispose()
			ObjPool.Add(v)
			self.Items[k] = nil
		end
	end
end

function M:Clean()
	self.Index = "1"
	self:UnloadPic()
	self:UnloadSkillIcon()
end

function M:DisposeCustom()
	self:Clean()
	self:ClearBookItem()
	self.Index = nil
	if self.Togs then
		for i,v in ipairs(self.Togs) do
			self.Togs[i] = nil
		end
	end
	self.Togs = nil
	self.Pic = nil
end

return M

--endregion

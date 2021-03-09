--region UIPicCollectList.lua
--UIPicCollectList
--此文件由[HS]创建生成

UIPicCollectList = Super:New{Name="UIPicCollectList"}
local M = UIPicCollectList

local PCMgr = PicCollectMgr
M.eClickItem=Event()

--初始化控件
function M:Init(go, parent)
	self.Parent = parent
	local name = "UIPicCollectList"
	self.GO = go
	local trans = self.GO.transform
	self.GO.name = string.gsub(self.GO.name,"%(Clone%)","")
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Grid = C(UIGrid, trans, "Tween/Grid", name, false)
	self.Prefab = T(trans, "Tween/Grid/Item")
	self.Bg = C(UISprite, trans, "bg", name, false)
	self.Select = T(trans, "bg/Select")
	self.Title = C(UILabel, trans, "Title", name, false)
	self.PlayTween = C(UIPlayTween, trans, "bg", name, false)
	self.Tweener = C(UITweener, trans, "Tween", name, false)
	self.Action = T(trans, "Action")
	self.Items = {}

	UITool.SetLsnrSelf(self.Bg, self.OnClickBg, self, nil, false)

end

function M:OnClickBg(go)
	self:UpdateTitle(self.Tweener.IsForward)
end

function M:OpenDefault()
	self.PlayTween:Play(true)
	self:OnClickBg()
	local list = self.Items
	if list and #list > 0 then
		local defaultGroup = 1
		local parent = self.Parent
		if parent then
			if parent.DefaultGroup <= #list then
				defaultGroup = parent.DefaultGroup
			end
			parent:SelectPicGroup(list[defaultGroup].Root)
		end
	end
end

function M:UpdateData(tKey, tDic)
	self.Type = tKey
	if tDic == nil then return end
	self:Clean()
	local list = PCMgr:GetList(tDic)
	if not list then return end
	local len = #list
	local value = len == 0
	if value then 
		self.Grid:Reposition()
		return 
	end
	self:SetActive(true)
	for i=1,len do
		local gKey = list[i]
		if i == 1 then
			self:UpdateName(gKey)
		end
		self:AddItem(tKey, gKey, tDic[gKey])
	end

	self.Grid:Reposition()

	self:UpdateTitle(self.Tweener.gameObject.activeSelf)
	self:UpdateAction()
end

function M:UpdateName(gkey)
	local name = PCMgr:GetGroupName(gkey)
	if StrTool.IsNullOrEmpty(name) == true then return end
	local title = self.Title
	if title then
		title.text = name
	end
end

function M:AddItem(tKey, gKey, gDic)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = string.format("%s_%s_",tKey,gKey)
	local trans = go.transform
	trans.parent = self.Grid.transform
	trans.localPosition = Vector3.zero
	trans.localScale = Vector3.one
	go:SetActive(true)
	local T = TransTool.FindChild
	local data = {}
	data.Root = go
	data.Lable = ComTool.Get(UILabel, trans,"Label", "图鉴组分类", false)
	data.Lable.text = PCMgr:GetGroupName(gKey)
	data.Select = T(trans, "Select")
	data.Action = T(trans, "Action")
	table.insert(self.Items, data)
	local parent = self.Parent 
	if parent then
		UITool.SetLsnrSelf(go, parent.SelectPicGroup, parent, nil, false)
	end
end

function M:UpdateTitle(isForward)
	if LuaTool.IsNull(self.Select) == false then
		self.Select:SetActive(isForward)
	end
	--[[
	local name = nil
	if isForward then
		name = "ty_a15"
	else
		name = "ty_a4"
	end
	if not StrTool.IsNullOrEmpty(name) then 
		if self.Bg then
			self.Bg.spriteName = name
		end
	end
	]]--
end

function M:ShowSelect(name)
	local item = self.SelectItem
	local items = self.Items
	if not items then return end
	local len = #items
	if item and item.Select then
		item.Select:SetActive(false)
	end
	if StrTool.IsNullOrEmpty(name) then return end
	for i=1,len do
		if items[i].Root and items[i].Root.name == name then
			self.SelectItem = items[i]
			self.SelectItem.Select:SetActive(true)
		end
	end
end

function M:UpdateAction()
	local action = self.Action
	if action then
		action:SetActive(PCMgr:GetTypeToRed(self.Type))
	end
	local items = self.Items
	local len = #items
	for i=1,len do
		local v = items[i]
		local name = v.Root.name
		if StrTool.IsNullOrEmpty(name) == true then return end
		local keys = string.split(name, "_")
		local tkey = tonumber(keys[1])
		local gkey = tonumber(keys[2])
		v.Action:SetActive(PCMgr:GetGroupToRed(tkey, gkey))
	end
end

function M:SetActive(value)
	local root = self.GO
	if root then
		root:SetActive(value)
	end
end

function M:CleanCur()
end

--清楚数据
function M:Clean()
	if self.Items then
		local len = #self.Items
		while len > 0 do
			local data = self.Items[len]
			if LuaTool.IsNull(data.Root) == false then
				Destroy(data.Root)
			end
			TableTool.ClearDic(data)
			data = nil
			table.remove(self.Items, len)
			len = #self.Items
		end
	end
end

--释放或销毁
function M:Dispose()
	self:Clean()
	self.Count = nil
	self.Grid = nil
	self.Prefab = nil
end
--endregion

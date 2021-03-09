--region UIFriendList.lua
--UIFriendList
--此文件由[HS]创建生成

UIFriendList = Super:New{Name="UIFriendList"}
local M = UIFriendList
M.Menu = nil
M.Status = nil
M.eClickItem=Event()

--初始化控件
function M:Init(go, status)
	self.Status = status
	self.Name = "UIFriendList"
	self.GO = go
	self.trans = self.GO.transform
	self.GO.name = string.gsub(self.GO.name,"%(Clone%)","")
	self.GO:SetActive(true)
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Count = C(UILabel, self.trans, "Count", self.Name, false)
	self.Grid = C(UIGrid, self.trans, "Tween/Grid", self.Name, false)
	self.Prefab = T(self.trans, "Tween/Grid/Item")
	self.Bg = C(UISprite, self.trans, "bg", self.Name, false)
	self.Select = T(self.trans, "bg/Sprite")
	self.Title = C(UILabel, self.trans, "Title", self.Name, false)
	--self.Arr =  C(UIPlayTween, self.trans, "Arr", self.Name, false)
	self.PlayTween = C(UIPlayTween, self.trans, "bg", self.Name, false)
	self.Tweener = C(UITweener, self.trans, "Tween", self.Name, false)
	self.Items = {}

	UITool.SetLsnrSelf(self.Bg, self.OnClickBg, self, nil, false)

	FriendMgr.eRed:Add(self.OnChat,self)


end

function M:OpenDefault()
	self.PlayTween:Play(true)
	self:OnClickBg()
	local list = FriendMgr.ChatList
	if list and #list == 0 then return end
	local key = tostring(list[1].ID)
	local items = self.Items
	if items and items[key] then
		items[key]:OnClickCell()
	end
end

function M:OnChat(id)
	local cell = self.Items[id]
	if not cell then return end
	cell.red:SetActive(true)
end

function M:OnClickBg(go)
	self:UpdateTitle(self.Tweener.IsForward)
end

function M:UpdateTitle(isForward)
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
	if self.Select then
		self.Select:SetActive(not isForward)
	end
end

function M:UpdateData(list)
	if list == nil then return end
	self:Clean()
	local t = UITable
	local len = #list
	local num = FriendMgr:GetOnlineNum(list)
	self.Count.text = string.format("%s/%s",num,len)
	local value = len == 0
	if value then 
		self.Grid:Reposition()
		return 
	end
	for i=1,len do
		self:AddItem(list[i])
	end
	self.Grid:Reposition()
	if self.Status == FriendsType.Friend then
		local id = FriendMgr.TalkId
		if not id then return end
		self:UpdateTitle(true)
		local pt = self.PlayTween
		if pt and pt.isPlayStatus == false then 
			pt:Play(true) 
		end
		FriendMgr.TalkId = nil
		return
	end
	self:UpdateTitle(self.Tweener.gameObject.activeSelf)
end

function M:AddItem(v)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = string.gsub(go.name, "%(Clone%)", "")
	go.name = v.ID
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	local cell = ObjPool.Get(UICellAddFriend)
	cell:Init(go, true)
	cell:UpdateData(v)
	cell.ClickMenu:Add(self.ClickMenu, self)
	if cell == nil then return end
	self.Items[v.ID]=cell
	local state = FriendMgr.chatDic[v.ID] or false
	cell.red:SetActive(state)
end

function M:ClickMenu(data)
	if self.Menu then self.Menu:UpdateData(data, self.Status) end
end

function M:FriendlyUpdate(id, value)
	local items = self.Items
	if not items then return end
	local item = items[id]
	if not item then return end
	item:Familiarity(value)
end


function M:UpdateRedStatus(id, value)
	local dic = self.Items
	for k,v in pairs(dic) do
		if k == id then
			v.red:SetActive(value)
		end
	end
end


function M:CleanCur()
end

--清楚数据
function M:Clean()
	for k,v in pairs(self.Items) do
		v:Dispose(true)
		self.Items[k]=nil
	end
end

--释放或销毁
function M:Dispose(isDestory)
    FriendMgr.eRed:Remove(self.OnChat,self)
	self:Clean()
	self.Count = nil
	self.Grid = nil
	self.Prefab = nil
end
--endregion

--region UILogin.lua
--好友推荐UI
--此文件由[HS]创建生成

UIFriendsRecommend = UIBase:New{Name ="UIFriendsRecommend"}
local M = UIFriendsRecommend
local fMgr = FriendMgr
--注册的事件回调函数

function M:InitCustom()
	self.Persitent = true
	name = "lua好友推荐"
	local go = self.gbj
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.CloseBtn = C(UIButton, trans, "Close", name, false)
	self.SearchBtn = C(UIButton, trans, "Search", name, false)
	self.RefurbishBtn = C(UIButton, trans, "Refurbish", name, false)
	self.Input = C(UIInput, trans, "Input", name, false)

	self.ScrollView = C(UIScrollView, trans, "ScrollView", name, false)
	self.Grid = C(UIGrid, trans, "ScrollView/Grid", name, false)
	self.Prefab = T(trans,"ScrollView/Grid/Item")
	self.Items = {}
	for i=1,9 do
		self:AddItems(i)
	end
	self:Reposition()
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	local M = EventMgr.Add
	if self.CloseBtn then	
		E(self.CloseBtn, self.OnClickCloseBtn, self)
	end
	if self.SearchBtn then	
		E(self.SearchBtn, self.OnClickSearchBtn, self)
	end
	if self.RefurbishBtn then	
		E(self.RefurbishBtn, self.OnClickRefurbishBtn, self)
	end
	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	fMgr.eRecommendEnd[fn](fMgr.eRecommendEnd, self.UpdateFriend, self)
end

--查找好友
function M:SearchFriend(data)
	if data ~= nil then
		self:CleanItems()
		self.Items[1].gameObject:SetActive(true)
	else
		self:CleanItems()
	end
end

--推荐好友
function M:UpdateFriend()
	self:CleanItems()
	local list = FriendMgr.RecommendList
	if list == nil then return end
	local len = #list
	local iLen = #self.Items
	if len > iLen then
		for i= iLen + 1,len do
			self:AddItems(i)
		end
		self:Reposition()
	end
	for i=1,len do
		local item = self.Items[i]
		if item then
			item:UpdateData(list[i])
		end
	end
end

---------------------------------------------------
function M:AddItems(index)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = tostring(index)
	go:SetActive(true)
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	local item = ObjPool.Get(UICellAddFriend)
	item:Init(go, false)
	table.insert(self.Items, item)
end

function M:CleanItems()
	for i=1,#self.Items do
		self.Items[i]:Clean()
	end
end

function M:Reposition()
	if self.ScrollView and self.Grid then
		self.Grid:Reposition()
		if self.Grid:GetChildList().Count > 9 then
			self.ScrollView.isDrag = true
		else
			self.ScrollView.isDrag = false
		end
	end
end

-----------------------------------------------

	--打开效果
function M:OpenCustom()
	FriendMgr:ReqRecommendFriend()
end

	--关闭效果
function M:CloseCustom()
	self:CleanItems()
	--self:FinalClose()
end

function M:DisposeCustom()
	if self.Items then 
		for i,v in ipairs(self.Items) do
			table.remove(self.Items, i)
			v:Dispose()
			ObjPool.Add(v)
		end
	end
end

-------------按钮点击事件
--关闭面板
function M:OnClickCloseBtn(go)
	FriendMgr:ClearRecommend()
	self:Close()
end

--搜索
function M:OnClickSearchBtn(go)
	local name = self.Input.value
	if StrTool.IsNullOrEmpty(name) then
		UITip.Error("请输入需要查找的玩家名字")
		return
	end
	FriendMgr:ClearRecommend()
	FriendMgr:ReqSearchFriend(name)
end

--换一批
function M:OnClickRefurbishBtn(go)
	FriendMgr:ReqRecommendFriend()
end

return UIFriendsRecommend
--endregion

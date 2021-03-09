--region UIFriend.lua
--好友窗口
--此文件由[HS]创建生成
require("UI/UIFriend/UIFriendMenu")
require("UI/UIFriend/UIFriendList")
require("UI/UIFriend/ChatV")
require("UI/UIFriend/UIFamiliarityTip")
UIFriend = {}
local M = UIFriend

local fMgr = FriendMgr
M.Parent = nil

--构造函数
function M:New(go)
	local name = "UIFriend"
	self.go = go
	local trans = self.go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Add = C(UIButton, trans, "AddBtn", name, false)
	self.Request = C(UIButton, trans, "RequestBtn", name, false)
	self.Menu = UIFriendMenu:New(T(trans,"View"))
	self.Tb = C(UITable, trans, "List/Table", name, false)
	self.Talk = ObjPool.Get(UIFriendList)
	self.Talk:Init(T(trans, "List/Table/Quest3"), FriendsType.Chat)
	self.Talk.Menu = self.Menu
	self.Friend = ObjPool.Get(UIFriendList)
	self.Friend:Init(T(trans, "List/Table/Quest2"), FriendsType.Friend )
	self.Friend.Menu = self.Menu
	self.Black = ObjPool.Get(UIFriendList)
	self.Black:Init(T(trans, "List/Table/Quest1"), FriendsType.Black)
	self.Black.Menu = self.Menu
	
	self.FTip = UIFamiliarityTip:New(T(trans, "FamiliarityV"))
	
	self.SelectCell = nil

	self.ChatV = ObjPool.Get(ChatV)
	self.ChatV:Init(T(trans,"ChatV"))

	self:AddEvent()
	return M
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Add then	
		E(self.Add, self.OnAddBtn, self)
	end
	if self.Request then	
		E(self.Request, self.OnRequestBtn, self)
	end
	self:SetLsnr(fMgr,"Add")

	UICellAddFriend.eClickCell:Add(self.ClickItem,self)
	UICellAddFriend.eClickFamiliar:Add(self.ClickFamiliar,self)
end

function M:RemoveEvent()
	self:SetLsnr(fMgr,"Remove")
	UICellAddFriend.eClickCell:Remove(self.ClickItem,self)
	UICellAddFriend.eClickFamiliar:Add(self.ClickFamiliar,self)
end

--设置监听
--fn(string):注册/注销名
function M:SetLsnr(t,fn)
	t.eUpdateChat[fn](t.eUpdateChat, self.UpdateChat, self)
  t.eUpdateFriend[fn](t.eUpdateFriend, self.UpdateFriend, self)
  t.eUpdateBlack[fn](t.eUpdateBlack, self.UpdateBlack, self)
  t.eFriendlyUpdate[fn](t.eFriendlyUpdate, self.FriendlyUpdate, self)
 -- t.eUpdateRequest[fn](t.eUpdateRequest, self.UpdateRequest, self)
end

-----------------------更新数据----------------------------
function M:ShowChat()
	local listView = self.Talk
	if not listView then return end
	listView:OpenDefault()
end

function M:Open()
	self:UpdateChat()
	self:UpdateFriend()
	self:UpdateBlack()
--	self:UpdateRequest()
	self:ShowChat()
	UserMgr.eUpdateData:Add(self.UpdateChaData, self)
end

function M:Close()
	if self.Talk then
		self.Talk:CleanCur()
	end
	if self.Friend then
		self.Friend:CleanCur()
	end
	if self.Black then
		self.Black:CleanCur()
	end
	if self.FTip then
		self.FTip:SetActive(false)
	end
	self.SelectCell = nil
	UserMgr.eUpdateData:Remove(self.UpdateChaData, self)
end

function M:UpdateChat()
	self.SelectCell = nil
	if self.Talk then
		self.Talk:UpdateData(fMgr.ChatList)
	end
	if self.Tb then
		self.Tb:Reposition()
	end
end

function M:UpdateFriend()
	self.SelectCell = nil
	if self.Friend then
		self.Friend:UpdateData(fMgr.FriendList)
	end
	-- if self.ChatV then
	-- 	self.ChatV:CleanData()
	-- end
	if self.Tb then
		self.Tb:Reposition()
	end
end

function M:UpdateBlack()
	self.SelectCell = nil
	if self.Black then
		self.Black:UpdateData(fMgr.BlackList)
	end
	if self.Tb then
		self.Tb:Reposition()
	end
end

function M:FriendlyUpdate(id, v)
	self:FriendlyUpdateUI(self.Friend, id, v)
	self:FriendlyUpdateUI(self.Talk, id, v)
	self:FriendlyUpdateUI(self.Black, id, v)
end

function M:FriendlyUpdateUI(view, id, v)
	if not view then return end
	view:FriendlyUpdate(id, v)
end

--[[
function M:UpdateRequest()
	if self.Request then
		self.Request:UpdateData(fMgr.RequestList)
	end
	if self.Tb then
		self.Tb:Reposition()
	end
end
]]--

function M:ClickItem(cell, data)
	local dic = fMgr.chatDic
	if self.SelectCell then
		self.SelectCell:SetActive(false)
	end
	cell:SetActive(true)
	cell.red:SetActive(false)
	local id = data.ID
	if self.Talk then self.Talk:UpdateRedStatus(id, false) end
	if self.Friend then self.Friend:UpdateRedStatus(id, false) end
	dic[id]=false
	self.SelectCell = cell
	self.ChatV:UpDta(data)

	local state = false
	for k,v in pairs(dic) do
		if v==true then 
			state=true 
			break 
		end
	end
	fMgr.eRed(-1,state)
end

function M:ClickFamiliar(temp, value)
	if self.FTip then
		self.FTip:UpdateData(temp, value)
		self.FTip:SetActive(true)
	end
end
-----------------------------------------------

--添加
function M:OnAddBtn(go)
	UIMgr.Open(UIFriendsRecommend.Name)
end

function M:OnRequestBtn(go)
	UIMgr.Open(UIFriendRequest.Name)
	local parent = self.Parent
	if parent then parent:Close() end
end

function M:UpdateChaData()
	UIMgr.Open(UIOtherInfoCPM.Name)
end

--释放或销毁
function M:Dispose()
	self:RemoveEvent()
	if self.Talk then
		ObjPool.Add(self.Talk)
	end
	if self.Friend then
		ObjPool.Add(self.Friend)
	end
	if self.Black then
		ObjPool.Add(self.Black)
	end
	if self.ChatV then
		ObjPool.Add(self.ChatV)
	end
	if self.FTip then
		self.FTip = nil
	end
end
--endregion

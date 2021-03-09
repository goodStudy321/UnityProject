--region UIFriendMenu.lua
--好友菜单
--此文件由[HS]创建生成

UIFriendMenu = {}
local M = UIFriendMenu

M.MenuTitles = {"添加好友","邀请组队","查看资料","送花","邀请加入道庭","加入黑名单","移出黑名单","删除"}
M.MenuFriend = {2,3,4,5,6,8}
M.MenuBlack = {3,7}
M.MenuRequest = {1,2,3,5,6,8}
M.MenuChat = {2,3,4,5,6,8}

M.BaseH = 138
M.MenuH = 64


function M:New(go)
	local name = "UIFriend"
	self.go = go
	local name = "好友菜单"
	local trans = self.go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.BG = C(UISprite, trans, "bg", name, false)
	self.Icon = C(UITexture, trans, "Icon", name, false)
	self.Label = C(UILabel, trans, "Label", name, false)
	self.LV = C(UILabel, trans, "LV", name, false)
	self.Family = C(UILabel, trans, "Family", name, false)
	self.Menus = {}
	for i=1,6 do
		local data = {}
		local key = "Btn"..i
		data.Root = T(trans, key)
		data.Label = C(UILabel, trans, key.."/Label", name, false)
		data.Root.name = i
		table.insert( self.Menus, data )
	end
	self:AddEvent()
	return M
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	local list = self.Menus
	local len = #list
	for i=1,len do
		E(list[i].Root, self.OnClickBtn, self, nil, false)
	end
	if self.go then	
		E(self.go, self.OnClickCloseBtn, self, nil, false)
	end
end

function M:RemoveEvent()
end

function M:OnClickBtn(go)
	local len = string.len(go.name)
	local index = tonumber(string.sub(go.name,len))
	local data = nil 
	if not self.Data then return end
	if self.Menus and self.Menus[index] then data = self.Menus[index] end
	local value = false
	if data then
		local key = data.Label.text
		value = self:Active(key, self.Data.ID)
	end
	if not value then
		self:Close()
	else
		UIMgr.Close(UIInteractPanel.Name)
	end
end

function M:Active(key,id)
	if key == "添加好友" then
		FriendMgr:ReqAddFriend(id)
	elseif key == "邀请组队" then
		TeamMgr:ReqInviteTeam(id)
	elseif key == "查看资料" then
		UserMgr:ReqRoleObserve(tonumber(id))
	elseif key == "送花" then
		local data, index = FriendMgr:GetFriendByID(id)
		if not data or data.Online == false then
			UITip.Error("好友离线中，不能送花")
			return
		end
		FlowersMgr:OpenUI(1, id)
		return true
	elseif key == "邀请加入道庭" then
		FamilyMgr:ReqFamilyInvite(id)
	elseif key == "加入黑名单" then
		FriendMgr:ReqFriendAddBlack(id)
	elseif key == "移出黑名单" then
		FriendMgr:ReqFriendDelBlack(id)
	elseif key == "删除" then
		FriendMgr:ReqDelFriend(id)
	end
	return false
end

function M:OnClickCloseBtn(go)
	self:Close()
end

function M:Close()
	local list = self.Menus
	if list then
		local len = #list
		if len >0 then
			for i=1,len do
				list[i].Root:SetActive(false)
			end
		end
	end
	if self.BG then
		self.BG.height = self.BaseH
	end
	self:Clear()
	self.Data = nil
	self.go:SetActive(false)
end

-----------------------更新数据----------------------------
function M:UpdateData(data, status)
	self.Status = status
	if data then  
		self.go:SetActive(true)
		self.Data = data
		self:UpdateIcon(string.format( "tx_0%s.png", data.Category))
		local name = data.Name
		if self.Data.Online == true then 
			name = name.." [ADFF2F]在线[-]"
		else
			name = name.." [919191]离线[-]"
		end
		self:UpdateLabel(name)
		self:UpdateLV(data.Level)
		self:UpdateFamily(data.FName)
	end
	self:UpdateMenu()
end

function M:UpdateMenu()
	local s = self.Status
	local t = nil
	local ft = FriendsType
	if s  == ft.Request then
		t = self.MenuRequest
	elseif s == ft.Friend then
		t = self.MenuFriend
	elseif s == ft.Black then
		t = self.MenuBlack
	elseif s == ft.Chat then
		t = self.MenuChat
	end
	if t then 
		local len = #t
		for i=1,len do
			local menu = self.Menus[i]
			if menu then
				local index = t[i]
				local title = self.MenuTitles[index]
				if title then
					menu.Label.text = title
					menu.Root:SetActive(true)
				end
			end
		end
	if self.BG then
		self.BG.height = self.BaseH + self.MenuH * len + 20
	end
	end
end

--更新Icon
function M:UpdateIcon(path)
	if self.Icon then
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

function M:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = tex
	end
end

function M:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

--更新Label
function M:UpdateLabel(value)
	if self.Label then
		if value ~= 0 then
			self.Label.text = value
		else
			self.Label.text = ""
		end
	end
end

--更新玩家等级
function M:UpdateLV(lv)
	if self.LV then
		self.LV.text = tostring(lv)
		self.LV.gameObject:SetActive(true)
	end
end

--更新玩家等级
function M:UpdateFamily(value)
	if StrTool.IsNullOrEmpty(value) then value = "无" end
	if self.Family then
		self.Family.text = tostring(value)
	end
end

function M:Clear()
	self:UnloadIcon()
	if self.Icon then self.Icon.mainTexture = nil end
	if self.Label then self.Label.text = "" end
	if self.LV then self.LV.text = "" end
	if self.Family then self.Family.text = "" end
end
-----------------------------------------------

--释放或销毁
function M:Dispose()
	self:RemoveEvent()
end
--endregion

--region FriendMgr.lua
--Date
--此文件由[HS]创建生成

FriendMgr = {Name="FriendMgr"}
local M = FriendMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

M.FirendLimit = 50

M.eUpdateFriend = Event()
M.eUpdateBlack = Event()
M.eUpdateRequest = Event()
M.eUpdateChat = Event()
M.eRecommendEnd = Event()
M.eRed=Event()
M.eFriendlyUpdate = Event()


M.FriendList = {}	--好友
M.BlackList = {}	--黑名单
M.RequestList = {}	--好友请求
M.ChatList = {}		--最近聊天
M.RecommendList = {} --推荐好友
M.chatDic = {} --消息红点

function M:Init()
	self:AddProto()
end

function M:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
	ChatMgr.eAddChat:Add(self.SetRed,self)
end

function M:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
	ChatMgr.eAddChat:Remove(self.SetRed,self)
end

function M:ProtoHandler(Lsnr)
	Lsnr(21300, self.RespFriendInfo, self)	
	Lsnr(21302, self.RespFriendAdd, self)	
	Lsnr(21304, self.RespFriendSearch, self)	
	Lsnr(21312, self.RespFriendDel, self)	
	Lsnr(21314, self.RespRecommend, self)	
	Lsnr(21320, self.RespRequestInfo, self)	
	Lsnr(21322, self.RespRequestDel, self)	
	Lsnr(21324, self.RespRequestReject, self)	
	Lsnr(21332, self.RespBlackAdd, self)	
	Lsnr(21334, self.RespBlackDel, self)	
	Lsnr(21340, self.RespIsOnline, self)	
	Lsnr(21342, self.RespChatUpdate, self)	
	Lsnr(21344, self.RespLvUpdate, self)	
	Lsnr(21346, self.RespFriendlyUpdate, self)	
end

--[[#############################################################]]--

--邀请加入队伍返回
function M:RespFriendInfo(msg)
	self:UpdateList(msg.friend_list, 1)
	self:UpdateList(msg.black_list, 2)
	self:UpdateList(msg.request_list, 3)
	self:UpdateList(msg.chat_list, 4)
	self:ResetListSort(self.FriendList, 1)
	self:ResetListSort(self.BlackList, 2)
	self:ResetListSort(self.RequestList, 3)
	self:ResetListSort(self.ChatList, 4)
end

--添加好友回调
function M:RespFriendAdd(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local data = msg.friend_info
	if data then
		local id = data.role_id
		if id == 0 then return end
		local name = data.role_name
		local sex = data.sex
		local level = data.level
		local vip = data.vip_level
		local cate = data.category
		local friendly = data.friendly
		local isOnline = data.is_online
		local fName = data.family_name
		local coupleId = data.couple_id
		self:AddPlayerList(id, name, sex, level, cate, friendly, vip, isOnline, coupleId, fName, self.FriendList)
		self:ResetListSort(self.FriendList, 1)
		if self:DelPlayerList(self.RequestList, id) == true then
			self:ResetListSort(self.RequestList, 3)
		end
		if self:DelPlayerList(self.RecommendList, id) == true then
			self:ResetListSort(self.RecommendList, 5)
		end
	end
end

--搜索好友返回
function M:RespFriendSearch(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local data = msg.friend_info
	if data then
		local id = data.role_id
		local name = data.role_name
		local sex = data.sex
		local level = data.level
		local vip = data.vip_level
		local cate = data.category
		local lv = data.friendly
		local isOnline = data.is_online
		local fName = data.family_name
		local coupleId = data.couple_id
		self:AddPlayerList(id, name, sex, level, cate, friendly, vip, isOnline, coupleId, fName, self.RecommendList)
		self:ResetListSort(self.RecommendList, 5)
	end
end

--删除好友返回
function M:RespFriendDel(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local id = msg.role_id
	if self:DelPlayerList(self.FriendList, id) == true then
		self:ResetListSort(self.FriendList, 1)
	end
	if self:DelPlayerList(self.ChatList , id) == true then
		self:ResetListSort(self.ChatList, 4)
	end
end

--好友推荐返回
function M:RespRecommend(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	self:UpdateList(msg.recommend_list, 5)
	self:ResetListSort(self.RecommendList, 5)
end

--好友请求
function M:RespRequestInfo(msg)
	local data = msg.request_info
	if data then
		local id = data.role_id
		local name = data.role_name
		local sex = data.sex
		local level = data.level
		local vip = data.vip_level
		local cate = data.category
		local friendly = data.friendly
		local isOnline = data.is_online
		local fName = data.family_name
		local coupleId = data.couple_id
		self:AddPlayerList(id, name, sex, level, cate, friendly, vip, isOnline, coupleId, fName, self.RequestList)
		self:ResetListSort(self.RequestList, 3)
	end
end

--删除好友申请人返回
function M:RespRequestDel(msg)
	if self:DelPlayerList(self.RequestList, msg.request_id) == true then
		self:ResetListSort(self.RequestList, 3)
	end
end

--拒绝添加好友返回
function M:RespRequestReject(msg)
	UITip.Error(string.format("%s拒绝了你的好友申请", msg.from_role_name))
end

--加入黑名单返回
function M:RespBlackAdd(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local data = msg.black_info
	if data then
		local id = data.role_id
		local name = data.role_name
		local sex = data.sex
		local level = data.level
		local vip = data.vip_level
		local cate = data.category
		local lv = data.friendly
		local isOnline = data.is_online
		local fName = data.family_name
		local coupleId = data.couple_id
		self:AddPlayerList(id, name, sex, level, cate, lv, vip, isOnline, coupleId, fName, self.BlackList)
		self:ResetListSort(self.BlackList, 2)
		if self:DelPlayerList(self.FriendList, id) == true then
			self:ResetListSort(self.FriendList, 1)
		end
		if self:DelPlayerList(self.RequestList, id) == true then
			self:ResetListSort(self.RequestList, 3)
		end
	end
end

--移除黑名单返回
function M:RespBlackDel(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	if self:DelPlayerList(self.BlackList, msg.black_id) == true then 
		self:ResetListSort(self.BlackList, 2)
	end
end

--更新在线状态
function M:RespIsOnline(msg)
	self:UpdateFriendIsOnline(msg.role_id, msg.is_online)
end

--最近联系更新
function M:RespChatUpdate(msg)
	local data = msg.friend_info
	if data then
		if self:UpdateLvInfo(self.ChatList, data) == false then
			local id = data.role_id
			local name = data.role_name
			local sex = data.sex
			local level = data.level
			local vip = data.vip_level
			local cate = data.category
			local lv = data.friendly
			local isOnline = data.is_online
			local fName = data.family_name
			local coupleId = data.couple_id
			self:AddPlayerList(id, name , sex, level, cate, lv, vip, isOnline, coupleId, fName, self.ChatList)
			self:ResetListSort(self.ChatList, 4)
		end
		self.eUpdateChat()
	end
end

--等级更新
function M:RespLvUpdate(msg)
	local data = msg.friend_info
	if data then
		if self:UpdateLvInfo(self.FriendList, data) == true then
			self:ResetListSort(self.FriendList, 3)
		end
		if self:UpdateLvInfo(self.BlackList, data) == true then
			self:ResetListSort(self.BlackList, 2)
		end
	end
end

--亲密度更新
function M:RespFriendlyUpdate(msg)
	local id = msg.friend_id
	local friendly = msg.friendly
	self:UpdateFriendly(id, self.FriendList, friendly)
	self:UpdateFriendly(id, self.BlackList, friendly)
	self.eFriendlyUpdate(id, friendly)
end

----------------------------------------------------------------
--添加好友
function M:ReqAddFriend(id)
	local msg = ProtoPool.GetByID(21301)
	msg.role_id = id
	Send(msg)
end

--搜索好友
function M:ReqSearchFriend(name)
	local msg = ProtoPool.GetByID(21303)
	msg.role_name = name
	Send(msg)
end

--删除好友
function M:ReqDelFriend(id)
	local msg = ProtoPool.GetByID(21311)
	msg.role_id = id
	Send(msg)
end

--好友推荐
function M:ReqRecommendFriend()
	self:ClearRecommend()
	local msg = ProtoPool.GetByID(21313)
	Send(msg)
end

--删除好友申请人信息
function M:ReqDelRequestFriend(id)
	local msg = ProtoPool.GetByID(21321)
	msg.request_id = id
	Send(msg)
end

--加入黑名单
function M:ReqFriendAddBlack(id)
	local msg = ProtoPool.GetByID(21331)
	msg.black_id = id
	Send(msg)
end

--移除黑名单
function M:ReqFriendDelBlack(id)
	local msg = ProtoPool.GetByID(21333)
	msg.black_id = id
	Send(msg)
end

--[[################################私有 开始#############################]]--
--更新好友列表
function M:UpdateList(list, type)
	local len = #list
	for i=1,len do
		local data = list[i]
		if data then
			local id = data.role_id
			local name = data.role_name
			local sex = data.sex
			local level = data.level
			local vip = data.vip_level
			local cate = data.category
			local lv = data.friendly
			local isOnline = data.is_online
			local fName = data.family_name
			local coupleId = data.couple_id
			if type == 1 then
				self:AddPlayerList(id, name, sex, level, cate, lv, vip, isOnline, coupleId, fName, self.FriendList)
			elseif type == 2 then
				self:AddPlayerList(id, name, sex, level, cate, lv, vip, isOnline, coupleId, fName, self.BlackList)
			elseif type == 3 then
				self:AddPlayerList(id, name, sex, level, cate, lv, vip, isOnline, coupleId, fName, self.RequestList)
			elseif type == 4 then
				self:AddPlayerList(id, name , sex, level, cate, lv, vip, isOnline, coupleId, fName, self.ChatList)
			elseif type == 5 then
				self:AddPlayerList(id, name, sex, level, cate, lv, vip, isOnline, coupleId, fName, self.RecommendList)
			end
		end
	end
end

--获取玩家数据Tabel
function M:AddPlayerList(id, name, sex, lv, category, friendly, vip, online, coupleId, fName, list)
	if not list then 
		iTrace.eError("hs", string.format("添加玩家数据目标队列{%s}为nil", t))
		return 
	end
	local data = {}
	data.ID = id
	data.Name = name
	data.Sex = sex
	data.Level = lv
	data.Category = category
	data.Friendly = friendly
	data.VIP = vip
	data.Online = online
	data.FName = fName
	data.CoupleID = coupleId
	table.insert(list, data)
end

--更新好友数据
function M:UpdateLvInfo(list, data)
	for i,v in ipairs(list) do
		if v.ID == data.role_id then
			list[i].ID = data.role_id
			list[i].Name = data.role_name
			list[i].Sex = data.sex
			list[i].Level = data.level
			list[i].Category = data.category
			--list[i].Friendly = data.friendly 
			list[i].VIP = data.vip_level
			list[i].Online = data.is_online
			list[i].FName = data.family_name
			list[i].CoupleID = data.couple_id
			return true
		end
	end
	return false
end

--更新在线状态
function M:UpdateFriendIsOnline(id, isOnline)
	if self:SetOnline(self.FriendList, id, isOnline) == true then
		self:ResetListSort(self.FriendList, 1)
	end
	if self:SetOnline(self.BlackList, id, isOnline) == true then
		self:ResetListSort(self.BlackList, 2)
	end
	if self:SetOnline(self.RequestList, id, isOnline) == true then
		self:ResetListSort(self.RequestList, 3)
	end
	if self:SetOnline(self.ChatList, id, isOnline) == true then
		self:ResetListSort(self.ChatList, 4)
	end
end

--设置在线状态
function M:SetOnline(list, id, isOnline)
	if list then 
		local len = #list
		for i=1,len do
			if list and list[i] and list[i].ID == id then
				list[i].Online = isOnline
				return true
			end
		end
	end
	return false
end

--删除队列
function M:DelPlayerList(list, id)
	if id == 0 then return end
	local data, index = self:GetListIndex(list, id)
	if index then
		table.remove(list, index)
		return true
	end
	return false
end

--重置列表排序
function M:ResetListSort(list, t)
	if list and #list > 1 then
		table.sort(list, function(a, b)
			return self:SortFunc(a, b)
		end)
	end
	if t == 1 then
		self.eUpdateFriend()
	elseif t == 2 then
		self.eUpdateBlack()
	elseif t == 3 then
		self.eUpdateRequest()
	elseif t == 4 then
		self.eUpdateChat()
	elseif t == 5 then
		self.eRecommendEnd()
	end
end

--获取队列索引
function M:GetListIndex(list, id)
	if list then
		for i,v in ipairs(list) do
			if v and v.ID == id then
				return v, i
			end
		end
	end
	return nil, nil
end

--排序
function M:SortFunc(a, b)
	if not a or not b then return false end
	if a.ID == b.ID then return false end
	if a.Online == true and b.Online == false then 
		return true  
	elseif a.Online == false and b.Online == true then
		return false
	end
	if a.Friendly > b.Friendly then
		return true
	elseif a.Friendly < b.Friendly then
		return false
	end
	return tonumber(a.ID) > tonumber(b.ID)
end

--更新好友亲密度
function M:UpdateFriendly(id, list, value)
	if not list or #list <= 0 then return end
	for i=1,#list do
		local friend = list[i]
		if friend.ID == id then
			friend.Friendly = value
		end
	end
end

--[[################################私有 结束#############################]]--

function M:ClearRecommend()
	self:ClearList(self.RecommendList)
	self:ResetListSort(self.BlackList, 2)
	self:ResetListSort(self.RecommendList, 5)
end

function M:GetOnlineNum(list)
	local num = 0
	if list then 
		local len = #list
		if len == 0 then return num end
		for i=1,len do
			if list[i] and list[i].Online == true then
				num = num + 1
			end
		end
	end
	return num
end


function M:GetFriendByID(id)
	if not id then return end
	id = tostring(id)
	for i,v in ipairs(self.FriendList) do
		if v.ID == id then
			return v,i
		end
	end
	return nil, -1
end

function M:GetFriendByIDStr(strId)
	if not strId or strId == "" then return end
	for i,v in ipairs(self.FriendList) do
		local curId = v.ID
		if curId == strId then
			return v,i
		end
	end
	return nil, -1
end

function M:IsFriend(id)
	for i,v in ipairs(self.FriendList) do
		if v.ID == id then
			return true
		end
	end
	return false
end

function M:GetFamiliarty(value)
	local temp = nil
	for i=1,#FamiliarityTemp do
		if value <= FamiliarityTemp[i].need then
			break
		end
		temp = FamiliarityTemp[i]
	end
	return temp
end

function M:ClickMenuTip(str, id)
	if str == "添加好友" then
		self:ReqAddFriend(id)
	elseif str == "删除好友" then
		self:ReqDelFriend(id)
	elseif str == "加入黑名单" then
		self:ReqFriendAddBlack(id)
	elseif str == "移除黑名单" then
		self:ReqFriendDelBlack(id)
	elseif str == "邀请组队" then
		TeamMgr:ReqInviteTeam(id)
	elseif str == "送花" then
		local data, index = self:GetFriendByID(id)
		if not data or data.Online == false then
			UITip.Error("好友离线中，不能送花")
			return
		end
		FlowersMgr:OpenUI(1)
	end
end

--好友消息红点
function M:SetRed(tp,index,tb)
	if tp~=4 then return end
	local id = tostring(tb.cId)
	if tb.info.rId~=tostring(User.instance.MapData.UID) then
		M.chatDic[id]=true
		M.eRed(id,true)
	end
end

function M:Clear()
	self:ClearList(self.FriendList)
	self:ClearList(self.BlackList)
	self:ClearList(self.RequestList)
	self:ClearList(self.ChatList)
	self:ClearList(self.RecommendList)
end

function M:ClearList(list)
	TableTool.ClearDic(list)
end

function M:Dispose()
	self:RemoveProto()
end

return M
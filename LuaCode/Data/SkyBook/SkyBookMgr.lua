--region SkyBookMgr.lua
--Date
--此文件由[HS]创建生成

SkyBookMgr = {Name="SkyBookMgr"}
local M = SkyBookMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr
local SMgr = SystemMgr
local aMgr = ActivityMgr

local SBTemp = ActivityTemp["119"]
M.eUpdate = Event()
M.eGetReward = Event()
M.eGetTypeReward = Event()

function M:Init()
	self.TypeDic = {}
	self.Rewards = {}
	self.CurReward = nil
	self.IsClose = false
	self:InitData()
	self:AddEvent()
end

function M:InitData()
	local tTemp = SkyBookTypeTemp
	if not tTemp then return end
	for k,v in pairs(tTemp) do
		self:AddTypeData(v)
	end
	local temp = SkyBookTemp
	if not temp then return end
	for k,v in pairs(temp) do
		self:AddData(v)
	end
	for k,v in pairs(self.TypeDic) do
		self:SortList(v.List)
	end
end

function M:AddTypeData(temp)
	local t = temp.type
	if not self.TypeDic then return end
	self.TypeDic[tostring(t)] = {}
	self.TypeDic[tostring(t)].Temp = temp
	self.TypeDic[tostring(t)].List = {}
	self.TypeDic[tostring(t)].Reward = false
end

function M:AddData(temp)
	local t = temp.type
	local data = self.TypeDic[tostring(t)]
	if not data or not data.List then return end
	local child = {}
	child.id = temp.id
	child.Temp = temp
	table.insert(data.List, child)
end

function M:SortList(list)
	table.sort(list, function (a, b) return a.id < b.id end)
end

function M:AddEvent()
	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveEvent()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:UpdateEvent(M)	
	--M("OnChangeLv", self.OnChangeLevel)
	--M("InitOwner", self.OnInitOwner)
end

function M:SetEvent(fn)
	UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.UpdateBtnAction, self)
	UserMgr.eLvUpdate[fn](UserMgr.eLvUpdate, self.UpdateBtnAction, self)
	--SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent, self.OnChangeScene, self)
end

function M:ProtoHandler(Lsnr)
	Lsnr(22200, self.RespSkyBook, self)	
	Lsnr(22202, self.RespSkyBookUpdate, self)	
	Lsnr(22204, self.SkyBookReward, self)	
	Lsnr(22206, self.SkyBookTypeReward, self)	
end
-----------------------------------------------------
--天书信息
function M:RespSkyBook(msg)
	local kvl = msg.doing_list
	for i,v in ipairs(kvl) do
		self:UpdateSkyBookStatus(v)
	end
	local rewards = msg.reward_list
	for i,v in ipairs(rewards) do
		table.insert(self.Rewards, v)
	end
	local tList = msg.type_reward_list
	for i,v in ipairs(tList) do
		local info = self.TypeDic[tostring(v)]
		if info then
			info.Reward = true
		end
	end
	self.IsClose = self:CheckReward()
	if self.IsClose == true then
		ActivityMgr:Remove(SBTemp)
	end
	self:UpdateBtnAction()
end

--天书信息更新
function M:RespSkyBookUpdate(msg)
	local kvl = msg.doing
	for i,v in ipairs(kvl) do
		local k, index, id = self:UpdateSkyBookStatus(v)
		if k and id then
			self.eUpdate(k, index, id)
		end
	end
	self:UpdateBtnAction()
end

function M:SkyBookReward(msg)
	if not CheckErr(msg.err_code) then return end
	local id = msg.id
	for i,v in ipairs(self.Rewards) do
		if v == id then return end
	end
	self:ShowReward(id)
	table.insert(self.Rewards, id)
	self.eGetReward(id)
	self:UpdateBtnAction()
end

function M:SkyBookTypeReward(msg)
	if not CheckErr(msg.err_code) then return end
	local t = msg.type_id
	local info = self.TypeDic[tostring(t)]
	if info then
		info.Reward = true
		self.eGetTypeReward(t)
	end
	self.IsClose = self:CheckReward()
	if self.IsClose == true then
		ActivityMgr:Remove(SBTemp)
	end
	self:UpdateBtnAction()
end
------------------------------------------------------
--领取奖励
function M:ReqGetReward(id)
	local msg = ProtoPool.GetByID(22203)
	msg.id = id
	Send(msg)
end

function M:ReqGetTypeReward(t)
	local msg = ProtoPool.GetByID(22205)
	msg.type_id = t
	Send(msg)
end
------------------------------------------------------
function M:ShowReward(id)
	local temp = SkyBookTemp[tostring(id)]
	if not temp then return end
	local reward = temp.reward
	if not reward then return end
	self.CurReward = reward
	UIMgr.Open(UIGetRewardPanel.Name, self.OnShowReward, self)
end

function M:OnShowReward(name)
	local ui = UIMgr.Dic[name]
	if ui then
		local reward  = self.CurReward
		if reward then
			list = {}
			local data = {}
			data.k = reward.k
			data.v = reward.v
			data.b = false
			table.insert(list,data)
		end
		if list then
			ui:UpdateData(list)
		else
			ui:Close()
		end
	end
	self.CurReward = nil
end

--完成状态
function M:UpdateSkyBookStatus(data)
	local id = data.id
	local list = data.list
	if #list == 0 then return end
	local temp = SkyBookTemp[tostring(id)]
	if temp then
		local key = tostring(temp.type)
		local dic = self.TypeDic[key]
		if dic then
			local datas = dic.List
			if datas then
				for i,v in ipairs(datas) do
					if v.id == id then
						self.TypeDic[key].List[i].List = list
						return temp.type, i, id
					end
				end
			end
		end
	end
	return nil,nil,nil
end
function M:CheckReward()
	for k,v in pairs(self.TypeDic) do
		if v.Reward == false then return false end
	end
	return true
end

function M:UpdateBtnAction()
	local state = self:IsCheck()
	if state == true then
		SMgr:ShowActivity(aMgr.TS)
	else
		SMgr:HideActivity(aMgr.TS)
	end
end

function M:IsCheck()
	if aMgr:CheckLv(aMgr.TS) == false then return false end
	for k,v in pairs(SkyBookTemp) do	
		local isOpen = self:IsOpen(v.type, false)
		if isOpen == true then
			if self:IsCheckType(v) == true then
				return true
			end
		end
	end
	return false
end

function M:IsCheckType(info)
	local key = tostring(info.type)
	local dic = self.TypeDic[key]
	if dic then
		local index = 0
		local datas = dic.List
		if datas then
			for i,v in ipairs(datas) do
				if v.List then
					local temp = v.Temp
					local cur,max = self:IsStatus(temp.condition, temp.param, v.List)
					if cur >= max then
						index = index + 1
						if not self:IsGetReward(temp.id) then
							return true
						end
					end
				end
			end
			if dic.Reward == false then
				if index == #datas then
					return true
				end
			end
		end
	end
	return false
end

function M:IsGetReward(id)
	if self.Rewards then
		for i,v in ipairs(self.Rewards) do
			if id == v then
				return true
			end
		end
	end
	return false
end

function M:IsStatus(t, params, list)
	local md = User.MapData
	local cur = 0
	local max = 1
	local len = 0
	local satisfy = nil
	local ti = 0
	if list then len = #list end
	if t == 1 then
		ti = 1
		cur = md:GetBaseProperty(ProType.Def)
		max = params[1]
		if icons then w = #icons end
	elseif t == 2 then
		ti = 1
		if len > 0 then
			cur = 1
		end
	elseif t== 3 then
		cur = len
		max = #params
		ti = 2
		satisfy = list
	elseif t== 4 then
		ti = 3
		if len > 0 then cur = list[1] end
		max = params[1]
	elseif t == 5 then
		ti = 3
		if len > 0 then cur = list[1] end
		max = params[1]
	elseif t == 6 then
		ti = 3
		max = params[1]
		if len > 0 then 
			cur = list[1] 
		else 
			cur = VIPMgr.GetVIPLv() 
		end
	elseif t == 7 then
		ti = 3
		if len > 0 then cur = list[1] end
		max = params[1]
	elseif t == 8 then
		ti = 3
		if len > 0 then cur = list[1] end
		max = params[1]
	elseif t == 10 then
		ti = 3
		if len > 0 then cur = list[1] end
		max = params[1]
	elseif t >= 11 and t <= 16 then
		ti = 4
		if len > 0 then cur = list[1] end
		max = params[1]
	end
	return tonumber(cur),max,ti,satisfy
end

function M:IsOpen(i, isShowTip)
	local temp = SkyBookTypeTemp[tostring(i)]
	if not temp then return false end
	local t = temp.open
	if t then
		if t == 1 then
			local lv = temp.value
			if StrTool.IsNullOrEmpty(lv) == true then lv = 0 end
			if User.MapData.Level < lv then 
				if isShowTip then
					UITip.Error(string.format("等级不足，%s级开启", lv))
				end
				return false 
			end
		elseif t == 2 then
			local pre = temp.value
			if pre then
				local data = self.TypeDic[tostring(pre)]
				if data then
					local list = data.List
					if list then
						for i,v in ipairs(list) do
							if v.List then
								local temp = v.Temp
								local cur,max = self:IsStatus(temp.type, temp.param, v.List)
								if cur < max then
									if isShowTip then
										UITip.Error(string.format("[%s]未完成", data.Temp.name))
									end
									return false
								end
							end
						end
					end
				end
			end
		end
	end
	return true
end

function M:GuideUI(condition)
	if condition == 4 then --首冲
		UIFirstPay:OpenFirsyPay()
	elseif condition == 5 then --月卡
		VIPMgr.OpenVIP(2)
	elseif condition == 6 then --vip
		VIPMgr.OpenVIP(5)
	elseif condition == 7 then --小鬼/仙女
		StoreMgr.OpenStore(2)
	elseif condition == 8 then --投资
		VIPMgr.OpenVIP(3)
	elseif condition == 10 then --武器时装
		UIMgr.Open(UIFashionPanel.Name, self.OpenWeapon, self)
	elseif condition >= 11 and condition <= 16 then
		SuitMgr.OpenSuit()
	end
end

function M:ClickMenuTipAction(key)
	if key == "寻宝" then
		UIMgr.Open(UITreasure.Name)
	elseif key == "装备副本" then
		-- UIMgr.Open(UICopy.Name, self.OpenCopy, self)
		UICopy:Show(CopyType.Equip)
	elseif key == "BOSS" then
		UIMgr.Open(UIBoss.Name)
	end
end

function M:OpenWeapon(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:ClickToggle(2)
	end
end

-- function M:OpenCopy(name)
-- 	local ui = UIMgr.Get(name)
-- 	if ui then 
-- 		ui:SetPage(3)
-- 	end
-- end


function M:Clear()
	if self.TypeDic then
		for k,v in pairs(self.TypeDic) do
			self.TypeDic[k].Reward = false
			for i,j in ipairs(self.TypeDic[k].List) do
				self.TypeDic[k].List[i].List = nil
			end
		end
	end
	TableTool.ClearDic(self.Rewards)
	self.CurReward = nil
end

function M:Dispose()
end

return M
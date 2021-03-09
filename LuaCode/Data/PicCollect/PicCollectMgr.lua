--region PicCollectMgr.lua
--Date
--此文件由[HS]创建生成

PicCollectMgr = {Name="PicCollectMgr"}
local M = PicCollectMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr
local SMgr = SystemMgr
local aMgr = ActivityMgr

local Temp = PicCollectTemp
local ProTemp = PicCollectGroupProTemp

M.ResolveUseEff = 63
M.PicEXP = {1201,1202,1203,1204,1205}
M.FullLv = 5
M.FullStar = 5

M.eUpdatePic = Event()
M.ePicEssence= Event()
M.eGroupActive = Event()
M.ePicRed = Event()	
M.eResolveRed = Event()
M.eUpdateEssence = Event()
M.eRed = Event()

function M:Init()
	self.TypeDic = {}
	self.GroupActive = {}
	self.Essence = 0
	self.RedBuffer = nil
	self.ProRedBuffer = nil
	self:InitData()
	self:CheckRed()
	self:AddEvent()
end

function M:InitData()
	local dic = PicCollectTemp
	if not dic then return end
	for k,v in pairs(dic) do
		self:AddTypeData(v)
	end
end

function M:AddTypeData(temp)
	local dic = self.TypeDic
	--类型
	local tKey = temp.type
	local type = dic[tKey]
	if not type then
		dic[tKey] = {}
		type = dic[tKey]
	end
	--卡组
	local gKey = temp.group
	local group = type[gKey]
	if not group then
		type[gKey] = {}
		group = type[gKey]
	end
	--卡牌
	local key = temp.picId
	local pic = group[key]
	if not pic then
		group[key] = {}
		pic = group[key]
	end
	pic.Name = temp.name
	pic.Path = temp.show
	pic.Active = false
	if temp.star == 0 and temp.lv == 0 then
		pic.Temp = temp
	end
end

function M:GetList(dic)
	local list = {}
	for k,v in pairs(dic) do
		table.insert(list, k)
	end
	self:SortList(list)
	return list
end

-----------------------------------------------------
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

-----------------------------------------------------
function M:UpdateEvent(EMF)	
	EMF("SelectSuc", EventHandler(self.InitData, self))
end

function M:SetEvent(fn)
	PropMgr.eUpdate[fn](PropMgr.eUpdate, self.UpdateItemList, self)
	UserMgr.eLvUpdate[fn](UserMgr.eLvUpdate, self.UpdateItemList, self)
end

function M:ProtoHandler(Lsnr)
	Lsnr(28002, self.RespPicCollectInfo, self)	
	Lsnr(28004, self.RespActivePic, self)	
	Lsnr(28006, self.RespResolvePic, self)	
	Lsnr(28008, self.RespUpPic, self)	
	Lsnr(28010, self.RespActiveGroupPic, self)	
	Lsnr(28012, self.RespUpdateEssence, self)	
end
-----------------------------------------------------
--上线更新数据
function M:RespPicCollectInfo(msg)
	local group = msg.handbook_list
	local len = #group
	for i=1,len do
		local group = group[i]
		if group then
			local idList = group.card_id
			for i,v in ipairs(idList) do
				self:UpdateActivePic(v)
			end
			local proidList = group.card_group_id
			for i,v in ipairs(proidList) do
				table.insert(self.GroupActive, v)
			end
		end
	end
	self.Essence = msg.total_essence
	self:CheckRed()
end

--激活卡片返回
function M:RespActivePic(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local id = msg.card_id
	--self.Essence = msg.total_essence
	local data = self:UpdateActivePic(id)
	if not data then return end
	self.eUpdatePic(data)
	self:CheckRed()
	UITip.Error("激活成功")
end

--分解卡片材料返回
function M:RespResolvePic(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local Cur = msg.get_essence
	--self.Essence = msg.total_essence
	self.ePicEssence()
	self:CheckRed()
	UITip.Error("分解成功")
end

--升级卡片返回
function M:RespUpPic(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.eError(ErrorCodeMgr.GetError(err))
		return 
	end
	local id = msg.card_id
	--self.Essence = msg.total_essence
	local data = self:UpdateUpPic(id)
	if not data then return end
	self.eUpdatePic(data)
	self:CheckRed()
	UITip.Error("升级成功")
end

--激活组图片
function M:RespActiveGroupPic(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local id = msg.card_group_id
	table.insert(self.GroupActive, id)
	self.eGroupActive(id)
	self:CheckRed()
	UITip.Error("激活卡组成功")
end

--更新精华
function M:RespUpdateEssence(msg)
	self.Essence = msg.total_essence
	self.eUpdateEssence()
	self:CheckRed()
end
-----------------------------------------------------
--激活卡片
function M:ReqActivePic(id)
	local msg = ProtoPool.GetByID(28003)
	msg.card_id = id
	Send(msg)
end

--分解卡片材料
function M:ReqResolvePic(list)
	local msg = ProtoPool.GetByID(28005)
	for i,v in ipairs(list) do
		msg.resolve_item_id:append(v)
	end
	Send(msg)
end

--升级卡片
function M:ReqUpPic(id)
	local msg = ProtoPool.GetByID(28007)
	msg.card_id = id
	Send(msg)
end

--图鉴组激活
function M:ReqActiveGroupPic(id)
	local msg = ProtoPool.GetByID(28009)
	msg.card_group_id = id
	Send(msg)
end
-----------------------------------------------------
--更新卡片激活状态
function M:UpdateActivePic(id)
	local temp = PicCollectTemp[tostring(id)]
	if not temp then return end
	local dic = self.TypeDic
	--类型
	local list = dic[temp.type]
	if list then
		--卡组
		local group = list[temp.group]
		if group then
			local pic = group[temp.picId]
			if pic then 
				pic.Active = true 
				pic.Temp = temp
				return pic
			end
		end
	end
	return nil
end

--更新卡片等级
function M:UpdateUpPic(id)
	local temp = PicCollectTemp[tostring(id)]
	if not temp then return end
	local dic = self.TypeDic
	--类型
	local list = dic[temp.type]
	if list then
		--卡组
		local group = list[temp.group]
		if group then
			local pic = group[temp.picId]
			if pic then 
				pic.Temp = temp
				return pic
			end
		end
	end
	return nil
end
-----------------------------------------------------
function M:GetGroupName(gKey)
	for k,v in pairs(ProTemp) do
		local id = math.floor(v.id/100)
		if id == gKey then return v.name end
	end
	return ""
end

function M:GetPicForId(id)
	local tkey = nil
	local gkey = nil
	local pkey = nil
	local dic = self.TypeDic
	for ii,tdic in ipairs(dic) do
		for i,v in pairs(tdic) do
			for k,p in pairs(v) do
				local temp = p.Temp
				if temp and temp.picId == id then
					local nTemp = PicCollectTemp[tostring(temp.id)]
					if nTemp then
						return nTemp
					end
				end
			end	
		end
	end
	return nil
end

function M:GetPics(tkey, gkey)
	local dic = self.TypeDic
	--类型
	local list = dic[tkey]
	if list then
		--卡组
		local group = list[gkey]
		if group then
			return group
		end
	end
	return nil
end
function M:GetPic(tkey, gkey, key)
	local dic = self.TypeDic
	--类型
	local list = dic[tkey]
	if list then
		--卡组
		local group = list[gkey]
		if group then
			local pic = group[key]
			if pic then
				return pic
			end
		end
	end
	return nil
end

function M:GetPicPros(tkey, gkey)
	local list = {}
	local pics = self:GetPics(tkey, gkey)
	if pics then
		for k,v in pairs(ProTemp) do
			local group = math.floor(v.id / 100)
			if group == gkey then
				table.insert(list, v)
			end
		end
	end
	table.sort(list, function (a, b) return a.id < b.id end)
	return list
end

function M:GetStepGroup(tkey, gkey, isAllActive)
	isAllActive = isAllActive or false
	local full = false
	local pics = self:GetPics(tkey, gkey)
	local num = 0
	local limit = 0
	local list = {}
	for k,v in pairs(ProTemp) do
		table.insert(list, v.id)
	end
	local len = #list
	if len > 1 then
		self:SortList(list)
	end
	for i=1,len do
		local temp = ProTemp[tostring(list[i])]
		if temp then
			if self:GetGroupActive(temp.id) == false or isAllActive == true then
				local group = math.floor(temp.id / 100)
				if group == gkey then
					if pics then
						limit = LuaTool.Length(pics)
						for k,v in pairs(pics) do
							if v.Active == true then
								num = num + v.Temp.star
							end
						end
						return temp, num
					end
				end
			end
		end
	end
	return nil, 0
end

function M:GetStepActiveNum(tkey, gkey)
	local dic = self.TypeDic
	local num = 0
	--类型
	local list = dic[tkey]
	if list then
		--卡组
		local group = list[gkey]
		if group then
			for k,v in pairs(group) do
				if v.Active == true then
					num = num + v.Temp.star
				end
			end
		end
	end
	return num
end

function M:GetGroupActive(id)
	for i,v in ipairs(self.GroupActive) do
		if v == id then 
			return true
		end
	end
	return false
end

function M:GetGroupName(group)
	for k,v in pairs(ProTemp) do
		local k = math.floor(v.id / 100)
		if k == group then 
			return v.name
		end
	end
	return nil
end

--是否满足消耗条件
--K == 0 消耗碎片精华
function M:IsCostMaterial(k,v)
	if k == 0 then
		return self.Essence >= v, self.Essence
	else
		local count = PropMgr.TypeIdByNum(k)
		return count >= v, count
	end
	return false, 0
end

function M:SortList(list)
	if not list or #list <= 1 then return end
	table.sort(list, function (a, b) return a < b end)
end

--道具更新
function M:UpdateItemList()
	self:CheckRed()
	self.eResolveRed()
	self:GetResolveToRed(true)
end

function M:CheckRed()
	local activeNum = 0
	local lvNum = 0
	local UpNum = 0
	if self.RedBuffer then TableTool.ClearDic(self.RedBuffer) end
	if self.ProRedBuffer then TableTool.ClearDic(self.ProRedBuffer) end
	if self:IsOpen() == true then
		local list = {}
		local groupRed = {}
		local dic = self.TypeDic
		for ii,t in ipairs(dic) do
			for i,v in pairs(t) do
				for k,p in pairs(v) do
					local temp = p.Temp
					self:CheckGroupProRed(groupRed, temp)
					local nTemp = PicCollectTemp[tostring(temp.id + 1)]
					if nTemp then
						local isCost1 = nil 
						if temp.cost then
							isCost1 = self:IsCostMaterial(0, temp.cost)
						end
						local isCost2 = nil
						if temp.upLvCost then
							isCost2 = self:IsCostMaterial(temp.upLvCost.k, temp.upLvCost.v)
						end
						if (isCost1 == nil and isCost2 == true) or (isCost1 == true and isCost2 == nil) or (isCost1 == true and isCost2 == true) then
							if p.Active == false then
								activeNum = activeNum + 1
							else
								if nTemp.star == temp.star then
									lvNum = lvNum  + 1
								else
									UpNum = UpNum + 1
								end
							end
							list[tostring(temp.picId)] = temp
						end
					end
				end
			end
		end
		self.RedBuffer = list
		self.ProRedBuffer = groupRed
	end
	self.eRed(activeNum > 0, 1)
	self.eRed(lvNum > 0, 2)
	self.eRed(UpNum > 0, 3)
	local value = self.ProRedBuffer ~= nil and LuaTool.Length(self.ProRedBuffer)  > 0
	self.eRed(value, 4)
	self.ePicRed()
end

function M:CheckGroupProRed(list, temp)
	local tkey = temp.type
	local gkey = temp.group
	local num = self:GetStepActiveNum(tkey, gkey)
	for k,v in pairs(ProTemp) do
		local group = math.floor(v.id / 100) 
		if group == gkey then
			local isEnabled = self:GetGroupActive(v.id) == false and  num >= v.stars
			if isEnabled == true then
				list[tostring(v.id)] = v
			end
		end
	end
end

function M:GetPicToRed(id)
	if not self.RedBuffer then return false end
	local key = tostring(id)
	return self.RedBuffer[key] ~= nil
end

function M:GetGroupToRed(tkey, gkey)
	local buffer = self.RedBuffer
	if buffer then
		for k,v in pairs(buffer) do
			if v.type == tkey and v.group == gkey then
				return true
			end
		end
	end
	--[[
	if self:GetResolveToRed() == true then
		return true
	end
	]]--
	if self:GetGroupProViewToRed(gkey) == true then
		return true
	end
	return false
end

function M:GetResolveToRed(event)
	local list = {}
	PropMgr.UseGetDic(list, {self.ResolveUseEff})
	local count = self:ResolveFilter(list)
	local value = count > 0
	if event ~= nil then 
		self.eRed(value, 5) 
	end
	return value
end

function M:ResolveFilter(list)
	local count = 0
	if list then
		local len = #list
		if len > 0 then
			for i=len,1,-1 do
				local info = list[i]
				if info then
					if TableTool.Contains(self.PicEXP, info.type_id) ~= -1 then
						count = count + 1
					else
						local temp = PicCollectTemp[tostring(info.type_id * 100)]
						if temp then
							local pic = self:GetPic(temp.type, temp.group, temp.picId)
							if pic then
								if pic.Active == false then
									table.remove(list, i)
								else
									if pic.Temp and (pic.Temp.star >= self.FullStar and pic.Temp.lv >= self.FullLv) then
										count = count + 1
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return count
end

function M:GetTypeToRed(type)
	local buffer = self.RedBuffer
	if buffer then
		for k,v in pairs(buffer) do
			if v.type == type then
				return true
			end
		end
	end
	--[[
	if self:GetResolveToRed() == true then
		return true
	end
	]]--
	if self:GetGroupProViewTypeToRed(type) == true then
		return true
	end
	return false
end

function M:GetGroupProToRed(id)
	if not self.ProRedBuffer then return false end
	local key = tostring(id)
	return self.ProRedBuffer[key] ~= nil
end

function M:GetGroupProViewToRed(group)
	local dic = self.ProRedBuffer
	if dic then
		for k,v in pairs(dic) do
			local g = math.floor(v.id / 100)
			if g == group then return true end
		end
	end
	return false
end

function M:GetGroupProViewTypeToRed(type)
	local dic = self.ProRedBuffer
	local list = self.TypeDic
	local len = #list
	if dic then
		for k,v in pairs(dic) do
			local gkey = math.floor(v.id/100)
			if list then
				for i=1,len do
					local tdic = list[type]
					if tdic then
						local group = tdic[gkey]
						if group and i == type then
							return true 
						end
					end
				end
			end
		end
	end
	return false
end

function M:IsOpen()
	local oMgr = OpenMgr
	return oMgr:IsOpen(oMgr.TJ)
end

function M:OpenForId(id)
	if self.IsOpen() == false then
		UITip.Error("功能未开启")
		return
	end
	if id ~= nil then
		local tkey = nil
		local gkey = nil
		local pkey = nil
		local dic = self.TypeDic
		for ii,tdic in ipairs(dic) do
			for i,v in pairs(tdic) do
				for k,p in pairs(v) do
					local temp = p.Temp
					local nTemp = PicCollectTemp[tostring(temp.id)]
					if nTemp then
						if nTemp.picId == id then	
							tkey = temp.type
							gkey = temp.group
							pkey = temp.picId 
							break		
						end
					end
				end			
				if pkey ~= nil then 
					break 
				end
			end
			if pkey ~= nil then 
				break 
			end
		end
		if tkey == nil then tkey = 1 end
		if gkey == nil then gkey = 1 end
		if pkey == nil then pkey = 1 end
		UIPicCollect.DefaultType = tkey
		UIPicCollect.DefaultGroup = gkey
		UIPicCollect.DefaultPic = pkey
	end
	UIMgr.Open(UIPicCollect.Name)
end

function M:OpenUI(t)
	if t == 1 or t == 2 then
		local tkey = nil
		local gkey = nil
		local pkey = nil
		local dic = self.TypeDic
		for ii,tdic in ipairs(dic) do
			for i,v in pairs(tdic) do
				for k,p in pairs(v) do
					local temp = p.Temp
					local nTemp = PicCollectTemp[tostring(temp.id + 1)]
					if nTemp then
						local isCost1 = nil 
						if temp.cost then
							isCost1 = self:IsCostMaterial(0, temp.cost)
						end
						local isCost2 = nil
						if temp.upLvCost then
							isCost2 = self:IsCostMaterial(temp.upLvCost.k, temp.upLvCost.v)
						end
						if (isCost1 == nil and isCost2 == true) or (isCost1 == true and isCost2 == nil) or (isCost1 == true and isCost2 == true) then														
							if p.Active == false then
								if  t == 1 then
									tkey = temp.type
									gkey = temp.group
									pkey = temp.picId 
									break
								end
							else
								if t == 2 then
									tkey = temp.type
									gkey = temp.group
									pkey = temp.picId 
									break
								end
							end
						end
					end
				end			
				if pkey ~= nil then 
					break 
				end
			end
			if pkey ~= nil then 
				break 
			end
		end
		UIPicCollect.DefaultType = tkey
		UIPicCollect.DefaultGroup = gkey
		UIPicCollect.DefaultPic = pkey
	elseif t == 3 then
		local dic = self.ProRedBuffer
		if dic then
			for k,v in pairs(dic) do
				local gkye = math.floor(v.id / 100)
				UIPicCollect.DefaultGroup = gkye
				local tDic = self.TypeDic
				for i,t in ipairs(tDic) do
					for k,v in pairs(t) do
						if tonumber(k) == gkye then
							UIPicCollect.DefaultType = i
							break
						end
					end
				end
				break
			end
		end
		UIPicCollect.DefaultOpen = 2
	elseif t == 4 then
		UIPicCollect.DefaultOpen = 3
	end
	UIMgr.Open(UIPicCollect.Name)
end

function M:Clear()
	TableTool.ClearDic(self.TypeDic)
	TableTool.ClearDic(self.GroupActive)
end

function M:Dispose()
end

return M
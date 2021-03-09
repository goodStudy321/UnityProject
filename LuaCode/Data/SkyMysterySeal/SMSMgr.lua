--region SMSMgr.lua
--Date
--此文件由[HS]创建生成
require("Data/SkyMysterySeal/SMSNetwork")
require("Data/SkyMysterySeal/SMSControl")

SMSMgr = {Name="SMSMgr"}
local M = SMSMgr

M.PageType = {}
M.PageType.Yang = 1
M.PageType.Yin  = 2

M.DecomposeMenu = {
	{quality = 0, star = 0},
	{quality = 2, star = 0},
	{quality = 3, star = 0},
	{quality = 3, star = 1},
	{quality = 4, star = 1},
	{quality = 4, star = 2},
	{quality = 5, star = 1},
	{quality = 5, star = 2},
	{quality = 5, star = 3}
}
M.ProKeys = {"hp", "atk", "def", "arm", "hpadd", "atkadd", "metal", "wood", "water", "fire", "soil"}
--使用效果
M.UseEff = 86
--分解获得
M.CostItem = 700006
--获取途径
M.GetWayID = 11423
M.GetWay = GetWayData["11423"]
M.GloblCfg = GlobalTemp["161"]
--==============================--
--数据
--==============================--
---印记分类记录
M.Infos = {}
M.Infos[1] = {} 		--阳
M.Infos[2] = {}			--阴
--套装
M.SuitIndex = {}
M.SuitInfos = {}
M.SuitActiveInfos = {}
--默认分解品质 0 不分解 大于0品质
M.DecomposeQuality = 0
M.DecomposeStar = 0
--分解数量
M.CostNum = 0
--当前分页
M.CurPage = M.PageType.Yang
--当前选中
M.CurSelectIndex = -1
--当前标签页
M.CurToggle = -1
--是否有可镶嵌
M.IsHole = false
--是否有积分
M.IsUpScore = false
--是否强化
M.IsStrength = false
M.PageStrength = {}
M.PageStrength[1] = false
M.PageStrength[2] = false
M.HoleRedTab = {} --孔红点
--==============================--
--事件
--==============================--
M.eOpenHold = Event()
M.eChangeHold = Event()
M.eStrengthHold = Event()
M.eChangeConsume = Event()
M.eChangeRed = Event()
M.eChangeSuitAceive = Event()
--==============================--
--更新数据
--==============================--
function M:Init()
	SMSNetwork:Init()
	for k,v in pairs(SMSOpenTemp) do
		self:AddInfo(v)
	end
	local dic = SMSSuitProTemp
	for k,v in pairs(dic) do
		self:AddSuitInfo(v)
	end
	self:AddEvent()
end

function M:AddEvent()
	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	PropMgr.eMSMUpdate[fn](PropMgr.eMSMUpdate, self.CheckRed, self)
end

--初始化开孔数据
function M:AddInfo(temp)
	local type = temp.type
	local index = temp.index
	local typeList = self.Infos
	local len = #typeList
	local indexList = typeList[type]
	if not indexList then 
		typeList[type] = {} 
		indexList = typeList[type]
	end
	local info = indexList[index]
	if not info then
		indexList[index] = {} 
		info = indexList[index]
	end
	info.OpenTemp = temp
end

function M:AddSuitInfo(temp)
	local type = temp.type
	local id = temp.id
	local key = tostring(type)
	local list = self.SuitInfos[key]
	if not list then
		table.insert(self.SuitIndex, type)
		self.SuitInfos[key] = {}
		table.insert(self.SuitInfos[key], id)
		return
	end
	if self:IsCheckList(list, id) == true then return end
	table.insert(self.SuitInfos[key], id)
end

--更新服务器数据
function M:UpdateProto(type, id, items, sl, init)
	if not init then init = false end
	local temp = SMSOpenTemp[tostring(id)]
	local pro = {}
	pro.Type = type
	pro.Index = temp.index
	pro.StrengthLv = sl
	pro.SStatus = false 		--是否可强化
	local item = items[1]
	if item ~= nil then
		pro.Item = ObjPool.Get(PropTb)
		pro.Item:Init(item)
	end
	local info = self:GetPageInfo(type, temp.index)
	if info then
		info.Pro = pro
		if info.Pro.Item ~= nil then 
			self:UpdateActiveSuitInfo(type, item.type_id, true)
		end
		if init == false then
			if item == nil then
				if self.CurPage == temp.index then
					self.eOpenHold(info)
				end
			end
		end
	end
end

function M:UpdateHole(type, id)
	local temp = SMSOpenTemp[tostring(id)]
	local pro = {}
	pro.Type = type
	pro.Index = temp.index
	pro.StrengthLv = 0
	pro.SStatus = false 		--是否可强化

	local info = self:GetPageInfo(type, temp.index)
	if info then
		info.Pro = pro
		if self.CurPage == temp.type then
			self.eOpenHold(info)
		end
	end
end

--更新激活的套装
function M:UpdateActiveSuitInfo(type, id, init)
	if not init then init = false end
	local temp = SMSProTemp[tostring(id)]
	local list = self:GetSuitProTempList(temp, type)
	local activeInfos = self.SuitActiveInfos[type]
	if not activeInfos then 
		self.SuitActiveInfos[type] = {}
		activeInfos = self.SuitActiveInfos[type] 
	end
	local len = 0
	if list ~= nil then len = #list end
	local aLen = #activeInfos
	if aLen > 0 then				--如果之前有激活了的套装 开始移除未激活的
		--如果没有找到激活的套装 则全部移除
		if list == nil or len == 0 then
			while len > 0 do
				table.remove(self.SuitActiveInfos[type], len)
				len = #self.SuitActiveInfos[type]
			end
		else
			--新激活的套装里 在已激活套装补存在 移除上一次已激活的
			local del = {}
			--检查移除未激活的
			if len > 0 then
				for i=1,aLen do
					if self:IsCheckSuitActiveList(list, activeInfos[i]) == false then
						table.insert(del, i)
					end
				end
			end
			local delLen = #del
			while delLen > 0 do
				table.remove(self.SuitActiveInfos[type], del[delLen])
				delLen = delLen-1
			end
		end
	end
	--把新激活的套装id 压入已激活队列
	local isShowTip = false
	if list ~= nil and len > 0 then
 		for i=len,1,-1 do
			local info = list[i]
			if info.Status == true then
				if self:IsCheckList(activeInfos, info.Temp.id) == false then
					table.insert(activeInfos, info.Temp.id)
					if isShowTip == false then
						isShowTip = true
						if init == false then
							UITip.Error(string.format("%s触发【%s】件套装效果[-]", UIMisc.LabColor(info.Temp.quality), info.Temp.num))
						end
					end
				end
			end
		end
		table.sort(activeInfos, function(a,b) return a<b end)
	end
	self.eChangeSuitAceive()
end

--更新镶嵌的印章
--t操作类型
function M:UpdateSeal(type, id, items, t)
	--[[
	if t == 0 then
		UITip.Error("卸下天机印成功")
	elseif t == 1 then
		UITip.Error("镶嵌天机印成功")
	elseif t == 2 then
		UITip.Error("替换天机印成功")
	end
	]]--
	local temp = SMSOpenTemp[tostring(id)]
	local info = self:GetPageInfo(type, temp.index)
	if info and info.Pro then
		local id = 0
		local item = items[1]
		if item ~= nil and t ~= 0 then
			if info.Pro.Item ~= nil then	--替换的
				id = info.Pro.Item.type_id
			end
			info.Pro.Item = ObjPool.Get(PropTb)
			info.Pro.Item:Init(item)
			if id ~= 0 then --替换完检查套装
				self:UpdateActiveSuitInfo(type, id)
			end
			id = item.type_id --新的
		elseif t == 0 then
			id = info.Pro.Item.type_id --移除的
			info.Pro.Item = nil
		end
		if id ~= 0 then
			self:UpdateActiveSuitInfo(type, id)
		end
		self.eChangeHold(info)
	end	
end

--更新强化
function M:UpdateStrengthLv(type, id, sl)
	local temp = SMSOpenTemp[tostring(id)]
	local info = self:GetPageInfo(type, temp.index)
	if info and info.Pro then
		info.Pro.StrengthLv = sl
	end	
	self.eStrengthHold(info)
end
--==============================--
--
--==============================--
--==============================--
--获取数据
--==============================---
--获取分页数据
function M:GetPageInfos(type)
	local typeInfos = self.Infos
	if typeInfos then return typeInfos[type] end
	return nil
end

--获取分页数据
function M:GetPageInfo(type, index)
	local typeInfos = self.Infos
	if typeInfos then 
		local indexInfos = typeInfos[type] 
		if indexInfos then
			return indexInfos[index]
		end
	end
	return nil
end

--获得分页名字
function M:GetPageName(page)
    local pageType = self.PageType
	if page == pageType.Yang then
		return "阴"
	elseif page == pageType.Yin then
		return "阳"
	end
	return "未开启"
end

--获取指定位置的天机印
function M:GetItemsForIndex(list, index)
	if not list then list = {} end
	local dic = PropMgr.tb5Dic
	for k,v in pairs(dic) do
		local id = v.type_id
		local temp = SMSProTemp[tostring(id)]
		if index == -1 or temp and temp.index == index then
			local star = 0
			if temp then star = temp.star end
			if star == nil then star = 0 end
			table.insert(list, v)
			list[#list].star = star
		end
	end
end

--获得可分解的天机印
function M:GetDecomposeItems(list)
	if not list then list = {} end
	local dic = PropMgr.tb5Dic
	for k,v in pairs(dic) do
		local id = v.type_id
		local temp = SMSProTemp[tostring(id)]
		if temp then
			if temp.index ~= 999 then
				local status = self:GetScoreCompare(id)
				if status ~= 1 then
					local star = 0
					if temp then star = temp.star end
					if star == nil then star = 0 end
					table.insert(list, v)
					list[#list].star = star
				end
			else
				star = 0
				table.insert(list, v)
				list[#list].star = star
			end	
		end
	end
end

--排序
function M:Sort(a, b)
	local at = SMSProTemp[tostring(a.type_id)]
	local bt = SMSProTemp[tostring(b.type_id)]
	if a.type_id ~= b.type_id then
		if at ~= nil and bt ~= nil then
			if at.quality > bt.quality then return true end
			if at.quality < bt.quality then return false end 
			if at.index == 0 and bt.index ~= 0 then return true end
			if at.index ~= 0 and bt.index == 0 then return false end
			if at.star > bt.star then return true end
			if at.star < bt.star then return false end
			if at.index > bt.index then return true end	
			if at.index < bt.index then return false end
		end
		if a.type_id > b.type_id then return true end
		if a.type_id < b.type_id then return false end
	end
	return false
end

--分解排序
function M:DSort(a, b)
	local at = SMSProTemp[tostring(a.type_id)]
	local bt = SMSProTemp[tostring(b.type_id)]
	if a.type_id ~= b.type_id then
		if at ~= nil and bt ~= nil then
			if at.quality > bt.quality then return true end
			if at.quality < bt.quality then return false end 
			if at.index == 0 and bt.index ~= 0 then return true end
			if at.index ~= 0 and bt.index == 0 then return false end
			if at.star > bt.star then return true end
			if at.star < bt.star then return false end
			if at.index < bt.index then return true end	
			if at.index > bt.index then return false end
		end
		if a.type_id > b.type_id then return true end
		if a.type_id < b.type_id then return false end
	end
	return false
end

function M:SuitProSort(a, b)
	local at = SMSSuitProTemp[tostring(a)]
	local bt = SMSSuitProTemp[tostring(b)]
	if a ~= b then
		if at.num ~= bt.num then return at.num < bt.num end
		if at.quality ~= bt.quality then return at.quality < bt.quality end
		return at.id < bt.id
	end
	return a > b
end

function M:GetSuitProTempList(temp,type)
	local list = {}
	local suitid = temp.limitId
	local suitTemp = SMSSuitProTemp[tostring(suitid)]
	if suitTemp then
		local condition = self.SuitInfos[tostring(suitTemp.type)]
		if condition then
			for i=1,#condition do
				local id = condition[i]
				local v = SMSSuitProTemp[tostring(id)]
				if v then
					local info = {}
					info.Temp = v
					local status, num = self:GetSuitActiveStatusAllType(v, v.num, type)
					info.Status = status
					info.Num = num
					table.insert(list, info)
				end
			end
		end
	end
	if #list == 0 then return nil end
	table.sort(list,function(a, b) return self:SuitProSort(a.Temp.id, b.Temp.id) end)
	return list
end

--获取所有的激活套装
function M:GetAllActiveSuit()
	local suit = {}
	local idList = {}
	for k,v in pairs(SMSSuitProTemp) do
		local status, num = self:GetSuitActiveStatus(v, v.num)
		if status == true then
			local type = v.type
			if suit[type] == nil then
				suit[type] = {}
				suit[type].Quality = v.quality
				suit[type].Num = v.num
				table.insert(idList, v.type)
			else
				if v.num > suit[type].Num then
					suit[type].Num = v.num
				end
			end
		end
	end
	table.sort(idList, function(a,b) return a <b end)
	return idList, suit
end

function M:Contains(list, value, key)
	local index = -1
	if not list then return index end
	local len = #list
	for i=1,len do
	  if key then
		if list[i][key] == value then
		  index = i
		  break
		end
	  end
	end
	return index
end
--[[


--获取所有的激活套装
function M:GetAllActiveSuit()
	local suit = {}
	local idList = {}
	for k,v in pairs(SMSSuitProTemp) do
		for k,t in pairs(self.PageType) do
			self:CheckActiveSuit(idList, suit, v, t)
		end
	end
	table.sort(idList, function(a,b) return a <b end)
	return idList, suit
end

function M:CheckActiveSuit(idList, suit, v, t)
	local status, num = self:GetSuitActiveStatus(v, v.num, t)
	if status == true then
		local type = v.type
		if suit[type] == nil then
			suit[type] = {}
			suit[type].Quality = v.quality
			suit[type].Num = v.num
			table.insert(idList, v.type)
		else
			if v.num > suit[type].Num then
				suit[type].Num = v.num
			end
		end
	end
end

]]--

--获取指定位置数据
function M:GetInfoForIndex(index)
	if not index then index = self.CurSelectIndex end
	local infos = self.Infos[self.CurPage]
	if infos then
		return infos[index]
	end
	return nil
end

--获取消耗道具数量
function M:GetCostNum(id)
	if not id then id = self.CostItem end
	local num = 0
	local dic = PropMgr.tb5Dic
	for k,v in pairs(dic) do
		local id = v.type_id
		if id == v.type_id then
			num = num + v.num
		end
	end
	return num
end

--获得自动分解数据
function M:GetDecomposeData()
	local list = self.DecomposeMenu
	for i=1, #list do
		local data = list[i]
		if data.quality == self.DecomposeQuality and data.star == self.DecomposeStar then
			return i - 1
		end
	end
	return 1
end
function M:IsCheckSuitActiveList(list, id)
	for i,v in ipairs(list) do
		if v.Temp.id == id then
			return v.Status
		end
	end
	return true
end

function M:IsCheckList(list, id)
	for i,v in ipairs(list) do
		if type(v) == "number" then
			if v == id then
				return true
			end
		else
			if v.Temp.id == id then
				return true
			end
		end
	end
	return false
end

function M:IsCheckSuitActiveForId(id)
	local temp = SMSProTemp[tostring(id)]
	return self:IsCheckSuitActive(temp.condition)
end

function M:IsCheckSuitActive(list)
	if list then
		for i=1,#list do
			if self:IsCheckList(self.SuitActiveInfos[self.CurPage], list[i]) == true then
				return true
			end
		end
	end
	return false
end
--==============================--
--状态
--==============================---
function M:GetSuitActiveStatusAllType(cTemp, limit, type)
	local limitNum = 0
	for k,v in pairs(self.PageType) do
		if not type or type == v then 
			if cTemp.name == "绝品.丁火" or cTemp.name == "绝品.离火" then
				if limit == 8 then
					limit = 8
				end
			end
			local status,num = self:GetSuitActiveStatus(cTemp ,limit, v)
			if num > limitNum then limitNum = num end
			if status == true then return true, num end
		end
	end
	return false, limitNum
end

--套装激活状态
function M:GetSuitActiveStatus(cTemp, limit, t)
	if t == nil then t = self.CurPage end
	if cTemp == nil then
		cTemp = nil
	end
	local ids = cTemp.condition
	if ids == nil then
		local lTemp = SMSSuitProTemp[tostring(cTemp.limitId)]
		if lTemp then ids = lTemp.condition end
	end
	local num = 0
	if not ids then return false, num end
	local list = self.Infos[t]
	if not list then return false, num end
	local len = #ids
	local k = 0
	for i=1,len do
		local id = ids[i]
		local temp = SMSProTemp[tostring(id)]
		if temp then
			local info = list[temp.index]
			if info then
				if info.Pro and info.Pro.Item then
					if info.OpenTemp.index == 0 then
						if limit >= temp.skillEff.v then
							k = temp.skillEff.k
						end
					else
						if info.Pro.Item.type_id == id then 
							num = num + 1
						end
					end
				end
			end
		end
	end
	return num >= limit - k, num
end

--分页开启状态
function M:IsOpen(cur)
	local pages = self.Infos[cur]
	if pages then
		local info = pages[0]
		if info then
			local temp = info.OpenTemp
			local id = temp.condition
			if id == nil then return true, temp  end
			local value = FiveElmtMgr:CopyIsOpen(id) 
			if value == true then return true, temp end
			return info.Pro ~= nil,temp 
		end
	end
	return false, nil
end

--检查变强
function M:CheckStrengthRed()
	local types = self.Infos
	local state = false
	for i,v in ipairs(types) do
		self.PageStrength[i] = false
		local len = #v
		for j=0,len do
			local info = v[j]
			if info.Pro  then
				info.Pro.SStatus = false 		--是否可强化
				if info.Pro.Item then
					local index = info.OpenTemp.index
					local slv = info.Pro.StrengthLv + 1
					local temp = SMSProTemp[tostring(info.Pro.Item.type_id)]
					if temp then
						if temp.limit >= slv then
							local id = 10000+index*1000 + slv
							local temp = SMSStrengthTemp[tostring(id)]
							if temp then
								if self.CostNum >= temp.cost_num then
									info.Pro.SStatus = true 		--是否可强化
									state = true
									self.PageStrength[i] = true
								end
							end
						end
					end
				end
			end
		end
	end
	self.IsStrength = state
	self.eChangeRed()
end


--检查红点
function M:CheckRed()
	self:ClearHoleRedTab()
	local redTab = {}
	local holeIndex = 0
	local upScoreIndex = 0
	local dic = PropMgr.tb5Dic
	for k,v in pairs(dic) do
		local id = v.type_id
		local temp = SMSProTemp[tostring(id)]
		if temp then
			local index = temp.index
			if index ~= 999 then
				local total = PropTool.GetFight(temp, self.ProKeys)
				local info = self.Infos[self.CurPage]
				if info then
					local hole = info[temp.index]
					if hole and hole.Pro then
						if  hole.Pro.Item == nil then
							redTab[index] = true
							holeIndex = holeIndex + 1
							-- self.IsHole = true
							-- self.eChangeRed()
							-- return
						else
							local curTemp = SMSProTemp[tostring(hole.Pro.Item.type_id)]
							if curTemp then
								local curTotal = PropTool.GetFight(curTemp, self.ProKeys)
								if total > curTotal then
									redTab[index] = true
									upScoreIndex = upScoreIndex + 1
									-- self.IsUpScore = true
									-- self.eChangeRed()
									-- return
								end
							end
						end
					end
				end
			else
			end
		end
	end
	self.HoleRedTab = redTab
	self.IsHole = holeIndex > 0
	self.IsUpScore = upScoreIndex > 0
	self.eChangeRed()
end

--积分比对
function M:GetScoreCompare(id)
	local temp = SMSProTemp[tostring(id)]
	if temp then
		local total = PropTool.GetFight(temp, self.ProKeys)
		local info = self.Infos[self.CurPage]
		if info then
			local hole = info[temp.index]
			if hole and hole.Pro and hole.Pro.Item then
				local curTemp = SMSProTemp[tostring(hole.Pro.Item.type_id)]
				if curTemp then
					local curTotal = PropTool.GetFight(curTemp, self.ProKeys)
					if total > curTotal then
						return 1
					elseif total == curTotal then
						return 0
					else
						return -1
					end
				end
			end
		end
	end
	return 1
end

--是不是可以去卖
function M:IsAuction(bt)
	if bt == nil then return false end
	local now =  TimeTool.GetServerTimeNow()*0.001
	local endTime = now - bt.market_end_time;
	-- local now = TimeTool.GetServerTimeNow()*0.001
	-- local time = endTime - now
	local cfg = ItemData[tostring(bt.type_id)];
	if cfg.AucSecId and cfg.startPrice then
		if bt.bind == false and (bt.market_end_time == 1 or endTime > 0) then
			return true
		end   
	end
	return false
end

--有效期 
function M:ShowWhetherLimit(tb)
	local txt = ""
	if not tb then return txt end
	local cfg = ItemData[tostring(tb.type_id)]
	if cfg and cfg.time then
		local str=ObjPool.Get(StrBuffer)
		--str:Line()
		str:Apd("[-][67cc67]")
		local day,hour,seconds = self:GetDated(cfg, tb)
		if day==nil and hour==nil and seconds==nil  then
			str:Apd("【已过期】")
		else
			str:Apd("【有效期：")
			if day then 
				str:Apd(day):Apd("天")
			end
			if hour then 
				if second then str:Apd(hour+1):Apd("小时")
				else str:Apd(hour):Apd("小时") end				
			end
			if day==nil and hour==nil and seconds then str:Apd(seconds):Apd("分")end
			str:Apd("】")
		end
		txt=str:ToStr()
		if str then ObjPool.Get(str) str=nil end
	end
	return txt
end

function M:GetDated(cfg, tb)
	local day,hour,seconds=nil,nil,nil
	local time=nil
	if tb and tb.startTime~=0 then
		local now=TimeTool.GetServerTimeNow()*0.001
		local lerp=tb.endTime-now
		if lerp>0 then time=lerp else return nil,nil,nil end
	else
		time=tonumber(cfg.time)
	end
	day,hour=DateTool.GetDay(time)
	if hour then hour,second=DateTool.GetHour(hour) end
	if seconds then seconds=DateTool.GetMinu(second) end
	return day,hour,seconds
end

function M:ClearInfo()
	for i,v in ipairs(self.Infos) do
		for j=0,8 do
			if v[j].Pro and v[j].Pro.Item then
				ObjPool.Add(v[j].Pro.Item)
			end
			v[j].Pro = nil
		end
	end
	TableTool.ClearDic(self.SuitActiveInfos)
end

function M:ClearHoleRedTab()
	for k,v in pairs(self.HoleRedTab) do
		self.HoleRedTab[k] = nil
	end
end

function M:Clear()
	--[[
	---印记分类记录
	self.Infos = {}
	self.Infos[1] = {} 		--阳
	self.Infos[2] = {}			--阴
	--套装
	self.SuitIndex = {}
	self.SuitInfos = {}
	self.SuitActiveInfos = {}
	]]--
	--默认分解品质 0 不分解 大于0品质
	self:ClearHoleRedTab()
	self:ClearInfo()
	self.DecomposeQuality = 0
	self.DecomposeStar = 0
	--分解数量
	self.CostNum = 0
	--当前分页
	self.CurPage = self.PageType.Yang
	--当前选中
	self.CurSelectIndex = -1
	--当前标签页
	self.CurToggle = -1
	--是否有可镶嵌
	self.IsHole = false
	--是否有积分
	self.IsUpScore = false
	--是否强化
	M.IsStrength = false
end

function M:Dispose()
end

return M
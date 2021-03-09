--[[
 	authors 	:Liu
 	date    	:2018-11-2 16:00:00
 	descrition 	:仙魂信息类
--]]

ImmortalSoulInfo = {Name = "ImmortalSoulInfo"}

local My = ImmortalSoulInfo

function My:Init()
    --当前点击的Tog索引
	self.togIndex = 0
	--当前点击的分页索引
	self.tabIndex = 0
	--合成列表
	self.compList = {}
	--合成类型
	self.compTypeList = {"橙色单属性", "红色单属性", "橙色双属性", "红色双属性", "核心双属性"}
	--装备上的仙魂列表
	self.useList = {}
	--背包里的仙魂列表
	self.bagList = {}
	--自定义Tab
	self.tab = { soulId = 0, index = 0, lvId = 0}
	--仙魂碎片
	self.debris = 0
	--仙魂石
	self.stone = 0
	--已开启的装备孔
	self.openList = {}
	--自动设置
	self.decompSet = 0
	--自定义属性Tab
	self.proTab = { name = "", val = 0, type = 0 }
	--自定义分解信息Tab
	self.decompTab = { name = "", val1 = "", val2 = "", stone = 0, debris = 0 }
	--记录分解所得的仙尘数量
	self.decompCount = 0

	self:InitCompList()
end

--设置仙魂背包列表信息
function My:SetBagList(SoulId, Index, LvId)
	self.tab = { soulId = SoulId, index = Index, lvId = LvId}
	table.insert(self.bagList, self.tab)
end

--删除某项背包列表信息
function My:RemoveBagList(index)
	for i,v in ipairs(self.bagList) do
		if v.index == index then
			table.remove(self.bagList, i)
			return
		end
	end
end

--设置仙魂镶嵌列表信息
function My:SetUseList(SoulId, Index, LvId)
	self.tab = { soulId = SoulId, index = Index, lvId = LvId}
	table.insert(self.useList, self.tab)
end

--删除某项镶嵌列表信息
function My:RemoveUseList(index)
	for i,v in ipairs(self.useList) do
		if v.index == index then
			table.remove(self.useList, i)
			return
		end
	end
end

--更新镶嵌列表信息
function My:UpUserList(index, lvId)
	for i,v in ipairs(self.useList) do
		if v.index == index then
			v.lvId = lvId
			break
		end
	end
end

--根据索引删除仙魂背包列表
function My:DelBagList(index)
	table.remove(self.bagList, index)
end

--设置开启列表
function My:SetOpenList(num)
	table.insert(self.openList, num)
end

--设置Tog索引
function My:SetTogIndex(index)
    self.togIndex = index
end

--设置分页索引
function My:SetTabIndex(index)
    self.tabIndex = index
end

--初始化合成列表
function My:InitCompList()
	local dic = {}
	local cfg = ImmSoulCompCfg
	for k,v in pairs(cfg) do
		local key = tostring(v.compType)
		if dic[key] == nil then
			dic[key] = v.compType
		end
	end
	for k,v in pairs(dic) do
		local list = {}
		table.insert(self.compList, list)
	end
	for k,v in pairs(cfg) do
		local key = tostring(v.compType)
		if dic[key] then
			table.insert(self.compList[v.compType], v.id)
		end
	end
	self:CompListSort()
end

--列表排序
function My:CompListSort()
	for i,v in ipairs(self.compList) do
		table.sort(v)
	end
end

--根据分页id,获取Tog索引
function My:GetTogIndex(id)
	for i,v in ipairs(self.compList) do
		for i1,v1 in ipairs(v) do
			if v1 == id then
				return i
			end
		end
	end
end

--判断是否显示跳转按钮
function My:IsShowJump(lvId)
	local bid = self:GetBaseID(lvId)
	local key = tostring(bid)
	local cfg = ImmSoulCompCfg[key]
	if cfg then
		return true
	end
	for i,v in ipairs(ImmSoulCompCfg) do
		if v.compNeed1 == bid or v.compNeed2 == bid then
			return true
		end
	end
	return false
end

--判断是否跳转到分页
function My:IsJumpTab(lvId)
	local bid = self:GetBaseID(lvId)
	local key = tostring(bid)
	local cfg = ImmSoulCfg[key]
	if cfg then
		if #cfg.proType > 1 then
			return 2,bid
		else
			return 1,bid
		end
	end
	return 0,0
end

--获取跳转信息
function My:GetJumpInfo(lvId)
	local num, bid = self:IsJumpTab(lvId)
	if num == 2 then
		local key = tostring(bid)
		local cfg = ImmSoulCompCfg[key]
		if cfg then
			local tabId = self:GetTabIndex(cfg.compType, cfg.sortId)
			return cfg.compType, tabId
		else
			return nil,nil
		end
	elseif num == 1 then
		for k,v in pairs(ImmSoulCompCfg) do
			if v.compNeed1 == bid or v.compNeed2 == bid then
				local tabId = self:GetTabIndex(v.compType, v.sortId)
				return v.compType, tabId
			end
		end
	end
	return nil,nil
end

--获取分页索引
function My:GetTabIndex(compType, sortId)
	local tabId = sortId
	local num = compType
	if num == 1 then
		return tabId
	end
	for i=1, num-1 do
		tabId = tabId - #self.compList[i]
	end
	return tabId
end

--判断是否存在相同类型
function My:IsSameType(type)
	local baseCfg = ImmSoulCfg
	for i,v in ipairs(self.useList) do
		local key = tostring(v.soulId)
		local cfg = baseCfg[key]
		if cfg then
			for i1,v1 in ipairs(cfg.proType) do
				if v1 == type then
					return true
				end
			end
		end
	end
	return false
end

--获取对应品质的所有物品
function My:GetQuaList(myList, quality)
	local list = {}
	local list1 = {}
	local list2 = {}
	for i,v in ipairs(myList) do
		local key = tostring(v.soulId)
		local cfg = ImmSoulCfg[key]
		local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
		if cfg and lvCfg then
			local id = lvCfg.id
			local qua = math.floor(id % 10)
			if quality == qua then
				if #cfg.proType > 1 then
					table.insert(list2, v)
				else
					table.insert(list1, v)
				end
			end
		end
	end
	table.sort(list2, function(a,b) return a.lvId > b.lvId end)
	table.sort(list1, function(a,b) return a.lvId > b.lvId end)
	for i,v in ipairs(list2) do
		table.insert(list, v)
	end
	for i,v in ipairs(list1) do
		table.insert(list, v)
	end
	return list
end

--获取所有碎片
function My:GetDebris()
	local list = {}
	for i,v in ipairs(self.bagList) do
		local key = tostring(v.soulId)
		local cfg = ImmSoulCfg[key]
		if cfg and cfg.wearType == 0 then
			table.insert(list, v)
		end
	end
	return list
end

--根据id获取背包里相同的id列表
function My:GetIdList(id)
	local list = {}
	local baseId = self:GetBaseID(id)
	for i,v in ipairs(self.bagList) do
		if v.soulId == baseId then
			table.insert(list, v)
		end
	end
	return list
end

--根据id获取装备上相同的id
function My:GetId(id)
	local baseId = self:GetBaseID(id)
	for i,v in ipairs(self.useList) do
		if v.soulId == baseId then
			return v
		end
	end
	return nil
end

--抽取最高品质的仙魂(仙魂背包)
function My:GetTopSoulInBag()
	local decompList = self:GetTopSoulInDecomp()
	local list = self:GetTopList(decompList, self.useList)
	for i,v in ipairs(self.useList) do
		for i1,v1 in ipairs(list) do
			if v.index == v1.index then
				table.remove(list, i1)
				break
			end
		end
	end
	return list
end

--抽取最高品质的仙魂(只过滤背包)
function My:GetTopSoulInDecomp()
	local bagList = {}
	local list = self:GetTopList(bagList, self.bagList)
	return list
end

--获取置顶列表
function My:GetTopList(list, setList)
	for i,v in ipairs(setList) do
		local key = tostring(v.soulId)
		local cfg = ImmSoulCfg[key]
		local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
		if cfg and lvCfg then
			local isEnd = (i==#setList)
			if cfg.wearType ~= 0 then
				local qua = lvCfg.id % 10
				local isTop, index = self:IsTopSoul(list, cfg.proType, lvCfg.lv, qua, cfg.onlyType, v.index, isEnd)
				if isTop then
					if index == 0 then
						table.insert(list, v)
					else
						table.remove(list, index)
						table.insert(list, v)
					end
				end
			end
		end
	end
	return list
end

--判断是否为置顶的仙魂
function My:IsTopSoul(list, type, lv, qua, onlyType, index, isEnd)
	for i,v in ipairs(list) do
		local key = tostring(v.soulId)
		local cfg = ImmSoulCfg[key]
		local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
		if cfg and lvCfg then
			local myQua = lvCfg.id % 10
			local isOne = #type <= 1 and #cfg.proType <=1
			local isTwo = #type > 1 and #cfg.proType > 1
			if cfg.onlyType == onlyType and isTwo then
				return self:IsTopQua(myQua, qua, lvCfg.lv, lv, i, index, isEnd)
			elseif cfg.proType[1] == type[1] and isOne then
				return self:IsTopQua(myQua, qua, lvCfg.lv, lv, i, index, isEnd)
			end
		end
	end
	return true, 0
end

--判断是否为更高品质的仙魂
function My:IsTopQua(myQua, qua, myLv, lv, i, index, isEnd)
	if myQua < qua then
		return true, i
	elseif myQua == qua then
		if myLv < lv then
			return true, i
		elseif myLv == lv then
			if index > 900 then
				return true, i
			else
				if isEnd then
					return true, i
				else
					return false, 0
				end
			end
		else
			return false, 0
		end
	else
		return false, 0
	end
end

--获取总属性
function My:GetAllPro(list)
	local proList = {}
	for i,v in ipairs(list) do
		local key = tostring(v.soulId)
		local cfg = ImmSoulCfg[key]
		local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
		if lvCfg == nil then return proList end
		self:SetProVal(proList, lvCfg.pro1, lvCfg.proVal1, cfg.wearType)
		self:SetProVal(proList, lvCfg.pro2, lvCfg.proVal2, cfg.wearType)
	end
	return proList
end

--设置属性值
function My:SetProVal(proList, Pro, Val, WearType)
	if pro ~= 0 then
		local proCfg = PropName[Pro]
		if proCfg then
			self.proTab = { name = proCfg.name, val = Val, type = Pro, wearType = WearType }
			table.insert(proList, self.proTab)
		end
	end
end

--获取红点列表
function My:GetActionList()
	local isUse1, isUse2 = self:IsUse()
	local isOne = false
	local isTwo = false
	local useList = self:GetAllPro(self.useList)
	local dic = {}
	for i,v in ipairs(useList) do
		local key = tostring(v.type)
		dic[key] = true
	end
	local bagList = self:GetAllPro(self.bagList)
	for i,v in ipairs(bagList) do
		local key = tostring(v.type)
		if not dic[key] then
			local isUse = self:IsUseFromType(dic, v.type)
			if isUse then
				if v.wearType == 1 then
					if isUse1 then
						isOne = true
					end
				elseif v.wearType == 2 then
					if isUse2 then
						isTwo = true
					end
				end
			end
		end
	end
	return isOne, isTwo
end

--根据类型判断是否能镶嵌
function My:IsUseFromType(dic, type)
	for i,v in ipairs(self.bagList) do
		local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
		if lvCfg then
			if lvCfg.pro1 == type or lvCfg.pro2 == type then
				local key1 = tostring(lvCfg.pro1)
				local key2 = tostring(lvCfg.pro2)
				if dic[key1] or dic[key2] then
					return false
				end
			end
		end
	end
	return true
end

--判断是否能镶嵌
function My:IsUse()
	local isUse1 = false
	local isUse2 = false
	local useDic = self:GetUseDic()
	for i,v in ipairs(self.openList) do
		local key = tostring(v)
		if not useDic[key] then
			if v < 907 then
				isUse1 = true
			else
				isUse2 = true
			end
		end
	end
	return isUse1, isUse2
end

--获取镶嵌字典
function My:GetUseDic()
	local dic = {}
	for i,v in ipairs(self.useList) do
		local key = tostring(v.index)
		dic[key] = true
	end
	return dic
end

--获取背包字典
function My:GetBagDic()
	local dic = {}
	for i,v in ipairs(self.bagList) do
		local key = tostring(v.index)
		dic[key] = v
	end
	return dic
end

--获取双属性仙魂分解信息
function My:GetDecompInfo(it)
	local compKey = tostring(it.soulId)
	local compCfg = ImmSoulCompCfg[compKey]
	local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, it.lvId)
	if compCfg and lvCfg then
		local cfg1, temp1 = BinTool.Find(ImmSoulLvCfg, compCfg.compNeed1)
		local cfg2, temp2 = BinTool.Find(ImmSoulLvCfg, compCfg.compNeed2)
		local Name = lvCfg.name
		local Val1 = ""
		local Val2 = ""
		if cfg1 and cfg2 then
			Val1 = cfg1.name
			Val2 = cfg2.name
		else
			return nil
		end
		local Stone = compCfg.needCount
		local Debris = lvCfg.getDebris
		self.decompTab = { name = Name, val1 = Val1, val2 = Val2, stone = Stone, debris = Debris }
		return self.decompTab
	end
	return nil
end

--获取镶嵌列表的可升级列表
function My:GetLvUpList()
	local list = {}
	for i,v in ipairs(self.useList) do
		local num = math.floor(v.lvId + 100000)
		local cfg, temp = BinTool.Find(ImmSoulLvCfg, num)
		if cfg then
			if self.debris < cfg.needDebris then
				table.insert(list, 0)
			else
				table.insert(list, v.index)
			end
		end
	end
	return list
end

--判断是否显示某个镶嵌部位的红点
function My:IsShowAction(pos)
	local list = self:GetLvUpList()
	for i,v in ipairs(list) do
		if v == pos then
			return true
		end
	end
	return false
end

--判断提示一键分解
function My:IsDecomp()
	for i,v in ipairs(self.bagList) do
		local key = tostring(v.soulId)
		local cfg = ImmSoulCfg[key]
		if cfg then
			if cfg.wearType == 0 then
				return true
			end
		end
	end
	return false
end

--根据品质获取格子背景
function My:GetCellBg(qua)
	local str = ""
	if qua == 1 then
        str = "cell_1"
    elseif qua == 2 then
        str = "cell_2"
    elseif qua == 3 then
        str = "cell_3"
    elseif qua == 4 then
        str = "cell_4"
    elseif qua == 5 then
        str = "cell_5"
	end
	return str
end

--通过等级ID获取基础ID
function My:GetBaseID(lvId)
	local r = 100000
	local s = 10000000
	local num1 = lvId % r
	local num2 = math.floor(lvId / s)
	local lv = num2 * 100 + 1
	local bid = lv * r + num1
	return bid
end

--获取仙魂道具描述
function My:GetCellDes(id)
	local str = ""
	local lvCfg, index = BinTool.Find(ImmSoulLvCfg, tonumber(id))
	if lvCfg then
		local pro1 = lvCfg.pro1
		local pro2 = lvCfg.pro2
		if pro1==0 and pro2==0 then
			str = "分解可获得仙尘"
		elseif pro1~=0 and pro2==0 then
			local cfg = PropName[pro1]
			local val = (cfg.show==1) and string.format("%.2f", lvCfg.proVal1/10000*100).."%" or lvCfg.proVal1
			str = string.format("使用后获得%s：\n%s+%s", lvCfg.name, cfg.name, val)
		elseif pro1~=0 and pro2~=0 then
			local cfg1 = PropName[pro1]
			local cfg2 = PropName[pro2]
			local val1 = (cfg1.show==1) and string.format("%.2f", lvCfg.proVal1/10000*100).."%" or lvCfg.proVal1
			local val2 = (cfg2.show==1) and string.format("%.2f", lvCfg.proVal2/10000*100).."%" or lvCfg.proVal2
			str = string.format("使用后获得%s：\n%s+%s\n%s+%s", lvCfg.name, cfg1.name, val1, cfg2.name, val2)
		end
	end
	return str
end

--判断仙魂系统是否开启
function My:IsOpen()
	return #self.openList > 0
end

--设置分解数量
function My:SetDecompCount(num)
	self.decompCount = num
end

--清空索引
function My:ClearIndex()
    self.togIndex = 0
	self.tabIndex = 0
end

--清理缓存
function My:Clear()
	self:ClearIndex()
	self.useList = {}
	self.bagList = {}
	self.debris = 0
	self.stone = 0
	self.openList = {}
	self.decompSet = 0
end
    
--释放资源
function My:Dispose()
    
end

return My
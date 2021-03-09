--[[
    拍卖行管理类
]]
AuctionMgr = Super:New{Name = "AuctionMgr"}

local M = AuctionMgr

M.leftBtnSelf = {{id=1, name="我的拍品"},
{id=2, name="拍品记录"},
{id=3, name="竞品记录"},
{id=4, name="道庭拍品记录"}}
M.FirstData = {}

function M:Init()
    self.firId = 0
    self.secId = 0

    self.secIdList = {}
    self.goodsList = {}
    self.goodsSelfList = {}
    self.sellLogs = {}
    self.buyLogs = {}
    self.familyLogs = {}
    self.secItemDic = {}

    self.eUpSecType = Event()
    self.eUpCurPrice = Event()
    self.eUpGoods = Event()
    self.eUpAttr = Event()

    self:InitSecItemList()
    self:InitFirstTypeTb()

    self:SetLsner(ProtoLsnr.Add)
end

function M:SetLsner(fun)
    fun(24702,self.RespFirstType,self)
    fun(24704,self.RespGoods,self)
    fun(24706,self.RespSearch,self)
    -- fun(24708,self.RespUpdate,self)
    fun(24712,self.RespBuy,self)
    fun(24718,self.RespOnShelf,self)
    fun(24722,self.RespCareGoods,self)
    fun(24724,self.RespInfoSelf,self)
    fun(24726,self.RespUpRecord,self)
    fun(24728,self.RespUpSelfGoods,self)
    fun(24730,self.RespAttr,self)
    fun(24732,self.ResUpdate,self)
    fun(24734,self.ResDel,self)
    fun(24736,self.ResAdd,self)
    fun(24720, self.ResqPutDown, self);
end

--===============初始化数据===============--
function M:InitSecItemList()
    local atmp = {}
    for k,v in pairs(AucFristType) do
        local children = v.children
        local tmp = {}
        for i,v1 in ipairs(children) do
            for k2,v2 in pairs(ItemData) do
                if v2.AucSecId == v1 then
                    table.insert(atmp,v2.id)
                    table.insert(tmp,v2.id)
                end
            end
        end
        if k ~= "1000" then
            self.secItemDic[k] = tmp
        end
    end
    self.secItemDic["1000"] = atmp
end

function M:InitFirstTypeTb()
    for k,v in pairs(AucFristType) do
        local temp = {}
        temp.id = v.id
        temp.name = v.name
        table.insert(M.FirstData,temp)
    end
end

--===============协议处理===============--
-- 道具自己使用
function M:ReqUseSelf(dic)
    local msg = ProtoPool.GetByID(20821)
    local list = msg.kv_list
    for k,v in pairs(dic) do
        local kv = list:add()
        kv.id = tonumber(k)
        kv.val = v
    end
    if #list > 0 then
        ProtoMgr.Send(msg)
    else
        UITip.Log("请选择需要使用的道具")
    end
end

-- 请求商品一级分类信息
function M:ReqFirstType(class)
    local msg = ProtoPool.GetByID(24701)
    msg.class = tonumber(class)
    ProtoMgr.Send(msg)
end

-- 返回商品一级分类信息
function M:RespFirstType(msg)
    if msg.err_code == 0 then
        local classList = msg.class_list
        self:SetSecIdList(classList)
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(err)
        return
    end
end

-- 请求商品二级分类信息
function M:ReqSecType()
    local msg = ProtoPool.GetByID(24703)
    local firstId = self:GetFirId()
    local secId = self:GetSecId()
    local class = 0
    if firstId == "1000" then
        class = firstId
    elseif secId == 0 then
        class = firstId
    else
        class = secId
    end
    local step = self:GetPJIndex() or 0
    local quality = self:GetPZIndex() or 0
    msg.class = tonumber(class)
    msg.quality = quality or 0
    msg.step = step or 0
    ProtoMgr.Send(msg)
end

-- 返回商品分类信息
function M:RespGoods(msg)
    self.originalData = nil
    TableTool.ClearDic(self.goodsList)
    if msg.err_code == 0 then
        local dataList = msg.auction_goods
        self:SwtichGoods(dataList,self.goodsList)
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(err)
        return
    end
    self.eUpGoods()
end

-- 请求搜索商品
function M:ReqSearch(list)
    local msg = ProtoPool.GetByID(24705)
    local idlist = msg.type_id_list
    for i,v in ipairs(list) do
        idlist:append(v)
    end
    ProtoMgr.Send(msg)
end

-- 返回搜索商品
function M:RespSearch(msg)
    self.originalData = nil
    TableTool.ClearDic(self.goodsList)
    local dataList = msg.auction_goods
    self:SwtichGoods(dataList,self.goodsList)
    self.eUpGoods()
end

-- 竞价、一口价请求
function M:ReqBuy(type,id,gold)
    local msg = ProtoPool.GetByID(24711)
    msg.type = type
    msg.id = id
    msg.gold = gold
    ProtoMgr.Send(msg)
end

-- 竞价、一口价返回
function M:RespBuy(msg)
    self.originalData = nil
    if msg.err_code == 0 then
        local type = msg.type
        local data = msg.auction_goods
        if type == 1 then
            self:UpGoods(data.id,self.goodsList)
        else
            self:SetGoodsData(data,self.goodsList)
        end
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(err)
        return
    end
end

-- 上架物品请求
function M:ReqOnShelf(dic)
    local msg = ProtoPool.GetByID(24717)
	local list = msg.sell_goods
    for k,v in pairs(dic) do
        local kv = list:add()
		kv.id=tonumber(k)
		kv.val=v
    end
    if #list > 0 then
        ProtoMgr.Send(msg)
    else
        UITip.Log("请选择需要上架的道具")
    end
end

-- 上架物品返回
function M:RespOnShelf(msg)
    if msg.err_code == 0 then
        --local id = msg.goods_id
        UITip.Log("上架成功")
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(err)
        return
    end
end

-- 关注物品请求
function M:RepCareGoods(type,id)
    local msg = ProtoPool.GetByID(24721)
    msg.type = type
    msg.type_id = id
    ProtoMgr.Send(msg)
end

-- 关注物品返回
function M:RespCareGoods(msg)
    if msg.err_code == 0 then
        local id = msg.type_id
        local type = msg.type
        if type == 1 then
            for i=#self.careList,1,-1 do
                if self.careList[i] == id then
                    table.remove( self.careList,i )
                end
            end
        else
            table.insert( self.careList, id )
        end
        self.eUpAttr(id,type)
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(err)
        return
    end
end

-- 个人信息推送
function M:RespInfoSelf(msg)
    self.careList = msg.care_type_ids
    local goodsSelfList = msg.auction_goods
    local sellLogs = msg.sell_logs
    local buyLogs = msg.buy_logs
    local familyLogs = msg.family_sell_logs

    self:SwtichGoods(goodsSelfList,self.goodsSelfList)
    self:SwtichLogs(sellLogs,self.sellLogs)
    self:SwtichLogs(buyLogs,self.buyLogs)
    self:SwtichLogs(familyLogs,self.familyLogs)
end

-- 记录更新推送
function M:RespUpRecord(msg)
    local type = msg.type
    local log = msg.log
    local logs = {self.sellLogs,self.buyLogs,self.familyLogs}
    local temp = {}
    table.insert( temp,log)
    self:SwtichLogs(temp,logs[type])
end

--个人拍品信息更新
function M:RespUpSelfGoods(msg)
    local delId = msg.del_goods_id
    local upGoods = msg.update_goods
    if delId ~= "0" then
        self:UpGoods(delId,self.goodsSelfList)
        return
    end
    local id = upGoods.id
    local list = self.goodsSelfList
    local isHas = false
    for i,v in ipairs(list) do
        if v.id == id then
            isHas = true
        end
    end
    if isHas then
        self:SetGoodsData(upGoods,list)
    else
        local temp = {}
        table.insert( temp, upGoods )
        self:SwtichGoods(temp,list)
    end
end


-- 关注信息返回
function M:RespAttr(msg)
    local type_id = msg.type_id
    self:SetAttrData(type_id)
end

-- 请求关闭面板
function M:RepClose()
    local msg = ProtoPool.GetByID(24709)
    ProtoMgr.Send(msg)
end

function M:ResUpdate(msg)
    local upData = msg.update_goods
    self:SetGoodsData(upData,self.goodsList)
    --self.eUpGoods()
    self.originalData = nil
end

function M:ResDel(msg)
    local delId = msg.del_goods_id
    self:UpGoods(delId,self.goodsList)
    self.originalData = nil
end

function M:ResAdd(msg)
    local add_goods = msg.add_goods
    local temp = {}
    table.insert( temp, add_goods )
    self:SwtichGoods(temp,list)
    self.eUpGoods()
end

--请求下架物品
function M:ReqPutDown(selectItem)
    local msg = ProtoPool.GetByID(24719);
    -- for k,v in pairs(selectDic) do
    --     msg.ids:append(tonumber(v.id));
    -- end
    if selectItem == nil then return end
    local id = tonumber(selectItem.data.id);
    msg.id = id;
    
    ProtoMgr.Send(msg);
end

--响应下架物品协议返回
function M:ResqPutDown(msg)
    if msg.err_code == 0 then
        UITip.Log("下架成功");
    else
        local error = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(error);
        return ;
    end
end

--==============数据处理================--
function M:SwtichGoods(tempList,List)
    for i,v in ipairs(tempList) do
        local temp = {}
        temp.id = v.id
        temp.type_id = v.type_id 
        temp.num = v.num
        local data = ItemData[tostring(v.type_id)]
        local qua = UIMisc.LabColor(data.quality)
        --temp.name = qua..data.name
        temp.name = StrTool.Concat(qua, data.name);
        temp.auction_time = v.auction_time
        temp.end_time = v.end_time
        temp.aucId = v.auction_role_id
        temp.cur_gold = v.cur_gold
        temp.from_type = v.from_type
        temp.from_id = v.from_id
        table.insert(List,temp)
    end
end

function M:UpGoods(delId,List)
    local list = List
    for i=#list,1,-1 do
        if list[i].id == delId then
            table.remove(list,i)
        end
    end
    self.eUpGoods()
end

function M:SwtichLogs(tempList,List)
    if tempList == nil or List == nil then return end
    for i,v in ipairs(tempList) do
        local temp = {}
        temp.time = v.time
        temp.type_id = v.type_id
        temp.num = v.num
        local data = ItemData[tostring(v.type_id)]
        local qua = UIMisc.LabColor(data.quality)
        temp.name = qua..data.name
        temp.gold = v.gold
        table.insert(List,temp)
    end
end

-- 竞价变动
function M:SetGoodsData(data,List)
    local dataList = List
    local id = data.id
    for i,v in ipairs(dataList) do
        if id == v.id then
            v.aucId = data.auction_role_id
            v.end_time = data.end_time
            v.cur_gold = data.cur_gold
            self.eUpCurPrice(v)
            return
        end
    end
end

-- 得到搜索列表
function M:GetSearchItemIdLocal(searchStr,data)
	local retIds = {};
	if searchStr == nil or searchStr == "" then
		return retIds;
	end

	--// 清除无用字符
	local cleanStr = StrTool.OnlyChnAndNum(searchStr);
	if cleanStr == nil or cleanStr == "" then
		return retIds;
	end
	local itemName = nil
	local sData = {}
	
	if not data then
        sData = ItemData
        for k,v in pairs(sData) do
            if v.AucSecId then
                itemName = v.name
                if string.len(cleanStr) <= string.len(itemName) then
                    if string.find(itemName, cleanStr) ~= nil then
                        retIds[#retIds + 1] = v.id
                    end
                end
            end
        end
	else
        sData = data
        for i,v in pairs(sData) do
            itemName = ItemData[tostring(v.id)].name
            if string.len(cleanStr) <= string.len(itemName) then
                if string.find(itemName, cleanStr) ~= nil then
                    retIds[#retIds + 1] = v
                end
            end
        end
	end
    
	return retIds;
end


-- 得到本地筛选数字
function M:GetByPZorPJ(goodList)
	local pz = self:GetPZIndex() or 0
	local pj = self:GetPJIndex() or 0
	local tempList = {}
	if pz == 0 and pj == 0 then
		for i,v in ipairs(goodList) do
			tempList[#tempList + 1] = v
		end
	elseif pz == 0 and pj ~= 0 then
        for i,v in ipairs(goodList) do
            if EquipBaseTemp[tostring(v.id)] then
                local wearRank = EquipBaseTemp[tostring(v.id)].wearRank
                if wearRank == pj  then
                    tempList[#tempList + 1] = v
                end
            end
		end
	elseif pz ~= 0 and pj == 0 then
        for i,v in ipairs(goodList) do
            local quality = ItemData[tostring(v.id)].quality
			if quality == pz  then
				tempList[#tempList + 1] = v
			end
		end
	elseif pz ~= 0 and pj ~= 0 then
        for i,v in ipairs(goodList) do
            local quality = ItemData[tostring(v.id)].quality
            if EquipBaseTemp[tostring(v.id)] then
                local equipData = EquipBaseTemp[tostring(v.id)]
                local wearRank =  equipData.wearRank
                if quality == pz and wearRank == pj then
                     tempList[#tempList + 1] = v
                end
            end
		end
	end
	return tempList
end

function M:SetSecIdList(data)
    self.secIdList = {}
    for i,v in ipairs(data) do
        temp = {}
        temp.id = v.id
        temp.num = v.val
        local secDic = AucSecType[tostring(v.id)]
        temp.name = secDic.name
        temp.icon = secDic.icon
        table.insert(self.secIdList, temp)
    end
    self.eUpSecType()
end

function M:SetFirId(firId)
    self.firId = firId
end

function M:GetFirId()
    return self.firId
end

function M:SetSecId(secId)
    self.secId = secId
end

function M:GetSecId()
    return self.secId
end

function M:GetCareList()
    return self.careList
end

function M:GetSecIdList()
    table.sort(self.secIdList,M.Sort)
    return self.secIdList
end

function M:GetFirstData()
    table.sort( M.FirstData, self.Sort )
    return M.FirstData
end

function M:SetPJIndex(pjIndex)
    self.pjIndex = pjIndex
end

function M:GetPJIndex()
    return self.pjIndex
end

function M:SetPZIndex(pzIndex)
    self.pzIndex = pzIndex
end

function M:GetPZIndex()
    return self.pzIndex
end

function M.Sort(a,b)
    local isJoin = FamilyMgr:JoinFamily();
    if isJoin then
        local familyData = FamilyMgr:GetFamilyData();
        if a.from_id == tostring(familyData.Id) and
            b.from_id ~= tostring(familyData.Id) then
            return true;
        elseif a.from_id ~= tostring(familyData.Id) and
            b.from_id == tostring(familyData.Id) then
            return false;
        elseif a.from_id == tostring(familyData.Id) and
            b.from_id == tostring(familyData.Id) then
            return tonumber(a.id) < tonumber(b.id);
        end
    end
    return tonumber(a.id) < tonumber(b.id)
end


-- 拍卖物品
function M:GetGoods()
    table.sort(self.goodsList, self.Sort)
    local data = self.goodsList
    local list = {}
    local num = #data
    for i=1, num do
        local index = math.ceil(i/3)
        if not list[index] then
            list[index] = {}
        end
        table.insert(list[index], data[i])
    end
    return list
end

function M:GetGoodsByIndex(index)
    local data = self:GetGoods()
    return data[index]
end

function M:SetGoodsDataByStr(str)
    if self.originalData then
        self.goodsList = self.originalData
    end
    local list = self.goodsList
    local temp = {}
    for i=1,#list do
        local item = list[i]
        local itemName = ItemData[tostring(item.type_id)].name
        if string.len(str) <= string.len(itemName) then
            if string.find(itemName, str) ~= nil then
                table.insert(temp, item)
            end
        end
    end

    -- local data = {}
    -- local num = #temp
    -- for i=1, num do
    --     local index = math.ceil(i/3)
    --     if not data[index] then
    --         data[index] = {}
    --     end
    --     table.insert(data[index], temp[i])
    -- end

    self.originalData = self.goodsList
    self.goodsList = temp
end
-- 我的拍品
function M:GetgoodsSelfList()
    local data = self.goodsSelfList
    local num = #data
    local list = {}
    for i=1, num do
        local index = math.ceil(i/4)
        if not list[index] then
            list[index] = {}
        end
        table.insert(list[index], data[i])
    end
    return list
end

function M:GetMyGoods()
    return self.goodsSelfList
end

function M:GetGoodsSelfByIndex(index)
    local data = self:GetgoodsSelfList()
    return data[index]
end

--拍品记录
function M:GetSellLogs()
    local temp = self:GetLogs(self.sellLogs)
    return temp
end

-- 竞拍记录
function M:GetbuyLogs()
    local temp = self:GetLogs(self.buyLogs)
    return temp
end

-- 行会拍品纪录
function M:GetFamilyLogs()
    local temp = self:GetLogs(self.familyLogs)
    return temp
end

function M:GetLogs(list)
    -- local num = #list
    -- local temp = {}
    -- if num > 30 then
    --     for i=1,30 do
    --         table.insert( temp,list[i] )
    --     end
    -- else
    --     temp = list
    -- end
    table.sort( list, self.SortTime )
    return list
end

function M.SortTime(a,b)
    return a.time > b.time
end

-- 关注物品推送
function M:SetAttrData(id)
    self.attrData = {}
    local attrData = self.attrData
    attrData.type_id = id
    data = ItemData[tostring(id)]
    local qua = UIMisc.LabColor(data.quality)
    attrData.name = qua..data.name
    UIMgr.Open(AttrTip.Name)
end

function M:GetAttrData()
    return self.attrData
end

function M:GetSecItemDic(secId,data)
    local temp = {}
    for i,v in ipairs(data) do
        local secid = ItemData[tostring(v.id)].AucSecId
         if secid == secId then
            table.insert(temp,v)
        end
    end
    return temp
end


function M:GetFirstItemDic(firstId)
    local tempList = {}
    local allList = {}
    local k = tostring(firstId)
    local list = self.secItemDic[k]
    for i,v in ipairs(list) do
        local temp = {}
        temp.id = v
        local qua = ItemData[tostring(v)].quality
        if EquipBaseTemp[tostring(v)] then
            local equipData = EquipBaseTemp[tostring(v)]
            temp.wearRank = equipData.wearRank or 0
            temp.wearParts = equipData.wearParts or 0
        end
        temp.qua = qua
        table.insert( tempList, temp )
    end
    if #tempList > 1 then
        local isItem = AucFristType[firstId].isPJ
        if isItem == 1 then
            table.sort(tempList, self.SortPJDic)
        else
            table.sort(tempList, self.SortPZDic)
        end
    end
    return tempList
end

function M:GetAllDecItem()
    local tempList = {}
    for k,v in pairs(AucFristType) do
        if v.id ~= 1000 then
            local id = tostring(v.id)
            local temp = AuctionMgr:GetFirstItemDic(id)
            for k1,v1 in ipairs(temp) do
                table.insert(tempList,v1)
            end
        end
    end
    return tempList
end

function M.SortPJDic(a,b)
    if a.qua ==  b.qua then
        if a.wearRank ==  b.wearRank then
            return a.wearParts > b.wearParts
        else
            return a.wearRank > b.wearRank
        end
    else
        return a.qua > b.qua
    end
end

function M.SortPZDic(a,b)
    if a.qua ==  b.qua then
        return a.id < b.id
    else
        return a.qua > b.qua
    end
end

function M:Clear()
    self.originalData = nil
    TableTool.ClearDic(self.secIdList)
    TableTool.ClearDic(self.goodsList)
    TableTool.ClearDic(self.goodsSelfList)
    TableTool.ClearDic(self.sellLogs)
    TableTool.ClearDic(self.buyLogs)
    TableTool.ClearDic(self.familyLogs)
end

return M
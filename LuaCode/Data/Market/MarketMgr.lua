--// 地图系统管理器

MarketMgr = Super:New{Name = "MarketMgr"}

local iLog = iTrace.eLog;
local iError = iTrace.Error;
local eError = iTrace.eError;
local ET = EventMgr.Trigger;

local mgrPre = {};
local itemCfg = {}

--// 初始化
function MarketMgr:Init()

	if mgrPre.init ~= nil and mgrPre.init == true then
 		return;
	end

	self:InitItemCfg()
 	--iLog("LY", " MarketMgr create !!! ");
	mgrPre.init = false;
	
	--// 市场销售商品存储结构
	mgrPre.sellGoodsTbl = {};
	--// 市场求购商品存储结构
	mgrPre.wantGoodsTbl = {};
	--// 市场日志列表
	mgrPre.logList = {};
	--// 交易解禁时间 0-为无限制
	mgrPre.prohibitTime = 0;
	--// 摆摊上架物品
	mgrPre.selfOnShelfBuyGoods = {};
	--// 求购上架物品
	mgrPre.selfOnShelfWantGoods = {};

	mgrPre.showItemTbl = nil;

	mgrPre.showEquipTbl = nil;

	self:AddLsnr();

	self.eNewWantGoods = Event()
	self.eSell = Event()

	self:InitMktGoodsTbl();
	self:InitMarketItem();

	--// 当前市场面板打开界面: 1、摆摊  2、求购
	mgrPre.curMktOpenState = 0;
	--// 当前选择一级属性Id
	mgrPre.curSelFstId = 0;
	--// 当前选择二级属性Id
	mgrPre.curSelSceId = 0;
	--// 当前选择购买物品Id
	mgrPre.curSelBuyItemId = 0;
	--// 当前选择购买物品名称
	mgrPre.curSelBuyItemName = "";
	--// 当前选择购买物品是否有密码
	mgrPre.curSelBuyItemPsw = false;
	--// 当前选择物品价钱
	mgrPre.curSelBuyItemCost = 0;
	--// 当前选择下架商品Id
	mgrPre.curSelDownShelfItemId = 0;
	--// 默认排序
	mgrPre.useSortType = 1;
	--// 单价排序：0、降序，1、升序
	mgrPre.onePSortIndex = 0;
	--// 总价排序：0、降序，1、升序
	mgrPre.allPSortIndex = 0;
	--// 需要向下搜索（第一次使用）
	mgrPre.firstSearch = true;
	--// 已经到达数据底部
	mgrPre.searchBottom = false;
	--// 等待搜索返回
	mgrPre.waitSearching = false;
	--// 品阶筛选索引
	mgrPre.pjIndex = 0;
	--// 品质筛选索引
	mgrPre.pzIndex = 0;
	--// 密码筛选索引
	mgrPre.mmUse = 0;
	--// 求购品阶筛选索引
	mgrPre.wantpjIndex = 0
	--// 求购品质筛选索引
	mgrPre.wantpzIndex = 0
	--// 我要求购品质筛选索引
	mgrPre.IwantpzIndex = 0
	--// 我要求购品阶筛选索引
	mgrPre.IwantpjIndex = 0
	--// 搜索选中Id列表
	mgrPre.filterIds = nil;
	--// 出售密码
	mgrPre.salePsw = nil;

	mgrPre.init = true;
	 
end

function MarketMgr:InitItemCfg()
	for k,v in pairs(ItemData) do
		if v.SecType ~= nil and v.SecType > 0 then
			table.insert(itemCfg, v)
		end
	end
	table.sort(itemCfg, function(a,b) return a.id < b.id end)
end

--// 添加监听
function MarketMgr:AddLsnr()
	--// 物品数量返回
	ProtoLsnr.AddByName("m_market_class_num_toc", self.RespMarketClassNum, self);
	--// 市场搜索返回
	ProtoLsnr.AddByName("m_market_search_toc", self.RespMarketSearch, self);
	--// 市场购买返回
	ProtoLsnr.AddByName("m_market_buy_toc", self.RespMarketBuy, self);
	--// 市场上架返回
	ProtoLsnr.AddByName("m_market_on_shelf_toc", self.RespMarketOnShelf, self);
	--// 市场下架返回
	ProtoLsnr.AddByName("m_market_down_shelf_toc", self.RespMarketDownShelf, self);
	--// 市场交易日志返回
	ProtoLsnr.AddByName("m_market_self_log_toc", self.RespMarketLlog, self);
	--// 市场增加日志返回
	ProtoLsnr.AddByName("m_market_add_log_toc", self.RespMarketAddLog, self);
	--// 市场自身信息返回
	ProtoLsnr.AddByName("m_market_self_info_toc", self.RespMarketInfo, self);
	--// 市场完成交易返回
	ProtoLsnr.AddByName("m_market_info_change_toc", self.RespMarketInfoChange, self);
	--// 求购上架完成返回
	ProtoLsnr.AddByName("m_market_demand_toc", self.RespMarketWantInfos, self);
	--// 求购出售成功返回
	ProtoLsnr.AddByName("m_market_sell_demand_toc", self.RespMarketWantGoods, self);
end

--// 清理缓存
function MarketMgr:Clear()
	self:ResetSearchState();
	mgrPre.init = false;
end

--// 释放
function MarketMgr:Dispose()
	
end

--// 
function MarketMgr:Update()
	
end

--// 初始化市场物品数据结构
function MarketMgr:InitMktGoodsTbl()
	mgrPre.sellGoodsTbl = {};

	--// 建立一级属性
	for k, v in pairs(MarketDic) do
		if v.preids ~= nil and v.preids[1] == 0 then
			local fData = {};
			fData.id = v.id;
			fData.category = 1;
			fData.name = v.name;
			--// 子属性字典
			fData.subDataDic = {};
			fData.goodList = {};
			fData.getClassNumId = 0;
			mgrPre.sellGoodsTbl[k] = fData;
		end
	end
	table.sort(mgrPre.sellGoodsTbl, function(a, b)
		return a.id < b.id;
	end);

	--// 建立二级属性
	for k, v in pairs(MarketDic) do
		if v.preids ~= nil and v.preids[1] ~= 0 then
			--// 判断类型
			if v.category == 1 then
				iError("LY", "MarketDic category error !!! ");
			elseif v.category == 2 then
				for i = 1, #v.preids do
					local tDic = MarketDic[tostring(v.preids[i])];
					if tDic ~= nil then
						local sData = {};
						sData.id = v.id;
						sData.category = 2;
						sData.name = v.name;
						sData.num = 0;
						--//数据列表
						sData.goodList = {};
						mgrPre.sellGoodsTbl[tostring(tDic.preids[1])].subDataDic[k] = sData;
					end
				end
			elseif v.category == 3 then
				for i = 1, #v.preids do
					local sData = {};
					sData.id = v.id;
					sData.category = 3;
					sData.name = v.name;
					sData.num = 0;
					--//数据列表
					sData.goodList = {};
					mgrPre.sellGoodsTbl[tostring(v.preids[i])].getClassNumId = v.id;
					mgrPre.sellGoodsTbl[tostring(v.preids[i])].subDataDic[k] = sData;
				end
			end
		end
	end
	for k, v in pairs(mgrPre.sellGoodsTbl) do
		if v.subDataDic ~= nil and #v.subDataDic > 0 then
			table.sort(v.subDataDic, function(a, b)
				if a.category ~= b.category then
					return  a.category > b.category;
				else
					return a.id < b.id;
				end
			end);
		end
	end


	mgrPre.wantGoodsTbl = {};

	--// 建立一级属性
	for k, v in pairs(MarketDic) do
		if v.preids ~= nil and v.preids[1] == 0 then
			local fData = {};
			fData.id = v.id;
			fData.category = 1;
			fData.name = v.name;
			--// 子属性字典
			fData.subDataDic = {};
			fData.goodList = {};
			fData.getClassNumId = 0;
			mgrPre.wantGoodsTbl[k] = fData;
		end
	end

	table.sort(mgrPre.wantGoodsTbl, function(a, b)
		return a.id < b.id;
	end);

	--// 建立二级属性
	for k, v in pairs(MarketDic) do
		if v.preids ~= nil and v.preids[1] ~= 0 then
			--// 判断类型
			if v.category == 1 then
				iError("LY", "MarketDic category error !!! ");
			elseif v.category == 2 then
				for i = 1, #v.preids do
					local tDic = MarketDic[tostring(v.preids[i])];
					if tDic ~= nil then
						local sData = {};
						sData.id = v.id;
						sData.category = 2;
						sData.name = v.name;
						sData.num = 0;
						--//数据列表
						sData.goodList = {};
						mgrPre.wantGoodsTbl[tostring(tDic.preids[1])].subDataDic[k] = sData;
					end
				end
			elseif v.category == 3 then
				for i = 1, #v.preids do
					local sData = {};
					sData.id = v.id;
					sData.category = 3;
					sData.name = v.name;
					sData.num = 0;
					--//数据列表
					sData.goodList = {};
					mgrPre.wantGoodsTbl[tostring(v.preids[i])].getClassNumId = v.id;
					mgrPre.wantGoodsTbl[tostring(v.preids[i])].subDataDic[k] = sData;
				end
			end
		end
	end
	for k, v in pairs(mgrPre.wantGoodsTbl) do
		if v.subDataDic ~= nil and #v.subDataDic > 0 then
			table.sort(v.subDataDic, function(a, b)
				if a.category ~= b.category then
					return a.category > b.category;
				else
					return a.id < b.id;
				end
			end);
		end
	end
end

function MarketMgr:InitMarketItem()
	mgrPre.showItemTbl = {};
	mgrPre.showEquipTbl = {};

	local lastShowItem = nil;
	-- local len = ItemData
	local len = #itemCfg
	for i=1,len do
		local v = itemCfg[i]
		local k = tostring(v.id)
		if v.SecType ~= nil then

			local nowEquipItem = EquipBaseTemp[k];

			local tShowItem = {};
			--// 道具
			if nowEquipItem == nil then
				--local tShowItem = {};
				tShowItem.id = v.id;
				tShowItem.name = v.name;
				tShowItem.color = v.quality;
				tShowItem.lv = v.useLevel;
				tShowItem.secType = v.SecType

				mgrPre.showItemTbl[#mgrPre.showItemTbl + 1] = tShowItem;
			--// 装备
			else
				if #mgrPre.showEquipTbl == 0 then
					--local tShowItem = {};
					tShowItem.id = v.id;
					tShowItem.num = 1;
					tShowItem.name = v.name;
					tShowItem.color = v.quality;
					tShowItem.lv = v.useLevel;
					tShowItem.secType = v.SecType
					tShowItem.wearRank = nowEquipItem.wearRank;
					tShowItem.subItemTbl = {}

					mgrPre.showEquipTbl[#mgrPre.showEquipTbl+1] = tShowItem;
					local sData = {}
					sData.id = v.id;
					sData.startLv = nowEquipItem.startLv;
					local subItemTbl = mgrPre.showEquipTbl[#mgrPre.showEquipTbl].subItemTbl
					subItemTbl[#subItemTbl+1]=sData;
				else
					if v.name ~= lastShowItem.name or v.quality ~= lastShowItem.color or nowEquipItem.wearRank ~= lastShowItem.wearRank then
						tShowItem.id = v.id;
						tShowItem.num = 1;
						tShowItem.name = v.name;
						tShowItem.color = v.quality;
						tShowItem.lv = v.useLevel;
						tShowItem.secType = v.SecType
						tShowItem.wearRank = nowEquipItem.wearRank;
						tShowItem.subItemTbl = {}
						mgrPre.showEquipTbl[#mgrPre.showEquipTbl+1] = tShowItem;
						local sData = {}
						sData.id = v.id;
						sData.startLv = nowEquipItem.startLv;

						local subItemTbl = mgrPre.showEquipTbl[#mgrPre.showEquipTbl].subItemTbl
						subItemTbl[#subItemTbl+1]=sData;
					else
						local sData = {}
						sData.id = v.id;
						sData.startLv = nowEquipItem.startLv;
						local subItemTbl = mgrPre.showEquipTbl[#mgrPre.showEquipTbl].subItemTbl
						subItemTbl[#subItemTbl+1]=sData;
					end
				end

				if tShowItem ~= nil and tShowItem.name ~= nil then
					lastShowItem = tShowItem;
				end
			end
		end
	end
end
	


---------------------------------- 向服务器请求 ----------------------------------

--// 请求类别总数
function MarketMgr:ReqMarketClassNum(fstId,typeIndex)

	local fstTypeData = {};
	if typeIndex == nil then typeIndex = mgrPre.curMktOpenState end

	if typeIndex == 1 then
		fstTypeData = mgrPre.sellGoodsTbl[tostring(fstId)];
	else
		fstTypeData = mgrPre.wantGoodsTbl[tostring(fstId)];
	end
	if fstTypeData == nil or fstTypeData.getClassNumId == nil or fstTypeData.getClassNumId <= 0 then
		return;
	end

	iLog("LY", "m_market_class_num_tos : "..fstTypeData.getClassNumId);

	local msg = ProtoPool.Get("m_market_class_num_tos");
	msg.class = fstTypeData.getClassNumId;
	msg.type = typeIndex;
	ProtoMgr.Send(msg);
end

--// 请求市场搜索信息
--// typeIndex：市场类型 1-摆摊 2-求购
--// keyWord：搜索关键字
--// fType：第一分类
--// sType：第二分类
--// col：品质
--// order：品阶
--// psw：密码
function MarketMgr:ReqSearchItemInfo(typeIndex, keyWord, fType, sType, col, order, dic, sortKv, psw)
	if mgrPre.waitSearching == true or mgrPre.searchBottom == true then
		-- if mgrPre.waitSearching == true then
		-- 	iLog("LY", "Market waiting search return !!! ");
		-- end
		-- if mgrPre.searchBottom == true then
		-- 	iLog("LY", "Market search reach botton !!! ");
		-- end
		return;
	end

	iLog("LY", "m_market_search_tos : fstId -- "..fType.."   secId -- "..sType);

	local msg = ProtoPool.Get("m_market_search_tos");
	msg.type = typeIndex;
	if keyWord ~= nil and #keyWord > 0 then
		for i = 1, #keyWord do
			msg.key_word:append(keyWord[i]);
		end
	end
	msg.first_type = fType;
	msg.second_type = sType;
	msg.color = col;
	msg.order = order;
	msg.dic = dic
	msg.search_type = mgrPre.firstSearch;
	msg.sort_type.id = sortKv.id;
	msg.sort_type.val = sortKv.val;
	msg.password = psw;

	ProtoMgr.Send(msg);
	
	mgrPre.waitSearching = true;
end

--// 请求市场搜索信息
--// typeIndex：市场类型 1-摆摊 2-求购
--// keyWord：搜索关键字
--// fType：第一分类
--// sType：第二分类
--// col：品质
--// order：品阶
--// psw：密码
function MarketMgr:ReqSearchItemInfoDetail(typeIndex, keyWord, fType, sType, col, order, dic, sortKv, psw, category, unique)
	if mgrPre.waitSearching == true or mgrPre.searchBottom == true then
		if mgrPre.waitSearching == true then
			iLog("LY", "Market waiting search return !!! ");
		end
		if mgrPre.searchBottom == true then
			iLog("LY", "Market search reach botton !!! ");
		end
		return;
	end

	if category == 1 then
		--MarketMgr:ReqSearchItemInfo(typeIndex, keyWord, fType, 0, col, order, dic, psw);
		iLog("LY", "Market search type category is 1, no send !!! ");
		return;
	elseif category == 2 then
		if unique == 1 then
			-- if fType == 1051 then
			-- 	local sendSecId = MarketDic[tostring(sType)].preids[1];
			-- else
			-- 	local sendSecId = MarketDic[tostring(sType)].preids[2]; 
			-- end
			local preids = MarketDic[tostring(sType)].preids
			local sendSecId = 0;
			if fType == 1051 or fType == 1052 then
				sendSecId = fType == 1051 and preids[1] or preids[2]
			else
				sendSecId = preids[1]
				--sendSecId = fType;
			end
			MarketMgr:ReqSearchItemInfo(typeIndex, keyWord, sType, sendSecId, col, order, dic, sortKv, psw);
		elseif unique == 0 then
			MarketMgr:ReqSearchItemInfo(typeIndex, keyWord, sType, 0, col, order, dic, sortKv, psw);
		else
			iError("LY", "MarketMgr:ReqSearchItemInfoDetail unique type error !!! "..unique);
		end
	elseif category == 3 then
		if sType == 0 then
			MarketMgr:ReqSearchItemInfo(typeIndex, keyWord, fType, 0, col, order, dic, sortKv, psw);
		else
			MarketMgr:ReqSearchItemInfo(typeIndex, keyWord, sType, 0, col, order, dic, sortKv, psw);
		end
	else
		--iError("LY", "MarketMgr:ReqSearchItemInfoDetail category type error !!! "..category);
	end
end

--// 请求当前指定Id的物品
function MarketMgr:ReqCurSearchItemInfo()
	if mgrPre.curMktOpenState <= 0 then
		return;
	end
	local tDic = nil;
	local dic = 0
	local secId = self:GetSelSecId()
	if secId > 0 then
		tDic = MarketDic[tostring(secId)];
		dic = secId;
	else
		tDic = MarketDic[tostring(mgrPre.curSelFstId)];
		dic = mgrPre.curSelFstId;
	end
	
	if tDic == nil then
		iError("LY", "Can not get MarketDic info !!! "..mgrPre.curSelFstId.."      "..secId);
		return;
	end

	--// 临时设置
	local sortKv = {};
	--if mgrPre.curMktOpenState == 1 then
		sortKv.id = mgrPre.useSortType;
		if mgrPre.useSortType == 1 then
			sortKv.val = 1;
		elseif mgrPre.useSortType == 2 then
			sortKv.val = mgrPre.onePSortIndex + 1;
		elseif mgrPre.useSortType == 3 then
			sortKv.val = mgrPre.allPSortIndex + 1;
		end
	--else
		--sortKv.id = 1;
		--sortKv.val = 1;
	--end
	
	local pzIdx = 0;
	local pjIdx = 0;
	local sendFstId = self:GetSelFstId();
	if mgrPre.curMktOpenState == 1 then
		local fstData = mgrPre.sellGoodsTbl[tostring(sendFstId)];
		if mgrPre.pzIndex > 0 then
			--pzIdx = mgrPre.pzIndex + 2;
			pzIdx = mgrPre.pzIndex;
		end
		if mgrPre.pjIndex > 0 then
			--pjIdx =  mgrPre.pjIndex + 3;
			pjIdx =  mgrPre.pjIndex;
		end
	else
		local fstData = mgrPre.wantGoodsTbl[tostring(sendFstId)];
		if mgrPre.wantpzIndex > 0 then
			--pzIdx = mgrPre.wantpzIndex + 2;
			pzIdx = mgrPre.wantpzIndex
		end
		if mgrPre.wantpjIndex > 0 then
			--pjIdx =  mgrPre.wantpjIndex + 3;
			pjIdx =  mgrPre.wantpjIndex
		end
	end
	if fstData ~= nil and fstData.getClassNumId ~= nil and fstData.getClassNumId > 0 then
		sendFstId = fstData.getClassNumId;
	end
	MarketMgr:ReqSearchItemInfoDetail(mgrPre.curMktOpenState, mgrPre.filterIds, sendFstId, secId, pzIdx, pjIdx, dic, sortKv, mgrPre.mmUse + 1, tDic.category, tDic.unique);
end

--// 市场购买商品
function MarketMgr:ReqMarketBuy(itemId, psw)

	local msg = ProtoPool.Get("m_market_buy_tos");
	msg.id = itemId;
	if psw == nil then
		msg.password = "";
	else
		msg.password = psw;
	end

    ProtoMgr.Send(msg);
end

--// 市场上架商品
--// itemUId：背包ID
--// number：数量
--// totalPrice：总价
--// psw：密码
function MarketMgr:ReqMarketOnShelf(itemUId, number, totalPrice, unitPrice, psw)
	local msg = ProtoPool.Get("m_market_on_shelf_tos");
	msg.id = itemUId;
	msg.num = number;
	msg.total_price = totalPrice;
	msg.unit_price = unitPrice;
	if psw == nil then
		msg.password = "";
	else
		msg.password = psw;
	end

    ProtoMgr.Send(msg);
end

--// 请求市场物品下架
function MarketMgr:ReqMarketDownShelf(markeyType, itemId)
	local msg = ProtoPool.Get("m_market_down_shelf_tos");
	msg.id = itemId;
	msg.market_type = markeyType;

    ProtoMgr.Send(msg);
end

--// 请求市场日志
function MarketMgr:ReqMarketLog()
	local msg = ProtoPool.Get("m_market_self_log_tos");
	ProtoMgr.Send(msg);
end

--// 自身市场信息
function MarketMgr:ReqMarketInfoTos()
	local msg = ProtoPool.Get("m_market_self_info_tos");
	ProtoMgr.Send(msg);
end

--// 请求求购信息
function MarketMgr:ReqMarketWantInfos(list)
	local msg = ProtoPool.Get("m_market_demand_tos");
	msg.info.total_price = tonumber(list.price);
	msg.info.type_id = tonumber(list.id)
	msg.info.num =  tonumber(list.num)
	ProtoMgr.Send(msg);
end

--// 请求出售求购物品
function MarketMgr:ReqMarketWantGoods(id,itemid)
	local msg = ProtoPool.Get("m_market_sell_demand_tos");
	msg.id = id
	msg.demand_id = itemid
	ProtoMgr.Send(msg);
end

-------------------------------------------------------------------------------

---------------------------------- 服务器推送返回 ----------------------------------

--// 请求出售求购物品返回
function MarketMgr:RespMarketWantGoods(msg)
	if msg == nil then
		return;
	end
	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		return;
	end
	
	self:DeleteLocalBuyItem(msg.id);
	UITip.Log("出售成功")
	self.eSell()
end

--// 请求求购信息返回
function MarketMgr:RespMarketWantInfos(msg)
	if msg == nil then
		return;
	end
	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		return;
	else
		UITip.Log("求购成功")
	end

	local onShelfGood = self:SwitchMarketGoodData(msg.demand_grid);

	mgrPre.selfOnShelfWantGoods[#mgrPre.selfOnShelfWantGoods + 1] = onShelfGood;
	self.eNewWantGoods()
end

--// 请求类别总数返回
function MarketMgr:RespMarketClassNum(msg)

	if msg == nil then
		return;
	end 

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end
	if msg.type == 1 then
		for i = 1, #msg.list do
			local dicId = msg.list[i].id;
			local claNum = msg.list[i].val;
			for k, v in pairs(mgrPre.sellGoodsTbl) do
				if v.subDataDic[tostring(dicId)] ~= nil then
					v.subDataDic[tostring(dicId)].num = claNum;
				end
			end
		end
	else
		for i = 1, #msg.list do
			local dicId = msg.list[i].id;
			local claNum = msg.list[i].val;
			for k, v in pairs(mgrPre.wantGoodsTbl) do
				if v.subDataDic[tostring(dicId)] ~= nil then
					v.subDataDic[tostring(dicId)].num = claNum;
				end
			end
		end
	end

	ET("NewClassNum");
end

--// 搜索信息到达
function MarketMgr:RespMarketSearch(msg)
	if msg == nil then
		return;
	end

	if mgrPre.waitSearching == false then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	local dicId = msg.dic_id;
	iLog("LY", "m_market_search_toc dic_id : "..dicId);
	--// 市场销售数据
	if msg.type == 1 then
		local fstDic = mgrPre.sellGoodsTbl[tostring(dicId)];
		--// 一级属性
		if fstDic ~= nil then
			if mgrPre.firstSearch == true then
				fstDic.goodList = {};
			end
			for i = 1, #msg.goods do
				fstDic.goodList[#fstDic.goodList + 1] = self:SwitchMarketGoodData(msg.goods[i]);
			end
		--// 二级属性
		else
			for k, v in pairs(mgrPre.sellGoodsTbl) do
				local tSD = v.subDataDic[tostring(dicId)];
				if tSD ~= nil then
					if mgrPre.firstSearch == true then
						tSD.goodList = {};
					end
					for j = 1, #msg.goods do
						tSD.goodList[#tSD.goodList + 1] = self:SwitchMarketGoodData(msg.goods[j]);
					end
				end
			end
		end
	--// 市场求购数据
	elseif msg.type == 2 then

		local fstDic = mgrPre.wantGoodsTbl[tostring(dicId)];
		--// 一级属性
		if fstDic ~= nil then
			if mgrPre.firstSearch == true then
				fstDic.goodList = {};
			end
			for i = 1, #msg.goods do
				fstDic.goodList[#fstDic.goodList + 1] = self:SwitchMarketGoodData(msg.goods[i]);
			end
		--// 二级属性
		else
			for k, v in pairs(mgrPre.wantGoodsTbl) do
				local tSD = v.subDataDic[tostring(dicId)];
				if tSD ~= nil then
					if mgrPre.firstSearch == true then
						tSD.goodList = {};
					end
					for j = 1, #msg.goods do
						tSD.goodList[#tSD.goodList + 1] = self:SwitchMarketGoodData(msg.goods[j]);
					end
				end
			end
		end
	end

	mgrPre.waitSearching = false;
	--mgrPre.firstSearch = false;
	mgrPre.searchBottom = msg.is_null;
	ET("NewMarketGoods");
	mgrPre.firstSearch = false;

	--ET("NewMarketGoods");
end

--// 市场购买商品返回
function MarketMgr:RespMarketBuy(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		MarketMgr:ResetToFirstState();
		self:ReqCurSearchItemInfo();
		return;
	end

	UITip.Log("购买成功！");

	--// 删除本地购买成功物品
	--print("------------------------------------    "..msg.id)
	self:DeleteLocalBuyItem(msg.id);

	ET("NewMarketGoods");
end

--// 市场上架商品返回
function MarketMgr:RespMarketOnShelf(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	local onShelfGood = self:SwitchMarketGoodData(msg.sell_grid);

	mgrPre.selfOnShelfBuyGoods[#mgrPre.selfOnShelfBuyGoods + 1] = onShelfGood;

	ET("NewMarketOnShelf");
end

--// 请求市场物品下架返回
function MarketMgr:RespMarketDownShelf(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	if msg.grid_type == 1 then
		local newList = {}
		for i = 1, #mgrPre.selfOnShelfBuyGoods do
			if mgrPre.selfOnShelfBuyGoods[i].id ~= msg.grid_id then
				newList[#newList + 1] = mgrPre.selfOnShelfBuyGoods[i];
			end
		end
		mgrPre.selfOnShelfBuyGoods = newList;

	elseif msg.grid_type == 2 then
		local newList = {}
		for i = 1, #mgrPre.selfOnShelfWantGoods do
			if mgrPre.selfOnShelfWantGoods[i].id ~= msg.grid_id then
				newList[#newList + 1] = mgrPre.selfOnShelfWantGoods[i];
			end
		end
		mgrPre.selfOnShelfWantGoods = newList;
	end

	ET("NewMarketOnShelf");
end

--// 市场日志返回
function MarketMgr:RespMarketLlog(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	mgrPre.logList = {};

	if msg.logs ~= nil then
		for i = 1, #msg.logs do
			mgrPre.logList[#mgrPre.logList + 1] = MarketMgr:SwitchMarketLog(msg.logs[i]);
		end
	end

	ET("NewMarketLog");
end

--// 增加日志
function MarketMgr:RespMarketAddLog(msg)
	if msg == nil or msg.log then
		return;
	end

	mgrPre.logList[#mgrPre.logList + 1] = MarketMgr:SwitchMarketLog(msg.log);

	ET("NewMarketLog");
end

--// 自身市场信息返回
function MarketMgr:RespMarketInfo(msg)
	if msg == nil then
		return;
	end

	if msg.err_code ~= nil and msg.err_code > 0 then
		UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
		eError("LY", ErrorCodeMgr.GetError(msg.err_code));
		return;
	end

	mgrPre.selfOnShelfBuyGoods = {};
	for i = 1, #msg.sell_grid do
		mgrPre.selfOnShelfBuyGoods[#mgrPre.selfOnShelfBuyGoods + 1] = self:SwitchMarketGoodData(msg.sell_grid[i]);
	end

	mgrPre.selfOnShelfWantGoods = {};
	for i = 1, #msg.demand_grid do
		mgrPre.selfOnShelfWantGoods[#mgrPre.selfOnShelfWantGoods + 1] = self:SwitchMarketGoodData(msg.demand_grid[i]);
	end

	ET("NewMarketOnShelf");
end

--// 市场完成交易（删除上架信息）
function MarketMgr:RespMarketInfoChange(msg)
	if msg == nil then
		return;
	end

	if msg.type == 2 then
		local newList = {}
		for i = 1, #mgrPre.selfOnShelfBuyGoods do
			if mgrPre.selfOnShelfBuyGoods[i].id ~= msg.id then
				newList[#newList + 1] = mgrPre.selfOnShelfBuyGoods[i];
			end
		end
		mgrPre.selfOnShelfBuyGoods = newList;
	elseif msg.type == 4 then
		local newList = {}
		for i = 1, #mgrPre.selfOnShelfWantGoods do
			if mgrPre.selfOnShelfWantGoods[i].id ~= msg.id then
				newList[#newList + 1] = mgrPre.selfOnShelfWantGoods[i];
			end
		end
		mgrPre.selfOnShelfWantGoods = newList;
	end

	ET("NewMarketOnShelf");
end

-------------------------------------------------------------------------------

---------------------------------- 监听函数部分 ----------------------------------



-------------------------------------------------------------------------------

---------------------------------- 处理数据部分 ----------------------------------

--// 转换市场商品数据
function MarketMgr:SwitchMarketGoodData(oriData)
	local retData = {};

	--// 市场ID
	retData.id = oriData.id;
	--// 主人Id 
	retData.roleId = oriData.role_id;
	--// 道具type_id
	retData.typeId = oriData.type_id;
	--// 数量
	retData.num = oriData.num;

	retData.name = oriData.role_name;
	--// 装备卓越属性
	-- retData.excellentList = {};
	-- if oriData.excellent_list ~= nil then
	-- 	for i = 1, #oriData.excellent_list do
	-- 		local exData = {};
	-- 		exData.key = oriData.excellent_list[i].key;
	-- 		exData.val = oriData.excellent_list[i].val;
	-- 		retData.excellentList[#retData.excellentList + 1] = exData;
	-- 	end
	-- end
	--// 单价
	retData.unitPrice = oriData.unit_price;
	--// 总价
	retData.totalPrice = oriData.total_price;
	--// 密码（空 -没有  1 - 有）
	if oriData.password == nil or oriData.password == "" then
		retData.password = false;
	else
		retData.password = true;
	end

	retData.itemCellData = self:SwitchMarketGoodsToItemTbl(oriData);

	return retData;
end

--// 转换市场物品到背包物品格式
function MarketMgr:SwitchMarketGoodsToItemTbl(oriData)
	local goodData = {};

	goodData.id = oriData.id;
	--道具表id
	goodData.type_id = oriData.type_id;
	--是否绑定
	goodData.bind = false;
	--数量
	goodData.num = oriData.num;

	--卓越属性
	goodData.eDic = {};
	for i = 1, #oriData.excellent_list do
		goodData.eDic[oriData.excellent_list[i].id] = oriData.excellent_list[i].val;
	end

	--翅膀
	goodData.wing_id = nil;
	goodData.bList = {};
	goodData.lDic = {};
	
	--goodData.startTime = oriData.start_time; --开始生效的时间
	--goodData.endTime = oriData.end_time;  --now>endTime 过期

	return goodData;
end

--// 转换市场日志数据
function MarketMgr:SwitchMarketLog(oriData)
	local retData = {};

	--// 背包数据
	retData.id = oriData.id;
	--// 道具type_id
	retData.typeId = oriData.type_id;
	--// 数量
	retData.num = oriData.num;
	--// 装备卓越属性
	-- retData.excellentList = {};
	-- if oriData.excellent_list ~= nil then
	-- 	for i = 1, #oriData.excellent_list do
	-- 		local exData = {};
	-- 		exData.key = oriData.excellent_list[i].key;
	-- 		exData.val = oriData.excellent_list[i].val;
	-- 		retData.excellentList[#retData.excellentList + 1] = exData;
	-- 	end
	-- end

	retData.itemCellData = self:SwitchMarketGoodsToItemTbl(oriData);

	--// 单价
	retData.unitPrice = oriData.unit_price;
	--// 总价
	retData.totalPrice = oriData.total_price;
	--// 密码（" 空 -没有 "）
	--retData.password = oriData.password;
	--// 发生时间
	retData.time = oriData.time;
	--// 日志类型
	retData.logType = oriData.log_type;
	--// 税收
	retData.tax = oriData.tax;

	return retData;
end

--// 检测物品Id是否存在列表中
function MarketMgr:CheckGoodsIdExist(goodList, itemId)
	for i = 1, #goodList do
		if goodList[i].id == itemId then
			return true;
		end
	end

	return false;
end

--// 删除本地购买成功数据
function MarketMgr:DeleteLocalBuyItem(itemId)
	local Tbl = {}
	if mgrPre.curMktOpenState == 1  then
		Tbl = mgrPre.sellGoodsTbl
	else
		Tbl = mgrPre.wantGoodsTbl
	end
	for k, v in pairs(Tbl) do
		if MarketMgr:CheckGoodsIdExist(v.goodList, itemId) == true then
			local newList = {};
			for i = 1, #v.goodList do
				if v.goodList[i].id ~= itemId then
					newList[#newList + 1] = v.goodList[i]
				end
			end
			v.goodList = newList;
		end

		for kc, vc in pairs(v.subDataDic) do
			if MarketMgr:CheckGoodsIdExist(vc.goodList, itemId) == true then
				local newList = {};
				for i = 1, #vc.goodList do
					if vc.goodList[i].id ~= itemId then
						newList[#newList + 1] = vc.goodList[i]
					end
				end
				vc.goodList = newList;
			end
		end
	end
end

-------------------------------------------------------------------------------


---------------------------------- 设置数据部分 ----------------------------------

--// 设置面板打开状态
function MarketMgr:SetOpenState(stateInd)
	mgrPre.curMktOpenState = stateInd;
end

--// 设置一级属性选择Id
function MarketMgr:SetSelFstId(fstId)
	mgrPre.curSelFstId = fstId;
end

--// 设置二级属性选择Id
function MarketMgr:SetSelSecId(secId)
	if secId == nil or secId < 0 then
		mgrPre.curSelSceId = 0;
		return;
	end
	mgrPre.curSelSceId = secId;
end

--// 设置选择购买物品Id
function MarketMgr:SetSelBuyItemId(itemId, itemName, hasPsw, cost)
	mgrPre.curSelBuyItemId = itemId;
	mgrPre.curSelBuyItemName = itemName;
	mgrPre.curSelBuyItemPsw = false;
	if hasPsw ~= nil then
		mgrPre.curSelBuyItemPsw = hasPsw;
	end
	if cost ~= nil then
		mgrPre.curSelBuyItemCost = cost;
	else
		mgrPre.curSelBuyItemCost = 0;
	end
end

--// 设置选择求购物品Id
function MarketMgr:SetSelWantItemId(itemId, itemName, hasPsw)
	mgrPre.curSelBuyItemId = itemId;
	mgrPre.curSelBuyItemName = itemName;
	mgrPre.curSelBuyItemPsw = false;
	if hasPsw ~= nil then
		mgrPre.curSelBuyItemPsw = hasPsw;
	end
end

--// 设置选择下架物品Id
function MarketMgr:SetSelDownShelfItemId(itemId)
	mgrPre.curSelDownShelfItemId = itemId;
end

function MarketMgr:ResetSearchState()
	mgrPre.firstSearch = true;
	mgrPre.waitSearching = false;
	mgrPre.searchBottom = false;
end

--// 重置当前条件首次向服务器请求标志
function MarketMgr:ResetFirstSearch()
	mgrPre.firstSearch = true;
end

--// 重置数据返回已经到底部标志
function MarketMgr:ResetBottonSign()
	mgrPre.searchBottom = false;
end

--// 
function MarketMgr:ResetToFirstState()
	self:ResetFirstSearch();
	self:ResetBottonSign();
end

--// 
function MarketMgr:SetPJIndex(fIndex)
	mgrPre.pjIndex = fIndex;
end

--//
function MarketMgr:SetPZIndex(fIndex)
	mgrPre.pzIndex = fIndex;
end

--// 
function MarketMgr:SetMMUse(fIndex)
	mgrPre.mmUse = fIndex;
end

--//
function MarketMgr:SetWBPJIndex(fIndex)
	mgrPre.wantpjIndex = fIndex;
end

--//
function MarketMgr:SetWBPZIndex(fIndex)
	mgrPre.wantpzIndex = fIndex;
end

--// 清除搜索Id列表
function MarketMgr:ClearFilterIds()
	mgrPre.filterIds = nil;
end

--// 设置出售密码（临时变量）
function MarketMgr:SetSalePsw(pswStr)
	mgrPre.salePsw = pswStr;
end

function MarketMgr:SetIWBGoodId(id)
	mgrPre.iWBid = id;
end

--// 获取搜索Id列表本地
function MarketMgr:FindSearchItemIds(searchStr)
	iLog("LY", StrTool.Concat("Search item : ", searchStr));

	--mgrPre.filterIds = self:GetSearchItemIdLocal(searchStr);
	
	mgrPre.filterIds = {}

	local secId = mgrPre.curSelSceId
	if secId <= 0 then
		mgrPre.filterIds = self:GetSearchItemIdLocal(searchStr);
		return
	else
		local filterIds = self:GetSearchItemIdLocal(searchStr);
		for i,v in ipairs(filterIds) do
			local secType = ItemData[tostring(v)].SecType
			if secType then 
				if MarketDic[tostring(secId)].category == 3 then
					local pre = MarketDic[tostring(secType)].preids
					for i1,v1 in ipairs(pre) do
						if v1 == secId then
							mgrPre.filterIds[#mgrPre.filterIds + 1] = v
						end
					end
				else
					if secType == secId  then
						mgrPre.filterIds[#mgrPre.filterIds + 1] = v
					end
				end
			end
		end
	end

	-- if mgrPre.filterIds ~= nil and #mgrPre.filterIds <= 0 then
	-- 	mgrPre.filterIds = nil;
	-- end
end

--// 设置排序类型
--// 1：时序，2：单价，3：总价
function MarketMgr:SetSortType(sType)
	mgrPre.useSortType = sType;
end

--// 0：降序， 1：升序
function MarketMgr:SetOnePSortType(sortType)
	if sortType < 0 then
		mgrPre.onePSortIndex = 0;
		return;
	end

	mgrPre.onePSortIndex = sortType;
end

--// 0：降序， 1：升序
function MarketMgr:SetAllPSortType(sortType)
	if sortType < 0 then
		mgrPre.allPSortIndex = 0;
		return;
	end

	mgrPre.allPSortIndex = sortType;
end

-------------------------------------------------------------------------------


---------------------------------- 获取数据部分 ----------------------------------
--// 得到我要求购筛选过后的列表
function MarketMgr:GetIWBGoodsByPZorPJ(goodList)
	local pz = self:GetWBPZIndex()
	local pj = self:GetWBPJIndex()
	--iTrace.eError("pz "..pz..",".."pj"..pj .."#goodList :  "..#goodList)
	local tempList = {}
	if pz == 0 and pj == 0 then
		for i,v in pairs(goodList) do
			tempList[#tempList + 1] = v
		end
	elseif pz == 0 and pj ~= 0 then
		for i,v in pairs(goodList) do
			if v.wearRank == pj  then
				tempList[#tempList + 1] = v
			end
		end
	elseif pz ~= 0 and pj == 0 then
		for i,v in pairs(goodList) do
			if v.color == pz  then
				tempList[#tempList + 1] = v
			end
		end
	elseif pz ~= 0 and pj ~= 0 then
		for i,v in ipairs(goodList) do
			if v.color == pz and v.wearRank == pj then
				tempList[#tempList + 1] = v
			end
		end
	end
	return tempList
end

--// 是否有出售物品
function MarketMgr:HasSellGoods()
	if mgrPre.sellGoodsTbl == nil or #mgrPre.sellGoodsTbl <= 0 then
		return false;
	end
	
	return true;
end

--// 是否有求购物品
function MarketMgr:HasWantGoods()
	if mgrPre.wantGoodsTbl == nil or #mgrPre.wantGoodsTbl <= 0 then
		return false;
	end
	
	return true;
end

--// 是否有搜索id
function MarketMgr:HasSearchIds()
	if mgrPre.filterIds == nil or #mgrPre.filterIds <= 0 then
		return false;
	end

	return true;
end
--// 获得我要求购的id
function MarketMgr:GetIWBGoodId()
	return mgrPre.iWBid;
end

--// 获得面板打开状态
function MarketMgr:GetOpenState()
	return mgrPre.curMktOpenState;
end

--// 获得一级属性选择Id
function MarketMgr:GetSelFstId()
	return mgrPre.curSelFstId;
end

--// 获得二级属性选择Id
function MarketMgr:GetSelSecId()
	return mgrPre.curSelSceId;
end

--// 获得选择购买物品Id
function MarketMgr:GetSelBuyItemId()
	return mgrPre.curSelBuyItemId;
end

--// 获得选择购买物品名称
function MarketMgr:GetSelBuyItemName()
	return mgrPre.curSelBuyItemName;
end

--// 
function MarketMgr:IsSelBuyItemPsw()
	return mgrPre.curSelBuyItemPsw;
end

--//
function MarketMgr:GetSelBuyItemCost()
	if mgrPre.curSelBuyItemCost == nil then
		return 0;
	end

	return mgrPre.curSelBuyItemCost;
end

--// 获得选择下架物品Id
function MarketMgr:GetSelDownShelfItemId()
	return mgrPre.curSelDownShelfItemId;
end

--// 转换64位整数
function MarketMgr.ChangeInt64Num(number)
	return tonumber(tostring(number));
end

--// 是否申请第一页数据
function MarketMgr:IsFstReqData()
	return mgrPre.firstSearch;
end

--// 返回市场日志
function MarketMgr:GetMarketLogs()
	return mgrPre.logList;
end

--// 获取市场字典一级属性结构
function MarketMgr:GetMarketDicFstCfg()
	local retTbl = {};

	for k, v in pairs(MarketDic) do
		if v.preids ~= nil and v.preids[1] == 0 and v.category ~= 4 then
			retTbl[#retTbl + 1] = v;
		end
	end

	table.sort(retTbl, function(a, b)
		return a.id < b.id;
	end);

	return retTbl;
end


--// 获取市场我要求购一级属性结构
function MarketMgr:GetIWBDicFstCfg()
	local retTbl = {};
	for k, v in pairs(MarketDic) do
		if v.category == 1 then
			retTbl[#retTbl + 1] = v;
		end
	end

	table.sort(retTbl, function(a, b)
		return a.id < b.id;
	end);
	return retTbl;
end

--// 获取市场 求购列表一级属性结构
function MarketMgr:GetWBDicFstCfg()
	local retTbl = {};
	for k, v in pairs(MarketDic) do
		if v.preids ~= nil and v.preids[1] == 0 or v.category == 4 then
			retTbl[#retTbl + 1] = v;
		end
	end

	table.sort(retTbl, function(a, b)
		return a.id < b.id;
	end);
	return retTbl;
end


--// 根据一级Id获取二级属性集合
function MarketMgr:GetSecCfgByFstId(fstId)
	local fstData = mgrPre.sellGoodsTbl[tostring(fstId)];
	if fstData == nil then
		return nil
	end

	local retTbl = {};

	for k, v in pairs(fstData.subDataDic) do
		--retTbl[#retTbl + 1] = MarketDic[tostring(v.id)];
		retTbl[#retTbl + 1] = v;
	end
	table.sort(retTbl, function(a, b)
		if a.category ~= b.category then
			return a.category > b.category;
		else
			return a.id < b.id;
		end
	end);

	return retTbl;
end

--// 根据一级Id获取求购二级属性集合
function MarketMgr:GetWBSecCfgByFstId(fstId)
	local fstData = mgrPre.wantGoodsTbl[tostring(fstId)];
	if fstData == nil then
		return nil
	end

	local retTbl = {};

	for k, v in pairs(fstData.subDataDic) do
		--retTbl[#retTbl + 1] = MarketDic[tostring(v.id)];
		retTbl[#retTbl + 1] = v;
	end
	table.sort(retTbl, function(a, b)
		if a.category ~= b.category then
			return a.category > b.category;
		else
			return a.id < b.id;
		end
	end);

	return retTbl;
end

--// 根据一级Id获取求购列表装备 -- num==1 云舒装备 num==2 夜夕装备
function MarketMgr:GetWantAllById(fstId,num)
	local fstData = self:GetWBSecCfgByFstId(fstId)
	if fstData == nil then
		return nil
	end

	local oneList = {}
	for k,v in pairs(fstData) do
		if MarketDic[tostring(v.id)].unique == 0 then
			for i,v1 in ipairs(mgrPre.showEquipTbl) do
				if v1.secType == v.id then
					oneList[#oneList + 1] = v1
				end
			end
		end
	end

	for i,v in pairs(mgrPre.showEquipTbl) do
		if ItemData[tostring(v.id)].cateLim == num then
			oneList[#oneList + 1] = v
		end
	end

	table.sort(oneList, function(a, b)
		if a.wearRank ~= b.wearRank then
			return a.wearRank > b.wearRank;
		elseif a.lv ~= b.lv and a.lv ~= nil and b.lv ~= nil then
			return a.lv > b.lv
		elseif a.color ~= b.color then
			return a.color > b.color
		else
			return a.id < b.id
		end
	end);

	return oneList
end

-- // 根据一级Id获得道具的条目
function MarketMgr:GetWantItemByFstId(fstId)
	local fstData = self:GetWBSecCfgByFstId(fstId)
	local Tbl = {}
	
	for i,v in ipairs(mgrPre.showItemTbl) do
		for k,v1 in pairs(fstData) do
			if v.secType == v1.id then
				Tbl[#Tbl + 1] = v
			end
		end
	end
	table.sort(Tbl, function(a, b)
		if a.lv ~= b.lv and a.lv ~= nil and b.lv ~= nil then
			return a.lv > b.lv
		elseif a.color ~= b.color then
			return a.color > b.color
		else
			return a.id < b.id
		end
	end);
	return Tbl
end

--// 根据Id获取物品列表
function MarketMgr:GetSellGoodsListById(fstId, secId)
	if secId <= 0 then
		return mgrPre.sellGoodsTbl[tostring(fstId)].goodList;
	else
		return mgrPre.sellGoodsTbl[tostring(fstId)].subDataDic[tostring(secId)].goodList;
	end
end

--// 根据Id获取求购物品列表
function MarketMgr:GetWantGoodsListById(fstId, secId)
	if secId <= 0 then
		return mgrPre.wantGoodsTbl[tostring(fstId)].goodList;
	else
		return mgrPre.wantGoodsTbl[tostring(fstId)].subDataDic[tostring(secId)].goodList;
	end
end


--// 获得自己上架摆摊物品列表
function MarketMgr:GetOnShelfBuyGoods()
	return mgrPre.selfOnShelfBuyGoods;
end

--// 获取自己上架摆摊物品数量
function MarketMgr:OnShelfBuyGoodsNum()
	return #mgrPre.selfOnShelfBuyGoods;
end

--//
function MarketMgr:GetShelfWantGoods()
	return mgrPre.selfOnShelfWantGoods;
end

--// 
function MarketMgr:OnShelfWantGoodsNum()
	return #mgrPre.selfOnShelfWantGoods;
end

--// 
function MarketMgr:GetPJIndex()
	return mgrPre.pjIndex;
end

--//
function MarketMgr:GetPZIndex()
	return mgrPre.pzIndex;
end

--// 
function MarketMgr:GetMMUse()
	return mgrPre.mmUse;
end



--//
function MarketMgr:GetWBPJIndex()
	return mgrPre.wantpjIndex;
end

--//
function MarketMgr:GetWBPZIndex()
	return mgrPre.wantpzIndex;
end

--// 获取出售密码
function MarketMgr:GetSalePsw()
	return mgrPre.salePsw;
end

function MarketMgr:GetShowItemTbl()
	return mgrPre.showItemTbl;
end

function MarketMgr:GetShowEquipTbl()
	return mgrPre.showEquipTbl;
end

function MarketMgr:GetItemAndEquipTbl()
	local Tbl = {}
	for i,v in ipairs(mgrPre.showItemTbl) do
		Tbl[#Tbl + 1] = v
	end
	for i,v in ipairs(mgrPre.showEquipTbl) do
		Tbl[#Tbl + 1] = v
	end
	return Tbl
end

--// 根据输入字符串在本地查找对应物品Id
function MarketMgr:GetSearchItemIdLocal(searchStr,data)
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
	else
		sData = data
	end
	for k,v in pairs(sData) do
		if not data then
			itemName = v.name
		else
			itemName = ItemData[tostring(v.id)].name;
		end
		if string.len(cleanStr) <= string.len(itemName) then
			if string.find(itemName, cleanStr) ~= nil then
				retIds[#retIds + 1] = v.id;
			end
		end
	end

	return retIds;
end

--// 
function MarketMgr:GetOnePSortType()
	return mgrPre.onePSortIndex;
end

--// 
function MarketMgr:GetAllPSortType()
	return mgrPre.allPSortIndex;
end

--// 获得排序类型
--// 1：时序，2：单价，3：总价
function MarketMgr:GetSortType()
	return mgrPre.useSortType;
end

-------------------------------------------------------------------------------

return MarketMgr
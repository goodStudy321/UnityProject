--// 市场商品购买面板
require("UI/Market/UIMktSellIMat");

UIMktMatPanel = Super:New{Name = "UIMktMatPanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local downSpriteName = "ty_11";
local upSpriteName = "ty_13";

--// 初始化面板
function UIMktMatPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 条目克隆主体
	panelCtrl.itemMain = T(panelCtrl.rootTrans, "ItemSV/Grid/Item_99");
	panelCtrl.itemMain:SetActive(false);
	panelCtrl.noGoodSignObj = T(panelCtrl.rootTrans, "NoGoodSign");

	--------- 获取控件 ---------
	local tip = "UI市场条目面板"
	--// 滚动区域
	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "ItemSV", tip, false);
	--// 排序控件
	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "ItemSV/Grid", tip, false);
	--// 
	panelCtrl.onePSortSprite = C(UISprite, panelCtrl.rootTrans, "PropCont/OnePCont/SortBtn", tip, false);
	--// 
	panelCtrl.allPSortSprite = C(UISprite, panelCtrl.rootTrans, "PropCont/AllPCont/SortBtn", tip, false);


	UITool.SetBtnClick(panelCtrl.rootTrans, "PropCont/OnePCont", des, self.ClickOnePSortBtn, self);
	UITool.SetBtnClick(panelCtrl.rootTrans, "PropCont/AllPCont", des, self.ClickAllPSortBtn, self);


	panelCtrl.itemsSV.onDragFinished = function ()
		self:ContinueSearch();
	end;

	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("NewMarketGoods", panelCtrl.OnNewData);


	panelCtrl.goodsList = nil;
	--// 帮派成员条目列表
	panelCtrl.items = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.init = true;
	panelCtrl.isOpen = false;
end

--// 更新
function UIMktMatPanel:Update()
	if panelCtrl.isOpen == false then
		return;
	end

	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.itemsSV:ResetPosition();
		end
	end
end

--// 打开
function UIMktMatPanel:Open()
	panelCtrl.isOpen = true;
	panelCtrl.panelObj:SetActive(true);

	UIMarketWnd:OpenSearchPanel(true);

	-- self:SetOnePSortSpriteShow(MarketMgr:GetOnePSortType());
	-- self:SetAllPSortSpriteShow(MarketMgr:GetAllPSortType());
	self:SetOnePSortSpriteShow(-1);
	self:SetAllPSortSpriteShow(-1);

	self:ShowData();
end

--// 关闭
function UIMktMatPanel:Close()
	MarketMgr:SetSelBuyItemId(0, "", false, 0);
	UIMarketWnd:CloseFilterCont();

	UIMarketWnd:OpenSearchPanel(false);

	panelCtrl.isOpen = false;
	panelCtrl.panelObj:SetActive(false);
end

--// 销毁释放窗口
function UIMktMatPanel:Dispose()
	EventMgr.Remove("NewMarketGoods", panelCtrl.OnNewData);

	for i = 1, #panelCtrl.items do
		panelCtrl.items[i]:Dispose();
		ObjPool.Add(panelCtrl.items[i]);
	end
	panelCtrl.items ={};

	panelCtrl.init = false;
end

function UIMktMatPanel:ClickOnePSortBtn()
	MarketMgr:ResetToFirstState();
	local lastSortType = MarketMgr:GetSortType();
	MarketMgr:SetSortType(2);

	if lastSortType == 1 then
		MarketMgr:SetOnePSortType(0);
		self:SetOnePSortSpriteShow(0);
	elseif lastSortType == 3 then
		MarketMgr:SetOnePSortType(MarketMgr:GetOnePSortType())
		self:SetOnePSortSpriteShow(MarketMgr:GetOnePSortType());
	else
		if MarketMgr:GetOnePSortType() == 0 then
			MarketMgr:SetOnePSortType(1);
			self:SetOnePSortSpriteShow(1);
		else
			MarketMgr:SetOnePSortType(0)
			self:SetOnePSortSpriteShow(0);
		end
	end
	self:SetAllPSortSpriteShow(-1);

	--// 根据条件向服务器请求数据
	MarketMgr:ReqCurSearchItemInfo();
end

function UIMktMatPanel:ClickAllPSortBtn()
	MarketMgr:ResetToFirstState();
	local lastSortType = MarketMgr:GetSortType();
	MarketMgr:SetSortType(3);

	if lastSortType == 1 then
		MarketMgr:SetAllPSortType(0)
		self:SetAllPSortSpriteShow(0);
	elseif lastSortType == 2 then
		MarketMgr:SetAllPSortType(MarketMgr:GetAllPSortType())
		self:SetAllPSortSpriteShow(MarketMgr:GetAllPSortType());
	else
		if MarketMgr:GetAllPSortType() == 0 then
			MarketMgr:SetAllPSortType(1)
			self:SetAllPSortSpriteShow(1);
		else
			MarketMgr:SetAllPSortType(0)
			self:SetAllPSortSpriteShow(0);
		end
	end
	self:SetOnePSortSpriteShow(-1);

	--// 根据条件向服务器请求数据
	MarketMgr:ReqCurSearchItemInfo();
end

--// 1为升序
function UIMktMatPanel:SetOnePSortSpriteShow(updown)
	if updown == 1 then
		panelCtrl.onePSortSprite.spriteName = downSpriteName;
		--UITool.SetNormal(panelCtrl.onePSortSprite.gameObject);
	elseif updown == 0 then
		panelCtrl.onePSortSprite.spriteName = upSpriteName;
		--UITool.SetNormal(panelCtrl.onePSortSprite.gameObject);
	else
		panelCtrl.onePSortSprite.spriteName = downSpriteName;
		--UITool.SetGray(panelCtrl.onePSortSprite.gameObject, true);
	end
end

--// 1为升序
function UIMktMatPanel:SetAllPSortSpriteShow(updown)
	if updown == 1 then
		panelCtrl.allPSortSprite.spriteName = downSpriteName;
		--UITool.SetNormal(panelCtrl.allPSortSprite.gameObject);
	elseif updown == 0 then
		panelCtrl.allPSortSprite.spriteName = upSpriteName;
		--UITool.SetNormal(panelCtrl.allPSortSprite.gameObject);
	else
		panelCtrl.allPSortSprite.spriteName = downSpriteName;
		--UITool.SetGray(panelCtrl.allPSortSprite.gameObject, true);
	end
end

--// 选择
function UIMktMatPanel:SelectMatCont(itemId, itemName, hasPsw, cost)
	MarketMgr:SetSelBuyItemId(itemId, itemName, hasPsw, cost);

	for i = 1, #panelCtrl.goodsList do
		if panelCtrl.goodsList[i].id == itemId then
			panelCtrl.items[i]:SetSel(true);
		else
			panelCtrl.items[i]:SetSel(false);
		end
	end
end

--// 显示数据
function UIMktMatPanel:ShowData()
	if panelCtrl.isOpen == false then
		return;
	end

	local fstId = MarketMgr:GetSelFstId();
	local secId = MarketMgr:GetSelSecId();

	local tCfg = nil;
	if secId > 0 then
		tCfg = MarketDic[tostring(secId)];
	else
		tCfg = MarketDic[tostring(fstId)];
	end
	if tCfg == nil then
		UIMarketWnd:CloseFilterCont();
		local showStr = StrTool.Concat("Can not find config in MarketDic !!!  fstId : ", tostring(fstId), "  secId : ", tostring(secId));
		iError("LY", showStr);
	else
		local showColorF = false;
		local showQualityF = false;
		local showPswF = true;

		if tCfg.color == 1 then
			showColorF = true;
		end
		if tCfg.quality == 1 then
			showQualityF = true;
		end

		UIMarketWnd:OpenFilterCont(showQualityF, showColorF, showPswF);
	end

	panelCtrl.goodsList = MarketMgr:GetSellGoodsListById(fstId, secId);
	if panelCtrl.goodsList == nil or #panelCtrl.goodsList <= 0 then
		--panelCtrl.noGoodSignObj:SetActive(true);
		self:RenewItemNum(0);
		return;
	end
	--panelCtrl.noGoodSignObj:SetActive(false);

	local isFst = MarketMgr:IsFstReqData();
	if isFst == nil or isFst == true then
		self:RenewItemNum(#panelCtrl.goodsList);
	else
		self:RenewItemNum(#panelCtrl.goodsList, true);
	end

	for i = 1, #panelCtrl.goodsList do
		panelCtrl.items[i]:LinkAndConfig(panelCtrl.goodsList[i], function() self:SelectMatCont(panelCtrl.goodsList[i].id, panelCtrl.goodsList[i].name, panelCtrl.goodsList[i].password, panelCtrl.goodsList[i].totalPrice) end);
	end

	local selId = MarketMgr:GetSelBuyItemId();
	if selId == nil or selId <= 0 then
		panelCtrl.items[1]:ClickSelf();
	else
		local isHit = false;
		for i = 1, #panelCtrl.goodsList do
			if selId == panelCtrl.goodsList[i].id then
				panelCtrl.items[i]:ClickSelf();
				isHit = true;
				break;
			end
		end
		if isHit == false then
			panelCtrl.items[1]:ClickSelf();
		end
	end
end

--// 克隆商品条目
function UIMktMatPanel:CloneItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.itemMain);
	cloneObj.transform.parent = panelCtrl.itemMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.itemMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.itemMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.itemMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMktSellIMat);
	cloneItem:Init(cloneObj);

	local newName = "";
	if #panelCtrl.items + 1 >= 100 then
		newName = string.gsub(panelCtrl.itemMain.name, "99", tostring(#panelCtrl.items + 1));
	elseif #panelCtrl.items + 1 >= 10 then
		newName = string.gsub(panelCtrl.itemMain.name, "99", "0"..tostring(#panelCtrl.items + 1));
	else
		newName = string.gsub(panelCtrl.itemMain.name, "99", "00"..tostring(#panelCtrl.items + 1));
	end
	cloneObj.name = newName;

	panelCtrl.items[#panelCtrl.items + 1] = cloneItem;

	return cloneItem;
end

--// 重置条目数量
function UIMktMatPanel:RenewItemNum(number, noRenewSV)
	if panelCtrl.isOpen == nil or panelCtrl.isOpen == false then
		return;
	end

	for a = 1, #panelCtrl.items do
		panelCtrl.items[a]:Dispose();
		panelCtrl.items[a]:Show(false)
	end

	local realNum = number;
	if realNum <= 0 then
		panelCtrl.noGoodSignObj:SetActive(true);
	else
		panelCtrl.noGoodSignObj:SetActive(false);
	end
	
	if realNum <= #panelCtrl.items then
		for a = 1, realNum do
			panelCtrl.items[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.items do
			panelCtrl.items[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.items;
		for a = 1, needNum do
			self:CloneItem();
		end
	end

	panelCtrl.itemGrid:Reposition();
	if noRenewSV ~= nil and noRenewSV == true then
		return;
	end
	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIMktMatPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end

--// 继续往下搜索
function UIMktMatPanel:ContinueSearch()
	MarketMgr:ReqCurSearchItemInfo();
end
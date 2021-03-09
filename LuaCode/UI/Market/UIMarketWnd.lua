--// 市场主界面
require("UI/Market/UIMktITypePanel");
require("UI/Market/UIMktItemCatPanel");
require("UI/Market/UIMktMatPanel");
require("UI/Market/UIMktOnShelfPanel");
require("UI/Market/UIMktBagItemPanel");
require("UI/Market/UIMktRecordPanel");
require("UI/UIFamily/UIBtnItem");
require("UI/Market/UIPopDownMenu");

require("UI/Market/UIMktWBListPanel")
require("UI/Market/UIMktIWBListPanel")
require("UI/Market/UIMktWBSetPanel")
require("UI/Market/UIMktWBItemPanel")
require("UI/Market/UIMktWBSetPanel")
require("UI/Market/UIMktWBSellPanel")

UIMarketWnd = UIBase:New{Name = "UIMarketWnd"};

local winCtrl = {};

local iLog = iTrace.eLog;
local iError = iTrace.Error;


--// 初始化界面
--// 链接所有操作物体
function UIMarketWnd:InitCustom()
	if winCtrl.init ~= nil and winCtrl.init == true then
		return;
	end
	winCtrl.init = false;

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	local tip = "市场主界面"
	--------- 获取GO ---------

	--// 市场摆摊按钮框物体
	winCtrl.sellBtnContObj = T(winCtrl.winRootTrans, "UpCtrlCont/SellBtnCont");
	--// 左侧分类按钮面板物体
	winCtrl.iTypeBtnPanelObj = T(winCtrl.winRootTrans, "LeftBtnListCont");
	--// 市场商品分类面板物体
	winCtrl.itemCatPanelObj = T(winCtrl.winRootTrans, "ItemGridCont");
	--// 市场商品物品面板物体
	winCtrl.itemMatPanelObj = T(winCtrl.winRootTrans, "ItemListCont");
	--// 市场上架面板物体
	winCtrl.onShelfPanelObj = T(winCtrl.winRootTrans, "OnShelfCont");
	--// 市场背包物品面板物体
	winCtrl.onBagItemPanelObj = T(winCtrl.winRootTrans, "BagItemCont");
	--// 上架提示
	winCtrl.onShelfInfoObj = T(winCtrl.winRootTrans, "OnShelfInfoCont");
	--// 交易记录面板物体
	winCtrl.recordPanelObj = T(winCtrl.winRootTrans, "RecordListCont");
	--// 搜索面板物体
	winCtrl.searchContObj = T(winCtrl.winRootTrans, "FindCont");
	--// 筛选按钮框物体
	winCtrl.filterContObj = T(winCtrl.winRootTrans, "UpCtrlCont/PopMenuContPanel");
	--// 品阶筛选下拉框物体
	winCtrl.pjMenuObj = T(winCtrl.winRootTrans, "UpCtrlCont/PopMenuContPanel/PopMenuCont/Grid/PopMenu1");
	--// 品质筛选下拉框物体
	winCtrl.pzMenuObj = T(winCtrl.winRootTrans, "UpCtrlCont/PopMenuContPanel/PopMenuCont/Grid/PopMenu2");
	--// 密码筛选下拉框物体
	winCtrl.mmMenuObj = T(winCtrl.winRootTrans, "UpCtrlCont/PopMenuContPanel/PopMenuCont/Grid/PopMenu3");

	--// 摆摊按钮物体
	winCtrl.marketBtnObj = T(winCtrl.winRootTrans, "SideBtnCont/MarketBtn");
	--// 求购按钮物体
	winCtrl.wantBuyBtnObj = T(winCtrl.winRootTrans, "SideBtnCont/WantBuyBtn");
	--// 购买商品按钮物体
	winCtrl.buyBtnObj = T(winCtrl.winRootTrans, "UpCtrlCont/SellBtnCont/ToBuyBtn");
	--// 出售商品按钮物体
	winCtrl.sellBtnObj = T(winCtrl.winRootTrans, "UpCtrlCont/SellBtnCont/ToSellBtn");
	--// 记录按钮物体
	winCtrl.recordBtnObj = T(winCtrl.winRootTrans, "UpCtrlCont/SellBtnCont/RecordBtn");
	--// 说明信息面板
	winCtrl.infoPanelObj = T(winCtrl.winRootTrans, "FindInfoPanel");
	winCtrl.infoPanelObj:SetActive(false);

	--//HYN
	--//求购物品显示面板
	winCtrl.WantBuyListObj = T(winCtrl.winRootTrans,"WantBuyListCont")
	--//我要求购列表面板
	winCtrl.iWantBuyListObj = T(winCtrl.winRootTrans,"IWantBuyListCont")
	--//求购设置面板
	winCtrl.wantBuySetObj = T(winCtrl.winRootTrans, "WantBuySet")
	--//求购出售面板
	winCtrl.WBSellObj = T(winCtrl.winRootTrans,"WBSellPanel")
	--//求购点击按钮框物体
	winCtrl.wantBuyUpList = T(winCtrl.winRootTrans, "WantBuyUpCtrlCont")
	--//求购物品Item面板
	winCtrl.wantBuyItem = T(winCtrl.winRootTrans, "WantBuyItemCont")
	--//求购列表按钮物体
	winCtrl.wantBuyListBtnObj = T(winCtrl.winRootTrans, "WantBuyUpCtrlCont/SellBtnCont/WantBuyListBtn")
	--//我要求购按钮物体
	winCtrl.iWanBuyBtnObj = T(winCtrl.winRootTrans, "WantBuyUpCtrlCont/SellBtnCont/IWanBuyBtn")
	--//品阶筛选下拉框物体
	winCtrl.wantpjMenuObj = T(winCtrl.winRootTrans, "WantBuyUpCtrlCont/PopMenuContPanel/PopMenuCont/Grid/PopMenu1")
	--//品质筛选下拉框物体
	winCtrl.wantpzMenuObj = T(winCtrl.winRootTrans, "WantBuyUpCtrlCont/PopMenuContPanel/PopMenuCont/Grid/PopMenu2")



	--------- 获取控件 ---------

	--// 元宝数量
	winCtrl.goldL = C(UILabel, winCtrl.winRootTrans, "FindCont/MoneyCont/Bg/MoneyNum", tip, false);
	--// 搜索控件
	winCtrl.inputCom = C(UIInput, winCtrl.winRootTrans, "FindCont/InputCont/InputBg", tip, false);
	--// 排列控件
	winCtrl.matGrid = C(UIGrid, winCtrl.winRootTrans, "UpCtrlCont/PopMenuContPanel/PopMenuCont/Grid", tip, false);
	--//求购排列控件
	winCtrl.wbMatGrid = C(UIGrid, winCtrl.winRootTrans, "WantBuyUpCtrlCont/PopMenuContPanel/PopMenuCont/Grid", tip, false);
	--// 说明面板文本
	winCtrl.findInfoL = C(UILabel, winCtrl.winRootTrans, "FindInfoPanel/PanelCont/Label", tip, false);

	--// 关闭按钮
	local com = C(UIButton, winCtrl.winRootTrans, "TitleCont/CloseBtn/Sprite", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:Close();
	end;

	--// 搜索按钮
	com = C(UIButton, winCtrl.winRootTrans, "FindCont/FindBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:OnSearchSubmit();
	end;

	--// 购买按钮
	com = C(UIButton, winCtrl.winRootTrans, "FindCont/BuyBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickBuyBtn();
	end;

	--// 下架按钮
	com = C(UIButton, winCtrl.winRootTrans, "OnShelfInfoCont/DownShelfBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickDownShelfBtn();
	end;

	--// 打开说明面板按钮
	com = C(UIButton, winCtrl.winRootTrans, "FindCont/InputCont/InfoBtn/BtnBg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		winCtrl.infoPanelObj:SetActive(true);
	end;

	--// 关闭说明面板按钮
	com = C(UIButton, winCtrl.winRootTrans, "FindInfoPanel/PanelCont/Bg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		winCtrl.infoPanelObj:SetActive(false);
	end;

	--// 搜索框提交事件
	--EventDelegate.Add(winCtrl.inputCom.onSubmit, EventDelegate.Callback(self.OnSearchSubmit, self));
	--EventDelegate.Add(winCtrl.inputCom.onChange, EventDelegate.Callback(self.OnSearchSubmit, self));


	--------- 初始化操作 ---------

	--// 初始化类型按钮面板
	UIMktITypePanel:Init(winCtrl.iTypeBtnPanelObj);
	--// 初始化市场商品分类面板
	UIMktItemCatPanel:Init(winCtrl.itemCatPanelObj);
	--// 初始化市场商品物品面板
	UIMktMatPanel:Init(winCtrl.itemMatPanelObj);
	--// 初始化市场上架面板
	UIMktOnShelfPanel:Init(winCtrl.onShelfPanelObj);
	--// 初始化市场背包面板
	UIMktBagItemPanel:Init(winCtrl.onBagItemPanelObj);
	--// 初始化市场记录面板
	UIMktRecordPanel:Init(winCtrl.recordPanelObj);

	--// 初始化求购物品列表面板
	UIMktWBListPanel:Init(winCtrl.WantBuyListObj)
	--//初始化我要求购物品列表面板
	UIMktIWBListPanel:Init(winCtrl.iWantBuyListObj)
	--//初始化求购设置面板
	UIMktWBSetPanel:Init(winCtrl.wantBuySetObj)
	--//初始化求购物品Item面板
	UIMktWBItemPanel:Init(winCtrl.wantBuyItem)
	--//初始化求购出售面板
	UIMktWBSellPanel:Init(winCtrl.WBSellObj)

	--// 初始化摆摊按钮
	winCtrl.marketBtn = ObjPool.Get(UIBtnItem);
	winCtrl.marketBtn:Init(winCtrl.marketBtnObj, function() self:SwitchToMarketMode(); end);
	--// 初始化求购按钮
	winCtrl.wantBuyBtn = ObjPool.Get(UIBtnItem);
	winCtrl.wantBuyBtn:Init(winCtrl.wantBuyBtnObj, function() self:SwitchToWantBuyMode(); end);
	--// 初始化购买按钮
	winCtrl.buyBtn = ObjPool.Get(UIBtnItem);
	winCtrl.buyBtn:Init(winCtrl.buyBtnObj, function() self:ClickToBuyBtn(true); end);
	--// 初始化出售按钮
	winCtrl.sellBtn = ObjPool.Get(UIBtnItem);
	winCtrl.sellBtn:Init(winCtrl.sellBtnObj, function() self:ClickToSellBtn(true); end);
	--// 初始化记录按钮
	winCtrl.recordBtn = ObjPool.Get(UIBtnItem);
	winCtrl.recordBtn:Init(winCtrl.recordBtnObj, function() self:ClicToRecordBtn(true); end);

	--HYN
	--//初始化求购列表按钮
	winCtrl.wantBuyListBtn=ObjPool.Get(UIBtnItem)
	winCtrl.wantBuyListBtn:Init(winCtrl.wantBuyListBtnObj,function() self:ClickToWantBuyList(true) end)
	--//初始化我要求购按钮
	winCtrl.iWanBuyBtn=ObjPool.Get(UIBtnItem)
	winCtrl.iWanBuyBtn:Init(winCtrl.iWanBuyBtnObj,function() self:ClickToIWantBuy(true) end)

	winCtrl.pjMenu = nil;
	winCtrl.pzMenu = nil;
	winCtrl.mmMenu = nil;

	winCtrl.wantpjMenu=nil
	winCtrl.wantpzMenu=nil

	self:InitFilterBtns();
	self:InitWBFilterBtns()

	RoleAssets.eUpAsset:Add(function() self:MoneyChange(); end);

	winCtrl.findInfoL.text = InvestDesCfg["1600"].des;


	--// 当前商店选择状态
	--// 1：购买商品
	--// 2：出售商品
	--// 3：交易记录
	winCtrl.curShopSelState = 0;

	--//当前求购选择状态
	--//1:求购列表
	--//2:我要求购
	winCtrl.curWBSelState = 0

	--// 搜索字段输入状态
	winCtrl.inputSearch = false;
	--// 搜索字符串
	winCtrl.searchStr = "";

	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UIMarketWnd:OpenCustom()
	winCtrl.mOpen = true;
	winCtrl.inputSearch = false;
	winCtrl.searchStr = "";
	winCtrl.inputCom.value = "";

	MarketMgr:ReqMarketInfoTos();

	self:MoneyChange();
	self:SwitchToMarketMode();
end

function UIMarketWnd:OpenTabByIdx(t1, t2, t3, t4)
	
end

--// 关闭窗口
function UIMarketWnd:CloseCustom()
	MarketMgr:SetOpenState(0);
	MarketMgr:ResetSearchState();
	winCtrl.curShopSelState = 0;
	winCtrl.curWBSelState = 0

	UIMktITypePanel:Close();
	UIMktItemCatPanel:Close();
	UIMktMatPanel:Close();
	UIMktOnShelfPanel:Close();
	UIMktBagItemPanel:Close();
	UIMktRecordPanel:Close();

	MarketMgr:SetOpenState(0);
	MarketMgr:SetSelFstId(0);
	MarketMgr:SetSelFstId(0);

	MarketMgr:ClearFilterIds();
	--winCtrl.inputSearch = false;
  	winCtrl.mOpen = false;
end

--// 更新
function UIMarketWnd:Update()
	if winCtrl.mOpen == nil or winCtrl.mOpen == false then
		return;
	end

	UIMktITypePanel:Update();
	UIMktItemCatPanel:Update();
	UIMktMatPanel:Update();
	UIMktOnShelfPanel:Update();
	UIMktBagItemPanel:Update();
	UIMktRecordPanel:Update();

	--// 搜索框选中状态
	-- if winCtrl.inputCom.isSelected == true and winCtrl.inputSearch == false then
	-- 	iLog("LY", "Begin input search !");

	-- 	winCtrl.inputSearch = true;
	--// 搜索框结束选中状态
	-- elseif winCtrl.inputCom.isSelected == false and winCtrl.inputSearch == true then
	-- 	iLog("LY", "End input search !");
	-- 	self:OnSearchSubmit();
	-- 	winCtrl.inputSearch = false;
	-- end
end

--// 销毁释放窗口
function UIMarketWnd:DisposeCustom()

	UIMktITypePanel:Dispose();
	UIMktItemCatPanel:Dispose();
	UIMktMatPanel:Dispose();
	UIMktOnShelfPanel:Dispose();
	UIMktBagItemPanel:Dispose();
	UIMktRecordPanel:Dispose();
	UIMktWBListPanel:Dispose();
	UIMktIWBListPanel:Dispose();
	UIMktWBSetPanel:Dispose();
	UIMktWBItemPanel:Dispose();
	UIMktWBSetPanel:Dispose();
	UIMktWBSellPanel:Dispose();

	if winCtrl.marketBtn ~= nil then
		ObjPool.Add(winCtrl.marketBtn);
		winCtrl.marketBtn = nil;
	end
	if winCtrl.wantBuyBtn ~= nil then
		ObjPool.Add(winCtrl.wantBuyBtn);
		winCtrl.wantBuyBtn = nil;
	end
	if winCtrl.buyBtn ~= nil then
		ObjPool.Add(winCtrl.buyBtn);
		winCtrl.buyBtn = nil;
	end
	if winCtrl.sellBtn ~= nil then
		ObjPool.Add(winCtrl.sellBtn);
		winCtrl.sellBtn = nil;
	end
	if winCtrl.recordBtn ~= nil then
		ObjPool.Add(winCtrl.recordBtn);
		winCtrl.recordBtn = nil;
	end

	if winCtrl.pjMenu ~= nil then
		ObjPool.Add(winCtrl.pjMenu);
		winCtrl.pjMenu = nil;
	end
	if winCtrl.pzMenu ~= nil then
		ObjPool.Add(winCtrl.pzMenu);
		winCtrl.pzMenu = nil;
	end
	if winCtrl.mmMenu ~= nil then
		ObjPool.Add(winCtrl.mmMenu);
		winCtrl.mmMenu = nil;
	end
	if winCtrl.wantpjMenu ~= nil then
		ObjPool.Add(winCtrl.wantpjMenu);
		winCtrl.wantpjMenu = nil;
	end
	if winCtrl.wantpzMenu ~= nil then
		ObjPool.Add(winCtrl.wantpzMenu);
		winCtrl.wantpzMenu = nil;
	end

	MarketMgr:ClearFilterIds();
	winCtrl.inputSearch = false;
	winCtrl.init = false;
end

--// 初始化筛选按钮
function UIMarketWnd:InitFilterBtns()
	winCtrl.pjMenu = ObjPool.Get(UIPopDownMenu);
	local bNs = {"所有", "一阶", "二阶", "三阶", "四阶", "五阶", "六阶", "七阶", "八阶", "九阶","十阶","十一阶"};
	winCtrl.pjMenu:Init(winCtrl.pjMenuObj, "品阶筛选", bNs, 46, function(fIndex) self:ChangePJFilter(fIndex) end, true);

	winCtrl.pzMenu = ObjPool.Get(UIPopDownMenu);
	bNs = {"所有", "白色", "蓝色", "紫色", "橙色", "红色", "粉色"};
	winCtrl.pzMenu:Init(winCtrl.pzMenuObj, "品质筛选", bNs, 46, function(fIndex) self:ChangePZFilter(fIndex) end, true);

	winCtrl.mmMenu = ObjPool.Get(UIPopDownMenu);
	bNs = {"所有", "没有", "有"};
	winCtrl.mmMenu:Init(winCtrl.mmMenuObj, "密码筛选", bNs, 46, function(fIndex) self:ChangeMMFilter(fIndex) end);
end

--//初始化求购筛选按钮
function UIMarketWnd:InitWBFilterBtns()
	winCtrl.wantpjMenu = ObjPool.Get(UIPopDownMenu)
	local bNs = {"所有", "一阶", "二阶", "三阶", "四阶", "五阶", "六阶", "七阶", "八阶", "九阶","十阶","十一阶"}
	winCtrl.wantpjMenu:Init(winCtrl.wantpjMenuObj,"品阶筛选", bNs, 46, function(fIndex) self:ChangeWBPJFilter(fIndex) end,true)

	winCtrl.wantpzMenu = ObjPool.Get(UIPopDownMenu)
	local bNs = {"所有", "白色", "蓝色","紫色", "橙色", "红色", "粉色"}
	winCtrl.wantpzMenu:Init(winCtrl.wantpzMenuObj,"品质筛选", bNs, 46, function(fIndex) self:ChangeWBPZFilter(fIndex) end,true)
end

--// 更改品阶筛选
function UIMarketWnd:ChangePJFilter(fIndex)
	local lastIndex = MarketMgr:GetPJIndex();
	if lastIndex ~= fIndex then
		--iLog("LY", "Change PJFilter : "..fIndex);
		MarketMgr:SetPJIndex(fIndex);
		--// 根据条件向服务器请求数据
		MarketMgr:ResetToFirstState();
		MarketMgr:ReqCurSearchItemInfo();
	end
end

--// 更改品质筛选
function UIMarketWnd:ChangePZFilter(fIndex)
	local lastIndex = MarketMgr:GetPZIndex();
	if lastIndex ~= fIndex then
		iLog("Hyn", "Change PZFilter : "..fIndex);
		MarketMgr:SetPZIndex(fIndex);
		--// 根据条件向服务器请求数据
		MarketMgr:ResetToFirstState();
		MarketMgr:ReqCurSearchItemInfo();
	end
end

--// 更改密码筛选
function UIMarketWnd:ChangeMMFilter(fIndex)
	local lastIndex = MarketMgr:GetMMUse();
	if lastIndex ~= fIndex then
		iLog("Hyn", "Change MMFilter : "..fIndex);
		MarketMgr:SetMMUse(fIndex);
		--// 根据条件向服务器请求数据
		MarketMgr:ResetToFirstState();
		MarketMgr:ReqCurSearchItemInfo();
	end
end

--//更改求购品阶筛选
function UIMarketWnd:ChangeWBPJFilter(fIndex)
	local lastIndex = MarketMgr:GetWBPJIndex()
	if lastIndex ~= fIndex then
		if winCtrl.curWBSelState == 1 then
			MarketMgr:SetWBPJIndex(fIndex)
			--// 根据条件向服务器请求数据
			MarketMgr:ResetToFirstState()
			MarketMgr:ReqCurSearchItemInfo()
		else
			local index = fIndex
			MarketMgr:SetWBPJIndex(index)
			UIMktIWBListPanel:CPzOrPj()
		end
	end
end

--//更改求购品质筛选
function UIMarketWnd:ChangeWBPZFilter(fIndex)
	local lastIndex = MarketMgr:GetWBPZIndex()
	if lastIndex ~= fIndex then
		if winCtrl.curWBSelState == 1 then
			MarketMgr:SetWBPZIndex(fIndex)
			--// 根据条件向服务器请求数据
			MarketMgr:ResetToFirstState()
			MarketMgr:ReqCurSearchItemInfo()
		else
			local index = fIndex
			MarketMgr:SetWBPZIndex(index)
			UIMktIWBListPanel:CPzOrPj()
		end
	end
end

--// 玩家金钱改变
function UIMarketWnd:MoneyChange()
	if winCtrl.mOpen == false then
		return;
	end

	winCtrl.goldL.text = tostring(RoleAssets.Gold);
end

--// 转换到摆摊模式
function UIMarketWnd:SwitchToMarketMode()
	if MarketMgr:GetOpenState() == 1 then
		return;
	end

	MarketMgr:SetSortType(1);
	MarketMgr:SetOnePSortType(0);
	MarketMgr:SetAllPSortType(0);

	MarketMgr:ResetSearchState();
	MarketMgr:SetOpenState(1);
	winCtrl.marketBtn:SetSelect(true);
	winCtrl.wantBuyBtn:SetSelect(false);
	winCtrl.sellBtnContObj:SetActive(true);
	self:ClickToBuyBtn(true);
	winCtrl.wantBuyUpList:SetActive(false)
	UIMktWBListPanel:Close()
	UIMktIWBListPanel:Close()
	UIMktWBSetPanel:Close()
	UIMktWBItemPanel:Close()
end

--// 转换到求购模式
function UIMarketWnd:SwitchToWantBuyMode()
	if MarketMgr:GetOpenState() == 2 then
		return;
	end

	MarketMgr:SetSortType(1);
	MarketMgr:SetOnePSortType(0);
	MarketMgr:SetAllPSortType(0);

	MarketMgr:ResetSearchState();
	MarketMgr:SetOpenState(2);

	winCtrl.marketBtn:SetSelect(false);
	winCtrl.wantBuyBtn:SetSelect(true);

	winCtrl.sellBtnContObj:SetActive(false);
	UIMktItemCatPanel:Close();
	UIMktMatPanel:Close();
	UIMktOnShelfPanel:Close();
	UIMktBagItemPanel:Close();
	UIMktRecordPanel:Close();
	winCtrl.onShelfInfoObj:SetActive(false);
	winCtrl.searchContObj:SetActive(false);
	MarketMgr:ClearFilterIds();
	winCtrl.wantBuyUpList:SetActive(true)
	UIMktWBListPanel:Open()
	self:ClickToWantBuyList(true)
end

--// 转换到购买商品模式
function UIMarketWnd:ClickToBuyBtn(force)
	MarketMgr:ResetSearchState();

	--self:OpenFilterCont(true, true, true);
	--self:CloseFilterCont();

	if force == nil or force == false then
		if winCtrl.curShopSelState == 1 then
			return;
		end
	end

	winCtrl.curShopSelState = 1;

	winCtrl.buyBtn:SetSelect(true);
	winCtrl.sellBtn:SetSelect(false);
	winCtrl.recordBtn:SetSelect(false);
	UIMktITypePanel:Close()
	UIMktITypePanel:Open(1);
	UIMktOnShelfPanel:Close();
	UIMktBagItemPanel:Close();
	UIMktRecordPanel:Close();
	winCtrl.onShelfInfoObj:SetActive(false);
end

--// 转换到出售商品模式
function UIMarketWnd:ClickToSellBtn(force)
	MarketMgr:ResetSearchState();
	self:CloseFilterCont();

	if force == nil or force == false then
		if winCtrl.curShopSelState == 2 then
			return;
		end
	end

	winCtrl.curShopSelState = 2;

	winCtrl.buyBtn:SetSelect(false);
	winCtrl.sellBtn:SetSelect(true);
	winCtrl.recordBtn:SetSelect(false);

	UIMktOnShelfPanel:Open();
	UIMktBagItemPanel:Open();
	UIMktITypePanel:Close();
	UIMktItemCatPanel:Close();
	UIMktMatPanel:Close();
	UIMktRecordPanel:Close();
	winCtrl.searchContObj:SetActive(false);
	winCtrl.onShelfInfoObj:SetActive(true);
	MarketMgr:ClearFilterIds();
end

--// 转换到交易记录模式
function UIMarketWnd:ClicToRecordBtn(force)
	MarketMgr:ResetSearchState();
	self:CloseFilterCont();

	if force == nil or force == false then
		if winCtrl.curShopSelState == 3 then
			return;
		end
	end

	winCtrl.curShopSelState = 3;

	winCtrl.buyBtn:SetSelect(false);
	winCtrl.sellBtn:SetSelect(false);
	winCtrl.recordBtn:SetSelect(true);

	UIMktITypePanel:Close();
	UIMktItemCatPanel:Close();
	UIMktMatPanel:Close();
	UIMktOnShelfPanel:Close();
	UIMktBagItemPanel:Close();
	UIMktRecordPanel:Open();
	winCtrl.searchContObj:SetActive(false);
	winCtrl.onShelfInfoObj:SetActive(false);
	MarketMgr:ClearFilterIds();
end

--//转换到求购列表模式
function UIMarketWnd:ClickToWantBuyList(force)
	MarketMgr:ResetSearchState()

	if force == nil or force == false then
		if winCtrl.curWBSelState == 1 then
			return;
		end
	end

	winCtrl.curWBSelState = 1

	winCtrl.wantBuyListBtn:SetSelect(true)
	winCtrl.iWanBuyBtn:SetSelect(false)
	UIMktWBListPanel:Open()
	UIMktIWBListPanel:Close()
	UIMktWBSetPanel:Close()
	UIMktITypePanel:Close()
	UIMktITypePanel:Open(2)
end

--//转换到我要求购模式
function UIMarketWnd:ClickToIWantBuy(force)
	MarketMgr:ResetSearchState()

	if force == nil or force == false then
		if winCtrl.curWBSelState == 2 then
			return;
		end
	end

	winCtrl.curWBSelState = 2

	winCtrl.wantBuyListBtn:SetSelect(false)
	winCtrl.iWanBuyBtn:SetSelect(true)
	UIMktWBListPanel:Close()
	UIMktIWBListPanel:Open()
	UIMktWBSetPanel:Open()
	UIMktWBItemPanel:Close()
	UIMktITypePanel:Close()
	UIMktITypePanel:Open(3)
end

--// 点击购买按钮
function UIMarketWnd:ClickBuyBtn()
	local buyItemId = MarketMgr:GetSelBuyItemId();
	if buyItemId <= 0 then
		UITip.Log("请选择购买物品");
		return;
	end

	local goldNum = RoleAssets.Gold;
	if goldNum < MarketMgr:GetSelBuyItemCost() then
		local showStr = "元宝不足，前往充值?";
		MsgBox.ShowYesNo(showStr, self.GotoPay, self);
		return;
	end

	--local showStr = StrTool.Concat("购买", MarketMgr:GetSelBuyItemName(), "?");
	local showStr = "是否确认购买?";
	MsgBox.ShowYesNo(showStr, self.SureBuy, self);

	-- if MarketMgr:IsSelBuyItemPsw() == true then
	-- 	PsdPanel.eConfirm:Add(self.OnPswConfirm, self);
	-- 	UIMgr.Open(PsdPanel.Name);
	-- 	return;
	-- end

	-- MarketMgr:ReqMarketBuy(buyItemId, "");
end

--// 确认购买
function UIMarketWnd:SureBuy()
	local buyItemId = MarketMgr:GetSelBuyItemId();
	if buyItemId <= 0 then
		return;
	end

	if MarketMgr:IsSelBuyItemPsw() == true then
		PsdPanel.eConfirm:Add(self.OnPswConfirm, self);
		UIMgr.Open(PsdPanel.Name);
		return;
	end

	MarketMgr:ReqMarketBuy(buyItemId, "");
end

--// 前往充值界面
function UIMarketWnd:GotoPay()
	VIPMgr.OpenVIP(1);
end

function UIMarketWnd:OnPswConfirm(pswStr)
	local buyItemId = MarketMgr:GetSelBuyItemId();
	if buyItemId <= 0 then
		return;
	end

	MarketMgr:ReqMarketBuy(buyItemId, pswStr);
end

--// 点击下架按钮
function UIMarketWnd:ClickDownShelfBtn()
	local downShelfItemId = MarketMgr:GetSelDownShelfItemId();
	if downShelfItemId <= 0 then
		UITip.Log("请选择下架物品");
		return;
	end

	MarketMgr:ReqMarketDownShelf(MarketMgr:GetOpenState(), downShelfItemId);
end

--// 打开筛选框
function UIMarketWnd:OpenFilterCont(openPJ, openPZ, openMM)
	-- MarketMgr:SetPJIndex(0);
	-- MarketMgr:SetPZIndex(0);
	-- MarketMgr:SetMMUse(0);

	if openPJ == true then
		winCtrl.pjMenuObj:SetActive(true);
		winCtrl.pjMenu:SynBtnIndexShow(MarketMgr:GetPJIndex());
	else
		winCtrl.pjMenuObj:SetActive(false);
		MarketMgr:SetPJIndex(0);
	end

	if openPZ == true then
		winCtrl.pzMenuObj:SetActive(true);
		winCtrl.pzMenu:SynBtnIndexShow(MarketMgr:GetPZIndex());
	else
		winCtrl.pzMenuObj:SetActive(false);
		MarketMgr:SetPZIndex(0);
	end

	if openMM == true then
		winCtrl.mmMenuObj:SetActive(true);
		winCtrl.mmMenu:SynBtnIndexShow(MarketMgr:GetMMUse());
	else
		winCtrl.mmMenu:SetActive(false);
		MarketMgr:SetMMUse(0);
	end

	winCtrl.matGrid:Reposition();
end

--// 打开求购筛选框
function UIMarketWnd:OpenWBFilterCont(openPJ, openPZ)
	-- MarketMgr:SetWBPJIndex(0);
	-- MarketMgr:SetWBPZIndex(0);

	if openPJ == true then
		winCtrl.wantpjMenuObj:SetActive(true);
		winCtrl.wantpjMenu:SynBtnIndexShow(MarketMgr:GetWBPJIndex());
	else
		winCtrl.wantpjMenuObj:SetActive(false);
	end

	if openPZ == true then
		winCtrl.wantpzMenuObj:SetActive(true);
		winCtrl.wantpzMenu:SynBtnIndexShow(MarketMgr:GetWBPZIndex());
	else
		winCtrl.wantpzMenuObj:SetActive(false);
	end

	winCtrl.wbMatGrid:Reposition();
end

--// 关闭筛选框
function UIMarketWnd:CloseFilterCont()
	winCtrl.pjMenuObj:SetActive(false);
	winCtrl.pzMenuObj:SetActive(false);
	winCtrl.mmMenuObj:SetActive(false);

	MarketMgr:SetPJIndex(0);
	MarketMgr:SetPZIndex(0);
	MarketMgr:SetMMUse(0);
end

--//关闭求购筛选框
function UIMarketWnd:CloseWBFilterCont()
	winCtrl.wantpjMenuObj:SetActive(false);
	winCtrl.wantpzMenuObj:SetActive(false);

	MarketMgr:SetWBPJIndex(0);
	MarketMgr:SetWBPZIndex(0);
end

--// 清空搜索字符串
function UIMarketWnd:ClearSearchStr()
	winCtrl.searchStr = "";
	winCtrl.inputCom.value = "";
	MarketMgr:ClearFilterIds();
end

--// 提交搜索字段
function UIMarketWnd:OnSearchSubmit()
	local tStr = winCtrl.inputCom.value;
	if tStr == nil or tStr == "" or winCtrl.searchStr == tStr then
		if tStr == nil or tStr == "" then
			MarketMgr:ClearFilterIds();
			if MarketMgr:HasSellGoods() == false then
				MarketMgr:ResetToFirstState();
				MarketMgr:ReqCurSearchItemInfo();
			end
		end
		return;
	end

	winCtrl.searchStr = tStr;
	MarketMgr:FindSearchItemIds(winCtrl.searchStr);
	if MarketMgr:HasSearchIds() == false then
		--winCtrl.inputCom.value = "";
		--UITip.Error("没有此商品 ！");
		UIMktMatPanel:RenewItemNum(0);
		return;
	end

	MarketMgr:ResetToFirstState();
	MarketMgr:ReqCurSearchItemInfo();
end

--// 打开搜索控件
function UIMarketWnd:OpenSearchPanel(isOpen)
	winCtrl.searchContObj:SetActive(isOpen);
	if isOpen == false then
		self:ClearSearchStr();
	end
end

return UIMarketWnd
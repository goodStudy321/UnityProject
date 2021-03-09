--// 市场记录面板
require("UI/Market/UIMktOnShelfItem");

UIMktOnShelfPanel = Super:New{Name = "UIMktOnShelfPanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIMktOnShelfPanel:Init(panelObject)

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
	--// 没有物品出售标志
	panelCtrl.noGoodSignObj = T(panelCtrl.rootTrans, "NoGoodSign");

	--------- 获取控件 ---------
	local tip = "UI市场上架面板"
	--// 滚动区域
	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "ItemSV", tip, false);
	--// 排序控件
	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "ItemSV/Grid", tip, false);


	--// 市场日志更新
	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("NewMarketOnShelf", panelCtrl.OnNewData);


	--// 帮派成员条目列表
	panelCtrl.items = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;
	--// 
	panelCtrl.goodsList = nil;
	--// 当前选择物品Id
	panelCtrl.curSelId = 0;

	panelCtrl.init = true;
	panelCtrl.isOpen = false;
end

--// 更新
function UIMktOnShelfPanel:Update()
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
function UIMktOnShelfPanel:Open()
	panelCtrl.isOpen = true;
	panelCtrl.panelObj:SetActive(true);

	self:ShowData();
	-- if panelCtrl.goodsList ~= nil and #panelCtrl.goodsList > 0 then
	-- 	panelCtrl.items[1]:ClickSelf();
	-- end
end

--// 关闭
function UIMktOnShelfPanel:Close()
	panelCtrl.isOpen = false;
	panelCtrl.panelObj:SetActive(false);
	panelCtrl.curSelId = 0;
	MarketMgr:SetSelDownShelfItemId(panelCtrl.curSelId);
end

--// 销毁释放窗口
function UIMktOnShelfPanel:Dispose()
	EventMgr.Remove("NewMarketOnShelf", panelCtrl.OnNewData);

	for i = 1, #panelCtrl.items do
		panelCtrl.items[i]:Dispose();
		ObjPool.Add(panelCtrl.items[i]);
	end
	panelCtrl.items ={};
	panelCtrl.goodList = nil;
	panelCtrl.curSelId = 0;
	MarketMgr:SetSelDownShelfItemId(panelCtrl.curSelId);

	panelCtrl.init = false;
end

--// 点击条目
function UIMktOnShelfPanel:ClickOnShelfItem(itemId)
	panelCtrl.curSelId = itemId;
	MarketMgr:SetSelDownShelfItemId(panelCtrl.curSelId);

	for i = 1, #panelCtrl.goodsList do
		if panelCtrl.goodsList[i].id == itemId then
			panelCtrl.items[i]:SetSel(true);
		else
			panelCtrl.items[i]:SetSel(false);
		end
	end
end

--// 显示数据
function UIMktOnShelfPanel:ShowData()
	if panelCtrl.isOpen == false then
		return;
	end

	panelCtrl.curSelId = 0;
	MarketMgr:SetSelDownShelfItemId(panelCtrl.curSelId);

	panelCtrl.goodsList = MarketMgr:GetOnShelfBuyGoods();
	self:RenewItemNum(#panelCtrl.goodsList);

	if panelCtrl.goodsList == nil or #panelCtrl.goodsList <= 0 then
		panelCtrl.noGoodSignObj:SetActive(true);
	else
		panelCtrl.noGoodSignObj:SetActive(false);
	end

	for i = 1, #panelCtrl.goodsList do
		panelCtrl.items[i]:LinkAndConfig(panelCtrl.goodsList[i], function() self:ClickOnShelfItem(panelCtrl.goodsList[i].id); end);
	end
end

--// 显示、链接按钮
-- function UIMktOnShelfPanel:ShowAndLinkBtn(tblList, eventList)
-- 	if tblList == nil then
-- 		self:RenewItemNum(0);
-- 		return;
-- 	end

-- 	self:RenewItemNum(#tblList);
-- 	for a = 1, #panelCtrl.items do
-- 		panelCtrl.items[a]:LinkAndConfig(tblList[a], eventList[a]);
-- 	end
-- end

--// 克隆商品条目
function UIMktOnShelfPanel:CloneItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.itemMain);
	cloneObj.transform.parent = panelCtrl.itemMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.itemMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.itemMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.itemMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMktOnShelfItem);
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
function UIMktOnShelfPanel:RenewItemNum(number)
	for a = 1, #panelCtrl.items do
		panelCtrl.items[a]:Dispose();
		panelCtrl.items[a]:SetSel(false);
		panelCtrl.items[a]:Show(false)
	end

	local realNum = number;
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
	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIMktOnShelfPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end
--// 市场子分类显示面板
require("UI/Market/UIMktSellItem");

UIMktItemCatPanel = Super:New{Name = "UIMktItemCatPanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIMktItemCatPanel:Init(panelObject)

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

	--------- 获取控件 ---------
	local tip = "UI市场条目面板"
	--// 滚动区域
	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "ItemSV", tip, false);
	--// 排序控件
	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "ItemSV/Grid", tip, false);


	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("NewClassNum", panelCtrl.OnNewData);


	--// 帮派成员条目列表
	panelCtrl.items = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.init = true;
	panelCtrl.isOpen = false;
end

--// 更新
function UIMktItemCatPanel:Update()
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
function UIMktItemCatPanel:Open()
	panelCtrl.isOpen = true;
	panelCtrl.panelObj:SetActive(true);

	self:ShowData();
end

--// 关闭
function UIMktItemCatPanel:Close()
	panelCtrl.isOpen = false;
	panelCtrl.panelObj:SetActive(false);
end

--// 销毁释放窗口
function UIMktItemCatPanel:Dispose()
	EventMgr.Remove("NewClassNum", panelCtrl.OnNewData);

	for i = 1, #panelCtrl.items do
		ObjPool.Add(panelCtrl.items[i]);
	end
	panelCtrl.items ={};

	panelCtrl.init = false;
end

--// 点击条目
function UIMktItemCatPanel:ClickSelItem(secId)
	MarketMgr:SetSelSecId(secId);
	MarketMgr:ResetToFirstState();
	
	MarketMgr:ReqCurSearchItemInfo();

	self:Close();
	UIMktMatPanel:Open();
end

--// 显示数据
function UIMktItemCatPanel:ShowData()
	if panelCtrl.isOpen == false then
		return;
	end

	local fstId = MarketMgr:GetSelFstId();
	local cfgList = MarketMgr:GetSecCfgByFstId(fstId);
	if cfgList == nil then
		self:RenewItemNum(0);
		return;
	end
	
	self:RenewItemNum(#cfgList);
	for i = 1, #cfgList do
		panelCtrl.items[i]:LinkAndConfig(cfgList[i], function() self:ClickSelItem(cfgList[i].id) end);
	end
end

--// 显示、链接按钮
-- function UIMktItemCatPanel:ShowAndLinkBtn(itemNum, tblList, eventList)
-- 	self:RenewItemNum(itemNum);
-- 	for a = 1, #panelCtrl.items do
-- 		panelCtrl.items[a]:LinkAndConfig(tblList[a], eventList[a]);
-- 	end
-- end

--// 克隆商品条目
function UIMktItemCatPanel:CloneItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.itemMain);
	cloneObj.transform.parent = panelCtrl.itemMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.itemMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.itemMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.itemMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMktSellItem);
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
function UIMktItemCatPanel:RenewItemNum(number)
	for a = 1, #panelCtrl.items do
		--panelCtrl.items[a]:UnloadTex()
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
function UIMktItemCatPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end
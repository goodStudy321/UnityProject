--// 市场背包物品面板
require("UI/Market/UIMktBagItem");

UIMktBagItemPanel = Super:New{Name = "UIMktBagItemPanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIMktBagItemPanel:Init(panelObject)

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
	panelCtrl.cellMain = T(panelCtrl.rootTrans, "ItemSV/Grid/Item_99");

	--------- 获取控件 ---------
	local tip = "UI市场背包物品面板"
	--// 滚动区域
	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "ItemSV", tip, false);
	--// 排序控件
	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "ItemSV/Grid", tip, false);


	--// 市场日志更新
	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("NewMarketOnShelf", panelCtrl.OnNewData);

	Cell.eMarketShow["Add"](Cell.eMarketShow, self.ShowData, self)


	--// 物品列表
	panelCtrl.items = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.init = true;
	panelCtrl.isOpen = false;
end

--// 更新
function UIMktBagItemPanel:Update()
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
function UIMktBagItemPanel:Open()
	if panelCtrl.isOpen ~= nil and panelCtrl.isOpen == true then
		return;
	end

	panelCtrl.isOpen = true;
	panelCtrl.panelObj:SetActive(true);

	self:ShowData();
end

--// 关闭
function UIMktBagItemPanel:Close()
	panelCtrl.isOpen = false;
	panelCtrl.panelObj:SetActive(false);
end

--// 销毁释放窗口
function UIMktBagItemPanel:Dispose()
	EventMgr.Remove("NewMarketOnShelf", panelCtrl.OnNewData);
	Cell.eMarketShow["Remove"](Cell.eMarketShow, self.ShowData, self)

	for i = 1, #panelCtrl.items do
		panelCtrl.items[i]:Dispose();
		ObjPool.Add(panelCtrl.items[i]);
	end
	panelCtrl.items ={};

	panelCtrl.init = false;
end

--// 显示数据
function UIMktBagItemPanel:ShowData()
	if panelCtrl.isOpen == false then
		return;
	end

	-- local dataTbl = {};
	-- for k, v in pairs(PropMgr.typeIdDic) do
	-- 	for i = 1, #v do
	-- 		local bTb = PropMgr.tbDic[tostring(v[i])];
	-- 		local itemData = ItemData[tostring(bTb.type_id)];
	-- 		if bTb ~= nil and bTb.bind == false and itemData ~= nil and itemData.SecType ~= nil then
	-- 			dataTbl[#dataTbl + 1] = bTb;
	-- 		end
	-- 	end
	-- end

	local idTbl = PropMgr.SortTb(1);
	local dataTbl = {};
	local now = TimeTool.GetServerTimeNow()*0.001

	for i, v in ipairs(idTbl) do
		local tIData = PropMgr.tbDic[tostring(v)];
		local gotTime = tIData.gotTime
		if tIData ~= nil then
			local itemData = ItemData[tostring(tIData.type_id)];
			if tIData.bind == false and itemData ~= nil and itemData.SecType ~= nil then
				if itemData.time then
					local time = gotTime - now + tonumber(itemData.time)
					if time > 0 then
						dataTbl[#dataTbl + 1] = tIData
					end
				else
					dataTbl[#dataTbl + 1] = tIData
				end
			end
		end
	end
	if dataTbl == nil then
		self:RenewItemNum(0);
		return;
	end

	self:RenewItemNum(#dataTbl);
	for i = 1, #dataTbl do
		panelCtrl.items[i]:LinkAndConfig(dataTbl[i]);
	end
end


--// 显示、链接按钮
-- function UIMktBagItemPanel:ShowAndLinkBtn(tblList, eventList)
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
function UIMktBagItemPanel:CloneItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.cellMain);
	cloneObj.transform.parent = panelCtrl.cellMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.cellMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.cellMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.cellMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMktBagItem);
	cloneItem:Init(cloneObj);

	local newName = "";
	if #panelCtrl.items + 1 >= 100 then
		newName = string.gsub(panelCtrl.cellMain.name, "99", tostring(#panelCtrl.items + 1));
	elseif #panelCtrl.items + 1 >= 10 then
		newName = string.gsub(panelCtrl.cellMain.name, "99", "0"..tostring(#panelCtrl.items + 1));
	else
		newName = string.gsub(panelCtrl.cellMain.name, "99", "00"..tostring(#panelCtrl.items + 1));
	end
	cloneObj.name = newName;

	panelCtrl.items[#panelCtrl.items + 1] = cloneItem;

	return cloneItem;
end

--// 重置条目数量
function UIMktBagItemPanel:RenewItemNum(number)
	for a = 1, #panelCtrl.items do
		panelCtrl.items[a]:Dispose();
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
function UIMktBagItemPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end
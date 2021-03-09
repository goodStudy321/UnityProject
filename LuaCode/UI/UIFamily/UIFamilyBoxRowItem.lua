--// 道庭仓库宝箱行控件
require("UI/UIFamily/UIFamilyBoxItem");


UIFamilyBoxRowItem = {Name = "UIFamilyBoxRowItem"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;

--// 创建控件
function UIFamilyBoxRowItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFamilyBoxRowItem:Init(gameObj)
	--// 条目物体
	self.itemObj = gameObj;
	--// 条目transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI道庭仓库宝箱行控件";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 记录条目克隆主体
	self.itemMain = T(self.rootTrans, "GridIS/BoxItem_99");
	self.itemMain:SetActive(false);

	--------- 获取控件 ---------

	--// 排序控件
	self.itemGrid = C(UIGrid, self.rootTrans, "GridIS", tip, false);

	--// 条目列表
	self.items = {};
	self.dataList = {};
	self.rowIndex = -1;
end

--// 更新
function UIFamilyBoxRowItem:Update(dTime)
	if self.dataList == nil then
		return;
	end

	for i = 1, #self.items do
		self.items[i]:Update(dTime);
	end
end

--// 释放
function UIFamilyBoxRowItem:Dispose()
	if self.items ~= nil then
		for a = 1, #self.items do
			ObjPool.Add(self.items[a]);
		end
	end

	self.dataList = nil;
	self.rowIndex = -1;
end

--// 链接和初始化配置
function UIFamilyBoxRowItem:LinkAndConfig(dataList, rowInd)
	self.rowIndex = rowInd;
	self.dataList = dataList;
	if self.dataList == nil or #self.dataList <= 0 then
		self:RenewItemNum(0);
		self:Show(false);
		return;
	end

	local iNum = #self.dataList;
	if iNum > 4 then
		iNum = 4;
	end
	self:RenewItemNum(iNum);

	for i = 1, #self.items do
		self.items[i]:LinkAndConfig(self.dataList[i]);
	end
end

--// 显示隐藏
function UIFamilyBoxRowItem:Show(sOh)
	if sOh == false then
		self.rowIndex = -1;
		self.dataList = nil;
	end
	self.itemObj:SetActive(sOh);
end

--// 克隆宝箱条目
function UIFamilyBoxRowItem:CloneBoxItem()
	local cloneObj = GameObject.Instantiate(self.itemMain);
	cloneObj.transform.parent = self.itemMain.transform.parent;
	cloneObj.transform.localPosition = self.itemMain.transform.localPosition;
	cloneObj.transform.localRotation = self.itemMain.transform.localRotation;
	cloneObj.transform.localScale = self.itemMain.transform.localScale;
	cloneObj:SetActive(true);

	local newName = "";
	if #self.items + 1 >= 100 then
		newName = string.gsub(self.itemMain.name, "99", tostring(#self.items + 1));
	elseif #self.items + 1 >= 10 then
		newName = string.gsub(self.itemMain.name, "99", "0"..tostring(#self.items + 1));
	else
		newName = string.gsub(self.itemMain.name, "99", "00"..tostring(#self.items + 1));
	end
	cloneObj.name = newName;

	local cloneItem = ObjPool.Get(UIFamilyBoxItem);
	cloneItem:Init(cloneObj);

	self.items[#self.items + 1] = cloneItem;

	return cloneItem;
end

--// 重置宝箱数量
function UIFamilyBoxRowItem:RenewItemNum(number)
	for a = 1, #self.items do
		self.items[a]:Show(false)
	end

	local realNum = number;
	if realNum > 4 then
		realNum = 4;
	end
	if realNum <= #self.items then
		for a = 1, realNum do
			self.items[a]:Show(true);
		end
	else
		for a = 1, #self.items do
			self.items[a]:Show(true)
		end

		local needNum = realNum - #self.items;
		for a = 1, needNum do
			self:CloneBoxItem();
		end
	end

	self.itemGrid:Reposition();
end

--// 获取行索引
function UIFamilyBoxRowItem:GetRowIndex()
	return self.rowIndex;
end

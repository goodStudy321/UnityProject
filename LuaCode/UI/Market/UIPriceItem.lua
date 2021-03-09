--// 价格控件
UIPriceItem = {Name = "UIPriceItem"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建控件
function UIPriceItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIPriceItem:Init(gameObj)
	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI价格条目";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 标志1
	self.icon1 = T(self.rootTrans, "Icon1");
	--// 标志2
	self.icon2 = T(self.rootTrans, "Icon2");
	--// 标志3
	self.icon3 = T(self.rootTrans, "Icon3");

	
	--// 价格
	self.numL = C(UILabel, self.rootTrans, "Num", tip, false);
end

--// 释放
function UIPriceItem:Dispose()

end

--// 显示价格
function UIPriceItem:ShowNumData(showNum, iconType)
	self.numL.text = tostring(showNum);

	self.icon1:SetActive(false);
	self.icon2:SetActive(false);
	self.icon3:SetActive(false);

	if iconType == 1 then
		self.icon1:SetActive(true);
	elseif iconType == 2 then
		self.icon2:SetActive(true);
	elseif iconType == 3 then
		self.icon3:SetActive(true);
	end
end

--// 显示价格
function UIPriceItem:ShowStrData(showNum, iconType)
	self.numL.text = showNum;

	self.icon1:SetActive(false);
	self.icon2:SetActive(false);
	self.icon3:SetActive(false);

	if iconType == 1 then
		self.icon1:SetActive(true);
	elseif iconType == 2 then
		self.icon2:SetActive(true);
	elseif iconType == 3 then
		self.icon3:SetActive(true);
	end
end
--// 背包条目
--require("UI/Market/UIPriceItem");

UIMktBagItem = {Name = "UIMktBagItem"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建控件
function UIMktBagItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIMktBagItem:Init(gameObj)
	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI市场上架条目";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 选择标志
	self.bg = T(self.rootTrans, "Bg");

	self.cellCont = nil;
	self.dataTbl = nil;
end

--// 释放
function UIMktBagItem:Dispose()
	if self.cellCont ~= nil then
		self.cellCont:DestroyGo();
		ObjPool.Add(self.cellCont);
		self.cellCont = nil;
	end

	self.dataTbl = nil;
end

--// 链接和初始化配置
function UIMktBagItem:LinkAndConfig(tbData)
	self.dataTbl = tbData;

	if self.dataTbl == nil then
		self.bg:SetActive(true);
		return;
	end

	self.bg:SetActive(false);
	self.cellCont = ObjPool.Get(UIItemCell);
	self.cellCont:InitLoadPool(self.rootTrans, 0.85);
	local numShow = ""
	if self.dataTbl.num ~= nil and self.dataTbl.num > 1 then
		numShow = tostring(self.dataTbl.num);
	end
	self.cellCont:TipData(self.dataTbl, numShow, {"PutAway"}, true);
end

--// 显示隐藏
function UIMktBagItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

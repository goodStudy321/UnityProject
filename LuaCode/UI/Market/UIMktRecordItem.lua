--// 市场记录条目
require("UI/Market/UIPriceItem");

UIMktRecordItem = {Name = "UIMktRecordItem"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建控件
function UIMktRecordItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIMktRecordItem:Init(gameObj)
	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI市场记录条目";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 选择标志
	self.selSign = T(self.rootTrans, "SelSign");
	--// 物品cell父节点
	self.cellParent = T(self.rootTrans, "CellCont");
	--// 税收物体
	self.texObj = T(self.rootTrans, "TexCont");
	--// 收支物体
	self.mnyObj = T(self.rootTrans, "MnyCont");


	--// 物品名称
	self.itemName = C(UILabel, self.rootTrans, "ItemName", tip, false);
	--// 物品等级
	self.itemLv = C(UILabel, self.rootTrans, "Lv", tip, false);
	--// 操作类型
	self.buyType = C(UILabel, self.rootTrans, "BuyType", tip, false);
	--// 交易时间
	self.time = C(UILabel, self.rootTrans, "Time", tip, false);

	--// 税收控件
	self.texCont = ObjPool.Get(UIPriceItem);
	self.texCont:Init(self.texObj);
	--// 收支控件
	self.mnyCont = ObjPool.Get(UIPriceItem);
	self.mnyCont:Init(self.mnyObj);

	local com = CF(UIButton, self.rootTrans, tip);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickSelf();
	end;

	self.dataTbl = nil;
	self.selCallBack = nil;
	self.cellCont = nil;
	self.isSel = false;
end

--// 释放
function UIMktRecordItem:Dispose()
	if self.cellCont ~= nil then
		self.cellCont:DestroyGo();
		ObjPool.Add(self.cellCont);
		self.cellCont = nil;
	end

	self.dataTbl = nil;
	ObjPool.Add(texCont);
	ObjPool.Add(mnyCont);
end

--// 链接和初始化配置
function UIMktRecordItem:LinkAndConfig(tbData, selCB)
	self.dataTbl = tbData;
	self.selCallBack = selCB;

	local itemCfg = ItemData[tostring(self.dataTbl.typeId)];

	self.itemName.text = itemCfg.name;
	self.itemLv.text = "Lv."..tostring(itemCfg.useLevel);

	if self.dataTbl.logType == 1 then
		self.buyType.text = "购买";
		self.texCont:ShowStrData("无");
	elseif self.dataTbl.logType == 2 then
		self.buyType.text = "出售";
		self.texCont:ShowNumData(self.dataTbl.tax, 1);
	end

	self.time.text = tostring(DateTool.GetDate(self.dataTbl.time));

	--self.texCont:ShowNumData(self.dataTbl.tax, 1);
	self.mnyCont:ShowNumData(self.dataTbl.totalPrice, 1);

	self.cellCont = ObjPool.Get(UIItemCell);
	self.cellCont:InitLoadPool(self.cellParent.transform, 0.8);
	self.cellCont:TipData(self.dataTbl.itemCellData, tostring(self.dataTbl.itemCellData.num), nil, true);
end

--// 点击自身
function UIMktRecordItem:ClickSelf()
	if self.selCallBack ~= nil then
		self.selCallBack();
	end
end

--// 显示隐藏
function UIMktRecordItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

function UIMktRecordItem:SetSel(isSel)
	self.isSel = isSel;
	self.selSign:SetActive(self.isSel);
end

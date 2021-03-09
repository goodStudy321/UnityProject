--// 市场上架条目
require("UI/Market/UIPriceItem");

UIMktOnShelfItem = {Name = "UIMktOnShelfItem"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建控件
function UIMktOnShelfItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIMktOnShelfItem:Init(gameObj)
	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI市场上架条目";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 选择标志
	self.selSign = T(self.rootTrans, "SelSign");
	--// 物品cell父节点
	self.cellParent = T(self.rootTrans, "CellCont");
	--// 价钱物体
	self.mnyObj = T(self.rootTrans, "MnyCont");
	--// 密码标志物体
	self.pswObj = T(self.rootTrans, "PswSign");
	self.pswObj:SetActive(false);


	--// 物品名称
	self.itemName = C(UILabel, self.rootTrans, "ItemName", tip, false);


	--// 价钱控件
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
function UIMktOnShelfItem:Dispose()
	if self.cellCont ~= nil then
		self.cellCont:DestroyGo();
		ObjPool.Add(self.cellCont);
		self.cellCont = nil;
	end

	self.dataTbl = nil;
	ObjPool.Add(mnyCont);
end

--// 链接和初始化配置
function UIMktOnShelfItem:LinkAndConfig(tbData, selCB)
	self.dataTbl = tbData;
	self.selCallBack = selCB;

	local itemCfg = ItemData[tostring(self.dataTbl.typeId)];
	self.itemName.text = itemCfg.name;
	self.mnyCont:ShowNumData(self.dataTbl.totalPrice, 1);

	self.cellCont = ObjPool.Get(UIItemCell);
	self.cellCont:InitLoadPool(self.cellParent.transform, 0.8);
	local itemNum = "";
	if self.dataTbl.itemCellData.num ~= nil and self.dataTbl.itemCellData.num > 1 then
		itemNum = tostring(self.dataTbl.itemCellData.num);
	end
	--self.cellCont:TipData(self.dataTbl.itemCellData, tostring(self.dataTbl.itemCellData.num), nil, true);
	self.cellCont:TipData(self.dataTbl.itemCellData, itemNum, nil, true);

	if self.dataTbl ~= nil and self.dataTbl.password ~= nil and self.dataTbl.password == true then
		self.pswObj:SetActive(true);
	else
		self.pswObj:SetActive(false);
	end
end

--// 点击自身
function UIMktOnShelfItem:ClickSelf()
	if self.selCallBack ~= nil then
		self.selCallBack();
	end
end

--// 显示隐藏
function UIMktOnShelfItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

function UIMktOnShelfItem:SetSel(isSel)
	self.isSel = isSel;
	self.selSign:SetActive(self.isSel);
end

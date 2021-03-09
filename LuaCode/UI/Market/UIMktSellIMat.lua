--// 市场出售物品条目
require("UI/Market/UIPriceItem");

UIMktSellIMat = {Name = "UIMktSellIMat"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建控件
function UIMktSellIMat:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIMktSellIMat:Init(gameObj)

	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI市场出售材料条目";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 选择标志
	self.selSign = T(self.rootTrans, "SelSign");
	--// 物品cell父节点
	self.cellParent = T(self.rootTrans, "CellCont");
	--// 单价控件物体
	self.opObj = T(self.rootTrans, "OnePriceCont");
	--// 总价控件物体
	self.apObj = T(self.rootTrans, "AllPriceCont");
	--// 密码标志物体
	self.pswObj = T(self.rootTrans, "PswSign");
	self.pswObj:SetActive(false);


	--// 物品名称
	self.itemName = C(UILabel, self.rootTrans, "ItemName", tip, false);
	--// 物品等级
	self.itemLv = C(UILabel, self.rootTrans, "Lv", tip, false);

	--// 单价控件
	self.opCont = ObjPool.Get(UIPriceItem);
	self.opCont:Init(self.opObj);
	--// 总价控件
	self.apCont = ObjPool.Get(UIPriceItem);
	self.apCont:Init(self.apObj);

	local com = CF(UIButton, self.rootTrans, tip);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickSelf();
	end;

	self.cellCont = nil;
	self.dataTbl = nil;
	self.selCallBack = nil;
	self.isSel = false;
end

--// 释放
function UIMktSellIMat:Dispose()
	ObjPool.Add(opCont);
	ObjPool.Add(apCont);

	if self.cellCont ~= nil then
		self.cellCont:DestroyGo();
		ObjPool.Add(self.cellCont);
		self.cellCont = nil;
	end
end

--// 链接和初始化配置
function UIMktSellIMat:LinkAndConfig(tbData, selCB)

	self.dataTbl = tbData;
	self.selCallBack = selCB;

	local itemCfg = ItemData[tostring(self.dataTbl.typeId)];

	self.itemName.text = itemCfg.name;
	local uLv = 1;
	if itemCfg.useLevel ~= nil then
		uLv = itemCfg.useLevel;
	end
	local lvText = StrTool.Concat("Lv.", tostring(uLv));
	-- if uLv > 370 then
	if uLv > 999 then
		lvText = FamilyMgr:GetLvShowText(uLv);
	end
	self.itemLv.text = lvText;

	local goldNum = RoleAssets.Gold;
	local allPrice = self.dataTbl.totalPrice;
	local onePrice = math.ceil(self.dataTbl.totalPrice / self.dataTbl.num);
	local opShow = "";
	local apShow = "";

	if allPrice <= goldNum then
		opShow = "[F39800FF]"..onePrice.."[-]";
		apShow = "[F39800FF]"..allPrice.."[-]";
	else
		opShow = "[E83030FF]"..onePrice.."[-]";
		apShow = "[E83030FF]"..allPrice.."[-]";
	end

	self.opCont:ShowStrData(opShow, 1);
	self.apCont:ShowStrData(apShow, 1);

	self.cellCont = ObjPool.Get(UIItemCell);
	self.cellCont:InitLoadPool(self.cellParent.transform, 0.8);
	local showNum = "";
	if self.dataTbl.itemCellData.num ~= nil and self.dataTbl.itemCellData.num > 1 then
		showNum = tostring(self.dataTbl.itemCellData.num);
	end
	self.cellCont:TipData(self.dataTbl.itemCellData, showNum, nil, true);

	if self.dataTbl ~= nil and self.dataTbl.password ~= nil and self.dataTbl.password == true then
		self.pswObj:SetActive(true);
	else
		self.pswObj:SetActive(false);
	end
end

--// 点击自身
function UIMktSellIMat:ClickSelf()
	if self.selCallBack ~= nil then
		self.selCallBack();
	end
end

--// 显示隐藏
function UIMktSellIMat:Show(sOh)
	self.itemObj:SetActive(sOh);
end

function UIMktSellIMat:SetSel(isSel)
	self.isSel = isSel;
	self.selSign:SetActive(self.isSel);
end

--// 道庭物品控件

UIFDItemCell = Super:New{Name = "UIFDItemCell"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;

--// 创建控件
--function UIFDItemCell:New(o)
--	o = o or {}
--	setmetatable(o, self);
--	self.__index = self;
--	return o
--end

--// 初始化赋值
function UIFDItemCell:Init(gameObj)
	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI道庭仓库物品控件";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;


	self.selSignObj = T(self.rootTrans, "SelSign");
	self.selBlockObj = T(self.rootTrans, "SelBlock");

	--// 多选使用
	UITool.SetBtnSelf(self.selBlockObj, self.ClickSelBlock, self, self.Name);


	--// 是否需要比较
	self.isCom = false;
	--// 显示按钮列表
	self.btnList = nil;
	--// 是否可以选择
	self.canSel = false;
	--// 是否选择
	self.isSel = false;
	--// 选择事件回调
	self.selCallBack = nil;
	--// 是否处于道庭仓库中
	self.inWareHouse = false;
	self.cellCont = nil;
	--// 链接数据
	self.tbData = nil;
end

--// 释放
function UIFDItemCell:Dispose()
	if self.cellCont ~= nil then
		self.cellCont.showDepotPoint=nil
		self.cellCont:DestroyGo();
		ObjPool.Add(self.cellCont);
		self.cellCont = nil;
	end
	--self.showDepotPoint = nil
	--self:DestroyGo()
	--ObjPool.Add(self)

	self.tbData = nil;
end

--// 链接和初始化配置
function UIFDItemCell:LinkAndConfig(tbData, isCom, btnList, canSel, selCB, isInWarehouse)
	self.tbData = tbData;

	--// 创建一个空框
	if self.tbData == nil then
		self.isCom = false;
		self.btnList = nil;
		self.canSel = false;
		self.isSel = false;
		self.selCallBack = nil;
		return;
	end

	self.tbData = tbData;
	self.isCom = false;
	if isCom ~= nil then
		self.isCom = isCom;
	end
	self.btnList = btnList;

	self.canSel = false;
	if canSel ~= nil then
		self.canSel = canSel;
	end

	self.inWareHouse = false
	if isInWarehouse then
		self.inWareHouse = isInWarehouse
	end

	self.selCallBack = selCB;
	self:SetCanSel(self.canSel);
	self:ResetSel();

	self.cellCont = ObjPool.Get(UIItemCell);
	self.cellCont.showDepotPoint = true;
	self.cellCont.isInWarehouse = self.inWareHouse
	self.cellCont:InitLoadPool(self.rootTrans, 1);
	self.cellCont:TipData(self.tbData, 1, self.btnList, self.isCom);

	self.cellCont:IconUp(false);
	self.cellCont:IconDown(false);

	--self.showDepotPoint = true
	--self:InitLoadPool(self.rootTrans, 1)
	--local btnList = self.btnList
	--self:TipData(self.tbData, 1, btnList, self.isCom)
	--
	--self:IconUp(false)
	--self:IconDown(false)



	--// 自填充类型
	if self.tbData.fightVal ~= nil then
		local wear = EquipMgr.hasEquipDic[self.tbData.wearPart];
		if wear == nil then
			self.cellCont:IconUp(true);
			--self:IconUp(true)
			return;
		end

		if wear.fight < self.tbData.fightVal then
			self.cellCont:IconUp(true);
			--self:IconUp(true)
		elseif wear.fight > self.tbData.fightVal then
			self.cellCont:IconDown(true);
			--self:IconDown(true)
		end
	--// 背包类型
	else
		if self.tbData.isUp == true then
			self.cellCont:IconUp(true);
			--self:IconUp(true)
		elseif self.tbData.isDown == true then
			self.cellCont:IconDown(true);
			--self:IconDown(true)
		end
	end
end

--// 显示隐藏
function UIFDItemCell:Show(sOh)
	self.itemObj:SetActive(sOh);
end

function UIFDItemCell:SetSel(isSel)
	self.isSel = isSel;
	self:SetSelSign(self.isSel);
end

--// 设置选择标记
function UIFDItemCell:SetSelSign(isSel)
	self.selSignObj:SetActive(isSel);
end

--// 设置是否可以选择
function UIFDItemCell:SetCanSel(canSel)
	self.canSel = canSel;
	self.selBlockObj:SetActive(self.canSel);
end

--// 重置选择
function UIFDItemCell:ResetSel()
	self:SetSel(false);
end

--// 点击事件
function UIFDItemCell:ClickSelBlock()
	if self.canSel == true then
		if self.isSel == false then
			self.isSel = true;
		else
			self.isSel = false;
		end
		self:SetSel(self.isSel);
	end

	if self.selCallBack ~= nil then
		self.selCallBack(self.tbData.id, self.isSel);
	end
end








--// 打开弹出提示回调
--function UIFDItemCell:OpenCb(name)
--	local ui = UIMgr.Get(name);
--	if ui then
--		if self.itemData.isEqu == true and self.btnList ~= nil then
--			-- local equTbs = PropMgr.ATbDic[tostring(self.itemData.typeId)];
--			-- local equTb = equTbs[tostring(self.itemData.uId)];
--
--			--ui:UpData(equTb, self.isCom);
--			ui:UpData(self.itemData.typeId, self.isCom);
--			ui:ShowBtn(self.btnList);
--
--			for i = 1, #self.btnList do
--				if self.btnList[i] == "Donate" then
--					ui:SetDonateEvnt(self.btnCBList[i]);
--				elseif self.btnList[i] == "Exchange" then
--					ui:SetExchangeEvnt(self.btnCBList[i]);
--				end
--			end
--		else
--			ui:UpData(self.itemData.typeId, self.isCom);
--			ui:ShowBtn(self.btnList);
--			ui:SetExchangeEvnt(self.btnCBList[1]);
--		end
--	end
--end
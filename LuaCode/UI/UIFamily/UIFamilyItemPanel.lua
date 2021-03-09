 --// 帮派物品面板
 require("UI/Cmn/UICheckBox");
 require("UI/Cmn/UIPopMenu");
 require("UI/UIFamily/UIFDItemCell");


 UIFamilyItemPanel = Super:New{Name = "UIFamilyItemPanel"};

 local panelCtrl = {}

 local iLog = iTrace.Log;
 local iError = iTrace.Error;


 --// 初始化面板
 function UIFamilyItemPanel:Init(panelObject)

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

     --// 勾选框物体
     panelCtrl.cBoxObj = T(panelCtrl.rootTrans, "ComCont/CheckBox");
     --// 品阶筛选菜单
     panelCtrl.pMenuObj1 = T(panelCtrl.rootTrans, "ComCont/PopMenu1");
     --// 品质筛选菜单
     panelCtrl.pMenuObj2 = T(panelCtrl.rootTrans, "ComCont/PopMenu2");
 	--// 帮派物体克隆主体
 	panelCtrl.cellMain = T(panelCtrl.rootTrans, "ItemsCont/ItemsSV/GridObj/ItemCell_99");
 	--// 捐献按钮
 	panelCtrl.depotBtnObj = T(panelCtrl.rootTrans, "DonateBtn");
 	--// 删除状态按钮
 	panelCtrl.delStateBtnObj = T(panelCtrl.rootTrans, "DelStateBtn");
 	--// 批量删除按钮
 	panelCtrl.deleteBtnObj = T(panelCtrl.rootTrans, "DeleteBtn");
 	--// 返回捐献按钮
 	panelCtrl.returnBtnObj = T(panelCtrl.rootTrans, "ReturnBtn");


 	--------- 获取控件 ---------

 	local tip = "帮派物品面板"
 	--// 滚动区域
 	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "ItemsCont/ItemsSV", tip, false);
 	--// 排序控件
     panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "ItemsCont/ItemsSV/GridObj", tip, false);
     --// 仓库积分
     panelCtrl.depotPointL = C(UILabel, panelCtrl.rootTrans, "PointCont/Point", tip, false);

 	--// 打开捐献装备按钮
 	local com = C(UIButton, panelCtrl.rootTrans, "DonateBtn", tip, false);
 	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickDonateBtn(); end;
 	--//
 	com = C(UIButton, panelCtrl.rootTrans, "DelStateBtn", tip, false);
 	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickDelStateBtn(); end;
 	--//
 	com = C(UIButton, panelCtrl.rootTrans, "DeleteBtn", tip, false);
 	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickDeleteBtn(); end;
 	--//
 	com = C(UIButton, panelCtrl.rootTrans, "ReturnBtn", tip, false);
 	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickReturnBtn(); end;

    
     --// 勾选框
     panelCtrl.cBox = ObjPool.Get(UICheckBox);
     panelCtrl.cBox:Init(panelCtrl.cBoxObj, function(isShow)
         self:ShowSelfVocation(isShow);
     end);
     --// 筛选品阶下拉菜单
     panelCtrl.pMenu1 = ObjPool.Get(UIPopMenu);
     panelCtrl.pMenu1:Init(panelCtrl.pMenuObj1, 7, function(quaIndex)
         self:ChangeQualityShow(quaIndex);
 	end);
 	panelCtrl.pMenu1:CloseMenu();
     --// 筛选品质下拉菜单
     panelCtrl.pMenu2 = ObjPool.Get(UIPopMenu);
     panelCtrl.pMenu2:Init(panelCtrl.pMenuObj2, 4, function(colIndex)
         self:ChangeColorShow(colIndex)
 	end);
 	panelCtrl.pMenu2:CloseMenu();

 	self.OnNewData = EventHandler(self.OnClickNewData, self);
 	EventMgr.Add("NewFamilyDepotData", self.OnNewData);
 	self.OnShowPoint = EventHandler(self.ShowPoint, self);
 	EventMgr.Add("NewIntegral", self.OnShowPoint);


 	--// 帮派成员条目列表
 	panelCtrl.itemCells = {};
 	--// 延迟重置倒数
 	panelCtrl.delayResetCount = 0;
 	--// 显示本职业
 	panelCtrl.showSelfJob = false;
 	--// 品阶索引
 	panelCtrl.quaIndex = 0;
 	--// 颜色索引
 	panelCtrl.colIndex = 0;
 	--// 是否在删除状态
 	panelCtrl.inDelState = false;
 	--// 意图删除物品Uid列表
 	panelCtrl.delUids = {};

 	panelCtrl.init = true;
 end

 --// 打开
 function UIFamilyItemPanel:Open()
 	panelCtrl.cBox:SetTick(panelCtrl.showSelfJob);
 	panelCtrl.pMenu1:SynBtnIndexShow(panelCtrl.quaIndex);
 	panelCtrl.pMenu2:SynBtnIndexShow(panelCtrl.colIndex);

 	panelCtrl.depotBtnObj:SetActive(true);
 	if FamilyMgr:CanDealWithMember() == true then
 		panelCtrl.delStateBtnObj:SetActive(true);
 	else
 		panelCtrl.delStateBtnObj:SetActive(false);
 	end
 	panelCtrl.deleteBtnObj:SetActive(false);
 	panelCtrl.returnBtnObj:SetActive(false);

 	self:ShowData();
 end

 --// 更新
 function UIFamilyItemPanel:Update()
 	if panelCtrl.delayResetCount > 0 then
 		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
 		if panelCtrl.delayResetCount <= 0 then
 			panelCtrl.delayResetCount = 0;
 			panelCtrl.itemsSV:ResetPosition();
 		end
 	end
 end

 --// 销毁释放
 function UIFamilyItemPanel:Dispose()
 	EventMgr.Remove("NewFamilyDepotData", self.OnNewData);
 	EventMgr.Remove("NewIntegral", self.OnShowPoint);

     ObjPool.Add(panelCtrl.cBox);
     ObjPool.Add(panelCtrl.pMenu1);
 	ObjPool.Add(panelCtrl.pMenu2);

 	for i = 1, #panelCtrl.itemCells do
 		panelCtrl.itemCells[i]:Dispose();
 		ObjPool.Add(panelCtrl.itemCells[i]);
 	end
 	panelCtrl.itemCells = {};
	
 	panelCtrl.init = false;
 end

 --// 转换删除状态
 function UIFamilyItemPanel:ChangeDelState(changeIn)
 	panelCtrl.inDelState = changeIn;
 	panelCtrl.delUids = {};
 	if panelCtrl.inDelState == true then
 		panelCtrl.depotBtnObj:SetActive(false);
 		panelCtrl.delStateBtnObj:SetActive(false);
 		panelCtrl.deleteBtnObj:SetActive(true);
 		panelCtrl.returnBtnObj:SetActive(true);
 	else
 		panelCtrl.depotBtnObj:SetActive(true);
		if FamilyMgr:CanDealWithMember() == true then
			panelCtrl.delStateBtnObj:SetActive(true);
		end
 		panelCtrl.deleteBtnObj:SetActive(false);
 		panelCtrl.returnBtnObj:SetActive(false);
 	end

 	self:ShowData(panelCtrl.inDelState);
 end

 --// 新数据刷新
 function UIFamilyItemPanel:OnClickNewData()
 	self:ChangeDelState(false);
 end

 --// 刷新数据显示
 function UIFamilyItemPanel:ShowData(forDel)

 	for i = 1, #panelCtrl.itemCells do
 		panelCtrl.itemCells[i]:Dispose();
 		--ObjPool.Add(panelCtrl.itemCells[i]);
 	end

 	local itemDatas = FamilyMgr:GetFamilyDepotItems(forDel);
 	if itemDatas == nil or #itemDatas <= 0 then
 		self:RenewItemCellNum(0);
		panelCtrl.depotPointL.text = tostring(FamilyMgr:GetSelfIntegral());
 		return;
 	end

 	if panelCtrl.showSelfJob == true then
 		itemDatas = FamilyMgr:ChoseJobItems(User.MapData.Category, itemDatas);
 	end

 	if panelCtrl.quaIndex > 0 then
 		itemDatas = FamilyMgr:GetDepotItemsByQuality(panelCtrl.quaIndex + 3, itemDatas);
 	end

 	if panelCtrl.colIndex > 0 then
 		itemDatas = FamilyMgr:GetDepotItemsByColor(panelCtrl.colIndex + 3, itemDatas);
 	end

 	itemDatas = FamilyMgr:SortDepotItems(itemDatas);

 	local itNum = 200;
 	if #itemDatas > 200 then
 		itNum = #itemDatas;
 		--iError("LY", "Item number more than 200 !!! ");
 	end

 	self:RenewItemCellNum(itNum);
 	for i = 1,#itemDatas do
 		--local bList = {"Donate"};
 		if forDel == true then
 			panelCtrl.itemCells[i]:LinkAndConfig(itemDatas[i], true, nil, true, function(itemUid, isSel)
 				self:SelItemTemp(itemUid, isSel);
 			end);
 		else
 			local bList = {"Exchange"};
 			--local bCBList = {};
 			--bCBList[#bCBList + 1] = function() self:ExchangeDepot(newItemData.uId, 1) end;
 			panelCtrl.itemCells[i]:LinkAndConfig(itemDatas[i], true, bList, false, nil, true);
 		end
 	end
 	for i = #itemDatas + 1, #panelCtrl.itemCells do
 		panelCtrl.itemCells[i]:LinkAndConfig(nil);
 	end

 	panelCtrl.depotPointL.text = tostring(FamilyMgr:GetSelfIntegral());
 end

 --//
 function UIFamilyItemPanel:ShowPoint()
 	panelCtrl.depotPointL.text = tostring(FamilyMgr:GetSelfIntegral());
 end

 --// 临时选择物品装备处理
 function UIFamilyItemPanel:SelItemTemp(itemUid, isSel)
 	local inList = false;
 	for i = 1, #panelCtrl.delUids do
 		if panelCtrl.delUids[i] == itemUid then
 			inList = true;
 			break;
 		end
 	end

 	if isSel == true then
 		if inList == false then
 			panelCtrl.delUids[#panelCtrl.delUids + 1] = itemUid;
 		else
 			iError("LY", "Select item has in selected list !!! ");
 		end
 	else
 		if inList == true then
 			local newList = {};
 			for i = 1, #panelCtrl.delUids do
 				if panelCtrl.delUids[i] ~= itemUid then
 					newList[#newList + 1] = panelCtrl.delUids[i];
 				end
 			end
 			panelCtrl.delUids = newList;
 		else
 			iError("LY", "Select item is not in selected list !!! ");
 		end
 	end
 end

 --// 克隆帮派物品条目
 function UIFamilyItemPanel:CloneItemCell()
 	local cloneObj = GameObject.Instantiate(panelCtrl.cellMain);
 	cloneObj.transform.parent = panelCtrl.cellMain.transform.parent;
 	cloneObj.transform.localPosition = panelCtrl.cellMain.transform.localPosition;
 	cloneObj.transform.localRotation = panelCtrl.cellMain.transform.localRotation;
 	cloneObj.transform.localScale = panelCtrl.cellMain.transform.localScale;
 	cloneObj:SetActive(true);

 	local cloneItem = ObjPool.Get(UIFDItemCell);
 	cloneItem:Init(cloneObj);

 	local newName = "";
 	if #panelCtrl.itemCells + 1 >= 100 then
 		newName = string.gsub(panelCtrl.cellMain.name, "99", tostring(#panelCtrl.itemCells + 1));
 	elseif #panelCtrl.itemCells + 1 >= 10 then
 		newName = string.gsub(panelCtrl.cellMain.name, "99", "0"..tostring(#panelCtrl.itemCells + 1));
 	else
 		newName = string.gsub(panelCtrl.cellMain.name, "99", "00"..tostring(#panelCtrl.itemCells + 1));
 	end
 	cloneObj.name = newName;
 	panelCtrl.itemCells[#panelCtrl.itemCells + 1] = cloneItem;

 	return cloneItem;
 end

 --// 重置帮派装备数量
 function UIFamilyItemPanel:RenewItemCellNum(number)
 	for a = 1, #panelCtrl.itemCells do
 		panelCtrl.itemCells[a]:Show(false)
 	end

 	local realNum = number;
 	if realNum <= #panelCtrl.itemCells then
 		for a = 1, realNum do
 			panelCtrl.itemCells[a]:Show(true);
 		end
 	else
 		for a = 1, #panelCtrl.itemCells do
 			panelCtrl.itemCells[a]:Show(true)
 		end

 		local needNum = realNum - #panelCtrl.itemCells;
 		for a = 1, needNum do
 			self:CloneItemCell();
 		end
 	end

 	panelCtrl.itemGrid:Reposition();

 	self:DelayResetSVPosition();
 end

 --// 延迟重置滑动面板位置
 function UIFamilyItemPanel:DelayResetSVPosition()
 	panelCtrl.delayResetCount = 2;
 end

 --// 点击打开捐献按钮
 function UIFamilyItemPanel:ClickDonateBtn()
 	UIFamilyEquipSelPanel:Open();
 end

 --// 点击转换删除状态
 function UIFamilyItemPanel:ClickDelStateBtn()
 	self:ChangeDelState(true);
 end

 --// 点击删除按钮
 function UIFamilyItemPanel:ClickDeleteBtn()
 	FamilyMgr:ReqFamilyDelDepot(panelCtrl.delUids);
 	self:ChangeDelState(false);
 end

 --// 点击返回捐献状态
 function UIFamilyItemPanel:ClickReturnBtn()
 	self:ChangeDelState(false);
 end

 --// 显示本职业
 function UIFamilyItemPanel:ShowSelfVocation(isShow)
 	if panelCtrl.showSelfJob ~= isShow then
 		panelCtrl.showSelfJob = isShow;
 		self:ShowData();
 	end
 end

 --// 筛选品阶显示
 function UIFamilyItemPanel:ChangeQualityShow(quaIndex)
 	if panelCtrl.quaIndex ~= quaIndex then
 		panelCtrl.quaIndex = quaIndex;
 		self:ShowData();
 	end
 end

 --// 筛选品质显示
 function UIFamilyItemPanel:ChangeColorShow(colIndex)
 	if panelCtrl.colIndex ~= colIndex then
 		panelCtrl.colIndex = colIndex;
 		self:ShowData();
 	end
 end

 --// 兑换物品装备
 function UIFamilyItemPanel:ExchangeDepot(itemUId, number)
 	FamilyMgr:ReqFamilyExcDepot(itemUId, number);
 end
 --// 帮派装备选择面板
 --require("UI/UIFamily/UIFItemCell");

 UIFamilyEquipSelPanel = Super:New{Name = "UIFamilyEquipSelPanel"};

 local panelCtrl = {}

 local iLog = iTrace.Log;
 local iError = iTrace.Error;


 --// 初始化面板
 function UIFamilyEquipSelPanel:Init(panelObject)

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

 	--// 帮派成员条目克隆主体
 	panelCtrl.cellMain = T(panelCtrl.rootTrans, "ListCont/ItemsSV/GridObj/ItemCell_99");

 	--------- 获取控件 ---------

 	local tip = "UI帮派装备选择面板"
 	--// 滚动区域
 	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "ListCont/ItemsSV", tip, false);
 	--// 排序控件
 	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "ListCont/ItemsSV/GridObj", tip, false);

 	--// 关闭按钮
 	local com = C(UIButton, panelCtrl.rootTrans, "ListCont/ContBg/TopBg/CloseBtn/CloseBtn", tip, false);
 	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:Close(); end;
 	--// 关闭面板按钮
 	com = C(UIButton, panelCtrl.rootTrans, "Bg", tip, false);
 	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:Close(); end;

 	--// 添加监听
 	PropMgr.eUpdate:Add(self.BagUpdate, self);
 	PropMgr.eMSMUpdate:Add(self.BagUpdate, self)


 	--// 帮派成员条目列表
 	panelCtrl.itemCells = {};
 	--// 延迟重置倒数
 	panelCtrl.delayResetCount = 0;

 	panelCtrl.init = true;
 	panelCtrl.isOpen = false;
 end

 --// 更新
 function UIFamilyEquipSelPanel:Update()
 	if panelCtrl.delayResetCount > 0 then
 		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
 		if panelCtrl.delayResetCount <= 0 then
 			panelCtrl.delayResetCount = 0;
 			panelCtrl.itemsSV:ResetPosition();
 		end
 	end
 end

 --// 打开
 function UIFamilyEquipSelPanel:Open()
 	panelCtrl.panelObj:SetActive(true);
 	panelCtrl.isOpen = true;

 	self:ShowData();
 end

 --// 关闭
 function UIFamilyEquipSelPanel:Close()
 	for i = 1, #panelCtrl.itemCells do
 		panelCtrl.itemCells[i]:Dispose();
 		--ObjPool.Add(panelCtrl.itemCells[i]);
 	end
 	--panelCtrl.itemCells ={};

 	panelCtrl.panelObj:SetActive(false);
 	panelCtrl.isOpen = false;
 end

 --// 销毁释放窗口
 function UIFamilyEquipSelPanel:Dispose()
 	PropMgr.eUpdate:Remove(self.BagUpdate, self);
	PropMgr.eMSMUpdate:Remove(self.BagUpdate, self)
 	for i = 1, #panelCtrl.itemCells do
 		panelCtrl.itemCells[i]:Dispose();
 		ObjPool.Add(panelCtrl.itemCells[i]);
 	end
 	panelCtrl.itemCells ={};

 	panelCtrl.init = false;
 end

 --// 刷新成员列表数据
 function UIFamilyEquipSelPanel:ShowData(notRepos)
 	if panelCtrl.isOpen == false then
 		return;
 	end

 	if panelCtrl.itemCells ~= nil then
 		for i = 1, #panelCtrl.itemCells do
 			panelCtrl.itemCells[i]:Dispose();
 			--ObjPool.Add(panelCtrl.itemCells[i]);
 		end
 	end

 	--// 获取可捐献装备结构
 	local goodsTbl = FamilyMgr:GetCanDepotEquipData();
 	self:RenewItemCellNum(#goodsTbl, notRepos);
 	for i = 1, #goodsTbl do
 		local bList = {"Donate"};
 		panelCtrl.itemCells[i]:LinkAndConfig(goodsTbl[i], true, bList, false, nil);
 	end
 end

 --// 克隆帮派物品条目
 function UIFamilyEquipSelPanel:CloneItemCell()
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
 function UIFamilyEquipSelPanel:RenewItemCellNum(number, notRepos)
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

 	if notRepos ~= nil and notRepos == true then
 		return;
 	end
 	self:DelayResetSVPosition();
 end

 --// 延迟重置滑动面板位置
 function UIFamilyEquipSelPanel:DelayResetSVPosition()
 	panelCtrl.delayResetCount = 2;
 end

 --// 背包物品更新
 function UIFamilyEquipSelPanel:BagUpdate()
 	if panelCtrl.isOpen == false then
 		return;
 	end

 	UIMgr.Close(EquipTip.Name)
 	UIMgr.Close(PropTip.Name)
 	self:ShowData(true);
 end
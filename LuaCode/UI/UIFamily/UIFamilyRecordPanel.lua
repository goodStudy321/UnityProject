 --// 帮派物品面板
 require("UI/Cmn/UITextBox");


 UIFamilyRecordPanel = Super:New{Name = "UIFamilyRecordPanel"};

 local panelCtrl = {}

 local iLog = iTrace.Log;
 local iError = iTrace.Error;


 --// 初始化面板
 function UIFamilyRecordPanel:Init(panelObject)

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

 	--// 记录条目克隆主体
 	panelCtrl.itemMain = T(panelCtrl.rootTrans, "ListCont/ListSV/ListGrid/RecordItem_99");
 	panelCtrl.itemMain:SetActive(false);

 	--------- 获取控件 ---------

 	local tip = "帮派记录面板"
 	--// 滚动区域
 	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "ListCont/ListSV", tip, false);
 	--// 排序控件
 	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "ListCont/ListSV/ListGrid", tip, false);
	
 	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
 	EventMgr.Add("NewDepotLog", panelCtrl.OnNewData);

 	--// 日志数据
 	panelCtrl.logsData = nil;
 	--// 帮派记录条目列表
 	panelCtrl.items = {};
 	--// 延迟重置倒数
 	panelCtrl.delayResetCount = 0;

 	panelCtrl.init = true;
 end

 --// 更新
 function UIFamilyRecordPanel:Update()
 	if panelCtrl.delayResetCount > 0 then
 		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
 		if panelCtrl.delayResetCount <= 0 then
 			panelCtrl.delayResetCount = 0;
 			panelCtrl.itemsSV:ResetPosition();
 		end
 	end
 end

 --// 销毁释放
 function UIFamilyRecordPanel:Dispose()
 	EventMgr.Remove("NewDepotLog", panelCtrl.OnNewData);

     for a = 1, #panelCtrl.items do
 		ObjPool.Add(panelCtrl.items[a]);
 	end
	
 	panelCtrl.init = false;
 end

 --// 刷新数据显示
 function UIFamilyRecordPanel:ShowData()
 	panelCtrl.logsData = FamilyMgr:GetFamilyDepotLogs();
 	if panelCtrl.logsData == nil or #panelCtrl.logsData <= 0 then
 		self:RenewItemNum(0);
 		return;
 	end

 	local iNum = #panelCtrl.logsData;
 	if iNum > 50 then
 		iNum = 50;
 	end
 	self:RenewItemNum(iNum);

 	for i = 1, #panelCtrl.items do
 		local evnTbl = {};
 		evnTbl[1] = function() self:ClickLogItem(i) end
 		local textList = {};
 		--// 玩家名
 		textList[#textList + 1] = panelCtrl.logsData[i].roleName;
 		--// 做了什么
 		if panelCtrl.logsData[i].type == 0 then
 			textList[#textList + 1] = "兑换了"
 		else
 			textList[#textList + 1] = "捐献了"
 		end
 		--// 道具名称
 		local itemInfo = ItemData[tostring(panelCtrl.logsData[i].good.type_id)];
 		if itemInfo ~= nil then
 			local comText = FamilyMgr:ChangeTextColByQua(itemInfo.name, itemInfo.quality);
 			textList[#textList + 1] = StrTool.Concat("[u]", comText, "[/u]");
 		end
 		panelCtrl.items[i]:LinkItem(textList, {3}, evnTbl);
 	end
 end

 --// 克隆帮派记录条目
 function UIFamilyRecordPanel:CloneRecordItem()
 	local cloneObj = GameObject.Instantiate(panelCtrl.itemMain);
 	cloneObj.transform.parent = panelCtrl.itemMain.transform.parent;
 	cloneObj.transform.localPosition = panelCtrl.itemMain.transform.localPosition;
 	cloneObj.transform.localRotation = panelCtrl.itemMain.transform.localRotation;
 	cloneObj.transform.localScale = panelCtrl.itemMain.transform.localScale;
 	cloneObj:SetActive(true);

 	local newName = "";
 	if #panelCtrl.items + 1 >= 100 then
 		newName = string.gsub(panelCtrl.itemMain.name, "99", tostring(#panelCtrl.items + 1));
 	elseif #panelCtrl.items + 1 >= 10 then
 		newName = string.gsub(panelCtrl.itemMain.name, "99", "0"..tostring(#panelCtrl.items + 1));
 	else
 		newName = string.gsub(panelCtrl.itemMain.name, "99", "00"..tostring(#panelCtrl.items + 1));
 	end
 	cloneObj.name = newName;

 	local cloneItem = ObjPool.Get(UITextBox);
 	cloneItem:Init(cloneObj);
 	--cloneObj.name = string.gsub(panelCtrl.itemMain.name, "99", tostring(#panelCtrl.items + 1));

 	panelCtrl.items[#panelCtrl.items + 1] = cloneItem;

 	return cloneItem;
 end

 --// 重置帮派记录数量
 function UIFamilyRecordPanel:RenewItemNum(number)
 	for a = 1, #panelCtrl.items do
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
 			self:CloneRecordItem();
 		end
 	end

 	panelCtrl.itemGrid:Reposition();

 	self:DelayResetSVPosition();
 end

 --// 延迟重置滑动面板位置
 function UIFamilyRecordPanel:DelayResetSVPosition()
 	panelCtrl.delayResetCount = 2;
 end

 --// 点击日志条目
 function UIFamilyRecordPanel:ClickLogItem(itemIndex)
 	--print("              ===============              "..itemIndex)
 	if panelCtrl.logsData == nil or itemIndex <= 0 or itemIndex > #panelCtrl.logsData then
 		return;
 	end

 	local logData = panelCtrl.logsData[itemIndex];
 	if logData == nil then
 		return;
 	end

 	local tData = ItemData[tostring(logData.good.type_id)];
 	if tData ~= nil then
 		if tData.uFx == 1 then
 			UIMgr.Open(EquipTip.Name, function(name)
 				local ui = UIMgr.Get(name);
 				--local logData = panelCtrl.logsData[itemIndex];
 				ui:UpData(logData.good , false, nil, false);
 			end)
 		else
 			UIMgr.Open(PropTip.Name, function(name)
 				local ui = UIMgr.Get(name);
 				--local logData = panelCtrl.logsData[itemIndex];
 				ui:UpData(logData.good.type_id);
 			end)
 		end
 	end
 end
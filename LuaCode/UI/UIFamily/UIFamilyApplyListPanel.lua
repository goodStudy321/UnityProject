--// 道庭申请列表面板
require("UI/UIFamily/UIFamilyApplyItem")

UIFamilyApplyListPanel = Super:New{Name = "UIFamilyApplyListPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIFamilyApplyListPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyApplyListPanel create !!! ");

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 帮派申请条目克隆主体
	panelCtrl.applyItemMain = T(panelCtrl.rootTrans, "ListCont/DataCont/ApplySV/ListGrid/ApplyItem_99");

	--------- 获取控件 ---------

	local tip = "UI道庭申请列表面板"
	--// 滚动区域
	panelCtrl.applySV = C(UIScrollView, panelCtrl.rootTrans, "ListCont/DataCont/ApplySV", tip, false);
	--// 排序控件
	panelCtrl.listGrid = C(UIGrid, panelCtrl.rootTrans, "ListCont/DataCont/ApplySV/ListGrid", tip, false);

	--// 关闭按钮
	local com = C(UIButton, panelCtrl.rootTrans, "ListCont/TitleCon/CloseBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:Close(); end;
	--// 一键批准按钮
	com = C(UIButton, panelCtrl.rootTrans, "ListCont/DataCont/CtrlCon/AllYesBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickAllYesBtn(); end;
	--// 一键拒绝按钮
	com = C(UIButton, panelCtrl.rootTrans, "ListCont/DataCont/CtrlCon/AllNoBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickAllNoBtn(); end;
	--// 申请条件按钮
	com = C(UIButton, panelCtrl.rootTrans, "ListCont/DataCont/CtrlCon/ApplyConBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickApplyConBtn(); end;

	panelCtrl.applyItemMain:SetActive(false);

	-- iTool.SetFunc(self,"ShowApplyData");
	-- EventMgr.Add( "FamilyApplyListUpdate", self.ShowApplyData );

	panelCtrl.onNewData = EventHandler(self.ShowApplyData, self);
	EventMgr.Add("FamilyApplyListUpdate", panelCtrl.onNewData)

	--// 帮派成员条目列表
	panelCtrl.applyItems = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.init = true;
	panelCtrl.isOpen = false;
end

--// 更新
function UIFamilyApplyListPanel:Update()
	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.applySV:ResetPosition();
		end
	end
end

--// 打开
function UIFamilyApplyListPanel:Open()
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.isOpen = true;

	panelCtrl.curApplyPage = 1;
	self:ShowApplyData();
end

--// 关闭
function UIFamilyApplyListPanel:Close()
	panelCtrl.panelObj:SetActive(false);
	panelCtrl.isOpen = false;
end

--// 销毁释放窗口
function UIFamilyApplyListPanel:Dispose()
	EventMgr.Remove("FamilyApplyListUpdate", panelCtrl.onNewData);

	for i = 1, #panelCtrl.applyItems do
		ObjPool.Add(panelCtrl.applyItems[i]);
	end
	panelCtrl.applyItems ={};

	panelCtrl.init = false;
end

--// 点击一键同意按钮
function UIFamilyApplyListPanel:ClickAllYesBtn()
	FamilyMgr:AgreeAllFamilyApply();
end

--// 点击一键拒绝按钮
function UIFamilyApplyListPanel:ClickAllNoBtn()
	FamilyMgr:RefuseAllFamilyApply();
end

--// 刷新申请列表数据
function UIFamilyApplyListPanel:ShowApplyData()
	if panelCtrl.isOpen == false then
		return;
	end

	local bInd = 1;
	local eInd = 100;
	local dataList = FamilyMgr:GetFamilyApplyData(bInd, eInd);
	local tItemNum = 0;

	if dataList ~= nil then
		tItemNum = #dataList;
	end
	
	self:RenewApplyItemNum(tItemNum);
	for i = 1, tItemNum do
		--panelCtrl.memberItems[i]:ResetData(dataList[i]);
		panelCtrl.applyItems[i]:ResetData(dataList[i]);
	end
end

--// 克隆帮派申请条目
function UIFamilyApplyListPanel:CloneApplyItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.applyItemMain);
	cloneObj.transform.parent = panelCtrl.applyItemMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.applyItemMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.applyItemMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.applyItemMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIFamilyApplyItem);
	cloneItem:Init(cloneObj);
	-- cloneObj.name = string.gsub(cloneObj.name, "99", tostring(#panelCtrl.applyItems + 1));
	-- panelCtrl.applyItems[#panelCtrl.applyItems + 1] = cloneItem;

	local newName = "";
	if #panelCtrl.applyItems + 1 >= 100 then
		newName = string.gsub(panelCtrl.applyItemMain.name, "99", tostring(#panelCtrl.applyItems + 1));
	elseif #panelCtrl.applyItems + 1 >= 10 then
		newName = string.gsub(panelCtrl.applyItemMain.name, "99", "0"..tostring(#panelCtrl.applyItems + 1));
	else
		newName = string.gsub(panelCtrl.applyItemMain.name, "99", "00"..tostring(#panelCtrl.applyItems + 1));
	end
	cloneObj.name = newName;
	panelCtrl.applyItems[#panelCtrl.applyItems + 1] = cloneItem;

	return cloneItem;
end

--// 重置帮派申请条目数量
function UIFamilyApplyListPanel:RenewApplyItemNum(number)
	for a = 1, #panelCtrl.applyItems do
		panelCtrl.applyItems[a]:Show(false)
	end

	local realNum = number;
	if realNum < 0 then
		realNum = 0;
	end

	if realNum <= #panelCtrl.applyItems then
		for a = 1, realNum do
			panelCtrl.applyItems[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.applyItems do
			panelCtrl.applyItems[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.applyItems;
		for a = 1, needNum do
			self:CloneApplyItem();
		end
	end

	panelCtrl.listGrid:Reposition();
	--panelCtrl.memberInfoSV:ResetPosition();

	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIFamilyApplyListPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end

--// 点击申请条件按钮
function UIFamilyApplyListPanel:ClickApplyConBtn()
	UIFamilyConfigPanel:Open();
end
--// 帮派列表界面
require("UI/UIFamily/UIFamilyInfoItem")
require("UI/UIFamily/UINewFamilyPanel")

UIFamilyListWnd = UIBase:New{Name = "UIFamilyListWnd"}

local winCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;
local ET = EventMgr.Trigger;

--// 帮派显示条目最大数量
local MAXITEMNUM = 8;
--// 解锁帮派系统等级
--local FAMILYUNLOCKLV = 110;

--// 初始化界面
--// 链接所有操作物体
function UIFamilyListWnd:InitCustom()

	if winCtrl.init ~= nil and winCtrl.init == true then
		return;
	end
	winCtrl.init = false;

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 帮派信息条目克隆主体
	winCtrl.familyInfoMain = T(winCtrl.winRootTrans, "WndContainer/MainPanel/FamilyInfoSV/UIWrapCont/FamilyCont_99");
	--// 创建道庭按钮物体
	winCtrl.createBtnObj = T(winCtrl.winRootTrans, "WndContainer/MainPanel/ConBar/CreateBtn");
	--// 创建道庭面板
	winCtrl.newFamilyPanelObj = T(winCtrl.winRootTrans, "FamilyCreatePanel");

	--------- 获取控件 ---------

	local tip = "UI帮派列表界面";

	--// 滚动区域
	winCtrl.infoScrollView = C(UIScrollView, winCtrl.winRootTrans, "WndContainer/MainPanel/FamilyInfoSV", tip, false);
	--// 排序控件
	--winCtrl.infoGrid = C(UIGrid, winCtrl.winRootTrans, "WndContainer/MainPanel/FamilyInfoSV/UIGrid", tip, false);
	--// 循环控件
	winCtrl.wrapContent = C(UIWrapContent, winCtrl.winRootTrans, "WndContainer/MainPanel/FamilyInfoSV/UIWrapCont", tip, false);
	--// 页数信息显示
	winCtrl.pageLabel = C(UILabel, winCtrl.winRootTrans, "WndContainer/MainPanel/ConBar/PageBar/PageInfo", tip, false);

	--// 关闭按钮
	local com = C(UIButton, winCtrl.winRootTrans, "WndContainer/Title/CloseBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:CloseBtn();
	end;
	--//一键申请帮派
	com = C(UIButton, winCtrl.winRootTrans, "WndContainer/MainPanel/ConBar/QuickApplyBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickQuickApply();
	end;
	--// 创建帮派按钮
	com = C(UIButton, winCtrl.winRootTrans, "WndContainer/MainPanel/ConBar/CreateBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickCreateFamily();
	end;
	-- --// 上一页按钮
	-- com = C(UIButton, winCtrl.winRootTrans, "WndContainer/MainPanel/ConBar/PageBar/LastPage", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	-- 	self:ChangeLastPage();
	-- end;
	-- --// 下一页按钮
	-- com = C(UIButton, winCtrl.winRootTrans, "WndContainer/MainPanel/ConBar/PageBar/NextPage", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	-- 	self:ChangeNextPage();
	-- end;

	local func = UIWrapContent.OnInitializeItem(self.OnUpdateItem, self);
	winCtrl.wrapContent.onInitializeItem = func;

	UINewFamilyPanel:Init(winCtrl.newFamilyPanelObj);
	winCtrl.newFamilyPanelObj:SetActive(false);
	winCtrl.familyInfoMain:SetActive(false);

	--// 帮派信息条目列表
	winCtrl.familyInfoItems = {};
	--// 延迟重置倒数
	winCtrl.delayResetCount = 0;
	--// 当前列表页
	--winCtrl.curBriefPage = 0;
	--// 所有简介数量
	winCtrl.allBriefNum = 0;
	--// 最大页数
	--winCtrl.maxPage = 0;

	winCtrl.familyBriefs = nil;

	--// 自动申请加入帮派
	winCtrl.autoApplying = false;
	FamilyMgr.autoApplying = false;
	FamilyMgr.autoApplyShowTip = false;
	--// 所有帮派数量
	winCtrl.fBNum = 0;
	--// 当前申请索引
	winCtrl.curApplyIndex = 0;
	--// 等待计算帧数
	winCtrl.applyFrameCount = 0;


	EventMgr.Add("NewFamilyBrief", function (familyBriefs, briefNum) self:RenewShowList(familyBriefs, briefNum); end);
	EventMgr.Add("NewFamilyMemberData", function () self:JoinFamilyNotice(); end);
	--EventMgr.Add("RespFamilyApply", function () self:JoinFamilyNotice(); end);

	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UIFamilyListWnd:OpenCustom()
	--print("UIFamilyListWnd open !!! ");

	winCtrl.mOpen = true;
	
	--winCtrl.curBriefPage = 1;
	--winCtrl.maxPage = 1;
	self:CallShowList();

	if FamilyMgr:JoinFamily() == false --[[and User.MapData.Level >= CREATE_FAMILY_LV]] then
		winCtrl.createBtnObj:SetActive(true);
	else
		winCtrl.createBtnObj:SetActive(false);
	end

	UINewFamilyPanel:Close();
end

function UIFamilyListWnd:OpenTabByIdx(t1, t2, t3, t4)
	if FamilyMgr:JoinFamily() == true then
		self:Close();
		UIMgr.Open("UIFamilyMainWnd");
		return;
	end
end

function UIFamilyListWnd:CloseBtn()
	self:Close()
	JumpMgr.eOpenJump()
end

--// 关闭窗口
function UIFamilyListWnd:CloseCustom()
  	--print("UIFamilyListWnd close !!! ");

	winCtrl.autoApplying = false;
	FamilyMgr.autoApplying = false;
	winCtrl.mOpen = false;
end

--// 更新
function UIFamilyListWnd:Update()
	if winCtrl.delayResetCount > 0 then
		winCtrl.delayResetCount = winCtrl.delayResetCount - 1;
		if winCtrl.delayResetCount <= 0 then
			winCtrl.delayResetCount = 0;
			winCtrl.infoScrollView:ResetPosition();
		end
	end

	if winCtrl.autoApplying == true then
		if FamilyMgr:JoinFamily() == true or winCtrl.curApplyIndex > winCtrl.fBNum then
			winCtrl.autoApplying = false;
			FamilyMgr.autoApplying = false;
			FamilyMgr.autoApplyShowTip = false;
			return;
		end

		winCtrl.applyFrameCount = winCtrl.applyFrameCount - 1;
		if winCtrl.applyFrameCount <= 0 then
			FamilyMgr:ReqFamilyApplyByIndex(winCtrl.curApplyIndex);
			winCtrl.curApplyIndex = winCtrl.curApplyIndex + 1;
			winCtrl.applyFrameCount = 2;
		end
	end

	UINewFamilyPanel:Update();
end

--// 销毁释放窗口
function UIFamilyListWnd:DisposeCustom()
	UINewFamilyPanel:Dispose();

	for i = 1, #winCtrl.familyInfoItems do
		ObjPool.Add(winCtrl.familyInfoItems[i]);
	end
	winCtrl.familyInfoItems ={};

	winCtrl.init = false;
end

--// 点击一键申请按钮
function UIFamilyListWnd:ClickQuickApply()
	winCtrl.autoApplying = true;
	FamilyMgr.autoApplying = true;
	FamilyMgr.autoApplyShowTip = false;
	winCtrl.fBNum = FamilyMgr:GetFamilyNum();
	winCtrl.curApplyIndex = 1;
	winCtrl.applyFrameCount = 0;
end

--// 点击创建道庭
function UIFamilyListWnd:ClickCreateFamily()
	--iLog("LY", "Click Create Family !!! ");
	-- if User.MapData.Level < CREATE_FAMILY_LV then
	-- 	MsgBox.ShowYes("等级未达到"..CREATE_FAMILY_LV.."级。");
	-- 	return;
	-- end

	UINewFamilyPanel:Open();
end

--// 加入帮派通知
function UIFamilyListWnd:JoinFamilyNotice()
	if winCtrl.mOpen == false then
		return;
	end

	self:Close();
	--UIMgr.Open(UIFamilyMainWnd.Name);
end

--// 转换上一页
-- function UIFamilyListWnd:ChangeLastPage()
-- 	if winCtrl.curBriefPage <= 1 then
-- 		return;
-- 	end

-- 	winCtrl.curBriefPage = winCtrl.curBriefPage - 1;
-- 	self:CallShowList();
-- end

--// 转换下一页
-- function UIFamilyListWnd:ChangeNextPage()
-- 	if winCtrl.curBriefPage >= winCtrl.maxPage then
-- 		return;
-- 	end

-- 	winCtrl.curBriefPage = winCtrl.curBriefPage + 1;
-- 	self:CallShowList();
-- end

--// 更新当前显示列表
function UIFamilyListWnd:CallShowList()
	-- local fromInd = (winCtrl.curBriefPage - 1) * MAXITEMNUM + 1;
	-- local toInd = winCtrl.curBriefPage * MAXITEMNUM;

	local fromInd = 1;
	local toInd = 999;

	FamilyMgr:ReqFamilyBrief(fromInd, toInd);

	-- self:RenewPageShow();
end

function UIFamilyListWnd:OnUpdateItem(gObj, index, realIndex)
	--print("---------------------------------------------------     "..index);
	--print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     "..realIndex);

	if winCtrl.familyBriefs ~= nil then
		local rIndex = -realIndex + 1;
		winCtrl.familyInfoItems[index + 1]:ResetData(winCtrl.familyBriefs[rIndex]);
	end
end

--// 更新当前显示列表
function UIFamilyListWnd:RenewShowList(familyBriefs, allNum)
	if winCtrl.mOpen == false then
		return;
	end

	if familyBriefs == nil or #familyBriefs <= 0 or allNum == nil then
		self:RenewFamilyItemNum(0);
		winCtrl.allBriefNum = 0;
		--winCtrl.maxPage = 1;
		-- self:RenewPageShow();
		winCtrl.familyBriefs = nil;
		return;
	end

	winCtrl.familyBriefs = familyBriefs;
	winCtrl.allBriefNum = allNum;
	-- winCtrl.maxPage = math.ceil( winCtrl.allBriefNum / MAXITEMNUM );
	-- if winCtrl.allBriefNum <= 0 then
	-- 	winCtrl.maxPage = 1;
	-- end

	-- local itemNum = 0;
	-- if #familyBriefs > MAXITEMNUM then
	-- 	itemNum = MAXITEMNUM;
	-- else
	-- 	itemNum = #familyBriefs;
	-- end

	local itemNum = #familyBriefs;
	self:RenewFamilyItemNum(itemNum);
	if itemNum > MAXITEMNUM then
		itemNum = MAXITEMNUM;
	end
	for i = 1, itemNum do
		winCtrl.familyInfoItems[i]:ResetData(familyBriefs[i]);
	end

	-- self:RenewPageShow();
end

--// 刷新页数信息显示
-- function UIFamilyListWnd:RenewPageShow()
-- 	--local tFamilyNum = FamilyMgr:GetFamilyNum();
-- 	--local tTotalPage = math.ceil( winCtrl.allBriefNum / MAXITEMNUM );
-- 	-- if tFamilyNum == 0 then
-- 	-- 	tTotalPage = 1;
-- 	-- end

-- 	winCtrl.pageLabel.text = tostring(winCtrl.curBriefPage).."/"..winCtrl.maxPage;
-- end

--// 克隆帮派信息条目
function UIFamilyListWnd:CloneFamilyInfoItem()
	local cloneObj = GameObject.Instantiate(winCtrl.familyInfoMain);
	cloneObj.transform.parent = winCtrl.familyInfoMain.transform.parent;
	cloneObj.transform.localPosition = winCtrl.familyInfoMain.transform.localPosition;
	cloneObj.transform.localRotation = winCtrl.familyInfoMain.transform.localRotation;
	cloneObj.transform.localScale = winCtrl.familyInfoMain.transform.localScale;
	cloneObj:SetActive(true);

	--local cloneItem = UIFamilyInfoItem:New();
	local cloneItem = ObjPool.Get(UIFamilyInfoItem);
	cloneItem:Init(cloneObj);
	-- cloneObj.name = string.gsub(cloneObj.name, "99", tostring(#winCtrl.familyInfoItems + 1));
	-- winCtrl.familyInfoItems[#winCtrl.familyInfoItems + 1] = cloneItem;

	local newName = "";
	if #winCtrl.familyInfoItems + 1 >= 100 then
		newName = string.gsub(winCtrl.familyInfoMain.name, "99", tostring(#winCtrl.familyInfoItems + 1));
	elseif #winCtrl.familyInfoItems + 1 >= 10 then
		newName = string.gsub(winCtrl.familyInfoMain.name, "99", "0"..tostring(#winCtrl.familyInfoItems + 1));
	else
		newName = string.gsub(winCtrl.familyInfoMain.name, "99", "00"..tostring(#winCtrl.familyInfoItems + 1));
	end
	cloneObj.name = newName;
	winCtrl.familyInfoItems[#winCtrl.familyInfoItems + 1] = cloneItem;

	return cloneItem;
end

--// 重置帮派信息条目数量
function UIFamilyListWnd:RenewFamilyItemNum(number)
	for a = 1, #winCtrl.familyInfoItems do
		winCtrl.familyInfoItems[a]:Show(false)
	end

	-- winCtrl.wrapContent.minIndex = 0;
	-- winCtrl.wrapContent.maxIndex = number - 1;

	
	if number < MAXITEMNUM then
		winCtrl.wrapContent.minIndex = 0;
		winCtrl.wrapContent.maxIndex = 7;
	else
		winCtrl.wrapContent.minIndex = -number + 1;
		winCtrl.wrapContent.maxIndex = 0;
	end

	local realNum = number;
	if realNum < 0 then
		realNum = 0;
	elseif realNum > MAXITEMNUM then
		realNum = MAXITEMNUM;
	end

	if realNum <= #winCtrl.familyInfoItems then
		for a = 1, realNum do
			winCtrl.familyInfoItems[a]:Show(true);
		end
	else
		for a = 1, #winCtrl.familyInfoItems do
			winCtrl.familyInfoItems[a]:Show(true)
		end

		local needNum = realNum - #winCtrl.familyInfoItems;
		for a = 1, needNum do
			self:CloneFamilyInfoItem();
		end
	end

	for i = 1, #winCtrl.familyInfoItems do
		if i % 2 == 0 then
			winCtrl.familyInfoItems[i]:BgOn(false);
		else
			winCtrl.familyInfoItems[i]:BgOn(true);
		end
	end

	--winCtrl.infoGrid:Reposition();
	--winCtrl.wrapContent:SortBasedOnScrollMovement();
	winCtrl.wrapContent:SortAlphabetically();

	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIFamilyListWnd:DelayResetSVPosition()
	winCtrl.delayResetCount = 2;
end

return UIFamilyListWnd
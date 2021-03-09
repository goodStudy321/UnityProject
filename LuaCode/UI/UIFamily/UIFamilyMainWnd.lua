--// 帮派主界面
require("UI/UIFamily/UIBtnItem")
require("UI/UIFamily/UIFamilyMainPanel")
require("UI/UIFamily/UIFamilyMemberPanel")
require("UI/UIFamily/UIFamilyEventPanel")
require("UI/UIFamily/UIFamilyMenuPanel")

UIFamilyMainWnd = UIBase:New{Name = "UIFamilyMainWnd"};

local winCtrl = {};

local iLog = iTrace.Log;
local iError = iTrace.Error;

local PageType = {};
PageType.NONE 			= 0;
PageType.MAINPAGE		= 1;
PageType.MEMBERPAGE		= 2;
PageType.EVENTPAGE		= 3;
--PageType.RANKPAGE		= 4;
--PageType.DEPOTPAGE		= 5;
--// 初始化界面
--// 链接所有操作物体
function UIFamilyMainWnd:InitCustom()
	if winCtrl.init ~= nil and winCtrl.init == true then
		return;
	end
	winCtrl.init = false;

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;

	winCtrl.redOpenCount = {};
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;
	local TF = TransTool.Find;

	local tip = "UI主面板"
	--------- 获取GO ---------

	--// 主面板物体
	winCtrl.mainPanObj = T(winCtrl.winRootTrans, "WndContainer/DetailCont/MainPagePanel");
	--// 成员面板物体
	winCtrl.memberPanObj = T(winCtrl.winRootTrans, "WndContainer/DetailCont/MemberPanel");
	--// 活动面板物体
	winCtrl.eventPanObj = T(winCtrl.winRootTrans, "WndContainer/DetailCont/EventPanel");
	--// 排名面板物体


	--// 仓库面板物体
	--winCtrl.depotPanObj = T(winCtrl.winRootTrans, "WndContainer/DetailCont/DepotPanel");


	--// 弹出菜单物体
	winCtrl.menuPanelObj = T(winCtrl.winRootTrans, "WndContainer/PopMenuPanel");
	--// 关闭按钮物体
	winCtrl.closeBtnObj = T(winCtrl.winRootTrans, "WndContainer/TagList/CloseBtn");


	winCtrl.tagBtnObjs = {};
	winCtrl.tagBtnObjs[#winCtrl.tagBtnObjs + 1] = T(winCtrl.winRootTrans, "WndContainer/TagList/MainPage");
	winCtrl.tagBtnObjs[#winCtrl.tagBtnObjs + 1] = T(winCtrl.winRootTrans, "WndContainer/TagList/MemberPage");
	winCtrl.tagBtnObjs[#winCtrl.tagBtnObjs + 1] = T(winCtrl.winRootTrans, "WndContainer/TagList/EventPage");
	--winCtrl.tagBtnObjs[#winCtrl.tagBtnObjs + 1] = T(winCtrl.winRootTrans, "WndContainer/TagList/RankPage");
	--winCtrl.tagBtnObjs[#winCtrl.tagBtnObjs + 1] = T(winCtrl.winRootTrans, "WndContainer/TagList/DepotPage");

	winCtrl.redBtnObjs = {};
	winCtrl.redBtnObjs[#winCtrl.redBtnObjs + 1] = T(winCtrl.winRootTrans, "WndContainer/TagList/MainPage/Red");
	winCtrl.redBtnObjs[#winCtrl.redBtnObjs + 1] = T(winCtrl.winRootTrans, "WndContainer/TagList/MemberPage/Red");
	winCtrl.redBtnObjs[#winCtrl.redBtnObjs + 1] = T(winCtrl.winRootTrans, "WndContainer/TagList/EventPage/Red");

	for i = 1, #winCtrl.redBtnObjs do
		winCtrl.redBtnObjs[i]:SetActive(false);
	end

	--------- 获取控件 ---------

	--// 关闭按钮
	UITool.SetBtnSelf(winCtrl.closeBtnObj, self.CloseBtn, self, self.Name);
	

	winCtrl.tagBtns = {};
	--local btnItem = UIBtnItem:New();
	local btnItem = ObjPool.Get(UIBtnItem);
	btnItem:Init(winCtrl.tagBtnObjs[1], function () self:ChangePanel(PageType.MAINPAGE) end);
	winCtrl.tagBtns[#winCtrl.tagBtns + 1] = btnItem;
	btnItem = ObjPool.Get(UIBtnItem);
	btnItem:Init(winCtrl.tagBtnObjs[2], function () self:ChangePanel(PageType.MEMBERPAGE) end);
	winCtrl.tagBtns[#winCtrl.tagBtns + 1] = btnItem;
	btnItem = ObjPool.Get(UIBtnItem);
	btnItem:Init(winCtrl.tagBtnObjs[3], function () self:ChangePanel(PageType.EVENTPAGE) end);
	winCtrl.tagBtns[#winCtrl.tagBtns + 1] = btnItem;
	-- winCtrl.tagBtns[#winCtrl.tagBtns + 1] = btnItem;
	-- btnItem = ObjPool.Get(UIBtnItem);
	-- btnItem:Init(winCtrl.tagBtnObjs[3], function () self:ChangePanel(PageType.RANKPAGE) end);
	-- winCtrl.tagBtns[#winCtrl.tagBtns + 1] = btnItem;
	-- btnItem = ObjPool.Get(UIBtnItem);
	-- btnItem:Init(winCtrl.tagBtnObjs[5], function () self:ChangePanel(PageType.DEPOTPAGE) end);
	-- winCtrl.tagBtns[#winCtrl.tagBtns + 1] = btnItem;

	FamilyMgr.eRed["Add"](FamilyMgr.eRed, self.NewMsg, self);

	--// 初始化道庭主面板
	UIFamilyMainPanel:Init(winCtrl.mainPanObj);
	--// 初始化道庭成员面板
	UIFamilyMemberPanel:Init(winCtrl.memberPanObj);
	--// 初始化道庭活动面板
	UIFamilyEventPanel:Init(winCtrl.eventPanObj);

	--// 初始化弹出菜单
	UIFamilyMenuPanel:Init(winCtrl.menuPanelObj);


	EventMgr.Add("NewFamilyMemberData", function ()
		UIFamilyMenuPanel:Close();
		self:LeaveFamily();
	end);


	--// 窗口是否打开
	winCtrl.mOpen = false;
	--// 当前打开面板
	winCtrl.curPage = PageType.NONE;
	--// 当前打开面板
	winCtrl.curPanel = nil;

	winCtrl.init = true;
end

--// 打开窗口
function UIFamilyMainWnd:OpenCustom()
	--print("UIFamilyMainWnd open !!! ");

	local familyData = FamilyMgr:GetFamilyData();
	local memberData = FamilyMgr:GetCurMemberData();
	if familyData == nil or memberData == nil then
		self:Close();
		return;
	end

	winCtrl.mOpen = true;

	self:ChangePanel(PageType.MAINPAGE);

	local hasReward = FamilyMgr:IsGetReward() == false;
	self:NewMsg(hasReward, 1, 0);

	if FamilyMgr:CanDealWithMember() == true then
		local hasApplyMember = FamilyMgr:GetFamilyApplyNum() > 0;
		self:NewMsg(hasApplyMember, 2, 0);
	end

	local hasRedPacket = FamilyMgr:HasRedPacket();
	local hasSkill = FamilyMgr:IsAnySkillCanUpdate();
	if hasRedPacket == true then
		self:NewMsg(true, 3, 2);
	else
		self:NewMsg(false, 3, 2);
	end

	if hasSkill == true then
		self:NewMsg(true, 3, 1);
	else
		self:NewMsg(false, 3, 1);
	end

	local isShow = FamilyBossMgr:IsShowAction()--道庭Boss
	self:NewMsg(isShow, 3, 3);

	local mState = FamilyMissionMgr:IsShowAction()--道庭任务
	self:NewMsg(mState, 1, 2);

	self:NewMsg(FamilyEscortMgr:IsOpen(), 1, 3);

	--self:NewMsg(FamilyMgr:RedTempDropCheck(), 3, 6);

	local idFmlDftOpen = FamilyActivityMgr.FmlDftState;
	self:NewMsg(idFmlDftOpen, 3, 5);

	if FamilyMgr:GetNewBoxNumber() > 0 then
		self:NewMsg(true, 1, 4);
		-- self:NewMsg(true, 3, 1);
	else
		self:NewMsg(false, 1, 4);
		-- self:NewMsg(false, 3, 1);
	end
end

--// 关闭窗口
function UIFamilyMainWnd:CloseCustom()
	winCtrl.redOpenCount = {};

	UIFamilyMainPanel:Close();
	UIFamilyMemberPanel:Close();
	UIFamilyMenuPanel:Close();

	FamilyMgr.eUpdateRedPack();
	
  	winCtrl.mOpen = false;
end

--// 更新
function UIFamilyMainWnd:Update()
	UIFamilyMemberPanel:Update();
end

--// 销毁释放窗口
function UIFamilyMainWnd:DisposeCustom()
	FamilyMgr.eRed["Remove"](FamilyMgr.eRed, self.NewMsg, self);

	UIFamilyMainPanel:Dispose();
	UIFamilyMemberPanel:Dispose();
	UIFamilyEventPanel:Dispose();
	UIFamilyMenuPanel:Dispose();

	for i = 1, #winCtrl.tagBtns do
		ObjPool.Add(winCtrl.tagBtns[i]);
	end
	winCtrl.tagBtns = {};

	winCtrl.init = false;
end

function UIFamilyMainWnd:CloseBtn()
	self:Close()
	JumpMgr.eOpenJump()
end

function UIFamilyMainWnd:OpenTabByIdx(t1, t2, t3, t4)
	-- if FamilyMgr:JoinFamily() == false then
	-- 	self:Close();
	-- 	UIMgr.Open("UIFamilyListWnd");
	-- 	return;
	-- end
end

--// 转换操作面板
function UIFamilyMainWnd:ChangePanel(tagType)

	if tagType == PageType.MAINPAGE then
		winCtrl.tagBtns[1]:SetSelect(true);
		winCtrl.tagBtns[2]:SetSelect(false);
		winCtrl.tagBtns[3]:SetSelect(false);
		-- winCtrl.tagBtns[4]:SetSelect(false);
		-- winCtrl.tagBtns[5]:SetSelect(false);

		UIFamilyMemberPanel:Close();
		UIFamilyEventPanel:Close();

		UIFamilyMainPanel:Open();
	elseif tagType == PageType.MEMBERPAGE then
		winCtrl.tagBtns[1]:SetSelect(false);
		winCtrl.tagBtns[2]:SetSelect(true);
		winCtrl.tagBtns[3]:SetSelect(false);
		-- winCtrl.tagBtns[4]:SetSelect(false);
		-- winCtrl.tagBtns[5]:SetSelect(false);

		UIFamilyMainPanel:Close();
		UIFamilyEventPanel:Close();
		UIFamilyMemberPanel:Open();
	elseif tagType == PageType.EVENTPAGE then
		winCtrl.tagBtns[1]:SetSelect(false);
		winCtrl.tagBtns[2]:SetSelect(false);
		winCtrl.tagBtns[3]:SetSelect(true);
		-- winCtrl.tagBtns[4]:SetSelect(false);
		-- winCtrl.tagBtns[5]:SetSelect(false);

		UIFamilyMainPanel:Close();
		UIFamilyMemberPanel:Close();
		UIFamilyEventPanel:Open();
	end

	winCtrl.curPage = tagType;
end

--// 检测退出帮派
function UIFamilyMainWnd:LeaveFamily()
	if winCtrl.mOpen == false then
		return;
	end

	if FamilyMgr:JoinFamily() == false then
		self:Close();
		--UIMgr.Open(UIFamilyListWnd.Name);
	end
end

--// 有新状态到达
function UIFamilyMainWnd:NewMsg(state, tapIndex, subIndex)
	if winCtrl.init == nil or winCtrl.init == false or winCtrl.mOpen == false then
		return;
	end

	if winCtrl.redOpenCount == nil then
		winCtrl.redOpenCount = {};
	end
	if winCtrl.redOpenCount[tapIndex] == nil then
		winCtrl.redOpenCount[tapIndex] = {};
	end

	local tapTbl = winCtrl.redOpenCount[tapIndex];
	if state == true then
		local isNew = true;
		for i = 1, #tapTbl do
			local countData = tapTbl[i];
			if countData.index == subIndex then
				countData.count = 1;
				isNew = false;
				break;
			end
		end

		if isNew == true then
			local countData = {};
			countData.index = subIndex;
			countData.count = 1;
			tapTbl[#tapTbl + 1] = countData;
		end

		--winCtrl.redOpenCount[tapIndex] = winCtrl.redOpenCount[tapIndex] + 1;
	else
		for i = 1, #tapTbl do
			local countData = tapTbl[i]
			if countData.index == subIndex then
				countData.count = 0;
				break;
			end
		end

		-- winCtrl.redOpenCount[tapIndex] = winCtrl.redOpenCount[tapIndex] - 1;
		-- if winCtrl.redOpenCount[tapIndex] < 0 then
		-- 	winCtrl.redOpenCount[tapIndex] = 0;
		-- end
	end

	local hasNew = false;
	for i = 1, #tapTbl do
		local countData = tapTbl[i]
		if countData.count > 0 then
			hasNew = true
		end
	end

	if hasNew == true then
		winCtrl.redBtnObjs[tapIndex]:SetActive(true);
	else
		winCtrl.redBtnObjs[tapIndex]:SetActive(false);
	end

	-- if winCtrl.redOpenCount[tapIndex] > 0 then
	-- 	winCtrl.redBtnObjs[tapIndex]:SetActive(true);
	-- else
	-- 	winCtrl.redBtnObjs[tapIndex]:SetActive(false);
	-- end
end

return UIFamilyMainWnd
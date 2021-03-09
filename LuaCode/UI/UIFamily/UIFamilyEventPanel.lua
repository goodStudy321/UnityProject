--// 道庭活动子面板
require("UI/UIFamily/UIFGameBtnItem");

UIFamilyEventPanel = Super:New{Name = "UIFamilyEventPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 原始按钮索引
--// 1：道庭仓库
--// 2：道庭战
--// 3：道庭宴会
--// 4：道庭BOSS
--// 5：守卫道庭
--// 6：道庭技能
--// 7：道庭红包

--// 新按钮索引
--// 1：道庭技能
--// 2：道庭红包
--// 3：道庭神兽
--// 4：道庭战
--// 5：守卫道庭
--// 6：道庭晚宴


--// 初始化面板
function UIFamilyEventPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyEventPanel create !!! ");

	local tip = "UI道庭活动子面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 按钮物体列表
	panelCtrl.btnObjs = {};
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance1");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance2");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance3");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance4");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance5");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance6");

	--// 红点物体
	panelCtrl.redBtnObjs = {};
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance1/RedBtn");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance2/RedBtn");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance3/RedBtn");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance4/RedBtn");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance5/RedBtn");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "GameEntrance6/RedBtn");

	--// 按钮控件列表
	panelCtrl.gameBtns = {};
	for i = 1, #panelCtrl.btnObjs do
		local cloneBtn = ObjPool.Get(UIFGameBtnItem);
		cloneBtn:Init(panelCtrl.btnObjs[i]);
		panelCtrl.gameBtns[#panelCtrl.gameBtns + 1] = cloneBtn;
	end

	panelCtrl.gameBtns[1]:SetClickCB(function() self:ClickFSkill() end);
	panelCtrl.gameBtns[2]:SetClickCB(function() self:ClickFRedPacket() end);
	panelCtrl.gameBtns[3]:SetClickCB(function() self:ClickFBoss() end);
	panelCtrl.gameBtns[4]:SetClickCB(function() self:ClickFWar() end);
	panelCtrl.gameBtns[5]:SetClickCB(function() self:ClickFDefend() end);
	panelCtrl.gameBtns[6]:SetClickCB(function() self:ClickFDinner() end);

	FamilyMgr.eRed["Add"](FamilyMgr.eRed, self.NewMsg, self);

	panelCtrl.open = false;
	panelCtrl.init = true;
end

--// 打开面板
function UIFamilyEventPanel:Open()
	panelCtrl.open = true;
	panelCtrl.panelObj:SetActive(true);

	local hasRedPacket = FamilyMgr:HasRedPacket();
	self:NewMsg(hasRedPacket, 3, 2);

	local hasSkill = FamilyMgr:IsAnySkillCanUpdate();
	self:NewMsg(hasSkill, 3, 1);
	self:NewMsg(FamilyMgr:RedTempDropCheck( ), 3, 4);
	
	local isHave = CustomInfo:IsHaveItem(FamilyBossMgr.id)
	local isShow = FamilyBossMgr:IsShowAction()
	local state = isHave or isShow
	self:NewMsg(state, 3, 3);

	local idFmlDftOpen = FamilyActivityMgr.FmlDftState;
	self:NewMsg(idFmlDftOpen, 3, 5);
end

--// 关闭面板
function UIFamilyEventPanel:Close()
	panelCtrl.panelObj:SetActive(false);
	panelCtrl.open = false;
end

--// 销毁释放面板
function UIFamilyEventPanel:Dispose()
	FamilyMgr.eRed["Remove"](FamilyMgr.eRed, self.NewMsg, self);

	for i = 1, #panelCtrl.gameBtns do
		ObjPool.Add(panelCtrl.gameBtns[i]);
	end
	panelCtrl.gameBtns ={};

	panelCtrl.init = false;
end

--// 点击道庭战
function UIFamilyEventPanel:ClickFWar()
	UIMgr.Open(UIFamilyWar.Name)
end

--// 点击道庭宴会
function UIFamilyEventPanel:ClickFDinner()
	UIMgr.Open(UIFamilyAnswerIt.Name)
end

--// 点击道庭Boss
function UIFamilyEventPanel:ClickFBoss()
	UIMgr.Open(UIFamilyBossIt.Name)
end

--// 点击道庭守卫
function UIFamilyEventPanel:ClickFDefend()
	UIMgr.Open(UIFamilyDefendWnd.Name);
end

--// 点击道庭技能
function UIFamilyEventPanel:ClickFSkill()
	UIMgr.Open(UIFamilySkillWnd.Name);
end

--// 点击道庭红包
function UIFamilyEventPanel:ClickFRedPacket()
	UIMgr.Open(UIFamilyRedPWnd.Name);
end

--// 有新状态到达
function UIFamilyEventPanel:NewMsg(state, tapIndex, subIndex)
	if panelCtrl.open == nil or panelCtrl.open == false or tapIndex ~= 3 then
		return;
	end

	if subIndex == nil or subIndex < 1 or subIndex > 7 then
		iError("LY", "SubIndex error !!!");
		return;
	end

	panelCtrl.redBtnObjs[subIndex]:SetActive(state);
end
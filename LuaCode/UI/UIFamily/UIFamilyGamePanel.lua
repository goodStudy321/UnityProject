--// 道庭活动子面板
require("UI/UIFamily/UIFGameBtnItem");

UIFamilyGamePanel = Super:New{Name = "UIFamilyGamePanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 初始化面板
function UIFamilyGamePanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyGamePanel create !!! ");

	local tip = "UI道庭活动子面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 按钮物体列表
	panelCtrl.btnObjs = {};
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameBtn1");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameBtn2");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameBtn3");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameBtn4");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameBtn5");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameBtn6");
	panelCtrl.btnObjs[#panelCtrl.btnObjs + 1] = T(panelCtrl.rootTrans, "GameBtn7");

	--// 按钮控件列表
	panelCtrl.gameBtns = {};
	for i = 1, #panelCtrl.btnObjs do
		local cloneBtn = ObjPool.Get(UIFGameBtnItem);
		cloneBtn:Init(panelCtrl.btnObjs[i]);
		panelCtrl.gameBtns[#panelCtrl.gameBtns + 1] = cloneBtn;
	end

	panelCtrl.gameBtns[1]:SetClickCB(function() self:ClickFDepot() end);
	panelCtrl.gameBtns[2]:SetClickCB(function() self:ClickFWar() end);
	panelCtrl.gameBtns[3]:SetClickCB(function() self:ClickFDinner() end);
	panelCtrl.gameBtns[4]:SetClickCB(function() self:ClickFBoss() end);
	panelCtrl.gameBtns[5]:SetClickCB(function() self:ClickFDefend() end);
	panelCtrl.gameBtns[6]:SetClickCB(function() self:ClickFSkill() end);
	panelCtrl.gameBtns[7]:SetClickCB(function() self:ClickFRedPacket() end);

	panelCtrl.init = true;
end

--// 销毁释放面板
function UIFamilyGamePanel:Dispose()
	for i = 1, #panelCtrl.gameBtns do
		ObjPool.Add(panelCtrl.gameBtns[i]);
	end
	panelCtrl.gameBtns ={};
end

--// 点击仓库
function UIFamilyGamePanel:ClickFDepot()
	UIMgr.Open(UIFamilyDepotWnd.Name);
end

--// 点击道庭战
function UIFamilyGamePanel:ClickFWar()
	UIMgr.Open(UIFamilyWar.Name)
end

--// 点击道庭宴会
function UIFamilyGamePanel:ClickFDinner()
	UIMgr.Open(UIFamilyAnswerIt.Name)
end

--// 点击道庭Boss
function UIFamilyGamePanel:ClickFBoss()
	UIMgr.Open(UIFamilyBossIt.Name)
end

--// 点击道庭守卫
function UIFamilyGamePanel:ClickFDefend()
	UIMgr.Open(UIFamilyDefendWnd.Name);
end

--// 点击道庭技能
function UIFamilyGamePanel:ClickFSkill()
	UIMgr.Open(UIFamilySkillWnd.Name);
end

--// 点击道庭红包
function UIFamilyGamePanel:ClickFRedPacket()
	UIMgr.Open(UIFamilyRedPWnd.Name);
end
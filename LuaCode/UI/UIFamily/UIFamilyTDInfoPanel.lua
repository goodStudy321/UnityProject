--// 道庭守卫信息面板
--require("UI/UIFamily/UIFItemCell");

UIFamilyTDInfoPanel = Super:New{Name = "UIFamilyTDInfoPanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIFamilyTDInfoPanel:Init(panelObject)

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

	--// 
	--panelCtrl.cellMain = T(panelCtrl.rootTrans, "ListCont/ItemsSV/GridObj/ItemCell_99");

	--------- 获取控件 ---------

	local tip = "UI道庭守卫信息面板"
	--// 进度（波数）
	panelCtrl.waveInfo = C(UILabel, panelCtrl.rootTrans, "Cont1/Item1/Label1", tip, false);
	--// 打怪数量
	panelCtrl.killNum = C(UILabel, panelCtrl.rootTrans, "Cont1/Item2/Label1", tip, false);
	--// 经验
	panelCtrl.expNum = C(UILabel, panelCtrl.rootTrans, "Cont1/Item3/Label1", tip, false);
	--// 目标描述
	panelCtrl.targetL = C(UILabel, panelCtrl.rootTrans, "Cont2/Label1", tip, false);

	--// 捐献按钮
	-- local com = C(UIButton, panelCtrl.rootTrans, "ListCont/DonateBtn", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickDonateBtn(); end;


	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("NewFTDInfo", panelCtrl.OnNewData);


	--// 目标描述文字
	panelCtrl.targetText = "[E9AC50FF]副本目标：[-][B1A495FF]守护道庭神像击退来犯敌人，更多盟友协助可轻松通关。[-]";

	panelCtrl.init = true;
	panelCtrl.isOpen = false;
end

--// 打开
function UIFamilyTDInfoPanel:Open()
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.isOpen = true;

	self:ShowData();
end

--// 更新
function UIFamilyTDInfoPanel:Update()

end

--// 关闭
function UIFamilyTDInfoPanel:Close()
	panelCtrl.panelObj:SetActive(false);
	panelCtrl.isOpen = false;
end

--// 销毁释放窗口
function UIFamilyTDInfoPanel:Dispose()
	EventMgr.Remove("NewFTDInfo", panelCtrl.OnNewData);
	panelCtrl.init = false;
end

--// 刷新成员列表数据
function UIFamilyTDInfoPanel:ShowData()
	if panelCtrl.isOpen == false then
		return;
	end

	self:ShowWave();
	self:ShowKillNum();
	self:ShowExp();
	self:ShowTargetInfo();
end

--// 显示波数
function UIFamilyTDInfoPanel:ShowWave()
	local totalW = FamilyActivityMgr:GetTotalWave();
	local curW = FamilyActivityMgr:GetCurWave();

	panelCtrl.waveInfo.text = string.format("%d/%d (波)", curW, totalW);
end

--// 显示打怪数量
function UIFamilyTDInfoPanel:ShowKillNum()
	local killNum = FamilyActivityMgr:GetKillNum();

	panelCtrl.killNum.text = tostring(killNum);
end

--// 显示当前经验
function UIFamilyTDInfoPanel:ShowExp()
	local expNum = FamilyActivityMgr:GetExp();

	panelCtrl.expNum.text = math.NumToStr(expNum);
end

--// 显示副本目标
function UIFamilyTDInfoPanel:ShowTargetInfo()
	panelCtrl.targetL.text = panelCtrl.targetText;
end
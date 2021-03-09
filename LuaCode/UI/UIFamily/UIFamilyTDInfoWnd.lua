--// 道庭守卫信息主界面
require("UI/UIFamily/UIFamilyTDInfoPanel");
require("UI/UIFamily/UIFamilyTDRankPanel");

UIFamilyTDInfoWnd = UIBase:New{Name = "UIFamilyTDInfoWnd"};

local winCtrl = {};

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化界面
--// 链接所有操作物体
function UIFamilyTDInfoWnd:InitCustom()

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	if ScreenMgr.orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "WndCont", self.root.name, true)
	end
	--------- 获取GO ---------

	--// 守卫按钮物体
	winCtrl.tdInfoBtnObj = T(winCtrl.winRootTrans, "WndCont/BtnCont/Btn1");
	--// 排行按钮物体
	winCtrl.rankBtnObj = T(winCtrl.winRootTrans, "WndCont/BtnCont/Btn2");
	--// 守卫信息面板物体
	winCtrl.panel1Obj = T(winCtrl.winRootTrans, "WndCont/InfoCont/Panel1");
	--// 排行面板物体
	winCtrl.panel2Obj = T(winCtrl.winRootTrans, "WndCont/InfoCont/Panel2");


	--------- 获取控件 ---------

	local tip = "UI道庭守卫信息主界面"

	winCtrl.sneakWarmL = C(UILabel, winCtrl.winRootTrans, "WndCont/WarmCont/Label2", tip, false);


	--// 打开捐献装备按钮
	-- local com = C(UIButton, winCtrl.winRootTrans, "Bg/BackBtn", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject) self:Close(); end;

	winCtrl.tdInfoBtn = ObjPool.Get(UIBtnItem);
	winCtrl.tdInfoBtn:Init(winCtrl.tdInfoBtnObj, function() self:SwitchPanel(1) end);

	winCtrl.rankBtn = ObjPool.Get(UIBtnItem);
	winCtrl.rankBtn:Init(winCtrl.rankBtnObj, function() self:SwitchPanel(2) end);


	UIFamilyTDInfoPanel:Init(winCtrl.panel1Obj);
	UIFamilyTDRankPanel:Init(winCtrl.panel2Obj);

	winCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("NewFTDAssaultTime", winCtrl.OnNewData);
	EventMgr.Add("NewFTDInfo", winCtrl.OnNewData);
	ScreenMgr.eChange:Add(self.ScrChg,self);

	--// 当前打开面板类型
	--// 1：守卫信息
	--// 2: 伤害排行
	winCtrl.panelType = 0;

	winCtrl.assaultTime = 0;
	winCtrl.lastNT = 0;

	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--屏幕发生旋转
function UIFamilyTDInfoWnd:ScrChg(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "WndCont", nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "WndCont", nil, true, true)
	end
end

--// 打开窗口
function UIFamilyTDInfoWnd:OpenCustom()
	winCtrl.mOpen = true;
	winCtrl.panelType = 0;
	winCtrl.assaultTime = 0;
	winCtrl.lastNT = 0;

	self:SwitchPanel(1);
	self:ShowData();
end

--// 关闭窗口
function UIFamilyTDInfoWnd:CloseCustom()
	winCtrl.panelType = 0;
  	winCtrl.mOpen = false;
end

--// 更新
function UIFamilyTDInfoWnd:Update()
	if winCtrl.mOpen == false then
		return;
	end

	if winCtrl.assaultTime > 0 then
		winCtrl.assaultTime = winCtrl.assaultTime - Time.deltaTime;
		if winCtrl.assaultTime< 0 then
			winCtrl.assaultTime = 0;
		end

		local y, yy = math.modf(winCtrl.assaultTime);
		if y ~= winCtrl.lastNT then
			self:ResetAssaultShow(y + 1);
		end
		winCtrl.lastNT = y;
	end

	UIFamilyTDInfoPanel:Update();
	UIFamilyTDRankPanel:Update();
end

--// 销毁释放窗口
function UIFamilyTDInfoWnd:DisposeCustom()
	EventMgr.Remove("NewFTDAssaultTime", winCtrl.OnNewData);
	EventMgr.Remove("NewFTDInfo", winCtrl.OnNewData);
	ScreenMgr.eChange:Remove(self.ScrChg,self);

	if winCtrl.tdInfoBtn ~= nil then
		ObjPool.Add(winCtrl.tdInfoBtn);
	end
	if winCtrl.rankBtn ~= nil then
		ObjPool.Add(winCtrl.rankBtn);
	end

	UIFamilyTDInfoPanel:Dispose();
	UIFamilyTDRankPanel:Dispose();
end

--// 转换面板
--// 1：守卫信息
--// 2: 伤害排行
function UIFamilyTDInfoWnd:SwitchPanel(panType)
	if winCtrl.panelType == panType then
		return;
	end

	if panType == 1 then
		self:SwitchPanel1();
	elseif panType == 2 then
		self:SwitchPanel2();
	end
end

--// 转换道庭守卫面板
function UIFamilyTDInfoWnd:SwitchPanel1()
	winCtrl.tdInfoBtn:SetSelect(true);
	winCtrl.rankBtn:SetSelect(false);

	UIFamilyTDInfoPanel:Open();
	UIFamilyTDRankPanel:Close();
end

--// 转换道庭守卫排行面板
function UIFamilyTDInfoWnd:SwitchPanel2()
	winCtrl.tdInfoBtn:SetSelect(false);
	winCtrl.rankBtn:SetSelect(true);

	UIFamilyTDInfoPanel:Close();
	UIFamilyTDRankPanel:Open();
end

--// 刷新成员列表数据
function UIFamilyTDInfoWnd:ShowData()
	if winCtrl.mOpen == false then
		return;
	end

	winCtrl.assaultTime = FamilyActivityMgr:GetAssaultTime();
	self:ResetAssaultShow(winCtrl.assaultTime);
end

--// 更新突袭时间显示
function UIFamilyTDInfoWnd:ResetAssaultShow(timeNum)
	if timeNum <= 0 then
		winCtrl.sneakWarmL.text = "刷新完毕";
		return;
	end

	local showText = string.format("[67CC67FF]%d秒[-]后怪物突袭道庭神像", timeNum);
	winCtrl.sneakWarmL.text = showText;
end

--持续显示 ，不受配置tOn == 1 影响
function UIFamilyTDInfoWnd:ConDisplay()
	do return true end
end

return UIFamilyTDInfoWnd
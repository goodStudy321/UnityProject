--// 帮派红包窗口
require("UI/UIFamily/UIFRedPRecordPanel");
require("UI/UIFamily/UIFRedPListPanel");
require("UI/UIFamily/UIFGiveRedPPanel");
require("UI/UIFamily/UIFRedPInfoPanel");


UIFamilyRedPWnd = UIBase:New{Name = "UIFamilyRedPWnd"};

local base = UIBase

local winCtrl = {};

local iLog = iTrace.Log;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;


--// 初始化界面
--// 链接所有操作物体
function UIFamilyRedPWnd:InitCustom()

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 记录面板物体
	winCtrl.recordPanelObj = T(winCtrl.winRootTrans, "WndCont/Bg/RecordCont");
	--// 红包物体面板
	winCtrl.redPacketPanelObj = T(winCtrl.winRootTrans, "WndCont/Bg/RedPCont");
	--// 发送红包面板
	winCtrl.giveRedPPanelObj = T(winCtrl.winRootTrans, "WndCont/Bg/GiveRedPPanel");
	--// 红包信息面板（领取红包）
	winCtrl.redPInfoPanelObj = T(winCtrl.winRootTrans, "WndCont/Bg/RedPInfoPanel");


	--------- 获取控件 ---------

	local tip = "UI道庭红包窗口"


	local com = C(UIButton, winCtrl.winRootTrans, "WndCont/Bg/Title/backBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:Close();
	end;

	com = C(UIButton, winCtrl.winRootTrans, "WndCont/Bg/V6Btn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:V6GiveRedPacket();
	end;


	UIFRedPRecordPanel:Init(winCtrl.recordPanelObj);
	UIFRedPListPanel:Init(winCtrl.redPacketPanelObj);
	UIFGiveRedPPanel:Init(winCtrl.giveRedPPanelObj);
	UIFRedPInfoPanel:Init(winCtrl.redPInfoPanelObj);

	winCtrl.closeEnt = EventHandler(self.Close, self);
	EventMgr.Add("QuitFamily", winCtrl.closeEnt);
	
	--// 
	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UIFamilyRedPWnd:OpenCustom()
	winCtrl.mOpen = true;
	FamilyMgr.lookAtRP = true;
	FamilyMgr.checkRP = true;

	UIFRedPRecordPanel:Open();
	UIFRedPListPanel:Open();
end

--// 关闭窗口
function UIFamilyRedPWnd:CloseCustom()
	winCtrl.mOpen = false;
	FamilyMgr.lookAtRP = false;
	FamilyMgr.checkRP = false;
	  
	UIFRedPRecordPanel:Close();
	UIFRedPListPanel:Close();

	UISystemView:UpdateRedPacket()
end

--// 更新
function UIFamilyRedPWnd:Update()
	UIFRedPRecordPanel:Update();
	UIFRedPListPanel:Update();
end

--// 销毁释放窗口
function UIFamilyRedPWnd:DisposeCustom()
	EventMgr.Remove("QuitFamily", winCtrl.closeEnt);
	
	winCtrl.mOpen = false;

	UIFRedPRecordPanel:Dispose();
	UIFRedPListPanel:Dispose();
	UIFGiveRedPPanel:Dispose();
	UIFRedPInfoPanel:Dispose();

	winCtrl.init = false;
end

--// 刷新成员列表数据
function UIFamilyRedPWnd:ShowData()
	
end

--// 打开发放红包面板
function UIFamilyRedPWnd:OpenGivePedPPanel()
	if winCtrl.mOpen == false then
		return;
	end

	UIFGiveRedPPanel:Open();
end

--// 打开红包信息面板
function UIFamilyRedPWnd:OpenRedPInfoPanel()
	if winCtrl.mOpen == false then
		return;
	end

	UIFRedPInfoPanel:Open();
end

--// Vip6发红包
function UIFamilyRedPWnd:V6GiveRedPacket()
	if VIPMgr.GetVIPLv() < 6 then
		MsgBox.ShowYes("未达到Vip6等级");
		return;
	end

	UIFamilyRedPWnd:OpenGivePedPPanel();
	UIFGiveRedPPanel:ShowData(nil, 0);
end

return UIFamilyRedPWnd
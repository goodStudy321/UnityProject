--// 道庭增值引导窗口
-- require("UI/UIFamily/UIFamilyInfoItem")

UIFamilyTipsWnd = UIBase:New{Name = "UIFamilyTipsWnd"}

local winCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;
local ET = EventMgr.Trigger;


--// 初始化界面
--// 链接所有操作物体
function UIFamilyTipsWnd:InitCustom()

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

	--// 引导克隆主体
	winCtrl.eventItemMain = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid/EventItem_99");
	--// 道庭资金标签物体
	winCtrl.tag1BtnObj = T(winCtrl.winRootTrans, "Bg/Tags/Tag1");
	--// 道绩标签物体
	winCtrl.tag2BtnObj = T(winCtrl.winRootTrans, "Bg/Tags/Tag2");
	--// 道庭资金标签选择物体
	winCtrl.tag1BtnSelObj = T(winCtrl.winRootTrans, "Bg/Tags/Tag1/SelSign");
	--// 道绩标签选择物体
	winCtrl.tag2BtnSelObj = T(winCtrl.winRootTrans, "Bg/Tags/Tag2/SelSign");

	winCtrl.grid1Obj = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid1");
	winCtrl.grid2Obj = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid2");


	winCtrl.tag1btnObj1 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid1/EventItem1/GoBtn");
	winCtrl.tag1btnObj2 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid1/EventItem2/GoBtn");
	winCtrl.tag1btnObj3 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid1/EventItem3/GoBtn");
	winCtrl.tag1btnObj4 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid1/EventItem4/GoBtn");
	winCtrl.tag1btnObj5 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid1/EventItem5/GoBtn");

	winCtrl.tag2btnObj1 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid2/EventItem1/GoBtn");
	winCtrl.tag2btnObj2 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid2/EventItem2/GoBtn");
	winCtrl.tag2btnObj4 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid2/EventItem4/GoBtn");
	winCtrl.tag2btnObj5 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid2/EventItem5/GoBtn");
	winCtrl.tag2btnObj6 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid2/EventItem6/GoBtn");
	winCtrl.tag2btnObj7 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid2/EventItem7/GoBtn");
	winCtrl.tag2btnObj8 = T(winCtrl.winRootTrans, "SVBg/EventSV/Grid2/EventItem8/GoBtn");


	--------- 获取控件 ---------

	local tip = "UI道庭增值引导窗口";

	--// 抬头
	winCtrl.titleLab = C(UILabel, winCtrl.winRootTrans, "Bg/TitleCont/Title", tip, false);
	--// 说明信息
	winCtrl.infoLab = C(UILabel, winCtrl.winRootTrans, "Info", tip, false);
	--// 滚动区域
	winCtrl.infoScrollView = C(UIScrollView, winCtrl.winRootTrans, "SVBg/EventSV", tip, false);

	--// 排序控件1
	winCtrl.infoGrid1 = C(UIGrid, winCtrl.winRootTrans, "SVBg/EventSV/Grid1", tip, false);
	--// 排序控件2
	winCtrl.infoGrid2 = C(UIGrid, winCtrl.winRootTrans, "SVBg/EventSV/Grid2", tip, false);

	--// 关闭按钮
	local com = C(UIButton, winCtrl.winRootTrans, "Bg/TitleCont/BtnClose", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:Close();
	end;

	UITool.SetBtnSelf(winCtrl.tag1BtnObj, self.ChangeToDTZJ, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag2BtnObj, self.ChangeToDJ, self, self.Name);


	UITool.SetBtnSelf(winCtrl.tag1btnObj1, self.GoToFDinner, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag1btnObj2, self.ClickFBoss, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag1btnObj3, self.ClickFEscort, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag1btnObj4, self.ClickFDefend, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag1btnObj5, self.ClickFWar, self, self.Name);

	UITool.SetBtnSelf(winCtrl.tag2btnObj1, self.GoToFDepot, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag2btnObj2, self.GoToFMission, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag2btnObj4, self.GoToFDinner, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag2btnObj5, self.ClickFBoss, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag2btnObj6, self.ClickFEscort, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag2btnObj7, self.ClickFDefend, self, self.Name);
	UITool.SetBtnSelf(winCtrl.tag2btnObj8, self.ClickFWar, self, self.Name);

	
	--// 当前标签索引
	winCtrl.curTagIndex = 0;
	--// 延迟重置倒数
	winCtrl.delayResetCount = 0;

	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UIFamilyTipsWnd:OpenCustom()
	if FamilyMgr:JoinFamily() == false then
		self:Close();
		return;
	end
	winCtrl.mOpen = true;
	
	self:ChangeToDTZJ();
end

--// 关闭窗口
function UIFamilyTipsWnd:CloseCustom()
	winCtrl.curTagIndex = 0;

	winCtrl.mOpen = false;
end

--// 销毁释放窗口
function UIFamilyTipsWnd:DisposeCustom()
	winCtrl.mOpen = false;
	winCtrl.init = false;
end

--// 更新
function UIFamilyTipsWnd:Update()
	if winCtrl.delayResetCount > 0 then
		winCtrl.delayResetCount = winCtrl.delayResetCount - 1;
		if winCtrl.delayResetCount <= 0 then
			winCtrl.delayResetCount = 0;
			winCtrl.infoScrollView:ResetPosition();
		end
	end
end

--// 点击标签
function UIFamilyTipsWnd:ClickTag(tagIndex)
	if tagIndex == 2 then
		self:ChangeToDJ();
	else
		self:ChangeToDTZJ();
	end
end

--// 打开道庭资金途径
function UIFamilyTipsWnd:ChangeToDTZJ()
	if winCtrl.curTagIndex == 1 then
		return;
	end

	winCtrl.tag1BtnSelObj:SetActive(true);
	winCtrl.tag2BtnSelObj:SetActive(false);

	winCtrl.grid1Obj:SetActive(true);
	winCtrl.grid2Obj:SetActive(false);

	winCtrl.infoGrid1:Reposition();
	self:DelayResetSVPosition();

	winCtrl.titleLab.text = "道庭资金";
	winCtrl.curTagIndex = 1;
end

--// 打开道绩途径
function UIFamilyTipsWnd:ChangeToDJ()
	if winCtrl.curTagIndex == 2 then
		return;
	end

	winCtrl.tag1BtnSelObj:SetActive(false);
	winCtrl.tag2BtnSelObj:SetActive(true);

	winCtrl.grid1Obj:SetActive(false);
	winCtrl.grid2Obj:SetActive(true);

	winCtrl.infoGrid2:Reposition();
	self:DelayResetSVPosition();

	winCtrl.titleLab.text = "道绩";
	winCtrl.curTagIndex = 2;
end

--// 道庭仓库
function UIFamilyTipsWnd:GoToFDepot()
	UIMgr.Close(UIFamilyMainWnd.Name);
	self:Close();

	UIMgr.Open(UIFamilyDepotWnd.Name);
end

--// 道庭任务
function UIFamilyTipsWnd:GoToFMission()
	UIMgr.Close(UIFamilyMainWnd.Name);
	self:Close();

	if OpenMgr:IsOpen(33) then
		UIMgr.Open(UIFamilyMission.Name)
	else
		UITip.Log("系统未开启")
	end
end

--// 道庭晚宴
function UIFamilyTipsWnd:GoToFDinner()
	UIMgr.Close(UIFamilyMainWnd.Name);
	self:Close();

	UIMgr.Open(UIFamilyAnswerIt.Name);
end

--// 道庭神兽
function UIFamilyTipsWnd:ClickFBoss()
	UIMgr.Close(UIFamilyMainWnd.Name);
	self:Close();

	UIMgr.Open(UIFamilyBossIt.Name);
end

--// 道庭护送
function UIFamilyTipsWnd:ClickFEscort()
	UIMgr.Close(UIFamilyMainWnd.Name);
	self:Close();

	if FamilyEscortMgr:GetSysEscortStatus() then
		UIMgr.Open(UIFamilyEscort.Name)
	else
		UITip.Log(string.format("%s级开启", ActivityTemp["103"].lv))
		-- UITip.Log("活动尚未开启")
	end
end

--// 守卫道庭
function UIFamilyTipsWnd:ClickFDefend()
	UIMgr.Close(UIFamilyMainWnd.Name);
	self:Close();

	UIMgr.Open(UIFamilyDefendWnd.Name);
end

--// 道庭大战
function UIFamilyTipsWnd:ClickFWar()
	UIMgr.Close(UIFamilyMainWnd.Name);
	self:Close();

	UIMgr.Open(UIFamilyWar.Name)
end

--// 延迟重置滑动面板位置
function UIFamilyTipsWnd:DelayResetSVPosition()
	winCtrl.delayResetCount = 2;
end

return UIFamilyTipsWnd
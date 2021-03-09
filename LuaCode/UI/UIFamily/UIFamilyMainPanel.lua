--// 道庭主面板
--require("UI/UIFamily/UIFamilyGamePanel");
require("UI/UIFamily/UIFamilyInfoPanel");
require("UI/UIFamily/UIFamilyNoticePanel");
--require("UI/UIFamily/UIFamilyBarPanel");
require("UI/UIFamily/UIFamilyGiftPanel");
require("UI/UIFamily/UIFamilyListPanel");
require("UI/UIFamily/UIFamilyNoticeEditPanel");


UIFamilyMainPanel = Super:New{Name = "UIFamilyMainPanel"};

local panelCtrl = {};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 初始化面板
function UIFamilyMainPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyMainPanel create !!! ");

	local tip = "UI道庭主面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 活动面板物体
	--panelCtrl.gamePanelObj = T(panelCtrl.rootTrans, "GamePanel");
	--// 信息面板物体
	panelCtrl.infoObj = T(panelCtrl.rootTrans, "InfoPanel");
	--// 通告面板物体
	panelCtrl.noticeObj = T(panelCtrl.rootTrans, "NoticePanel");
	--// 简介面板物体
	--panelCtrl.barObj = T(panelCtrl.rootTrans, "UpBar");
	--// 礼物面板物体
	panelCtrl.giftObj = T(panelCtrl.rootTrans, "GiftPanel");
	--// 帮派列表面板物体
	panelCtrl.listPanelObj = T(panelCtrl.rootTrans, "FamilyListPanel");
	--// 道庭公告修改面板物体
	panelCtrl.noticeEditObj = T(panelCtrl.rootTrans, "NoticeEditPanel");

	--// 道庭商店按钮物体
	panelCtrl.btnShopObj = T(panelCtrl.rootTrans, "BtnPanel/BtnShop");
	--// 道庭任务按钮物体
	panelCtrl.btnMissionObj = T(panelCtrl.rootTrans, "BtnPanel/BtnMission");
	--// 道庭护送按钮物体
	panelCtrl.btnEscortObj = T(panelCtrl.rootTrans, "BtnPanel/BtnEscort");
	--// 道庭仓库按钮物体
	panelCtrl.btnDepotObj = T(panelCtrl.rootTrans, "BtnPanel/BtnDepot");
	--// 道庭新仓库按钮物体
	panelCtrl.btnWarehouseObj = T(panelCtrl.rootTrans, "BtnPanel/BtnWarehouse");

	--// 红点物体
	panelCtrl.redBtnObjs = {};
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "BtnPanel/BtnShop/RedP");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "BtnPanel/BtnMission/RedP");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "BtnPanel/BtnEscort/RedP");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "BtnPanel/BtnDepot/RedP");
	panelCtrl.redBtnObjs[#panelCtrl.redBtnObjs + 1] = T(panelCtrl.rootTrans, "BtnPanel/BtnWarehouse/RedP");


	--// 初始化活动面板
	--UIFamilyGamePanel:Init(panelCtrl.gamePanelObj);
	--// 初始化信息面板
	UIFamilyInfoPanel:Init(panelCtrl.infoObj);
	--// 初始化公告面板
	UIFamilyNoticePanel:Init(panelCtrl.noticeObj);
	--// 初始化简介面板
	--UIFamilyBarPanel:Init(panelCtrl.barObj);
	--// 初始化礼物面板
	UIFamilyGiftPanel:Init(panelCtrl.giftObj);
	--// 初始化帮派列表面板
	UIFamilyListPanel:Init(panelCtrl.listPanelObj);
	UIFamilyListPanel:Close();
	--// 初始化公告修改面板
	UIFamilyNoticeEditPanel:Init(panelCtrl.noticeEditObj);
	UIFamilyNoticeEditPanel:Close();

	UITool.SetBtnSelf(panelCtrl.btnShopObj, self.ClickBtnShop, self, self.Name);
	UITool.SetBtnSelf(panelCtrl.btnMissionObj, self.ClickBtnMission, self, self.Name);
	UITool.SetBtnSelf(panelCtrl.btnEscortObj, self.ClickBtnEscort, self, self.Name);
	UITool.SetBtnSelf(panelCtrl.btnDepotObj, self.ClickBtnDepot, self, self.Name);
	UITool.SetBtnSelf(panelCtrl.btnWarehouseObj, self.ClickBtnWarehouse, self, self.Name)

	--// 
	panelCtrl.OnNewData = EventHandler(self.FamilyRename, self);
	EventMgr.Add("FamilyNameChange", panelCtrl.OnNewData);

	panelCtrl.OnNewNotice = EventHandler(self.FamilyNoticeChange, self);
	EventMgr.Add("FamilyNoticeChange", panelCtrl.OnNewNotice);

	FamilyMgr.eRed["Add"](FamilyMgr.eRed, self.NewMsg, self);

	panelCtrl.init = true;
	panelCtrl.open = false;
end

--// 打开面板
function UIFamilyMainPanel:Open()

	if panelCtrl.open == true then
		return;
	end

	panelCtrl.open = true;
	panelCtrl.panelObj:SetActive(true);

	local familyData = FamilyMgr:GetFamilyData();
	local memberData = FamilyMgr:GetCurMemberData();
	if familyData == nil or memberData == nil then
		iError("LY", "Self family member data miss !!! ");
	else
		UIFamilyNoticePanel:SetDataShow(familyData.notice);
		if FamilyMgr:CanEditNotice() == true then
			UIFamilyNoticePanel:ShowEditBtn(true);
		else
			UIFamilyNoticePanel:ShowEditBtn(false);
		end

		UIFamilyInfoPanel:SetDataShow(familyData, memberData);
		UIFamilyGiftPanel:ShowData();

		--//检测是否有宝箱
		if FamilyMgr:GetNewBoxNumber() > 0 then
			self:NewMsg(true, 1, 4);
		else
			self:NewMsg(false, 1, 4);
		end

		local mState = FamilyMissionMgr:IsShowAction()--道庭任务
		self:NewMsg(mState, 1, 2);
		local canGetReward = FamilyEscortMgr:GetHasRewardStatus()
		if FamilyEscortMgr:IsOpen() then
			local escortTime = FamilyEscortMgr:GetEscortRemainTime()
			local isEscorting = FamilyEscortMgr:IsEscorting()
			if isEscorting then
				self:NewMsg(false, 1, 3)
			else
				self:NewMsg(escortTime > 0 or canGetReward==1, 1, 3)
			end

		else
			if canGetReward == 1 then
				self:NewMsg(true, 1, 3)
			else
				self:NewMsg(false, 1, 3)
			end
		end

	end

end

--// 关闭面板
function UIFamilyMainPanel:Close()
	--UIFamilyNoticePanel:EndEditState()
	panelCtrl.panelObj:SetActive(false);

	panelCtrl.open = false;
end

--// 释放面板
function UIFamilyMainPanel:Dispose()
	EventMgr.Remove("FamilyNameChange", panelCtrl.OnNewData);
	EventMgr.Remove("FamilyNoticeChange", panelCtrl.OnNewNotice);

	FamilyMgr.eRed["Remove"](FamilyMgr.eRed, self.NewMsg, self);

	UIFamilyInfoPanel:Dispose();
	UIFamilyNoticePanel:Dispose();
	UIFamilyNoticeEditPanel:Dispose();
	UIFamilyGiftPanel:Dispose();
	UIFamilyListPanel:Dispose();

	panelCtrl.init = false;
end

--// 
function UIFamilyMainPanel:ClickBtnShop()
	if UIStore:IsOpen() == false then
		UITip.Log("系统未开发！");
		return;
	end

	StoreMgr.OpenStore(99);
end

--// 
function UIFamilyMainPanel:ClickBtnMission()
	if OpenMgr:IsOpen(33) then
		-- UIMgr.Open(UIFamilyMission.Name)
		UIFamilyMission:OpenTab(true)
	else
		UITip.Log("系统未开启")
	end
end

--// 
function UIFamilyMainPanel:ClickBtnEscort()
	-- if OpenMgr:IsOpen(66) then
	-- 	JumpMgr:InitJump(UIFamilyMainWnd.Name)
	-- 	UIMgr.Open(UIFamilyEscort.Name)
	-- else
	-- 	local tCfg = SystemOpenTemp[tostring(66)];
	-- 	if tCfg ~= nil and tCfg.trigParam ~= nil then
	-- 		local showStr = StrTool.Concat(tostring(tCfg.trigParam), "级开启道庭护送");
	-- 		UITip.Log(showStr);
	-- 	end
	-- end
	if FamilyEscortMgr:GetSysEscortStatus() then
		JumpMgr:InitJump(UIFamilyMainWnd.Name)
		UIMgr.Open(UIFamilyEscort.Name)
	else
		if SystemOpenTemp["66"].trigParam then
			UITip.Log(string.format("%s级开启", SystemOpenTemp["66"].trigParam))
		else
			UITip.Log("活动尚未开启")
		end
	end
end

--// 
function UIFamilyMainPanel:ClickBtnDepot()
	UIMgr.Open(UIFamilyDepotWnd.Name);
end

--//
function UIFamilyMainPanel:ClickBtnWarehouse()
	UIMgr.Open(UIFamilyWarehouse.Name)
end

--// 
function UIFamilyMainPanel:FamilyRename()
	if panelCtrl.open == nil or panelCtrl.open == false then
		return;
	end

	local familyData = FamilyMgr:GetFamilyData();
	local memberData = FamilyMgr:GetCurMemberData();
	UIFamilyInfoPanel:SetDataShow(familyData, memberData);
end

--// 道庭公告改变
function UIFamilyMainPanel:FamilyNoticeChange()
	local familyData = FamilyMgr:GetFamilyData();
	if familyData == nil then
		iError("LY", "Self family member data miss !!! ");
		return;
	end

	UIFamilyNoticePanel:SetDataShow(familyData.notice);
end

--// 有新状态到达
function UIFamilyMainPanel:NewMsg(state, tapIndex, subIndex)
	if panelCtrl.open == nil or panelCtrl.open == false or tapIndex ~= 1 then
		return;
	end

	if subIndex == nil or subIndex < 1 or subIndex > 5 then
		return;
	end

	panelCtrl.redBtnObjs[subIndex]:SetActive(state);
end
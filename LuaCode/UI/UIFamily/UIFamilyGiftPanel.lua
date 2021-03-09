--// 道庭礼物面板
--require("UI/UIFamily/UIFItemCell");
require("UI/UIFamily/UIFDItemCell");


UIFamilyGiftPanel = Super:New{Name = "UIFamilyGiftPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 初始化面板
function UIFamilyGiftPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyGiftPanel create !!! ");

	local tip = "UI道庭礼物面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 主面板物体
	-- panelCtrl.giftItemObj = T(panelCtrl.rootTrans, "ItemCell");
	--// 红点提示物体
	panelCtrl.redSignObj = T(panelCtrl.rootTrans, "RedSign");
	panelCtrl.redSignObj:SetActive(false);

	--// 奖励信息
	panelCtrl.giftInfoL = C(UILabel, panelCtrl.rootTrans, "NameAndNum", tip, false);

	panelCtrl.stateL = C(UILabel, panelCtrl.rootTrans, "GiftBtn/Label", tip, false);

	--// 上一项按钮
	-- local com = C(UIButton, panelCtrl.rootTrans, "LB", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ChangeLastItem(); end;
	--// 下一项按钮
	-- com = C(UIButton, panelCtrl.rootTrans, "RB", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ChangeNextPage(); end;
	--// 领取按钮
	com = C(UIButton, panelCtrl.rootTrans, "GiftBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:GetGift(); end;


	-- panelCtrl.giftItem = ObjPool.Get(UIFItemCell);
	-- panelCtrl.giftItem:Init(panelCtrl.giftItemObj);

	-- panelCtrl.cellCont = ObjPool.Get(UIItemCell);
	-- panelCtrl.cellCont:InitLoadPool(panelCtrl.giftItemObj.transform, 1);
	--panelCtrl.cellCont:TipData(self.tbData, 1, self.btnList, self.isCom);

	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("RewardChange", panelCtrl.OnNewData);

	--panelCtrl.mOpen = false;
	panelCtrl.init = true;
end

--// 设置公告显示
function UIFamilyGiftPanel:ShowData()
	if panelCtrl == nil or panelCtrl.init == nil or panelCtrl.init == false then
		return;
	end

	local tInfo = GlobalTemp[tostring(50)];
	if tInfo == nil then
		iError("LY", "Can not find reward info !!! ");
	end

	local tItemInfo = ItemData[tostring(tInfo.Value2[1])];
	panelCtrl.giftInfoL = tItemInfo.name;

	-- panelCtrl.cellCont:UpData(tostring(tInfo.Value2[1], 1, true));

	if FamilyMgr:IsGetReward() == true then
		panelCtrl.stateL.text = "已领取"
		panelCtrl.redSignObj:SetActive(false);
	else
		panelCtrl.stateL.text = "领取"
		panelCtrl.redSignObj:SetActive(true);
	end
end

--// 转换上一个奖励
-- function UIFamilyGiftPanel:ChangeLastItem()
	
-- end

--// 转换下一个奖励
-- function UIFamilyGiftPanel:ChangeNextItem()
	
-- end

--// 获取礼物
function UIFamilyGiftPanel:GetGift()
	if FamilyMgr:IsGetReward() == true then
		return;
	end

	FamilyMgr:ReqReward();
end

--// 释放
function UIFamilyGiftPanel:Dispose()
	EventMgr.Remove("RewardChange", panelCtrl.OnNewData);

	-- if panelCtrl.cellCont ~= nil then
	-- 	--panelCtrl.cellCont:DestroyGo();
	-- 	panelCtrl.cellCont:Dispose();
	-- 	ObjPool.Add(self.cellCont);
	-- 	panelCtrl.cellCont = nil;
	-- end

	panelCtrl.init = false;
end
--// 道庭设置面板
require("UI/UIFamily/UICheckBoxO")

UIFamilyConfigPanel = Super:New{Name = "UIFamilyConfigPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local MAXLIMITLV = 999;
local MAXLIMITPOWER = 2000000000;

--// 初始化面板
function UIFamilyConfigPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyConfigPanel create !!! ");

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 勾选框物体
	panelCtrl.checkBoxObj = T(panelCtrl.rootTrans, "ConfigCon/CfgCon/Con1/CheckBox");
	--// 
	panelCtrl.lvObj = T(panelCtrl.rootTrans, "ConfigCon/CfgCon/Con2/Value");
	--//
	--panelCtrl.lvShowObj = T(panelCtrl.rootTrans, "ConfigCon/CfgCon/Con2/Show");

	--------- 获取控件 ---------

	local tip = "UI道庭设置面板"
	--// 等级显示
	panelCtrl.lvLabel = C(UILabel, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con2/Value", tip, false);
	--// 等级显示
	--panelCtrl.lvShowLabel = C(UILabel, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con2/Show", tip, false);
	--// 等级输入控件
	panelCtrl.lvInputCom = C(UIInput, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con2/InputBg", tip, false);
	--// 战力显示
	panelCtrl.powerLabel = C(UILabel, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con3/Value", tip, false);
	--// 等级输入控件
	panelCtrl.powerInputCom = C(UIInput, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con3/InputBg", tip, false);

	--// 关闭按钮
	local com = C(UIButton, panelCtrl.rootTrans, "ConfigCon/TitleCon/CloseBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:Close(); end;
	--// 勾选框
	com = C(UIButton, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con1/CheckBox", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickCheckBox(); end;
	--// 降等级按钮
	com = C(UIButton, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con2/M", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickLvM(); end;
	--// 升等级按钮
	com = C(UIButton, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con2/P", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickLvP(); end;
	--// 降战力按钮
	com = C(UIButton, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con3/M", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickPowerM(); end;
	--// 升战力按钮
	com = C(UIButton, panelCtrl.rootTrans, "ConfigCon/CfgCon/Con3/P", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickPowerP(); end;
	--// 取消
	com = C(UIButton, panelCtrl.rootTrans, "ConfigCon/CfgCon/NoBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickCancel(); end;
	--// 保存
	com = C(UIButton, panelCtrl.rootTrans, "ConfigCon/CfgCon/YesBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickSave(); end;

	EventDelegate.Add(panelCtrl.lvInputCom.onChange, EventDelegate.Callback(self.CheckInputLv, self));
	EventDelegate.Add(panelCtrl.powerInputCom.onChange, EventDelegate.Callback(self.CheckInputPower, self));

	panelCtrl.familyData = nil;
	--// 是否直接加入
	panelCtrl.isDirectJoin = true;
	--// 限制等级
	panelCtrl.limitLevel = 1;
	--// 限制战力
	panelCtrl.limitPower = 1;

	--// 等级输入状态
	panelCtrl.inputLv = false;
	--// 战力输入状态
	panelCtrl.inputPower = false;


	panelCtrl.checkBox = UICheckBoxO:New();
	panelCtrl.checkBox:Init(panelCtrl.checkBoxObj);

	panelCtrl.open = false;
	panelCtrl.init = true;
end

--// 打开
function UIFamilyConfigPanel:Open()
	panelCtrl.panelObj:SetActive(true);
	self:ResetPanel();

	panelCtrl.open = true;
end

--// 
function UIFamilyConfigPanel:Update()
	if panelCtrl.open == nil or panelCtrl.open == false then
		return;
	end

	--// 等级选中状态
	if panelCtrl.lvInputCom.isSelected == true and panelCtrl.inputLv == false then
		self:OnLvInput();
	--// 等级结束选中状态
	elseif panelCtrl.lvInputCom.isSelected == false and panelCtrl.inputLv == true then
		self:FinLvInput();
	end

	--// 战力选中状态
	if panelCtrl.powerInputCom.isSelected == true and panelCtrl.inputPower == false then
		self:OnPowerInput();
	--// 等级结束选中状态
	elseif panelCtrl.powerInputCom.isSelected == false and panelCtrl.inputPower == true then
		self:FinPowerInput();
	end
end

--// 关闭
function UIFamilyConfigPanel:Close()
	panelCtrl.familyData = nil;
	panelCtrl.panelObj:SetActive(false);

	panelCtrl.open = false;
end

--// 销毁释放面板
function UIFamilyConfigPanel:Dispose()
	panelCtrl.init = false;
end

--// 
function UIFamilyConfigPanel:CheckInputLv()
	local inputLv = tonumber(panelCtrl.lvInputCom.value);
	if inputLv == nil then
		return;
	end

	if inputLv <= 0 then
		panelCtrl.limitLevel = 1;
		panelCtrl.lvInputCom.value = tostring(panelCtrl.limitLevel);
		MsgBox.ShowYes("限制等级最小为1级！");
		return;
	end

	if inputLv > MAXLIMITLV then
		panelCtrl.limitLevel = MAXLIMITLV;
		panelCtrl.lvInputCom.value = tostring(panelCtrl.limitLevel);
		MsgBox.ShowYes("限制等级最大为999级！");
		return;
	end

	panelCtrl.limitLevel = inputLv;
end

--// 
function UIFamilyConfigPanel:OnLvInput()
	panelCtrl.inputLv = true;

	--panelCtrl.lvObj:SetActive(true);
	--panelCtrl.lvShowObj:SetActive(false);
end

--// 
function UIFamilyConfigPanel:FinLvInput()
	panelCtrl.inputLv = false;

	self:CheckInputLv();
	--panelCtrl.lvObj:SetActive(false);
	--panelCtrl.lvShowObj:SetActive(true);
end

--// 
function UIFamilyConfigPanel:CheckInputPower()
	local inputPower = tonumber(panelCtrl.powerInputCom.value);
	if inputPower == nil then
		return;
	end

	if inputPower < 0 then
		panelCtrl.limitPower = 0;
		panelCtrl.powerInputCom.value = tostring(panelCtrl.limitPower);
		MsgBox.ShowYes("限制战力最小为0！");
		return;
	end

	if inputPower > MAXLIMITPOWER then
		panelCtrl.limitPower = MAXLIMITPOWER;
		panelCtrl.powerInputCom.value = tostring(panelCtrl.limitPower);
		local showStr = StrTool.Concat("限制战力最大为", tostring(MAXLIMITPOWER));
		MsgBox.ShowYes(showStr);
		return;
	end

	panelCtrl.limitPower = inputPower;
end

--// 
function UIFamilyConfigPanel:OnPowerInput()
	panelCtrl.inputPower = true;
end

--// 
function UIFamilyConfigPanel:FinPowerInput()
	panelCtrl.inputPower = false;

	self:CheckInputPower();
end

--// 重置面板数据
function UIFamilyConfigPanel:ResetPanel()
	panelCtrl.familyData = FamilyMgr:GetFamilyData();
	panelCtrl.isDirectJoin = panelCtrl.familyData.isDirectJoin;
	panelCtrl.limitLevel = panelCtrl.familyData.limitLevel;
	panelCtrl.limitPower = panelCtrl.familyData.limitPower;

	panelCtrl.checkBox:SetCheck(panelCtrl.isDirectJoin);
	panelCtrl.lvLabel.text = tostring(panelCtrl.limitLevel);
	panelCtrl.powerLabel.text = tostring(panelCtrl.limitPower);
end

--// 点击勾选框
function UIFamilyConfigPanel:ClickCheckBox()
	if panelCtrl.isDirectJoin == true then
		panelCtrl.isDirectJoin = false;
	else
		panelCtrl.isDirectJoin = true;
	end

	--print("                       "..tostring(panelCtrl.isDirectJoin))
	panelCtrl.checkBox:SetCheck(panelCtrl.isDirectJoin);
end

--// 点击降等级
function UIFamilyConfigPanel:ClickLvM()
	panelCtrl.limitLevel = panelCtrl.limitLevel - 1;
	if panelCtrl.limitLevel < 0 then
		panelCtrl.limitLevel = 0;
	end

	panelCtrl.lvLabel.text = tostring(panelCtrl.limitLevel);
end

--// 点击升等级
function UIFamilyConfigPanel:ClickLvP()
	panelCtrl.limitLevel = panelCtrl.limitLevel + 1;
	panelCtrl.lvLabel.text = tostring(panelCtrl.limitLevel);
end

--// 点击降战力
function UIFamilyConfigPanel:ClickPowerM()
	panelCtrl.limitPower = panelCtrl.limitPower - 1000;
	if panelCtrl.limitPower < 0 then
		panelCtrl.limitPower = 0;
	end

	panelCtrl.powerLabel.text = tostring(panelCtrl.limitPower);
end

--// 点击升战力
function UIFamilyConfigPanel:ClickPowerP()
	panelCtrl.limitPower = panelCtrl.limitPower + 1000;
	panelCtrl.powerLabel.text = tostring(panelCtrl.limitPower);
end

--// 点击取消
function UIFamilyConfigPanel:ClickCancel()
	self:Close();
end

--// 点击保存
function UIFamilyConfigPanel:ClickSave()
	if panelCtrl.isDirectJoin == panelCtrl.familyData.isDirectJoin 
		and panelCtrl.limitLevel == panelCtrl.familyData.limitLevel
		and panelCtrl.limitPower == panelCtrl.familyData.limitPower then
		self:Close();
		return;
	end

	local key1Tbl = {};
	local val1Tbl = {};

	key1Tbl[#key1Tbl + 1] = 1;
	key1Tbl[#key1Tbl + 1] = 2;
	key1Tbl[#key1Tbl + 1] = 3;

	if panelCtrl.isDirectJoin == true then
		val1Tbl[#val1Tbl + 1] = 1;
	else
		val1Tbl[#val1Tbl + 1] = 0;
	end
	val1Tbl[#val1Tbl + 1] = panelCtrl.limitLevel;
	val1Tbl[#val1Tbl + 1] = panelCtrl.limitPower;

	FamilyMgr:ReqFamilyConfig(false, true, key1Tbl, val1Tbl, nil, nil);
	self:Close();
end
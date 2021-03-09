--// 道庭创建面板
--require("UI/UIWingWnd/UIWingSkillBtn")

UINewFamilyPanel = Super:New{Name = "UINewFamilyPanel"}

local panelCtrl = {}

local iLog = iTrace.eLog;
local iError = iTrace.Error;

--// 初始化面板
function UINewFamilyPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UINewFamilyPanel create !!! ");

	local tip = "UI道庭创建面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 关闭按钮
	--panelCtrl.inputNameLabel = C(UILabel, panelCtrl.rootTrans, "Bg/NameInput/InName", tip, false);
	--// 输入控件
	panelCtrl.nameInputCom = C(UIInput, panelCtrl.rootTrans, "Bg/NameInput", tip, false);
	--// 等级判断显示
	--panelCtrl.lvOkLabel = C(UILabel, panelCtrl.rootTrans, "Bg/LvOkLabel", tip, false);
	--// 银两判断显示
	panelCtrl.goldLabel = C(UILabel, panelCtrl.rootTrans, "Bg/GoldLabel", tip, false);
	--// 令牌判断显示
	panelCtrl.monOkLabel = C(UILabel, panelCtrl.rootTrans, "Bg/MonOkLabel", tip, false);
	--// 道庭图标
	panelCtrl.familyIcon = C(UITexture, panelCtrl.rootTrans, "Bg/FamilyIcon", tip, false);


	local com = C(UIButton, panelCtrl.rootTrans, "Bg/Ok", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickOk();
	end;

	com = C(UIButton, panelCtrl.rootTrans, "Bg/TitleBg/Cancel", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:Close();
	end;

	com = C(UIButton, panelCtrl.rootTrans, "Bg/BtnL/Bg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:CLastIcon();
	end;

	com = C(UIButton, panelCtrl.rootTrans, "Bg/BtnR/Bg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:CNextIcon();
	end;

	EventDelegate.Add(panelCtrl.nameInputCom.onChange, EventDelegate.Callback(self.CheckInput, self));

	panelCtrl.open = false;
	panelCtrl.firstClick = false;
	panelCtrl.init = true;
end

--// 打开面板
function UINewFamilyPanel:Open()
	--panelCtrl.inputNameLabel.text = "";
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.open = true;
	--panelCtrl.nameInputCom.value = "点击此处输入";
	panelCtrl.nameInputCom.defaultText = "点击此处输入";
	panelCtrl.firstClick = false;

	PropMgr.eUpdate:Add(self.RenewItemNum, self);

	self:ShowData();
end

--// 关闭面板
function UINewFamilyPanel:Close()
	PropMgr.eUpdate:Remove(self.RenewItemNum, self)

	panelCtrl.panelObj:SetActive(false);
	panelCtrl.open = false;
end

function UINewFamilyPanel:Dispose()
	panelCtrl.init = false;
end

function UINewFamilyPanel:Update()
	if panelCtrl.open == nil or panelCtrl.open == false then
		return;
	end

	if panelCtrl.nameInputCom.isSelected == true and panelCtrl.firstClick == false then
		panelCtrl.nameInputCom.value = "";
		panelCtrl.firstClick = true;
	end
end

function UINewFamilyPanel:RenewItemNum()
	local lpNum = PropMgr.TypeIdByNum(31007);

	if lpNum >= 1 then
		panelCtrl.monOkLabel.text = StrTool.Concat("[00FF00FF]", tostring(lpNum), "[-]", "[F4DDBDFF]/1", "[-]");
	else
		panelCtrl.monOkLabel.text = StrTool.Concat("[F21919FF]", tostring(lpNum), "[-]/[F4DDBDFF]1[-]");
	end
end

function UINewFamilyPanel:RenewGoldNum()
	local goldNum = RoleAssets.Silver;
	local mathToStr = math.NumToStrCtr

	if goldNum >= 10000 then
		panelCtrl.goldLabel.text = StrTool.Concat("[00FF00FF]", mathToStr(goldNum), "[-]", "[F4DDBDFF]/1万[-]");
	else
		panelCtrl.goldLabel.text = StrTool.Concat("[F21919FF]", mathToStr(goldNum), "[-][F4DDBDFF]/1万[-]");
	end
end

--// 检测输入
function UINewFamilyPanel:CheckInput()
	local tempName = panelCtrl.nameInputCom.value;
	local nameTbl = StrTool.SplitStrToTbl(tempName);
	if #nameTbl > 6 then
		UITip.Log("道庭名称不能超过6个字符 ！ ");
		return;
	end

	panelCtrl.nameInputCom.value = FamilyMgr:FilterSpecChars(tempName);
end

--// 点击创建帮派
function UINewFamilyPanel:ClickOk()
	--local tempName = panelCtrl.inputNameLabel.text;
	local tempName = panelCtrl.nameInputCom.value;
	if tempName == "" or tempName == "点击此处输入" then
		--iLog("LY", "Family name is null !!! ");
		UITip.Log("道庭名称不能为空 ！ ");
		return;
	end

	local nameTbl = StrTool.SplitStrToTbl(tempName);
	if #nameTbl > 6 then
		UITip.Log("道庭名称不能超过6个字符 ！ ");
		return;
	end

	local lpNum = PropMgr.TypeIdByNum(31007);
	if lpNum == nil or lpNum <= 0 then 
		StoreMgr.TypeIdBuy(31007, 1, true);
		return;
	end

	local goldNum = RoleAssets.Silver;
	if goldNum < 10000 then
		UITip.Log("银两不足 ！ ");
		return;
	end

	--local checkName = panelCtrl.inputNameLabel.text;
	local checkRetName, isIllegal = MaskWord.SMaskWord(tempName);
	if isIllegal == true then
		panelCtrl.nameInputCom.value = checkRetName;
		--UITip.Error("存在非法字符 ！！！ ");
		MsgBox.ShowYes("存在非法字符 ！！！");

		return;
	end

	FamilyMgr:ReqCreateFamily(tempName);
	UITip.Log("创建道庭已提交 ！！！ ");
	self:Close();
end

--// 转换上一个图标
function UINewFamilyPanel:CLastIcon()
	
end

--// 转换下一个图标
function UINewFamilyPanel:CNextIcon()
	
end

--// 显示数据
function UINewFamilyPanel:ShowData()
	--local vipLv = VIPMgr.GetVIPLv();
	--local playerMon = RoleAssets.BindGold + RoleAssets.Gold;
	local lpNum = PropMgr.TypeIdByNum(31007);

	-- if vipLv >= 4 then
	-- 	panelCtrl.lvOkLabel.text = "(已达成)";
	-- 	panelCtrl.lvOkLabel.color = Color.New(0/255, 255/255, 0/255, 1);
	-- else
	-- 	panelCtrl.lvOkLabel.text = "(未达成)";
	-- 	panelCtrl.lvOkLabel.color = Color.New(242/255, 25/255, 25/255, 1);
	-- end

	self:RenewItemNum();
	self:RenewGoldNum();
end

--// 读取道庭图标
-- function UINewFamilyPanel:LoadFamilyIcon(iconName)
-- 	AssetMgr.Instance:Load(iconName, ObjHandler(self.LoadIconFin,self));
-- end

--// 读取图标完成
-- function UINewFamilyPanel:LoadIconFin(obj)
-- 	panelCtrl.familyIcon.mainTexture = obj;
-- end
--// 道庭信息面板
UIFamilyInfoPanel = Super:New{Name = "UIFamilyInfoPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 初始化面板
function UIFamilyInfoPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyInfoPanel create !!! ");

	local tip = "UI道庭信息面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;


	--// 改名按钮物体
	panelCtrl.renameBtnObj = T(panelCtrl.rootTrans, "ReNameBtn");
	--// 改名图标物体
	panelCtrl.renameSignObj = T(panelCtrl.rootTrans, "ReNameBtn/RenameSign");
	--// 道庭列表按钮物体
	panelCtrl.familyListBtnObj = T(panelCtrl.rootTrans, "FamilyListBtn");
	--// 引导按钮物体
	panelCtrl.getInfoBtnObj = T(panelCtrl.rootTrans, "GetInfoBtn");


	--// 帮派名称
	panelCtrl.familyNameL = C(UILabel, panelCtrl.rootTrans, "ReNameBtn/FamilyName", tip, false);
	--// 道庭战力Label
	panelCtrl.abilityL = C(UILabel, panelCtrl.rootTrans, "FigVal/FamilyAbility", tip, false);
	--// 道庭等级Label
	panelCtrl.lvL = C(UILabel, panelCtrl.rootTrans, "FigVal/FamilyLv", tip, false);
	--// 道庭排名Label
	--panelCtrl.rankL = C(UILabel, panelCtrl.rootTrans, "FigVal/FamilyRank", tip, false);
	--// 职位
	--panelCtrl.titleL = C(UILabel, panelCtrl.rootTrans, "FigVal/Title", tip, false);
	--// 庭主名字Label
	panelCtrl.ownerNameL = C(UILabel, panelCtrl.rootTrans, "FigVal/OwnerName", tip, false);
	--// 帮派人数Label
	panelCtrl.numberL = C(UILabel, panelCtrl.rootTrans, "FigVal/MemberNum", tip, false);
	--// 道庭资金Label
	panelCtrl.moneyL = C(UILabel, panelCtrl.rootTrans, "FigVal/FamilyMoney", tip, false);
	--// 道庭升级金钱Label
	--panelCtrl.uMoneyL = C(UILabel, panelCtrl.rootTrans, "FigVal/UpgradeMoney", tip, false);
	--// 帮派贡献Label
	--panelCtrl.devoteL = C(UILabel, panelCtrl.rootTrans, "FigVal/MyDevote", tip, false);

	panelCtrl.moneySlider = C(UISlider, panelCtrl.rootTrans, "FigVal/FamilyMoney/MoneyPBar", tip, false);


	--// 点击改名按钮
	UITool.SetBtnSelf(panelCtrl.renameBtnObj, self.ClickReNameBtn, self, self.Name);
	--// 点击改名图标
	UITool.SetBtnSelf(panelCtrl.renameSignObj, self.ClickReNameBtn, self, self.Name);
	--// 打开帮派列表按钮
	UITool.SetBtnSelf(panelCtrl.familyListBtnObj, self.ClickOpenFamilyListBtn, self, self.Name);
	--// 
	UITool.SetBtnSelf(panelCtrl.getInfoBtnObj, self.ClickGetInfoBtn, self, self.Name);
	

	panelCtrl.init = true;
end

function UIFamilyInfoPanel:Dispose()
	panelCtrl.init = false;
end

--// 设置公告显示
function UIFamilyInfoPanel:SetDataShow(familyData, memberData)
	local fD = FamilyMgr:GetFamilyData();
	--local mD = FamilyMgr:GetCurMemberData();
	local curCfg = FamilyMgr:GetLvCfgByLv(familyData.Lv);
	local ownerData = FamilyMgr:GetFamilyOwnerData();

	--// 道庭名称
	panelCtrl.familyNameL.text = StrTool.Concat("【", fD.Name, "】");
	--// 道庭战力
	--panelCtrl.abilityL.text = tostring(memberData.power);
	panelCtrl.abilityL.text = tostring(FamilyMgr:GetFamilyAbility());
	--// 道庭等级
	panelCtrl.lvL.text = StrTool.Concat(tostring(fD.Lv), "级");
	--// 道庭排名
	--panelCtrl.rankL.text = StrTool.Concat(tostring(fD.rank), "名");
	--// 道庭职位
	--panelCtrl.titleL.text = FamilyMgr:GetTitleByIndex(memberData.title);
	--// 盟主名字
	if ownerData ~= nil then
		panelCtrl.ownerNameL.text = ownerData.roleName;
	end
	--// 道庭资金
	--panelCtrl.moneyL.text = tostring(familyData.money);

	local curMonStr = tostring(familyData.money);
	if familyData.money >= 100000000 then
		curMonStr = string.format("%.0f亿", familyData.money / 100000000);
	elseif familyData.money >= 10000 then
		curMonStr = string.format("%.0f万", familyData.money / 10000);
	end

	if curCfg == nil then
		--// 道庭资金
		panelCtrl.moneyL.text = curMonStr;
		panelCtrl.moneySlider.value = 0;
		--// 成员数量
		panelCtrl.numberL.text = tostring(#familyData.members);
		--// 升级资金
		--panelCtrl.uMoneyL.text = "-";
	else
		--// 道庭资金
		local upMonStr = tostring(curCfg.uMoney);
		if curCfg.uMoney >= 100000000 then
			upMonStr = string.format("%.0f亿", curCfg.uMoney / 100000000);
		elseif curCfg.uMoney >= 10000 then
			upMonStr = string.format("%.0f万", curCfg.uMoney / 10000);
		end
		panelCtrl.moneyL.text = StrTool.Concat(curMonStr, "/", upMonStr);
		if curCfg.uMoney > 0 then
			panelCtrl.moneySlider.value = familyData.money / curCfg.uMoney;
		else
			panelCtrl.moneySlider.value = 1;
		end
		--// 成员数量
		panelCtrl.numberL.text = StrTool.Concat(tostring(#familyData.members), "/", tostring(FamilyMgr:GetLvCfgMaxPer(familyData.Lv)));
		--// 升级资金
		--panelCtrl.uMoneyL.text = tostring(curCfg.uMoney);
	end
	--// 道庭贡献
	--panelCtrl.devoteL.text = tostring(FamilyMgr:GetFamilyCon());
end

--// 点击改名按钮
function UIFamilyInfoPanel:ClickReNameBtn(go)
	local owner = FamilyMgr.ChangeInt64Num(User.instance.MapData.UID)
	local data = FamilyMgr:GetFamilyOwnerData()
	if not data or data.roleId ~= owner then 
		UITip.Log("只有盟主才可以更换道庭名字")
		return
	end
	UIMgr.Open(UIChangeName.Name, self.ChangeNameCb, self)
end

function UIFamilyInfoPanel:ChangeNameCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpData(31031)
	end
end

--// 点击打开帮派列表按钮
function UIFamilyInfoPanel:ClickOpenFamilyListBtn()
	UIFamilyListPanel:Open();
end

--// 点击获取来源按钮
function UIFamilyInfoPanel:ClickGetInfoBtn()
	UIMgr.Open(UIFamilyTipsWnd.Name)
end
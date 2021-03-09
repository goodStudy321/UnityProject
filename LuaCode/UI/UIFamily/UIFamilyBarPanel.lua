--// 道庭简介面板

UIFamilyBarPanel = Super:New{Name = "UIFamilyBarPanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 初始化面板
function UIFamilyBarPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	iLog("LY", "UIFamilyBarPanel create !!! ");

	local tip = "UI道庭简介面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 职位
	panelCtrl.titleL = C(UILabel, panelCtrl.rootTrans, "Title", tip, false);
	--// 帮派排名Label
	panelCtrl.rankL = C(UILabel, panelCtrl.rootTrans, "FamilyRank", tip, false);
	--// 帮派名称
	panelCtrl.familyNameL = C(UILabel, panelCtrl.rootTrans, "FamilyName", tip, false);
	--// 帮派等级Label
	panelCtrl.lvL = C(UILabel, panelCtrl.rootTrans, "FamilyLv", tip, false);


	--// 点击改名按钮
	self.com = C(UIButton, panelCtrl.rootTrans, "ReNameBtn", tip, false);
	UITool.SetBtnSelf(self.com.gameObject,self.ClickReNameBtn,self,self.Name)
	

	--// 市场日志更新
	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("FamilyNameChange", panelCtrl.OnNewData);

	panelCtrl.init = true;
end

--// 设置公告显示
function UIFamilyBarPanel:ShowData()
	local fD = FamilyMgr:GetFamilyData();
	local mD = FamilyMgr:GetCurMemberData();

	panelCtrl.titleL.text = "="..FamilyMgr:GetTitleByIndex(mD.title).."=";
	panelCtrl.rankL.text = tostring(fD.rank).."名";
	panelCtrl.familyNameL.text = fD.Name;
	panelCtrl.lvL.text = tostring(fD.Lv).."级";
end

--// 点击改名按钮
function UIFamilyBarPanel:ClickReNameBtn(go)
	local owner = FamilyMgr.ChangeInt64Num(User.instance.MapData.UID)
	local data = FamilyMgr:GetFamilyOwnerData()
	if not data or data.roleId~=owner then 
		UITip.Log("只有盟主才可以更换道庭名字")
		return
	end
	UIMgr.Open(UIChangeName.Name,self.ChangeNameCb,self)
end

function UIFamilyBarPanel:ChangeNameCb(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:UpData(31031)
	end
end
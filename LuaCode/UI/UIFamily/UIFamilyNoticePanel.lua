--// 道庭通告面板
--require("UI/UIWingWnd/UIWingSkillBtn")

UIFamilyNoticePanel = Super:New{Name = "UIFamilyNoticePanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 初始化面板
function UIFamilyNoticePanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyNoticePanel create !!! ");

	local tip = "UI道庭通告面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 编辑公告按钮物体
	panelCtrl.editBtnObj = T(panelCtrl.rootTrans, "NoticeBg/EditBtn");
	--// 输入控件
	--panelCtrl.uiInput = C(UIInput, panelCtrl.rootTrans, "NoticeBg", tip, false);

	--panelCtrl.boxCollider = C(Collider, panelCtrl.rootTrans, "NoticeBg", tip, false);
	--// 公告label
	panelCtrl.noticeLabel = C(UILabel, panelCtrl.rootTrans, "NoticeBg/NoticeLabel", tip, false);
	--// 按钮label
	--panelCtrl.btnLabel = C(UILabel, panelCtrl.rootTrans, "NoticeBg/EditBtn/Label", tip, false);
	--// 编辑按钮
	local com = C(UIButton, panelCtrl.rootTrans, "NoticeBg/EditBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = UIFamilyNoticePanel.ClickEditBtn;

	--panelCtrl.boxCollider.enabled = false;
	--panelCtrl.uiInput.enabled = false;
	--// 是否在编辑状态
	--panelCtrl.inEdit = false;

	panelCtrl.init = true;
end

function UIFamilyNoticePanel:Dispose()
	panelCtrl.init = false;
end

--// 设置公告显示
function UIFamilyNoticePanel:SetDataShow(noticeString)
	if noticeString == nil or noticeString == "" then
		local tNotice = InvestDesCfg["9"].des;
		panelCtrl.noticeLabel.text = tNotice;
		return;
	end
	panelCtrl.noticeLabel.text = noticeString;
end

--// 设置编辑按钮显示
function UIFamilyNoticePanel:ShowEditBtn(isShow)
	panelCtrl.editBtnObj:SetActive(isShow);
end

--// 点击编辑按钮
function UIFamilyNoticePanel.ClickEditBtn(gameObject)
	UIFamilyNoticeEditPanel:Open();
	UIFamilyNoticeEditPanel:SetDataShow(panelCtrl.noticeLabel.text);
end
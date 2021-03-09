--// 道庭通告修改面板

UIFamilyNoticeEditPanel = Super:New{Name = "UIFamilyNoticeEditPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 初始化面板
function UIFamilyNoticeEditPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyNoticeEditPanel create !!! ");

	local tip = "UI道庭通告修改面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;


	panelCtrl.okBtnObj = T(panelCtrl.rootTrans, "EditCont/OkBtn");
	panelCtrl.canelBtnObj = T(panelCtrl.rootTrans, "EditCont/CanelBtn");
	panelCtrl.closeBtnObj = T(panelCtrl.rootTrans, "Bg");


	--// 公告label
	panelCtrl.noticeLabel = C(UILabel, panelCtrl.rootTrans, "EditCont/NoticeBg/NoticeLabel", tip, false);
	--// 
	panelCtrl.noticeInput = C(UIInput, panelCtrl.rootTrans, "EditCont/NoticeBg", tip, false);

	--// 提交按钮
	UITool.SetBtnSelf(panelCtrl.okBtnObj, self.ClickOkBtn, self, self.Name);
	--// 取消按钮
	UITool.SetBtnSelf(panelCtrl.canelBtnObj, self.Close, self, self.Name);
	--// 关闭按钮
	UITool.SetBtnSelf(panelCtrl.closeBtnObj, self.Close, self, self.Name);

	UITool.SetBtnSelf(panelCtrl.noticeInput.gameObject, self.OnChangeLab, self, self.Name,false);

	panelCtrl.open = false;
	panelCtrl.init = true;

	-- EventDelegate.Add(panelCtrl.noticeInput.onChange,EventDelegate.Callback(self.OnChangeLab,self))
end

function UIFamilyNoticeEditPanel:OnChangeLab()
	panelCtrl.noticeLabel.supportEncoding = true
end

--// 打开面板
function UIFamilyNoticeEditPanel:Open()
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.open = true;
end

--// 关闭面板
function UIFamilyNoticeEditPanel:Close()
	panelCtrl.panelObj:SetActive(false);
	panelCtrl.open = false;
end

--// 释放面板
function UIFamilyNoticeEditPanel:Dispose()
	panelCtrl.init = false;
end

--// 设置公告显示
function UIFamilyNoticeEditPanel:SetDataShow(noticeString)
	--panelCtrl.noticeLabel.text = noticeString;

	panelCtrl.noticeInput.value = noticeString;
	panelCtrl.noticeLabel.supportEncoding = true;
end

--// 点击提交按钮
function UIFamilyNoticeEditPanel:ClickOkBtn()
	local key2Tbl = {};
	local str2Tbl = {};

	local checkText = panelCtrl.noticeInput.value;
	local checkRetName, isIllegal = MaskWord.SMaskWord(checkText);
	if isIllegal == true then
		panelCtrl.noticeInput.value = checkRetName;
		panelCtrl.noticeLabel.supportEncoding = true;
		--UITip.Error("存在非法字符 ！！！ ");
		MsgBox.ShowYes("存在非法字符 ！！！");
	
		return;
	end

	key2Tbl[#key2Tbl + 1] = 101;
	str2Tbl[#str2Tbl + 1] = panelCtrl.noticeInput.value;
	panelCtrl.noticeLabel.supportEncoding = true;

	FamilyMgr:ReqFamilyConfig(true, false, nil, nil, key2Tbl, str2Tbl);
	-- UIFamilyNoticePanel:SetDataShow(panelCtrl.noticeInput.value);

	self:Close();
end
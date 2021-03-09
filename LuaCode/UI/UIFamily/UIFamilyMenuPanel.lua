--// 道庭弹出菜单
require("UI/UIFamily/UIMenuBtnItem")


UIFamilyMenuPanel = Super:New{Name = "UIFamilyMenuPanel"}


local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIFamilyMenuPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyMenuPanel create !!! ");

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 菜单面板物体
	panelCtrl.menuObj = T(panelCtrl.rootTrans, "MenuGrid");
	--// 弹出菜单按钮条目克隆主体
	panelCtrl.menuBtnMain = T(panelCtrl.rootTrans, "MenuGrid/Btn_99");

	--------- 获取控件 ---------

	local tip = "UI道庭成员弹出菜单"

	--// 关闭按钮
	local com = C(UIButton, panelCtrl.rootTrans, "Bg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:Close(); end;

	--// 排序控件
	panelCtrl.listGrid = C(UIGrid, panelCtrl.rootTrans, "MenuGrid", tip, false);


	--// 弹出按钮条目列表
	panelCtrl.btnItems = {};
	--// 关闭弹出菜单回调
	panelCtrl.closeCallBack = nil;

	panelCtrl.menuBtnMain:SetActive(false);

	panelCtrl.open = false;
	panelCtrl.init = true;
end

--// 打开
function UIFamilyMenuPanel:Open(closeCB)
	panelCtrl.closeCallBack = closeCB;

	panelCtrl.panelObj:SetActive(true);
	panelCtrl.open = true;
end

--// 关闭
function UIFamilyMenuPanel:Close()
	if panelCtrl.open == false then
		return;
	end

	panelCtrl.panelObj:SetActive(false);
	if panelCtrl.closeCallBack ~= nil then
		panelCtrl.closeCallBack();
	end
	panelCtrl.open = false;
	UIFamilyMemberPanel:UnSelMemberItem();
end

--// 释放
function UIFamilyMenuPanel:Dispose()
	for i = 1, #panelCtrl.btnItems do
		ObjPool.Add(panelCtrl.btnItems[i]);
	end
	panelCtrl.btnItems = {};

	panelCtrl.init = false;
end

--// 克隆弹出按钮
function UIFamilyMenuPanel:ClonePopBtn()
	local cloneObj = GameObject.Instantiate(panelCtrl.menuBtnMain);
	cloneObj.transform.parent = panelCtrl.menuBtnMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.menuBtnMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.menuBtnMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.menuBtnMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMenuBtnItem);
	cloneItem:Init(cloneObj);
	cloneObj.name = string.gsub(cloneObj.name, "99", tostring(#panelCtrl.btnItems + 1));
	panelCtrl.btnItems[#panelCtrl.btnItems + 1] = cloneItem;

	return cloneItem;
end

--// 重置帮派申请条目数量
function UIFamilyMenuPanel:RenewPopBtnNum(number)
	for a = 1, #panelCtrl.btnItems do
		panelCtrl.btnItems[a]:Show(false)
	end

	local realNum = number;
	if realNum < 0 then
		realNum = 0;
	end

	if realNum <= #panelCtrl.btnItems then
		for a = 1, realNum do
			panelCtrl.btnItems[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.btnItems do
			panelCtrl.btnItems[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.btnItems;
		for a = 1, needNum do
			self:ClonePopBtn();
		end
	end

	panelCtrl.listGrid:Reposition();
end

--// 重置菜单选项
function UIFamilyMenuPanel:SetAndLinkBtns(linkTbl)
	if linkTbl == nil or #linkTbl <= 0 then
		iError("LY", "Pop menu link table is null !!! ");
		return;
	end

	self:RenewPopBtnNum(#linkTbl);
	for i = 1, #linkTbl do
		panelCtrl.btnItems[i]:Link(linkTbl[i].showTxt, linkTbl[i].btnLinkEvent);
	end
end

--// 设置弹出菜单位置
function UIFamilyMenuPanel:SetMenuPos(xPos, yPos)
	if panelCtrl.menuObj == nil then
		iError("LY", "Menu object is null !!! ");
		return;
	end

	panelCtrl.menuObj.transform.localPosition = Vector3.New(xPos, yPos, 0);
end
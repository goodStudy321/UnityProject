--// 道庭成员面板
require("UI/UIFamily/UIFamilyMemberItem")
require("UI/UIFamily/UIFamilyMenuPanel")
require("UI/UIFamily/UIFamilyApplyListPanel")
require("UI/UIFamily/UIFamilyConfigPanel")

UIFamilyMemberPanel = Super:New{Name = "UIFamilyMemberPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 初始化面板
function UIFamilyMemberPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--iLog("LY", "UIFamilyMemberPanel create !!! ");

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 帮派成员条目克隆主体
	panelCtrl.memberInfoMain = T(panelCtrl.rootTrans, "ListCon/MemberSV/ListGrid/MemberItem_99");
	--// 申请列表面板
	panelCtrl.applyPanelObj = T(panelCtrl.rootTrans, "ApplyListPanel");
	--// 配置面板
	panelCtrl.configPanelObj = T(panelCtrl.rootTrans, "ConfigPanel");
	--// 申请列表按钮
	panelCtrl.applyListBtnObj = T(panelCtrl.rootTrans, "CtrlCon/ApplyListBtn");
	--// 帮派列表面板物体
	panelCtrl.quitBtnObj = T(panelCtrl.rootTrans, "CtrlCon/QuitBtn");

	--------- 获取控件 ---------

	local tip = "UI道庭成员面板"
	--// 滚动区域
	panelCtrl.memberInfoSV = C(UIScrollView, panelCtrl.rootTrans, "ListCon/MemberSV", tip, false);
	--// 排序控件
	panelCtrl.infoGrid = C(UIGrid, panelCtrl.rootTrans, "ListCon/MemberSV/ListGrid", tip, false);
	--// 退出按钮显示
	panelCtrl.quitLabel = C(UILabel, panelCtrl.rootTrans, "CtrlCon/QuitBtn/Label", tip, false);

	panelCtrl.upDownSign = {};
	panelCtrl.upDownSign[#panelCtrl.upDownSign + 1] = C(UISprite, panelCtrl.rootTrans, "TitleCon/Name1/UpDown", tip, false);
	panelCtrl.upDownSign[#panelCtrl.upDownSign + 1] = C(UISprite, panelCtrl.rootTrans, "TitleCon/Name2/UpDown", tip, false);
	panelCtrl.upDownSign[#panelCtrl.upDownSign + 1] = C(UISprite, panelCtrl.rootTrans, "TitleCon/Name3/UpDown", tip, false);
	panelCtrl.upDownSign[#panelCtrl.upDownSign + 1] = C(UISprite, panelCtrl.rootTrans, "TitleCon/Name4/UpDown", tip, false);
	-- panelCtrl.upDownSign[#panelCtrl.upDownSign + 1] = C(UISprite, panelCtrl.rootTrans, "TitleCon/Name5/UpDown", tip, false);
	panelCtrl.upDownSign[#panelCtrl.upDownSign + 1] = C(UISprite, panelCtrl.rootTrans, "TitleCon/Name6/UpDown", tip, false);
	panelCtrl.upDownSign[#panelCtrl.upDownSign + 1] = C(UISprite, panelCtrl.rootTrans, "TitleCon/Name7/UpDown", tip, false);

	--// 申请列表按钮
	UITool.SetBtnSelf(panelCtrl.applyListBtnObj, self.ClickApplyListBtn, self, self.Name);
	--// 退出道庭按钮
	UITool.SetBtnSelf(panelCtrl.quitBtnObj, self.ClickQuitFamilyBtn, self, self.Name);

	--// 初始化申请列表面板
	UIFamilyApplyListPanel:Init(panelCtrl.applyPanelObj);
	UIFamilyApplyListPanel:Close();
	--// 初始化配置面板
	UIFamilyConfigPanel:Init(panelCtrl.configPanelObj);
	UIFamilyConfigPanel:Close();

	panelCtrl.memberInfoMain:SetActive(false);

	UITool.SetBtnClick(panelCtrl.rootTrans, "TitleCon/Name1", tip, self.ClickDefSort, self);
	UITool.SetBtnClick(panelCtrl.rootTrans, "TitleCon/Name2", tip, self.ClickLvSort, self);
	--UITool.SetBtnClick(panelCtrl.rootTrans, "TitleCon/Name3", tip, self., self);
	UITool.SetBtnClick(panelCtrl.rootTrans, "TitleCon/Name4", tip, self.ClickTitleSort, self);
	-- UITool.SetBtnClick(panelCtrl.rootTrans, "TitleCon/Name5", tip, self.ClickConSort, self);
	UITool.SetBtnClick(panelCtrl.rootTrans, "TitleCon/Name6", tip, self.ClickPowerSort, self);
	UITool.SetBtnClick(panelCtrl.rootTrans, "TitleCon/Name7", tip, self.ClickOLSort, self);

	EventMgr.Add("NewFamilyMemberData", function ()
		self:ShowMemberData();
	end);

	panelCtrl.mDataList = nil;
	--// 道庭成员条目列表
	panelCtrl.memberItems = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;
	--// 当前列表页
	--panelCtrl.curMemberPage = 0;
	--// 当前选择的成员数据
	panelCtrl.curSelMemData = nil;
	--// 当前选择的条目
	panelCtrl.curSelMemItem = nil;

	--// 箭头索引标记
	--// 0：没被选择，1：降序，2升序
	panelCtrl.upDownIndex = {};
	panelCtrl.upDownIndex[1] = 0;
	panelCtrl.upDownIndex[2] = 0;
	panelCtrl.upDownIndex[3] = 0;
	panelCtrl.upDownIndex[4] = 0;
	panelCtrl.upDownIndex[5] = 0;
	panelCtrl.upDownIndex[6] = 0;
	-- panelCtrl.upDownIndex[7] = 0;

	panelCtrl.init = true;
	panelCtrl.isOpen = false;
end

--// 更新
function UIFamilyMemberPanel:Update()
	if panelCtrl.isOpen == false then
		return;
	end

	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.memberInfoSV:ResetPosition();
		end
	end

	UIFamilyConfigPanel:Update();
end

--// 打开
function UIFamilyMemberPanel:Open()
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.isOpen = true;

	if FamilyMgr:CanDealWithMember() == true then
		panelCtrl.applyListBtnObj:SetActive(true);
	else
		panelCtrl.applyListBtnObj:SetActive(false);
	end

	--panelCtrl.curMemberPage = 1;
	self:ShowMemberData();

	local memberData = FamilyMgr:GetCurMemberData();
	if memberData ~= nil then
		if memberData.title == 4 then
			--panelCtrl.quitLabel.text = "解散道庭";
			panelCtrl.quitLabel.text = "退出道庭";
		else
			panelCtrl.quitLabel.text = "退出道庭";
		end
	end

	UserMgr.eUpdateData["Add"](UserMgr.eUpdateData, self.UpdateChaData, self)
end

--// 关闭
function UIFamilyMemberPanel:Close()
	UserMgr.eUpdateData["Remove"](UserMgr.eUpdateData, self.UpdateChaData, self)

	panelCtrl.mDataList = nil;
	panelCtrl.panelObj:SetActive(false);
	panelCtrl.isOpen = false;
end

--// 销毁释放窗口
function UIFamilyMemberPanel:Dispose()
	UIFamilyApplyListPanel:Dispose();
	UIFamilyConfigPanel:Dispose();

	for i = 1, #panelCtrl.memberItems do
		ObjPool.Add(panelCtrl.memberItems[i]);
	end
	panelCtrl.memberItems ={};

	panelCtrl.init = false;
end

--// 重置所有箭头索引
function UIFamilyMemberPanel:ResetUpDownIndex()
	panelCtrl.upDownIndex[1] = 0;
	panelCtrl.upDownIndex[2] = 0;
	panelCtrl.upDownIndex[3] = 0;
	panelCtrl.upDownIndex[4] = 0;
	panelCtrl.upDownIndex[5] = 0;
	panelCtrl.upDownIndex[6] = 0;
	-- panelCtrl.upDownIndex[7] = 0;
end

--// 上下箭头显示
function UIFamilyMemberPanel:SetUpDownShow()
	panelCtrl.upDownSign[1].spriteName = "ty_11";
	panelCtrl.upDownSign[2].spriteName = "ty_11";
	panelCtrl.upDownSign[3].spriteName = "ty_11";
	panelCtrl.upDownSign[4].spriteName = "ty_11";
	panelCtrl.upDownSign[5].spriteName = "ty_11";
	panelCtrl.upDownSign[6].spriteName = "ty_11";
	-- panelCtrl.upDownSign[7].spriteName = "ty_11";

	if panelCtrl.upDownIndex[2] == 2 then
		panelCtrl.upDownSign[2].spriteName = "ty_13";
	elseif panelCtrl.upDownIndex[4] == 2 then
		panelCtrl.upDownSign[4].spriteName = "ty_13";
	elseif panelCtrl.upDownIndex[5] == 2 then
		panelCtrl.upDownSign[5].spriteName = "ty_13";
	elseif panelCtrl.upDownIndex[6] == 2 then
		panelCtrl.upDownSign[6].spriteName = "ty_13";
	-- elseif panelCtrl.upDownIndex[7] == 2 then
	-- 	panelCtrl.upDownSign[7].spriteName = "ty_13";
	end
end

--// 默认排序
function UIFamilyMemberPanel:ClickDefSort()
	if panelCtrl.mDataList == nil or #panelCtrl.mDataList < 2 then
		return;
	end

	self:ResetUpDownIndex();
	self:SetUpDownShow();

	table.sort(panelCtrl.mDataList, function(a, b)
		if a.isOnline == true and b.isOnline == false then
			return true;
		elseif a.isOnline == false and b.isOnline == true then
			return false;
		else
			if a.title ~= b.title then
				return a.title > b.title;
			elseif a.power ~= b.power then
				return a.power > b.power;
			else
				return a.roleId < b.roleId;
			end
		end
	end)

	for i = 1, #panelCtrl.mDataList do
		panelCtrl.memberItems[i]:ResetData(panelCtrl.mDataList[i]);
	end
end

--// 等级排序
function UIFamilyMemberPanel:ClickLvSort()
	if panelCtrl.mDataList == nil or #panelCtrl.mDataList < 2 then
		return;
	end

	if panelCtrl.upDownIndex[2] == 0 or panelCtrl.upDownIndex[2] == 2 then
		self:ResetUpDownIndex();
		panelCtrl.upDownIndex[2] = 1;

		table.sort(panelCtrl.mDataList, function(a, b)
			if a.roleLv ~= b.roleLv then
				return a.roleLv > b.roleLv;
			else
				return a.roleId < b.roleId;
			end
		end)
	else
		self:ResetUpDownIndex();
		panelCtrl.upDownIndex[2] = 2;

		table.sort(panelCtrl.mDataList, function(a, b)
			if a.roleLv ~= b.roleLv then
				return a.roleLv < b.roleLv;
			else
				return a.roleId < b.roleId;
			end
		end)
	end

	self:SetUpDownShow();
	for i = 1, #panelCtrl.mDataList do
		panelCtrl.memberItems[i]:ResetData(panelCtrl.mDataList[i]);
	end
end

--// 职务排序
function UIFamilyMemberPanel:ClickTitleSort()
	if panelCtrl.mDataList == nil or #panelCtrl.mDataList < 2 then
		return;
	end

	if panelCtrl.upDownIndex[4] == 0 or panelCtrl.upDownIndex[4] == 2 then
		self:ResetUpDownIndex();
		panelCtrl.upDownIndex[4] = 1;

		table.sort(panelCtrl.mDataList, function(a, b)
			if a.title ~= b.title then
				return a.title > b.title;
			else
				return a.roleId < b.roleId;
			end
		end)
	else
		self:ResetUpDownIndex();
		panelCtrl.upDownIndex[4] = 2;

		table.sort(panelCtrl.mDataList, function(a, b)
			if a.title ~= b.title then
				return a.title < b.title;
			else
				return a.roleId < b.roleId;
			end
		end)
	end

	self:SetUpDownShow();
	for i = 1, #panelCtrl.mDataList do
		panelCtrl.memberItems[i]:ResetData(panelCtrl.mDataList[i]);
	end
end

--// 道绩排序
-- function UIFamilyMemberPanel:ClickConSort()
-- 	if panelCtrl.mDataList == nil or #panelCtrl.mDataList < 2 then
-- 		return;
-- 	end

-- 	if panelCtrl.upDownIndex[5] == 0 or panelCtrl.upDownIndex[5] == 2 then
-- 		self:ResetUpDownIndex();
-- 		panelCtrl.upDownIndex[5] = 1;

-- 		table.sort(panelCtrl.mDataList, function(a, b)
-- 			if a.active ~= b.active then
-- 				return a.active > b.active;
-- 			else
-- 				return a.roleId < b.roleId;
-- 			end
-- 		end)
-- 	else
-- 		self:ResetUpDownIndex();
-- 		panelCtrl.upDownIndex[5] = 2;

-- 		table.sort(panelCtrl.mDataList, function(a, b)
-- 			if a.active ~= b.active then
-- 				return a.active < b.active;
-- 			else
-- 				return a.roleId < b.roleId;
-- 			end
-- 		end)
-- 	end

-- 	self:SetUpDownShow();
-- 	for i = 1, #panelCtrl.mDataList do
-- 		panelCtrl.memberItems[i]:ResetData(panelCtrl.mDataList[i]);
-- 	end
-- end

--// 战斗力排序
function UIFamilyMemberPanel:ClickPowerSort()
	if panelCtrl.mDataList == nil or #panelCtrl.mDataList < 2 then
		return;
	end

	if panelCtrl.upDownIndex[5] == 0 or panelCtrl.upDownIndex[5] == 2 then
		self:ResetUpDownIndex();
		panelCtrl.upDownIndex[5] = 1;

		table.sort(panelCtrl.mDataList, function(a, b)
			if a.power ~= b.power then
				return a.power > b.power;
			else
				return a.roleId < b.roleId;
			end
		end)
	else
		self:ResetUpDownIndex();
		panelCtrl.upDownIndex[5] = 2;

		table.sort(panelCtrl.mDataList, function(a, b)
			if a.power ~= b.power then
				return a.power < b.power;
			else
				return a.roleId < b.roleId;
			end
		end)
	end

	self:SetUpDownShow();
	for i = 1, #panelCtrl.mDataList do
		panelCtrl.memberItems[i]:ResetData(panelCtrl.mDataList[i]);
	end
end

--// 离线时间排序
function UIFamilyMemberPanel:ClickOLSort()
	if panelCtrl.mDataList == nil or #panelCtrl.mDataList < 2 then
		return;
	end

	if panelCtrl.upDownIndex[6] == 0 or panelCtrl.upDownIndex[6] == 2 then
		self:ResetUpDownIndex();
		panelCtrl.upDownIndex[6] = 1;

		table.sort(panelCtrl.mDataList, function(a, b)
			if a.isOnline ~= b.isOnline then
				if a.isOnline == true then
					return true;
				else
					return false;
				end
			elseif a.offTime ~= b.offTime then
				return a.offTime > b.offTime;
			else
				return a.roleId < b.roleId;
			end
		end)
	else
		self:ResetUpDownIndex();
		panelCtrl.upDownIndex[6] = 2;

		table.sort(panelCtrl.mDataList, function(a, b)
			if a.isOnline == true then
				return false;
			elseif b.isOnline == true then
				return true;
			elseif a.offTime ~= b.offTime then
				return a.offTime < b.offTime;
			else
				return a.roleId < b.roleId;
			end
		end)
	end

	self:SetUpDownShow();
	for i = 1, #panelCtrl.mDataList do
		panelCtrl.memberItems[i]:ResetData(panelCtrl.mDataList[i]);
	end
end

--// 点击申请列表按钮
function UIFamilyMemberPanel:ClickApplyListBtn()
	UIFamilyApplyListPanel:Open();
end

--// 刷新成员列表数据
function UIFamilyMemberPanel:ShowMemberData()
	if panelCtrl.isOpen == nil or panelCtrl.isOpen == false or FamilyMgr:JoinFamily() == false then
		return;
	end

	self:ResetUpDownIndex();

	local bInd = 1;
	local eInd = FamilyMgr:GetFamilyMemberNum();
	local dataList = FamilyMgr:GetFamilyMembersRange(bInd, eInd);

	if dataList == nil then
		--iError("LY", "No family member !!! ");
		return;
	end
	panelCtrl.mDataList = dataList;
	self:RenewMemberItemNum(#dataList);
	for i = 1, #dataList do
		panelCtrl.memberItems[i]:ResetData(dataList[i]);
	end
end

--// 克隆帮派成员条目
function UIFamilyMemberPanel:CloneMemberItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.memberInfoMain);
	cloneObj.transform.parent = panelCtrl.memberInfoMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.memberInfoMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.memberInfoMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.memberInfoMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIFamilyMemberItem);
	cloneItem:Init(cloneObj);
	-- cloneObj.name = string.gsub(cloneObj.name, "99", tostring(#panelCtrl.memberItems + 1));
	-- panelCtrl.memberItems[#panelCtrl.memberItems + 1] = cloneItem;

	local newName = "";
	if #panelCtrl.memberItems + 1 >= 100 then
		newName = string.gsub(panelCtrl.memberInfoMain.name, "99", tostring(#panelCtrl.memberItems + 1));
	elseif #panelCtrl.memberItems + 1 >= 10 then
		newName = string.gsub(panelCtrl.memberInfoMain.name, "99", "0"..tostring(#panelCtrl.memberItems + 1));
	else
		newName = string.gsub(panelCtrl.memberInfoMain.name, "99", "00"..tostring(#panelCtrl.memberItems + 1));
	end
	cloneObj.name = newName;
	panelCtrl.memberItems[#panelCtrl.memberItems + 1] = cloneItem;

	return cloneItem;
end

--// 重置帮派成员条目数量
function UIFamilyMemberPanel:RenewMemberItemNum(number)
	for a = 1, #panelCtrl.memberItems do
		panelCtrl.memberItems[a]:Show(false)
	end

	local realNum = number;
	if realNum < 0 then
		realNum = 0;
	end

	if realNum <= #panelCtrl.memberItems then
		for a = 1, realNum do
			panelCtrl.memberItems[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.memberItems do
			panelCtrl.memberItems[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.memberItems;
		for a = 1, needNum do
			self:CloneMemberItem();
		end
	end

	for i = 1, #panelCtrl.memberItems do
		if i % 2 == 0 then
			panelCtrl.memberItems[i]:BgShow(true);
		else
			panelCtrl.memberItems[i]:BgShow(false);
		end
	end

	panelCtrl.infoGrid:Reposition();
	--panelCtrl.memberInfoSV:ResetPosition();

	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIFamilyMemberPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end

--// 
function UIFamilyMemberPanel:SelMemberItem(memberData, item)
	self:UnSelMemberItem();
	panelCtrl.curSelMemData = memberData;
	panelCtrl.curSelMemItem = item;
	panelCtrl.curSelMemItem:SetSelectSign(true);

	local selfData = FamilyMgr:GetCurMemberData();
	--// 判断是否点击自己
	if memberData == nil or selfData == nil or memberData.roleId == selfData.roleId then
		return;
	end

	UIFamilyMenuPanel:Open();
	UIFamilyMenuPanel:SetAndLinkBtns(self:GroupMenuTbl(selfData.roleId, memberData.roleId, selfData.title, panelCtrl.curSelMemData.title));
	--UIFamilyMenuPanel:SetMenuPos(350, 190);
end

--// 
function UIFamilyMemberPanel:UnSelMemberItem()
	if panelCtrl.curSelMemItem ~= nil then
		panelCtrl.curSelMemItem:SetSelectSign(false);
	end
	panelCtrl.curSelMemData = nil;
	panelCtrl.curSelMemItem = nil;
end

--// 组合弹出菜单
function UIFamilyMemberPanel:GroupMenuTbl(selfRoleId, tarRoleId, selfTitle, targetTitle)

	if targetTitle == 5 then
		if selfRoleId == tarRoleId then
			return self:GroupMenuTblSelf(selfTitle, targetTitle);
		elseif selfTitle == 4 then
			return self:GroupMenuTblSAdmin(selfTitle, targetTitle);
		elseif selfTitle == 3 then
			return self:GroupMenuTblAdmin(selfTitle, targetTitle);
		else
			return self:GroupMenuTblNormal(selfTitle, targetTitle);
		end
	end

	if selfRoleId == tarRoleId then
		return self:GroupMenuTblSelf(selfTitle, targetTitle);
	elseif selfTitle == 1 or selfTitle <= targetTitle then
		return self:GroupMenuTblNormal(selfTitle, targetTitle);
	elseif selfTitle == 4 then
		return self:GroupMenuTblSAdmin(selfTitle, targetTitle);
	else
		return self:GroupMenuTblAdmin(selfTitle, targetTitle);
	end
	return nil;
end

--// 组合自己对自己的弹出菜单
function UIFamilyMemberPanel:GroupMenuTblSelf(selfTitle, targetTitle)
	local retTbl = {};

	-- local btnItem = {};
	-- btnItem.showTxt = "查看信息";
	-- btnItem.btnLinkEvent = function() self:ShowInfo(); end;
	-- retTbl[#retTbl + 1] = btnItem;

	return retTbl;
end



--// 组合庭主弹出菜单
function UIFamilyMemberPanel:GroupMenuTblSAdmin(selfTitle, targetTitle)
	local retTbl = {};
	
	local btnItem = {};
	btnItem.showTxt = "查看信息";
	btnItem.btnLinkEvent = function() self:ShowInfo(); end;
	retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "转让庭主";
	btnItem.btnLinkEvent = function()
		MsgBox.ShowYesNo("是否转让庭主？", function() self:ChangeMemberTitle(4); end, self);
	end;
	retTbl[#retTbl + 1] = btnItem;

	if targetTitle == 5 then
		btnItem = {};
		btnItem.showTxt = "晋升副庭主";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(3); end;
		retTbl[#retTbl + 1] = btnItem;

		btnItem = {};
		btnItem.showTxt = "降为长老";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(2); end;
		retTbl[#retTbl + 1] = btnItem;

		btnItem = {};
		btnItem.showTxt = "降为会员";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(1); end;
		retTbl[#retTbl + 1] = btnItem;

	elseif targetTitle == 3 then
		btnItem = {};
		btnItem.showTxt = "晋升人气甜心";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(5); end;
		retTbl[#retTbl + 1] = btnItem;

		btnItem = {};
		btnItem.showTxt = "降为长老";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(2); end;
		retTbl[#retTbl + 1] = btnItem;

		btnItem = {};
		btnItem.showTxt = "降为会员";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(1); end;
		retTbl[#retTbl + 1] = btnItem;

	elseif targetTitle == 2 then
		btnItem = {};
		btnItem.showTxt = "晋升副庭主";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(3); end;
		retTbl[#retTbl + 1] = btnItem;

		btnItem = {};
		btnItem.showTxt = "晋升人气甜心";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(5); end;
		retTbl[#retTbl + 1] = btnItem;

		btnItem = {};
		btnItem.showTxt = "降为会员";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(1); end;
		retTbl[#retTbl + 1] = btnItem;

	else
		btnItem = {};
		btnItem.showTxt = "晋升副庭主";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(3); end;
		retTbl[#retTbl + 1] = btnItem;

		btnItem = {};
		btnItem.showTxt = "晋升人气甜心";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(5); end;
		retTbl[#retTbl + 1] = btnItem;

		btnItem = {};
		btnItem.showTxt = "晋升长老";
		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(2); end;
		retTbl[#retTbl + 1] = btnItem;

	end

	-- btnItem = {};
	-- btnItem.showTxt = "送花";
	-- btnItem.btnLinkEvent = function()  end;
	-- retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "添加好友";
	btnItem.btnLinkEvent = function() self:ReqAddFriend() end;
	retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "邀请入队";
	btnItem.btnLinkEvent = function() self:ReqInviteTeam(); end;
	retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "申请入队";
	btnItem.btnLinkEvent = function() self:ReqTeamApply(); end;
	retTbl[#retTbl + 1] = btnItem;
	
	-- btnItem = {};
	-- btnItem.showTxt = "加入黑名单";
	-- btnItem.btnLinkEvent = function()  end;
	-- retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "踢出道庭";
	btnItem.btnLinkEvent = function() self:DismissCurSelMember(); end;
	retTbl[#retTbl + 1] = btnItem;
	
	return retTbl;
end

--// 组合管理者弹出菜单
function UIFamilyMemberPanel:GroupMenuTblAdmin(selfTitle, targetTitle)
	local retTbl = {};
	
	local btnItem = {};
	btnItem.showTxt = "查看信息";
	btnItem.btnLinkEvent = function() self:ShowInfo(); end;
	retTbl[#retTbl + 1] = btnItem;

	-- if selfTitle == 3 then
	-- 	if targetTitle == 2 then
	-- 		btnItem = {};
	-- 		btnItem.showTxt = "降为成员";
	-- 		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(1); end;
	-- 		retTbl[#retTbl + 1] = btnItem;
	-- 	elseif targetTitle == 1 then
	-- 		btnItem = {};
	-- 		btnItem.showTxt = "晋升长老";
	-- 		btnItem.btnLinkEvent = function() self:ChangeMemberTitle(2); end;
	-- 		retTbl[#retTbl + 1] = btnItem;
	-- 	end
	-- end

	-- btnItem = {};
	-- btnItem.showTxt = "送花";
	-- btnItem.btnLinkEvent = function()  end;
	-- retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "添加好友";
	btnItem.btnLinkEvent = function() self:ReqAddFriend() end;
	retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "邀请入队";
	btnItem.btnLinkEvent = function() self:ReqInviteTeam(); end;
	retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "申请入队";
	btnItem.btnLinkEvent = function() self:ReqTeamApply(); end;
	retTbl[#retTbl + 1] = btnItem;
	
	-- btnItem = {};
	-- btnItem.showTxt = "加入黑名单";
	-- btnItem.btnLinkEvent = function()  end;
	-- retTbl[#retTbl + 1] = btnItem;

	if selfTitle == 3 then
		if targetTitle == 2 or targetTitle == 1 then
			btnItem = {};
			btnItem.showTxt = "踢出道庭";
			btnItem.btnLinkEvent = function() self:DismissCurSelMember(); end;
			retTbl[#retTbl + 1] = btnItem;
		end
	end

	return retTbl;
end

--// 组合普通弹出菜单
function UIFamilyMemberPanel:GroupMenuTblNormal(selfTitle, targetTitle)
	local retTbl = {};
	
	local btnItem = {};
	btnItem.showTxt = "查看信息";
	btnItem.btnLinkEvent = function() self:ShowInfo(); end;
	retTbl[#retTbl + 1] = btnItem;

	-- btnItem = {};
	-- btnItem.showTxt = "送花";
	-- btnItem.btnLinkEvent = function()  end;
	-- retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "添加好友";
	btnItem.btnLinkEvent = function() self:ReqAddFriend() end;
	retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "邀请入队";
	btnItem.btnLinkEvent = function() self:ReqInviteTeam(); end;
	retTbl[#retTbl + 1] = btnItem;

	btnItem = {};
	btnItem.showTxt = "申请入队";
	btnItem.btnLinkEvent = function() self:ReqTeamApply(); end;
	retTbl[#retTbl + 1] = btnItem;
	
	-- btnItem = {};
	-- btnItem.showTxt = "加入黑名单";
	-- btnItem.btnLinkEvent = function()  end;
	-- retTbl[#retTbl + 1] = btnItem;
	
	return retTbl;
end

function UIFamilyMemberPanel:UpdateChaData()
	-- JumpMgr:InitJump(UIChat.Name,My.cTp)
    -- UIMgr.Close(UIChat.Name)
	UIMgr.Open(UIOtherInfoCPM.Name)
end


--// 查看信息
function UIFamilyMemberPanel:ShowInfo()
	if panelCtrl.curSelMemData == nil then
		iError("LY", "Select family member data is null !!! ");
		return;
	end

	UserMgr:ReqRoleObserve(panelCtrl.curSelMemData.roleId, false);
	UIFamilyMenuPanel:Close();
end

--// 变更成员职位
function UIFamilyMemberPanel:ChangeMemberTitle(titleType)
	if panelCtrl.curSelMemData == nil then
		iError("LY", "Select family member data is null !!! ");
		return;
	end

	FamilyMgr:ReqFamilyAdmin(panelCtrl.curSelMemData.roleId, titleType);
	UIFamilyMenuPanel:Close();
end

--// 添加好友
function UIFamilyMemberPanel:ReqAddFriend()
	if panelCtrl.curSelMemData == nil then
		iError("LY", "Select family member data is null !!! ");
		return;
	end

	FriendMgr:ReqAddFriend(panelCtrl.curSelMemData.roleId);
	UIFamilyMenuPanel:Close();
end

--// 邀请组队
function UIFamilyMemberPanel:ReqInviteTeam()
	TeamMgr:ReqInviteTeam(tostring(panelCtrl.curSelMemData.roleId));
end

--// 申请组队
function UIFamilyMemberPanel:ReqTeamApply()
	if TeamMgr.TeamInfo ~= nil and TeamMgr.TeamInfo.TeamId ~= nil then
		UITip.Log("已经拥有队伍 ！");
		return;
	end

	TeamMgr:ReqTeamApply(0, panelCtrl.curSelMemData.roleId);
	MsgBox.ShowYes("申请已经发送！");
end

--// 删除当前选择成员
function UIFamilyMemberPanel:DismissCurSelMember()
	if panelCtrl.curSelMemData == nil then
		iError("LY", "Select family member data is null !!! ");
		return;
	end

	FamilyMgr:ReqFamilyKick(panelCtrl.curSelMemData.roleId);
	UIFamilyMenuPanel:Close();
end

--// 点击退出帮派按钮
function UIFamilyMemberPanel:ClickQuitFamilyBtn()
	local warmStr = "确定";

	local memberData = FamilyMgr:GetCurMemberData();
	if memberData.title == 4 then
		--warmStr = StrTool.Concat(warmStr, "解散道庭");
		warmStr = StrTool.Concat(warmStr, "退出道庭");
	else
		warmStr = StrTool.Concat(warmStr, "退出道庭");
	end

	MsgBox.ShowYesNo(warmStr,self.ConfirmQuit,self,nil, nil ,self);
end

function UIFamilyMemberPanel:ConfirmQuit()
	FamilyMgr:ReqFamilyLeave();
	UIFamilyMenuPanel:Close();
end
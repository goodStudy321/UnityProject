--// 道庭申请条目
UIFamilyApplyItem = {Name = "UIFamilyApplyItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UIFamilyApplyItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFamilyApplyItem:Init(gameObj)
	-- if self.itemObj ~= nil then
	-- 	--print("LY : Family apply item has init !!! ");
	-- 	return;
	-- end

	local tip = "UI帮派申请条目"

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	self.bgObj = T(self.itemTrans, "Bg/Bg1");
	--// 同意按钮物体
	self.yesBtnObj = T(self.itemTrans, "Con5/YesBtn");
	--// 拒绝按钮物体
	self.noBtnObj = T(self.itemTrans, "Con5/NoBtn");

	self.nameLabel = C(UILabel, self.itemTrans, "Con1/Label", tip, false);
	self.lvLabel = C(UILabel, self.itemTrans, "Con2/Label", tip, false);
	self.categoryLabel = C(UILabel, self.itemTrans, "Con3/Label", tip, false);
	self.powerLabel = C(UILabel, self.itemTrans, "Con4/Label", tip, false);

	--// 同意按钮
	UITool.SetBtnSelf(self.yesBtnObj, self.ClickYesBtn, self, self.Name);
	--// 拒绝按钮
	UITool.SetBtnSelf(self.noBtnObj, self.ClickNoBtn, self, self.Name);

	--// 当前链接数据
	--[[
		self.curData.roleId				：角色Id
		self.curData.roleName			：角色名
		self.curData.lv 				：角色等级
		self.curData.category			：角色职业
		self.curData.power 				：角色战斗力
	]]
	self.curData = nil;
end

--// 显示隐藏
function UIFamilyApplyItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 刷新链接数据
--[[
	connetData.roleId			：角色Id
	connetData.roleName			：角色名
	connetData.roleLv 			：角色等级
	connetData.category			：角色职业
	connetData.power 			：角色战斗力
]]
function UIFamilyApplyItem:ResetData(connetData)
	if connetData == nil then
		return;
	end

	self.curData = connetData;

	self.nameLabel.text = self.curData.roleName;
	self.lvLabel.text = tostring(self.curData.roleLv);
	local catShow = FamilyMgr:GetJobByIndex(self.curData.sex + 1, 0);
	-- local catShow = FamilyMgr:GetJobByIndex(self.curData.sex + 1, self.curData.category);
	--local catShow = FamilyMgr:GetJobByIndex(self.curData.sex + 1, RebirthMsg.RbLev);
	self.categoryLabel.text = catShow;
	self.powerLabel.text = tostring(self.curData.power);
end

--// 点击同意按钮
function UIFamilyApplyItem:ClickYesBtn()
	if self.curData == nil then
		iError("LY", "Bad UIFamilyApplyItem !!! ")
		return;
	end

	FamilyMgr:AgreeFamilyApply(self.curData.roleId);
end

--// 点击拒绝按钮
function UIFamilyApplyItem:ClickNoBtn()
	if self.curData == nil then
		iError("LY", "Bad UIFamilyApplyItem !!! ")
		return;
	end

	FamilyMgr:RefuseFamilyApply(self.curData.roleId);
end

function UIFamilyApplyItem:ShowBg(show)
	self.bgObj:SetActive(show);
end
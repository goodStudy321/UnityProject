--// 道庭活动按钮
UIFGameBtnItem = {Name = "UIFGameBtnItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UIFGameBtnItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFGameBtnItem:Init(gameObj)
	local tip = "UI帮派活动按钮条目"

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	self.btnObj = T(self.itemTrans, "EnterBtn");
	-- self.lockSignObj = T(self.itemTrans, "LockSign");

	--------- 获取控件 ---------

	--// 点击按钮
	UITool.SetBtnSelf(self.btnObj, self.ClickSelf, self, self.Name);

	--// 点击自身回调
	self.clickCallBack = nil;
end

--// 点击
function UIFGameBtnItem:ClickSelf()
	if self.clickCallBack ~= nil then
		self.clickCallBack();
	end
end

--// 设置点击回调
function UIFGameBtnItem:SetClickCB(callback)
	self.clickCallBack = callback;
end

--// 设置特殊状态
-- function UIFGameBtnItem:SetLock(isLock)
-- 	if isLock == true then
-- 		self.lockSignObj:SetActive(false);
-- 	else
-- 		self.lockSignObj:SetActive(true);
-- 	end
-- end
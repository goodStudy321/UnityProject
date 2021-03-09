--// UI勾选框

UICheckBox = {Name = "UICheckBox"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UICheckBox:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;
	return o;
end

--// 初始化赋值
function UICheckBox:Init(gameObj, cEvnt)

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;
	self.checkEvnt = cEvnt;

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 勾选显示物体
	self.tickObj = T(self.itemTrans, "tick");

	local tip = "UI勾选框";

	--// 按钮控件
	self.btnCom = CGS(UIButton, self.itemTrans, tip);
	UIEvent.Get(self.btnCom.gameObject).onClick = function (gameObject)
		self:ClickSelf();
	end

	self.isTick = false;
end

--// 显示勾选标志
function UICheckBox:ShowTick(sOh)
	self.tickObj:SetActive(sOh);
end

--// 设置勾选
function UICheckBox:SetTick(istick)
	self.isTick = istick;
	self:ShowTick(istick);
end

--// 点击自己
function UICheckBox:ClickSelf()
	if self.isTick == true then
		self:SetTick(false);
	else
		self:SetTick(true);
	end

	if self.checkEvnt ~= nil then
		self.checkEvnt(self.isTick);
	end
end
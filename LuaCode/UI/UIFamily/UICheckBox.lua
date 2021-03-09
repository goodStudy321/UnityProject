--// 通用勾选框

UICheckBox = {}

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
function UICheckBox:Init(gameObj)
	if self.itemObj ~= nil then
		--print("LY : UICheckBox has init !!! ");
		return;
	end

	local tip = "UI勾选框";

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	self.checkSign = T(self.itemTrans, "Check");
end

--// 设置勾选
function UICheckBox:SetCheck(isCheck)
	self.checkSign:SetActive(isCheck);
end
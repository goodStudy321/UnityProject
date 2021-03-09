--// 文案输入条目

UIFTextInputItem = {Name = "UIFTextInputItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 创建条目
function UIFTextInputItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFTextInputItem:Init(gameObj)

	local tip = "UI文案输入条目"

	--// 条目物体
	self.itemObj = gameObj;
	--// 条目transform
	self.rootTrans = self.itemObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 条目名称
	self.nameL = C(UILabel, self.rootTrans, "ContName", tip, false);
	--// 文案显示
	self.textL = C(UILabel, self.rootTrans, "TBg/TextLabel", tip, false);
end

--// 显示隐藏
function UIFTextInputItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 设置内容
function UIFTextInputItem:SetText(setText)
	self.textL.text = tostring(setText);
end

--// 返回当前输入文案
function UIFTextInputItem:GetInputText()
	return self.textL.text;
end
--// 数值输入条目

UIFNumInputItem = {Name = "UIFNumInputItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 创建条目
function UIFNumInputItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFNumInputItem:Init(gameObj)

	local tip = "UI数值输入条目"

	--// 条目物体
	self.itemObj = gameObj;
	--// 条目transform
	self.rootTrans = self.itemObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 条目名称
	self.nameL = C(UILabel, self.rootTrans, "ContName", tip, false);
	--// 数值显示
	self.numberL = C(UILabel, self.rootTrans, "InputBg/ShowL", tip, false);
	--// UIInput
	self.inputCom = C(UIInput, self.rootTrans, "InputBg", tip, false);

	--// 减少按钮
	local com = C(UIButton, self.rootTrans, "M", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickM();
	end;

	--// 增加按钮
	com = C(UIButton, self.rootTrans, "P", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickP();
	end;

	--// 输入框
	--EventDelegate.Add(self.inputCom.onChange, EventDelegate.Callback(self.NumberChange, self));
	self.OnNewData = EventDelegate.Callback(self.NumberChange, self);
	EventDelegate.Add(self.inputCom.onChange, self.OnNewData);


	--// 溢出回调(参数1: 0、下限溢出，1、上限溢出
	--//         参数2: 限界数值)
	self.overFlowCb = nil;
	self.hasMin = false;
	self.minVal = 0;
	self.hasMax = false;
	self.maxVal = 0;
	self.moneyType = 0;
end

function UIFNumInputItem:Dispose()
	EventDelegate.Remove(self.inputCom.onChange, self.OnNewData);
end

function UIFNumInputItem:Reset()
	self.overFlowCb = nil;
	self.hasMin = false;
	self.minVal = 0;
	self.hasMax = false;
	self.maxVal = 0;
	self.moneyType = 0;
end

--// 显示隐藏
function UIFNumInputItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 设置界限
function UIFNumInputItem:SetBound(hasMin, min, hasMax, max, overCb)
	self.hasMin = hasMin;
	self.minVal = min;
	self.hasMax = hasMax;
	self.maxVal = max;

	self.overFlowCb = overCb;
end

--// 设置数值
function UIFNumInputItem:SetNumber(setNum, monType)
	-- self.numberL.text = tostring(setNum);
	-- self.inputCom.defaultText = tostring(setNum);
	-- if defNum ~= nil then
	-- 	--self.inputCom.defaultText = tostring(defNum);
	-- 	self.inputCom.value = tostring(defNum);
	-- end

	self.inputCom.value = tostring(setNum);
	self.moneyType = monType;
end

--// 返回当前输入数值
function UIFNumInputItem:GetInputNumber()
	-- local numStr = self.numberL.text;
	-- return tonumber(numStr);

	local numStr = self.inputCom.value;
	local retNum = tonumber(numStr);
	if retNum == nil then
		retNum = 0
	end

	return retNum;
end

--// 点击减少按钮
function UIFNumInputItem:ClickM()
	local num = self:GetInputNumber();

	num = num - 1;
	if self.hasMin == true and num < self.minVal then
		num = self.minVal;
		if self.overFlowCb ~= nil then
			self.overFlowCb(0, self.minVal, self.moneyType);
		end
		return;
	end

	self:SetNumber(num, self.moneyType);
end

--// 点击增加按钮
function UIFNumInputItem:ClickP()
	local num = self:GetInputNumber();

	num = num + 1;
	if self.hasMax == true and num > self.maxVal then
		num = self.maxVal;
		if self.overFlowCb ~= nil then
			self.overFlowCb(1, self.maxVal, self.moneyType);
		end
		return;
	end

	self:SetNumber(num, self.moneyType);
end

--// 输入数值变化
function UIFNumInputItem:NumberChange()
	local checkNum = self:GetInputNumber();

	if self.hasMin == true then
		if checkNum < self.minVal then
			self:SetNumber(self.minVal, self.moneyType);
			if self.overFlowCb ~= nil then
				self.overFlowCb(0, self.minVal, self.moneyType);
			end
		end
	end

	if self.hasMax == true then
		if checkNum > self.maxVal then
			self:SetNumber(self.maxVal, self.moneyType)
			if self.overFlowCb ~= nil then
				self.overFlowCb(1, self.maxVal, self.moneyType);
			end
		end
	end
end
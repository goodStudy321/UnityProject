--// UI通用文本条目

UITextBox = {Name = "UITextBox"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UITextBox:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;
	return o;
end

--// 初始化赋值
function UITextBox:Init(gameObj)

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;

	self.labels = {};
end

--// 链接控件
function UITextBox:LinkItem(labelTexts, btnIndexs, cEvns)

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	local tip = "UI勾选框";
	
	local labelNum = #labelTexts;
	--// 文本框集合
	self.labels = {};
	for i = 1, labelNum do
		self.labels[#self.labels + 1] = C(UILabel, self.itemTrans, "Label"..tostring(i), tip, false);
		self.labels[i].text = labelTexts[i];
	end

	if btnIndexs ~= nil then
		self.btns = {};
		for i = 1, #btnIndexs do
			self.btns[#self.btns + 1] = C(UIButton, self.itemTrans, "Label"..tostring(btnIndexs[i]), tip, false);
			UIEvent.Get(self.btns[#self.btns].gameObject).onClick = cEvns[i];
		end
	end
end

--// 显示
function UITextBox:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 显示数据
function UITextBox:ShowData(dataList)
	for i = 1, #dataList do
		self.labels[i].text = dataList[i];
	end
end
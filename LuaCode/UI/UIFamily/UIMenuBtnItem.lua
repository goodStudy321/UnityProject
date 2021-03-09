--// 弹出菜单按钮条目

UIMenuBtnItem = {Name = "UIMenuBtnItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UIMenuBtnItem:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;
	return o;
end

--// 初始化赋值
function UIMenuBtnItem:Init(gameObj)

	local tip = "UI弹出菜单按钮";

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;
	self.btnEvent = nil;

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	self.btnCom = CGS(UIButton, self.itemTrans, tip);

	self.showText = C(UILabel, self.itemTrans, "Label", tip, false);
end

--// 链接按钮
function UIMenuBtnItem:Link(showTxt, btnLinkEvent)
	self.showText.text = showTxt;
	self.btnEvent = btnLinkEvent;
	
	UIEvent.Get(self.btnCom.gameObject).onClick = function (gameObject)
		if self.btnEvent ~= nil then
			self.btnEvent();
		end
	end;
end

--// 
function UIMenuBtnItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end
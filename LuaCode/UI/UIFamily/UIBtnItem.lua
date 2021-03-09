--// 通用按钮条目

UIBtnItem = {Name = "UIBtnItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UIBtnItem:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;
	return o;
end

--// 初始化赋值
--// iconComName：图标路径，查找图标控件，如果为空则不设置图标
--// iconName：图标名称，设置图标的图片
function UIBtnItem:Init(gameObj, btnLinkEvent, iconComName, iconName)
	
	local tip = "UI按钮条目";

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;
	self.btnEvent = btnLinkEvent;

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	self.selSign = T(self.itemTrans, "SelSign");

	self.btnNameL = C(UILabel, self.itemTrans, "BtnName", tip, false);

	if iconComName ~= nil and iconComName ~= "" then
		self.icon = C(UISprite, self.itemTrans, iconComName, tip, false);
		self.icon.spriteName = iconName;
	end

	local com = CGS(UIButton, self.itemTrans, tip);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickBtn();
	end;
end

--// 设置显示
function UIBtnItem:Show(isShow)
	self.itemObj:SetActive(isShow);
end

--// 设置选择标志
function UIBtnItem:SetSelect(isSel)
	self.selSign:SetActive(isSel);
end

--// 点击按钮
function UIBtnItem:ClickBtn()
	if self.btnEvent ~= nil then
		self.btnEvent();
	end
end

--// 设置
function UIBtnItem:SetClickEvent(btnLinkEvent)
	self.btnEvent = btnLinkEvent;
end

--// 设置按钮名称
function UIBtnItem:SetBtnName(btnName)
	-- if self.btnNameL ~= nil then
	-- 	self.btnNameL.text = btnName;
	-- 	return;
	-- end

	-- local tip = "UI按钮条目";
	-- local C = ComTool.Get;
	-- self.btnNameL = C(UILabel, self.itemTrans, "BtnName", tip, false);

	self.btnNameL.text = btnName;
end

--// 查找图标控件和设置显示图标
function UIBtnItem:FindAndSetIcon(iconComName, iconName)
	if iconComName ~= nil and iconComName ~= "" then
		local C = ComTool.Get;
		self.icon = C(UISprite, self.itemTrans, iconComName, tip, false);
		self.icon.spriteName = iconName;
	end
end

--// 设置显示图标
function UIBtnItem:SetIcon(iconName)
	if self.icon == nil then
		return;
	end

	self.icon.spriteName = iconName;
end
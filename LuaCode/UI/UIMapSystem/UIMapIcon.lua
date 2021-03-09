--// 地图图标
UIMapIcon = {Name = "UIMapIcon"};

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 创建按钮
function UIMapIcon:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIMapIcon:Init(gameObj, canSel, clickEvnt)

	local tip = "UI地图图标"

	--// 按钮物体
	self.iconObj = gameObj;
	--// 面板transform
	self.rootTrans = self.iconObj.transform;
	--// 是否可以选择
	self.canSel = canSel;
	--// 按钮索引
	self.clickEvnt = clickEvnt;

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 上锁标志
	self.lockSignObj = T(self.rootTrans, "Lock");
	--// 选择标志
	self.selSignObj = T(self.rootTrans, "SelSign");
	self.bgObj = T(self.rootTrans, "Bg");

	--// 图标名称
	self.nameLb = C(UILabel, self.rootTrans, "Name", tip, false);

	--// self按钮
	local com = CF(UIButton, self.rootTrans, tip);
	UIEvent.Get(com.gameObject).onClick = function(gameObject) self:ClickSelf(); end;

	--// 当前是否选择
	self.isSel = false;

	self:Reset();
end

--// 
function UIMapIcon:Reset()
	self:SetLock(true);
	self:SetSel(false);
end

--// 显示数据
function UIMapIcon:ShowData(showData, showName)
	self.nameLb.text = showData.name;
	if showName == nil or showName == true then
		self.nameLb.gameObject:SetActive(true);
		self.bgObj:SetActive(true);
	else
		self.nameLb.gameObject:SetActive(false);
		self.bgObj:SetActive(false);
	end
	self.rootTrans.localPosition = showData.mapPos;
	if showData.unlock == true then
		self:SetLock(false);
	else
		self:SetLock(true);
	end
	
end

--// 显示隐藏
function UIMapIcon:Show(sOh)
	self.iconObj:SetActive(sOh);
end

--// 设置上锁
function UIMapIcon:SetLock(isLock)
	self.lockSignObj:SetActive(isLock);
end

--// 设置选择显示
function UIMapIcon:SetSel(isSel)
	self.selSignObj:SetActive(isSel);
end

--// 设置回调事件
function UIMapIcon:SetEvnt(cbEvnt)
	self.clickEvnt = cbEvnt;
end

--// 点击自身
function UIMapIcon:ClickSelf()
	if self.canSel ~= nil and self.canSel == true then
		if self.isSel == false then
			self.isSel = true;
		else
			self.isSel = false;
		end

		self:SetSel(self.isSel);
	end

	if self.clickEvnt ~= nil then
		self.clickEvnt = nil;
	end
end
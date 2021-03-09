--// UI下拉菜单
require("UI/UIFamily/UIBtnItem");


UIPopMenu = {Name = "UIPopMenu"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UIPopMenu:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;
	return o;
end

--// 初始化赋值
function UIPopMenu:Init(gameObj, btnNum, cEvnt)

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;
	self.checkEvnt = cEvnt;

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 下三角
	self.closeT = T(self.itemTrans, "downT");
	--// 上三角
	self.openT = T(self.itemTrans, "upT");
	--// 按钮框体
	self.btnsCont = T(self.itemTrans, "PopPart");


	local tip = "UI下拉菜单";

	--// 按钮控件
	local com = CGS(UIButton, self.itemTrans, tip);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickSelf(); end

	self.btnObjs = {};
	self.menuBtns = {};
	if btnNum ~= nil and btnNum > 0 then
		for i = 1, btnNum do
			self.btnObjs[i] = T(self.itemTrans, "PopPart/Btn"..(i - 1));
			self.menuBtns[i] = ObjPool.Get(UIBtnItem);
			self.menuBtns[i]:Init(self.btnObjs[i], function()
				self:ClickMenuBtn(i - 1);
			end);
		end
	end

	--// 关闭弹出菜单
	com = C(UIButton, self.itemTrans, "PopPart/MaskBg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:CloseMenu(); end;

	--// 是否打开下拉菜单
	self.openMenu = false;
	--// 当前点击序列
	self.curClickIndex = 0;
end

--// 销毁释放
function UIPopMenu:Dispose()
	for i = 1, #self.menuBtns do
		ObjPool.Add(self.menuBtns[i]);
	end
	self.menuBtns ={};
	self.btnObjs = {};
end

function UIPopMenu:Reset()
	self.openMenu = false;
	self.curClickIndex = 1;

	self.closeT:SetActive(true);
	self.openT:SetActive(false);
	self.btnsCont:SetActive(false);
end

--// 打开下拉菜单
function UIPopMenu:OpenMenu()
	self.openMenu = true;

	self.closeT:SetActive(false);
	self.openT:SetActive(true);
	self.btnsCont:SetActive(true);
end

--// 隐藏下拉菜单
function UIPopMenu:CloseMenu()
	self.openMenu = false;

	self.closeT:SetActive(true);
	self.openT:SetActive(false);
	self.btnsCont:SetActive(false);
end

--// 点击自己
function UIPopMenu:ClickSelf()
	if self.openMenu == true then
		self:CloseMenu();
	else
		self:OpenMenu();
	end
end

--// 点击菜单按钮
function UIPopMenu:ClickMenuBtn(btnIndex)
	self:SynBtnIndexShow(btnIndex);
	if self.checkEvnt ~= nil then
		self.checkEvnt(btnIndex);
	end

	self:CloseMenu();
end

--// 
function UIPopMenu:SynBtnIndexShow(btnIndex)
	self.curClickIndex = btnIndex;
	for i = 1, #self.menuBtns do
		if self.curClickIndex == i - 1 then
			self.menuBtns[i]:SetSelect(true);
		else
			self.menuBtns[i]:SetSelect(false);
		end
	end
end
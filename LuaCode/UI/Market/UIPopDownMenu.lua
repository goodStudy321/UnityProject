--// 新UI下拉菜单
require("UI/UIFamily/UIBtnItem");


UIPopDownMenu = {Name = "UIPopDownMenu"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

local MAX_SHOW_BTN_NUM = 4;

--// 创建条目
function UIPopDownMenu:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;
	return o;
end

--// 初始化赋值
function UIPopDownMenu:Init(gameObj, btnName, btnNames, btnH, cEvnt, svVer, iconComPath, iconNames)

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;
	self.checkEvnt = cEvnt;
	--// 单个按钮高度间隔
	self.btnHeight = btnH;
	--// 是否有滚动框
	self.svVer = false;
	if svVer == true then
		self.svVer = true;
	end

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 按钮克隆主体
	if self.svVer == true then
		self.btnMain = T(self.itemTrans, "PopPart/BtnSV/Grid/Btn_99");
	else
		self.btnMain = T(self.itemTrans, "PopPart/Grid/Btn_99");
	end

	--// 下三角
	self.closeT = T(self.itemTrans, "downT");
	--// 上三角
	self.openT = T(self.itemTrans, "upT");
	--// 按钮框体
	self.btnsCont = T(self.itemTrans, "PopPart");

	local tip = "UI下拉菜单";

	--// 排序控件
	if self.svVer == true then
		self.btnGrid = C(UIGrid, self.itemTrans, "PopPart/BtnSV/Grid", tip, false);
	else
		self.btnGrid = C(UIGrid, self.itemTrans, "PopPart/Grid", tip, false);
	end
	--// 下拉菜单名称
	self.popName = C(UILabel, self.itemTrans, "PopName", tip, false);
	--// 背景
	self.bgSprite = C(UISprite, self.itemTrans, "PopPart/PopBg", tip, false);
	

	--// 按钮控件
	local com = CGS(UIButton, self.itemTrans, tip);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickSelf(); end

	--// 关闭弹出菜单
	com = C(UIButton, self.itemTrans, "PopPart/MaskBg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:CloseMenu(); end;

	--// 下拉菜单初始化
	self.BtnNames = btnNames;
	self.menuBtns = {};
	if btnNames ~= nil and #btnNames > 0 then
		self:RenewItemNum(#btnNames);
	else
		self:RenewItemNum(0);
	end
	
	for i = 1, #btnNames do
		self.menuBtns[i]:SetBtnName(btnNames[i]);
		self.menuBtns[i]:SetClickEvent(function()
			self:ClickMenuBtn(i - 1);
		end);
	end

	self.defaultName = btnName;
	if btnName ~= nil then
		self.popName.text = btnName;
	else
		self.defaultName = "";
	end

	if btnNames ~= nil then
		if self.svVer == true then
			self.bgSprite.height = self.btnHeight * MAX_SHOW_BTN_NUM;
		else
			self.bgSprite.height = self.btnHeight * #btnNames;
		end
	end

	--// 图标路径
	self.iconComPath = iconComPath;
	--// 图标名称
	self.iconNames = iconNames;

	if self.iconComPath ~= nil then
		for i = 1, #self.BtnNames do
			self.menuBtns[i]:FindAndSetIcon(self.iconComPath, self.iconNames[i]);
		end
	end

	self.closeT:SetActive(true);
	self.openT:SetActive(false);
	self.btnsCont:SetActive(false);

	--// 是否打开下拉菜单
	self.openMenu = false;
	--// 当前点击序列
	self.curClickIndex = 0;
end


-- 改变位置
function UIPopDownMenu:ChgPopPartY()
	local trans = self.btnsCont.transform
	trans.localPosition = Vector3.New(0,202,0)
end

--// 销毁释放
function UIPopDownMenu:Dispose()
	local trans = self.btnsCont.transform
	trans.localPosition = Vector3.New(0,0,0)
	self.checkEvnt = nil;
	if not self.menuBtns then return end
	for i = 1, #self.menuBtns do
		ObjPool.Add(self.menuBtns[i]);
	end
	self.menuBtns ={};
end

function UIPopDownMenu:Reset()
	self.openMenu = false;
	self.curClickIndex = 1;

	self.closeT:SetActive(true);
	self.openT:SetActive(false);
	self.btnsCont:SetActive(false);
end

--// 打开下拉菜单
function UIPopDownMenu:OpenMenu()
	self.openMenu = true;

	self.closeT:SetActive(false);
	self.openT:SetActive(true);
	self.btnsCont:SetActive(true);

	self.btnGrid:Reposition();
end

--// 隐藏下拉菜单
function UIPopDownMenu:CloseMenu()
	self.openMenu = false;

	self.closeT:SetActive(true);
	self.openT:SetActive(false);
	self.btnsCont:SetActive(false);
end

--// 点击自己
function UIPopDownMenu:ClickSelf()
	if self.openMenu == true then
		self:CloseMenu();
	else
		self:OpenMenu();
	end
end

--// 点击菜单按钮
function UIPopDownMenu:ClickMenuBtn(btnIndex)
	self:SynBtnIndexShow(btnIndex);
	if self.checkEvnt ~= nil then
		self.checkEvnt(btnIndex);
	end

	self:CloseMenu();
end

--// 
function UIPopDownMenu:SynBtnIndexShow(btnIndex)
	self.curClickIndex = btnIndex;

	if self.curClickIndex == 0 then
		if self.defaultName ~= nil and self.defaultName ~= "" then
			self.popName.text = self.defaultName;
		end
	else
		self.popName.text = self.BtnNames[btnIndex + 1];
	end

	for i = 1, #self.menuBtns do
		if self.curClickIndex == i - 1 then
			self.menuBtns[i]:SetSelect(true);
		else
			self.menuBtns[i]:SetSelect(false);
		end
	end
end

--// 克隆按钮条目
function UIPopDownMenu:CloneBtn()
	local cloneObj = GameObject.Instantiate(self.btnMain);
	cloneObj.transform.parent = self.btnMain.transform.parent;
	cloneObj.transform.localPosition = self.btnMain.transform.localPosition;
	cloneObj.transform.localRotation = self.btnMain.transform.localRotation;
	cloneObj.transform.localScale = self.btnMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneBtn = ObjPool.Get(UIBtnItem);
	cloneBtn:Init(cloneObj);

	local newName = "";
	if #self.menuBtns + 1 >= 100 then
		newName = string.gsub(self.btnMain.name, "99", tostring(#self.menuBtns + 1));
	elseif #self.menuBtns + 1 >= 10 then
		newName = string.gsub(self.btnMain.name, "99", "0"..tostring(#self.menuBtns + 1));
	else
		newName = string.gsub(self.btnMain.name, "99", "00"..tostring(#self.menuBtns + 1));
	end
	cloneObj.name = newName;

	self.menuBtns[#self.menuBtns + 1] = cloneBtn;

	return cloneItem;
end

--// 重置按钮数量
function UIPopDownMenu:RenewItemNum(number)
	for a = 1, #self.menuBtns do
		self.menuBtns[a]:Show(false)
	end
	local realNum = number;
	if realNum <= #self.menuBtns then
		for a = 1, realNum do
			self.menuBtns[a]:Show(true);
		end
	else
		for a = 1, #self.menuBtns do
			self.menuBtns[a]:Show(true)
		end

		local needNum = realNum - #self.menuBtns;
		for a = 1, needNum do
			self:CloneBtn();
		end
	end

	self.btnGrid:Reposition();
end

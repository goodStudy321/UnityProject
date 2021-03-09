--// 玩家获得红包信息条目

UIFGetRedPItem = {Name = "UIFGetRedPItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;
local AssetMgr = Loong.Game.AssetMgr;


--// 创建条目
function UIFGetRedPItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFGetRedPItem:Init(gameObj)

	local tip = "UI玩家获得红包信息条目"

	--// 条目物体
	self.itemObj = gameObj;
	--// 条目transform
	self.rootTrans = self.itemObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	self.bgSign = T(self.rootTrans, "Bg1");
	--// 元宝标志
	self.goldSign = T(self.rootTrans, "GoldSign");
	--// 绑定元宝标志
	self.bindGoldSign = T(self.rootTrans, "BindGoldSign");


	--// 玩家头像
	self.playerIcon = C(UISprite, self.rootTrans, "Icon", tip, false);
	--// 玩家名字
	self.nameL = C(UILabel, self.rootTrans, "Name", tip, false);
	--// 领取数量
	self.numL = C(UILabel, self.rootTrans, "Number", tip, false);
end

--// 显示隐藏
function UIFGetRedPItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 设置装饰显示
function UIFGetRedPItem:SetBgOn(bgOn)
	self.bgSign:SetActive(bgOn);
end

--// 显示条目内容
function UIFGetRedPItem:ShowData(iconName, pName, rpNum, bindGold)
	self:SetIcon(iconName);
	self.nameL.text = pName;
	self.numL.text = tostring(rpNum);

	if bindGold == false then
		self.goldSign:SetActive(true);
		self.bindGoldSign:SetActive(false);
	else
		self.goldSign:SetActive(false);
		self.bindGoldSign:SetActive(true);
	end
end

--// 设置图标
function UIFGetRedPItem:SetIcon(iconName)
	if iconName == nil or iconName == "" then
		return;
	end

	self.playerIcon.spriteName = iconName;
	--AssetMgr.Instance:Load(iconName, ObjHandler(self.LoadIconFin,self));
end

--// 读取图标完成
-- function UIFGetRedPItem:LoadIconFin(obj)
-- 	self.playerIcon.mainTexture = obj;
-- end
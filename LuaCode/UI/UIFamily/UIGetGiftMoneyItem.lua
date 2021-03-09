--// 玩家获得红包信息条目
UIGetGiftMoneyItem = {Name = "UIGetGiftMoneyItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;
local AssetMgr = Loong.Game.AssetMgr;


--// 创建条目
function UIGetGiftMoneyItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIGetGiftMoneyItem:Init(gameObj)

	local tip = "UI玩家获得红包信息条目"

	--// 条目物体
	self.itemObj = gameObj;
	--// 条目transform
	self.rootTrans = self.itemObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 元宝标志
	self.goldSign = T(self.rootTrans, "GoldSign");
	--// 绑定元宝标志
	self.bindGoldSign = T(self.rootTrans, "BindGoldSign");

	--//银两标志
	self.silverSign = T(self.rootTrans, "SilverSign");

	--// 玩家头像
	self.playerIcon = C(UISprite, self.rootTrans, "IconBg/Icon", tip, false);
	--// 玩家名字
	self.nameL = C(UILabel, self.rootTrans, "Name", tip, false);
	--// 领取数量
	self.numL = C(UILabel, self.rootTrans, "Number", tip, false);
end

--// 显示隐藏
function UIGetGiftMoneyItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 显示条目内容
function UIGetGiftMoneyItem:ShowData(iconName, pName, rpNum, bindGold, isSelf, isSilver)
	self:SetIcon(iconName);
	local showName = "";
	if isSelf == true then
		showName = StrTool.Concat("[00FF00FF]", pName, "[-]");
	else
		showName = StrTool.Concat("[F4DDBDFF]", pName, "[-]");
	end
	self.nameL.text = showName;

	
	if isSilver then
		local num = rpNum;
		local str = tostring(num);
		if num > 10000 then
			local y, yy = math.modf(num/10000);
			local text = yy < 0.1 and y or string.format("%.1f",num/10000);		
			str = StrTool.Concat(tostring(text), "W");
		end
		self.numL.text = tostring(str);
	else
		self.numL.text = tostring(rpNum);
	end

	if bindGold == false then
		self.goldSign:SetActive(true);
		self.bindGoldSign:SetActive(false);
		self.silverSign:SetActive(false);
	else
		self.goldSign:SetActive(false);
		self.bindGoldSign:SetActive(true);
		self.silverSign:SetActive(false);
	end
	if isSilver then
		self.goldSign:SetActive(false);
		self.bindGoldSign:SetActive(false);
		self.silverSign:SetActive(true);
	end
	
end

--// 设置图标
function UIGetGiftMoneyItem:SetIcon(iconName)
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
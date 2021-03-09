--// 道庭红包条目

UIFRedPacketItem = {Name = "UIFRedPacketItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;
local AssetMgr = Loong.Game.AssetMgr;


--// 创建条目
function UIFRedPacketItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFRedPacketItem:Init(gameObj)

	local tip = "UI道庭红包条目"

	--// 条目物体
	self.itemObj = gameObj;
	--// 条目transform
	self.rootTrans = self.itemObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;


	--// 发送按钮物体
	self.giveBtnObj = T(self.rootTrans, "GiveBtn");
	--// 领取按钮物体
	self.getBtnObj = T(self.rootTrans, "GetBtn");
	--// 领取标志
	self.getSignObj = T(self.rootTrans, "HasGotSign");
	--// 领完标志
	self.finSignObj = T(self.rootTrans, "FinGotSign");
	--// 查看按钮
	self.checkBtnObj = T(self.rootTrans, "CheckBtn");
	--// 头像图标
	self.IconObj = T(self.rootTrans, "p_icon_bg");


	--// 玩家名字
	self.nameL = C(UILabel, self.rootTrans, "Name", tip, false);
	--// 玩家头像
	self.iconTex = C(UITexture, self.rootTrans, "p_icon_bg/PIcon", tip, false);
	--// 信息描述
	self.infoL = C(UILabel, self.rootTrans, "Text", tip, false);


	--// 发送红包按钮
	local com = C(UIButton, self.rootTrans, "GiveBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickGiveBtn();
	end;

	com = C(UIButton, self.rootTrans, "GetBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickGetBtn();
	end;

	com = C(UIButton, self.rootTrans, "HasGotSign", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickInfoBtn();
	end;

	com = C(UIButton, self.rootTrans, "FinGotSign", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickInfoBtn();
	end;

	com = C(UIButton, self.rootTrans, "CheckBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickInfoBtn();
	end;

	--// 红包数据
	self.redPData = nil;
	--// 当前红包状态
	self.rpType = 0;
end

--// 显示隐藏
function UIFRedPacketItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 显示条目内容
--// rpType : 1、未发送；2、未领取；3、已领取；4、已领完
function UIFRedPacketItem:ShowData(rpData, rpType)
	self.redPData = rpData;
	self.rpType = rpType;

	self.nameL.text = self.redPData.senderName;
	self.infoL.text = self.redPData.content;

	local hasIcon = true;
	local iInd = self.redPData.icon;
	if iInd < 1 or iInd > 2 then
		hasIcon = false;
	end
	if self.rpType == 1 then
		self.giveBtnObj:SetActive(true);
		self.getBtnObj:SetActive(false);
		self.getSignObj:SetActive(false);
		self.finSignObj:SetActive(false);
		self.checkBtnObj:SetActive(false);

		self.nameL.text = FamilyMgr:GetPlayFamilyInfo().roleName;
		self.infoL.text = "恭喜发财";

		-- local iName = string.format("head_%s.png", User.MapData.Category);
		self.IconObj:SetActive(hasIcon);
		if hasIcon == true then
			local iName = string.format("head_%s.png", iInd);
			self:SetIcon(iName);
		end
		
	elseif self.rpType == 2 then
		self.giveBtnObj:SetActive(false);
		self.getBtnObj:SetActive(true);
		self.getSignObj:SetActive(false);
		self.finSignObj:SetActive(false);
		self.checkBtnObj:SetActive(false);

		self.IconObj:SetActive(hasIcon);
		if hasIcon == true then
			local iName = string.format("head_%s.png", iInd);
			self:SetIcon(iName);
		end

	elseif self.rpType == 3 then
		self.giveBtnObj:SetActive(false);
		self.getBtnObj:SetActive(false);
		--self.getSignObj:SetActive(true);
		self.getSignObj:SetActive(false);
		self.finSignObj:SetActive(false);
		self.checkBtnObj:SetActive(true);

		self.IconObj:SetActive(hasIcon);
		if hasIcon == false then
			local iName = string.format("head_%s.png", iInd);
			self:SetIcon(iName);
		end

	elseif self.rpType == 4 then
		self.giveBtnObj:SetActive(false);
		self.getBtnObj:SetActive(false);
		self.getSignObj:SetActive(false);
		--self.finSignObj:SetActive(true);
		self.finSignObj:SetActive(false);
		self.checkBtnObj:SetActive(true);

		self.IconObj:SetActive(hasIcon);
		if hasIcon == false then
			local iName = string.format("head_%s.png", iInd);
			self:SetIcon(iName);
		end
		
	end
end

--// 设置图标
function UIFRedPacketItem:SetIcon(iconName)
	AssetMgr.Instance:Load(iconName, ObjHandler(self.LoadIconFin,self));
end

--// 读取图标完成
function UIFRedPacketItem:LoadIconFin(obj)
	self.iconTex.mainTexture = obj;
end

--// 点击发送红包按钮
function UIFRedPacketItem:ClickGiveBtn()
	UIFamilyRedPWnd:OpenGivePedPPanel();
	UIFGiveRedPPanel:ShowData(self.redPData, 1);
end

--// 点击领取红包按钮
function UIFRedPacketItem:ClickGetBtn()
	UIGiftMoneyWnd.openRedPId = self.redPData.id;
	UIGiftMoneyWnd.autoGetRedP = true;
	UIMgr.Open(UIGiftMoneyWnd.Name);

	-- FamilyMgr:ReqGetRedPacket(self.redPData.id);

	-- UIFamilyRedPWnd:OpenRedPInfoPanel();
	-- UIFRedPInfoPanel:ShowData(self.redPData, self.rpType)
	-- --// 请求红包领取数据列表
	-- FamilyMgr:ReqSeeRedPacket(self.redPData.id);
end

--// 点击查看按钮
function UIFRedPacketItem:ClickInfoBtn()
	UIGiftMoneyWnd.openRedPId = self.redPData.id;
	UIGiftMoneyWnd.showInfo = true;
	UIMgr.Open(UIGiftMoneyWnd.Name);

	-- UIFamilyRedPWnd:OpenRedPInfoPanel();
	-- UIFRedPInfoPanel:ShowData(self.redPData, self.rpType)
	-- --// 请求红包领取数据列表
	-- FamilyMgr:ReqSeeRedPacket(self.redPData.id);
end
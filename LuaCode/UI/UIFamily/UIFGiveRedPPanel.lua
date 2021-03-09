--// 红包领取信息面板
require("UI/UIFamily/UIFNumInputItem");
require("UI/UIFamily/UIFTextInputItem");

UIFGiveRedPPanel = Super:New{Name = "UIFGiveRedPPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIFGiveRedPPanel:Init(panelObject)
	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.init = false;

	local tip = "UI红包领取信息面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	
	--// 系统红包物体
	panelCtrl.sysNumObj = T(panelCtrl.rootTrans, "WndCont/SysNumCont");
	--// 数值输入物体1
	panelCtrl.inputObj1 = T(panelCtrl.rootTrans, "WndCont/NumInputCont1");
	--// 数值输入物体2
	panelCtrl.inputObj2 = T(panelCtrl.rootTrans, "WndCont/NumInputCont2");
	--// 文案输入物体
	panelCtrl.inputObj3 = T(panelCtrl.rootTrans, "WndCont/TextCont");
	--// 剩余次数信息物体
	panelCtrl.infoObj = T(panelCtrl.rootTrans, "WndCont/InfoCont");
	--// 元宝标志物体
	panelCtrl.goldSignObj = T(panelCtrl.rootTrans, "WndCont/SysNumCont/GoldSign");
	--// 绑定元宝标志物体
	panelCtrl.bindGoldSignObj = T(panelCtrl.rootTrans, "WndCont/SysNumCont/BindGoldSign");
	--// 关闭按钮物体
	panelCtrl.closeBtnObj = T(panelCtrl.rootTrans, "Bg");


	--// 系统红包数量
	panelCtrl.sysNum = C(UILabel, panelCtrl.rootTrans, "WndCont/SysNumCont/SysNum", tip, false);
	--// 剩余发红包次数
	panelCtrl.giveNum = C(UILabel, panelCtrl.rootTrans, "WndCont/InfoCont/NumL", tip, false);


	--// 关闭按钮
	-- local com = C(UIButton, panelCtrl.rootTrans, "WndCont/CloseBtn", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	-- 	self:Close();
	-- end;
	UITool.SetBtnSelf(panelCtrl.closeBtnObj, self.Close, self, self.Name);

	--// 发送按钮
	com = C(UIButton, panelCtrl.rootTrans, "WndCont/OkBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickOkBtn();
	end;


	--// 红包金额控件
	panelCtrl.amountItem = ObjPool.Get(UIFNumInputItem);
	panelCtrl.amountItem:Init(panelCtrl.inputObj1);

	--// 红包份额控件
	panelCtrl.pieceItem = ObjPool.Get(UIFNumInputItem);
	panelCtrl.pieceItem:Init(panelCtrl.inputObj2);

	--// 红包内容控件
	panelCtrl.contItem = ObjPool.Get(UIFTextInputItem);
	panelCtrl.contItem:Init(panelCtrl.inputObj3);


	--// 当前红包数据
	panelCtrl.curRPData = nil;
	--// 红包类型：
	--// 0：vip自己发送红包，1：系统红包，2：道具红包
	panelCtrl.redPacketType = 1;
	--// 红包金额最小数量
	panelCtrl.minAmount = 0;
	--// 红包金额最大数量
	panelCtrl.maxAmount = 0;
	--// 红包最小份数
	panelCtrl.minPiece = 0;
	--// 红包最大份数
	panelCtrl.maxPiece = 0;
	--// 帮派成员条目列表
	panelCtrl.itemList = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;
	

	panelCtrl.init = true;
end

--// 销毁释放面板
function UIFGiveRedPPanel:Dispose()
	panelCtrl.amountItem:Dispose();
	panelCtrl.pieceItem:Dispose();

	ObjPool.Add(panelCtrl.amountItem);
	ObjPool.Add(panelCtrl.pieceItem);
	ObjPool.Add(panelCtrl.contItem);

	panelCtrl.init = false;
end

--// 打开面板
function UIFGiveRedPPanel:Open()
	panelCtrl.open = true;
	panelCtrl.panelObj:SetActive(true);
end

--// 关闭面板
function UIFGiveRedPPanel:Close()
	panelCtrl.amountItem:Reset();
	panelCtrl.pieceItem:Reset();

	panelCtrl.panelObj:SetActive(false);
	panelCtrl.open = false;
end

--// 更新
function UIFGiveRedPPanel:Update()
	
end

--// 显示数据
function UIFGiveRedPPanel:ShowData(rpData, redPType)
	panelCtrl.curRPData = rpData;
	panelCtrl.redPacketType = redPType;

	local tempAmount = 0;
	panelCtrl.minAmount = 1;

	panelCtrl.minPiece = 1;
	panelCtrl.maxPiece = FamilyMgr:GetFamilyMemberNum();

	--// 系统红包
	if panelCtrl.redPacketType == 1 then
		panelCtrl.sysNumObj:SetActive(true);
		--// 2:元宝
		if panelCtrl.curRPData.goldType == 2 then
			panelCtrl.maxAmount = RoleAssets.Gold;
			panelCtrl.goldSignObj:SetActive(true);
			panelCtrl.bindGoldSignObj:SetActive(false);
		--// 3:绑定元宝
		elseif panelCtrl.curRPData.goldType == 3 then
			panelCtrl.maxAmount = RoleAssets.BindGold;
			panelCtrl.goldSignObj:SetActive(false);
			panelCtrl.bindGoldSignObj:SetActive(true);
		end
		if panelCtrl.maxAmount > 10000 then
			panelCtrl.maxAmount = 10000;
		end
		panelCtrl.inputObj1:SetActive(false);
		panelCtrl.infoObj:SetActive(false);

		tempAmount = panelCtrl.curRPData.amount;
		--// 系统红包金额设置(固定)
		panelCtrl.sysNum.text = tostring(panelCtrl.curRPData.amount);

		panelCtrl.minPiece = 10;
		if panelCtrl.maxPiece < panelCtrl.minPiece then
			panelCtrl.maxPiece = panelCtrl.minPiece;
		end
	--// 道具红包
	elseif panelCtrl.redPacketType == 2 then
		panelCtrl.sysNumObj:SetActive(true);
		--// 2:元宝
		if panelCtrl.curRPData.goldType == 2 then
			panelCtrl.maxAmount = panelCtrl.curRPData.amount;
			panelCtrl.goldSignObj:SetActive(true);
			panelCtrl.bindGoldSignObj:SetActive(false);
		--// 3:绑定元宝
		elseif panelCtrl.curRPData.goldType == 3 then
			panelCtrl.maxAmount = panelCtrl.curRPData.amount;
			panelCtrl.goldSignObj:SetActive(false);
			panelCtrl.bindGoldSignObj:SetActive(true);
		end
		panelCtrl.inputObj1:SetActive(false);
		panelCtrl.infoObj:SetActive(false);

		tempAmount = panelCtrl.curRPData.amount;
		--// 系统红包金额设置(固定)
		panelCtrl.sysNum.text = tostring(tempAmount);

		panelCtrl.minPiece = panelCtrl.curRPData.minPiece;
		if panelCtrl.maxPiece < panelCtrl.minPiece then
			panelCtrl.maxPiece = panelCtrl.minPiece;
		end
	--// 个人红包
	else
		panelCtrl.sysNumObj:SetActive(false);
		panelCtrl.inputObj1:SetActive(true);
		panelCtrl.infoObj:SetActive(true);
		
		panelCtrl.maxAmount = RoleAssets.Gold;
		if panelCtrl.maxAmount > 10000 then
			panelCtrl.maxAmount = 10000;
		end
		if panelCtrl.maxAmount <= 0 then
			panelCtrl.maxAmount = 0;
			panelCtrl.maxPiece = 0;
		else
			if panelCtrl.maxAmount < panelCtrl.maxPiece then
				panelCtrl.maxPiece = tempAmount;
			end
			if panelCtrl.maxPiece < panelCtrl.minPiece then
				panelCtrl.minPiece = panelCtrl.maxPiece;
			end
		end

		local leftNum = 10 - FamilyMgr:GetPlayFamilyInfo().packetTimes;
		panelCtrl.giveNum.text = "[67CC67FF]"..leftNum.."[-][FFE9BDFF]/10[-]";
	end

	--// 红包金额规则设置
	if panelCtrl.redPacketType == 1 then
		panelCtrl.amountItem:SetNumber(panelCtrl.minAmount, panelCtrl.curRPData.goldType);
	elseif panelCtrl.redPacketType == 2 then
		panelCtrl.amountItem:SetNumber(panelCtrl.minAmount, 2);
	else
		panelCtrl.amountItem:SetNumber(panelCtrl.minAmount, 2);
	end
	panelCtrl.amountItem:SetBound(true, panelCtrl.minAmount, true, panelCtrl.maxAmount, function(overType, limitVal, moneyType) UIFGiveRedPPanel:RpAmountOver(overType, limitVal, moneyType) end);

	--// 红包份数规则设置
	panelCtrl.pieceItem:SetNumber(panelCtrl.minPiece, 0);
	panelCtrl.pieceItem:SetBound(true, panelCtrl.minPiece, true, panelCtrl.maxPiece, function(overType, limitVal, moneyType) UIFGiveRedPPanel:RpPieceOver(overType, limitVal, moneyType) end);
end

--// 点击发送按钮
function UIFGiveRedPPanel:ClickOkBtn()
	local rpId = panelCtrl.redPacketType;
	local amount = 0;
	if panelCtrl.redPacketType == 1 then
		--rpId = 1;
		amount = panelCtrl.curRPData.amount;
	elseif panelCtrl.redPacketType == 2 then
		amount = panelCtrl.curRPData.itemId;
	else
		amount = panelCtrl.amountItem:GetInputNumber();
	end

	local piece = panelCtrl.pieceItem:GetInputNumber();
	local content = panelCtrl.contItem:GetInputText();

	FamilyMgr:ReqGiveRedPacket(rpId, amount, content, piece);

	self:Close();
	--UITip.Log("红包发送成功");
end

--// 红包金额溢出
function UIFGiveRedPPanel:RpAmountOver(overType, limitVal, moneyType)
	if overType == 0 then
		MsgBox.ShowYes("红包最小金额为"..limitVal);
	elseif overType == 1 then
		if panelCtrl.maxAmount == 10000 then
			MsgBox.ShowYes("红包最大金额为"..limitVal);
		else

			--print("======================================     "..moneyType)

			--// 2:元宝
			if moneyType == 2 then
				MsgBox.ShowYes("元宝不足！");
			--// 3:绑定元宝
			elseif moneyType == 3 then
				MsgBox.ShowYes("绑定元宝不足！");
			end
		end
	end
end

--// 红包份数溢出
function UIFGiveRedPPanel:RpPieceOver(overType, limitVal)
	if overType == 0 then
		MsgBox.ShowYes("红包数量最小值为"..limitVal);
	elseif overType == 1 then
		MsgBox.ShowYes("红包数量最大值为"..limitVal);
	end
end
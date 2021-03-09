--// 红包领取信息面板
require("UI/UIFamily/UIFGetRedPItem");

UIFRedPInfoPanel = Super:New{Name = "UIFRedPInfoPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;
local AssetMgr = Loong.Game.AssetMgr;


--// 初始化面板
function UIFRedPInfoPanel:Init(panelObject)

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

	--// 信息条目克隆主体
	panelCtrl.itemMainObj = T(panelCtrl.rootTrans, "WndCont/RedPInfoCont/ItemSV/Grid/Item_99");
	--// 领取完标志物体
	panelCtrl.finSignObj = T(panelCtrl.rootTrans, "WndCont/BtnCont/FinSign");
	--// 领取按钮物体
	panelCtrl.getBtnObj = T(panelCtrl.rootTrans, "WndCont/BtnCont/GetBtn");
	--// 自己信息物体
	panelCtrl.selfInfoObj = T(panelCtrl.rootTrans, "WndCont/BtnCont/SelfGetCont");

	--// 元宝物体
	panelCtrl.goldObj = T(panelCtrl.rootTrans, "WndCont/BtnCont/SelfGetCont/GoldSign");
	--// 绑定元宝物体
	panelCtrl.bindGoldObj = T(panelCtrl.rootTrans, "WndCont/BtnCont/SelfGetCont/BindGoldSign");

	--// 关闭按钮物体
	panelCtrl.closeBtnObj = T(panelCtrl.rootTrans, "Bg");


	--// 发红包玩家头像
	panelCtrl.playerIcon = C(UISprite, panelCtrl.rootTrans, "WndCont/PlayerInfoCont/Icon", tip, false);
	--// 发红包玩家名字
	panelCtrl.playerName = C(UILabel, panelCtrl.rootTrans, "WndCont/PlayerInfoCont/Name", tip, false);
	--// 自己获得数量
	panelCtrl.selfGetNum = C(UILabel, panelCtrl.rootTrans, "WndCont/BtnCont/SelfGetCont/NumL", tip, false);
	--// 滚动区域
	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "WndCont/RedPInfoCont/ItemSV", tip, false);
	--// 排序控件
    panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "WndCont/RedPInfoCont/ItemSV/Grid", tip, false);


	--// 关闭按钮
	-- local com = C(UIButton, panelCtrl.rootTrans, "WndCont/CloseBtn", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	-- 	self:Close();
	-- end;
	UITool.SetBtnSelf(panelCtrl.closeBtnObj, self.Close, self, self.Name);

	com = C(UIButton, panelCtrl.rootTrans, "WndCont/BtnCont/GetBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickGetBtn();
	end;


	--// 道庭红包领取列表更新
	panelCtrl.OnNewData = EventHandler(self.NewRedPContListData, self);
	EventMgr.Add("NewRedPContList", panelCtrl.OnNewData);

	--// 道庭红包领取列表更新
	panelCtrl.OnNewRPData = EventHandler(self.NewGetRedPacketArrive, self);
	EventMgr.Add("NewGetRedPacket", panelCtrl.OnNewRPData);


	--// 当前红包数据
	panelCtrl.curRPData = nil;
	--// 红包状态类型
	panelCtrl.rpType = 0;
	--// 自身条目
	panelCtrl.selfCont = nil;
	--// 帮派成员条目列表
	panelCtrl.itemList = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.open = false;
	panelCtrl.init = true;
end

--// 销毁释放面板
function UIFRedPInfoPanel:Dispose()
	EventMgr.Remove("NewRedPContList", panelCtrl.OnNewData);
	EventMgr.Remove("NewGetRedPacket", panelCtrl.OnNewRPData);

	for i = 1, #panelCtrl.itemList do
		ObjPool.Add(panelCtrl.itemList[i]);
	end
	panelCtrl.itemList ={};

	panelCtrl.init = false;
end

--// 打开面板
function UIFRedPInfoPanel:Open()
	panelCtrl.open = true;
	panelCtrl.panelObj:SetActive(true);
end

--// 关闭面板
function UIFRedPInfoPanel:Close()
	panelCtrl.panelObj:SetActive(false);

	panelCtrl.open = false;
end

--// 更新
function UIFRedPInfoPanel:Update()
	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.itemsSV:ResetPosition();
		end
	end
end

--// 点击领取红包按钮
function UIFRedPInfoPanel:ClickGetBtn()
	FamilyMgr:ReqGetRedPacket(panelCtrl.curRPData.id);
end

--// 显示数据
--// rpType : 1、未发送；2、未领取；3、已领取；4、已领完
function UIFRedPInfoPanel:ShowData(rpData, rpType)
	panelCtrl.curRPData = rpData;
	panelCtrl.rpType = rpType;

	if panelCtrl.rpType == 1 then
		iError("LY", "Red packet type error !!!");
	elseif panelCtrl.rpType == 2 then
		panelCtrl.finSignObj:SetActive(false);
		panelCtrl.getBtnObj:SetActive(true);
		panelCtrl.selfInfoObj:SetActive(false);
	elseif panelCtrl.rpType == 3 then
		panelCtrl.finSignObj:SetActive(false);
		panelCtrl.getBtnObj:SetActive(false);
		panelCtrl.selfInfoObj:SetActive(true);

		--// 2:元宝
		if panelCtrl.curRPData.goldType == 2 then
			panelCtrl.goldObj:SetActive(true);
			panelCtrl.bindGoldObj:SetActive(false);
		--// 3:绑定元宝
		elseif panelCtrl.curRPData.goldType == 3 then
			panelCtrl.goldObj:SetActive(false);
			panelCtrl.bindGoldObj:SetActive(true);
		end

	elseif panelCtrl.rpType == 4 then
		panelCtrl.finSignObj:SetActive(true);
		panelCtrl.getBtnObj:SetActive(false);
		panelCtrl.selfInfoObj:SetActive(false);
	end

	local iName = string.format("FVP_head0%s", panelCtrl.curRPData.icon);
	self:SetIcon(iName);
	panelCtrl.playerName.text = panelCtrl.curRPData.senderName;
end

--// 新的红包获取列表数据到达
function UIFRedPInfoPanel:NewRedPContListData()
	if panelCtrl.open == false then
		return;
	end

	if panelCtrl.curRPData == nil then
		iError("LY", "UIFRedPInfoPanel:NewRedPContListData panelCtrl.curRPData is nil !!! ");
		return;
	end

	panelCtrl.curRPData = FamilyMgr:GetRedPacketById(panelCtrl.curRPData.id);
	if panelCtrl.curRPData == nil then
		iError("LY", "UIFRedPInfoPanel:NewRedPContListData new panelCtrl.curRPData is nil !!! ");
		return;
	end

	local selfRoldId = FamilyMgr:GetPlayerRoleId();
	local contList = panelCtrl.curRPData.contentTbl;

	local isBindGold = true;
	--// 2:元宝
	if panelCtrl.curRPData.goldType == 2 then
		isBindGold = false;
	end

	self:RenewItemNum(#contList);
	for i = 1, #contList do
		if selfRoldId == contList[i].roleId then
			panelCtrl.selfCont = contList[i];
		end

		local iName = string.format("FVP_head0%s", contList[i].icon);
		panelCtrl.itemList[i]:ShowData(iName, contList[i].name, contList[i].amount, isBindGold);

		if i % 2 == 1 then
			panelCtrl.itemList[i]:SetBgOn(true);
		else
			panelCtrl.itemList[i]:SetBgOn(false);
		end
	end

	--// 显示自己的条目信息（如果有）
	if panelCtrl.selfCont ~= nil then
		panelCtrl.selfGetNum.text = tostring(panelCtrl.selfCont.amount);
	end
end

--// 更新红包数据
function UIFRedPInfoPanel:NewGetRedPacketArrive()
	if panelCtrl.open == false then
		return;
	end

	panelCtrl.rpType = 3;

	self:ShowData(panelCtrl.curRPData, panelCtrl.rpType);
	--// 请求红包领取数据列表
	FamilyMgr:ReqSeeRedPacket(panelCtrl.curRPData.id);
end

--// 克隆红包获取信息条目
function UIFRedPInfoPanel:CloneItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.itemMainObj);
	cloneObj.transform.parent = panelCtrl.itemMainObj.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.itemMainObj.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.itemMainObj.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.itemMainObj.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIFGetRedPItem);
	cloneItem:Init(cloneObj);

	local newName = "";
	if #panelCtrl.itemList + 1 >= 100 then
		newName = string.gsub(panelCtrl.itemMainObj.name, "99", tostring(#panelCtrl.itemList + 1));
	elseif #panelCtrl.itemList + 1 >= 10 then
		newName = string.gsub(panelCtrl.itemMainObj.name, "99", "0"..tostring(#panelCtrl.itemList + 1));
	else
		newName = string.gsub(panelCtrl.itemMainObj.name, "99", "00"..tostring(#panelCtrl.itemList + 1));
	end
	cloneObj.name = newName;
	panelCtrl.itemList[#panelCtrl.itemList + 1] = cloneItem;

	return cloneItem;
end

--// 重置红包获取信息数量
function UIFRedPInfoPanel:RenewItemNum(number)
	for a = 1, #panelCtrl.itemList do
		panelCtrl.itemList[a]:Show(false)
	end

	local realNum = number;
	if realNum <= #panelCtrl.itemList then
		for a = 1, realNum do
			panelCtrl.itemList[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.itemList do
			panelCtrl.itemList[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.itemList;
		for a = 1, needNum do
			self:CloneItem();
		end
	end

	panelCtrl.itemGrid:Reposition();

	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIFRedPInfoPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end

--// 设置图标
function UIFRedPInfoPanel:SetIcon(iconName)
	panelCtrl.playerIcon.spriteName = iconName;
	--AssetMgr.Instance:Load(iconName, ObjHandler(self.LoadIconFin,self));
end

--// 读取图标完成
-- function UIFRedPInfoPanel:LoadIconFin(obj)
-- 	panelCtrl.playerIcon.mainTexture = obj;
-- end
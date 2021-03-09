--// 获取红包窗口
require("UI/UIFamily/UIGetGiftMoneyItem");


UIGiftMoneyWnd = UIBase:New{Name = "UIGiftMoneyWnd"};

local winCtrl = {};

local iLog = iTrace.Log;
local iError = iTrace.Error;
local AssetMgr = Loong.Game.AssetMgr;

--// 指定打开红包Id
UIGiftMoneyWnd.openRedPId = 0;
UIGiftMoneyWnd.autoGetRedP = false;
UIGiftMoneyWnd.showInfo = false;

UIGiftMoneyWnd.isRedActiv = false;


--// 初始化界面
--// 链接所有操作物体
function UIGiftMoneyWnd:InitCustom()

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 信息条目克隆主体
	winCtrl.itemMainObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont/RedPInfoCont/ItemSV/Grid/Item_99");
	winCtrl.itemMainObj:SetActive(false);

	--// 抢红包面板物体
	winCtrl.getMoneyContObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetMoneyCont");
	--// 红包信息面板物体
	winCtrl.getInfoContObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont");
	--// 继续抢按钮物体
	winCtrl.ctnuBtnObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont/ContinueBtn");
	--// 确定按钮
	winCtrl.finBtnObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont/FinBtn");

	winCtrl.qlObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/Bg/ql");
	winCtrl.qrObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/Bg/qr");
	winCtrl.iconObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/p_icon_bg");
	winCtrl.nameObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/Name");

	--// 特效节点
	winCtrl.fxObj = T(winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/FxPanel/FxNode");
	winCtrl.fxObj:SetActive(false);

	--------- 获取控件 ---------

	local tip = "UI获取红包窗口"

	--// 玩家名字
	winCtrl.nameL = C(UILabel, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/Name", tip, false);
	--// 玩家头像
	winCtrl.iconTex = C(UITexture, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/p_icon_bg/PIcon", tip, false);
	--// 来源信息
	winCtrl.infoL = C(UILabel, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetMoneyCont/Info", tip, false);
	--// 红包描述
	winCtrl.textL = C(UILabel, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetMoneyCont/Text", tip, false);
	--// 剩余红包数量
	winCtrl.leftNum = C(UILabel, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetMoneyCont/Num", tip, false);

	--//
	winCtrl.getInfoL = C(UILabel, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont/GetInfo", tip, false);
	--// 滚动区域
	winCtrl.itemsSV = C(UIScrollView, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont/RedPInfoCont/ItemSV", tip, false);
	--// 排序控件
    winCtrl.itemGrid = C(UIGrid, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont/RedPInfoCont/ItemSV/Grid", tip, false);


	local com = C(UIButton, winCtrl.winRootTrans, "WndCont/CloseBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:Close();
	end;

	com = C(UIButton, winCtrl.winRootTrans, "WndCont/Bg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:Close();
	end;

	com = C(UIButton, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetMoneyCont/GetBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickGetBtn();
	end;

	com = C(UIButton, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont/ContinueBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickContinueBtn();
	end;

	com = C(UIButton, winCtrl.winRootTrans, "WndCont/GiftMoneyPanel/GetInfoCont/FinBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:Close();
	end;

	-- winCtrl.closeEnt = EventHandler(self.Close, self);
	-- EventMgr.Add("QuitFamily", winCtrl.closeEnt);

	--// 道庭红包领取列表更新
	winCtrl.OnNewData = EventHandler(self.NewRedPContListData, self);
	EventMgr.Add("NewRedPContList", winCtrl.OnNewData);
	
	--// 当前红包数据
	winCtrl.curRedPData = nil;
	--// 当前红包是否领取
	winCtrl.isGet = false;
	--// 是否点击领取红包
	winCtrl.clickGet = false;

	--// 红包条目列表
	winCtrl.itemList = {};
	--// 延迟重置倒数
	winCtrl.delayResetCount = 0;

	--// 
	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UIGiftMoneyWnd:OpenCustom()
	winCtrl.mOpen = true;
	FamilyMgr.lookAtRP = true;
	FamilyMgr.checkRP = true;

	winCtrl.curRedPData = nil;
	winCtrl.isGet = false;
	winCtrl.clickGet = false;

	self:ShowData();
end

--// 关闭窗口
function UIGiftMoneyWnd:CloseCustom()
	winCtrl.fxObj:SetActive(false);
	winCtrl.mOpen = false;
	FamilyMgr.lookAtRP = false;
	FamilyMgr.checkRP = false;
	UIGiftMoneyWnd.openRedPId = 0;
	UIGiftMoneyWnd.autoGetRedP = false;
	UIGiftMoneyWnd.showInfo = false;
	UIGiftMoneyWnd.isRedActiv = false;

	-- UISystemView:UpdateRedPacket()
	FamilyMgr.eUpdateRedPack();
end

--// 更新
function UIGiftMoneyWnd:Update()
	if winCtrl.mOpen == false then
		return;
	end

	if winCtrl.delayResetCount > 0 then
		winCtrl.delayResetCount = winCtrl.delayResetCount - 1;
		if winCtrl.delayResetCount <= 0 then
			winCtrl.delayResetCount = 0;
			winCtrl.itemsSV:ResetPosition();
		end
	end
end

--// 销毁释放窗口
function UIGiftMoneyWnd:DisposeCustom()
	EventMgr.Remove("NewRedPContList", winCtrl.OnNewData);
	UIGiftMoneyWnd.openRedPId = 0;
	UIGiftMoneyWnd.autoGetRedP = false;
	UIGiftMoneyWnd.showInfo = false;

	for i = 1, #winCtrl.itemList do
		ObjPool.Add(winCtrl.itemList[i]);
	end
	winCtrl.itemList ={};
	
	winCtrl.mOpen = false;
	winCtrl.init = false;
end

--// 抢红包
function UIGiftMoneyWnd:ClickGetBtn()
	if UIGiftMoneyWnd.isRedActiv == false then
		FamilyMgr:ReqGetRedPacket(winCtrl.curRedPData.id);

		winCtrl.clickGet = true;
		--// 请求红包领取数据列表
		FamilyMgr:ReqSeeRedPacket(winCtrl.curRedPData.id);
	else
		winCtrl.clickGet = true;
		RedPacketActivMgr:ReqAward(winCtrl.curRedPData.id);

		RedPacketActivMgr:ReqSayOtherInfo(winCtrl.curRedPData.id);
	end
end

--// 点击继续抢按钮
function UIGiftMoneyWnd:ClickContinueBtn()
	UIGiftMoneyWnd.showInfo = false;
	winCtrl.isGet = false;
	winCtrl.clickGet = false;
	self:ShowData();
end

function UIGiftMoneyWnd:SwitchGetCont()
	UIGiftMoneyWnd.showInfo = false;
	winCtrl.fxObj:SetActive(false);
	winCtrl.getMoneyContObj:SetActive(true);
	winCtrl.getInfoContObj:SetActive(false);
end

function UIGiftMoneyWnd:SwitchInfoCont()
	winCtrl.getMoneyContObj:SetActive(false);
	winCtrl.getInfoContObj:SetActive(true);

	if UIGiftMoneyWnd.showInfo == false then
		winCtrl.fxObj:SetActive(true);
	end
end

--// 数据列表到达
function UIGiftMoneyWnd:NewRedPContListData()
	if winCtrl.mOpen == false then
		return;
	end

	if winCtrl.curRedPData == nil then
		iError("LY", "UIGiftMoneyWnd:NewRedPContListData winCtrl.curRedPData is nil !!! ");
		self:Close();
		return;
	end

	if UIGiftMoneyWnd.isRedActiv == false then
		winCtrl.curRedPData = FamilyMgr:GetRedPacketById(winCtrl.curRedPData.id);
	else
		winCtrl.curRedPData = RedPacketActivMgr:GetRedPacketData(winCtrl.curRedPData.id);
	end

	if winCtrl.curRedPData == nil then
		iError("LY", "UIGiftMoneyWnd:NewRedPContListData panelCtrl.curRPData is nil !!! ");
		return;
	end

	if UIGiftMoneyWnd.showInfo == false and winCtrl.clickGet == false then
		return;
	end

	winCtrl.isGet = true;
	self:SwitchInfoCont();

	local iInd = winCtrl.curRedPData.icon;

	if UIGiftMoneyWnd.isRedActiv == false then
		winCtrl.nameL.text = winCtrl.curRedPData.senderName;
	else
		winCtrl.nameL.text = "";
		iInd = 1;
	end

	
	if iInd < 1 or iInd > 2 then
		-- winCtrl.iconTex.mainTexture = nil;
		winCtrl.qlObj:SetActive(false);
		winCtrl.qrObj:SetActive(false);
		winCtrl.iconObj:SetActive(false);
		winCtrl.nameObj.transform.localPosition = Vector3.New(0, 190, 0);
	else
		winCtrl.qlObj:SetActive(true);
		winCtrl.qrObj:SetActive(true);
		winCtrl.iconObj:SetActive(true);
		winCtrl.nameObj.transform.localPosition = Vector3.New(0, 130.6, 0);

		local iName = string.format("head%s.png", iInd);
		self:SetIcon(iName);
	end

	local selfRoldId = FamilyMgr:GetPlayerRoleId();
	local contList = winCtrl.curRedPData.contentTbl;

	local isBindGold = true;
	local isSilver = false;
	--// 2:元宝
	if winCtrl.curRedPData.goldType == 2 then
		isBindGold = false;
	end

	if winCtrl.curRedPData.goldType == 1 then
		isSilver = true;
	end

	self:RenewItemNum(#contList);
	local doContList = {};
	for i = 1, #contList do
		if selfRoldId == contList[i].roleId or selfRoldId == tonumber(contList[i].roleId) then
			local iName = string.format("FVP_head0%s", contList[i].icon);
			winCtrl.itemList[1]:ShowData(iName, contList[i].name, contList[i].amount, isBindGold, true, isSilver);
		else
			doContList[#doContList + 1] = contList[i];
		end
	end

	if #contList == #doContList then
		for i = 1, #doContList do
			local iName = string.format("FVP_head0%s", doContList[i].icon);
			winCtrl.itemList[i]:ShowData(iName, doContList[i].name, doContList[i].amount, isBindGold, false, isSilver);
		end
	else
		for i = 1, #doContList do
			local iName = string.format("FVP_head0%s", doContList[i].icon);
			winCtrl.itemList[i + 1]:ShowData(iName, doContList[i].name, doContList[i].amount, isBindGold, false , isSilver);
		end
	end

	--// 信息显示
	local showInfo = "";
	local tPiece = winCtrl.curRedPData.piece;
	local getPicece = #contList
	local repNum = winCtrl.curRedPData.amount;
	local showChY = "元宝";
	if isBindGold == true then
		showChY = "绑元";
	end

	if isSilver then
		showChY = "银两";
	end
	if UIGiftMoneyWnd.isRedActiv == true then
		local num = repNum;
		if num >= 10000 then
			local y, yy = math.modf(num/10000);
			repNum = yy < 0.1 and y or string.format("%.1f",num/10000);	
			showInfo = StrTool.Concat("已领取", tostring(getPicece), "/", tostring(tPiece), ",共", tostring(repNum), "W", showChY);	
		else
			showInfo = StrTool.Concat("已领取", tostring(getPicece), "/", tostring(tPiece), ",共", tostring(repNum), showChY);
		end
	else
		showInfo = StrTool.Concat("已领取", tostring(getPicece), "/", tostring(tPiece), ",共", tostring(repNum), showChY);
	end

	
	winCtrl.getInfoL.text = showInfo;

	--// 1、未发送；2、未领取；3、已领取；4、已领完
	local rpList1, rpList2, rpList3, rpList4 = {},{},{},{};
	if UIGiftMoneyWnd.isRedActiv == false then
		rpList1, rpList2, rpList3, rpList4 = FamilyMgr:GetAllRedPacketData();
	else
		rpList1, rpList2, rpList3, rpList4 = RedPacketActivMgr:GetAllRedState();
	end
	if rpList2 == nil or #rpList2 <= 0 then
		winCtrl.ctnuBtnObj:SetActive(false);
		winCtrl.finBtnObj:SetActive(true);
	else
		winCtrl.ctnuBtnObj:SetActive(true);
		winCtrl.finBtnObj:SetActive(false);
	end
end

--// 刷新数据
function UIGiftMoneyWnd:ShowData()
	--// 显示数据
	if UIGiftMoneyWnd.showInfo == true then
		if UIGiftMoneyWnd.isRedActiv == false then
			winCtrl.curRedPData = FamilyMgr:GetRedPacketById(UIGiftMoneyWnd.openRedPId);
		else
			winCtrl.curRedPData = RedPacketActivMgr:GetRedPacketData(UIGiftMoneyWnd.openRedPId);
		end
		self:NewRedPContListData();
		if UIGiftMoneyWnd.isRedActiv == false then
			FamilyMgr:ReqSeeRedPacket(UIGiftMoneyWnd.openRedPId);
		else
			RedPacketActivMgr:ReqSayOtherInfo(UIGiftMoneyWnd.openRedPId);
		end
		UIGiftMoneyWnd.openRedPId = 0;
		return;
	end

	self:SwitchGetCont();
	self:GetOneRedPAndShow();
end

--// 获取一个红包并显示
function UIGiftMoneyWnd:GetOneRedPAndShow()
	if UIGiftMoneyWnd.isRedActiv == true then
		UIGiftMoneyWnd.openRedPId = 0;
	end
	if UIGiftMoneyWnd.openRedPId ~= nil and UIGiftMoneyWnd.openRedPId > 0 then
		if UIGiftMoneyWnd.isRedActiv == false then
			winCtrl.curRedPData = FamilyMgr:GetRedPacketById(UIGiftMoneyWnd.openRedPId);
		else
			winCtrl.curRedPData = RedPacketActivMgr:GetRedPacketData(UIGiftMoneyWnd.openRedPId);
		end
		UIGiftMoneyWnd.openRedPId = 0;
		if winCtrl.curRedPData == nil then
			self:Close();
			return;
		end
	else
		--// 1、未发送；2、未领取；3、已领取；4、已领完
		local rpList1, rpList2, rpList3, rpList4 = {},{},{},{};
		if UIGiftMoneyWnd.isRedActiv == false then
			rpList1, rpList2, rpList3, rpList4 = FamilyMgr:GetAllRedPacketData();
		else
			rpList1, rpList2, rpList3, rpList4 = RedPacketActivMgr:GetAllRedState();
		end
		if rpList2 == nil or #rpList2 <= 0 then
			self:Close();
			return;
		end
		winCtrl.curRedPData = rpList2[1];
	end
	
	winCtrl.isGet = false;
	winCtrl.clickGet = false;

	if UIGiftMoneyWnd.isRedActiv == false then
		local fromStr = StrTool.Concat(winCtrl.curRedPData.senderName, "[F39800FF]的大红包[-]");
		winCtrl.infoL.text = fromStr;
		winCtrl.textL.text = winCtrl.curRedPData.content;
		winCtrl.nameL.text = winCtrl.curRedPData.senderName;
	else
		winCtrl.nameL.text = "";
		winCtrl.infoL.text = "";
		winCtrl.textL.text = "";
		winCtrl.nameL.text = "";
	end
	

	local tNum = winCtrl.curRedPData.piece;
	local lNum = winCtrl.curRedPData.piece - #winCtrl.curRedPData.contentTbl;
	local sInfo = StrTool.Concat(tostring(lNum), "/", tostring(tNum));
	winCtrl.leftNum.text = sInfo;

	local iInd = winCtrl.curRedPData.icon;
	if UIGiftMoneyWnd.isRedActiv == true then
		iInd = 1;
	end
	if iInd < 1 or iInd > 2 then
		-- winCtrl.iconTex.mainTexture = nil;
		winCtrl.qlObj:SetActive(false);
		winCtrl.qrObj:SetActive(false);
		winCtrl.iconObj:SetActive(false);
		winCtrl.nameObj.transform.localPosition = Vector3.New(0, 190, 0);
	else
		winCtrl.qlObj:SetActive(true);
		winCtrl.qrObj:SetActive(true);
		winCtrl.iconObj:SetActive(true);
		winCtrl.nameObj.transform.localPosition = Vector3.New(0, 130.6, 0);

		local iName = string.format("head%s.png", iInd);
		self:SetIcon(iName);
	end

	if UIGiftMoneyWnd.autoGetRedP == true then
		--UIGiftMoneyWnd.autoGetRedP = false;
		self:ClickGetBtn();
	end
end

--// 设置图标
function UIGiftMoneyWnd:SetIcon(iconName)
	AssetMgr.Instance:Load(iconName, ObjHandler(self.LoadIconFin,self));
end

--// 读取图标完成
function UIGiftMoneyWnd:LoadIconFin(obj)
	if winCtrl.mOpen == false then
		return;
	end

	winCtrl.iconTex.mainTexture = obj;
end

--// 克隆红包获取信息条目
function UIGiftMoneyWnd:CloneItem()
	local cloneObj = GameObject.Instantiate(winCtrl.itemMainObj);
	cloneObj.transform.parent = winCtrl.itemMainObj.transform.parent;
	cloneObj.transform.localPosition = winCtrl.itemMainObj.transform.localPosition;
	cloneObj.transform.localRotation = winCtrl.itemMainObj.transform.localRotation;
	cloneObj.transform.localScale = winCtrl.itemMainObj.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIGetGiftMoneyItem);
	cloneItem:Init(cloneObj);

	local newName = "";
	if #winCtrl.itemList + 1 >= 100 then
		newName = string.gsub(winCtrl.itemMainObj.name, "99", tostring(#winCtrl.itemList + 1));
	elseif #winCtrl.itemList + 1 >= 10 then
		newName = string.gsub(winCtrl.itemMainObj.name, "99", "0"..tostring(#winCtrl.itemList + 1));
	else
		newName = string.gsub(winCtrl.itemMainObj.name, "99", "00"..tostring(#winCtrl.itemList + 1));
	end
	cloneObj.name = newName;
	winCtrl.itemList[#winCtrl.itemList + 1] = cloneItem;

	return cloneItem;
end

--// 重置红包获取信息数量
function UIGiftMoneyWnd:RenewItemNum(number)
	for a = 1, #winCtrl.itemList do
		winCtrl.itemList[a]:Show(false)
	end

	local realNum = number;
	if realNum <= #winCtrl.itemList then
		for a = 1, realNum do
			winCtrl.itemList[a]:Show(true);
		end
	else
		for a = 1, #winCtrl.itemList do
			winCtrl.itemList[a]:Show(true)
		end

		local needNum = realNum - #winCtrl.itemList;
		for a = 1, needNum do
			self:CloneItem();
		end
	end

	winCtrl.itemGrid:Reposition();

	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIGiftMoneyWnd:DelayResetSVPosition()
	winCtrl.delayResetCount = 2;
end

return UIGiftMoneyWnd
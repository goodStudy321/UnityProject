--// 道庭守卫排行面板
require("UI/UIFamily/UIDRankItem");

UIFamilyTDRankPanel = Super:New{Name = "UIFamilyTDRankPanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIFamilyTDRankPanel:Init(panelObject)

	-- if panelCtrl.init ~= nil and panelCtrl.init == true then
	-- 	return;
	-- end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 道庭伤害排行信息克隆主体
	panelCtrl.rankInfoMain = T(panelCtrl.rootTrans, "Cont1/ScrollView/Grid/RankInfo_99");
	--// 自身排名物体
	panelCtrl.selfRankObj = T(panelCtrl.rootTrans, "Cont2/RankInfo");

	--------- 获取控件 ---------

	local tip = "UI道庭守卫排行面板"
	--// 滚动区域
	panelCtrl.rankSV = C(UIScrollView, panelCtrl.rootTrans, "Cont1/ScrollView", tip, false);
	--// 排序控件
	panelCtrl.rankGrid = C(UIGrid, panelCtrl.rootTrans, "Cont1/ScrollView/Grid", tip, false);
	--// 偷袭警告
	--panelCtrl.sneakWarmL = C(UILabel, panelCtrl.rootTrans, "WarmCont/Label2", tip, false);


	--// 捐献按钮
	-- local com = C(UIButton, panelCtrl.rootTrans, "ListCont/DonateBtn", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickDonateBtn(); end;

	--// 自身排名控件
	panelCtrl.selfRank = ObjPool.Get(UIDRankItem);
	panelCtrl.selfRank:Init(panelCtrl.selfRankObj);


	panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("NewFTDRank", panelCtrl.OnNewData);


	--// 窗口是否打开
	panelCtrl.isOpen = false;
	--// 帮派信息条目列表
	panelCtrl.rankItems = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.reqRankTime = 8;
	panelCtrl.timer = 0;

	panelCtrl.init = true;
	
end

--// 打开
function UIFamilyTDRankPanel:Open()
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.isOpen = true;

	self:ShowData();

	if panelCtrl.timer == 0 then
		FamilyActivityMgr:ReqRankInfo();
	end
	panelCtrl.timer = 0;
end

--// 关闭
function UIFamilyTDRankPanel:Close()
	panelCtrl.panelObj:SetActive(false);
	panelCtrl.isOpen = false;
end

--// 销毁释放窗口
function UIFamilyTDRankPanel:Dispose()

	EventMgr.Remove("NewFTDRank", panelCtrl.OnNewData);

	for i = 1, #panelCtrl.rankItems do
		ObjPool.Add(panelCtrl.rankItems[i]);
	end
	panelCtrl.rankItems ={};

	panelCtrl.init = false;
end

--// 更新
function UIFamilyTDRankPanel:Update()
	if panelCtrl.isOpen == false then
		return;
	end

	panelCtrl.timer = panelCtrl.timer + Time.deltaTime;
	if panelCtrl.timer > panelCtrl.reqRankTime then
		FamilyActivityMgr:ReqRankInfo();
		panelCtrl.timer = 0;
	end

	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.rankSV:ResetPosition();
		end
	end
end

--// 刷新成员列表数据
function UIFamilyTDRankPanel:ShowData()
	if panelCtrl.isOpen == false then
		return;
	end

	self:ShowRankData();
	self:ShowSelfInfo();
end

--// 显示排行数据
function UIFamilyTDRankPanel:ShowRankData()
	local rankList = FamilyActivityMgr:GetRankInfo();
	if rankList == nil or #rankList <= 0 then
		self:RenewRankItemNum(0);
		return;
	end

	local rankNum = #rankList;
	self:RenewRankItemNum(rankNum);
	for a = 1, rankNum do
		panelCtrl.rankItems[a]:ShowData(rankList[a]);
	end
end

--// 显示自身排行
function UIFamilyTDRankPanel:ShowSelfInfo()
	local sRankI = FamilyActivityMgr:GetSelfRank();
	if sRankI == nil then
		panelCtrl.selfRank:ShowData(nil);
		return;
	end

	panelCtrl.selfRank:ShowData(sRankI);
end

--// 克隆帮派信息条目
function UIFamilyTDRankPanel:CloneRankInfoItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.rankInfoMain);
	cloneObj.transform.parent = panelCtrl.rankInfoMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.rankInfoMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.rankInfoMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.rankInfoMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIDRankItem);
	cloneItem:Init(cloneObj);
	cloneObj.name = string.gsub(panelCtrl.rankInfoMain.name, "99", tostring(#panelCtrl.rankItems + 1));
	panelCtrl.rankItems[#panelCtrl.rankItems + 1] = cloneItem;

	return cloneItem;
end

--// 重置帮派信息条目数量
function UIFamilyTDRankPanel:RenewRankItemNum(number)
	for a = 1, #panelCtrl.rankItems do
		panelCtrl.rankItems[a]:Show(false)
	end

	local realNum = number;
	if realNum < 0 then
		realNum = 0;
	end

	if realNum <= #panelCtrl.rankItems then
		for a = 1, realNum do
			panelCtrl.rankItems[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.rankItems do
			panelCtrl.rankItems[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.rankItems;
		for a = 1, needNum do
			self:CloneRankInfoItem();
		end
	end

	-- for i = 1, #winCtrl.familyInfoItems do
	-- 	if i % 2 == 0 then
	-- 		winCtrl.familyInfoItems[i]:BgOn(false);
	-- 	else
	-- 		winCtrl.familyInfoItems[i]:BgOn(true);
	-- 	end
	-- end

	panelCtrl.rankGrid:Reposition();
	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIFamilyTDRankPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end
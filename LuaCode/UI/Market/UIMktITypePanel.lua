--// 帮派装备选择面板
require("UI/UIFamily/UIBtnItem");

UIMktITypePanel = Super:New{Name = "UIMktITypePanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIMktITypePanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--//按钮克隆主体
	panelCtrl.btnMain = T(panelCtrl.rootTrans, "BtnSV/Grid/Btn_99");

	--------- 获取控件 ---------
	local tip = "UI市场分类按钮面板"
	--// 滚动区域
	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "BtnSV", tip, false);
	--// 排序控件
	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "BtnSV/Grid", tip, false);


	panelCtrl.fstCfgList = nil;
	--// 按钮列表
	panelCtrl.btns = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;
	--// 当前选择一级Id
	panelCtrl.curSelId = 0;

	--// 当前选择打开面板为：1.摆摊 2.求购列表 3.我要求购
	panelCtrl.curOpenId = 0

	panelCtrl.init = true;
	panelCtrl.isOpen = false;
end

--// 更新
function UIMktITypePanel:Update()
	if panelCtrl.isOpen == false then
		return;
	end

	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.itemsSV:ResetPosition();
		end
	end
end

--// 打开
function UIMktITypePanel:Open(openId)
	panelCtrl.isOpen = true;
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.curSelId = 0;

	self:ShowData(openId);
end

--// 关闭
function UIMktITypePanel:Close()
	panelCtrl.isOpen = false;
	panelCtrl.panelObj:SetActive(false);
end

--// 销毁释放窗口
function UIMktITypePanel:Dispose()
	panelCtrl.fstCfgList = nil;
	panelCtrl.curSelId = 0;
	panelCtrl.curOpenId = 0
	for i = 1, #panelCtrl.btns do
		ObjPool.Add(panelCtrl.btns[i]);
	end
	panelCtrl.btns ={};

	panelCtrl.init = false;
end

--// 
function UIMktITypePanel:ClickCatBtn(fstId)
	if MarketMgr:GetSelFstId() ~= fstId then
		MarketMgr:SetSelBuyItemId(0, "", false, 0);
		UIMarketWnd:ClearSearchStr();
	end

	--MarketMgr:ClearFilterIds()
	MarketMgr:SetSelFstId(fstId);
	MarketMgr:SetSelSecId(0);

	MarketMgr:ResetToFirstState();

	local dicData = MarketDic[tostring(fstId)];
	if dicData.category == 1 then
		if panelCtrl.curOpenId == 1 then
			UIMktMatPanel:Close();
			UIMktItemCatPanel:Open();
			UIMktWBItemPanel:Close()
			MarketMgr:ReqMarketClassNum(fstId);
		elseif panelCtrl.curOpenId == 2 then
			UIMktWBListPanel:Close();
			UIMktWBItemPanel:Open()
			MarketMgr:ReqMarketClassNum(fstId);
		elseif panelCtrl.curOpenId == 3 then
			UIMktWBItemPanel:Close()
			UIMktWBListPanel:Close()
			UIMktIWBListPanel:Open()
			UIMktWBSetPanel:Open()
		end
	else
		if panelCtrl.curOpenId == 1 then
			UIMktItemCatPanel:Close();
			UIMktWBListPanel:Close()
			UIMktMatPanel:Open()
		elseif panelCtrl.curOpenId == 2 then
			UIMktMatPanel:Close()
			UIMktWBItemPanel:Close()
			UIMktWBListPanel:Open()
		end
		MarketMgr:ReqCurSearchItemInfo();
	end

	if panelCtrl.curSelId == fstId then
		return;
	end

	panelCtrl.curSelId = fstId;
	if panelCtrl.fstCfgList == nil then
		return;
	end

	for i = 1, #panelCtrl.fstCfgList do
		if panelCtrl.fstCfgList[i].id == fstId then
			panelCtrl.btns[i]:SetSelect(true);
		else
			panelCtrl.btns[i]:SetSelect(false);
		end
	end
end

--// 显示数据
function UIMktITypePanel:ShowData(openId)
	panelCtrl.curOpenId = openId
	if panelCtrl.curOpenId == 3 then
		panelCtrl.fstCfgList = MarketMgr:GetIWBDicFstCfg()
	elseif panelCtrl.curOpenId == 2 then
		panelCtrl.fstCfgList = MarketMgr:GetWBDicFstCfg()
	else
		panelCtrl.fstCfgList = MarketMgr:GetMarketDicFstCfg()
	end
	self:RenewBtnNum(#panelCtrl.fstCfgList);
	for a = 1, #panelCtrl.fstCfgList do
		panelCtrl.btns[a]:SetBtnName(panelCtrl.fstCfgList[a].name);
		panelCtrl.btns[a]:SetClickEvent(function() self:ClickCatBtn(panelCtrl.fstCfgList[a].id) end);
	end

	--if panelCtrl.curSelId <= 0 then
	panelCtrl.btns[1]:ClickBtn();
	--end
	-- local dicData = MarketDic[tostring(MarketMgr:GetSelFstId())];
	-- if dicData.category == 1 then
	-- 	if panelCtrl.curOpenId == 1 then
	-- 		UIMktMatPanel:Close();
	-- 		UIMktItemCatPanel:Open();
	-- 		UIMktWBItemPanel:Close();
	-- 		MarketMgr:ReqMarketClassNum(panelCtrl.curSelId);
	-- 	elseif panelCtrl.curOpenId == 2 then
	-- 		UIMktWBListPanel:Close();
	-- 		UIMktWBItemPanel:Open()
	-- 		MarketMgr:ReqMarketClassNum(panelCtrl.curSelId);
	-- 	elseif panelCtrl.curOpenId == 3 then
	-- 		UIMktWBItemPanel:Close()
	-- 		UIMktWBListPanel:Close()
	-- 		UIMktIWBListPanel:Open()
	-- 		UIMktWBSetPanel:Open()
	-- 	end
			
	-- else
	-- 	if panelCtrl.curOpenId == 1 then
	-- 		UIMktItemCatPanel:Close()
	-- 		UIMktWBListPanel:Close()
	-- 		UIMktMatPanel:Open()
	-- 	elseif panelCtrl.curOpenId == 2 then
	-- 		UIMktWBItemPanel:Close()
	-- 		UIMktMatPanel:Close()
	-- 		UIMktWBListPanel:Open()
	-- 	end
	-- 	MarketMgr:ReqCurSearchItemInfo();
	-- end
end

--// 显示、链接按钮
-- function UIMktITypePanel:ShowAndLinkBtn(btnNum, nameList, eventList)
-- 	self:RenewBtnNum(btnNum);
-- 	for a = 1, #panelCtrl.btns do
-- 		panelCtrl.btns[a]:SetBtnName(nameList[a]);
-- 		panelCtrl.btns[a]:SetClickEvent(eventList[a]);
-- 	end
-- end

--// 克隆按钮条目
function UIMktITypePanel:CloneBtn()
	local cloneObj = GameObject.Instantiate(panelCtrl.btnMain);
	cloneObj.transform.parent = panelCtrl.btnMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.btnMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.btnMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.btnMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIBtnItem);
	cloneItem:Init(cloneObj);

	local newName = "";
	if #panelCtrl.btns + 1 >= 100 then
		newName = string.gsub(panelCtrl.btnMain.name, "99", tostring(#panelCtrl.btns + 1));
	elseif #panelCtrl.btns + 1 >= 10 then
		newName = string.gsub(panelCtrl.btnMain.name, "99", "0"..tostring(#panelCtrl.btns + 1));
	else
		newName = string.gsub(panelCtrl.btnMain.name, "99", "00"..tostring(#panelCtrl.btns + 1));
	end
	cloneObj.name = newName;

	panelCtrl.btns[#panelCtrl.btns + 1] = cloneItem;

	return cloneItem;
end

--// 重置按钮数量
function UIMktITypePanel:RenewBtnNum(number)
	for a = 1, #panelCtrl.btns do
		panelCtrl.btns[a]:Show(false)
	end

	local realNum = number;
	if realNum <= #panelCtrl.btns then
		for a = 1, realNum do
			panelCtrl.btns[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.btns do
			panelCtrl.btns[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.btns;
		for a = 1, needNum do
			self:CloneBtn();
		end
	end

	panelCtrl.itemGrid:Reposition();
	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIMktITypePanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end

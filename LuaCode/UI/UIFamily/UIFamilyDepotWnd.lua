--// 帮派仓库界面
require("UI/UIFamily/UIFamilyBoxRowItem");


UIFamilyDepotWnd = UIBase:New{Name = "UIFamilyDepotWnd"};

local winCtrl = {};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 行控件最大数量
local MAXITEMNUM = 3;


--// 初始化界面
--// 链接所有操作物体
function UIFamilyDepotWnd:InitCustom()

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 行控件克隆主体
	winCtrl.boxRowMain = T(winCtrl.winRootTrans, "SVBg/BoxContSV/UIWrapCont/RowItem_99");
	winCtrl.boxRowMain:SetActive(false);
	--// 没有宝箱提示物体
	winCtrl.noBoxSignObj = T(winCtrl.winRootTrans, "SVBg/NoBoxSign");
	--// 宝箱列表控件物体
	winCtrl.boxSVObj = T(winCtrl.winRootTrans, "SVBg/BoxContSV");
	--// 一键领取按钮物体
	winCtrl.getAllBtnObj = T(winCtrl.winRootTrans, "GetAllBtn");
	--// 关闭按钮物体
	winCtrl.closeBtnObj = T(winCtrl.winRootTrans, "Bg/Title/backBtn");
	--// 信息按钮物体
	winCtrl.infoBtnObj = T(winCtrl.winRootTrans, "InfoBtn");

	--------- 获取控件 ---------

	local tip = "UI道庭仓库窗口"

	--// 宝箱数量
	winCtrl.boxNum = C(UILabel, winCtrl.winRootTrans, "Bg/Title/Number", tip, false);
	--// 宝箱滚动区域
	winCtrl.boxScrollView = C(UIScrollView, winCtrl.winRootTrans, "SVBg/BoxContSV", tip, false);
	--// 循环控件
	winCtrl.wrapContent = C(UIWrapContent, winCtrl.winRootTrans, "SVBg/BoxContSV/UIWrapCont", tip, false);


	-- local com = C(UIButton, winCtrl.winRootTrans, "Bg/Title/backBtn", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	-- 	self:Close();
	-- end;

	--// 连接关闭按钮
	UITool.SetBtnSelf(winCtrl.closeBtnObj, self.Close, self, self.Name);
	--// 连接一键领取按钮
	UITool.SetBtnSelf(winCtrl.getAllBtnObj, self.GetAllBox, self, self.Name);
	--// 连接规则说明按钮
	UITool.SetBtnSelf(winCtrl.infoBtnObj, self.ClickInfo, self, self.Name);

	local func = UIWrapContent.OnInitializeItem(self.OnUpdateItem, self);
	winCtrl.wrapContent.onInitializeItem = func;

	winCtrl.newBoxEnt = EventHandler(self.ShowData, self);
	EventMgr.Add("NewBoxData", winCtrl.newBoxEnt);

	winCtrl.openBoxEnt = EventHandler(self.ResetNowBoxData, self);
	EventMgr.Add("OpenFamilyBox", winCtrl.openBoxEnt);

	--// 宝箱数据列表
	winCtrl.boxDataList = nil;
	--// 行控件列表
	winCtrl.boxRowItems = {};
	--// 延迟重置倒数
	winCtrl.delayResetCount = 0;
	--// 
	winCtrl.curRowNum = 0;

	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UIFamilyDepotWnd:OpenCustom()
	winCtrl.mOpen = true;
	winCtrl.curRowNum = 0;

	FamilyMgr:ClearGetFamilyBox();
	self:ShowData();
end

--// 关闭窗口
function UIFamilyDepotWnd:CloseCustom()
	FamilyMgr:ClearGetFamilyBox();

	if FamilyMgr:GetNewBoxNumber() > 0 then
		-- UIFamilyEventPanel:NewMsg(true, 3, 1);
	else
		-- UIFamilyEventPanel:NewMsg(false, 3, 1);
		UIFamilyMainPanel:NewMsg(false, 1, 4);
		UIFamilyMainWnd:NewMsg(false, 1, 4);
		-- UIFamilyMainWnd:NewMsg(false, 3, 1);

		FamilyMgr.eRed(false, 1, 4);
	end

	winCtrl.curRowNum = 0;
	winCtrl.mOpen = false;
end

--// 更新
function UIFamilyDepotWnd:Update()
	if winCtrl.mOpen == false then
		return;
	end

	if winCtrl.delayResetCount > 0 then
		winCtrl.delayResetCount = winCtrl.delayResetCount - 1;
		if winCtrl.delayResetCount <= 0 then
			winCtrl.delayResetCount = 0;
			winCtrl.boxScrollView:ResetPosition();

			if winCtrl.curRowNum ~= nil then
				if winCtrl.curRowNum < 3 then
					winCtrl.boxScrollView.enabled = false;
				else
					winCtrl.boxScrollView.enabled = true;
				end
			end
		end
	end

	if winCtrl.boxRowItems ~= nil then
		for i = 1, #winCtrl.boxRowItems do
			winCtrl.boxRowItems[i]:Update(Time.deltaTime);
		end
	end
end

--// 销毁释放窗口
function UIFamilyDepotWnd:DisposeCustom()
	EventMgr.Remove("NewBoxData", winCtrl.newBoxEnt);
	EventMgr.Remove("OpenFamilyBox", winCtrl.openBoxEnt);

	winCtrl.mOpen = false;
	winCtrl.init = false;
end

--// 一键领取
function UIFamilyDepotWnd:GetAllBox()
	FamilyMgr:ReqFamilyAllBoxOpen();
end

--// 点击规则说明按钮
function UIFamilyDepotWnd:ClickInfo()
	local tCfg = InvestDesCfg["1034"];
	local showStr = "";
	if tCfg ~= nil then
		showStr = tCfg.des;
	end

	UIComTips:Show(showStr, Vector3.New(0, -180, 0), 20, 0, 0, 700);
end

--// 刷新成员列表数据
function UIFamilyDepotWnd:ShowData()
	if winCtrl.mOpen == false then
		return;
	end

	local tBNum = FamilyMgr:GetNewBoxNumber();
	local tTNum = 40;
	local viplv = VIPMgr.GetVIPLv();
	if viplv >= 0 then
		local vipCfg = VIPLv[viplv + 1];
		if vipCfg ~= nil and vipCfg.maxBoxNum ~= nil then
			tTNum = vipCfg.maxBoxNum;
		end
	end
	winCtrl.boxNum.text = StrTool.Concat("(", tostring(tBNum), "/", tostring(tTNum), ")");
	
	winCtrl.boxDataList = FamilyMgr:GetFamilyBoxDataList();
	if winCtrl.boxDataList == nil or #winCtrl.boxDataList <= 0 then
		winCtrl.noBoxSignObj:SetActive(true);
		winCtrl.boxSVObj:SetActive(false);
	else
		winCtrl.noBoxSignObj:SetActive(false);
		winCtrl.boxSVObj:SetActive(true);

		local boxNum = #winCtrl.boxDataList;
		local rowNum = math.ceil(boxNum / 4);
		UIFamilyDepotWnd:RenewBoxRowNum(rowNum);
	end
end

--// 获取每行开始与结尾对应宝箱索引号
function UIFamilyDepotWnd:GetBeginEndIndex(rowIndex)
	local bIndex = 0;
	local eIndex = 0;

	bIndex = (rowIndex - 1) * 4 + 1;
	eIndex = rowIndex * 4;

	return bIndex, eIndex;
end

function UIFamilyDepotWnd:OnUpdateItem(gObj, index, realIndex)
	if winCtrl.boxDataList ~= nil then
		local rIndex = -realIndex + 1;

		--// 每行最多有4个数据，按索引来换算数量
		local bInd, eInd = self:GetBeginEndIndex(rIndex);
		if eInd > #winCtrl.boxDataList then
			eInd = #winCtrl.boxDataList;
		end

		local bDList = {};
		for a = bInd, eInd do
			bDList[#bDList + 1] = winCtrl.boxDataList[a];
		end
		
		winCtrl.boxRowItems[index + 1]:LinkAndConfig(bDList, rIndex);
	end
end

--// 刷新当前数据显示
function UIFamilyDepotWnd:ResetNowBoxData()
	if winCtrl.boxRowItems ~= nil then
		winCtrl.boxDataList = FamilyMgr:GetFamilyBoxDataList();

		for i = 1, #winCtrl.boxRowItems do
			local rInd = winCtrl.boxRowItems[i]:GetRowIndex();
			if rInd > -1 then
				local bInd, eInd = self:GetBeginEndIndex(rInd);
				if eInd > #winCtrl.boxDataList then
					eInd = #winCtrl.boxDataList;
				end

				local bDList = {};
				for a = bInd, eInd do
					bDList[#bDList + 1] = winCtrl.boxDataList[a];
				end
				
				winCtrl.boxRowItems[i]:LinkAndConfig(bDList, rInd);
			end
		end
	end
end

--// 克隆宝箱行控件条目
function UIFamilyDepotWnd:CloneBoxRowItem()
	local cloneObj = GameObject.Instantiate(winCtrl.boxRowMain);
	cloneObj.transform.parent = winCtrl.boxRowMain.transform.parent;
	cloneObj.transform.localPosition = winCtrl.boxRowMain.transform.localPosition;
	cloneObj.transform.localRotation = winCtrl.boxRowMain.transform.localRotation;
	cloneObj.transform.localScale = winCtrl.boxRowMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIFamilyBoxRowItem);
	cloneItem:Init(cloneObj);

	local newName = "";
	if #winCtrl.boxRowItems + 1 >= 100 then
		newName = string.gsub(winCtrl.boxRowMain.name, "99", tostring(#winCtrl.boxRowItems + 1));
	elseif #winCtrl.boxRowItems + 1 >= 10 then
		newName = string.gsub(winCtrl.boxRowMain.name, "99", "0"..tostring(#winCtrl.boxRowItems + 1));
	else
		newName = string.gsub(winCtrl.boxRowMain.name, "99", "00"..tostring(#winCtrl.boxRowItems + 1));
	end
	cloneObj.name = newName;
	winCtrl.boxRowItems[#winCtrl.boxRowItems + 1] = cloneItem;

	return cloneItem;
end

--// 重置行控件数量
function UIFamilyDepotWnd:RenewBoxRowNum(number)
	for a = 1, #winCtrl.boxRowItems do
		winCtrl.boxRowItems[a]:Show(false)
	end
	
	if number < MAXITEMNUM then
		winCtrl.wrapContent.minIndex = 0;
		winCtrl.wrapContent.maxIndex = MAXITEMNUM - 1;
	else
		winCtrl.wrapContent.minIndex = -number + 1;
		winCtrl.wrapContent.maxIndex = 0;
	end

	local realNum = number;
	if realNum < 0 then
		realNum = 0;
	elseif realNum > MAXITEMNUM then
		realNum = MAXITEMNUM;
	end

	if realNum <= #winCtrl.boxRowItems then
		for a = 1, realNum do
			winCtrl.boxRowItems[a]:Show(true);
		end
	else
		for a = 1, #winCtrl.boxRowItems do
			winCtrl.boxRowItems[a]:Show(true)
		end

		local needNum = realNum - #winCtrl.boxRowItems;
		for a = 1, needNum do
			self:CloneBoxRowItem();
		end
	end

	winCtrl.curRowNum = realNum;

	winCtrl.wrapContent:SortAlphabetically();
	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIFamilyDepotWnd:DelayResetSVPosition()
	winCtrl.delayResetCount = 2;
end

return UIFamilyDepotWnd
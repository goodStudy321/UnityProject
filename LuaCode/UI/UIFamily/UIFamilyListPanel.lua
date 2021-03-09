--// 道庭列表面板
require("UI/UIFamily/UIFamilyInfoItem")

UIFamilyListPanel = Super:New{Name = "UIFamilyListPanel"};

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;
local ET = EventMgr.Trigger;


--// 初始化界面
--// 链接所有操作物体
function UIFamilyListPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	local tip = "UI道庭列表面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 帮派信息条目克隆主体
	panelCtrl.familyInfoMain = T(panelCtrl.rootTrans, "FamilyInfoSV/UIGrid/FamilyCont_99");

	--------- 获取控件 ---------

	local tip = "UI道庭列表界面";

	--// 关闭按钮物体
	panelCtrl.closeBtnObj = T(panelCtrl.rootTrans, "Title/CloseBtn");

	--// 滚动区域
	panelCtrl.infoScrollView = C(UIScrollView, panelCtrl.rootTrans, "FamilyInfoSV", tip, false);
	--// 排序控件
	panelCtrl.infoGrid = C(UIGrid, panelCtrl.rootTrans, "FamilyInfoSV/UIGrid", tip, false);

	--// 关闭按钮
	UITool.SetBtnSelf(panelCtrl.closeBtnObj, self.Close, self, self.Name);


	--EventMgr.Add("NewFamilyBrief", function (familyBriefs, briefNum) self:RenewShowList(familyBriefs, briefNum); end);
	panelCtrl.OnNewData = EventHandler(self.RenewShowList, self);
	EventMgr.Add("NewFamilyBrief", panelCtrl.OnNewData);
	

	panelCtrl.familyInfoMain:SetActive(false);

	--// 面板是否打开
	panelCtrl.mOpen = false;
	--// 帮派信息条目列表
	panelCtrl.familyInfoItems = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.init = true;
end

--// 打开窗口
function UIFamilyListPanel:Open()
	panelCtrl.mOpen = true;
	panelCtrl.panelObj:SetActive(true);
	
	self:CallShowList();
end

--// 关闭窗口
function UIFamilyListPanel:Close()
	panelCtrl.panelObj:SetActive(false);

	panelCtrl.mOpen = false;
end

--// 更新
function UIFamilyListPanel:Update()
	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.infoScrollView:ResetPosition();
		end
	end
end

--// 销毁释放窗口
function UIFamilyListPanel:Dispose()
	EventMgr.Remove("NewFamilyBrief", panelCtrl.OnNewData);
	
	if panelCtrl.familyInfoItems ~= nil then
		for i = 1, #panelCtrl.familyInfoItems do
			ObjPool.Add(panelCtrl.familyInfoItems[i]);
		end
	end
	panelCtrl.familyInfoItems = {};

	panelCtrl.init = false;
end

--// 更新当前显示列表
function UIFamilyListPanel:CallShowList()
	local fromInd = 1;
	local toInd = 200;

	FamilyMgr:ReqFamilyBrief(fromInd, toInd);
end

--// 更新当前显示列表
function UIFamilyListPanel:RenewShowList(familyBriefs, allNum)
	if panelCtrl.mOpen == false then
		return;
	end

	if familyBriefs == nil or #familyBriefs <= 0 or allNum == nil then
		self:RenewFamilyItemNum(0);
		panelCtrl.allBriefNum = 0;
		panelCtrl.maxPage = 1;
		return;
	end

	local itemNum = #familyBriefs;
	self:RenewFamilyItemNum(itemNum);
	for i = 1, itemNum do
		panelCtrl.familyInfoItems[i]:ResetData(familyBriefs[i]);
	end
end

--// 克隆帮派信息条目
function UIFamilyListPanel:CloneFamilyInfoItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.familyInfoMain);
	cloneObj.transform.parent = panelCtrl.familyInfoMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.familyInfoMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.familyInfoMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.familyInfoMain.transform.localScale;
	cloneObj:SetActive(true);

	--local cloneItem = UIFamilyInfoItem:New();
	local cloneItem = ObjPool.Get(UIFamilyInfoItem);
	cloneItem:Init(cloneObj, true);

	local newName = "";
	if #panelCtrl.familyInfoItems + 1 >= 100 then
		newName = string.gsub(panelCtrl.familyInfoMain.name, "99", tostring(#panelCtrl.familyInfoItems + 1));
	elseif #panelCtrl.familyInfoItems + 1 >= 10 then
		newName = string.gsub(panelCtrl.familyInfoMain.name, "99", "0"..tostring(#panelCtrl.familyInfoItems + 1));
	else
		newName = string.gsub(panelCtrl.familyInfoMain.name, "99", "00"..tostring(#panelCtrl.familyInfoItems + 1));
	end
	cloneObj.name = newName;
	panelCtrl.familyInfoItems[#panelCtrl.familyInfoItems + 1] = cloneItem;

	return cloneItem;
end

--// 重置帮派信息条目数量
function UIFamilyListPanel:RenewFamilyItemNum(number)
	for a = 1, #panelCtrl.familyInfoItems do
		panelCtrl.familyInfoItems[a]:Show(false)
	end

	local realNum = number;
	if realNum < 0 then
		realNum = 0;
	end

	if realNum <= #panelCtrl.familyInfoItems then
		for a = 1, realNum do
			panelCtrl.familyInfoItems[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.familyInfoItems do
			panelCtrl.familyInfoItems[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.familyInfoItems;
		for a = 1, needNum do
			self:CloneFamilyInfoItem();
		end
	end

	for i = 1, #panelCtrl.familyInfoItems do
		if i % 2 == 0 then
			panelCtrl.familyInfoItems[i]:BgOn(false);
		else
			panelCtrl.familyInfoItems[i]:BgOn(true);
		end
	end

	panelCtrl.infoGrid:Reposition();
	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIFamilyListPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end

return UIFamilyListPanel
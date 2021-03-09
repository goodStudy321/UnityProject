--// 红包列表面板
require("UI/UIFamily/UIFRedPacketItem");

UIFRedPListPanel = Super:New{Name = "UIFRedPListPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIFRedPListPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.init = false;

	local tip = "UI红包列表面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 记录条目克隆主体
	panelCtrl.itemMainObj = T(panelCtrl.rootTrans, "ItemCont/ItemSV/Grid/Item_99");


	--// 滚动区域
	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "ItemCont/ItemSV", tip, false);
	--// 排序控件
	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "ItemCont/ItemSV/Grid", tip, false);
	

	--// 道庭红包领取列表更新
	panelCtrl.OnNewData = EventHandler(self.NewGetRedPacketArrive, self);
	EventMgr.Add("NewGetRedPacket", panelCtrl.OnNewData);
	EventMgr.Add("NewRedPContList", panelCtrl.OnNewData);


	--// 道庭红包条目列表
	panelCtrl.itemList = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.mOpen = false;
	panelCtrl.init = true;
end

--// 打开面板
function UIFRedPListPanel:Open()
	panelCtrl.mOpen = true;
	self:ShowData();
end

--// 关闭面板
function UIFRedPListPanel:Close()
	panelCtrl.mOpen = false;
end

--// 销毁释放面板
function UIFRedPListPanel:Dispose()
	EventMgr.Remove("NewGetRedPacket", panelCtrl.OnNewData);
	EventMgr.Remove("NewRedPContList", panelCtrl.OnNewData);

	for i = 1, #panelCtrl.itemList do
		ObjPool.Add(panelCtrl.itemList[i]);
	end
	panelCtrl.itemList ={};

	panelCtrl.init = false;
end

--// 更新
function UIFRedPListPanel:Update()
	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.itemsSV:ResetPosition();
		end
	end
end

--// 新领取红包数据到达
function UIFRedPListPanel:NewGetRedPacketArrive()
	if panelCtrl.mOpen == false then
		return;
	end

	self:ShowData();
end

--// 显示数据
--// 1、未发送；2、未领取；3、已领取；4、已领完
function UIFRedPListPanel:ShowData()
	local rpList1, rpList2, rpList3, rpList4 = FamilyMgr:GetAllRedPacketData();
	local allNum = #rpList1 + #rpList2 + #rpList3 + #rpList4;

	self:RenewItemNum(allNum);
	local calIndex = 1;
	for i = 1, #rpList1 do
		panelCtrl.itemList[calIndex]:ShowData(rpList1[i], 1);
		calIndex = calIndex + 1;
	end
	for i = 1, #rpList2 do
		panelCtrl.itemList[calIndex]:ShowData(rpList2[i], 2);
		calIndex = calIndex + 1;
	end
	for i = 1, #rpList3 do
		panelCtrl.itemList[calIndex]:ShowData(rpList3[i], 3);
		calIndex = calIndex + 1;
	end
	for i = 1, #rpList4 do
		panelCtrl.itemList[calIndex]:ShowData(rpList4[i], 4);
		calIndex = calIndex + 1;
	end
end

--// 克隆帮派物品条目
function UIFRedPListPanel:CloneItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.itemMainObj);
	cloneObj.transform.parent = panelCtrl.itemMainObj.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.itemMainObj.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.itemMainObj.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.itemMainObj.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIFRedPacketItem);
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

--// 重置帮派装备数量
function UIFRedPListPanel:RenewItemNum(number)
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
function UIFRedPListPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end
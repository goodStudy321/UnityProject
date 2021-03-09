--// 红包记录面板
require("UI/Cmn/UITextBox");

UIFRedPRecordPanel = Super:New{Name = "UIFRedPRecordPanel"}

local panelCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化面板
function UIFRedPRecordPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.init = false;

	local tip = "UI红包记录面板"

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
	

	panelCtrl.OnNewData = EventHandler(self.NewRecordLog, self);
	EventMgr.Add("NewRedPacketRecord", panelCtrl.OnNewData);


	--// 帮派成员条目列表
	panelCtrl.itemList = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;

	panelCtrl.mOpen = false;
	panelCtrl.init = true;
end

--// 打开面板
function UIFRedPRecordPanel:Open()
	panelCtrl.mOpen = true;
	self:ShowData();
end

--// 关闭面板
function UIFRedPRecordPanel:Close()
	panelCtrl.mOpen = false;
end

--// 销毁释放面板
function UIFRedPRecordPanel:Dispose()
	EventMgr.Remove("NewRedPacketRecord", panelCtrl.OnNewData);

	for i = 1, #panelCtrl.itemList do
		ObjPool.Add(panelCtrl.itemList[i]);
	end
	panelCtrl.itemList ={};

	panelCtrl.init = false;
end

--// 更新
function UIFRedPRecordPanel:Update()
	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.itemsSV:ResetPosition();
		end
	end
end

--// 
function UIFRedPRecordPanel:ShowData()
	local logTbl = FamilyMgr:GetRedPacketRecord();
	if logTbl == nil or #logTbl <= 0 then
		self:RenewItemNum(0);
		return;
	end

	self:RenewItemNum(#logTbl);
	for i = 1, #logTbl do
		local textTbl = {};
		--// 名称
		
		--// 来源
		local tFrom = RedPAward[tostring(logTbl[i].from)];
		if tFrom == nil then
			iError("LY", "Red packet from can not find !!! "..logTbl[i].from);
			textTbl[#textTbl + 1] = "[E9AC50FF]"..logTbl[i].senderName..",[-][B1A495FF]获得[-]";
		else
			textTbl[#textTbl + 1] = "[E9AC50FF]"..logTbl[i].senderName..",[-][B1A495FF]"..tFrom.from.."获得[-]";
		end
		--//
		textTbl[#textTbl + 1] = tostring(logTbl[i].amount).."绑定元宝红包";

		panelCtrl.itemList[i]:LinkItem(textTbl, nil, nil);
	end
end

--// 新记录数据到达
function UIFRedPRecordPanel:NewRecordLog()
	if panelCtrl.mOpen == false then
		return;
	end
	self:ShowData();
end

--// 克隆帮派物品条目
function UIFRedPRecordPanel:CloneItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.itemMainObj);
	cloneObj.transform.parent = panelCtrl.itemMainObj.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.itemMainObj.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.itemMainObj.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.itemMainObj.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UITextBox);
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
function UIFRedPRecordPanel:RenewItemNum(number)
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
function UIFRedPRecordPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end
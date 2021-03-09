--// 地图分线列表
require("UI/UIFamily/UIBtnItem");

UIMapLineList = Super:New{Name = "UIMapLineList"}

local eLog = iTrace.eLog;
local eError = iTrace.eError;

local MAX_SHOW_BTN_NUM = 4;

local panelCtrl = {}


--// 初始化面板
function UIMapLineList:Init(panelObject)
    if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

    panelCtrl.self = self;
	panelCtrl.init = false;

    local C = ComTool.Get;
    local CF = ComTool.GetSelf;
    local T = TransTool.FindChild;

    local tip = "地图分线列表"

    --// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

    --// 弹出菜单部分
    panelCtrl.popPartObj = T(panelCtrl.rootTrans, "LineBtn/PopPart");
    --// 选线按钮
    panelCtrl.lineBtnObj = T(panelCtrl.rootTrans, "LineBtn");
    --// 遮罩面板按钮物体
    panelCtrl.maskBgObj = T(panelCtrl.rootTrans, "LineBtn/PopPart/MaskBg");
    --// 分线按钮克隆主体
	panelCtrl.itemMain = T(panelCtrl.rootTrans, "LineBtn/PopPart/BtnSV/Grid/Item_99");


    --// 当前选择分线名称
    panelCtrl.curLineName = C(UILabel, panelCtrl.rootTrans, "LineBtn/title", tip, false);
    --// 展开标志
    panelCtrl.foldSign = C(UISprite, panelCtrl.rootTrans, "LineBtn/fold", tip, false);
    --// 滚动区域
	panelCtrl.itemsSV = C(UIScrollView, panelCtrl.rootTrans, "LineBtn/PopPart/BtnSV", tip, false);
	--// 排序控件
    panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "LineBtn/PopPart/BtnSV/Grid", tip, false);
    --// 背景
	panelCtrl.bgSprite = C(UISprite, panelCtrl.rootTrans, "LineBtn/PopPart/PopBg", tip, false);

    --// 连接选线按钮
    UITool.SetBtnSelf(panelCtrl.lineBtnObj, self.ShowPopPart, self, self.Name);
    --// 关闭下拉菜单
    UITool.SetBtnSelf(panelCtrl.maskBgObj, self.HidePopPart, self, self.Name);

    panelCtrl.OnNewData = EventHandler(self.ShowData, self);
	EventMgr.Add("NewLineList", panelCtrl.OnNewData);


    --// 道庭成员条目列表
    panelCtrl.itemList = {};
    --// 打开下拉菜单面板
    panelCtrl.openPPart = false;
    --// 延迟重置倒数
    panelCtrl.delayResetCount = 0;
    
    panelCtrl.init = true;
end

--// 弹出下拉菜单
function UIMapLineList:ShowPopPart()
    if panelCtrl.openPPart == true then
        return;
    end

    local lineList = MapMgr:GetLineList();
    if lineList == nil or #lineList <= 0 then
        UITip.Log("当前不能切换分线！");
        return;
    end

    panelCtrl.popPartObj:SetActive(true);
    panelCtrl.foldSign.spriteName = "ty_13";

    self:DelayResetSVPosition();

    panelCtrl.openPPart = true;
end

--// 隐藏下拉菜单
function UIMapLineList:HidePopPart()
    if panelCtrl.openPPart == false then
        return;
    end

    panelCtrl.popPartObj:SetActive(false);
    panelCtrl.foldSign.spriteName = "ty_11";

    panelCtrl.openPPart = false;
end

--// 
function UIMapLineList:Open()
    MapMgr:TryToGetLineInfo();
    self:HidePopPart();
    self:ShowData();
end

--// 
function UIMapLineList:Close()
    
end

--// 
function UIMapLineList:Update()
    if panelCtrl.init == nil or panelCtrl.init == false then
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

--// 销毁释放窗口
function UIMapLineList:Dispose()
    EventMgr.Remove("NewLineList", panelCtrl.OnNewData);

    for i = 1, #panelCtrl.itemList do
		ObjPool.Add(panelCtrl.itemList[i]);
	end
    panelCtrl.itemList = {};
    
    panelCtrl.openPPart = false;
    panelCtrl.init = false;
end

--// 显示分线信息
function UIMapLineList:ShowData()
    local curSInfo = SceneTemp[tostring(MapMgr:GetCurSceneId())];
    if curSInfo == nil then
        panelCtrl.curLineName.text = "---------";
        return;
    end

    local lineList = MapMgr:GetLineList();
    if lineList == nil or #lineList <= 0 then
        local curLineId = MapMgr:GetCurLineId();
        if curLineId > 0 then
            panelCtrl.curLineName.text = StrTool.Concat(curSInfo.name, tostring(MapMgr:GetCurLineId()), "线");
        else
            panelCtrl.curLineName.text = curSInfo.name;
        end

        return;
    end

    local scnName = curSInfo.name;
    local curLineId = MapMgr:GetCurLineId();
    local sName = StrTool.Concat(scnName, tostring(curLineId), "线");
    panelCtrl.curLineName.text = sName;

    self:RenewItemNum(#lineList);
    for i = 1, #lineList do
        sName = StrTool.Concat(scnName, tostring(lineList[i]), "线");
        panelCtrl.itemList[i]:SetBtnName(sName);
        panelCtrl.itemList[i]:SetClickEvent(function() self:ClickLineBtn(lineList[i]) end);

        if i == curLineId then
            panelCtrl.itemList[i]:SetSelect(true);
        else
            panelCtrl.itemList[i]:SetSelect(false);
        end
    end
end

--// 点击分线按钮
function UIMapLineList:ClickLineBtn(lineId)
    if SceneMgr:IsChangeScene() == false then
        UITip.Log("当前不能切换分线！");
        return;
    end

    local curLineId = MapMgr:GetCurLineId();
    if curLineId == lineId then
        self:HidePopPart();
        return;
    end

    SceneMgr:ReqPreEnter(MapMgr:GetCurSceneId(), false, true, lineId);
end

--// 克隆帮派物品条目
function UIMapLineList:CloneItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.itemMain);
	cloneObj.transform.parent = panelCtrl.itemMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.itemMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.itemMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.itemMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIBtnItem);
	cloneItem:Init(cloneObj);

	local newName = "";
	if #panelCtrl.itemList + 1 >= 100 then
		newName = string.gsub(panelCtrl.itemMain.name, "99", tostring(#panelCtrl.itemList + 1));
	elseif #panelCtrl.itemList + 1 >= 10 then
		newName = string.gsub(panelCtrl.itemMain.name, "99", "0"..tostring(#panelCtrl.itemList + 1));
	else
		newName = string.gsub(panelCtrl.itemMain.name, "99", "00"..tostring(#panelCtrl.itemList + 1));
	end
	cloneObj.name = newName;
	panelCtrl.itemList[#panelCtrl.itemList + 1] = cloneItem;

	return cloneItem;
end

--// 重置帮派装备数量
function UIMapLineList:RenewItemNum(number)
	for a = 1, #panelCtrl.itemList do
		panelCtrl.itemList[a]:Show(false)
    end
    
    if number > MAX_SHOW_BTN_NUM then
        panelCtrl.bgSprite.height = 48 * MAX_SHOW_BTN_NUM + 4;
    else
        panelCtrl.bgSprite.height = 48 * number + 4;
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
function UIMapLineList:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end
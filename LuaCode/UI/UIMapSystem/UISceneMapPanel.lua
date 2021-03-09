--// 场景地图面板
require("UI/UIMapSystem/UIMapLineList");
require("UI/UIMapSystem/UIMapIcon");
require("UI/UIFamily/UIBtnItem");
require("UI/UIOffLineHang/UIHangTip");
require("UI/UIMapSystem/UIMapGLstItem");
UISceneMapPanel = Super:New{Name = "UISceneMapPanel"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;


local panelCtrl = {}

--// 初始化面板
function UISceneMapPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;

	local C = ComTool.Get
	local T = TransTool.FindChild

	local tip = "UI场景地图面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;
	--挂机的显示tip加载
	panelCtrl.UIHangTip=T(panelCtrl.rootTrans,"UIHangTip");
	panelCtrl.UHT = UIHangTip
	panelCtrl.UHT:Init(panelCtrl.UIHangTip.transform);
	--// 主角图标
	panelCtrl.meIcon = T(panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex/Boku");
	--// 跳转口根节点
	panelCtrl.portalNode = T(panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex/PortalNode");
	--// npc根节点
	panelCtrl.npcNode = T(panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex/NpcNode");
	--// 怪物根节点
	panelCtrl.evilNode = T(panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex/EvilNode");

	--// 跳转点克隆物体
	panelCtrl.portalMain = T(panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex/PortalNode/Portal_99");
	--// Npc克隆物体
	panelCtrl.npcMain = T(panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex/NpcNode/Npc_99");
	--// 怪物克隆物体
	panelCtrl.evilMain = T(panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex/EvilNode/Evil_99");
	--// Boss克隆物体
	panelCtrl.bossMain = T(panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex/EvilNode/Boss_99");

	--// 克隆主体
	--panelCtrl.tblMain = T(panelCtrl.rootTrans, "InfoListPanel/SV/Table/TblItem_99");
	--// 克隆主体
	panelCtrl.desItemMain = T(panelCtrl.rootTrans, "InfoListPanel/SV/Grid/Item_99");
	panelCtrl.desItemMain:SetActive(false);


	--// 转换按钮1
	panelCtrl.tagBtn1Obj = T(panelCtrl.rootTrans, "InfoListPanel/TagCont/Tag1");
	--// 转换按钮2
	panelCtrl.tagBtn2Obj = T(panelCtrl.rootTrans, "InfoListPanel/TagCont/Tag2");
	--// 转换按钮3
	panelCtrl.tagBtn3Obj = T(panelCtrl.rootTrans, "InfoListPanel/TagCont/Tag3");
	--// 下拉菜单物体
	panelCtrl.linePanelObj = T(panelCtrl.rootTrans, "InfoListPanel/LinePanel");

	panelCtrl.tagList = {};
	panelCtrl.tagList[#panelCtrl.tagList + 1] = ObjPool.Get(UIBtnItem);
	panelCtrl.tagList[#panelCtrl.tagList]:Init(panelCtrl.tagBtn1Obj, function() self:ChangeTag(1); end);
	panelCtrl.tagList[#panelCtrl.tagList + 1] = ObjPool.Get(UIBtnItem);
	panelCtrl.tagList[#panelCtrl.tagList]:Init(panelCtrl.tagBtn2Obj, function() self:ChangeTag(2); end);
	panelCtrl.tagList[#panelCtrl.tagList + 1] = ObjPool.Get(UIBtnItem);
	panelCtrl.tagList[#panelCtrl.tagList]:Init(panelCtrl.tagBtn3Obj, function() self:ChangeTag(3); end);


	--// 小地图Panel
	panelCtrl.maskPanel = C(UIPanel, panelCtrl.rootTrans, "MapPanel/Offset/MapMask", tip, false);
	--// 小地图滚动框
	panelCtrl.maskSV = C(UIScrollView, panelCtrl.rootTrans, "MapPanel/Offset/MapMask", tip, false);
	--// 小地图渲染图
	panelCtrl.mapTex = C(UITexture, panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex", tip, false);
	--// 排序控件
	panelCtrl.itemGrid = C(UIGrid, panelCtrl.rootTrans, "InfoListPanel/SV/Grid", tip, false);
	--// 滚动区域
	panelCtrl.itemSV = C(UIScrollView, panelCtrl.rootTrans, "InfoListPanel/SV", tip, false);
	--// 排序控件
	--panelCtrl.tblTbl = C(UITable, panelCtrl.rootTrans, "InfoListPanel/SV/Table", tip, false);
	panelCtrl.boxCol = C(UnityEngine.BoxCollider, panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex", tip, false);
	--// 小地图名称图
	panelCtrl.mapNameTex = C(UITexture, panelCtrl.rootTrans, "MapPanel/NameBg/NameTex", tip, false);
	--// 小地图简介图
	panelCtrl.mapDesTex = C(UITexture, panelCtrl.rootTrans, "MapPanel/NameBg/DesTex", tip, false);

	--// 转换面板按钮
	-- local com = C(UIButton, panelCtrl.rootTrans, "MapPanel/WBtnCon/WIcon", tip, false)
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	--  	UIMapWnd:OpenWorldMapPanel();
	-- end;

	--// 点击小地图
	com = C(UIButton, panelCtrl.rootTrans, "MapPanel/Offset/MapMask/MapTex", tip, false)
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
	 	self:TryMoveToNewPos();
	end;

	--// 点击前往
	com = C(UIButton, panelCtrl.rootTrans, "InfoListPanel/Gobtn", tip, false)
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
	 	self:TryMoveToSelPot();
	end;

	--// 点击缩小地图
	panelCtrl.slider = C(UISlider, panelCtrl.rootTrans, "MapPanel/SliderCont/MapSlider", tip, false);

	UITool.SetBtnClick(panelCtrl.rootTrans, "CloseBtn", des, self.CloseWnd, self);

	UIMapLineList:Init(panelCtrl.linePanelObj);


	--// 遮罩区域长度
	panelCtrl.viewSize = panelCtrl.maskPanel:GetViewSize().x;
	--// UI中地图宽度(1:1, 和高度相同)
	panelCtrl.mapUIWidth = 0;
	--// 场景中地图宽度(强制1:1，取长度大的一端作为标准)
	panelCtrl.mapSNWidth = 0;
	--// 小地图起始位置
	panelCtrl.mapStartPos = Vector2.New(0, 0);
	--// 当前加载场景Id
	panelCtrl.loadSceneId = -1;
	--// 地图旋转角度
	panelCtrl.rotAngle = 0;

	--// 最大缩放等级数量
	panelCtrl.maxSizeLv = MapMgr:GetScaleLvNum();
	--// 当前缩放等级
	panelCtrl.curSizeLv = 1;

	panelCtrl.portalList = {};
	panelCtrl.npcList = {};
	panelCtrl.evilList = {};
	panelCtrl.bossList = {};

	--self:InitData();

	--// table列表
	--panelCtrl.tblList = {};
	--// 道庭成员条目列表
	panelCtrl.itemCells = {};
	--// 延迟重置倒数
	panelCtrl.delayResetCount = 0;
	--// 选择地图点类型
	panelCtrl.curSelPotType = 0;
	--// 当前选择地图点信息
	panelCtrl.curSelPotInfo = nil;
	--// 当前选定条目
	panelCtrl.curSelItem = nil;
	--// 选择显示面板类型
	panelCtrl.tagType = 0;

	panelCtrl.open = false;
	panelCtrl.init = true;
end

--// 打开面板
function UISceneMapPanel:Open()
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.open = true;

	local texPos = MapHelper.instance:ChangePosToUICamera(panelCtrl.mapTex.gameObject.transform.position);
	panelCtrl.mapStartPos = Vector2.New(texPos.x, texPos.y);

	self:ResetMapSize();
	self:CheckLoadMiniMap();
	self:ShowData();

	--self:ChangeTag(1);
	self:OpenTryChangeTag();

	UIMapLineList:Open();
end

--// 关闭面板
function UISceneMapPanel:Close()
	if panelCtrl.curSelItem ~= nil then
		panelCtrl.curSelItem:SetSel(false);
		panelCtrl.curSelItem = nil;
	end

	panelCtrl.curSelPotType = 0;
	panelCtrl.tagType = 0;
	panelCtrl.curSelPotInfo = nil;

	-- panelCtrl.tblList[1]:CloseWndReset();
	-- panelCtrl.tblList[2]:CloseWndReset();
	-- panelCtrl.tblList[3]:CloseWndReset();

	UIMapLineList:Close();

	panelCtrl.panelObj:SetActive(false);
	panelCtrl.open = false;
end

--// 更新
function UISceneMapPanel:Update()
	if panelCtrl.open == false then
		return;
	end

	UIMapLineList:Update();

	if panelCtrl.delayResetCount > 0 then
		panelCtrl.delayResetCount = panelCtrl.delayResetCount - 1;
		if panelCtrl.delayResetCount <= 0 then
			panelCtrl.delayResetCount = 0;
			panelCtrl.itemSV:ResetPosition();
		end
	end

	self:UpdateBokuTrans();

	if panelCtrl.slider.value == 0 then
		panelCtrl.boxCol.enabled = false;
		self:ChangeMapSize(1);
	elseif panelCtrl.slider.value == 0.5 then
		panelCtrl.boxCol.enabled = true;
		self:ChangeMapSize(2);
	elseif panelCtrl.slider.value == 1 then
		panelCtrl.boxCol.enabled = true;
		self:ChangeMapSize(3);
	end
end

--// 销毁释放窗口
function UISceneMapPanel:Dispose()
	if panelCtrl.init == false then
		return;
	end

	UIMapLineList:Dispose();

	if panelCtrl.mapTex.mainTexture ~= nil then
		-- local texName = StrTool.Concat(panelCtrl.mapTex.mainTexture.name, ".jpg");
		local texName = panelCtrl.mapTex.mainTexture.name;
		AssetMgr.Instance:Unload(texName, ".jpg", false);
		-- UITool.UnloadTex(panelCtrl.mapTex);
		panelCtrl.mapTex = nil;
	end
	if panelCtrl.mapNameTex.mainTexture ~= nil then
		-- local texName = StrTool.Concat(panelCtrl.mapNameTex.mainTexture.name, ".png");
		local texName = panelCtrl.mapNameTex.mainTexture.name;
		AssetMgr.Instance:Unload(texName, ".png", false);
		-- UITool.UnloadTex(panelCtrl.mapNameTex);
		panelCtrl.mapNameTex = nil;
	end
	if panelCtrl.mapDesTex.mainTexture ~= nil then
		-- local texName = StrTool.Concat(panelCtrl.mapDesTex.mainTexture.name, ".png");
		local texName = panelCtrl.mapDesTex.mainTexture.name;
		AssetMgr.Instance:Unload(texName, ".png", false);
		-- UITool.UnloadTex(panelCtrl.mapDesTex);
		panelCtrl.mapDesTex = nil;
	end

	for i = 1, #panelCtrl.portalList do
		ObjPool.Add(panelCtrl.portalList[i]);
	end
	panelCtrl.portalList ={};

	for i = 1, #panelCtrl.npcList do
		ObjPool.Add(panelCtrl.npcList[i]);
	end
	panelCtrl.npcList ={};

	for i = 1, #panelCtrl.evilList do
		ObjPool.Add(panelCtrl.evilList[i]);
	end
	panelCtrl.evilList ={};

	for i = 1, #panelCtrl.bossList do
		ObjPool.Add(panelCtrl.bossList[i]);
	end
	panelCtrl.bossList ={};

	-- for i = 1, #panelCtrl.tblList do
	-- 	panelCtrl.tblList[i]:Dispose();
	-- 	ObjPool.Add(panelCtrl.tblList[i]);
	-- end
	-- panelCtrl.tblList ={};

	for i = 1, #panelCtrl.itemCells do
		ObjPool.Add(panelCtrl.itemCells[i]);
	end
	panelCtrl.itemCells ={};

	panelCtrl.loadSceneId = -1;
	panelCtrl.rotAngle = 0;

	panelCtrl.init = false;
end

--// 重置地图大小
function UISceneMapPanel:ResetMapSize()
	panelCtrl.mapUIWidth = MapMgr:GetSizeLvByIndex(panelCtrl.curSizeLv);
	--panelCtrl.mapTex.localSize = Vector2.New(panelCtrl.mapUIWidth, panelCtrl.mapUIWidth);
	panelCtrl.mapTex:SetRect(-panelCtrl.viewSize / 2, -panelCtrl.viewSize / 2, panelCtrl.mapUIWidth, panelCtrl.mapUIWidth);

	--panelCtrl.mapUIWidth = panelCtrl.mapTex.localSize.x;
end

--// 显示数据
function UISceneMapPanel:ShowData()
	self:RenewPortal();
	self:RenewNpc();
	self:RenewEvil();
	--self:RenewTblData();

	self:UpdateBokuTrans();
end

--// 刷新跳转口数据
function UISceneMapPanel:RenewPortal()
	local portalInfos = MapMgr:GetPortalInfo();
	local protalNum = 0
	if portalInfos ~= nil then
		protalNum = #portalInfos;
	end
	self:RenewItemCellNum(panelCtrl.portalList, panelCtrl.portalMain, protalNum, false, nil);

	if portalInfos == nil then
		return;
	end

	local showName = true;
	if panelCtrl.curSizeLv < 2 then
		showName = false;
	end
	for i = 1, #portalInfos do
		local calPos = portalInfos[i].pos;
		local posScl = MapHelper.instance:CalPosSInMap(calPos);
		portalInfos[i].mapPos = Vector3.New(panelCtrl.mapUIWidth * posScl.x, panelCtrl.mapUIWidth * posScl.y, 0);

		--// new begin
		local uiMapCenPot = Vector3.New(panelCtrl.mapUIWidth / 2, panelCtrl.mapUIWidth / 2, 0);
		portalInfos[i].mapPos = MapHelper.instance:RotateAround(portalInfos[i].mapPos, uiMapCenPot, Vector3.New(0, 0, 1), panelCtrl.rotAngle);
		--// new end

		panelCtrl.portalList[i]:ShowData(portalInfos[i], showName);
	end
end

--// 刷新Npc数据
function UISceneMapPanel:RenewNpc()
	local npcInfos = MapMgr:GetNpcInfo();
	local npcInfNum = 0;
	if npcInfos ~= nil then
		npcInfNum = #npcInfos;
	end
	self:RenewItemCellNum(panelCtrl.npcList, panelCtrl.npcMain, npcInfNum, false, nil);

	local showName = true;
	if panelCtrl.curSizeLv < 2 then
		showName = false;
	end
	for i = 1, npcInfNum do
		local calPos = npcInfos[i].pos;
		local posScl = MapHelper.instance:CalPosSInMap(calPos);
		npcInfos[i].mapPos = Vector3.New(panelCtrl.mapUIWidth * posScl.x, panelCtrl.mapUIWidth * posScl.y, 0);

		--// new begin
		local uiMapCenPot = Vector3.New(panelCtrl.mapUIWidth / 2, panelCtrl.mapUIWidth / 2, 0);
		npcInfos[i].mapPos = MapHelper.instance:RotateAround(npcInfos[i].mapPos, uiMapCenPot, Vector3.New(0, 0, 1), panelCtrl.rotAngle);
		--// new end

		panelCtrl.npcList[i]:ShowData(npcInfos[i], showName);
	end
end

--// 刷新刷怪点数据
function UISceneMapPanel:RenewEvil()
	local evilInfos = MapMgr:GetEvilInfo();
	local evilInfoNum  = 0;
	if evilInfos ~= nil then
		evilInfoNum = #evilInfos;
	end
	local evilNum = 0;
	local bossNum = 0;

	for i = 1, evilInfoNum do
		if evilInfos[i].isSpec == true then
			bossNum = bossNum + 1;
		else
			evilNum = evilNum + 1;
		end
	end

	self:RenewItemCellNum(panelCtrl.evilList, panelCtrl.evilMain, evilNum, false, nil);
	self:RenewItemCellNum(panelCtrl.bossList, panelCtrl.bossMain, bossNum, false, nil);

	local showName = true;
	if panelCtrl.curSizeLv < 2 then
		showName = false;
	end
	local evilInd = 1;
	local bossInd = 1;
	for i = 1, evilInfoNum do
		local calPos = evilInfos[i].pos;
		local posScl = MapHelper.instance:CalPosSInMap(calPos);
		evilInfos[i].mapPos = Vector3.New(panelCtrl.mapUIWidth * posScl.x, panelCtrl.mapUIWidth * posScl.y, 0);

		--// new begin
		local uiMapCenPot = Vector3.New(panelCtrl.mapUIWidth / 2, panelCtrl.mapUIWidth / 2, 0);
		evilInfos[i].mapPos = MapHelper.instance:RotateAround(evilInfos[i].mapPos, uiMapCenPot, Vector3.New(0, 0, 1), panelCtrl.rotAngle);
		--// new end

		if evilInfos[i].isSpec == true then
			panelCtrl.bossList[bossInd]:ShowData(evilInfos[i], showName);
			bossInd = bossInd + 1;
		else
			panelCtrl.evilList[evilInd]:ShowData(evilInfos[i], showName);
			evilInd = evilInd + 1;
		end
	end
end

--// 刷新列表数据
-- function UISceneMapPanel:RenewTblData()
-- 	local portalInfos = MapMgr:GetPortalInfo();
-- 	local npcInfos = MapMgr:GetNpcInfo();
-- 	local evilInfos = MapMgr:GetEvilInfo();

-- 	--self:RenewTblNum(3);

-- 	-- panelCtrl.tblList[1]:LinkAndConfig("指引Npc", 1, npcInfos, self);
-- 	-- panelCtrl.tblList[2]:LinkAndConfig("怪物点", 2, evilInfos, self);
-- 	-- panelCtrl.tblList[3]:LinkAndConfig("传送点", 3, portalInfos, self);

-- 	self:DelayResetSVPosition();
-- end

--// 选择地图点
function UISceneMapPanel:SelectMapPoint(potType, potInfo, item)
	if panelCtrl.curSelItem ~= nil then
		panelCtrl.curSelItem:SetSel(false);
	end

	panelCtrl.curSelPotType = potType;
	panelCtrl.curSelPotInfo = potInfo;
	panelCtrl.curSelItem = item;

	if panelCtrl.curSelItem ~= nil then
		panelCtrl.curSelItem:SetSel(true);
	end
end

--// 尝试移动到选择的地图点
function UISceneMapPanel:TryMoveToSelPot()
	if panelCtrl.curSelPotInfo == nil then
		UITip.Log("请选择地点");
		return;
	end

	--local clickPos = panelCtrl.curSelPotInfo.mapPos;
	--clickPos.x = clickPos.x / panelCtrl.mapUIWidth;
	--clickPos.y = clickPos.y / panelCtrl.mapUIWidth;

	local clickPos = panelCtrl.curSelPotInfo.pos;
	if clickPos == nil then
		return;
	end

	if panelCtrl.curSelPotType == 1 then
		--MapHelper.instance:TryMoveToNewPos(clickPos, 1);
		MapHelper.instance:TryMoveToNewPos2(clickPos, 1);
	else
		--MapHelper.instance:TryMoveToNewPos(clickPos, -1);
		MapHelper.instance:TryMoveToNewPos2(clickPos, -1);
	end
end

--// 尝试移动到新的位置
function UISceneMapPanel:TryMoveToNewPos()
	--print("                                       "..UICamera.lastEventPosition.x.."  "..UICamera.lastEventPosition.y);

	if MapHelper.instance:CanInput() == false then
		iLog("LY", "Input ban !!! ");
		return;
	end

	local clickPos = UICamera.lastEventPosition - panelCtrl.mapStartPos;
	clickPos.x = clickPos.x / panelCtrl.mapUIWidth;
	clickPos.y = clickPos.y / panelCtrl.mapUIWidth;

	MapHelper.instance:TryMoveToNewPos(clickPos, -1);
end


function UISceneMapPanel:ChangeMapSize(sizeLv)
	if panelCtrl.curSizeLv == sizeLv then
		return;
	end

	panelCtrl.curSizeLv = sizeLv;
	self:ResetMapSize();
	self:ShowData();
	self:LocalBokuMapPos();
end

--// 点击放大地图
-- function UISceneMapPanel:ClickLarge()
-- 	panelCtrl.curSizeLv = panelCtrl.curSizeLv + 1;
-- 	if panelCtrl.curSizeLv > panelCtrl.maxSizeLv then
-- 		panelCtrl.curSizeLv = panelCtrl.maxSizeLv;
-- 		return;
-- 	end

-- 	self:ResetMapSize();
-- 	self:ShowData();
-- 	--panelCtrl.maskSV:ResetPosition();
-- 	self:LocalBokuMapPos();
-- end

--// 点击缩小地图
-- function UISceneMapPanel:ClickSmall()
-- 	panelCtrl.curSizeLv = panelCtrl.curSizeLv - 1;
-- 	if panelCtrl.curSizeLv < 1 then
-- 		panelCtrl.curSizeLv = 1;
-- 		return;
-- 	end

-- 	self:ResetMapSize();
-- 	self:ShowData();
-- 	--panelCtrl.maskSV:ResetPosition();
-- 	self:LocalBokuMapPos();
-- end

--// 初始化地图数据
-- function UISceneMapPanel:InitData()
-- 	panelCtrl.mapUIWidth = panelCtrl.mapTex.localSize.x;
-- end

--// 检测读取小地图
function UISceneMapPanel:CheckLoadMiniMap()
	local tSId = MapMgr:GetCurSceneId();
	if tSId == panelCtrl.loadSceneId then
		return;
	end

	panelCtrl.loadSceneId = tSId;
	local sInfo = SceneTemp[tostring(panelCtrl.loadSceneId)];
	if sInfo ~= nil and sInfo.maptex ~= "" then
		self:LoadMiniMap(sInfo.maptex);
		if sInfo.mapRot ~= nil then
			panelCtrl.rotAngle = sInfo.mapRot;
		end
	end
end

--// 读取小地图
function UISceneMapPanel:LoadMiniMap(mapname)
	AssetMgr.Instance:Load(mapname, ObjHandler(self.LoadMapFin, self));

	local mapNameName = string.gsub(mapname, ".jpg", "_name.png");
	AssetMgr.Instance:Load(mapNameName, ObjHandler(self.LoadMapNameFin, self));

	local mapDesName = string.gsub(mapname, ".jpg", "_des.png");
	AssetMgr.Instance:Load(mapDesName, ObjHandler(self.LoadMapDesFin, self));
end

--// 读取地图完成
function UISceneMapPanel:LoadMapFin(obj)
	panelCtrl.mapTex.mainTexture = obj;
end

--// 读取地图名字完成
function UISceneMapPanel:LoadMapNameFin(obj)
	panelCtrl.mapNameTex.mainTexture = obj;
end

--// 读取地图简介完成
function UISceneMapPanel:LoadMapDesFin(obj)
	panelCtrl.mapDesTex.mainTexture = obj;
	panelCtrl.mapDesTex:MakePixelPerfect();
end

--// 更新主角位置信息
function UISceneMapPanel:UpdateBokuTrans()
	local posScl = MapHelper.instance:GetBokuPosSInMap();
	panelCtrl.meIcon.transform.localPosition = Vector3.New(panelCtrl.mapUIWidth * posScl.x, panelCtrl.mapUIWidth * posScl.y, 0);

	--// new begin
	local uiMapCenPot = Vector3.New(panelCtrl.mapUIWidth / 2, panelCtrl.mapUIWidth / 2, 0);
	panelCtrl.meIcon.transform.localPosition = MapHelper.instance:RotateAround(panelCtrl.meIcon.transform.localPosition, uiMapCenPot, Vector3.New(0, 0, 1), panelCtrl.rotAngle);

	panelCtrl.meIcon.transform.localEulerAngles = Vector3.New(0, 0, -MapHelper.instance:GetBokuRotYInMap() + panelCtrl.rotAngle);
	--// new end

	--panelCtrl.meIcon.transform.localEulerAngles = Vector3.New(0, 0, -MapHelper.instance:GetBokuRotYInMap());
end

--// 克隆图标
function UISceneMapPanel:CloneIconItem(iconList, mainObj, canSel, cbEvnt)
	local cloneObj = GameObject.Instantiate(mainObj);
	cloneObj.transform.parent = mainObj.transform.parent;
	cloneObj.transform.localPosition = mainObj.transform.localPosition;
	cloneObj.transform.localRotation = mainObj.transform.localRotation;
	cloneObj.transform.localScale = mainObj.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMapIcon);
	cloneItem:Init(cloneObj, canSel, cbEvnt);
	cloneObj.name = string.gsub(mainObj.name, "99", tostring(#iconList + 1));
	iconList[#iconList + 1] = cloneItem;

	return cloneItem;
end

--// 重置指定图标数量
function UISceneMapPanel:RenewItemCellNum(iconList, mainObj, number, canSel, cbEvnt)
	for a = 1, #iconList do
		iconList[a]:Show(false)
	end

	local realNum = number;
	if realNum <= #iconList then
		for a = 1, realNum do
			iconList[a]:Show(true);
		end
	else
		for a = 1, #iconList do
			iconList[a]:Show(true)
		end

		local needNum = realNum - #iconList;
		for a = 1, needNum do
			self:CloneIconItem(iconList, mainObj, canSel, cbEvnt);
		end
	end
end

--// 克隆
-- function UISceneMapPanel:CloneTable()
--     local Inst = GameObject.Instantiate;
--     local TA = TransTool.AddChild;

--     local cloneObj = Inst(panelCtrl.tblMain);
--     TA(panelCtrl.tblMain.transform.parent, cloneObj.transform);
-- 	cloneObj:SetActive(true);

-- 	local cloneItem = ObjPool.Get(UIMapTblList);
-- 	cloneItem:Init(cloneObj);
-- 	cloneObj.name = string.gsub(panelCtrl.tblMain.name, "99", tostring(#panelCtrl.tblList + 1));
-- 	panelCtrl.tblList[#panelCtrl.tblList + 1] = cloneItem;

-- 	return cloneItem;
-- end

--// 重置数量
-- function UISceneMapPanel:RenewTblNum(number)
-- 	for a = 1, #panelCtrl.tblList do
-- 		panelCtrl.tblList[a]:Show(false);
-- 	end

-- 	local realNum = number;
-- 	if realNum <= #panelCtrl.tblList then
-- 		for a = 1, realNum do
-- 			panelCtrl.tblList[a]:Show(true);
-- 		end
-- 	else
-- 		for a = 1, #panelCtrl.tblList do
-- 			panelCtrl.tblList[a]:Show(true)
-- 		end

-- 		local needNum = realNum - #panelCtrl.tblList;
-- 		for a = 1, needNum do
-- 			self:CloneTable();
-- 		end
-- 	end

-- 	--panelCtrl.tblTbl:Reposition();
-- 	self:DelayResetSVPosition();
-- end

--// 克隆地点条目
function UISceneMapPanel:CloneDesItem()
	local cloneObj = GameObject.Instantiate(panelCtrl.desItemMain);
	cloneObj.transform.parent = panelCtrl.desItemMain.transform.parent;
	cloneObj.transform.localPosition = panelCtrl.desItemMain.transform.localPosition;
	cloneObj.transform.localRotation = panelCtrl.desItemMain.transform.localRotation;
	cloneObj.transform.localScale = panelCtrl.desItemMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMapGLstItem);
	cloneItem:Init(cloneObj);

	local newName = "";
	if #panelCtrl.itemCells + 1 >= 100 then
		newName = string.gsub(panelCtrl.desItemMain.name, "99", tostring(#panelCtrl.itemCells + 1));
	elseif #panelCtrl.itemCells + 1 >= 10 then
		newName = string.gsub(panelCtrl.desItemMain.name, "99", "0"..tostring(#panelCtrl.itemCells + 1));
	else
		newName = string.gsub(panelCtrl.desItemMain.name, "99", "00"..tostring(#panelCtrl.itemCells + 1));
	end
	cloneObj.name = newName;

	panelCtrl.itemCells[#panelCtrl.itemCells + 1] = cloneItem;

	return cloneItem;
end

--// 重置地点条目数量
function UISceneMapPanel:RenewDesItemNum(number)
	for a = 1, #panelCtrl.itemCells do
		panelCtrl.itemCells[a]:Show(false)
		panelCtrl.itemCells[a]:SetSel(false);
	end

	local realNum = number;
	if realNum <= #panelCtrl.itemCells then
		for a = 1, realNum do
			panelCtrl.itemCells[a]:Show(true);
		end
	else
		for a = 1, #panelCtrl.itemCells do
			panelCtrl.itemCells[a]:Show(true)
		end

		local needNum = realNum - #panelCtrl.itemCells;
		for a = 1, needNum do
			self:CloneDesItem();
		end
	end

	panelCtrl.itemGrid:Reposition();

	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UISceneMapPanel:DelayResetSVPosition()
	panelCtrl.delayResetCount = 2;
end


function UISceneMapPanel:LocalBokuMapPos()
	local bokuX = panelCtrl.meIcon.transform.localPosition.x;
	local bokuY = panelCtrl.meIcon.transform.localPosition.y;

	local halfViewSize = panelCtrl.viewSize / 2;

	local lastX = panelCtrl.meIcon.transform.localPosition.x - halfViewSize;
	local lastY = panelCtrl.meIcon.transform.localPosition.y - halfViewSize;

	
	if bokuX < halfViewSize then
		lastX = 0;
	elseif bokuX > panelCtrl.mapUIWidth - halfViewSize then
		lastX = panelCtrl.mapUIWidth - panelCtrl.viewSize;
	end
	if bokuY < halfViewSize then
		lastY = 0;
	elseif bokuY > panelCtrl.mapUIWidth - halfViewSize then
		lastY = panelCtrl.mapUIWidth - panelCtrl.viewSize;
	end

	panelCtrl.maskPanel.transform.localPosition = Vector3.New(-lastX, -lastY, 0);
	panelCtrl.maskPanel.clipOffset = Vector2.New(lastX, lastY);
end


function UISceneMapPanel:OpenTryChangeTag()
	local evilInfos = MapMgr:GetEvilInfo();
	--local npcInfos = MapMgr:GetNpcInfo();

	if evilInfos ~= nil and #evilInfos > 0 then
		self:ChangeTag(1);
	else
		self:ChangeTag(2);
	end
end

--// 转换页面：
--// 1为怪物
--// 2为Npc
--// 3为传送点
function UISceneMapPanel:ChangeTag(tagType)
	if panelCtrl.tagType == tagType then
		return;
	end
	panelCtrl.tagType = tagType;

	for i = 1, #panelCtrl.tagList do
		if i == tagType then
			panelCtrl.tagList[i]:SetSelect(true);
		else
			panelCtrl.tagList[i]:SetSelect(false);
		end
	end

	if tagType == 1 then
		self:RenewEvilInfo();
	elseif tagType == 2 then
		self:RenewNpcInfo();
	elseif tagType == 3 then
		self:RenewPortalInfo();
	end

	panelCtrl.curSelPotType = nil;
	panelCtrl.curSelPotInfo = nil;
	panelCtrl.curSelItem = nil;
end

--// 
function UISceneMapPanel:RenewEvilInfo()
	panelCtrl.evilNode:SetActive(true);
	panelCtrl.npcNode:SetActive(false);
	panelCtrl.portalNode:SetActive(false);

	local evilInfos = MapMgr:GetEvilInfo();
	local eInfNum = 0
	if evilInfos ~= nil then
		eInfNum = #evilInfos;
	end
	self:RenewDesItemNum(eInfNum)
	for i = 1, eInfNum do
		panelCtrl.itemCells[i]:LinkAndConfig(evilInfos[i], 2, self, nil);
		if i % 2 == 0 then
			panelCtrl.itemCells[i]:ShowBg(true);
		else
			panelCtrl.itemCells[i]:ShowBg(false);
		end
	end
end

--// 
function UISceneMapPanel:RenewNpcInfo()
	panelCtrl.evilNode:SetActive(false);
	panelCtrl.npcNode:SetActive(true);
	panelCtrl.portalNode:SetActive(false);

	local npcInfos = MapMgr:GetNpcInfo();
	local npcInfNum = 0;
	if npcInfos ~= nil then
		npcInfNum = #npcInfos;
	end

	self:RenewDesItemNum(npcInfNum)
	for i = 1, npcInfNum do
		panelCtrl.itemCells[i]:LinkAndConfig(npcInfos[i], 1, self, nil);
		if i % 2 == 0 then
			panelCtrl.itemCells[i]:ShowBg(true);
		else
			panelCtrl.itemCells[i]:ShowBg(false);
		end
	end
end

--// 
function UISceneMapPanel:RenewPortalInfo()
	panelCtrl.evilNode:SetActive(false);
	panelCtrl.npcNode:SetActive(true);
	panelCtrl.portalNode:SetActive(false);

	local portalInfos = MapMgr:GetPortalInfo();
	self:RenewDesItemNum(#portalInfos)
	for i = 1, #portalInfos do
		panelCtrl.itemCells[i]:LinkAndConfig(portalInfos[i], 3, self, nil);
		if i % 2 == 0 then
			panelCtrl.itemCells[i]:ShowBg(true);
		else
			panelCtrl.itemCells[i]:ShowBg(false);
		end
	end
end

--// 
function UISceneMapPanel:CloseWnd()
	UIMapWnd:Close();
end
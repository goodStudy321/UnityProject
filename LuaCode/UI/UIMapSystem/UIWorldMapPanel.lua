--// 世界地图面板
require("UI/UIMapSystem/UIMapPotBtn");

UIWorldMapPanel = Super:New{Name = "UIWorldMapPanel"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local panelCtrl = {}

--// 初始化面板
function UIWorldMapPanel:Init(panelObject)

	if panelCtrl.init ~= nil and panelCtrl.init == true then
		return;
	end

	panelCtrl.self = self;
	panelCtrl.init = false;
	--print("LY : UIWorldMapPanel create !!! ")

	local C = ComTool.Get
	local T = TransTool.FindChild

	local tip = "UI世界地图面板"

	--// 设置面板物体
	panelCtrl.panelObj = panelObject;
	--// 面板transform
	panelCtrl.rootTrans = panelCtrl.panelObj.transform;

	--// 上锁地区物体
	self.lockAreaObj = T(panelCtrl.rootTrans, "MapTex/LockArea");

	--// 按钮物体列表
	panelCtrl.btnObjs = {};
	panelCtrl.btnObjs[1] = T(panelCtrl.rootTrans, "SceneBtn1");
	panelCtrl.btnObjs[2] = T(panelCtrl.rootTrans, "SceneBtn2");
	panelCtrl.btnObjs[3] = T(panelCtrl.rootTrans, "SceneBtn3");
	panelCtrl.btnObjs[4] = T(panelCtrl.rootTrans, "SceneBtn4");
	panelCtrl.btnObjs[5] = T(panelCtrl.rootTrans, "SceneBtn5");
	panelCtrl.btnObjs[6] = T(panelCtrl.rootTrans, "SceneBtn6");
	panelCtrl.btnObjs[7] = T(panelCtrl.rootTrans, "SceneBtn7");
	panelCtrl.btnObjs[8] = T(panelCtrl.rootTrans, "SceneBtn8");
	panelCtrl.btnObjs[9] = T(panelCtrl.rootTrans, "SceneBtn9");
	panelCtrl.btnObjs[10] = T(panelCtrl.rootTrans, "SceneBtn10");

	--// 转换面板按钮
	-- local com = C(UIButton, panelCtrl.rootTrans, "ReturnBtn", tip, false)
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	--  	UIMapWnd:OpenSceneMapPanel();
	-- end;

	panelCtrl.btns = {}
	local tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[1], 1);
	panelCtrl.btns[1] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[2], 2);
	panelCtrl.btns[2] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[3], 3);
	panelCtrl.btns[3] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[4], 4);
	panelCtrl.btns[4] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[5], 5);
	panelCtrl.btns[5] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[6], 6);
	panelCtrl.btns[6] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[7], 7);
	panelCtrl.btns[7] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[8], 8);
	panelCtrl.btns[8] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[9], 9);
	panelCtrl.btns[9] = tBtn;

	tBtn = ObjPool.Get(UIMapPotBtn);
	tBtn:Init(panelCtrl.btnObjs[10], 10);
	panelCtrl.btns[10] = tBtn;
	
	local EH = EventHandler;
	panelCtrl.UpTC = EH(self.CheckBtnLock, self);
	EventMgr.Add("OnChangeExp", panelCtrl.UpTC);

	UITool.SetBtnClick(panelCtrl.rootTrans, "CloseBtn", des, self.CloseWnd, self);

	panelCtrl.open = false;
	panelCtrl.init = true;
end

--// 打开面板
function UIWorldMapPanel:Open()
	panelCtrl.panelObj:SetActive(true);
	panelCtrl.open = true;

	self:ShowSceneName();
	self:CheckBtnLock();


	local index = MapMgr:GetMapIdToBtnIndex(MapMgr:GetCurSceneId());
	for i = 1, #panelCtrl.btns do
		panelCtrl.btns[i]:ShowIcon(false);
	end
	if index > 0 then
		panelCtrl.btns[index]:ShowIcon(true);
	end
end

--// 关闭面板
function UIWorldMapPanel:Close()
	panelCtrl.panelObj:SetActive(false);
	panelCtrl.open = false;
end

--// 销毁释放窗口
function UIWorldMapPanel:Dispose()
	panelCtrl.init = false;
	EventMgr.Remove("OnChangeExp", panelCtrl.UpTC);
	panelCtrl.UpTC = nil;

	for i = 1, #panelCtrl.btns do
		ObjPool.Add(panelCtrl.btns[i]);
	end
end

--// 显示场景名称
function UIWorldMapPanel:ShowSceneName()
	local nameList = MapMgr:GetSceneNameList();
	for i = 1, #nameList do
			panelCtrl.btns[i]:SetSceneName(nameList[i]);
	end
end

--// 检测等级锁开放
function UIWorldMapPanel:CheckBtnLock()
	for i = 1, #panelCtrl.btns do
		panelCtrl.btns[i]:SetLock(true);
	end

	local unlockList = MapMgr:GetSceneUnlockList();
	for i = 1, #unlockList do
		-- if unlockList[i] <= 0 then
		-- 	panelCtrl.btns[i]:SetLock(false, 0);
		-- else
		-- 	panelCtrl.btns[i]:SetLock(true, unlockList[i]);
		-- end
		panelCtrl.btns[i]:SetLock(unlockList[i].unLock, unlockList[i].unLockLv);
	end
end

--// 显示隐藏区域
function UIWorldMapPanel:ShowLockArea(isShow)
	self.lockAreaObj:SetActive(isShow);
end

--// 
function UIWorldMapPanel:CloseWnd()
	UIMapWnd:Close();
end
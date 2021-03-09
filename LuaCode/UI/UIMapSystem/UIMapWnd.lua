--// 地图界面
require("UI/UIMapSystem/UISceneMapPanel")
require("UI/UIMapSystem/UIWorldMapPanel")

UIMapWnd = UIBase:New{Name = "UIMapWnd"}

local winCtrl = {}


--// 初始化界面
--// 链接所有操作物体
function UIMapWnd:InitCustom()

	if winCtrl.init ~= nil and winCtrl.init == true then
		return;
	end

	winCtrl.init = false;

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;

	--// 1、场景地图面板；2、世界地图面板
	winCtrl.curPanelType = 0;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	winCtrl.sMapObj = T(winCtrl.winRootTrans, "WndContainer/SceneMapPanel");
	winCtrl.wMapObj = T(winCtrl.winRootTrans, "WndContainer/WorldMapPanel");

	winCtrl.sTextObj = T(winCtrl.winRootTrans, "WndContainer/WBtnCon/Text1");
	winCtrl.wTextObj = T(winCtrl.winRootTrans, "WndContainer/WBtnCon/Text2");

	self:LinkBtns();
	UISceneMapPanel:Init(winCtrl.sMapObj);
	UIWorldMapPanel:Init(winCtrl.wMapObj);

	winCtrl.open = false;
	winCtrl.init = true;
end

--// 打开窗口
function UIMapWnd:OpenCustom()
	--print("UIMapWnd open !!! ");
	winCtrl.open = true;

	self:OpenSceneMapPanel();
	--self:OpenWorldMapPanel();
end

--// 关闭窗口
function UIMapWnd:CloseCustom()
  	--print("UIMapWnd close !!! ");
	  winCtrl.open = false;
end

--// 更新
function UIMapWnd:Update()
	UISceneMapPanel:Update();
end

--// 销毁释放窗口
function UIMapWnd:DisposeCustom()
	UISceneMapPanel:Dispose();
	UIWorldMapPanel:Dispose();

	winCtrl.init = false;
end

--// 链接按钮
function UIMapWnd:LinkBtns()

	local C = ComTool.Get;
	local tip = "UI地图界面";
	--// 关闭按钮
	-- local com = C(UIButton, winCtrl.winRootTrans, "WndContainer/Close", tip, false)
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	--  	self:Close();
	--  end;

	 --// 转换面板按钮
	local com = C(UIButton, winCtrl.winRootTrans, "WndContainer/WBtnCon/WIcon", tip, false)
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		if  winCtrl.curPanelType == 1 then
			UIMapWnd:OpenWorldMapPanel();
		elseif winCtrl.curPanelType == 2 then
			UIMapWnd:OpenSceneMapPanel()
		end
	end;
end

--// 打开场景地图面板
function UIMapWnd:OpenSceneMapPanel()
	winCtrl.curPanelType = 1;
	UIWorldMapPanel:Close();
	UISceneMapPanel:Open();

	winCtrl.sTextObj:SetActive(true);
	winCtrl.wTextObj:SetActive(false);
end

--// 打开世界地图面板
function UIMapWnd:OpenWorldMapPanel()

	local curMapId = MapMgr:GetCurSceneId();
	local sceneCfg = SceneTemp[tostring(curMapId)];
	if sceneCfg ~= nil and sceneCfg.lockWMap ~= nil and sceneCfg.lockWMap == 1 then
		return;
	end

	winCtrl.curPanelType = 2;
	UISceneMapPanel:Close();
	UIWorldMapPanel:Open();

	winCtrl.sTextObj:SetActive(false);
	winCtrl.wTextObj:SetActive(true);
end

return UIMapWnd
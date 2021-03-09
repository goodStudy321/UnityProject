--// 过场动画特效窗口
--require("UI/UIFamily/UIFRedPRecordPanel");


AnimeFxWnd = UIBase:New{Name = "AnimeFxWnd"};

local winCtrl = {};

local iLog = iTrace.Log;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;


--// 初始化界面
--// 链接所有操作物体
function AnimeFxWnd:InitCustom()

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 特效一面板
	winCtrl.fx1PanelObj = T(winCtrl.winRootTrans, "Fx1Panel");


	--------- 获取控件 ---------

	local tip = "过场动画特效窗口"

	-- local com = C(UIButton, winCtrl.winRootTrans, "WndCont/Bg/Title/backBtn", tip, false);
	-- UIEvent.Get(com.gameObject).onClick = function (gameObject)
	-- 	self:Close();
	-- end;

	-- winCtrl.closeEnt = EventHandler(self.Close, self);
	-- EventMgr.Add("QuitFamily", winCtrl.closeEnt);
	
	--// 
	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function AnimeFxWnd:OpenCustom()
	winCtrl.mOpen = true;
end

--// 关闭窗口
function AnimeFxWnd:CloseCustom()
	winCtrl.mOpen = false;
	winCtrl.fx1PanelObj:SetActive(false);
end

--// 更新
function AnimeFxWnd:Update()

end

--// 销毁释放窗口
function AnimeFxWnd:DisposeCustom()
	winCtrl.mOpen = false;
	winCtrl.init = false;
end

--// 打开特效
function AnimeFxWnd:PlayFx(fxIndex)
	if fxIndex == 1 then
		winCtrl.fx1PanelObj:SetActive(true);
	else
		winCtrl.fx1PanelObj:SetActive(false);
	end
end

return AnimeFxWnd
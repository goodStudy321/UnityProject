--// CG信息提示界面

UICGTipWnd = UIBase:New{Name = "UICGTipWnd"}

local winCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化界面
--// 链接所有操作物体
function UICGTipWnd:InitCustom()

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get
	local T = TransTool.FindChild

	--winCtrl.closeBtnObj = T(winCtrl.winRootTrans, "SkipBtn");
	UITool.SetBtnClick(winCtrl.winRootTrans, "WndContainer/SkipBtn", self.Name, self.SkipCutScene, self);

	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UICGTipWnd:OpenCustom()
	--print("UICGTipWnd open !!! ");
	winCtrl.mOpen = true;

	if CutscenePlayMgr.instance.IsPlaying == false then
		self:Close();
	end
end

--// 关闭窗口
function UICGTipWnd:CloseCustom()
	winCtrl.mOpen = false;
	if CutscenePlayMgr.instance.IsPlaying == true then
		UIMgr.Open("UICGTipWnd");
	end
end

--// 更新
function UICGTipWnd:Update()
	
end

--// 销毁释放窗口
function UICGTipWnd:Dispose()
	
end

function UICGTipWnd:SkipCutScene()
	CutscenePlayMgr.instance:SkipCutscene();
	--self:Close();
end

return UICGTipWnd
--// 地图界面
--require("UI/UIMapSystem/UISceneMapPanel")

UIMapTipWnd = UIBase:New{Name = "UIMapTipWnd"}

local winCtrl = {}


--// 初始化界面
--// 链接所有操作物体
function UIMapTipWnd:InitCustom()
	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--winCtrl.sMapObj = T(winCtrl.winRootTrans, "WndContainer/SceneMapPanel");

	local tip = "转换地图提示"

	--// 倒数
    winCtrl.numLb = C(UILabel, winCtrl.winRootTrans, "Cont/Discount", tip, false);

	--// 等待时间
	winCtrl.waitTime = 0;
	--// 上一次显示数字
	winCtrl.lastShowNum = 0;

	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UIMapTipWnd:OpenCustom()
	--print("UIMapTipWnd open !!! ");
	winCtrl.mOpen = true;
	
end

--// 关闭窗口
function UIMapTipWnd:CloseCustom()
  	--print("UIMapTipWnd close !!! ");

	
	winCtrl.mOpen = false;
end

--// 更新
function UIMapTipWnd:Update()
	if winCtrl.mOpen == false then
		return;
	end

	if winCtrl.waitTime > 0 then
		winCtrl.waitTime = winCtrl.waitTime - Time.deltaTime;
		if winCtrl.waitTime < 0 then
			winCtrl.waitTime = 0;
		end

		local tNewNum = self:GetShowNum(winCtrl.waitTime);
		if winCtrl.lastShowNum ~= tNewNum then
			winCtrl.lastShowNum = tNewNum;
			self:SetNum(winCtrl.lastShowNum);
		end
	end
end

--// 销毁释放窗口
function UIMapTipWnd:Dispose()
	
end

--// 设置等待时间
function UIMapTipWnd:SetWaitSec(waitSec)
	winCtrl.waitTime = waitSec;
	winCtrl.lastShowNum = self:GetShowNum(winCtrl.waitTime);
	self:SetNum(winCtrl.lastShowNum);
end

--// 设置倒数显示
function UIMapTipWnd:SetNum(number)
	winCtrl.numLb.text = tostring(number + 1);
end

--// 获取显示数字
function UIMapTipWnd:GetShowNum(number)
	return math.floor(number);
end

return UIMapTipWnd
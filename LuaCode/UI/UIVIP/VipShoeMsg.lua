--// VIP小飞鞋使用提示界面

VipShoeMsg = UIBase:New{Name = "VipShoeMsg"}

local winCtrl = {}

local iLog = iTrace.Log;
local iError = iTrace.Error;
local ET = EventMgr.Trigger;
local time = UnityEngine.Time;

--// 初始化界面
function VipShoeMsg:InitCustom()

	if winCtrl.init ~= nil and winCtrl.init == true then
		return;
	end
	--// 自动执行等待时间
	winCtrl.waitTime = 5;
	winCtrl.init = false;

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 打钩物体
	winCtrl.tickObj = T(winCtrl.winRootTrans, "toggleBg/tick");
	--// 创建道庭按钮物体
	--winCtrl.createBtnObj = T(winCtrl.winRootTrans, "WndContainer/MainPanel/ConBar/CreateBtn");
	--// 创建道庭面板
	--winCtrl.newFamilyPanelObj = T(winCtrl.winRootTrans, "FamilyCreatePanel");

	--------- 获取控件 ---------

	local tip = "VIP小飞鞋使用提示界面";

	--// 秒数显示
	winCtrl.timeLabel = C(UILabel, winCtrl.winRootTrans, "SecTip", tip, false);

	--// 关闭按钮
	local com = C(UIButton, winCtrl.winRootTrans, "CloseBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:CloseBtn();
	end;
	--// 点击勾
	com = C(UIButton, winCtrl.winRootTrans, "toggleBg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:SetTick();
	end;
	--// 点击确定
	com = C(UIButton, winCtrl.winRootTrans, "yesBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickYes();
	end;

	winCtrl.timer = 0;
	winCtrl.excuteFun = nil;

	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function VipShoeMsg:OpenCustom()
	winCtrl.mOpen = true;

	winCtrl.excuteFun = nil;
	winCtrl.timer = winCtrl.waitTime;
	VIPMgr.useFlyShoe = true;
	self:ShowTick();
end


function VipShoeMsg:CloseBtn()
	VIPMgr.useFlyShoe = false;
	self:Close();
end

--// 点击确定
function VipShoeMsg:ClickYes()
	if winCtrl.excuteFun ~= nil then
		winCtrl.excuteFun();
		winCtrl.excuteFun = nil;
		self:Close();
	end
end

--// 关闭窗口
function VipShoeMsg:CloseCustom()


	winCtrl.excuteFun = nil;
	winCtrl.mOpen = false;
end

--// 更新
function VipShoeMsg:Update()
	if winCtrl.mOpen == false then
		return;
	end

	winCtrl.timer = winCtrl.timer - time.deltaTime;
	if winCtrl.timer <= 0 then
		if winCtrl.excuteFun ~= nil then
			winCtrl.excuteFun();
			winCtrl.excuteFun = nil;
			self:Close();
		end
	end
	self:ShowWaitSec();
end

--// 销毁释放窗口
function VipShoeMsg:DisposeCustom()


	winCtrl.excuteFun = nil;
	winCtrl.init = false;
end

--// 设置执行函数
function VipShoeMsg:SetExcuteFun(fun)
	winCtrl.excuteFun = fun;
end

function VipShoeMsg:ShowTick()
	if VIPMgr.useFlyShoe == true then
		winCtrl.tickObj:SetActive(true);
	else
		winCtrl.tickObj:SetActive(false);
	end
end

function VipShoeMsg:SetTick()
	if VIPMgr.useFlyShoe == true then
		VIPMgr.useFlyShoe = false;
	else
		VIPMgr.useFlyShoe = true;
	end
	self:ShowTick();
end

function VipShoeMsg:ShowWaitSec()
	local showSec = math.ceil(winCtrl.timer);
	local showStr = StrTool.Concat("(", tostring(showSec), "s)");
	winCtrl.timeLabel.text = showStr;
end

return VipShoeMsg
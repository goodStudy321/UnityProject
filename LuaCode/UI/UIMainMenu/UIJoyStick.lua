--region UIJoyStick.lua
--Date
--此文件由[HS]创建生成

UIJoyStick = {}
local M = UIJoyStick
local JoyStickCtrl = JoyStickCtrl.instance
--不使用时通道
M.unUseCol = Color.New(1,1,1,0.3);
--使用时通道
M.useCol = Color.New(1,1,1,1);

--注册的事件回调函数

function M:New(go)
	local name = " 遥感窗口"
	self.Root = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	--self.Root:SetActive(false);
	self.mJoyStick_Back = T(trans, "MoveRoot/joystick_back")
	self.mJoyStick_Center = T(trans, "MoveRoot/joystick_center")
	self.mJStkBack_Spr = C(UISprite,trans,"MoveRoot/joystick_back",name,false);
	self.mJStkCenter_Spr = C(UISprite,trans,"MoveRoot/joystick_center",name,false);
	self.JSPlayTween = C(UIPlayTween, trans,"MoveRoot", name, false)
	self.JSTweenPos = C(TweenPosition, trans,"MoveRoot", name, false)
	
	self:SetVirtualAlpha(false);
	-- self.mJoyStickBackPos = self.mJoyStick_Back.transform.localPosition;
	-- self.mJoyStickCenterPos = self.mJoyStick_Center.transform.localPosition;
	self:Reset();
	return M
end

function M:UpdateJoyStickStatus(value)
	local jsPlayTween = self.JSPlayTween
	local jsTweenPos = self.JSTweenPos
	if jsTweenPos then
		local delay = 0
		if value == false then
			delay = 0.2
		end
		jsTweenPos.delay = delay
	end
	if jsPlayTween then
		jsPlayTween:Play(value)
	end
end

--重置
function M:Reset()
	self:SetVirtualAlpha(false);
	--self:SetVirtualBox(false);
	-- self.mJoyStick_Back.transform.localPosition = self.mJoyStickBackPos;
	-- self.mJoyStick_Center.transform.localPosition = self.mJoyStickCenterPos;

	local StartPosition = JoyStickCtrl:GetStartTouchPosition();
	local SWorldPoint = Vector3.New(StartPosition.x, StartPosition.y, UIMgr.Cam.nearClipPlane);
	local vStartPos = UIMgr.Cam:ScreenToWorldPoint(SWorldPoint);
	vStartPos.z = 0;
	self.mJoyStick_Back.transform.position = vStartPos;
	self.mJoyStick_Center.transform.position = vStartPos;
end

--设置虚拟摇杆UI显示状态
function M:SetVirtualBox(show)
	if self.Root == nil then
		return;
	end
	local state = self.Root.activeSelf;
	if show == state then
		return;
	end
	self.Root:SetActive(show);
end

--设置摇杆通道
function M:SetVirtualAlpha(active)
	local color = nil;
	if active == false then
		color = M.unUseCol;
	else
		color = M.useCol;
	end
	self.mJStkBack_Spr.color = color;
	self.mJStkCenter_Spr.color = color;
end

function M:SetJoyStickUI()
	self:SetVirtualAlpha(true);
	--self:SetVirtualBox(true);
	local StartPosition = JoyStickCtrl:GetStartTouchPosition();
	local MovePosition = JoyStickCtrl:GetMoveTouchPosition();
	local distanceV = Vector2.__sub(MovePosition, StartPosition);
	local DisSqrt = Vector2.Magnitude(distanceV);
	if DisSqrt > 40 then
		MovePosition = StartPosition + (MovePosition - StartPosition) / DisSqrt * 40;
	end
	local SWorldPoint = Vector3.New(StartPosition.x, StartPosition.y, UIMgr.Cam.nearClipPlane);
	local vStartPos = UIMgr.Cam:ScreenToWorldPoint(SWorldPoint);
	local MWorldPoint = Vector3.New(MovePosition.x, MovePosition.y, UIMgr.Cam.nearClipPlane);
	local MoveTouchPos = UIMgr.Cam:ScreenToWorldPoint(MWorldPoint);
	vStartPos.z = 0;
	MoveTouchPos.z = 0;
	self.mJoyStick_Back.transform.position = vStartPos;
	self.mJoyStick_Center.transform.position = MoveTouchPos;
end

function M:Update()
	if self.mJoyStick_Center == nil then
		return;
	end

	if self.mJoyStick_Back == nil then
		return;
	end

	if not JoyStickCtrl then
		return;
	end

	if JoyStickCtrl.IsTouch == nil then
		return;
	end
	if JoyStickCtrl.IsTouch == false then
		self:Reset();
	else
		self:SetJoyStickUI();
	end;
end

function M:Dispose()
end
--endregion

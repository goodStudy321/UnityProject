--region AccMgr.lua
--Date
--此文件由[HS]创建生成
require("UI/UICreatePanel/RoleTb")

AccMgr = {Name="AccMgr"}
local M = AccMgr

M.eLoginSdk = Event()
M.eLoginSuc = Event()
M.eLoginFail = Event()
M.eLogoutSuc = Event()
M.eLoginCreate=Event()
M.eBack=Event()

M.IsLogin = false
M.LoginSdk = false

M.IsCreate = false

M.RoleList={}
M.CurSelectRole = nil

function M:Init()
	self:AddEvent()
end

function M:AddEvent()
	self:SetEvent(EventMgr.Add)
end

function M:SetEvent(E)
	local EH = EventHandler
	E("LoginRole", EH(self.LoginRole, self))
	E("CreateSuc",EH(self.CreateSuc, self))
	E("LoginSuc", EH(self.LoginSuc, self))
	E("LoginFail", EH(self.LoginFail, self))
	E("SdkSuc", EH(self.SdkSuc, self))
	E("SdkFail",EH(self.SdkFail,self))
	E("LogoutSuc", EH(self.LogoutSuc, self))
	E("LogoutFail", EH(self.LogoutFail, self))
	--E("RoleLogin", EH(self.RoleLogin, self))
	--E("OnChangeLv", EH(self.ChangeLvHandler, self))
end

function M:RemoveEvent()
	self:SetEvent(EventMgr.Remove)
	local Re = EventMgr.Remove
	local EH = EventHandler
end


function M:CreateSuc(roleId,name,lv,sex,cate,skinList)
	--EventMgr.Trigger("OnLoginCreate")
	self.IsCreate = true
	self:LoginRole(tostring(roleId),name,lv,sex,cate,skinList)
end

--升级
function M:ChangeLvHandler()
	if not Sdk then return end
	if App.platform ~= 2 then return end
	local user = User
	local data = User.MapData
	local ra = RoleAssets
	Sdk:UpdataOnRoleUpg(data.UIDStr, user.ServerID, user.ServerName, data.Name, user.VIPLV , ra.Gold, ra:GetTypeName(2), data.Level)
end

--进入服务器
function M:RoleLogin()
	if not Sdk then return end
	if App.platform ~= 2 then return end
	local user = User
	local data = User.MapData
	local ra = RoleAssets
	Sdk:UpdataOnEnterSvr(data.UIDStr, user.ServerID, user.ServerName, data.Name, user.VIPLV , ra.Gold, ra:GetTypeName(2), data.Level)
end

--登入游戏成功
function M:LoginSuc()
	self.IsLogin = true
end

--登入游戏失败
function M:LoginFail()
	self.IsLogin = false
end

--Sdk登入成功
function M:SdkSuc()
	self.LoginSdk = true
	UITip.Log("账号登录成功")
	self.eLoginSdk()
end

--Sdk登入失败
function M:SdkFail()
	self.LoginSdk = false
	self.IsLogin=false
	self.eLoginSdk()
	--iTrace.sLog("hs","---------------->>Sdk登入失败")
	UITip.Log("账号登录失败")
	MsgBox.CloseOpt = MsgBoxCloseOpt.Yes;
	MsgBox.ShowYes("账号登录失败",self.MsgBoxCallback, self, "重新登录")
end

function M:MsgBoxCallback()
	--iTrace.sLog("hs","---------------->> 确认回调")
	self:Logout(true)
end

--登出成功
function M:Logout(value, setting)
	iTrace.sLog("XGY", "哪里调用了")
	setting = setting or false
	local gcid = tonumber(User.GameChannelId)
	if not setting then
		if gcid == 112591 or gcid == 112537 then
			self:CustomLogout(value)
			return
		end
	end
	if Sdk then
		self:Reset()
		if value then Sdk:Logout() end
	else
		EventMgr.Trigger("LogoutSuc")
	end
	ListTool.ClearToPool(self.RoleList)
end

function M:CustomLogout(value)
	if Sdk then
		iTrace.sLog("hs","---------------->>CustomLogout Sdk登出")
		self:Reset()
		if value then Sdk:Logout() end
	end
	EventMgr.Trigger("LogoutSuc")
	ListTool.ClearToPool(self.RoleList)
end

function M:LogoutSuc()
	iTrace.sLog("XGY", "哪里调用了！！")
	--iTrace.sLog("hs","---------------->>Sdk登出成功")
	self.eLogoutSuc()
end

function M:LogoutFail()
	self.eLogoutSuc()
	--iTrace.sLog("hs","---------------->>Sdk登出失败")
end

function M:Reset()
	self.IsLogin = false
	self.LoginSdk = false
end

--登入sdk
function M:Login()
	if Sdk then
		if self.LoginSdk == true then 
			UITip.Error("已请求登入")
			return
		end
		Sdk:Login()
		--iTrace.sLog("hs","---------------->> 有SDK 进行SDKLogin")
	else
		self:LoginSuc()
		--iTrace.sLog("hs","---------------->> 没有SDK 进行LoginSuc")
	end
end


--角色信息列表
function M:LoginRole(roleId,name,lv,sex,cate,skinList)
	local role = ObjPool.Get(RoleTb)
	role:Init(tostring(roleId),name,lv,sex,cate,skinList)
	self.RoleList[#self.RoleList+1]=role
end

function M:Clear()
	ListTool.ClearToPool(self.RoleList)
	self.IsCreate = false
	self:Reset()
end

function M:Dispose()
	self.eLoginSdk:Clear()
	self.eLoginSuc:Clear()
	self.eLoginFail:Clear()
	self.eLogoutSuc:Clear()
	self.eLoginCreate:Clear()
	self.eBack:Clear()
	self:RemoveEvent()
	ListTool.ClearToPool(self.RoleList)
end

return M
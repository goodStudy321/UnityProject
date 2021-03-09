--region UILogin.lua
--登入界面UI
--此文件由[HS]创建生成
require("UI/UILogin/UIServerSelect")


local GameSceneManager = GameSceneManager.instance

UILogin = UIBase:New{Name = "UILogin"}
local M = UILogin

--注册的事件回调函数

function M:InitCustom()
	--登陆图
	--1: 剑来传说
	--2：弑神斩仙
	--3：游艺道
	--4：坠星大陆
	--5：阴阳界
	--6：战殇
	self.LoginBgTab = {"jlcs.jpg","zc_sszx_login.png","zc_yyd_login.jpg","zc_zxdl_login.jpg","zc_yyj_login.png","zc_zs_login.png"}
	self.Persitent = true
	local name = "lua登入界面" 
	local trans = self.root
	local C = ComTool.Get 
	local T = TransTool.FindChild
	local US = UITool.SetLsnrSelf 

	self.pGuideGbj = T(trans,"pGuide",name)
	self.pBtnGbj = T(trans,"pGuide/pBtn",name)
	self.pCheckGbj = T(trans,"pGuide/pBtn/check",name)
	self.pLabGbj = C(UILabel,trans,"pGuide/pBtn/desLab1",name,false)

	self.pShowGbj = T(trans,"pGuide/pShow",name)
	self.pShowCloseGbj = T(trans,"pGuide/pShow/bg/close",name)

	self.pLabGbj.text = "我已详细阅读并同意[u]用户协议和隐私保护指南[/u]"
	self.pCheckBoxShow = true

	self.pGuideGbj:SetActive(false)

	US(self.pBtnGbj.gameObject,self.pBtnClick,self,name,false)
	US(self.pLabGbj.gameObject,self.pLabClick,self,name,false)

	US(self.pShowCloseGbj.gameObject,self.ClosePShow,self,name,false)

	--游戏LOGO
	self.Logo = C(UITexture, trans, "Logo", name, false)
	-- WWWTool.LoadChgTex("logo.png", self.SetLogo, self)
	-- self.Logo.gameObject:SetActive(false)
	--登入背景
	self.Bg = C(UITexture, trans, "bg", name, false)
	--WWWTool.LoadChgTex("login_bg.jpg", self.SetBg, self)


	self.SelectServerView = T(trans, "SelectServer")


	self.Server = T(trans, "SelectServer/ServerData")
	self.ServerView = UIServerSelect:New(T(trans, "ServerView"))
	self.Icon = C(UISprite, trans, "SelectServer/ServerData/Icon", name, false)
	self.NameLabel = C(UILabel, trans, "SelectServer/ServerData/Label", name, false)
	self.Symbol = T(trans, "SelectServer/ServerData/Symbol")
	self.ConnectBtn = C(UIButton, trans, "SelectServer/ConnectBtn", name, false)
	self.ConnectLab = C(UILabel, trans, "SelectServer/ConnectBtn/label", name, false)
	self.BackBtn = C(UIButton, trans, "SelectServer/BackBtn", name, false)

	self.AccView = T(trans, "AccView")
	self.Account = C(UIInput, trans, "AccView/nameInput", name, false)
	self.Password = C(UIInput, trans, "AccView/passwordInput", name, false)
	self.AccBtn = C(UIButton, trans, "AccView/AccBtn", name, false)

	self.LoadingIpc = T(trans, "Loading")
	self.LoadingLabel = C(UILabel, trans, "Loading/Label", name, false)

	UITool.SetBtnClick(trans,"repair",name, self.OnClickRepair,self)

	local repairGo = TransTool.FindChild(trans,"repair",name)
	if repairGo then repairGo:SetActive(true) end

	self.ServerIndex = nil
	self.Info = nil

	self.IsConnect = false
	self:AddEvent()
	self:SetVer()
	self:SetCopyRight()
end


function M:pBtnClick()
	local isShow = self.pCheckBoxShow
	self.pCheckGbj:SetActive(isShow)
	self.pCheckBoxShow = not isShow
end

function M:pLabClick()
	self:OpenPShow() 
end

function M:OpenPShow()
	self.pShowGbj:SetActive(true)
end

function M:ClosePShow()
	self.pShowGbj:SetActive(false)
end

function M:SetCopyRight()
	local lbl = ComTool.Get(UILabel, self.root, "Label", self.Name)
	local gid = UserMgr:GetGameChannelID()
	if App.IsAndroid() then 
		if gid == "0" then
			lbl.text = " "
		end
		-- lbl.text = "本网络游戏适合年满16周岁以上的用户使用：请您确认已如实进行实名注册。抵制不良游戏，拒绝盗版游戏。注意自我保护，谨防受骗上当。适度游戏益脑，沉迷游戏伤身。合理安排时间，享受健康生活。"
	elseif (App.IsIOS()) then
		if gid == "0" then
			lbl.text = " "
		end
	end
end

function M:SetVer()
	local verLbl = ComTool.Get(UILabel,self.root,"ver",name)
	if verLbl==nil then return end
	local str = App.FmtVer()
	verLbl.text = str
end

function M:SetBg(tex)
	self.Bg.mainTexture = tex
end

function M:SetLogo(tex)
	local logo = self.Logo
	logo.mainTexture = tex
	logo:MakePixelPerfect()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.AccBtn then
		E(self.AccBtn, self.OnClickAccBtn, self)
	end
	if self.ConnectBtn then
		E(self.ConnectBtn, self.OnClickConnectBtn, self)
	end
	if self.BackBtn then
		E(self.BackBtn, self.OnClickBackBtn, self)
	end
	if self.Server then
		E(self.Server, self.OnClickServerData, self, nil, false)
	end
	local M = EventMgr.Add
	local EH = EventHandler
	euiclose:Add(self.UIBBSClose, self)
	M("OnConnect", EH(self.OnConnect, self))
	M("OnConnectFail", EH(self.HideLoading, self))
	M("LoginSuc", EH(self.LoginSuc, self))
	M("LoginFail", EH(self.LoginFail, self))
	M("DisConnectSuccess",EH(self.DisConnectSuccess,self))
	--M("OnLoginSuccessful", EH(self.OnLoginSuccessful, self))
	if self.ServerView then
		self.ServerView.SelectServer:Add(self.SelectServer, self)
	end
	--AccMgr.eLoginSuc:Add(self.OnLoginSuc, self)
	AccMgr.eLogoutSuc:Add(self.OnLogoutSuc, self)
	AccMgr.eLoginSdk:Add(self.OnLoginSdk, self)
	ServerMgr.LoadSucc:Add(self.ServersLoadSucc, self)
	ServerMgr.LoadFail:Add(self.ServersLoadFail, self)
end

function M:RemoveEvent()
	local EH = EventHandler
	local M = EventMgr.Remove
	euiclose:Remove(self.UIBBSClose, self)
	M("OnConnect", EH(self.OnConnect, self))
	M("OnConnectFail", EH(self.HideLoading, self))
	M("LoginSuc", EH(self.LoginSuc, self))
	M("LoginFail", EH(self.LoginFail, self))
	M("DisConnectSuccess",EH(self.DisConnectSuccess,self))
	--M("OnLoginSuccessful", EH(self.OnLoginSuccessful, self))
	if self.ServerView then
		self.ServerView.SelectServer:Remove(self.SelectServer, self)
	end
	AccMgr.eLogoutSuc:Remove(self.OnLogoutSuc, self)
	AccMgr.eLoginSdk:Remove(self.OnLoginSdk, self)
	ServerMgr.LoadSucc:Remove(self.ServersLoadSucc, self)
	ServerMgr.LoadFail:Remove(self.ServersLoadFail, self)
end

------------------------------------------

-----關閉公告
function M:UIBBSClose(name)
	if name ~= UIBBS.Name then return end
	iTrace.sLog("hs", "关闭公告")
	--[[
	if Sdk then
		AccMgr:Login()
	end
	]]--
	if AccMgr.LoginSdk == true then
		self:OnLoginSdk()
	else
		self:EndterSdk()
	end
end


function M:OnConnect()
	if self.IsConnect == true then return end
	self.IsConnect = true
	self:ShowLoading("正在登入...")
	local account = UserMgr:GetAccount()
	local md5 = UserMgr:MD5()
	local sid = self.Info.server_id
	local cid = UserMgr:GetChannelId()
	local gcid = UserMgr:GetGameChannelID()
	Mgr.ReqLogin(account, md5, sid, cid, gcid)
end

function M:LoginSuc()
	LoginSceneMgr:ShowCharacter()
	UIMgr.Open(UICreatePanel.Name)
	self:Close()
end

function M:LoginFail()
	self:HideLoading()
end

function M:DisConnectSuccess()
	self.IsConnect=false 
end

-- function M:OnLoginSuccessful()
-- 	self:Close()
--     --SceneMgr:ReqPreEnter(User.SceneId, true)
-- end

function M:SelectServer(index, info)
	self.ServerIndex = index
	self.Info = info
	self:UpdateServer(info)
end

function M:UpdateServer(info)
	if not info then return end
	if self.Icon then
		self.Icon.spriteName = string.format("type_%s", info.status)
	end
	if self.NameLabel then
		self.NameLabel.text = info.name
	end
	--if self.Symbol then
		--self.Symbol:SetActive(tonumber(info.isNew == 1))
	--end
end

function M:ShowLoading(str)
	if self.LoadingLabel then self.LoadingLabel.text = str end
	if self.LoadingIpc then 
		self.LoadingIpc:SetActive(true) 
	end
end

function M:HideLoading()
	if self.LoadingIpc then 
		self.LoadingIpc:SetActive(false) 
	end
end

function M:OpenCustom()
	if not Sdk then
		local val = UserMgr:GetAccount()
		val = val or os.time()
		val = (val=="") and os.time() or val
		self.Account.value = val
	end
	UIMgr.Open(UIBBS.Name)
	self:UpdateData()
	self:pBtnClick()
end

function M:CloseCustom()
	self.pCheckBoxShow = true
	self.SelectServerView:SetActive(false)
	self.AccView:SetActive(false)
end

-- 9：掌创_幻世仙征
-- 10：掌创_阴阳界
-- 11：掌创_战殇

function M:DisposeCustom()
	self:RemoveEvent()
	-- UITool.UnloadTex(self.Logo)
end

----------------------------------------------------

--点击按钮登入并读入服务器数据
function M:OnClickAccBtn(gameObject)
	local account = self.Account.value
	local password = self.Password.value
	User.Account = account
	User.Password = password
	--self:OnLoginSuc()
	self:LoadServer()
	self:SelectView(false)
	self:Send()
end

function M:OpenCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:SetCircleActive(true)
	end
end

--连接服务器并登入
function M:OnClickConnectBtn(go)
	if Sdk then
		local sdkIndex = Sdk:GetSdkIndex()
		if sdkIndex == 6 then
			local isCheck = not self.pCheckBoxShow
			if not isCheck then
				UITip.Error("请勾选用户协议和隐私保护指南，即可进入游戏")
				return
			end
		end
	end
	if self.IsConnect==true then return end
	if self:EndterSdk() == true then
		return
	end
	--检测是否选择了服务器
	local server = self.Info
	if not server then
		return
	end
	--检查账号密码是否输入
	local account = UserMgr:GetAccount()
	--local password = UserMgr:GetPassword()
	if StrTool.IsNullOrEmpty(account) then
		UITip.Error("没有输入账号！！！")
		return
	end
	if server.status == 0 then
		local msg = server.message
		if StrTool.IsNullOrEmpty(msg) then
			msg = "服务器正在维护，请更换服务器"
		end
		MsgBox.ShowYes(msg)	
		return
	end
	if self.LoadingIpc.activeSelf == true then
		return
	end
	self:EnterSvr(true)
end

function M:EnterSvr(isCan)
	if isCan then
		local server = self.Info
		self:ShowLoading("连接服务器...")
		--Mgr.ReqEnterIp(server.server_id, server.name, server.ip, server.port)
		Mgr.ReqEnterDns(server.server_id, server.name, server.ip, server.port)
		ServerMgr:RecordWrite(self.ServerIndex,  UserMgr:GetAccount(), self.Info.id)
	else
		local msg = "当前服务器不允许进入，请更换服务器"
		MsgBox.ShowYes(msg)	
	end
end

--返回到账号界面
function M:OnClickBackBtn(go)
	--AccMgr:Logout()
	if Sdk == nil then
		self:SelectView(true)
	else
		AccMgr:Logout(true)
	end
	UserMgr.eBlackAccount()
end

function M:OnClickRepair()
	local msg = "当您无法正常登录或者进行游戏时,请尝试修复游戏\n此过程可能耗时较长,修复完成后请重新启动游戏"
	EventMgr.Trigger("AssetRepairStart",msg)
end

---------------------------------------------
--更新UI
function M:UpdateData()
	LoginSceneMgr:OnChangeEndEvent()
	if self.BackBtn then
		self.BackBtn.gameObject:SetActive(Sdk == nil)
	end
	self:SelectView(Sdk == nil)
	self:UpdateLoginStatus()
end

--進入登入成功
function M:LoadServer()
	iTrace.eLog("hs", "進入遊戲 , 请求服务器数据")
	self:ShowLoading("读取服务器数据...")
	ServerMgr:Load()
end

--服务器数据加载完成
function M:ServersLoadSucc()
	iTrace.eLog("hs", "服务器数据加载完成。。。")
	self:HideLoading()
	local view = self.ServerView
	if view then
		view:UpdateData()
	end
end

function M:ServersLoadFail(err)
	self:HideLoading()
	MsgBox.CloseOpt = MsgBoxCloseOpt.Yes
	MsgBox.ShowYes(string.format("获取服务器失败(%s)，重新连接",err),self.LoadServer,self,"重新获取")
end

--[[
function M:OnLoginSuc()
end
]]--

--登出遊戲成功
function M:OnLogoutSuc()
	self:HideLoading()
	if not Sdk then
		self:SelectView(false)
	else
		self:UpdateLoginStatus()
		if AccMgr.LoginSdk == true then
			self:OnLoginSdk()
		else
			self:EndterSdk()
		end
	end
end

--Sdk登陆返回
function M:OnLoginSdk()
	if AccMgr.LoginSdk == false then return end
	self:LoadServer()
	local box = self.ConnectBtn:GetComponent(typeof(BoxCollider))
	box.enabled = true
	UIMgr.Close(UIRefresh.Name)
	UIMgr.Close("MsgBox")
	self:Send()
end

--点击打开服务器选择窗口
function M:OnClickServerData()
	if self:EndterSdk() == true then
		return
	end

	if self.ServerView then
		self.ServerView:SetActive(true)
	end
end

--设置打开的窗口
function M:SelectView(value)
	if self.SelectServerView then
		self.SelectServerView:SetActive(not value)
	end
	if Sdk == nil then
		if self.AccView then
			self.AccView:SetActive(value)
		end
	end
end

function M:UpdateLoginStatus()
	if self.ConnectLab then
		local txt = "登录游戏"
		if AccMgr.IsLogin == true then txt = "进入游戏" end
		self.ConnectLab.text = txt
	end
end

function M:EndterSdk()
	if Sdk then
		if AccMgr.LoginSdk == false then
			--点击cd
			local box = self.ConnectBtn:GetComponent(typeof(BoxCollider))
			box.enabled = false
			self.ConnectTimer = os.time()
			--UIMgr.Open(UIRefresh.Name, self.OpenCb, self)
			AccMgr:Login()
			return true
		elseif AccMgr.LoginSdk == true then
			return false
		end
	end
	return false
end

function M:Send()
	UserMgr.eCreateAccount()
end

function M:Update()
	if self.ConnectTimer ~= nil then
		if os.time() - self.ConnectTimer > 2 then
			self.ConnectTimer = nil
			self:HideLoading()
			UIMgr.Close(UIRefresh.Name)
			local box = self.ConnectBtn:GetComponent(typeof(BoxCollider))
			box.enabled = true
		end 
	end
end

return UILogin
--endregion

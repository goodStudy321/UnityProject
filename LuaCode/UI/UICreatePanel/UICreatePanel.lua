--region UICreatePanel.lua
--登入界面UI
--此文件由[HS]创建生成
require("Data/CfgNames")
require("UI/UICreatePanel/UICreate")
require("UI/UICreatePanel/UISelect")
require("UI/UICreatePanel/RoleCell")

UICreatePanel = UIBase:New{Name ="UICreatePanel"}
local M = UICreatePanel


--注册的事件回调函数

function M:InitCustom()
	local name = "lua创建角色界面"
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Create=ObjPool.Get(UICreate)
	self.Create:Init(T(self.root,"Create"))

	self.Select=ObjPool.Get(UISelect)
	self.Select:Init(T(self.root,"Select"))

	UITool.SetBtnClick(self.root,"BackBtn",self.Name, self.OnBack, self)
	self:AddE()
end


function M:AddE()   
    local M = EventMgr.Add
    local EH = EventHandler

	--M("LoginSuc",EH(self.LoginSuc,self))
	M("SelectSuc",EH(self.OnClose,self))
	M("CreateSuc",EH(self.CreateSuc,self))
	M("LogoutSuc", EH(self.LogoutSuc, self))
	self.Select.eAdd:Add(self.ShowCreate,self)
end

function M:ReE()
    local M = EventMgr.Remove
	local EH = EventHandler
	
	--M("LoginSuc",EH(self.LoginSuc,self))
	M("SelectSuc",EH(self.OnClose,self))
	M("CreateSuc",EH(self.CreateSuc,self))
	M("LogoutSuc", EH(self.LogoutSuc, self))
	self.Select.eAdd:Remove(self.ShowCreate,self)
end

function M:OpenCustom()
	local list = AccMgr.RoleList
	if #list==0 then 
		self:ShowCreate()
	else	
		self:ShowSelect()
	end
end

function M:LogoutSuc()
	self:OnClose()
	AccMgr.eBack()
	AccMgr:Logout(true)
end

--返回
function M:OnBack(go)
	if self.curC.Name=="UICreate" then
		if #AccMgr.RoleList>0 then self:ShowSelect() return end
	end
	self:LogoutSuc()
end

function M:CreateSuc(roleId,roleName,lv,sex,cate,skin)
	Mgr.ReqSelect(tostring(roleId),lv) --创角直接进入
	AccMgr.eLoginCreate(true)
end

--显示选角界面
function M:ShowSelect()
	LoginSceneMgr:Close()
	if self.curC then self.curC:Close() end
	self.curC=self.Select
	self.curC:Open()
end

--关闭
function M:OnClose()
	if self.curC then self.curC:Close() self.curC=nil end
	LoginSceneMgr:ShowLogin()
	self:Close()
end

--显示创角界面
function M:ShowCreate()
	if self.curC then self.curC:Close() end
	self.curC=self.Create
	self.curC:Open()
end


function M:DisposeCustom()
	self:ReE()
	if self.Select then ObjPool.Add(self.Select) self.Select=nil end
	if self.Create then ObjPool.Add(self.Create) self.Create=nil end
	
end

return M
--endregion

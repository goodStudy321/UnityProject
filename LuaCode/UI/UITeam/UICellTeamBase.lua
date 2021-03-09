--region UICellTeamBase.lua
--
--此文件由[HS]创建生成

UICellTeamBase = baseclass()
UICellTeamBase.Items1 = {"我的队伍","离开队伍"}
UICellTeamBase.Items2 = {"提升队长","移出队伍","离开队伍"}
local tMgr = TeamMgr

--构造函数
function UICellTeamBase:Ctor(go)
	self.Name = "UICellTeamBase"
	self.GO = go
	self.trans = go.transform
end

--初始化控件
function UICellTeamBase:Init()
	self.Menu = self.GO:GetComponent("UIMenuTip")
	if not self.Menu then return end
	self.Menu.IsActive = false
	self.OnClickMenuTipAction = EventHandler(self.ClickMenuTipAction, self)
	EventMgr.Add("ClickMenuTipAction", self.OnClickMenuTipAction)
end

function UICellTeamBase:SetEvent(fn)
end

function UICellTeamBase:UpdateData(data)
end


function UICellTeamBase:UpdateMenuItems(data)
	if not data then return end
	local captId = TeamMgr.TeamInfo.CaptId
	if not captId then return end
	if not self.Menu then return end
	local menus = self.Menu.items
	menus:Clear()
	local items = nil
	if captId == data.ID or tostring(captId) ~= User.MapData.UIDStr then
		items = self.Items1
	else
		items = self.Items2
	end
	local len = #items
	for i=1,len do
		local txt = items[i]
		menus:Add(txt)
	end
end

function UICellTeamBase:ClickMenuTipAction(name, tt, str, index)
end

function UICellTeamBase:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

--清除数据
function UICellTeamBase:Clean()
	self:UnloadIcon()
end

--释放或销毁
function UICellTeamBase:Dispose(isDestory)
	if self.OnClickMenuTipAction then
		EventMgr.Remove("ClickMenuTipAction", self.OnClickMenuTipAction)
	end
	--self.OnClickMenuTipAction = nil
	self:Clean()
	if isDestory then
		self.trans.parent = nil
		GameObject.Destroy(self.GO)
	end
end
--endregion

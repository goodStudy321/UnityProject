--region UIMyTeamApply.lua
--Date
--此文件由[HS]创建生成


UIMyTeamApply = {}
local M = UIMyTeamApply
local E = UITool.SetLsnrSelf
--注册的事件回调函数

function M:New(go)
	local name = "申請列表"
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Panel = C(UIScrollView, trans, "Checkmark/ScrollView")
	self.Grid = C(UIGrid, trans, "Checkmark/ScrollView/Grid")
	self.Prefab = T(trans, "Checkmark/ScrollView/Grid/Item")
	self.Items = {}
	self:AddEvent()
	return M
end

function M:AddEvent()
	self.OnClickMenuTipAction = EventHandler(self.ClickMenuTipAction, self)
	EventMgr.Add("ClickMenuTipAction", self.OnClickMenuTipAction)
end

function M:RemoveEvent()
	EventMgr.Remove("ClickMenuTipAction", self.OnClickMenuTipAction)
end

function M:UpdateData()
	self:Clean()
	local list = TeamMgr.ApplyInfo
	if not list then return end
	for k,v in pairs(list) do
		self:AddItem(k,v)
	end
	self:Reposition()
end

function M:AddItem(id, name)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = id
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	local label = ComTool.Get(UILabel, go.transform, "Name")
	if label then label.text = name end
	table.insert(self.Items, go)
end

function M:Reposition()
	if self.Panel and self.Grid then
		self.Grid:Reposition()
		if self.Grid:GetChildList().Count >= 2 then
			self.Panel.isDrag = true
		else
			self.Panel.isDrag = false
		end
	end
end

function M:ClickMenuTipAction(name, tt, str, index)
	if not tt or tt ~= MenuType.Team then return end
	local id = name
	TeamMgr:ClickMenuTip(str, id)
end

function M:Clean()
	if not self.Items then return end
	while #self.Items > 0 do
		local len = #self.Items
		GameObject.Destroy(self.Items[len])
		table.remove(self.Items, len)
	end
end

function M:Dispose()
	self:RemoveEvent()
	self:Clean()
end
--endregion

--region UIServerSelect.lua
--UIServerSelect
--此文件由[HS]创建生成

UIServerSelect = {}
local M = UIServerSelect
M.SelectServer = Event()

local SMgr = ServerMgr
local SData = ServerData

--构造函数
function M:New(go)
	local name = "UIServerSelect"
	self.gbj = go
	local trans = self.gbj.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Back = C(UIButton, trans, "BackBtn", name, false)

	self.LPanel = C(UIScrollView, trans, "LPanel", name, false)
	self.LGrid = C(UIGrid, trans, "LPanel/Grid", name, false)
	self.LPrefab = T(trans, "LPanel/Grid/Item") 
	
	self.SPanel = C(UIPanel, trans, "SPanel", name, false)
	self.SUISV = C(UIScrollView, trans, "SPanel", name, false)
	self.SGrid = C(UIGrid, trans, "SPanel/Grid", name, false)
	self.SPrefab = T(trans, "SPanel/Grid/Item")

	self.Titles = {}
	self.CurTitle = nil
	self.CurServer = nil
	self.CurServerInfo = nil
	self.Servers = {}
	self.Data = nil

	UITool.SetLsnrSelf(self.Back, self.OnClickBack, self)
	return M
end

function M:UpdateData()
	self:UpdateTitle()
	self:Recommend()
end

function M:Recommend()
	self:SetTitle(1)
	self:SetServer(1)
end

function M:UpdateTitle()
	local data = SData.AllData
	if not data or not data.titles then return end
	local list = data.titles
	local len = #list
	for i=1, len do
		local title = self.Titles[i]
		if not title then 
			local go = self:AddItem(i, self.LGrid, self.LPrefab)
			UITool.SetLsnrSelf(go, self.OnClickTitle, self, nil, false)
			title = self:GetTitleCom(go, self.Titles)
		end
		self:UpdateTitleData(list[i], title)
	end
	self:Reposition(self.LPanel, self.LGrid, len > 4)
end

function M:UpdateServer()
	local data = SData.AllData
	if not data or not data.servers then return end
	self:CleanServer()
	local servers = data.servers
	local len = #servers
	if len > 0 then
		for i =1 , len do
			self:UpdateServerItem(i, servers)
		end
	end
	self:Reposition(self.SUISV, self.SGrid, len > 10)
	if self.SUISV then
		self.SUISV:Press(false)
	end
	if self.SPanel then
		self.SPanel.clipOffset = Vector2.zero
		self.SPanel.transform.localPosition = Vector3.New(135.6, -53, 0)
	end
end

function M:UpdateServerItem(index, list)
	local server = self.Servers[index]
	if not server then
		local go = self:AddItem(index, self.SGrid, self.SPrefab)
		UITool.SetLsnrSelf(go, self.OnClickServer, self, nil, false)
		server = self:GetServerCom(go, self.Servers)
		self:UpdateServerData(list[index], server, index)
	else
		server.Root:SetActive(true)
		self:UpdateServerData(list[index], server, index)
	end
end

function M:AddItem(index, grid, prefab)

	local go = GameObject.Instantiate(prefab)
	go.name = tostring(index)
	go.transform.parent = grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	return go
end

--获取Title控件
function M:GetTitleCom(go, list)
	local C = ComTool.Get
	local T = TransTool.FindChild
	local data = {}
	data.Root = go
	local trans = go.transform
	data.Title = C(UILabel, trans, "Title", name, false)
	data.Select = T(trans, "Select")
	table.insert(list, data)
	return data
end
--更新Title内容
function M:UpdateTitleData(info, data)
	data.Title.text = info.name
	data.Info = info
end

--获取服务器Item控件
function M:GetServerCom(go, list)
	local C = ComTool.Get
	local T = TransTool.FindChild
	local data = {}
	data.Root = go
	local trans = go.transform
	data.Icon = C(UISprite, trans, "Icon", name, false)
	data.Name = C(UILabel, trans, "Label", name, false)
	data.Select = T(trans, "Select")
	data.IsNew = T(trans, "New")
	table.insert(list, data)
	return data
end

--设置服务器Item内容
function M:UpdateServerData(info, data, index)
	if not info then return end
	data.Icon.spriteName = string.format("type_%s", info.status)
	data.Name.text = info.name
	data.IsNew:SetActive(tonumber(info.is_new) == 1)
	data.Info = info
	if self.CurServerInfo and self.CurServerInfo.server_id == info.server_id then
		data.Select:SetActive(true)
		self.CurServer = index
	end
end

function M:Reposition(panel, grid, drag)
	if grid then
		grid:Reposition()
	end
	if panel then
		panel.isDrag = drag
	end
end

function M:OnClickTitle(go, set)
	if set == nil then set = false end
	local index = tonumber(go.name)
	if self.CurTitle then 
		if self.CurTitle == index then return end
		self.Titles[self.CurTitle].Select:SetActive(false)
	end
	self.CurTitle = index
	local data = self.Titles[self.CurTitle]
	data.Select:SetActive(true)
	local curServer = self.CurServer
	if curServer then 
		if self.Servers[curServer] then
			self.Servers[curServer].Select:SetActive(false)
		end
	end
	if set == true then 
		self:UpdateServer()
		return 
	end
	ServerMgr:SelectPage(index)
end

function M:OnClickServer(go)
	local index = nil
	for i=1,#self.Servers do
		local data = self.Servers[i]
		if data and data.Root and data.Root.name == go.name then
			index = i
		end
	end
	if not index then return end
	if self.CurServer then 
		if self.CurServer == index then 
			self.SelectServer(self.CurServer, self.Servers[self.CurServer].Info)
			self:SetActive(false)
			return 
		end
		self.Servers[self.CurServer].Select:SetActive(false)
	end
	self.CurServer = index
	local data = self.Servers[self.CurServer]
	self.CurServerInfo = data.Info
	data.Select:SetActive(true)
	self.SelectServer(tonumber(go.name), data.Info)
	self:SetActive(false)
end

function M:OnClickBack(go)
	self:SetActive(false)
end

function M:SetTitle(title)
	if not title or title == 0 then return end
	local list = self.Titles
	if not list then return end
	local data = self.Titles[title]
	if not data then return end 
	self:OnClickTitle(data.Root, true)
end

function M:SetServer(index)
	local list = self.Servers
	if not list then return end
	local item = list[index]
	if item then
		self:OnClickServer(item.Root)
	end
end

function M:CleanTitle()
	if self.Titles then
		for k,v in pairs(self.Titles) do
			v.Title.text = ""
			v.Select.Root:SetActive(false)
		end
	end
end

function M:CleanServer()
	local list = self.Servers
	if list then
		for i=1,#list do
			list[i].name = tostring(i)
			list[i].Root:SetActive(false)
		end
	end
end

--清楚数据
function M:Clean()
	self:CleanTitle()
	self:CleanServer()
end

function M:SetActive(value)
	if value == true then
		SData.eUpdateServers:Add(self.UpdateServer, self)
	else
		SData.eUpdateServers:Remove(self.UpdateServer, self)
	end
	if self.gbj then
		self.gbj:SetActive(value)
	end
end

--释放或销毁
function M:Dispose(isDestory)
	self:Clean()
	self.Titles = nil
	self.gbj = nil
	self.LPanel = nil
	self.LGrid = nil
	self.LPrefab = nil
	
	self.SPanel = nil
	self.SUISV = nil
	self.SGrid = nil
	self.SPrefab = nil
end
--endregion

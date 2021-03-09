--region ServerData.lua
--Date
--此文件由[HS]创建生成

ServerData = {}
local M = ServerData

local LoadEnterKey = "登入过的服务器"
local NewServer = "推荐新服"

--读取服务器数据完成
M.eUpdateServers = Event()
--缓存数据
M.RecordData = nil
--组合数据
M.AllData = {}

--标签名
M.Name = ""
--区服总条数
M.Total = 0
--每页条数
M.Limit = 0
--总页数
M.TotalPage = 0
--当前分页
M.Page = 0

--==============================-------------
 function M:GetGameChannelID()
	do return User.GameChannelId end
 end
 
 function M:CheckServer(t)
	 if not t then return false end
	 if #t == 0 then return false end
	 if not t[1].servers  then return false end
	 if #t[1].servers == 0 then return false end
	 return true
 end

--服务器数据
function M:ServerInfo(data)
	self.Total = data.total
	self.Limit = data.limit
	self.Page = data.now_page
	self.TotalPage = data.total_page
end

--更新分页
function M:UpdateTitle(data, page)
	if self.AllData.titles == nil then
		self.AllData.titles = {}
	end
	self.Name = data.name
	self:UpdateServersTitle()
	if page == nil then
		self:UpdateNewServersTitle()
	end
	self:SortTitle()
end

--标签排序
function M:SortTitle()
	local titles = self.AllData.titles
	if titles and #titles > 0 then
		table.sort(titles, function(a,b)
			if a.IsLoadEnter == true and not b.IsLoadEnter then
				return true
			elseif not a.IsLoadEnter and b.IsLoadEnter then
				return false
			end
			if a.IsNew == true and not b.IsNew then
				return true
			elseif not a.IsNew and b.IsNew then
				return false
			end
			if a.page and b.page then
				return a.page > b.page
			end
			return true
		end )
	end
end

--设置新服标签
function M:UpdateNewServersTitle()
	local data = self.AllData
	local titles = self.AllData.titles
	local servers = self.AllData.servers
	if not servers then return end
	local i = TableTool.Contains(titles, NewServer, "name")
	if i == -1 then
		local d = {}
		d.name = NewServer
		d.IsNew = true
		d.page = #titles + 1
		table.insert(self.AllData.titles, 1, d)
	end
end

--设置服务器标签
function M:UpdateServersTitle()
	local name = self.Name
	local total = self.Total
	local totalPage = self.TotalPage
	local limit = self.Limit
	local start = 1
	local len = 0
	local titles = self.AllData.titles
	for i=1,totalPage do
		start = (i-1) * limit + 1
		len = i * limit
		if start == 0 then start = 1 end
		local name = string.format("%s [%s-%s]",name, start, len)
		local index = TableTool.Contains(titles, name, "name")
		if index == -1 then
			local d = {}
			d.name = name
			d.page = i
			table.insert(self.AllData.titles, d)
		end
	end
end

--更新服务器数据
function M:UpdateServer(servers)
	self.AllData.servers = servers
	self.eUpdateServers()
end

--读取缓存的服务器数据
function M:UpdateRecordData(servers)
	self.RecordData = self:LoadRecord()
	if self.RecordData then
		local record = self.RecordData[UserMgr:GetAccount()]
		if record then
			self:CheckServerIndexId(record)
			for i=1,#record do
				local id = record[i]
				local index = TableTool.Contains(servers, id, "id")
				if index == -1 then
					ServerMgr:RecordWrite(0, UserMgr:GetAccount(), id)
					table.insert(servers, id)
				end
			end
			self.RecordData[UserMgr:GetAccount()] = nil
			--ServerMgr:EnterRecordWrite()
		end
	end
	if servers and #servers > 0 then
		local titles = self.AllData.titles
		local i = TableTool.Contains(titles, LoadEnterKey, "name")
		if i == -1 then
			local d = {}
			d.name = LoadEnterKey
			d.IsLoadEnter = true
			d.page = #titles + 1
			table.insert(titles, 1, d)
		end
		self:UpdateServer(servers)
	end
end

--读取缓存服务器数据
function M:LoadRecord(acc)
	local j = User.EnterRecord
	if StrTool.IsNullOrEmpty(j) == false then
		local r = json.decode(j)
		if r then
			return r
		end
	else
		iTrace.eLog("hs", "没有缓存服务器信息:【第一次登入】")
	end
	return nil
end

function M:CheckServerIndexId(list)
	local servers = self.AllData.servers
	local len = #list
	local index = 1
	while len >= index do
		local id = list[index]
		local isRemove = false
		for k,v in pairs(servers) do
			if v.id == id then
				isRemove = true
				break
			end
		end
		if isRemove == true then
			local offset = list[index]
			list[index] = list[len]
			list[len] = offset
			table.remove(list, len)
			len = #list
		end
		index = index + 1
	end
end


function M:Clear()
	self.RecordData = nil
	self.Name = ""
	self.Total = 0
	self.Limit = 0
	self.TotalPage = 0
	self.Page = 0
	TableTool.ClearDic(self.AllData)
end

function M:Dispose()
	-- body
end

return M

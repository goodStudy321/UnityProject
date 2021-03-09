--region UIMyTeamView.lua
--Date
--此文件由[HS]创建生成


UIMyTeamView = {}
local M = UIMyTeamView
M.eChat=Event()
local E = UITool.SetLsnrSelf
--注册的事件回调函数

function M:New(go)
	local name = "我的队伍窗口"
	self.GO = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Player = {}
	for i=1,3 do
		local cell = UIMyTeamPlayer.New(T(trans, string.format("Player%s",i)))
		if cell ~= nil then 
			cell:Init()
			table.insert(self.Player, cell)
			UITool.SetLsnrSelf(cell.GO, self.OnClickView, self, nil, false)
		end
	end
	self.CurSelect = nil
	--self:UpdateData()
	self:AddEvent()
	return M
end

function M:AddEvent()
end

function M:RemoveEvent()
end

function M:UpdateData()
	self:Clean()
	local info = TeamMgr.TeamInfo
	if not info then return end
	self:UpdatePlayerBtn(info)
	local list = info.Player
	if not list or #list == 0 then
		self:Clean()
		return
	end
	local iList = self.Player
	local iLen = #iList
	local len = #list
	for i=1,iLen do
		view = self.Player[i]
		local data = list[i]
		view:UpdateData(data)
	end
end

function M:UpdatePlayerBtn(info)
	local id = info.TeamId
	local value = id ~= nil
	local len = #self.Player
	for i=1,len do
		local view = self.Player[i]
		view:UpdateBtn(value)
	end
end

function M:OnClickView(go)
	local name = string.gsub(go.name, "Player", "")
  	local index = tonumber(name)
 	if #self.Player < index then return end
  	local cell = self.Player[index]
	if not cell or not cell.Data then return end
	local select = self.CurSelect  
  	if select then
  		if select.GO.name == cell.GO.name then 
  			return 
  		else
			select:IsSelect(false)
  		end
  	end
  	self.CurSelect = cell
  	self.CurSelect:IsSelect(true)
end

function M:CleanSelect()
	if self.CurSelect then
  		self.CurSelect:IsSelect(false)
  		self.CurSelect = nil
	end
end

function M:Clean()
	self:CleanSelect()
	for i,v in ipairs(self.Player) do
		v:Clean()
	end
end

function M:Dispose()
	self:Clean()
	self.Name = nil
	self.Lv = nil
	self.SettingBtn = nil
	self.ExitBtn = nil
	self.RemoveBtn = nil
	self.ChangeBtn = nil
	if self.Player then
		if  type(arr) ~= "table" then
			local item = nil	
			for i,v in ipairs(self.Player) do
				v:Dispose()
				TableTool.ClearDic(self.Player[i])
				self.Player[i] = nil
			end
		end
		self.Player = nil
	end
end
--endregion

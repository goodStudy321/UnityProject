--region UIFlowers.lua
--Date
--此文件由[HS]创建生成

UIFlowersSelectPlay = UIFlowersSelectBase:New{Name="UIFlowersSelectPlay"}
local M = UIFlowersSelectPlay

local fMgr = FriendMgr

function M:CustomInitData()
	self.List = {}
end

function M:GetTabLen()
	local user = User.MapData
	local data = {}
	data.ID = user.UIDStr
	data.Name = "自己"
	data.Sex = user.Sex
	data.Level = user.Level
	data.Category = user.Category
	data.VIP = VIPMgr.vipLv
	data.Online = true
	table.insert(self.List, data)
	local friends = fMgr.FriendList
	if friends then
		for i,v in ipairs(friends) do
			if v.Online == true then
				table.insert(self.List, v)
			end
		end
		return #self.List
	end
	return 0
end

function M:UpdateItem(index, trans)
	local name = "送花选择好友"
	local C = ComTool.Get
	local T = TransTool.FindChild
	local data = {}
	data.Icon = C(UITexture, trans, "Icon", name, false)
	data.Name = C(UILabel, trans, "Label", name, false)
	data.FamiliarityValue = {}
	data.FamiliarityRoot = T(trans, "Familiarity")
	for i=1, 5 do
		local f = C(UISprite, trans, string.format("Familiarity/Item%s",i), self.Name, false)
		table.insert(data.FamiliarityValue, f)
	end
	table.insert(self.Items, data)
	self:UpdateItemData(index, data)
end

function M:UpdateItemData(index, data)
	local list = self.List
	if not list or #list <= 0 then return end
	local friend = list[index]
	if not friend then return end

	self:UpdateName(friend, data)
	self:UpdateIcon(friend, data)
	self:Familiarity(friend, data)
end

function M:UpdateName(friend, data)
	if data.Name then
		if friend.Name then
			if friend.ID == User.MapData.UIDStr then
				data.Name.text = string.format("[00FF02]%s[-]", friend.Name)
			else
				data.Name.text = friend.Name
			end
		else
			data.Name.text = ""
		end
	end
end

function M:UpdateIcon(friend, data)
	if not StrTool.IsNullOrEmpty(self.Path) then
		self:UnloadPic()
	end
	local path = string.format( "tx_0%s.png", friend.Category)
	if data.Icon then
		self.Path = path
		local del = ObjPool.Get(DelLoadTex)
		del:Add(data.Icon)
		del:SetFunc(self.SetIcon,self)
		AssetMgr:Load(path,ObjHandler(del.Execute, del))
	end
end

function M:SetIcon(tex, icon)
	if icon then
		icon.mainTexture = tex
	end
end

function M:UnloadPic()
	if not StrTool.IsNullOrEmpty(self.Path) then
		AssetMgr:Unload(self.Path, ".png", false)
	end
	self.Path = nil
end

function M:Familiarity(friend, data)
	if data.FamiliarityRoot then
		data.FamiliarityRoot:SetActive(friend.Friendly ~= nil)
	end
	if friend.Friendly == nil then return end
	local value = friend.Friendly
	local list = data.FamiliarityValue
	if not list then return end
	local k,v = math.modf(value / 2000)
	if k > 5 then k = 5 end
	if k > 0 and #list >= k then
		for i=1, k do
			list[i].fillAmountValue = 1
		end
	end
	if k >= 5 then return end
	list[k + 1].fillAmountValue = v
end

function M:FriendlyUpdate(id, value)
	local friend, index = fMgr:GetListIndex(self.List, id)
	self:Familiarity(friend, self.Items[index])
end

function M:CustomSetValue(id)
	if not id then return end
	local data, index = fMgr:GetListIndex(self.List, id)
	if not data then return end
	self:SetValue(index, data.Name)
	self:CustomClicItem()
end

function M:CustomClicItem()
	if not self.Index then return end
	local list = self.List
	if not list or #list <= 0 then return end
	self.Data = list[self.Index]
	self.Value = self.Data.Name
	self:UpdateVLabel()
	self.eSelect()
end

function M:CustomOpen()
	-- body
end


function M:CustomClose()
	-- body
end

function M:CustomClean()
	TableTool.ClearDic(self.List)
end

function M:CustomDispose()
end
--endregion

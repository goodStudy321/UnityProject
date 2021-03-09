--region UIFriendRequestItem.lua
--好友请求item
--此文件由[HS]创建生成

UIFriendRequestItem = Super:New{Name="UIFriendRequestItem"}

local M = UIFriendRequestItem

local fMgr = FriendMgr

M.Base = nil

--初始化控件
function M:Init(go)
	self.Root = go
	self.Name = "UIFriendRequestItem"
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = self.Root.transform
	local name = self.Name
	self.Icon = ComTool.Get(UITexture, trans, "Icon", self.Name, false)
	self.Label = ComTool.Get(UILabel, trans, "Name", self.Name, false)
	self.LV = C(UILabel, trans, "LV", name, false)
	self.RLV = T(trans, "LV/IsGod")

	local E = UITool.SetLsnrSelf
	self.Add = T(trans, "Add")
	self.Remove = T(trans, "Remove")
	if self.Add then	
		E(self.Add, self.OnClickAdd, self)
	end
	if self.Remove then
		E(self.Remove, self.OnClickRemove, self)
	end
end

--玩家数据
function M:UpdateData(data)
	if data == nil then 
		self:SetActive(false)
		return 
	end
	self:SetActive(true)
	self.Data = data
	self:UpdateIcon(data.Category)
	local name = self.Data.Name
	if self.IsFriend == true then
		if self.Data.Online == true then 
			name = name.." [ADFF2F]在线[-]"
		else
			name = name.." [919191]离线[-]"
		end
	end
	self:UpdateLabel(name)
	self:UpdateLV(self.Data.Level)
end

function M:UpdateIcon(cate)
	local path = string.format( "tx_0%s.png", cate)
	if self.Icon then
		self:UnloadIcon()
		self.IconName = path
		local del = ObjPool.Get(DelLoadTex)
		del:Add(self.Icon)
		del:SetFunc(self.SetIcon, self)
		AssetMgr:Load(path,ObjHandler(del.Execute,del))
	end
end

function M:SetIcon(tex, icon)
	if not LuaTool.IsNull(icon) then
		icon.mainTexture = tex
	else
		Destroy(tex)
		self:UnloadIcon()
	end
end

function M:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

--更新Label
function M:UpdateLabel(value)
	if self.Label then
		if value ~= 0 then
			self.Label.text = value
		else
			self.Label.text = ""
		end 
	end
end

--更新玩家等级
function M:UpdateLV(lv)
	local status = UserMgr:IsGod(lv)
	if LuaTool.IsNull(self.LV) == false  then
		self.LV.text = UserMgr:GetChangeLv(lv, false)
		local pos = self.LV.transform.localPosition
		if status == true then
			pos.x = -225
		else
			pos.x = -196
		end
		self.LV.transform.localPosition = pos
		self.LV.gameObject:SetActive(true)
	end
	if self.RLV then
		self.RLV:SetActive(status)
	end
end

function M:OnClickAdd(go)
	if self.Data == nil then 
		UITip.Error("添加好友失败！！！")
		return 
	end
	fMgr:ReqAddFriend(self.Data.ID)
	self:Clear()
	local base = self.Base
	if base then
		base:GridReposition()
	end
end

function M:OnClickRemove(go)
	if self.Data == nil then 
		UITip.Error("移除好友请求失败！！！")
		return 
	end
	fMgr:ReqDelRequestFriend(self.Data.ID)
	self:Clear()
	local base = self.Base
	if base then
		base:GridReposition()
	end
end

function M:SetActive(value)
	if LuaTool.IsNull(self.Root) == false then
		self.Root:SetActive(value) 
	end
end

--清楚数据
function M:Clear()
	self:SetActive(false)
	self:SetIcon(nil)
	self:UnloadIcon()
	if self.LV then self.LV.text = "" end
	if self.RLV then self.RLV:SetActive(false) end
	if self.Label then self.Label.text = "" end
end

--释放或销毁
function M:Dispose(isDestory)
	if self.Root then
		self.Root.transform.parent = nil
		if isDestory then
			Destroy(self.Root)
		end
	end
	self.Root = nil
	TableTool.ClearDic(self)
end
--endregion

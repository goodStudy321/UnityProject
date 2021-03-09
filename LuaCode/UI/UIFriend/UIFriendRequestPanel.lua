--region UIFriendRequestPanel.lua
--好友请求提示
--此文件由[HS]创建生成

UIFriendRequestPanel = UIBase:New{Name ="UIFriendRequestPanel"}
local M = UIFriendRequestPanel

function M:InitCustom()
	local name = "好友请求提示"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Icon = ComTool.Get(UITexture, trans, "Icon", name, false)
	self.Label = ComTool.Get(UILabel, trans, "Name", name, false)
	self.LV = C(UILabel, trans, "LV", name, false)
	self.RLV = T(trans, "LV/IsGod")
	self.Btn1 = C(UIButton, trans, "Button1", name, false)
	self.Btn2 = C(UIButton, trans, "Button2", name, false)
	self.CloseBtn = C(UIButton, trans, "Close", name, false)
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Btn1 then	
		E(self.Btn1, self.OnClickBtn, self)
	end
	if self.Btn2 then	
		E(self.Btn2, self.OnClickBtn, self)
	end
	if self.CloseBtn then
		E(self.CloseBtn, self.OnClickCloseBtn, self)
	end
end

function M:RemoveEvent()
end

function M:OnClickBtn(go)
	local data = self.Data
	if data then 
		local id = data.ID
		if self.Btn1.name == go.name then
			FriendMgr:ReqDelRequestFriend(id)
		elseif self.Btn2.name == go.name then
			FriendMgr:ReqAddFriend(id)
		end
	end
	self:Close()
end

function M:OnClickCloseBtn(go)
	self:Close()
end

-----------------------更新数据----------------------------
function M:UpdateData(data)
	self.Data = data
	self:UpdateIcon(data.Category)
	local name = data.Name
	if self.Data.Online == true then 
		name = name.." [ADFF2F]在线[-]"
	else
		name = name.." [919191]离线[-]"
	end
	self:UpdateLabel(name)
	self:UpdateLV(data.Level)
end

--更新Icon
function M:UpdateIcon(path)
	if self.Icon then
		local path = string.format( "tx_0%s.png", path)
		if StrTool.IsNullOrEmpty(path) then	
			self.Icon.mainTexture = nil
			self.Icon.gameObject:SetActive(false)
			self.Icon.gameObject:SetActive(true)
			return
		end
		self.IconName = path
		AssetMgr:Load(path,ObjHandler(self.SetIcon, self))
	end
end

function M:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = tex
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
	if self.LV then
		self.LV.text = UserMgr:GetChangeLv(lv, false)
		local pos = self.LV.transform.localPosition
		if status == true then
			pos.x = 33.18
		else
			pos.x = 3
		end
		self.LV.transform.localPosition = pos
		self.LV.gameObject:SetActive(true)
	end
	if self.RLV then
		self.RLV:SetActive(status)
	end
end

function M:Clear()
	self:UnloadIcon()
	if self.Icon then self.Icon.mainTexture = nil end
	if self.Label then self.Label.text = "" end
	if self.LV then self.LV.text = "" end
end
-----------------------------------------------

function M:OpenCustom()
	local data = FriendMgr.RequestList[1]
	if data then
		self:UpdateData(data)
	else
		self:Close()
	end
end

function M:CloseCustom()
	self:Clear()
end

--释放或销毁
function M:Dispose()
	self:RemoveEvent()
end
--endregion
return UIFriendRequestPanel

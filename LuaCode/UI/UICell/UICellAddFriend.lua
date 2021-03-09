--region UICellAddFriend.lua
--Cell 加好友Cell
--此文件由[HS]创建生成

UICellAddFriend = Super:New{Name="UICellAddFriend"}



local M = UICellAddFriend
M.eClickCell = Event()
M.eClickFamiliar = Event()

local fMgr = FriendMgr

--初始化控件
function M:Init(go, isFriend)
	self.Root = go
	self.Name = "UICellAddFriend"
	self.IsFriend = isFriend
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = self.Root.transform
	local name = self.Name
	self.Icon = ComTool.Get(UITexture, trans, "Icon", self.Name, false)
	self.Label = ComTool.Get(UILabel, trans, "Name", self.Name, false)
	self.LV = C(UILabel, trans, "LV", name, false)
	self.RLV = T(trans, "LV/IsGod")
	self.Select = T(trans, "Select")
	self.red=T(trans,"red")
	local E = UITool.SetLsnrSelf
	if isFriend == true then
		self.FamiliarityRoot = T(trans, "Familiarity")
		self.FamiliarityRoot:SetActive(true)
		self.FamiliarityValue = {}
		for i=1, 5 do
			local f = C(UISprite, trans, string.format("Familiarity/Item%s",i), self.Name, false)
			table.insert(self.FamiliarityValue, f)
		end
		E(self.FamiliarityRoot, self.OnClickFamiliarity, self, nil, false)
	end
	self.Add = C(UIButton, trans, "Button", name, false)
	if self.Add then	
		E(self.Add, self.OnClickAddBtn, self)
	end
	if self.Root then
		E(self.Root, self.OnClickCell, self, nil, false)
	end
	if isFriend == true then
		self.ClickMenu = Event()
	end
	self:Clean()
end

--玩家数据
function M:UpdateData(data)
	if data == nil then 
		self.Root:SetActive(false) 
		return 
	end
	self.Data = data
	if self.Data == nil then return end
	if self.Data.ID == fMgr.TalkId then
		self:SetActive(true)
		self:OnClickCell()
	end
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
	if self.IsFriend == true then
		self:Familiarity(self.Data.Friendly)
	end
	if self.Add then self.Add.gameObject:SetActive(true) end
end

function M:UpdateIcon(cate)
	local path = string.format( "tx_0%s.png", cate)
	if self.Icon then
		self:UnloadIcon()
		if StrTool.IsNullOrEmpty(path) == false then	
			self.Icon.gameObject:SetActive(true)
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
			pos.x = 165.73
		else
			pos.x = 133.03
		end
		self.LV.transform.localPosition = pos
		self.LV.gameObject:SetActive(true)
	end
	if self.RLV then
		self.RLV:SetActive(status)
	end
end

function M:Familiarity(value)
	if not self.FamiliarityValue then return end
	local k,v = math.modf(value / 2000)
	if k > 5 then k = 5 end
	if k > 0 and #self.FamiliarityValue >= k then
		for i=1, k do
			self.FamiliarityValue[i].fillAmountValue = 1
		end
	end
	if k >= 5 then return end
	self.FamiliarityValue[k + 1].fillAmountValue = v
end

function M:OnClickFamiliarity(go)
	if not self.Data then return end
	local temp = fMgr:GetFamiliarty(self.Data.Friendly)
	if not temp then return end
	self.eClickFamiliar(temp, self.Data.Friendly)
end

function M:OnClickAddBtn(go)
	if not self.IsFriend then
		if self.Data == nil then 
			UITip.Error("添加好友失败！！！")
			return 
		end
		fMgr:ReqAddFriend(self.Data.ID)
		UITip.Error("已发送申请")
		self.Add.Enabled = false
	else
		self.ClickMenu(self.Data)
	end
end

function M:OnClickCell(go)
	if not self.Data then return end
	M.eClickCell(self, self.Data)
end

function M:SetActive(value)
	if self.Select then
		self.Select:SetActive(value)
	end
end

--清楚数据
function M:Clean()
	self:UnloadIcon()
	if self.LV then 
		self.LV.text = "" 
		self.LV.gameObject:SetActive(false)
	end
	if self.FamiliarityValue then
		for i=1, #self.FamiliarityValue do
			self.FamiliarityValue[i].fillAmountValue = 0
		end
	end
	if self.Label then self.Label.text = "" end
	if self.Icon then self.Icon.gameObject:SetActive(false) end
	if self.Add then 
		self.Add.gameObject:SetActive(false) 
		
		self.Add.Enabled = true
	end
end

--释放或销毁
function M:Dispose(isDestory)
	self.ClickMenu:Clear()
	if self.Root then
		self.Root.transform.parent = nil
		if isDestory then
			Destroy(self.Root)
		end
	end
	self.Root = nil
end
--endregion

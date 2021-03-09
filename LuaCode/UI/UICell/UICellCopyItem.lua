--region UICellCopyItem.lua
--Cell 系统ItemCell
--此文件由[HS]创建生成

UICellCopyItem = Super:New{Name = "UICellCopyItem"}

local M = UICellCopyItem

--初始化控件
function M:Init(go, index)
	local name = self.Name
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Index = index
	self.GO = go
	self.LabName = C(UILabel, trans, "Label", name, false)
	self.Icon = C(UISprite, trans, "Icon", name, false)
	self.Lv = C(UILabel, trans, "Lv", name, self)
	self.Select = T(trans, "Select")
	self:IsSelect(false)
	self.Double = T(trans, "Double")
	self.RedPoint = T(trans, "RedPoint")
end

function M:UpdateInfo(info)
	self.Info = info
	if not info then return end
	self.Temp = info.Temp
	self:UpdateName()
	self:Updatelv()
	self:UpdateIcon()
	self:UpdateDouble()
end

function M:UpdateRealInfo()
	self:UpdateName()
	self:Updatelv()
	self:UpdateIcon()
end

function M:UpdateRedPoint(bool)
	self.RedPoint:SetActive(bool)
end

function M:GetRedPointActive()
	return self.RedPoint.activeSelf
end

function M:UpdateDouble()
	self.Double:SetActive(CopyMgr:IsDoubleCopy(self.Temp.type))
end

function M:UpdateName()
	local temp = self.Temp
	if self.LabName then
		self.LabName.text = CopyMgr:GSub(temp.name)
	end
end

function M:Updatelv()
	local temp = self.Temp
	if self.Lv then
		local lv = temp.lv
		self.Lv.text = tostring(lv)
		self.Lv.gameObject:SetActive(User.MapData.Level < lv)
	end
end

function M:UpdateIcon()
	local temp = self.Temp
	if self.Icon then
		self.Icon.spriteName = string.format("tower_%s", self.Index)
	end
end

function M:IsSelect(value)
	if self.Select then
		self.Select:SetActive(value)
	end
	local name = self.LabName
	if name then
		if value == true then
			name.color = Color.New(233, 172, 80, 255) / 255
		else
			name.color = Color.New(177, 164, 149, 255) / 255
		end
	end
end

function M:IsOpen()
	local temp = self.Temp
	local lv = 0
	if temp then
		lv = temp.lv
		if User.MapData.Level >= lv then
			return true
		end
	end
	self:ShowOpenTip(lv)
	return false
end

function M:ShowOpenTip(lv)
	UITip.Error(string.format("角色达到%s级开启该玩法", UIMisc.GetLv(lv)))
end

--释放或销毁
function M:Dispose()
	self.Temp = nil
	self.Info = nil
	TableTool.ClearUserData(self)
end
--endregion

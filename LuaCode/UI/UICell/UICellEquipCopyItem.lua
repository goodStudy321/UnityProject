--region UICellEquipCopyItem.lua
--Cell 系统ItemCell
--此文件由[HS]创建生成

UICellEquipCopyItem = Super:New{ Name = "UICellEquipCopyItem"}

local M = UICellEquipCopyItem

function M:Ctor()
	self.Cells = {}
end

--初始化控件
function M:Init(go)
	local name = self.Name
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.GO = go
	self.BG = C(UITexture, trans, "BG", name, false)
	self.LabName = C(UILabel, trans, "Name", name, false)
	self.Lv = C(UILabel, trans, "Lv", name, self)
	self.Lock = C(UILabel, trans, "Lock", name, false)
	self.Select = T(trans, "Select")
	self.Grid = C(UIGrid, trans, "Grid", name, false)
	self.Double = T(trans, "Double")
	self.texList = {}
	self:IsSelect(false)
end

function M:UpdateInfo(info)
	self.Info = info
	if not info then return end
	if not info.Temp then return end
	self.Temp = info.Temp
	self:UpdateName()
	self:UpdateBG()
	self:UpdateReward()
	self:Updatelv()
	self:UpdateDouble()
end

function M:UpdateRealInfo()
	self:Updatelv()
end

function M:UpdateDouble()
	self.Double:SetActive(CopyMgr:IsDoubleCopy(self.Temp.type))
end

function M:UpdateName()
	local temp = self.Temp
	if self.LabName then
		self.LabName.text = temp.name
	end
end

function M:Updatelv()
	local temp = self.Temp
	if not temp then return end
	local lv = temp.lv
	local isOpen = User.MapData.Level >= lv and CopyMgr:GetPreCopy(CopyMgr.Equip, temp.pre)
	if self.Lv then
		self.Lv.text = UIMisc.GetLv(lv)
		self.Lv.gameObject:SetActive(isOpen)
	end
	if self.Lock then
		self.Lock.text = UIMisc.GetLv(lv)
		self.Lock.gameObject:SetActive(not isOpen)
	end
	local a = 1
	if not isOpen then
		a = 0
	end
	if self.BG then
		self.BG.color = Color.New(a,1,1,1)
	end
	if self.Cells then
		local len = #self.Cells
		for i=1, len do
			local cell = self.Cells[i]
			if cell then
				if cell.Icon then
					cell.Icon.color = Color.New(a,1,1,1)
				end
				if cell.Qua then
					cell.Qua.color = Color.New(a,1,1,1)
				end
			end
		end
	end
end

function M:UpdateBG()
	local temp = self.Temp
	if not temp then return end
	if self.BG then
		local pic = temp.pic
		if StrTool.IsNullOrEmpty(pic) then	
			self.BG.mainTexture = nil
			self.BG.gameObject:SetActive(false)
			self.BG.gameObject:SetActive(true)
			return
		end
		AssetMgr:Load(pic,ObjHandler(self.SetIcon, self))
	end
end

--更新奖励
function M:UpdateReward()
	local temp = self.Temp
	if not temp then return end
	local list = temp.sItems
	if not list then return end
	local num = #list
	for i=1,num do
		local data = list[i]
		local item = ObjPool.Get(UIItemCell)
		item:InitLoadPool(self.Grid.transform)
		item:UpData(data.k, data.v)
		table.insert(self.Cells, item)
	end
	self.Grid:Reposition()
end


function M:SetIcon(texture)
	if self.texList then
		self.BG.mainTexture = texture
		table.insert(self.texList, texture.name)
	else
		AssetTool.UnloadTex(texture.name)
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

function M:IsOpen(isInit)
	local temp = self.Temp
	local lv = 0
	if temp then
		lv = temp.lv
		if User.MapData.Level < lv and not isInit then
			self:ShowOpenTip(lv)
			return false
		end
		if temp.pre and not CopyMgr:GetPreCopy(CopyMgr.Equip, temp.pre) then
			self:ShowOpenPreTip(temp.pre)
			return false
		end
	end
	return true
end

function M:ShowOpenTip(lv)
	UITip.Error(string.format("角色达到%s级开启该玩法",UIMisc.GetLv(lv)))
end

function M:ShowOpenPreTip(id)
	local temp = CopyTemp[tostring(id)]
	if not temp then return end
	UITip.Error("通关上一副本开启该副本")
end

--释放或销毁
function M:Dispose()
	self.Info = nil	
	TableTool.ClearDicToPool(self.Cells)
	AssetTool.UnloadTex(self.texList)
	self.texList = nil
	TableTool.ClearUserData(self)
end
--endregion

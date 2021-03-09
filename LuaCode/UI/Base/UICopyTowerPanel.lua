UICopyTowerPanel = UIBase:New{Name ="UICopyTowerPanel"}

require("UI/UICopyTower/UICopyTowerTT")
require("UI/UICopyTower/UICopyTowerZH")
require("UI/UICopyTower/UICopyTowerTX")

local M = UICopyTowerPanel

M.toggleList = {}

function M:InitCustom()
	local FC = TransTool.FindChild
	local G = ComTool.Get
	local trans = self.root

	self.grid = G(UIGrid, trans, "ToggleGroup/Grid")
	self.prefab = FC(self.grid.transform, "Toggle")

	self.copyTowerTT = ObjPool.Get(UICopyTowerTT)
	self.copyTowerTT:Init(FC(trans, "TT"))

	self.copyTowerZH = ObjPool.Get(UICopyTowerZH)
	self.copyTowerZH:Init(FC(trans, "ZH"))
	
	self.copyTowerTX = ObjPool.Get(UICopyTowerTX)
	self.copyTowerTX:Init(FC(trans, "TX"))

	self:InitToggle()

	self.grid:Reposition()
	UITool.SetLsnrClick(trans, "BtnClose", self.Name, self.OnClose, self)
	self:SwitchCopy(self.copyType or CopyType.Tower)

	self:SetLsnr("Add")
	self:InitRedPoint()
end

function M:SetLsnr(key)
	CopyMgr.eUpdateRedPoint[key](CopyMgr.eUpdateRedPoint, self.UpdateRedPoint, self)
	TongtianRankMgr.eAdmire[key](TongtianRankMgr.eAdmire, self.UpdateRed, self)
end

function M:UpdateRedPoint(copyType, state)
	local list = self.toggleList
	for i=1,#list do
		local name = list[i]:GetGoName()
		list[i]:SetRedPoint(name == copyType and state)
	end
end

function M:UpdateRed()
	local state = TongtianRankMgr.isRed  
	self:UpdateRedPoint(tostring(CopyType.TXTower), state)
	self.copyTowerTX:UpdateRed(state)
end

function M:InitRedPoint()
	CopyMgr:UpdateCopyRedPoint()
	self:UpdateRed()
end

function M:InitToggle()
	self:AddToggle(CopyType.Tower, "九九窥星塔")
	self:AddToggle(CopyType.TXTower, "太虚通天塔")
	self:AddToggle(CopyType.ZHTower, "镇魂塔")
end

function M:AddToggle(copyType, name)
	local G = ComTool.Get
	local go = Instantiate(self.prefab)
	go.name = copyType
	TransTool.AddChild(self.grid.transform, go.transform)
	local tog = ObjPool.Get(BaseToggle)
	local spr = G(UISprite, go.transform, "spr1")
	tog:Init(go)
	tog:SetName(name)
	tog.eClick:Add(self.OnToggle, self)
	tog:SetActive(true)
	table.insert(self.toggleList, tog)
	self:SetSpr(spr, copyType)
end

function M:SetSpr(spr, type)
    if type == CopyType.Tower then
        spr.spriteName = "zht_L_1"
    elseif type == CopyType.TXTower then
        spr.spriteName = "zht_L_3"
    elseif type == CopyType.ZHTower then
        spr.spriteName = "zht_L_2"
    end
end

function M:OnToggle(name)
	local copyType = tonumber(name)
	self:SwitchCopy(copyType)
end

function M:Show(copyType)
	local _, isOpen, _, lv = CopyMgr:GetCurCopy(copyType)
	if not isOpen then 
		UITip.Log(string.format("%s开启", UserMgr:chageLv(lv)))
		return 
	end
	self.copyType = copyType
	UIMgr.Open(self.Name)
end

function M:OpenTabByIdx(t1, t2, t3, t4)
	-- self:Show(t1)
	self:SwitchCopy(t1)
end


function M:SwitchCopy(copyType)
	if self.curType and self.curType == copyType then return end

	local _, isOpen, _, lv = CopyMgr:GetCurCopy(copyType)
	if not isOpen then 
		UITip.Log(string.format("%s开启", UserMgr:chageLv(lv)))
		return 
	end

	self.curType = copyType
	if self.curView then
		self.curView:Close()
		self.curView = nil
	end
	if copyType == CopyType.Tower then
		self.curView = self.copyTowerTT
	elseif copyType == CopyType.TXTower then
		self.curView = self.copyTowerTX
	elseif copyType == CopyType.ZHTower then
		self.curView = self.copyTowerZH
	end	
	if self.curView then
		self.curView:Open()
	end
	self:UpdateToggelState(copyType)
end

function M:UpdateToggelState(copyType)
	local list = self.toggleList
	for i=1,#list do
		local index = tonumber(list[i]:GetGoName())
		list[i]:SetHighlight(index == copyType)
	end
end


function M:OnClose()
	self:Close()
	JumpMgr.eOpenJump()
end

function M:DisposeCustom()
	self:SetLsnr("Remove")
	ObjPool.Add(self.copyTowerTT)
	ObjPool.Add(self.copyTowerZH)
	ObjPool.Add(self.copyTowerTX)
	TableTool.ClearDicToPool(self.toggleList)
	self.copyTowerTT = nil
	self.copyTowerTX = nil
	self.copyTowerZH = nil
	self.copyType = nil
	self.curType= nil
end

return M


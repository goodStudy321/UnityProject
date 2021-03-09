--region UIFlowers.lua
--Date
--此文件由[HS]创建生成

UIFlowersSelectBase = Super:New{Name ="UIFlowersSelectBase"}
local M = UIFlowersSelectBase

local fMgr = FriendMgr

function M:Ctor()
	self.VDefault = nil
	self.Value = nil
	self.Items = {}
	self.Index = nil
	self.Data = nil
	self.eSelect = Event()
	self.Offset = 50
end

function M:Init(root)
	self.root = root
	local name = "送花选择"
	local trans = self.root.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.VLabel = C(UILabel, trans, "Label", name, false)
	self.BG = C(UITexture, trans, "Menu", name, false)
	self.Mask = T(trans, "Menu/Mask")
	self.SV = C(UIScrollView, trans, "Menu/ScrollView", name, false)
	self.Panel = C(UIPanel, trans, "Menu/ScrollView", name, false)
	self.Grid = C(UIGrid, trans, "Menu/ScrollView/Grid", name, false)
	self.Prefab = T(trans, "Menu/ScrollView/Grid/Item")
	self:InitData()
	self:AddEvent()
end

function M:InitData()
	self.VDefault = self.VLabel.text
	self.Value = self.VLabel.text 
	self:CustomInitData()
end

function M:AddEvent()
	local S = UITool.SetLsnrSelf
	S(self.Mask, self.OnClickMask, self, nil, false)
	S(self.root, self.OnClickMenu, self, nil, false)
end

function M:UpdateData()
	self:UpdateGrid()
end

function M:UpdateGrid()
	local len = self:GetTabLen() 
	for i=1,len do
		local go = GameObject.Instantiate(self.Prefab)
		go:SetActive(true)
		go.name = tostring(i)
		local t = go.transform
		t.parent = self.Grid.transform
		t.localScale = Vector3.one
		t.localPosition = Vector3.zero
		UITool.SetLsnrSelf(go, self.OnClickItem, self, nil, false)
		self:UpdateItem(i, t)
	end
	if self.Grid then
		self:UpdateBG(len)
		self.Grid:Reposition()
	end
end


function M:UpdateItem(trans)
	-- body
end

function M:OnClickItem(go)
	self.Index = tonumber(go.name)
	self:CustomClicItem()
	self:OnClickMask()
end

function M:UpdateBG(len)
	if len > 5 then len = 5 end
	local h = self.Grid.cellHeight
	h = h * len
	if self.Panel then
		local rect = self.Panel.baseClipRegion
		rect.w = h
		self.Panel.baseClipRegion = rect
		self.Grid.transform.localPosition = Vector3.New(0, h / 2,0)
	end
	h = h + 2
	local pos = nil
	if self.SV then
		pos = self.SV.transform.localPosition
		pos.y = -h/2 - self.Offset
		self.SV.transform.localPosition = pos
	end
	
	self.BG.height = h + self.Offset * 1.1
end

function M:UpdateVLabel()
	if self.VLabel then self.VLabel.text = self.Value end
end

function M:OnClickMask(go)
	if self.BG then self.BG.gameObject:SetActive(false) end
end

function M:OnClickMenu(go)
	if self.BG then self.BG.gameObject:SetActive(true) end
end

function M:GetTabLen()
	return 0
end

function M:SetValue(index, value)
	self.Index = index
	self.Value = value
	self:UpdateVLabel()
end

function M:Reset()
	self.Index = nil
	self.Data = nil
	self.Value = self.VDefault
	self:UpdateVLabel()
end

function M:Open()
	self:CustomOpen()
end

function M:Close()
	self:CustomClose()
end

function M:Clean()
	self:Reset()
	if self.Grid then
		local len = self.Grid:GetChildList().Count
		while len > 0 do
			local trans = self.Grid:GetChild(len - 1)
			trans.parent = nil
			Destroy(trans.gameObject)
			len = self.Grid:GetChildList().Count
		end
	end
	self:CustomClean()
end

function M:Dispose()
	self:Clean()
	self:CustomDispose()
end


function M:CustomOpen()
	-- body
end


function M:CustomClose()
	-- body
end


function M:CustomInitData()
	-- body
end

function M:CustomClicItem()
	-- body
end

function M:CustomSetValue(value)
end

function M:CustomClean()
	-- body
end

function M:CustomDispose()
	-- body
end
--endregion

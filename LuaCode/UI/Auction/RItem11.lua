RItem11 = Super:New{Name = "RItem11"}

local M = RItem11

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick
local USS = UITool.SetLsnrSelf

M.texList = {}

function M:Init(go)
    self.go = go
    local trans = go.transform

    self.itemTex = C(UITexture,trans, "IconBg/Icon", tip, false)
    self.nameLb = C(UILabel,trans,"name",tip,false)
    self.numLb = C(UILabel,trans,"num",tip,false)

    USS(trans,self.ClickSelf, self)
end

function M:InitItem(data,selCB)
    if data == nil then return end
    self.data = data
    self.selCB = selCB

    self:SetIcon(data.icon)
    
    self.nameLb.text = self.data.name
    self.numLb.text = self.data.num
end

function M:ClickSelf()
    if self.selCB ~= nil and self.data  then
		self.selCB(self.data.id)
	end
end

function M:Show(value)
	self.go:SetActive(value)
end

function M:SetIcon(iconName)
	AssetMgr:Load(iconName, ObjHandler(self.LoadIconFin,self))
	self.iconName = self.data.icon
end

function M:LoadIconFin(obj)
	self.itemTex.mainTexture = obj
	if self.texList then
		table.insert( self.texList, obj.name )
	else
		AssetTool.UnloadTex(obj.name)
	end
end

function M:Dispose()
    self.data = nil
    AssetTool.UnloadTex(self.texList)
end

return M
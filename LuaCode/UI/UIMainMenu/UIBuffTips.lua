--region UIBuffTips.lua
--Date
--此文件由[HS]创建生成

require("UI/UIMainMenu/UIBuffItem")

UIBuffTips = {}
local M = UIBuffTips

local uMgr = UserMgr

--注册的事件回调函数

function M:New(go)
	local name = "UI主界面BuffTips窗口"
	self.GO = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.BG = go:GetComponent("UISprite")

	self.Grid = C(UIGrid, trans, "Grid", name, false)
	self.Prefab = T(trans, "Grid/Item")
	self.Items = {}
	self:AddEvent()
	return M
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	self:SetEvent("Add")
	E(self.GO, self.ClickBG, self, nil, false)
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	uMgr.eAddBuff[fn](uMgr.eAddBuff, self.OnAddBuff, self)
	uMgr.eDelBuff[fn](uMgr.eDelBuff, self.OnDelBuff, self)
end

function M:OnDelBuff(id)
	local key = tostring(id)
	local item = self.Items[key]
	if item then
		item:Dispose()
		ObjPool.Add(item)
	end
	self.Items[key] = nil
	self:Reposition()
end

function M:OnAddBuff(data)
	local key = tostring(data.Temp.id)
	if self.Items[key] then
		self.Items[key]:UpdateData(data)
		return
	end
	local go = GameObject.Instantiate(self.Prefab)
	go:SetActive(true)
	local t = go.transform
	t.parent = self.Grid.transform
	t.localScale = Vector3.one
	t.localPosition = Vector3.zero
	local item = ObjPool.Get(UIBuffItem)
	item:Init(go)
	item:UpdateData(data)
	self.Items[key] = item
	self:Reposition()
end

function M:RestBuffsIcon()
	if not self.Items then return end
	for k,v in pairs(self.Items) do
		v:UpdateIcon()
	end
end

function M:Open()
	-- body
end

function M:Close()
	-- body
end

function M:ClickBG(go)
	self:SetActive(false)
end

function M:SetActive(value)
	local go = self.GO
	if go then
		go:SetActive(value)
	end
end

function M:UpdateActive()
	local go = self.GO
	if go then
		go:SetActive(not go.activeSelf)
	end
end

function M:Clear()
	for k,v in pairs(self.Items) do
		v:Dispose()
		ObjPool.Add(v)
		self.Items[k] = nil
	end
	self:Reposition()
end

function M:Reposition()
	if self.Grid then
		self.Grid:Reposition()
	end
	self:UpdateHeight()
end

function M:UpdateHeight()
	if self.BG and self.Items and self.Grid then
		self.BG.height = LuaTool.Length(self.Items) * self.Grid.cellHeight
	end
end

function M:Dispose()
	self:Clear()
	self:RemoveEvent()
	TableTool.ClearDic(self)
end
--endregion

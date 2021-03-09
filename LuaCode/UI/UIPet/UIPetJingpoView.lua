--region UIPetJingpoView.lua
--Date
--此文件由[HS]创建生成
require("UI/UICell/UICellJingPoIItem")


UIPetJingpoView = {}
local P = UIPetJingpoView
P.Name = "UIPetJingpoView"

function P:New()
	return self
end

function P:Init(go)
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	
	self.ScrollView = C(UIScrollView, trans, "ScrollView", self.Name, false) 
	self.Grid = C(UIGrid, trans, "ScrollView/Grid", self.Name, false)
	self.Prefab = T(trans, "ScrollView/Grid/Item")
	self.KeyList = {}
	self.Items = {}
	self:InitData()
	self:AddEvent()
end

function P:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.gameObject then
		E(self.gameObject, self.OnClickCloseBtn, self)
	end
end

function P:InitData()
	for k,v in pairs(PetJingPoTemp) do
		table.insert(self.KeyList, v.id)
	end
	table.sort(self.KeyList, function (a,b) return a < b end)
	local len = #self.KeyList
	for i=1,len do
		local id = self.KeyList[i]
		local key = tostring(id)
		local v = PetJingPoTemp[key]
		if v then
			self:AddItem(key,v)
		end
	end
	self.Grid:Reposition()
end

function P:AddItem(key,info)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = string.gsub(go.name, "%(Clone%)", "")
	go.name = go.name.."_"..key
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	self:AddCell(key, info, go)
end

function P:AddCell(key, info, go)
	self.Items[key] = UICellJingPoIItem.New(go)
	self.Items[key]:Init()
	self.Items[key]:UpdateInfo(info)
end

function P:UpdateUseCount()
	if not self.Items then return end
	for k,v in pairs(self.Items) do
		v:UpdateUse()
	end
end

function P:OnClickCloseBtn(go)
	self:SetActive(false)
end

function P:JinpoUpdate(key, val)
	if self.Items[key] then self.Items[key]:UpdateSlider() end
end

function P:UpdateItemList()
	if not self.Items then return end
	for k,v in pairs(self.Items) do
		if v.temp then
			v:UpdateItemList()
		end
	end
end

function P:SetActive(value)
	if self.gameObject then self.gameObject:SetActive(value) end
end

function P:Dispose()
	if self.Items then
		for k,v in pairs(self.Items) do
			self.Items[k]:Dispose(true)
			self.Items[k] = nil
		end
	end
	self.Items = nil
	self.KeyList = nil
	self.gameObject = nil
	self.ScrollView = nil
	self.Grid = nil
	self.Prefab = nil
	self.KeyList = nil
end
--endregion

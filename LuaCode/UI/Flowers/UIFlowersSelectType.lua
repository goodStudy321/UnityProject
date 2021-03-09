--region UIFlowers.lua
--Date
--此文件由[HS]创建生成

UIFlowersSelectType = UIFlowersSelectBase:New{Name="UIFlowersSelectType"}
local M = UIFlowersSelectType

local fMgr = FriendMgr

function M:CustomInitData()
	local temp = GlobalTemp["72"]
	if not temp then
		iTrace.eError("hs","Global配置没有key为72的条目")
		return
	end
	self.TList = temp.Value2 
	if not self.TList then
		iTrace.eError("hs","Global配置key为72的条目Value2字段为nil")
		return
	end
end

function M:GetTabLen()
	local list = self.TList
	if list then
		return #list
	end
	return 0
end

function M:UpdateItem(index, trans)
	local name = "送花选择花的类型"
	local C = ComTool.Get
	local T = TransTool.FindChild
	local data = {}
	data.Cell = ObjPool.Get(UIItemCell)
	data.Cell:Init(T(trans, "ItemCell"))
	data.Name = C(UILabel, trans, "Name", name, false)
	data.Count = C(UILabel, trans, "Count", name, false)
	table.insert(self.Items, data)
	self:UpdateItemData(index, data)
end

function M:UpdateItemData(index, data)
	local list = self.TList
	if not list or #list <= 0 then return end
	local id = list[index]
	if not id then return end
	local item = ItemData[tostring(id)]
	if not item then
		iTrace.eError("hs",string.format( "道具id{%}不存在", id))
		return
	end
	self:UpdateName(item, data)
	self:UpdateCount(item, data)
	self:UpdateItemCell(item, data)
end

function M:UpdateName(item, data)
	if data.Name then
		if not StrTool.IsNullOrEmpty(item.name) then
			data.Name.text = item.name
		else
			data.Name.text = ""
		end
	end
end

function M:UpdateCount(item, data)
	local num = ItemTool.GetNum(item.id)
	if data.Count then
		data.Count.text = tostring(num)
	end
end

function M:UpdateItemCell(item, data)
	if data.Cell then
		data.Cell:UpData(item)
	end
end

function M:CustomSetValue(index)
	self.Index = index
	self:CustomClicItem()
end

function M:CustomClicItem()
	if not self.Index then return end
	local list = self.TList
	if not list or #list <= 0 then return end
	local id = list[self.Index]
	if not id then return end
	local item = ItemData[tostring(id)]
	if not item then return end
	self.Data  = item
	self.Value = item.name
	self:UpdateVLabel()
	self.eSelect()
end

function M:UpdateItemList()
	local items = self.Items
	if not items then return end
	local list = self.TList
	if not list or #list <= 0 then return end
	for i=1,#list do
		local item = items[i]
		if item then
			self:UpdateItemData(i, item)
		end
	end
end

function M:CustomClean()
	-- body
end

function M:CustomDispose()
end
--endregion
